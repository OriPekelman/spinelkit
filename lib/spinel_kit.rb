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
#   SpinelKit::Json -- ordered-object builder (toy half) + JSON-over-HTTP
#                      encoder/flat-key decoder (tep half), unioned.
#   SpinelKit::Git  -- git provenance from .git/HEAD (was Toy::Git).
#   SpinelKit::Log  -- minimal levelled logger (was Tep::Logger).
#
# No native extension (spinel-ext.json is []), no runtime dependencies --
# it vendors cleanly via bundler-spinel. See docs/adoption.md for how toy
# and tep consume it, and docs/gem-audit-first.md for the catalog audit that
# justifies implementing rather than reusing each surface.
require_relative "spinel_kit/version"
require_relative "spinel_kit/json"
require_relative "spinel_kit/git"
require_relative "spinel_kit/log"

module SpinelKit
end
