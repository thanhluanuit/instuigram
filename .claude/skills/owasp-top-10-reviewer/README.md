# owasp-top-10-reviewer

A Claude Code Agent Skill that reviews Ruby on Rails code against the **OWASP Top 10:2025** and
produces categorized, evidence-backed findings with severity and concrete remediations.

It sits between a generic code reviewer (too shallow on security) and a full ASVS audit (too
heavy for routine review): a focused, Top-10-scoped security pass structured around the ten 2025
categories.

## Two modes

- **PR mode** — give it a GitHub PR URL ("review this PR for security issues"). Reviews the diff,
  posts inline review comments + a summary via the GitHub MCP server, and requests changes if any
  Critical/High issue is present. Use as a pre-merge gate. Note: running the static tools in PR
  mode needs a local checkout of the PR branch (MCP file reads alone give no working tree); without
  one, PR mode runs inspection-only and says so.
- **Repo mode** — point it at a repo/directory ("audit this Rails app"). Sweeps the whole
  codebase and writes `owasp-review-<date>.md`. Use for periodic reviews.

The mode is auto-selected from the input (PR URL → PR mode; path → repo mode).

## How it works

Three passes:
1. **Static signal** — Brakeman (SAST) + bundler-audit (dependency CVEs), normalized and tagged
   to OWASP 2025 categories. Every tool signal is confirmed in code before it's reported.
2. **Inspection & reasoning** — the high-value pass for what tools can't see: missing
   authorization, IDOR, insecure design (rate limiting, client-trusted values), auth logic flaws,
   unverified webhooks, logging gaps, and fail-open exception handling.
3. **Consolidate** — one primary OWASP category per finding, severity by exploitability × impact,
   deduplicated and sorted.

## Anchoring

OWASP Top 10:2025 (final, Jan 2026). SSRF is folded into A01; A03 (Software Supply Chain Failures)
and A10 (Mishandling of Exceptional Conditions) are the 2025 additions.

## v2 corrections

- **Static mapping keyed on Brakeman `warning_type`** (documented, stable), not `check_name`;
  unmapped warnings surface as *uncategorized for inspection* instead of silently defaulting to a
  category. Fabricated check names removed; all 31 mappings verified against Brakeman's docs.
- **Version-gated rules** to kill false positives: `YAML.load` (safe by default on Psych 4 /
  Ruby ≥ 3.1) and open redirect (default-blocked on Rails ≥ 7.0). The runner detects Ruby/Rails
  from `Gemfile.lock` and emits guidance.
- **PR mode is honest about tooling** — declares inspection-only when no working tree is available.
- Grep cues made ripgrep-safe (no lookbehind; multiline cues flagged); noise paths excluded;
  LIKE-wildcard injection, the `^$`-anchor validation bypass, and deeper SSRF (resolve-and-pin)
  added; severity rubric now factors reachability.

## Requirements

- A Ruby on Rails project.
- **Brakeman** and **bundler-audit** recommended (`gem install brakeman bundler-audit`). The skill
  degrades to inspection-only if they're absent.
- **PR mode** needs the GitHub MCP server connected.
- Python 3 for the bundled scripts.

## Layout

```
owasp-top-10-reviewer/
├── SKILL.md                              # workflow, severity rubric, output contracts, guardrails
├── references/
│   ├── owasp-top-10-2025-rails.md        # the ten categories → Rails manifestations (the core)
│   ├── rails-subsystems.md               # multi-tenancy, ActiveStorage/Job/Mailer/Cable, caching, OAuth/SAML, Hotwire
│   └── tooling.md                        # Brakeman/bundler-audit run + warning_type mapping
├── data/
│   └── owasp-top-10-2025-rails-rules.json # category spine, warning_type map, cues, version gates, subsystem index
├── scripts/
│   ├── run_static.py                     # run tools → OWASP-tagged findings JSON (+ version detection)
│   ├── render_report.py                  # consolidated findings JSON → repo-mode Markdown report
│   └── score_benchmark.py                # RailsGoat false-negative / recall scorer
└── evals/
    ├── evals.json                        # trigger/behaviour test prompts
    ├── railsgoat-expected.json           # RailsGoat ground-truth vulns → OWASP 2025
    └── benchmark.md                       # how to measure coverage + honest interpretation
```

## Guarantees

Read-only — it never edits application code. Findings are comments and reports; remediations are
shown as suggested snippets, not applied. Secrets found are reported by location (and flagged for
rotation), never echoed.
