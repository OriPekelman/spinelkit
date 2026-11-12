# spin test entry: SpinelKit::Url — deterministic snapshot (.expected).
# Multi-byte inputs belong HERE, not only in the CRuby suite: this file used
# to say they were excluded because String#[] indexes bytes under Spinel and
# chars under CRuby, and that premise is what hid the escape bug —
# `"café".length` is 4 under Spinel too. The snapshot is byte-identical on
# both runtimes, which is the claim worth pinning where it can be checked.
require "spinel_kit/url"

# escape: RFC 3986 unreserved set survives, the rest becomes uppercase %XX
puts SpinelKit::Url.escape("abc-XYZ_0.9~")
puts SpinelKit::Url.escape("a b&c=d/e?f")
puts SpinelKit::Url.escape("")

# escape: every BYTE of a multi-byte character, not just its first
puts SpinelKit::Url.escape("caf\u00e9")
puts SpinelKit::Url.escape("\u20ac")
puts SpinelKit::Url.escape("\u{1F600}")

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
