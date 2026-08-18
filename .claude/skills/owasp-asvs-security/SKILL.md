---
name: owasp-asvs-security
description: Use when the user wants a security audit of a codebase against the OWASP ASVS 4.0.3 Level 2 standard - an ASVS audit or re-audit, a quarterly or periodic security review, a compliance check, a security-posture or risk assessment, pen-test preparation, or an audit of a specific ASVS chapter V1-V14 such as authentication, session management, access control, cryptography, input validation, output encoding, HTTP security headers, or configuration - even if they do not say the word "ASVS". Also use when the user mentions a security audit, ASVS, a quarterly security review, security compliance, or auditing auth, sessions, crypto, validation, or headers. Reference stack is Ruby on Rails; adaptable to other stacks.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# OWASP ASVS Security (Level 2, pinned to 4.0.3)

Audit the current repository against **OWASP ASVS 4.0.3 Level 2**. The 259
Level-2 requirements — pristine standard text, no results baked in — live in
`data/asvs-4.0.3-l2.json`. The per-requirement assessment strategy (auto /
inspect / manual) lives in `data/tiering.json`. Do not read those files whole;
pull just the section you are working on with `scripts/list_requirements.py`
(it joins the two and prints compact rows).

Prior audit history is **not shipped in this skill**. It accrues per-repo from
your own earlier runs: after each audit the findings are promoted to a baseline
(committed to the repo), and the next audit compares against it. The **first**
run on a repo has no baseline — everything is assessed fresh.

