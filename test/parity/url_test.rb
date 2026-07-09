# CRuby-side tests for SpinelKit::Url. Asserts the percent-codec + query
# parser behave like the CGI/URI surface they replace (for the cases where
# semantics line up) and against known-correct literals otherwise.
require "minitest/autorun"
require "cgi"
require "spinel_kit"

class UrlTest < Minitest::Test
  U = SpinelKit::Url

  def test_unescape_handles_percent_and_plus
    assert_equal "A b", U.unescape("%41+b")
    assert_equal "a/b c", U.unescape("a%2Fb+c")
    # matches CGI.unescape for the form-decode subset
    assert_equal CGI.unescape("hello%20world%21+x"), U.unescape("hello%20world%21+x")
  end

  def test_unescape_passes_through_malformed_percent
    assert_equal "%zz", U.unescape("%zz")
    assert_equal "%", U.unescape("%")
  end

  def test_escape_is_rfc3986_unreserved_uppercase
    assert_equal "abcXYZ0189-._~", U.escape("abcXYZ0189-._~")  # unreserved pass-through
    assert_equal "A%20b%2Fc", U.escape("A b/c")                # space->%20, /->%2F, UPPER
    assert_equal "%26%3D%3F", U.escape("&=?")
  end

  def test_escape_unescape_roundtrip_ascii
    ["a b/c?d=e&f", "x~y_z.q-r", "100% sure!"].each do |s|
      assert_equal s, U.unescape(U.escape(s))
    end
  end

  # The codec is byte-oriented (under Spinel, String#[] indexes bytes — strings
  # are byte-blobs). Pass binary so CRuby's String#[] is byte-indexed too, then
  # each UTF-8 byte round-trips through %XX. (A non-binary multibyte string in
  # CRuby would split on characters, not bytes — a CRuby/Spinel difference, not
  # a codec bug; under Spinel the plain string is already bytes.)
  def test_escape_unescape_utf8_bytes
    assert_equal "%C3%A9", U.escape("é".b)
    assert_equal "é".b, U.unescape("%C3%A9").b
    assert_equal "%E2%82%AC", U.escape("€".b)   # 3-byte char
  end

  def test_parse_query
    assert_equal({ "a" => "1", "b" => "2", "c" => "" }, U.parse_query("a=1&b=2&c"))
    assert_equal({}, U.parse_query(""))
    assert_equal({ "k" => "a b" }, U.parse_query("k=a+b"))
    assert_equal({ "name" => "a/b" }, U.parse_query("name=a%2Fb"))
  end

  def test_split_url_http
    h = U.split_url("http://example.com:8080/path/x?q=1")
    assert_equal "http", h["scheme"]
    assert_equal "example.com", h["host"]
    assert_equal "8080", h["port"]
    assert_equal "/path/x", h["path"]
    assert_equal "q=1", h["query"]
  end

  def test_split_url_https_default_port_and_no_path
    h = U.split_url("https://host")
    assert_equal "https", h["scheme"]
    assert_equal "host", h["host"]
    assert_equal "443", h["port"]
    assert_equal "/", h["path"]
  end

  def test_split_url_schemeless_is_path
    h = U.split_url("/just/a/path?x=1")
    assert_equal "", h["scheme"]
    assert_equal "", h["host"]
    assert_equal "/just/a/path", h["path"]
    assert_equal "x=1", h["query"]
  end
end
