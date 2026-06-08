# Adoption — standardize and clean (not shim-and-alias)

Bootstrap landed the gem and its three shims. Adoption by tep and toy is the
next phase. **Because we author every repo in this set — toy, tep, spinelgems,
and Spinel itself — the goal is to standardize and clean, not to bolt
compatibility aliases on top of the old duplication.** Each consumer migrates
to `SpinelKit::*` directly and **deletes** its donor module. No permanent
`Tep::Json = SpinelKit::Json` shims left lying around.

This is still a sequenced move — moving shared code into a new namespace can
introduce poly-degrade collisions in a consumer's whole-program inference — so
we migrate one consumer at a time and gate each on its poly-degrade scan. But
the end-state is clean call sites, one canonical surface, and no aliases.

## Consumption mechanism (and the current interim)

The clean path is `gem "spinel_kit"` + `spinel-compat vendor`. But that flow
does **not yet support transitive gem→gem dependencies** (no topo-sorted
`deps.rb`, no inter-gem require resolution), so a consumer that is *itself* a
vendored gem — like tep — can't yet pull spinel_kit through it. Tracked at
[OriPekelman/spinelgems#19](https://github.com/OriPekelman/spinelgems/issues/19).

**Interim:** the consumer vendors spinel_kit's lib (the surface it uses)
**committed under its own `lib/spinel_kit/`**, re-synced from the published gem
(e.g. tep's `make vendor-spinelkit`). Committed-under-`lib/` is what makes it
travel correctly when the consumer is itself vendored. Once spinelgems#19 lands,
switch to the gitignored `spinel-compat vendor` flow.

## Migration per consumer

For each of tep and toy:

1. Add `gem "spinel_kit"` (path/git during dev) and `spinel-compat vendor`.
2. **Rewrite the call sites** to the canonical names:
   - tep: ~157 `Tep::Json.*` → `SpinelKit::Json.*`; `Tep::Logger` →
     `SpinelKit::Log`.
   - toy: the `Toy::Json.new` builder sites → `SpinelKit::Json.new`;
     `Toy::Git.read` → `SpinelKit::Git.read`.
   A mechanical find/replace per symbol; the names below are chosen so the
   replacement is 1:1 (see "Canonical surface").
3. **Delete the donor files** (`lib/tep/json.rb`, `lib/tep/logger.rb`,
   `lib/toy/io/toy_json.rb`, `lib/toy/io/toy_git.rb`) — no alias, no subclass.
4. Build + run that consumer's suite.
5. **toy only:** `make gate-poly-degrade` must stay byte-identical to the
   frozen baseline (`prep/poly_degrade_gate.rb`). toy is where the
   name-collision corruption originally bit. If an emit-0 appears, fix the
   colliding name in SpinelKit (then re-vendor) rather than re-baselining.

Sequence tep first (simpler, no training landmine), then toy.

## Canonical surface — already converged

The kit exposes ONE clean surface, not the union of two prefixed donor copies:

- **No `j_*`/`tj_*`/`gi_*` prefixes.** Those existed only to dodge a Spinel
  name-keyed inference bug, which is now fixed upstream (`ac7720e` #684,
  `23ba632` #1043; verified on rev `57af7f9` with toy's gate-poly-degrade — see
  [`spinel-discipline.md`](spinel-discipline.md)). The builder uses
  `add_str`/`add_num`/`add_bool`/`add_raw`/`add_obj`/`dump`; Git uses
  `sha`/`branch`.
- **No duplicated escapers.** `escape`/`quote`/`hex2` are single canonical
  methods the builder calls.

The Json surface is split across **three files** so each consumer compiles only
what it uses — Spinel has no tree-shaking, so loading code a consumer never
calls would compile (and degrade) it, which both trips the poly-degrade gate
and, worse, was observed to silently miscompile (dead decoder walkers widened
`escape`'s string arg to int, emitting `""` keys from `from_*_hash`). The split:
`spinel_kit/json` (encoders), `spinel_kit/json_decoder` (decoders),
`spinel_kit/json_builder` (builder). So:

- **tep** `require "spinel_kit/json"` + `"spinel_kit/json_decoder"` (it both
  encodes responses and decodes request bodies) + `spinel_kit/log`. Verified:
  the full encode+decode surface compiles **0 warnings, correct** on rev
  `57af7f9`.
- **toy** `require "spinel_kit/json_builder"` + `spinel_kit/git`. Verified:
  builder-only compiles **0 warnings, correct** (integers preserved, no
  cross-module `value` poisoning).

A consumer must actually exercise the surface it loads (real ones do). A
program that loads decoders but never calls them — or encodes via `from_*_hash`
without any other string-`quote` call — can still see the dead-method
degradation; the poly-degrade gate is what catches that.

The per-symbol replacement is then a clean rename:

| donor call               | canonical call                  |
|--------------------------|---------------------------------|
| `Toy::Json.new`          | `SpinelKit::Json::Builder.new`  |
| `j.j_str(k, v)`          | `j.add_str(k, v)`               |
| `j.j_num(k, v)`          | `j.add_num(k, v)`               |
| `j.j_dump`               | `j.dump`                        |
| `Toy::Git.read.gi_sha`   | `SpinelKit::Git.read.sha`       |
| `Tep::Json.get_str(s,k)` | `SpinelKit::Json.get_str(s,k)`  |
| `Tep::Json.quote(s)`     | `SpinelKit::Json.quote(s)`      |
| `Tep::Logger.new`        | `SpinelKit::Log.new`            |

tep's encoder/decoder spellings (`escape`/`quote`/`encode_pair_*`/`from_*`/
`get_*`) are unchanged — only the namespace moves. toy's builder is the one set
of call sites that changes method names. Each consumer's compile should be
warning-clean (no new emit-0) because it loads only its own surface — verify
with the poly-degrade gate after the move.

## Git/Log

Once tep and toy are both on `SpinelKit::Json`, tep gains `SpinelKit::Git` and
toy gains `SpinelKit::Log` — each was previously single-consumer. No aliasing
needed; just use the canonical names at the new call sites.

## Out of scope until a catalog change

`Path` and `Bytes` stay where they are (see
[`gem-audit-first.md`](gem-audit-first.md)). Revisit `Path` only if the filed
`hike` re-verification flips it back to `verified`.
