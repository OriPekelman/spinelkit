# SpinelKit

**The Spinel stdlib-surface gem.** A pure-Ruby, Spinel-safe toolkit holding
the generic "stdlib substitute" shims that every Spinel-compiled project would
otherwise hand-roll.

[Spinel](../spinel-dev) is a Ruby→native AOT compiler. It cannot lower large
chunks of the CRuby standard library — the `json` gem's C-extension fast path
and its metaprogrammed pure-Ruby fallback, stdlib `Logger`, C-extension git
bindings, and more. So every Spinel project re-derives the same shims. toy and
tep grew theirs independently, and the JSON escape/quote/hex code came out
*byte-identical*. SpinelKit is that code, consolidated once.

## Why a gem instead of reusing one?

The first thing we did was audit the [spinelgems](../spinelgems) compatibility
catalog (verdict ladder: `verified > loaded > clean > risky > rejected`) for an
existing gem to reuse — that would have been the biggest win. **There wasn't
one.** These shims *are* the ecosystem's gaps:

| Surface | Catalog finding | Decision |
|---------|-----------------|----------|
| JSON    | `json` **rejected** (C-ext + metaprogrammed fallback); `oj` **risky** (C-ext) | implement |
| Log     | `logger` **rejected** (unresolved calls) | implement |
| Git     | `rugged` **rejected** (C); `gitkite`/`git_manager` only **clean**, unmet `needs:` | implement (read `.git/HEAD`) |
| Path    | `hike` **verified** at an older rev, only **loaded** now; overkill for basename/join | deferred |
| Bytes   | `unicode_utils`/`utf8-cleaner` **clean** only; toy's need is tokenizer-specific | deferred |

See [`docs/gem-audit-first.md`](docs/gem-audit-first.md) for the full audit and
the verification-request issues we filed on spinelgems.

## What's in it

```ruby
require "spinel_kit"
```

- **`SpinelKit::Json`** — an ordered JSON-object builder (`j_str`/`j_num`/
  `j_bool`/`j_raw`/`j_obj`/`j_dump`) plus JSON-over-HTTP encoders
  (`escape`/`quote`/`encode_pair_*`/`from_*`) and flat-key decoders
  (`get_str`/`get_int`/`get_float`/`get_int_array`/`has_key?`).

  ```ruby
  j = SpinelKit::Json.new
  j.j_str("kind", "run_start")
  j.j_num("t", 1715000000)
  j.j_dump                                   # => {"kind":"run_start","t":1715000000}

  SpinelKit::Json.get_int('{"age":33}', "age")   # => 33
  ```

- **`SpinelKit::Git`** — git provenance from `.git/HEAD`.

  ```ruby
  g = SpinelKit::Git.read
  g.gi_sha       # => "a1b2c3..." (or "unknown" outside a repo)
  g.gi_branch    # => "main"
  ```

- **`SpinelKit::Log`** — a minimal levelled logger (CRuby `Logger` doesn't
  compile under Spinel).

  ```ruby
  log = SpinelKit::Log.new
  log.set_level("info")
  log.info("server up")
  ```

## Design constraints (read before editing)

SpinelKit is **pure Ruby, no native extension** (`spinel-ext.json` is `[]`) and
has **no runtime dependencies**, so it vendors cleanly via `bundler-spinel`.
Critically, Spinel's whole-program type inference is keyed partly on **method
and parameter names** — a careless rename can silently corrupt a *consumer's*
compiled output even if SpinelKit is merely required. Every public name here is
preserved verbatim from its proven-green donor. See
[`docs/spinel-discipline.md`](docs/spinel-discipline.md).

## Status

Pre-alpha (`0.1.0`). The shims are implemented and CRuby-verified. Consumer
adoption is the next phase: because we author every repo in this set, tep and
toy **migrate to `SpinelKit::*` directly and delete their donor modules** — we
standardize and clean rather than leave compatibility aliases behind. The
bootstrap ships the *union* of both donors' surfaces so migration can start on
a stable API; converging the two leftover prefix/duplication artifacts is the
first follow-up (it depends on a Spinel inference fix — see
[`docs/adoption.md`](docs/adoption.md)). Tracking issue: toy#44.

## Development

```sh
rake test            # CRuby-side parity tests (never compiled)
rake rbs:validate    # syntax-check the advisory RBS in sig/
gem build spinel_kit.gemspec
```

MIT licensed.
