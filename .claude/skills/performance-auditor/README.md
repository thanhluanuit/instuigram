# performance-auditor

A Claude Code Agent Skill that reviews a **Rails/ActiveRecord + PostgreSQL** codebase or PR for
performance problems and produces evidence-backed findings — each with a severity, a concrete fix,
and a way to **verify** the win.

It is deliberately performance-only, so it doesn't collide with a general code reviewer or a
security audit. If it notices a correctness or security issue it notes it in one line and defers
to the right skill.

## Measure-first

The rule that governs the whole skill: **locate the bottleneck before prescribing a fix.** A
performance fix applied without knowing the real bottleneck is a guess that costs effort and adds
risk. Two consequences:

- **Static findings are hypotheses ranked by likely impact — not verdicts.** An N+1 on a rarely-hit
  admin page is real but Low; the same N+1 on the main listing page is Critical. Impact depends on
  traffic and data volume, which code alone can't show — so findings whose reach is unknown are
  marked `confidence: needs-measurement` rather than given a confident Critical.
- **Real runtime data beats any grep.** A `pg_stat_statements` export is the evidence to ask for
  first: it's a PostgreSQL contrib module, so there's no vendor to buy and nothing to instrument,
  and it aggregates *all* production traffic instead of one replayed request.
  `scripts/runtime_evidence.py` turns that export into queries ranked by total time and by call
  count, and flags the shapes whose fingerprint says N+1.
- **Not from application logs.** A dev or staging log is one machine's replayed traffic at toy
  data volume, so its query counts and timings don't generalize — ranking from one is how a
  measure-first review ends up confidently wrong.

## Three modes

The mode is resolved from the request and confirmed in one line before work starts.

- **A. Review changes** — a PR, diff, or branch ("check the perf impact before I merge"). Scans only
  the changed paths and flags only what *this change* introduces or worsens, not the codebase's
  existing debt.
- **B. Audit codebase** — a full audit. A checkpointed sweep through seven categories in
  impact-per-effort order (`N+1 → Index → Caching → Jobs → Memory → Views → System`), so a run that
  exceeds one context window can pause and resume. Re-runs diff against the previous run to show
  what regressed and what got fixed.
- **C. Diagnose a slow path** — "why is this slow", "will this scale". Runs the measure-first loop:
  reproduce → isolate → identify → fix → verify → guard. No fixes proposed before the bottleneck
  is isolated.

## Findings

Every finding carries eight fields, and `checkpoint.py` **rejects one that's missing any of them**
(exit 2, nothing recorded):

`category · location · pattern · impact · severity · confidence · fix · verify`

This is enforced in code rather than asked for in prose, because a finding without `verify` is a
claim nobody can check, and one without `impact` is a pattern name pretending to be a priority.
Severity is judged as **impact × reach**, not by how recognizable the anti-pattern is.

## Requirements

- A Ruby on Rails + PostgreSQL project. Pointed at another stack, the skill applies the
  query/caching/job/memory concepts and states plainly what doesn't transfer.
- **ripgrep** recommended for `scripts/scan.sh` (falls back to `grep`).
- **Python 3** for `runtime_evidence.py` and `checkpoint.py`. No third-party dependencies.
- Optional but strongly preferred: a `pg_stat_statements` CSV export from production. The module
  ships with PostgreSQL — enable it with `shared_preload_libraries = 'pg_stat_statements'` plus
  `CREATE EXTENSION pg_stat_statements`. `runtime_evidence.py --help` prints the export SQL.

## Usage

Run every command **from the target repo root** — `checkpoint.py` writes its state relative to the
working directory:

```bash
cd <target-repo-root>
SKILL_DIR=<path to this skill directory>

"$SKILL_DIR"/scripts/scan.sh app lib                                  # candidate scan
python3 "$SKILL_DIR"/scripts/runtime_evidence.py pgstat pg_stat.csv   # runtime evidence
python3 "$SKILL_DIR"/scripts/checkpoint.py init 2026-08-04 "full audit"   # ISO date, required
python3 "$SKILL_DIR"/scripts/checkpoint.py diff 2026-08-04
```

Export `pg_stat.csv` from the production database:

```sql
\copy (SELECT query, calls, total_exec_time, mean_exec_time, rows
       FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 200)
  TO 'pg_stat.csv' WITH CSV HEADER;
```

State and reports are written under `performance-review-report/` in the target repo — add it to
`.gitignore` if you don't want audit state committed.

## Layout

```
performance-auditor/
├── SKILL.md                          # modes, finding schema, severity rubric, guardrails
├── references/
│   ├── rails-antipatterns.md         # the ruleset: detection → cause → fix → caveats → verify
│   ├── system-architecture.md        # the System category: pool, replicas, backends, capacity
│   └── diagnosis-playbook.md         # the measure-first loop + profiling toolchain (Mode C)
├── scripts/
│   ├── scan.sh                       # 8-pattern high-signal candidate scan (ripgrep/grep)
│   ├── runtime_evidence.py           # pg_stat_statements → ranked queries + N+1 signatures
│   └── checkpoint.py                 # audit state, finding validation, run-over-run diff
├── assets/
│   └── report-template.md            # the report shape
└── evals/
    ├── evals.json                    # trigger/behaviour test prompts, one per mode
    └── fixtures/                     # runnable inputs: a planted mini Rails tree + pg_stat CSV
```

## Guarantees

**Read-only by default** — it never modifies application code, migrations, config, or dependencies
while reviewing. A reviewer that rewrites the code it reviews destroys the trust the review exists
to create, and ships a "fix" with no measured delta. Fixes are recorded as recommendations; one is
applied only when you explicitly ask, and then one at a time with a before/after measurement plan.
The only files the skill writes are under `performance-review-report/`.

Every scan hit is a **candidate**, not a finding — `scan.sh` says so in its own output, and each
hit is confirmed by reading the code before it's reported.
