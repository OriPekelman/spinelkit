# Spinel discipline — naming, poly-degrade, and the Hash gotcha

SpinelKit ships code that gets compiled into *other* programs by Spinel's
whole-program AOT compiler. That changes the rules for how it must be written.
This doc is the contract for anyone editing `lib/spinel_kit/*.rb`.

## 1. Whole-program inference is keyed on names — do NOT rename

Spinel infers types across the entire compiled program, and that inference is
keyed **partly on method and parameter names**. The failure mode is silent and
non-local:

> A builder method `num(key, value)` whose `value` parameter is numeric-poly
> can silently widen *every other* `value` parameter in the consuming program
> to `poly` — degrading or corrupting compute **even when SpinelKit is merely
> `require`d and never called.**

This actually happened in toy: a plain `value` param corrupted warm-start
training compute. The fix was to give every method and parameter a namespace
prefix so they can't collide with hot-path names elsewhere.

**This prefixing is a workaround, not the design we want.** Since we author
Spinel itself, the principled end-state is to fix the name-keyed cross-module
widening in the compiler and then drop the `j_*`/`tj_*`/`gi_*` prefixes so the
kit exposes plain, standard names. Until that compiler fix lands, the rules
below hold and the prefixes stay. See `adoption.md` ("Canonical surface").

**Consequences for SpinelKit:**

- **Every public name is preserved verbatim from its proven-green donor.** Do
  not "tidy," shorten, or generalise names. `Json`'s builder half keeps `j_*`
  / `tj_*` and params `jk`/`jv`/`jchild`; `Git` keeps `gi_*`; the
  encoder/decoder half keeps its donor spellings.
- **The two `Json` halves were checked for collisions.** Builder params
  (`jk`/`jv`/`jchild`) and encoder/decoder params (`s`/`key`/`k`/`v`) are
  disjoint, so the union adds no new collisions. The only intra-name
  polymorphism (`encode_pair_str` vs `encode_pair_int` over `v`) already
  shipped green inside tep.
- **`Json.escape` and `Json.tj_escape` stay separate**, byte-identical
  methods — we do **not** delegate one to the other. tep's `get_float` comment
  records that factoring a value-walk through a shared helper mis-widened a
  param to int. Independence is the safe choice; the small duplication is the
  price.
- **Never override `to_s`** — it merges across the whole program.

## 2. The poly-degrade gate (how consumers verify SpinelKit is safe)

Each consumer has a poly-degrade scan that compiles a canonical entrypoint and
counts Spinel's `cannot resolve call to '<x>' on <type> (emitting 0)` warnings,
comparing against a frozen baseline of known-benign dead paths. A **new**
warning is a regression.

- toy: `make gate-poly-degrade` → `prep/poly_degrade_gate.rb`
  (baseline-compare; `--record` to re-baseline).

When toy/tep adopt SpinelKit (see [`adoption.md`](adoption.md)), the gate must
stay **byte-identical to baseline** after the move. If aliasing
`Toy::Json = SpinelKit::Json` introduces an emit-0, the names are colliding —
fix the name, don't re-baseline.

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
