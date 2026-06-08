# SpinelKit

[![CI](https://github.com/OriPekelman/spinelkit/actions/workflows/ci.yml/badge.svg)](https://github.com/OriPekelman/spinelkit/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/spinel_kit)](https://rubygems.org/gems/spinel_kit)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-CC342D)
![Pure Ruby](https://img.shields.io/badge/native%20ext-none-brightgreen)

**The Spinel stdlib-surface gem.** A pure-Ruby, Spinel-safe toolkit holding
the generic "stdlib substitute" shims that every Spinel-compiled project would
otherwise hand-roll.

[Spinel](https://github.com/matz/spinel) is a Ruby→native AOT compiler. It
cannot lower large chunks of the CRuby standard library — the `json` gem's
C-extension fast path and its metaprogrammed pure-Ruby fallback, stdlib
`Logger`, C-extension git bindings, and more. So every Spinel project re-derives
the same shims. [toy](https://github.com/OriPekelman/toy) and
[tep](https://github.com/OriPekelman/tep) grew theirs independently, and the
JSON escape/quote/hex code came out *byte-identical*. SpinelKit is that code,
consolidated once.

## Installation

```sh
gem install spinel_kit
```

Or in a Gemfile:

```ruby
gem "spinel_kit"
```

Pure Ruby, no native extension, no runtime dependencies — so it also vendors
cleanly into a Spinel build via [bundler-spinel](https://github.com/OriPekelman/spinelgems).

## Why a gem instead of reusing one?

The first thing we did was audit the
[spinelgems](https://github.com/OriPekelman/spinelgems) compatibility catalog
(verdict ladder: `verified > loaded > clean > risky > rejected`) for an existing
gem to reuse — that would have been the biggest win. **There wasn't one.** These
shims *are* the ecosystem's gaps:

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
require "spinel_kit"   # everything (CRuby / convenience)
```

For a **Spinel-compiled** consumer, require only the surface you use — Spinel
has no tree-shaking, so every loaded method is compiled (and an uncalled one
can degrade). The Json surface is split into three files for exactly this
reason: `spinel_kit/json` (encoders), `spinel_kit/json_decoder` (decoders), and
`spinel_kit/json_builder` (the builder). e.g. tep requires `json` + `json_decoder`;
toy requires `json_builder`.

- **`SpinelKit::Json`** — a JSON-over-HTTP codec: encoders
  (`escape`/`quote`/`encode_pair_*`/`from_*`, in `spinel_kit/json`) and flat-key
  decoders (`get_str`/`get_int`/`get_float`/`get_int_array`/`has_key?`, in
  `spinel_kit/json_decoder`).

  ```ruby
  SpinelKit::Json.get_int('{"age":33}', "age")             # => 33
  SpinelKit::Json.from_int_hash({"a" => 1, "b" => 2})      # => {"a":1,"b":2}
  ```

- **`SpinelKit::Json::Builder`** — an incremental ordered-object builder
  (`add_str`/`add_num`/`add_bool`/`add_raw`/`add_obj`/`dump`), in its own file
  so a builder-only consumer never compiles the codec, and vice versa.

  ```ruby
  j = SpinelKit::Json::Builder.new
  j.add_str("kind", "run_start")
  j.add_num("t", 1715000000)
  j.dump                                     # => {"kind":"run_start","t":1715000000}
  ```

- **`SpinelKit::Git`** — git provenance from `.git/HEAD`.

  ```ruby
  g = SpinelKit::Git.read
  g.sha          # => "a1b2c3..." (or "unknown" outside a repo)
  g.branch       # => "main"
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
has **no runtime dependencies**, so it vendors cleanly via `bundler-spinel`. The
surface uses plain, standard names; the `j_`/`tj_`/`gi_` prefixes the donor
copies carried were a workaround for a Spinel whole-program-inference bug that
has since been fixed upstream (verified with toy's `gate-poly-degrade` on the
current compiler). One numeric caveat remains for `add_num` — see
[`docs/spinel-discipline.md`](docs/spinel-discipline.md).

## Status

Pre-alpha (`0.1.0`). The shims are implemented, CRuby-verified, and the surface
is the single canonical one (the donor prefixes and duplicated escapers are
gone — the Spinel inference bug that motivated them is fixed). Consumer adoption
is the next phase: because we author every repo in this set, tep and toy
**migrate to `SpinelKit::*` directly and delete their donor modules** — we
standardize and clean rather than leave compatibility aliases behind. See
[`docs/adoption.md`](docs/adoption.md). Tracking issue:
[OriPekelman/toy#44](https://github.com/OriPekelman/toy/issues/44).

## Development

```sh
rake test            # CRuby-side parity tests (never compiled)
rake rbs:validate    # syntax-check the advisory RBS in sig/
gem build spinel_kit.gemspec
```

MIT licensed.
