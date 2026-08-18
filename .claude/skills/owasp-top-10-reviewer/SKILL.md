---
name: owasp-top-10-reviewer
description: >-
  Review Ruby on Rails code for OWASP Top 10:2025 security issues and produce categorized,
  evidence-backed findings with severity and remediation. Use this whenever the user wants a
  security review, security-focused code review, OWASP review, vulnerability check, or "is this
  safe to merge" assessment of Rails/Ruby code — whether they point at a GitHub pull request
  (PR/diff mode) or a whole repository/directory (repo mode). Trigger even if they don't say
  "OWASP" — e.g. "check this PR for security problems", "audit this controller", "any
  vulnerabilities in this Rails app", "review before I ship". Combines Brakeman + bundler-audit
  static signal with code inspection mapped to the ten 2025 categories. Read-only: never edits
  application code.
compatibility: >-
  Ruby on Rails project. Brakeman and bundler-audit recommended for static signal (skill degrades
  gracefully to inspection-only if absent). PR mode uses the GitHub MCP server. Python 3 for the
  bundled scripts.
---

# OWASP Top 10:2025 Rails Reviewer

Security-focused code review for Rails, anchored to **OWASP Top 10:2025** (final, Jan 2026). It
finds issues, classifies each by OWASP category, assigns severity, and gives a concrete fix. It
does **not** modify code — it reviews and reports.

Two modes, auto-selected from what the user gives you:
- **PR mode** — a GitHub PR URL or "review this PR". Review the diff; post inline review comments
  + a summary via the GitHub MCP server. Fast, pre-merge gate.
- **Repo mode** — a repo path / "audit this app". Review the whole codebase; write a Markdown
  report. Broader, periodic sweep.

If it's ambiguous which mode, ask one question. If the user names both a PR and "the whole app",
default to PR mode and offer repo mode after.

## Before you start (both modes)

1. Read `references/owasp-top-10-2025-rails.md` in full — it is the substance of the review (the
   ten categories mapped to Rails manifestations, where to look, static signal, remediation).
2. Read `references/tooling.md` for how to run Brakeman/bundler-audit and map their output.
3. Load `data/owasp-top-10-2025-rails-rules.json` — the category spine, Brakeman warning-type mapping,
   grep cues, path exclusions, version-gated rules, and the subsystem index.
4. Read `references/rails-subsystems.md` — coverage for the Rails subsystems Brakeman/core review
   miss (multi-tenancy, ActiveStorage, ActiveJob, ActionMailer, ActionCable, caching, OAuth/SAML,
   API/Hotwire, git-history secrets). Used in Pass 2b.

Confirm the target is a Rails project (look for `Gemfile`, `config/application.rb`, `app/`). If
it isn't Rails, say so and offer a generic review instead of pretending Rails specificity.

## The review procedure

Run the same passes in both modes (version detection → static → inspection → subsystem sweep →
consolidate); only the input surface and output differ.

### Pass 0 — Detect versions (gates false-positive-prone rules)
Read the Ruby and Rails versions (from `Gemfile.lock`; `run_static.py` emits them and the
resulting `version_gate_notes`). Two rules are false positives on modern stacks and must be gated:
- **YAML.load** is safe by default on Psych 4 / Ruby ≥ 3.1 — only flag `YAML.unsafe_load` /
  `Marshal.load`, or `YAML.load` on Ruby < 3.1.
- **Open redirect** via `redirect_to(user_input)` is default-blocked on Rails ≥ 7.0 *new* apps;
  on upgraded apps confirm `config.action_controller.raise_on_open_redirects = true` before
  treating it as safe; on < 7.0 it's always a finding.
Do not report either without checking the version first.

### Pass 1 — Static signal (deterministic)
Run `scripts/run_static.py <repo_root>` (it wraps Brakeman + bundler-audit and normalizes output
into findings tagged with OWASP category). If the tools aren't installed, note it and continue
with inspection only — do not fail.
- Brakeman findings are mapped by **`warning_type`** (the documented, stable field — see
  tooling.md), not `check_name`. Anything unmapped lands in the `uncategorized` list — assign its
  category by inspection; never assume A05. **Confirm each finding at its `file:line` before
  reporting** — Brakeman has false positives. Drop confirmed-false ones.
- bundler-audit advisories → all A03, carrying criticality. If the run didn't update the advisory
  DB, treat results as possibly stale (the tool note says so) and re-run with `--update-advisories`
  where network allows.
