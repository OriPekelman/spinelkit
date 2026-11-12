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

  # The codec is byte-oriented, and escape walks bytes to be so, so a binary
  # string and the plain one it came from escape identically.
  def test_escape_unescape_utf8_bytes
    assert_equal "%C3%A9", U.escape("é".b)
    assert_equal "é".b, U.unescape("%C3%A9").b
    assert_equal "%E2%82%AC", U.escape("€".b)   # 3-byte char
  end

  # The case the `.b` above used to stand in for. escape indexed with
  # String#[] and encoded c.getbyte(0) — the FIRST byte of the character — on
  # the premise that `[]` indexes bytes under Spinel. It does not:
  # `"café".length` is 4 there and `[3]` is a two-byte "é". So a plain UTF-8
  # string lost every byte but the first of each character, on BOTH runtimes
  # identically — "café" escaped to "caf%C3", which does not unescape back.
  # Only ever passing `.b` here is what let it stand.
  def test_escape_multibyte_without_forcing_binary
    assert_equal "caf%C3%A9", U.escape("café")
    assert_equal "%E2%82%AC", U.escape("€")
    assert_equal "%F0%9F%98%80", U.escape("😀")   # 4-byte char
    # Same answer either way, which is the property that was missing.
    ["café", "€", "😀"].each { |s| assert_equal U.escape(s.b), U.escape(s) }
    # And the bytes come back (unescape answers a byte string, as it always has).
    assert_equal "café".b, U.unescape(U.escape("café")).b
  end

  # CGI.escape is the form encoder (space -> "+"); escapeURIComponent is the
  # one this matches on everything but the space, so compare there.
  def test_escape_matches_cgi_on_multibyte
    assert_equal CGI.escape("café").sub("+", "%20"), U.escape("café")
    assert_equal CGI.escape("😀"), U.escape("😀")
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