The baseline is resolved in this order: `$ASVS_BASELINE`, else
`asvs-audit/baseline.json` (the skill's flat format), else a single curated
`asvs-audit/baseline/*.json`. `prior` reads either the flat `{results:[…]}`
schema or a curated rich `{meta, requirements:[{…, prior:{…}}]}` one. When the
baseline is rich, `promote` **merges** each verdict additively under
`requirement.prior.automated` and never overwrites the human `l1`/`l2` notes;
otherwise it writes the flat findings.

At the start of every run, use the **Read tool** to load
`references/owasp-asvs-context.md` (located in this skill's directory, adjacent to
SKILL.md). It explains the version pinning, the tiering philosophy, the
tooling-to-chapter mapping, and how carry-forward and settled skips work.

## Requirements

Python 3 is required. This skill's tool layer targets a **Ruby on Rails** repo
(the auto-tier checks call `brakeman` and `bundler-audit`); on other stacks
those checks report `unavailable` and degrade gracefully — see Maintenance to
retarget them. The `headers` and `tls` checks are stack-agnostic.

## Read-only — this never changes application code

This is an audit. **Do not modify application code, configuration, migrations,
or dependencies.** Do not run generators, formatters, or auto-fixers. Security
tools run in report mode only (`brakeman`, `bundle-audit check` — never
`bundle update`, never `--fix`). The only files you may create or change are
under `asvs-audit/`. If a fix is obvious, record it as a remediation in the
report — never apply it. This matters because an auditor that edits the code it
audits destroys the trust the audit exists to create.

## Scope

Resolve the scope from the request, and confirm it in one line before starting:

- no scope, or "full audit" → walk all 14 chapters V1 → V14
- a chapter like "V2" → only Authentication
- a section like "V2.1" → only that section

## Procedure

Work **one section at a time, in tab order**, and **checkpoint after every
section** so a run can stop and resume across sittings. Auditing all 259 in one
pass is error-prone; a section (3-8 related requirements) is the unit that keeps
assessment accurate.

`<run-date>` is today's date in ISO form (`YYYY-MM-DD`) — use the same value for
every command in one run.

1. Initialise or resume the run:
   `python3 scripts/track_audit.py init <run-date> <scope>`
   It reports whether a prior baseline (`asvs-audit/baseline.json`) exists. If a
   run for today already exists, resume from its `progress.json` and skip
   sections already marked done.

2. Pull the section's requirements (do NOT read the whole catalog):
   `python3 scripts/list_requirements.py <section>` prints each requirement with
   its tier and text. Then assess each requirement by its tier:
   - **auto** — the row shows `[auto/<signal>]` where `<signal>` is the exact
     `run_tools.py` subcommand. Run `scripts/run_tools.py <signal> [url|host]`,
     interpret the output, decide. If a tool reports `unavailable`/`error`,
     treat the item as **inspect** instead.
   - **inspect** — locate and read the specific code path the requirement
     concerns (use Grep/Glob to find it, then Read it), reason, decide. For
     injection/XSS/mass-assignment classes, use Brakeman output as an assist,
     not a substitute.
   - **manual** — do NOT guess. If a prior baseline verdict exists, carry it
     forward (status `CARRY_FORWARD`, `needs_human: true`) and note what a human
     must re-confirm. On a first audit with no baseline, set status
     `NEEDS_REVIEW`, `needs_human: true`, and write what a human must confirm.

   If a prior baseline exists, compare each verdict against it
   (`python3 scripts/track_audit.py prior <req_id>` prints the prior record):
   - prior PASS and still holds → `PASS`
   - prior PASS but now broken → `REGRESSION` (a finding)
   - prior FAIL and remediation confirmed in code → `RESOLVED_CONFIRMED`
   - prior FAIL and still failing → `FAIL` (carry the prior remediation)
   - cannot determine from code → `NEEDS_REVIEW`

   On a first audit (no baseline), simply assess to `PASS` / `FAIL` /
   `NEEDS_REVIEW` on the evidence.

3. Record each verdict:
   `python3 scripts/track_audit.py add-finding <run-date> '<finding-json>'`
   (schema below).

4. Checkpoint the section:
   `python3 scripts/track_audit.py done-section <run-date> <section>`.

5. When every section in scope is done, render reports and promote the baseline:
   `python3 scripts/render_report.py <run-date>`
   → one Markdown report per chapter plus an HTML rollup under
   `asvs-audit/reports/<run-date>/`.
   `python3 scripts/track_audit.py promote <run-date>`
   → copies this run's findings to `asvs-audit/baseline.json` for next time.

## Paths & invocation

Scripts read `data/` relative to this skill folder (resolved via `__file__`).
Reports, state, and the promoted baseline are written under `asvs-audit/` in the
**repo root** (CWD).

Always invoke scripts from the **repo root**, using the full path to the skill's
scripts directory (adjust the prefix to wherever the skill is installed):

```bash
python3 .claude/skills/owasp-asvs-security/scripts/track_audit.py init 2025-07-28 all
python3 .claude/skills/owasp-asvs-security/scripts/run_tools.py brakeman
python3 .claude/skills/owasp-asvs-security/scripts/render_report.py 2025-07-28
```

## Git hygiene

- **Commit** `asvs-audit/reports/` — these are the deliverable.
- **Commit** `asvs-audit/baseline.json` — the carry-forward record for next run.
- **Gitignore** `asvs-audit/state/` — transient resume state, not needed in history.
  Add `asvs-audit/state/` to `.gitignore` if not already present.

## Finding record schema

```json
{
  "req_id": "V3.4.1", "chapter": "V3", "section": "V3.4",
  "tier": "auto", "status": "FAIL", "severity": "Medium",
  "evidence": "file:line / tool output / config observed",
  "remediation": "specific actionable fix",
  "needs_human": false, "owner": "suggested team/role"
}
```

Status vocabulary: `PASS` `FAIL` `REGRESSION` `RESOLVED_CONFIRMED`
`NEEDS_REVIEW` `CARRY_FORWARD`.
Severity (assign on FAIL / REGRESSION): `Critical` `High` `Medium` `Low`,
judged by exploitability x impact. Reuse a prior finding's severity unless the
situation changed.

## Assessment discipline

- **Evidence or it did not happen.** Every PASS/FAIL cites a file:line, a tool
  result, or the specific config observed. Never issue a verdict from assumption.
- **When unsure, NEEDS_REVIEW.** A false PASS is worse than an honest "needs a
  human". Do not inflate confidence.
- **Respect settled skips.** Where a prior run recorded a deliberate, reasoned
  skip (see `references/owasp-asvs-context.md`), carry the reason forward; only
  re-flag if the context changed.
- **Never fetch a newer ASVS version.** Pinned to 4.0.3 so requirement IDs stay
  aligned with prior audit history.

## Report shape

Each chapter report leads with findings (FAIL/REGRESSION/NEEDS_REVIEW, sorted by
severity), each with the ASVS reference, evidence, remediation, and suggested
owner; passing requirements are listed but collapsed. The `rollup.html`
aggregates the chapters in scope into a scorecard for leadership review.

## Example run (full audit)

```bash
# 1. Initialise (reports whether a prior baseline exists)
python3 .claude/skills/owasp-asvs-security/scripts/track_audit.py init 2025-07-28 all

# 2. (optional) Run automated tool checks upfront
python3 .claude/skills/owasp-asvs-security/scripts/run_tools.py all https://your-app.example.com

# 3. For each section — pull its requirements (compact, no whole-catalog read):
python3 .claude/skills/owasp-asvs-security/scripts/list_requirements.py V2.1

# ...then assess each requirement and record verdicts:
python3 .claude/skills/owasp-asvs-security/scripts/track_audit.py add-finding 2025-07-28 \
  '{"req_id":"V2.1.1","chapter":"V2","section":"V2.1","tier":"inspect","status":"PASS","severity":null,"evidence":"app/models/user.rb:15 — account lockout after 5 failed attempts","remediation":null,"needs_human":false,"owner":null}'

# 4. Checkpoint section as done:
python3 .claude/skills/owasp-asvs-security/scripts/track_audit.py done-section 2025-07-28 V2.1

# 5. When all sections complete — render reports and promote the baseline:
python3 .claude/skills/owasp-asvs-security/scripts/render_report.py 2025-07-28
python3 .claude/skills/owasp-asvs-security/scripts/track_audit.py promote 2025-07-28
```

## Maintenance

`data/tiering.json` ships as a heuristic seed from
`scripts/generate_tiering.py`; correct its tiers by hand as you run — that
accumulated hand-tuning is the durable asset. Every `auto` signal must stay an
exact `run_tools.py` subcommand. The auto-tier tools assume Rails + PostgreSQL; to
audit another stack, edit `scripts/run_tools.py` to swap the static-analysis and
dependency-scan commands (e.g. `semgrep`, `bandit`, `npm audit`,
`pip-audit`) — the `headers` and `tls` checks are already stack-agnostic.
