# SpinelKit -- the Spinel stdlib-surface gem.
#
# A pure-Ruby, Spinel-safe toolkit holding the generic "stdlib substitute"
# shims that every Spinel-compiled project would otherwise hand-roll. Spinel
# (the Ruby->native AOT compiler) cannot lower large chunks of CRuby stdlib
# -- the `json` gem's C-ext fast path and metaprogrammed pure-Ruby fallback,
# stdlib `Logger`, C-ext git bindings -- and the spinelgems compatibility
# catalog confirms there is no verified gem to reuse for any of them. So this
# gem consolidates the shims toy and tep each grew independently:
#
#   SpinelKit::Json          -- JSON encoders (json.rb) + flat-key decoders
#                               (json_decoder.rb).
#   SpinelKit::Json::Builder -- incremental ordered-object builder.
#   SpinelKit::Git           -- git provenance from .git/HEAD (was Toy::Git).
#   SpinelKit::Log           -- minimal levelled logger (was Tep::Logger).
#
# MINIMAL-SURFACE REQUIRING. This umbrella requires everything for
# convenience (and for CRuby use). But because Spinel compiles every loaded
# method with no tree-shaking, a Spinel-compiled consumer should require ONLY
# the file(s) it uses, to avoid compiling -- and degrading -- code it never
# calls:
#
#   require "spinel_kit/json"          # encoders
#   require "spinel_kit/json_decoder"  # decoders (require alongside json if you decode)
#   require "spinel_kit/json_builder"  # builder
#   require "spinel_kit/git"
#   require "spinel_kit/log"
#
# No native extension (spinel-ext.json is []), no runtime dependencies. See
# docs/adoption.md and docs/spinel-discipline.md.
require_relative "spinel_kit/version"
require_relative "spinel_kit/json"
require_relative "spinel_kit/json_decoder"
require_relative "spinel_kit/json_builder"
require_relative "spinel_kit/git"
require_relative "spinel_kit/log"

module SpinelKit
end
