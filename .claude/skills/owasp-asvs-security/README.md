# owasp-asvs-security

An agent skill that audits a codebase against **OWASP ASVS 4.0.3 Level 2**,
chapter by chapter, producing evidence-backed findings and a dashboard rollup —
without ever modifying the code it audits.

It ships the 259 Level-2 requirements as a pristine catalog and classifies each
one as **tool-checkable**, **code-inspection**, or **manual sign-off**, so the
agent knows when to run a scanner, when to read the code, and when to defer to a
human. Prior audit history accrues per-repo from your own earlier runs, so
re-audits surface regressions and confirmed fixes instead of starting over.

## Requirements

- **Python 3** (the tracking / report / tooling scripts).
- Reference stack is **Ruby on Rails + PostgreSQL**: the automated checks call
  [`brakeman`](https://brakemanscanner.org/) and
  [`bundler-audit`](https://github.com/rubysec/bundler-audit). When a tool is
  missing (or the target isn't a Rails app) the check reports `unavailable`/`error`
  and the audit continues via code inspection; see *Retargeting the stack* below.
  The HTTP `headers` and `tls` checks are stack-agnostic.

## Install

Copy this directory into your project (or a shared location) so an agent
harness that discovers skills can find it, e.g.:

```
your-repo/.claude/skills/owasp-asvs-security/
```

## Use

Ask your agent for a security audit — e.g. *"run an OWASP ASVS audit"*, *"audit
V2 authentication"*, or *"do the quarterly security review"*. The skill drives
the flow:

1. `track_audit.py init <run-date> <scope>` — start/resume a run (reports whether
   a prior baseline exists).
2. `list_requirements.py <section>` — pull a section's requirements + tiers
   (compact, so the whole catalog never loads into context).
3. Assess each section; record verdicts with `track_audit.py add-finding`.
4. `render_report.py <run-date>` — Markdown per chapter + `rollup.html` scorecard.
5. `track_audit.py promote <run-date>` — save this run as the baseline for next time.

Outputs land under `asvs-audit/` in the repo root:

| Path | Commit? | What |
|---|---|---|
| `asvs-audit/reports/<run-date>/` | yes | the deliverable (chapter reports + rollup) |
| `asvs-audit/baseline.json` | yes | carry-forward verdicts for the next audit |
| `asvs-audit/state/` | no (gitignore) | transient resume state |

## Retargeting the stack

Edit `scripts/run_tools.py` to swap the static-analysis and dependency-scan
commands (e.g. `semgrep`, `bandit`, `npm audit`, `pip-audit`) and adjust the
tool→chapter mapping in `references/owasp-asvs-context.md`. `data/tiering.json`
ships as a heuristic seed (`scripts/generate_tiering.py`) — refine its tiers by
hand as you audit; keep every `auto` signal equal to a `run_tools.py` subcommand.

## Version pinning

Pinned to ASVS **4.0.3** on purpose: stable requirement IDs keep carry-forward
history aligned from one audit to the next. Do not swap the catalog for another
ASVS version mid-run.

## Credit

ASVS requirement text © OWASP Foundation, licensed CC BY-SA 3.0.
