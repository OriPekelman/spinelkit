# Spinel discipline — naming, poly-degrade, and the Hash gotcha

SpinelKit ships code that gets compiled into *other* programs by Spinel's
whole-program AOT compiler. That changes the rules for how it must be written.
This doc is the contract for anyone editing `lib/spinel_kit/*.rb`.

## 1. The name-keyed inference bug — FIXED, prefixes dropped

The donor copies (`Toy::Json`, `Toy::Git`) carried `j_`/`tj_`/`gi_` prefixes on
every method and parameter to dodge a Spinel bug:

> A same-named method or attr-reader across unrelated classes, reached through
> an unresolved receiver, could commit a wrong type and widen an unrelated
> value to `poly` — degrading or corrupting compute **even when the offending
> module was merely `require`d and never called.**

This actually bit toy (landmines #12/#16 in the gx10-side memory note
`feedback_spinel_type_inference_landmines.md`; #16 was filed as matz/spinel
#1043). **It has since been fixed in the compiler** — the relevant commits are
`ac7720e` ("same-named attr_accessor on unrelated classes no longer widens
reader to poly", #684) and `23ba632` ("Don't let a Struct member name globally
type-merge unrelated code", fixes #1043), part of a sustained campaign that
made inference receiver-aware / method-scoped instead of name-keyed. Each ships
a regression test in Spinel's CI.

**Verified, not assumed.** On the current compiler (rev `57af7f9`) we compiled
two-module reproducers — a builder whose `value` param legitimately goes poly
alongside an unrelated method with its own `value` param — and confirmed no
cross-method leakage; toy's own `gate-poly-degrade` and its landmine-#16 probe
both pass. So **the prefixes are gone** and SpinelKit uses plain, standard
names (`escape`/`quote`/`add_str`/`sha`/`branch`/plain `value`).

**Remaining rules:**

- **Split the surface so consumers don't compile dead code.** Spinel has no
  tree-shaking: every loaded method is compiled, and a *set* of uncalled
  methods can degrade each other's (and nearby live methods') param types. We
  saw this concretely — with the encoders and decoders in one class, an
  encode-only program left the 9 decoder walkers dead; their `s` params
  collapsed to `int` and dragged `escape`'s `s` to `int` too, silently
  emitting `""` keys from `from_*_hash`. The fix was structural: encoders
  (`json.rb`), decoders (`json_decoder.rb`), and builder (`json_builder.rb`)
  live in separate files, so a consumer loads only a coherent surface it
  actually exercises. Verified clean (0 emit-0, correct output) for the real
  consumer shapes — builder-only (toy) and encode+decode (tep) — on rev
  `57af7f9`. A consumer that loads a surface but leaves part of it uncalled can
  still trip the gate; that's expected, and the gate is what flags it.
- **`escape`/`quote`/`hex2` are single canonical methods** — the builder
  carries its own byte-identical copies (so a builder-only compile pulls in no
  codec); there is no `tj_*` prefix any more.
- **Keep `get_float` inlined** (it does NOT delegate to a `parse_float_value`
  helper). This is unrelated to the name bug — it's a value-walk *indirection*
  issue where Spinel mis-widened the string arg `s` to int through the helper
  call. Until that's separately confirmed fixed, leave it inlined.
- **Never override `to_s`** — it merges across the whole program.
- The stale cautionary comments in toy's `toy_json.rb`/`toy_git.rb` and the
  landmine memory note should be annotated "fixed upstream by `ac7720e`/
  `23ba632`, verified on `57af7f9`" when those repos are next touched.

## 2. The poly-degrade gate (how consumers verify SpinelKit is safe)

Each consumer has a poly-degrade scan that compiles a canonical entrypoint and
counts Spinel's `cannot resolve call to '<x>' on <type> (emitting 0)` warnings,
comparing against a frozen baseline of known-benign dead paths. A **new**
warning is a regression.

- toy: `make gate-poly-degrade` → `prep/poly_degrade_gate.rb`
  (baseline-compare; `--record` to re-baseline).

When toy/tep migrate to SpinelKit (see [`adoption.md`](adoption.md)), the gate
must stay **byte-identical to baseline** after the move. If rewriting toy's call
sites to `SpinelKit::Json.*` introduces an emit-0, treat it as a real
regression — fix the cause, don't re-baseline. (This gate guards a broader
failure mode than the old name bug — unresolved hot-path calls and missing
requires that emit a literal `0` — so it stays in CI regardless.)

## 3. The `Hash[missing] == 0` gotcha (a.k.a. "SafeHash")

This is **not a class** SpinelKit ships — it's a coding rule, because under
Spinel a missing hash key reads back as integer `0`, not `nil`:

```ruby
# WRONG under Spinel — absent key looks like rank 0 (highest priority):
r = @merge_rank[key]

# RIGHT — guard with has_key? first:
if @merge_rank.has_key?(key)
  r = @merge_rank[key]
  ...
end
```

In toy's tokenizer this exact bug made BPE apply spurious merges (every absent
merge looked like rank 0). **Always `has_key?` before `Hash[]`** in any code
destined for Spinel. SpinelKit's own decoders follow this rule.

## 4. Other Spinel limits relevant here

- No `STDERR` as a general writable destination in all contexts — `Log` prefers
  a file path; the `$stderr.puts` fallback is the donor's and works where tep
  runs, but file output is the portable path.
- `Time.now` exposes integer seconds only (no rich `strftime`) — `Log` formats
  with `Time.now.to_i`.
- `Integer#chr` is not uniform for arbitrary bytes — `Json.byte_to_chr` uses a
  printable-ASCII table with a `"?"` fallback.
- No C extensions — `spinel-ext.json` is `[]`.
