---
name: code-reviewer
description: >-
  Review Ruby on Rails code for correctness bugs and reuse/simplification/efficiency cleanups,
  checked against this project's own engineering rules (principles.md, code_style.md,
  testing.md) — the general code-quality counterpart to the security and performance review
  skills. Use this whenever the user wants a code review or PR review, asks "is this ready to
  merge" / "does this look right", wants correctness bugs found, wants redundant or
  overcomplicated code simplified, or points at a GitHub pull request, diff, or branch — even
  if they don't say "code review" explicitly, e.g. "can you look over this PR", "review my
  changes before I push", "can this be simplified". Supports effort levels (low/medium/high/max
  — reuses whatever level was last used if none is given) and, only when explicitly asked, can
  post findings as inline PR comments (--comment) or apply the fixes to the working tree
  (--fix); by default it is read-only. Do NOT use this for a security review — use
  owasp-top-10-reviewer or owasp-asvs-security — or a performance review — use
  performance-auditor; this skill defers to them for issues in their lane.
compatibility: >-
  Any Ruby on Rails project. PR mode uses the GitHub MCP server; --fix and confirming a finding
  against the actual file on disk (rather than just the diff patch) need a local checkout of the
  branch under review. Reads the target repo's own .claude/rules/*.md (principles.md,
  code_style.md, testing.md) as the source of truth for conventions when present; falls back to
  references/fallback-conventions.md otherwise.
---

# Code Reviewer

General-purpose Rails code review: **correctness bugs** and **reuse / simplification /
efficiency cleanups**, evaluated against this project's own rules rather than a generic style
guide. It is the sibling `owasp-top-10-reviewer` and `performance-auditor` explicitly point to
when they say "leave general correctness to a code-review skill" — this is that skill, and it
stays out of their lanes in return.

## Scope — read this before reviewing anything

Two finding categories only:

- **Correctness** — the code does the wrong thing: logic errors, wrong edge-case handling, race
  conditions, nil/type errors, broken Rails idioms (callback ordering, transaction boundaries,
  validation vs. DB-constraint mismatches), a test that doesn't actually test what it claims.
- **Cleanup** — reuse, simplification, and efficiency issues that don't change behavior but cost
  the codebase: duplicated logic that should collapse per `principles.md`'s DRY guidance (see
  "Rule source" below), an abstraction fighting Rails convention, a controller doing model work,
  a simplification that removes real complexity (not stylistic taste).

**Out of scope, always**: security (auth, injection, secrets, IDOR — `owasp-top-10-reviewer` /
`owasp-asvs-security`) and performance (N+1s, indexing, caching, scaling — `performance-auditor`).
If something in-diff is clearly in one of those lanes, note it in **one line** in the summary —
"flagged, not analyzed: possible IDOR at `app/controllers/orders_controller.rb:14` — run
owasp-top-10-reviewer" — and move on. Don't investigate it yourself; a shallow security/perf take
from the wrong tool is worse than a pointer to the right one.

**Also out of scope**: pure style/formatting RuboCop or ERB Lint already catch (indentation,
quote style, line length). `code_style.md` says style is enforced by tooling first — repeating
what a linter already flags wastes the reviewer's attention. Only raise a style-adjacent issue
when it reflects a real judgment call the linter can't make (a name that hides intent, a
Rails-convention violation, an abstraction in the wrong layer).

## Rule source — read this first, every time

Before reviewing, check whether the target repo has `.claude/rules/*.md` (from this same
`agentic-engineering` package, or an equivalent):

