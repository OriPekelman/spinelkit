# Changelog

All notable changes to SpinelKit are documented here.

## [0.2.0] - 2026-06-08

### Added
- **`SpinelKit::Hex`** (`lib/spinel_kit/hex.rb`) — hex digit/byte codec:
  `nibble` (hex char → 0..15), `nibble_char` (0..15 → uppercase hex char),
  `byte2` (byte → two lowercase hex chars), `to_int` (leading hex digits →
  int). Consolidates a `hex_nibble` that was **byte-identical** across
  `Tep::Url`, `Tep::Llm`, and `SpinelKit::Json`'s decoder.
- **`SpinelKit::Url`** (`lib/spinel_kit/url.rb`) — the `CGI`/`URI`-component
  surface Spinel can't get from stdlib: `escape`/`unescape` (RFC 3986
  percent-codec), `parse_query` (form-urlencoded → Hash), `split_url`
  (scheme/host/port/path/query). Ported from `Tep::Url`; uses `SpinelKit::Hex`
  and is self-contained (inline typed-hash seeding + substring search).

`SpinelKit::Json` keeps its own private `hex2`/`hex_nibble` so a JSON-only
consumer never compiles `Hex` (Spinel has no tree-shaking) — the small
duplication is the surface-isolation cost.

## [0.1.1] - 2026-06-08

### Fixed
- `SpinelKit::Git.read` no longer truncates branch names that contain a slash.
  A branch like `feat/x` (HEAD → `ref: refs/heads/feat/x`) was reported as `x`
  because the parser took the last `/`-segment. It now strips the `refs/heads/`
  prefix, preserving the full branch path (`feat/x`, `user/feature/sub/thing`).
  Non-`heads` refs fall back to the last segment. Caught by toy's run_start
  provenance during the toy#44 migration. Covered by `test/git_test.rb`.

## [0.1.0] - 2026-06-08

First release. Establishes the gem and lands the three core shims, consolidated
from toy and tep. See [OriPekelman/toy#44](https://github.com/OriPekelman/toy/issues/44)
for the rationale.

### Added
- `SpinelKit::Json` encoders (`lib/spinel_kit/json.rb`) — from `Tep::Json`:
  `escape`/`quote`/`encode_pair_*`/`from_*`.
- `SpinelKit::Json` decoders (`lib/spinel_kit/json_decoder.rb`) — from
  `Tep::Json`: flat-key `get_str`/`get_int`/`get_float`/`get_int_array`/
  `has_key?` + the hand-rolled walker.
- `SpinelKit::Json::Builder` (`lib/spinel_kit/json_builder.rb`) — the
  incremental ordered-object builder from `Toy::Json`, now
  `add_str`/`add_num`/`add_bool`/`add_raw`/`add_obj`/`dump`, with its own
  byte-identical escapers.
- Encoders / decoders / builder are split across three files on purpose:
  Spinel has no tree-shaking, so a consumer that loaded an unused half compiled
  (and degraded) it — concretely, dead decoder walkers widened `escape`'s
  string arg to `int` and silently emitted `""` keys from `from_*_hash`. With
  the split, each real consumer shape compiles 0-warning and correct (verified
  through the Spinel binary on rev `57af7f9`): builder-only (toy), and
  encode+decode (tep).
- `SpinelKit::Git` — `.git/HEAD` provenance (`sha`/`branch`), ported from
  `Toy::Git`. tep gains it.
- `SpinelKit::Log` — minimal levelled logger, ported from `Tep::Logger`. toy
  gains it.

### Naming
- Dropped the donor `j_`/`tj_`/`gi_` prefixes in favour of plain, standard
  names. Those prefixes worked around a Spinel name-keyed inference bug that
  has since been fixed upstream (`ac7720e` #684, `23ba632` #1043), verified on
  rev `57af7f9` via toy's `gate-poly-degrade` and its landmine-#16 probe.
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