- **PR mode static analysis needs the code on disk.** The GitHub MCP server reads files over the
  API — it does **not** give a working tree, and Brakeman/bundler-audit cannot scan through it. So
  in PR mode either (a) check out the PR head SHA locally (`git fetch` + checkout, or clone) and
  run the tools against that, then keep findings whose `file:line` falls within the diff's changed
  hunks (parse the PR patch for changed files + line ranges); or (b) if no local checkout is
  available, run **inspection-only** and state that clearly in the summary — do not imply tool
  coverage you didn't have. In **repo mode**, run against the checkout and keep all findings.

Exclude noise paths from inspection (the rules JSON lists them): `spec/`, `test/`, `vendor/`,
`node_modules/`, `tmp/`, `coverage/`, `db/schema.rb`. Do **not** exclude `db/seeds.rb` or
`config/**` — real secrets and misconfig live there.

### Pass 2 — Inspection & reasoning (the high-value pass)
Tools miss the most impactful issues. For each category, inspect the code the field guide points
to. Use the `grep_cues` in the rules JSON as leads, then reason in context — a cue is not a
finding. Prioritize the tool-blind categories, which are often the worst issues:
- **A01** missing authorization / IDOR / unscoped finds; unprotected admin mounts.
- **A06** insecure design: no rate limiting, client-trusted money/quantity, no lockout.
- **A07** auth logic: enumeration, session fixation, timing-unsafe compares, token handling.
- **A08** unverified webhooks; trust-bearing unsigned cookies.
- **A09** logging/alerting gaps; `filter_parameters` coverage.
- **A10** fail-open rescues and broad exception handling in security paths.

In **PR mode**, scope inspection to what the diff changes or touches — the auth path it modifies,
the query it adds, the endpoint it introduces — plus obvious adjacent risk the change creates. Do
not review the whole app in PR mode; keep it proportional to the change. In **repo mode**, sweep
category by category across the codebase.

### Pass 2b — Rails subsystem sweep (`references/rails-subsystems.md`)
The core pass covers the request cycle; this pass covers the subsystems it doesn't. Do it whenever
the code touches them (PR mode) or across the app (repo mode):
- **Multi-tenancy first** for any multi-tenant app — cross-tenant isolation is usually the highest
  real risk and is invisible to tools. Check tenant scoping on every tenant-owned query, that
  `default_scope` isn't the only control, `CurrentAttributes` reset, and tenant-keyed caches.
- **ActiveStorage** (remote-URL SSRF, content-type spoofing, direct-upload authz), **ActiveJob**
  (arg deserialization, SSRF in jobs, lost tenant scope), **ActionMailer** (header injection, PII
  in logs), **ActionCable** (channel authorization), **caching** (viewer/tenant-unkeyed fragments),
  **auth/federation** (OAuth `redirect_uri`/`state`/PKCE, SAML signature verification), **API/Hotwire**
  (`null_session` CSRF, nested-attributes mass assignment, Turbo broadcast leakage, over-broad
  serializers), and **git-history secrets** (out of tree → recommend gitleaks/trufflehog, don't
  claim tree-scan covers it).
These map onto the same A01–A10 categories; tag findings accordingly.

### Pass 3 — Consolidate
For each finding assign a **primary** OWASP category by root cause (note any secondary in the
body). Deduplicate where static + inspection found the same issue. Assign severity per the rubric
below. Sort by severity, then by category.

## Severity rubric

Severity is **reachability × impact**, not bug class. The same bug class ranges widely: an
*unauthenticated* SQLi over sensitive data is Critical; the identical pattern reachable only by a
vetted admin in an internal tool over non-sensitive data may be Medium. Before rating, establish:
(1) **who can reach the sink** — unauthenticated / any authenticated user / privileged only; and
(2) **what's exposed or achieved** — RCE, cross-tenant data, PII, or something minor.

