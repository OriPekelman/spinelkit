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

## Canonical surface — the cleanup question

The bootstrap API is the *union* of both donors, which still carries two
artifacts of the old split that a clean standardization should resolve:

- **Prefixed names (`j_*`/`tj_*` on the builder, `gi_*` on Git).** These
  prefixes exist *only* to dodge Spinel's name-keyed inference landmine — they
  are a workaround, not a design. Since we own Spinel, the principled fix is to
  **fix the name-keyed cross-module widening in the compiler** and then drop
  the prefixes, so the kit exposes plain `escape`/`quote`/`add_str`/`sha`/…
  This is tracked as the real end-state; until that Spinel fix lands, dropping
  the prefixes risks reintroducing the corruption.
- **Duplicated escapers (`escape` vs `tj_escape`, `hex2` vs `tj_hex2`).** Today
  they are byte-identical but kept separate because delegating once mis-widened
  a param (documented in `spinel-discipline.md`). Same root cause; same fix.

So there is a genuine fork — collapse now (requires/bets on the Spinel
inference fix) vs. ship the union for v0.1 and converge once that fix lands.
**This is called out for an explicit decision rather than chosen unilaterally,
because it has compiler-correctness consequences.** The bootstrap ships the
union so the migration can begin immediately on a stable surface; the
convergence is the first follow-up once the call is made.

## Git/Log

Once tep and toy are both on `SpinelKit::Json`, tep gains `SpinelKit::Git` and
toy gains `SpinelKit::Log` — each was previously single-consumer. No aliasing
needed; just use the canonical names at the new call sites.

## Out of scope until a catalog change

`Path` and `Bytes` stay where they are (see
[`gem-audit-first.md`](gem-audit-first.md)). Revisit `Path` only if the filed
`hike` re-verification flips it back to `verified`.