1. **If present**, read `principles.md` (always relevant) plus whichever of `code_style.md` and
   `testing.md` match the files in the diff (they carry `paths:` frontmatter — a controller
   change loads `code_style.md`, a spec change loads `testing.md`). These are the target repo's
   live, current rules — cite them by name in findings ("violates DRY per principles.md: this
   duplicates the pricing calc in `app/models/order.rb:40`, extract to a shared method").
   Skip `security.md` and `performance.md` — those belong to the sibling skills.
2. **If absent**, fall back to `references/fallback-conventions.md` — a condensed,
   framework-level version of the same principles (Convention over Configuration, DRY-after-two,
   SOLID-in-Rails-terms, tooling-first style) for repos that don't have the rules package
   installed. Say once in the summary that you're using the fallback baseline, not a
   project-specific one.

Never invent a rule that isn't in one of these two places — if something merely bothers you
stylistically and isn't in the rule source or a real correctness/DRY issue, leave it out.

## Effort levels

Controls **how much you report**, not how carefully you look — always read the full diff.

| Level | What gets reported |
|---|---|
| `low` | Correctness bugs only, Critical/High severity, confirmed (not "might be"). |
| `medium` (default) | + Medium-severity correctness bugs, + cleanup findings that cite a specific, confirmed rule violation. |
| `high` | + Low-severity correctness bugs, + cleanup findings that are a judgment call — label these `confidence: plausible` rather than `confirmed`. |
| `max` | Everything worth a second look, including speculative leads — always labeled with confidence so nothing uncertain is presented as settled. |

If the user doesn't specify a level, reuse the level they last asked for in this conversation;
if none was ever specified, default to `medium`. State the level you're using at the top of the
output. (For the deep multi-agent cloud tier — "ultra" — point the user at the built-in
`/code-review ultra`; this skill doesn't replicate that infrastructure.)

## Flags

- **`--comment`** — post findings as inline GitHub PR review comments instead of (or in addition
  to) printing them. Requires PR mode and the GitHub MCP server.
- **`--fix`** — after reporting, apply the fixes to the working tree. Requires a local checkout
  of the branch under review. **Never applied unless the user passes this flag or explicitly
  asks in words** — default behavior always shows the fix as a snippet/diff without touching
  files. When applying, edit one finding at a time and re-state what changed; don't batch
  unrelated fixes into one edit if they touch the same lines in conflicting ways.
- Neither flag: read-only report, which is the default and always safe to run.

## Pick the mode from the input

| The user gives you… | Mode |
|---|---|
| a GitHub PR URL or number | **PR mode** |
| "review my changes" / a branch name / nothing (uncommitted work) | **Diff mode** — `git diff` against the base branch, or working-tree diff if uncommitted |
| a whole repo/directory with no diff in mind | Not this skill's job — say so; this is a change reviewer, not a repo sweep (that's closer to `owasp-asvs-security`'s repo-mode shape, which this skill doesn't have) |

## Review procedure (both modes)

1. **Resolve scope.** PR mode: fetch the PR diff via the GitHub MCP server; if `--fix` or
   confirming a finding against the actual file needs a working tree, check out the PR head SHA
   locally (`git fetch` + checkout) and say so. Diff mode: `git diff <base>...` or the
   working-tree diff.
2. **Load rules.** Per "Rule source" above, scoped to the files actually touched.
3. **Read the whole diff, not just the additions.** A correctness bug is often visible only by
   comparing new code to what it replaced, or to a sibling method it should have matched.
4. **Correctness pass.** Walk each changed method/block and ask: what input breaks this? Check
   nil handling, off-by-one and boundary conditions, type coercion, transaction/callback
   ordering, timezone and float handling, whether a rescued exception can mask a real failure,
   and whether new/changed tests actually assert the behavior they claim to (see
   `references/rails-correctness-pitfalls.md` for the Rails-specific patterns in this category —
   read it before this pass).
5. **Cleanup pass.** Look for: logic duplicated elsewhere in the diff or nearby in the file
   (DRY, but only once a pattern repeats — see `principles.md`'s "duplicate twice before
   abstracting"); a controller/view carrying logic that belongs in the model or a service;
   dead code or now-unreachable branches the diff left behind; an abstraction that fights Rails
   convention instead of using it.
6. **Filter by effort level**, attach rule citations where applicable, and write the fix for
   each finding as a concrete snippet — not "consider refactoring," but the actual replacement
   code.
7. **Deduplicate and sort** by severity, then file.

## Finding format

````
[SEVERITY] Correctness | Cleanup — <one-line issue>
Location: file:line
Why: <what breaks, or what it costs — concrete, not vague>
Rule: <principles.md / code_style.md / testing.md citation, or "general correctness" if none applies>
Fix:
```ruby
<the actual replacement code>
```
Confidence: confirmed | plausible   (plausible only surfaces at high/max)
````

Severity: **Critical** (wrong behavior reachable in normal use / data corruption / will break
CI) → **High** (wrong behavior in a real but narrower path) → **Medium** (real bug or real
cleanup win, limited blast radius) → **Low** (minor correctness nit or small cleanup).

## Output — PR mode

Default: print the findings list plus a short summary (counts by severity, effort level used,
rule source used). With `--comment`, via the GitHub MCP server: first read the PR's existing
review comments so a re-review never posts a duplicate of a finding already there, then post
each new finding as an inline comment on its `file:line` in the finding format above, then
submit one review summary with `REQUEST_CHANGES` if any Critical/High correctness finding
exists, `COMMENT` otherwise. With `--fix`: apply after reporting, per the flag rules above.

## Output — diff mode

Print the findings list plus the same short summary. With `--fix`, apply directly to the
working tree, one finding at a time.

## Guardrails

- **Evidence or it didn't happen.** Every finding cites `file:line` and shows the actual
  problem code, not a paraphrase. If you can't point at the line, it isn't a finding yet.
- **Read-only unless asked.** No edits without `--fix`, ever — including "obvious" one-liners.
- **Proportional.** Review what the diff changes and what it makes reachable; don't relitigate
  pre-existing issues the change didn't introduce (mention once as context if severe, don't gate
  on them).
- **Stay in your lane.** One-line pointer for security/performance leads, not analysis — see
  Scope above.
- **Don't repeat the linter.** If RuboCop/ERB Lint would catch it, it's not a finding here.

## Reference files
- `references/rails-correctness-pitfalls.md` — the Rails-specific correctness bug catalog used
  in the correctness pass (step 4).
- `references/fallback-conventions.md` — condensed conventions used only when the target repo
  has no `.claude/rules/` installed.
