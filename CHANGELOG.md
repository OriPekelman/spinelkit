# Changelog

All notable changes to SpinelKit are documented here.

## [0.1.0] - 2026-06-08 (unreleased)

Bootstrap. Establishes the gem and lands the three core shims, consolidated
from toy and tep. See toy#44 for the rationale.

### Added
- `SpinelKit::Json` — the union of `Toy::Json` (ordered-object builder, `j_*`
  appenders + `tj_*` escapers) and `Tep::Json` (JSON-over-HTTP encoders +
  flat-key decoders `get_str`/`get_int`/`get_float`/`get_int_array`/`has_key?`).
  The two donors' escape/quote/hex code was byte-identical; the halves share
  no method or parameter names, so the union is collision-safe under Spinel's
  whole-program inference.
- `SpinelKit::Git` — `.git/HEAD` provenance (`gi_sha`/`gi_branch`), ported
  from `Toy::Git`. tep gains it.
- `SpinelKit::Log` — minimal levelled logger, ported from `Tep::Logger`. toy
  gains it.
- `docs/gem-audit-first.md` — the spinelgems catalog audit justifying
  implement-don't-reuse for each surface, the methodology, and links to the
  filed verification-request issues.
- `docs/spinel-discipline.md` — the poly-degrade naming rules and the
  `Hash[missing]==0` / SafeHash gotcha.
- `docs/adoption.md` — the deferred 3-way move (tep adopts, toy adopts).

### Not yet done (deferred — see docs/adoption.md)
- Consumer adoption: tep and toy still ship their own `*::Json`/`Git`/`Logger`.
  The alias-and-vendor migration sequences behind this frozen API, gated by
  each consumer's poly-degrade scan.
