# Gem-audit-first methodology

**Rule: before implementing any SpinelKit lib, audit the
[spinelgems](../../spinelgems) catalog for an existing gem that already
provides the capability. Reusing a verified gem is always the biggest win.
Only implement when the catalog says nothing fit exists — and record why.**

This is not a one-time check. Every new surface added to SpinelKit must pass
through the same gate and append a row to the audit table below.

## How to query the catalog

The catalog is an append-only JSONL ledger keyed by gem name, with a verdict
ladder. Records live at `../../spinelgems/ledger/compat.jsonl`:

```
{"gem":"X","version":"1.2.3","rev":"git:8d88ebe/aarch64-linux-gnu",
 "verdict":"rejected|risky|clean|loaded|verified","reasons":[...],
 "risks":[...],"probe":"...","at":"..."}
```

| Verdict     | Meaning |
|-------------|---------|
| `verified`  | Full-surface compile + load + behaviour smoke matches CRuby. **Only tier to trust for production.** (~159 gems) |
| `loaded`    | Require-only differential load matches; logic untested. |
| `clean`     | Static lower bound — compiles; **no behaviour run**. Overstates compatibility. |
| `risky`     | Compiles but uses constructs Spinel degrades silently (`eval`, `define_method`, …). |
| `rejected`  | Doesn't compile, or a detected silent no-op/miscompile. `reasons` names the missing feature. |

Verdicts are scoped to an **engine revision** (the Spinel git SHA + platform).
A `rejected` is "rejected *as of this rev, because of these features*," never
forever — upgrading Spinel triggers an automatic re-probe.

Query examples:

```sh
LEDGER=../../spinelgems/ledger/compat.jsonl
grep '"verdict":"verified"' "$LEDGER" | jq -r '.gem'        # all verified
grep -E '"gem":"(json|oj|logger|rugged)"' "$LEDGER" | jq -c # specific gems
```

Human attestations (highest-trust, version-pinned) live separately in
`../../spinelgems/attestations.jsonl`.

## The audit (as of engine rev `git:8d88ebe`, aarch64-linux-gnu)

| SpinelKit surface | Candidate gems | Verdict | Decision | Notes |
|-------------------|----------------|---------|----------|-------|
| **Json** | `json` | rejected | **implement** | C-ext fast path + `define_method`/`class_eval` pure fallback — unlowerable. |
|          | `oj`, `yajl-ruby`, `multi_json` | risky / rejected | | All C-ext or thin wrappers thereof. |
| **Log**  | `logger` (stdlib) | rejected | **implement** | Metaprogrammed severity dispatch + formatter API; ~35 unresolved calls. |
| **Git**  | `rugged` | rejected | **implement** | libgit2 C bindings — needs `dlopen`. We read `.git/HEAD` as a plain file instead. |
|          | `gitkite`, `git_manager` | clean (unmet `needs:`) | | Only the cheap static tier; load-path-terminal, never behaviour-verified. |
| **Path** *(deferred)* | `hike` | verified@`2183a92`, only `loaded` now | **re-verify, then maybe reuse** | A path-*search* lib (Trail#find) — overkill for basename/join/expand. Filed a re-verify issue; revisit if it re-verifies. |
|          | `pathname` (stdlib) | rejected | | C-ext + eval. |
| **Bytes** *(deferred)* | `unicode_utils`, `utf8-cleaner` | clean only | **defer** | toy's actual need (`cp_to_utf8` + GPT-2 byte tables) is tokenizer-specific; no general reuse. |
| **SafeHash** | — | n/a | **document, don't implement** | Not a gem — a coding *pattern* (always `has_key?` before `Hash[]`, because Spinel returns `0` for a missing key). See [`spinel-discipline.md`](spinel-discipline.md). |

## Verification-request issues filed on spinelgems

Filed on `OriPekelman/spinelgems` (see [`spinelgems-issues.md`](spinelgems-issues.md)
for the exact bodies; issue numbers backfilled here once created):

1. **Re-verify `hike`** at the current engine rev — if it re-verifies,
   SpinelKit::Path becomes a *reuse* instead of an implement. → _#TBD_
2. **Rubric clarification: `gitkite` / `git_manager`** — confirm their `clean`
   verdict is load-path-terminal, so SpinelKit::Git's implement decision is
   catalog-blessed. → _#TBD_
3. *(optional)* **`oj` closure** — confirm `risky` is C-ext-terminal (no
   pure-Ruby path), closing the JSON-reuse question on the record. → _#TBD_

We did **not** file issues for `json`, `logger`, or `rugged`: their rejections
are unambiguous (C-ext / metaprogramming) and a re-probe wouldn't flip them.
