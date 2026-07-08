# SpinelKit -- the non-stdlib toolkit for Spinel-compiled apps.
#
# A pure-Ruby, Spinel-safe toolkit holding the shims Spinel (the Ruby->native
# AOT compiler) does not provide and that every Spinel-compiled project would
# otherwise hand-roll:
#
#   SpinelKit::Hex -- hex digit/byte encode + decode.
#   SpinelKit::Url -- percent-encode/decode + form-query + URL split.
#   SpinelKit::Git -- git provenance from .git/HEAD (was Toy::Git).
#   SpinelKit::Log -- minimal levelled logger (was Tep::Logger).
#
# JSON is NOT here any more. Spinel bundles `json` as a require-gated stdlib
# package (a typed native binding into sp_json.c), so consumers write a bare
# `require "json"` and use JSON.parse / JSON.generate, coercing parsed values
# at the boundary (`.to_s` / `.to_i` / `.to_f` / `.map { |x| x.to_i }`) to
# keep inference fully typed. The old SpinelKit::Json codec + Builder were
# retired in 0.3.0 -- see CHANGELOG.md and issue #3.
#
# MINIMAL-SURFACE REQUIRING. This umbrella requires everything for
# convenience (and for CRuby use). But because Spinel compiles every loaded
# method with no tree-shaking, a Spinel-compiled consumer should require ONLY
# the file(s) it uses, to avoid compiling -- and degrading -- code it never
# calls:
#
#   require "spinel_kit/hex"           # hex digit/byte codec
#   require "spinel_kit/url"           # percent-codec + query (pulls in hex)
#   require "spinel_kit/git"
#   require "spinel_kit/log"
#
# No native extension (spinel-ext.json is []), no runtime dependencies. See
# docs/adoption.md and docs/spinel-discipline.md.
require_relative "spinel_kit/version"
require_relative "spinel_kit/hex"
require_relative "spinel_kit/url"
require_relative "spinel_kit/git"
require_relative "spinel_kit/log"

module SpinelKit
end
