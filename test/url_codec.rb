# spin test entry: SpinelKit::Url — deterministic snapshot (.expected).
# ASCII-only inputs on purpose: escape is byte-oriented and String#[] indexes
# bytes under Spinel vs chars under CRuby, so multi-byte parity is exercised
# in the CRuby suite (test/parity/) with binary strings, not here.
require "spinel_kit/url"

# escape: RFC 3986 unreserved set survives, the rest becomes uppercase %XX
puts SpinelKit::Url.escape("abc-XYZ_0.9~")
puts SpinelKit::Url.escape("a b&c=d/e?f")
puts SpinelKit::Url.escape("")

# unescape: form-decode (+ is space, %XX is a byte; bad %-runs pass through)
puts SpinelKit::Url.unescape("a+b")
puts SpinelKit::Url.unescape("%41%20%26")
puts SpinelKit::Url.unescape("100%")
puts SpinelKit::Url.unescape("%zz")

# parse_query
puts SpinelKit::Url.parse_query("a=1&b=two&c").inspect
puts SpinelKit::Url.parse_query("k+ey=v%26al").inspect
puts SpinelKit::Url.parse_query("").inspect

# split_url
puts SpinelKit::Url.split_url("http://example.com/x/y?q=1").inspect
puts SpinelKit::Url.split_url("https://example.com:8443").inspect
puts SpinelKit::Url.split_url("/just/a/path?k=v").inspect
