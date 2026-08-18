# OWASP ASVS Audit Context

Read this at the start of a run. It holds the reasoning behind the audit that the
procedure in SKILL.md depends on.

## What this audit is

A recurring security audit against **OWASP ASVS 4.0.3, Level 2** (259
requirements). Level 2 is a superset of Level 1, so auditing L2 covers L1.

The requirement catalog shipped in `data/asvs-4.0.3-l2.json` is the pristine
standard — no verdicts baked in. Prior audit history accrues **per-repo** from
your own earlier runs: each completed run is promoted to
`asvs-audit/baseline.json` (committed), and the next run carries those verdicts,
notes, and remediations forward. The first audit on a repo has no baseline.

## Version is pinned to 4.0.3 — do not upgrade mid-run

The catalog is pinned to ASVS 4.0.3 so requirement IDs stay stable and prior
audit history keyed to those IDs keeps carrying forward. Do not fetch "latest"
or swap the catalog for a different ASVS version inside an audit run.

## The three tiers (in data/tiering.json)

- **auto** — a tool or pattern check settles it; run the tool and interpret it.
- **inspect** — read the specific code path and reason about it.
- **manual** — process, architecture, or human judgment; not code-verifiable
  (e.g. secure SDLC, threat modeling, data-classification policy). Never guess a
  PASS — carry the prior answer forward for human sign-off, or flag
  `NEEDS_REVIEW` on a first audit.

The seed split is roughly 25 auto / 171 inspect / 63 manual. `tiering.json` ships
as a heuristic seed and is meant to be hand-corrected over successive audits;
once corrected, trust it over re-deriving tiers each run. The seed mis-tags some
rows (for instance, tagging an architecture requirement `auto` because it
mentions "TLS") — those corrections are exactly what the review pass is for.
Every `auto` signal is an exact `run_tools.py` subcommand (`grep-eval`,
`bundler-audit`, `headers`, `tls`); if a tool can't run, treat the item as
`inspect`.

## Tooling to chapter mapping (Rails + PostgreSQL reference stack)

- **Brakeman** (static analysis) — injection, XSS, mass assignment, redirects:
  much of V5 (Validation, Sanitization, Encoding).
- **bundler-audit + ruby-advisory-db** — dependency CVEs: V14.2.x.
- **SSL Labs** (`tls` check is a liveness/cert probe; use the site for the full
  grade) — V9.1.x / V9.2.x (Communication).
- **securityheaders.com** (`headers` check) — CSP/HSTS/etc: V14.4.x.
- **grep-eval** — dynamic execution: V5.2.4, V5.5.4.

On another stack, map the equivalent tools (e.g. `semgrep`/`bandit` for static
analysis, `npm audit`/`pip-audit` for dependencies) to the same chapters.

## Carrying skips and settled decisions forward

Where a prior run recorded a reasoned skip or an accepted risk, carry it forward;
only re-flag if the context changed. For example, a team might intentionally not
enforce a strict Content-Security-Policy because it broke a required third-party
script, mitigating XSS via input sanitization and dependency review instead.
Once that trade-off is documented in the baseline with its rationale, re-flagging
it every quarter is noise, not signal — surface it for re-confirmation only when
the surrounding code or risk changes.

## Attribution

OWASP ASVS requirement text is (c) OWASP Foundation, licensed CC BY-SA 3.0.
