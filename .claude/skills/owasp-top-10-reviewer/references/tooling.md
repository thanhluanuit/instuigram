# Static Tooling — Running & Mapping to OWASP Top 10:2025  (v2)

Two Rails-native tools provide deterministic signal; everything else is inspection.
`scripts/run_static.py` wraps both and normalizes output. This file documents the mapping so a
reviewer can also run the tools by hand.

## Critical correctness note (fixed in v2)

Brakeman's JSON has **two different name fields**:
- `warning_type` — the documented, stable, human-readable category (e.g. `"SQL Injection"`,
  `"Mass Assignment"`, `"Unsafe Redirects"`). **We map on this.**
- `check_name` — the internal UpperCamelCase check *class* name (e.g. `"SQL"`, `"Redirect"`),
  used by `--checks`/`--except`. Do **not** map on this; it's a different vocabulary and drifts.

The map below uses only warning types verified against Brakeman's warning-types documentation.
Any warning type not in the map is routed to an **uncategorized** list for inspection — it is
never silently assigned a category. (This is what makes a wrong rollup impossible: unknowns are
visible, not mislabeled.)

## Brakeman warning_type → OWASP 2025

| Brakeman warning_type | OWASP 2025 |
|---|---|
| Mass Assignment, Attribute Restriction | A01 Broken Access Control |
| Unscoped Find | A01 |
| Unsafe Redirects | A01 (open redirect — version-gated, see below) |
| Cross-Site Request Forgery | A01 |
| File Access, Path Traversal | A01 (also A05 for some sinks) |
| Default Routes | A02 Security Misconfiguration |
| Information Disclosure | A02 |
| Session Settings | A02 (also A08) |
| Unmaintained Dependencies | A03 Software Supply Chain |
| Weak Hash | A04 Cryptographic Failures |
| SSL Verification Bypass | A04 (also A02) |
| SQL Injection | A05 Injection |
| Cross Site Scripting, XSS (Content Tag), XSS (JSON) | A05 |
| Command Injection | A05 |
| Dangerous Evaluation, Dangerous Send | A05 |
| Dynamic Render Paths | A05 (also A01 if path is user-controlled) |
| Remote Code Execution | A05 |
| Format Validation | A05 (the `^ $` vs `\A \z` anchor bypass — also A07 on auth fields) |
| Mail Link | A05 (legacy mailto XSS CVE) |
| Denial of Service | A06 Insecure Design (resource exhaustion — no cleaner Top 10 home) |
| Authentication, Basic Authentication | A07 Authentication Failures |
| Unsafe Deserialization, Remote Execution in YAML.load | A08 Software/Data Integrity (also A05) |
| Session Manipulation | A08 (also A02) |
| Divide By Zero | A10 Mishandling of Exceptional Conditions |

**Not Brakeman warning types — do NOT expect them from the static map (inspection-only):**
CORS misconfiguration (A02), CSP/security headers (A02), SSRF (A01 — no stable documented
warning type), hardcoded secrets (A02/A04). The field guide covers these under inspection.

Run: `brakeman -q -f json --no-exit-on-warn --no-exit-on-error` (or `bundle exec brakeman …`).
**Confidence**: report High; verify Medium in code; treat Weak as a lead only. Brakeman has known
false positives — always confirm at the cited `file:line` before reporting.

## Version-gated rules (v2 — prevents false positives)

`run_static.py` detects Ruby/Rails versions from `Gemfile.lock` and emits `version_gate_notes`.
Apply them before reporting:
- **YAML.load** — safe (`safe_load`) by default on Psych 4 / **Ruby ≥ 3.1**. Only a finding on
  Ruby < 3.1, or when the call is `YAML.unsafe_load` / `Psych.unsafe_load` / `Marshal.load`.
- **Open redirect** — `redirect_to` of user input is default-blocked on **Rails ≥ 7.0 new apps**
  (`raise_on_open_redirects`). On upgraded apps it's only safe if that config is enabled; on
  Rails < 7.0 it's always a finding. Confirm the framework-defaults state before flagging.

## bundler-audit (dependency CVEs → A03)

Run: `bundle audit check --update` (updates ruby-advisory-db first). Text output; each advisory
gives gem, version, advisory ID (CVE/GHSA), criticality, title, solution. All advisories → **A03**,
carrying the advisory's criticality.
- **Stale-DB risk**: without `--update`, the DB may be old and silently under-report. The script
  flags this in `tools.bundler_audit.note`; run with `--update-advisories` where network allows.
- **Dedup**: bundler-audit and Brakeman's `Unmaintained Dependencies` can both fire on one gem —
  the script drops the Brakeman one and keeps the CVE.
- **Insecure source / unpatched**: advisories without a CVE (e.g. insecure gem source) are still
  captured, not dropped.

## Optional external checks (repo mode, running instance only)

Not run by the script (they need a live URL) — list them as recommended manual checks:
securityheaders.com (headers/CSP → A02), SSL Labs / testssl.sh (TLS → A04/A02).

## What tools do NOT catch (often the worst issues — inspect)

Missing authorization / policy layer (A01); IDOR via unscoped finds (A01); SSRF behind
indirection (A01); insecure design — rate limiting, client-trusted money/quantity, lockout (A06);
auth logic — enumeration, session fixation, timing-unsafe compares (A07); unverified webhooks
(A08); logging/alerting gaps (A09); fail-open rescues (A10).
