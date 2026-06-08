# CRuby-side parity tests for SpinelKit::Json. These NEVER get compiled by
# Spinel -- they run under CRuby (which has the real `json` gem) to prove the
# hand-rolled shim encodes/decodes ASCII identically before the code is
# vendored into a Spinel build. The shim's value is that it compiles under
# Spinel where `json` can't; its correctness contract is "matches CRuby json
# for the ASCII / flat-object subset it supports."
require "minitest/autorun"
require "json"
require "spinel_kit"

class JsonParityTest < Minitest::Test
  J = SpinelKit::Json

  # ---- Encoder half: output must parse back to the same value via CRuby ----

  def test_from_str_hash_roundtrips_via_cruby
    h = { "name" => "gx10", "note" => "a \"quoted\" \\ slash\ttab" }
    assert_equal h, JSON.parse(J.from_str_hash(h))
  end

  def test_from_int_hash_roundtrips_via_cruby
    h = { "age" => 33, "neg" => -7, "zero" => 0 }
    assert_equal h, JSON.parse(J.from_int_hash(h))
  end

  def test_from_arrays_roundtrip_via_cruby
    assert_equal %w[a b c], JSON.parse(J.from_str_array(%w[a b c]))
    assert_equal [1, 2, 3], JSON.parse(J.from_int_array([1, 2, 3]))
  end

  def test_escape_matches_cruby_for_control_chars
    # CRuby dumps a bare string as "...."; strip the surrounding quotes to
    # compare the escaped body against our escape().
    s = "tab\tnl\nq\"bs\\del"
    cruby_body = JSON.generate(s)[1..-2]
    assert_equal cruby_body, J.escape(s)
  end

  # ---- Builder half ----

  def test_builder_emits_parseable_object_in_insertion_order
    j = SpinelKit::Json::Builder.new
    j.add_str("kind", "run_start")
    j.add_num("t", 1715000000)
    j.add_bool("ok", true)
    j.add_raw("lr", "0.001")
    out = j.dump
    assert_equal '{"kind":"run_start","t":1715000000,"ok":true,"lr":0.001}', out
    assert_equal "run_start", JSON.parse(out)["kind"]
  end

  def test_builder_nests_sub_builders
    host = SpinelKit::Json::Builder.new
    host.add_str("name", "gx10")
    j = SpinelKit::Json::Builder.new
    j.add_obj("host", host)
    assert_equal({ "host" => { "name" => "gx10" } }, JSON.parse(j.dump))
  end

  def test_builder_escapes_like_cruby
    j = SpinelKit::Json::Builder.new
    j.add_str("msg", "a \"q\" \\ b\tc")
    assert_equal({ "msg" => "a \"q\" \\ b\tc" }, JSON.parse(j.dump))
  end

  # ---- Decoder half: read a top-level key from a flat object ----

  def test_get_str_and_int_and_float
    doc = JSON.generate("name" => "abc", "age" => 33, "pi" => 3.14)
    assert_equal "abc", J.get_str(doc, "name")
    assert_equal 33,    J.get_int(doc, "age")
    assert_in_delta 3.14, J.get_float(doc, "pi"), 1e-9
  end

  def test_get_int_array
    doc = JSON.generate("ids" => [464, 6193, 0, -2])
    assert_equal [464, 6193, 0, -2], J.get_int_array(doc, "ids")
  end

  def test_has_key_and_missing_defaults
    doc = '{"a":"x","nest":{"k":"v"}}'
    assert J.has_key?(doc, "a")
    assert J.has_key?(doc, "nest")
    refute J.has_key?(doc, "missing")
    # Missing-key defaults (documented contract).
    assert_equal "", J.get_str(doc, "missing")
    assert_equal 0,  J.get_int(doc, "missing")
    assert_equal 0.0, J.get_float(doc, "missing")
    assert_equal [], J.get_int_array(doc, "missing")
  end

  def test_decoder_skips_nested_values_to_reach_later_key
    doc = JSON.generate("nest" => { "deep" => [1, 2] }, "after" => "found")
    assert_equal "found", J.get_str(doc, "after")
  end

  def test_get_str_decodes_escapes
    doc = JSON.generate("msg" => "line1\nline2\t\"q\"")
    assert_equal "line1\nline2\t\"q\"", J.get_str(doc, "msg")
  end
end
