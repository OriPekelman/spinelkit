# spinelgems verification-request issues

Issues filed on `OriPekelman/spinelgems` as part of the gem-audit-first pass
(see [`gem-audit-first.md`](gem-audit-first.md)):
[#16](https://github.com/OriPekelman/spinelgems/issues/16) (hike re-verify),
[#17](https://github.com/OriPekelman/spinelgems/issues/17) (gitkite/git_manager
rubric), [#18](https://github.com/OriPekelman/spinelgems/issues/18) (oj
closure). Bodies below.

---

## 1. Re-verify `hike` at the current engine rev

**Title:** Re-verify `hike` — was `verified`@2183a92, now only `loaded`

**Body:**

`hike` (path search / `Trail#find`) is the one candidate that could let a
downstream consumer *reuse* a gem instead of hand-rolling path resolution
(tracking: SpinelKit / toy#44). It shows `verified` at engine rev `2183a92`
but only `loaded` at the current dominant rev — i.e. its require-only load
still matches CRuby, but no behaviour smoke has run at this rev.

- Gem: `hike` (latest 2.x)
- Current verdict: `loaded` (please confirm with `spinel-compat probe hike`)
- Ask: run a full `verify` so it returns to `verified` (or surfaces the
  regression).
- Proposed smoke: build a `Hike::Trail`, append two roots, assert
  `trail.find("x.rb")` resolves the same path under CRuby and Spinel; assert a
  miss returns `nil`/empty identically.

If it re-verifies, `SpinelKit::Path` becomes a reuse instead of an implement.

---

## 2. Rubric clarification: `gitkite` / `git_manager`

**Title:** Confirm `gitkite` / `git_manager` `clean` verdicts are load-path-terminal

**Body:**

For SpinelKit (toy#44) we decided to implement `.git/HEAD` provenance directly
rather than depend on a git gem, because the only non-rejected candidates sit
at the `clean` tier with unmet `needs:`. Before we lock that decision in, can
you confirm the `clean` verdict for `gitkite` and `git_manager` is
**load-path-terminal** (the `needs:<x>` cannot be satisfied by vendoring),
i.e. they will not advance to `loaded`/`verified` without upstream changes?

- Gems: `gitkite`, `git_manager`
- Current verdict: `clean` with `needs:` reasons (please paste the `reasons`
  array from the ledger)
- Ask: confirm terminal, or tell us what would unblock them.

This just makes the "implement, don't reuse" call catalog-blessed rather than
assumed.

---

## 3. (optional) `oj` closure

**Title:** Confirm `oj` `risky` is C-ext-terminal (no pure-Ruby path)

**Body:**

Closing the JSON-reuse question on the record for SpinelKit (toy#44). `json`
is cleanly rejected (C-ext + metaprogrammed fallback). `oj` shows `risky` —
can you confirm that's C-extension-terminal (the fast path is native, and the
`method_missing` mimic path Spinel degrades), so there is no pure-Ruby
configuration of `oj` that could reach `verified`?

- Gem: `oj`
- Current verdict: `risky`
- Ask: confirm terminal for our purposes, or point at a pure-Ruby mode we
  missed.
