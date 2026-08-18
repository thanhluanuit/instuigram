# Measuring coverage — RailsGoat false-negative benchmark

Replaces "is it 100%?" with a number you can defend. Measures **recall** (false-negative rate)
against a ground-truth set of planted vulnerabilities.

## Run it

1. Clone the target: `git clone https://github.com/OWASP/railsgoat` (main = Rails 8; use a
   `git checkout rails_5` branch if you want the classic set). Its `spec/vulnerabilities/` is the
   ground truth encoded in `railsgoat-expected.json`.
2. Run the skill in **repo mode** against the checkout, producing an OWASP findings JSON.
3. From the report, list which planted vulns it actually caught into `results.json`:
   `{"detected": ["sql_injection", "mass_assignment", ...]}` (ids from `railsgoat-expected.json`).
4. Score:
   `python3 scripts/score_benchmark.py --expected evals/railsgoat-expected.json --detected results.json`
   The scorer exits non-zero if any deterministic **must** finding was missed — wire it as a CI
   gate on the skill itself so a regression in the static mapping fails the build.

A rough upper-bound estimate without hand-marking:
`python3 scripts/score_benchmark.py --expected ... --findings owasp-findings.json --by-category`
(credits any finding in a planted category — over-counts; treat as a ceiling, not the score.)

## Interpret it honestly

- **What a high score proves**: the strong tier works — injection, mass assignment, IDOR, known-CVE
  gems, open redirect. That's real and worth gating on (`must` = 100% or it's a defect).
- **What it does NOT prove**: RailsGoat plants none of the subsystem/design issues this skill was
  extended to cover — multi-tenant isolation, SSRF (request or job), ActiveStorage/ActiveJob,
  webhooks, exceptional-condition fail-open, logging/alerting. A 90% RailsGoat score says nothing
  about those. Report it as **"strong-tier recall,"** never as overall coverage.
- **RailsGoat is aligned to the 2013 Top 10** and is a teaching app — it's a floor for the classic
  surface, not a modern or exhaustive corpus.

## The rest of the coverage picture

To claim *strong* (not total) security for a real app, compose layers and measure each:
- This skill (fast, per-PR / repo, strong tier + inspected subsystems).
- **ASVS auditor** (your `owasp-asvs-auditor`) — completeness against L1→L3; express coverage as
  "% of ASVS L2 requirements with evidence."
- **DAST + pentest** — runtime, auth chains, business logic (undecidable statically).
- **Cloud/infra + container scanning** — AWS IAM/S3/RDS/SSM, base-image CVEs (outside any code review).
- **Secret-history scan** — `gitleaks` / `trufflehog` over git history (this skill scans the tree only).
- **JS/npm** — `npm audit` + DOM-XSS review for the frontend supply chain.

The skill is one measured layer. "Strong security" is the composition, not any single tool.
