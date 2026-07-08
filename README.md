# SpinelKit

[![CI](https://github.com/OriPekelman/spinelkit/actions/workflows/ci.yml/badge.svg)](https://github.com/OriPekelman/spinelkit/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/spinel_kit)](https://rubygems.org/gems/spinel_kit)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-CC342D)
![Pure Ruby](https://img.shields.io/badge/native%20ext-none-brightgreen)

**The non-stdlib toolkit for Spinel-compiled apps.** A pure-Ruby, Spinel-safe
library holding the shims [Spinel](https://github.com/matz/spinel) (the
Ruby→native AOT compiler) does not provide and that every Spinel project
would otherwise hand-roll: **git provenance, URL percent-codec + query
parsing, a minimal levelled logger, and a hex codec**.
[toy](https://github.com/OriPekelman/toy) and
[tep](https://github.com/OriPekelman/tep) grew these independently — parts
came out *byte-identical* — and SpinelKit is that code, consolidated once.

## Where JSON went

SpinelKit began as "the stdlib-surface gem," and its founding surface was a
JSON codec. Spinel now **bundles `json` as a require-gated stdlib package** —
a typed native binding straight into the runtime's `sp_json.c` — so the
compiler provides the stdlib surface itself and `SpinelKit::Json` was retired
in 0.3.0 ([#3](https://github.com/OriPekelman/spinelkit/issues/3)). Migration:

```ruby
require "json"                        # bare stdlib require, no manifest entry

h = JSON.parse(body)
model      = h["model"].to_s          # coerce at the parse boundary and
max_tokens = h["max_tokens"].to_i     # everything downstream stays fully
temp       = h["temperature"].to_f    # specialized under whole-program
ids        = h["prompt"].map { |x| x.to_i }  # inference

JSON.generate({ "ok" => true, "n" => max_tokens })   # replaces the Builder
```

Coerce parsed values once at the boundary (`.to_s`/`.to_i`/`.to_f`/mapped
`.to_i`) — verified against spinel master: byte-identical CRuby parity, no
cross-degrade, and full re-typification with the coercions in place.

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
(verdict ladder: `verified > loaded > clean > risky > rejected`) for existing
gems to reuse — that would have been the biggest win. **There weren't any.**
These shims *are* the ecosystem's gaps:

| Surface | Catalog finding | Decision |
|---------|-----------------|----------|
| Log     | `logger` **rejected** (unresolved calls) | implement |
| Git     | `rugged` **rejected** (C); `gitkite`/`git_manager` only **clean**, unmet `needs:` | implement (read `.git/HEAD`) |
| Url/Hex | `CGI`/`URI` stdlib not lowered; no verified gem | implement |
| Path    | `hike` **verified** at an older rev, only **loaded** now; overkill for basename/join | deferred |
| Bytes   | `unicode_utils`/`utf8-cleaner` **clean** only; toy's need is tokenizer-specific | deferred |

See [`docs/gem-audit-first.md`](docs/gem-audit-first.md) for the full audit
(which also covers the since-retired JSON surface).

## What's in it

```ruby
require "spinel_kit"   # everything (CRuby / convenience)
```

For a **Spinel-compiled** consumer, require only the surface you use — Spinel
has no tree-shaking, so every loaded method is compiled (and an uncalled one
can degrade): `spinel_kit/hex`, `spinel_kit/url` (pulls in hex),
`spinel_kit/git`, `spinel_kit/log`.

- **`SpinelKit::Git`** — git provenance from `.git/HEAD`.

  ```ruby
  g = SpinelKit::Git.read
  g.sha          # => "a1b2c3..." (or "unknown" outside a repo)
  g.branch       # => "main"
  ```

- **`SpinelKit::Url`** — the `CGI`/`URI`-component surface:
  `escape`/`unescape` (RFC 3986 percent-codec), `parse_query`
  (form-urlencoded → Hash), `split_url` (scheme/host/port/path/query).

  ```ruby
  SpinelKit::Url.escape("a b&c")            # => "a%20b%26c"
  SpinelKit::Url.parse_query("x=1&y=z")     # => {"x"=>"1", "y"=>"z"}
  ```

- **`SpinelKit::Log`** — a minimal levelled logger (CRuby `Logger` doesn't
  compile under Spinel).

  ```ruby
  log = SpinelKit::Log.new
  log.set_level("info")
  log.info("server up")
  ```

- **`SpinelKit::Hex`** — hex digit/byte encode + decode (`nibble`,
  `nibble_char`, `byte2`, `to_int`); the shared surface `Url` builds on.

## Design constraints (read before editing)

SpinelKit is **pure Ruby, no native extension** (`spinel-ext.json` is `[]`) and
has **no runtime dependencies**, so it vendors cleanly via `bundler-spinel`. The
surface uses plain, standard names; the `j_`/`tj_`/`gi_` prefixes the donor
copies carried were a workaround for a Spinel whole-program-inference bug that
has since been fixed upstream (verified with toy's `gate-poly-degrade` on the
current compiler). See [`docs/spinel-discipline.md`](docs/spinel-discipline.md).

## Status

Pre-alpha (`0.3.0` — the JSON retirement). tep and toy migrated to
`SpinelKit::*` directly and deleted their donor modules (see
[`docs/adoption.md`](docs/adoption.md)); their JSON call sites migrate to the
bundled stdlib `json` next
([tep#217](https://github.com/OriPekelman/tep/issues/217),
[tep#213](https://github.com/OriPekelman/tep/issues/213)). The next shape
change is repackaging as a [spin](https://github.com/matz/spin-index) package
named `spinel_kit`, tracked in
[#3](https://github.com/OriPekelman/spinelkit/issues/3).

## Development

```sh
rake test            # CRuby-side parity tests (never compiled)
rake rbs:validate    # syntax-check the advisory RBS in sig/
gem build spinel_kit.gemspec
```

MIT licensed.