| Severity | Meaning |
|---|---|
| **Critical** | Reachable by an unauthenticated or low-privilege attacker AND high impact — SQLi/RCE from user input, auth bypass, cross-tenant IDOR over sensitive data, fail-open authorization. Blocks merge. |
| **High** | Exploitable with modest constraints, or high impact behind authentication — stored XSS, SSRF with internal reach, missing authorization on a sensitive action, known-CVE gem with a public exploit. |
| **Medium** | Real weakness with limited reach or impact, or needs chaining — reflected XSS in a low-value view, weak crypto on non-critical data, missing rate limiting, an injection sink only privileged users reach. |
| **Low** | Hardening / defense-in-depth — missing security header, incomplete `filter_parameters`, verbose errors, minor config. |
| **Info** | Good-practice note or unconfirmed lead worth a manual look. |

State the reachability assumption in the finding (e.g. "assumes any logged-in user can hit this
action"). When reachability is uncertain, say what would confirm it rather than inflating or
dropping the finding.

## Output — PR mode

Use the GitHub MCP server (same tools as a standard PR review: read the PR, post line comments,
submit a review). For each confirmed finding, post an **inline review comment** on the offending
line:

```
🔒 [SEVERITY] A0X <Category> — <one-line issue>
<why it's exploitable / what an attacker does>
Fix: <concrete Rails remediation, ideally a corrected snippet>
```

Then post a **review summary** and set the review event:
- `REQUEST_CHANGES` if any Critical/High finding exists; otherwise `COMMENT`.
- Summary body:
  ```
  ## OWASP Top 10:2025 security review
  <N> findings: <c> Critical, <h> High, <m> Medium, <l> Low.
  | Severity | OWASP | Location | Issue |
  ...one row per finding...
  Tools: Brakeman <ran on checkout / not run — inspection only>, bundler-audit <ran / not run>.
  Scope: diff only. <If no local checkout: "Static analysis unavailable via MCP file reads —
  this review is inspection-only.">
  ```
Never post duplicate comments on re-review — read existing review comments first and only add new
findings. If nothing is found, submit a `COMMENT` review saying the diff is clean against the
Top 10:2025 with the scope noted.

## Output — repo mode

Run `scripts/render_report.py` (or write it directly) to produce `owasp-review-<date>.md`:

```
# OWASP Top 10:2025 Security Review — <repo> — <date>
## Summary
- Findings by severity: Critical <c> / High <h> / Medium <m> / Low <l> / Info <i>
- Findings by category: A01 <n> ... A10 <n>
- Tools: Brakeman <version/absent>, bundler-audit <version/absent>
## Findings
### [SEVERITY] A0X <Category> — <title>
- Location: `file:line`
- Issue: <what & why exploitable>
- Evidence: <snippet or tool ref>
- Fix: <remediation>
(one block per finding, sorted by severity)
## Recommended manual checks
<external checks from tooling.md that need a running instance: headers, TLS>
## Coverage notes
<Method and limits — be honest so a clean report isn't misread as a guarantee. State: which
categories were tool-checked vs inspected; that inspection is sampling, not exhaustive proof
(e.g. "access control reviewed across controllers by inspection; not a proof that every action
is authorized"); Ruby/Rails versions detected and which version-gated rules were applied;
anything skipped and why; external checks deferred to manual.>
```

A clean report means "no issues found at this coverage," never "no vulnerabilities exist." Say so.
Offer an HTML render only if asked.

## Guardrails

- **Read-only.** Never edit, refactor, or "fix" application code. Output is comments and reports.
  Remediations are shown as suggested snippets, not applied.
- **Confirm before reporting.** No raw tool dump. Every finding is verified in code with a
  `file:line` and a real fix. Better to drop an unconfirmable lead to Info than to cry wolf.
- **No secrets in output.** If you find a hardcoded secret, report its location and that it must
  be rotated — do not echo the secret value into a comment or report.
- **Proportional in PR mode.** Review the change, not the whole app. Don't block a PR on
  pre-existing issues it didn't introduce (mention them once as context, don't gate on them).
- **Stay in scope.** This is Top 10:2025 security review. For a full standards audit, point the
  user to an ASVS-style tool instead; for general code quality, a general reviewer.
- **Never claim completeness.** This is a static + inspection layer. It cannot see runtime behavior
  (DAST), cloud/IAM/container posture, or git history. Say "no issues found at this coverage," never
  "secure" or "100%." To put a real number on it, run the RailsGoat benchmark
  (`evals/benchmark.md` + `scripts/score_benchmark.py`) — it measures strong-tier recall and is
  explicit that it does not measure the subsystem/design tier. Strong security is the composition of
  layers (this skill + ASVS + DAST + cloud/secret-history/JS scanning), not any single tool.
