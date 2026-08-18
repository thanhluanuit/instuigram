---
name: performance-auditor
description: Review a Rails/ActiveRecord + PostgreSQL codebase or PR for PERFORMANCE problems — N+1 queries, slow or unindexed queries, missing or broken caching, memory bloat, background-job latency, and system/scaling limits — producing evidence-backed findings each with a severity, a concrete fix, and a way to verify it. Use this whenever the user asks for a performance review or perf audit, asks "why is this slow" or "will this scale", wants to find N+1s or missing indexes, or wants to speed up an endpoint — even if they don't say the word "performance". This skill is performance-only; leave general code correctness to a code-review skill and security to a security-audit skill. It follows a measure-first method — locating the real bottleneck from pg_stat_statements, EXPLAIN plans, or profiling before recommending a fix — and by default never modifies application code.
compatibility: Rails/ActiveRecord + PostgreSQL, assumed throughout. Needs ripgrep (rg, falls back to grep) for scripts/scan.sh and Python 3.6+ for scripts/runtime_evidence.py and scripts/checkpoint.py. The optional runtime input is a pg_stat_statements CSV export, used when the user provides one.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# Performance Auditor

Review a Rails app for performance problems and produce evidence-backed findings, each
with a concrete fix and a way to **verify** the win. The target is **Rails/ActiveRecord +
PostgreSQL** — that assumption runs through the whole skill.

## Measure-first — the rule that governs this skill

A performance "fix" applied without knowing the real bottleneck is a guess, and guesses
waste effort and add risk. So this skill **locates the bottleneck before prescribing a
fix**, and every finding states how to *prove* the fix worked. Two consequences:

- **Static findings are hypotheses ranked by likely impact — not verdicts.** An N+1 on a
  rarely-hit admin page is real but low-priority; the same N+1 on the main listing page is
  Critical. Impact depends on traffic and data volume, which code alone can't show. Say so,
  and set `confidence: needs-measurement` when reach is unknown.
- **Prefer real runtime data when it exists.** A `pg_stat_statements` export is stronger
  evidence than any grep, and it is the measurement to ask for first: it is a PostgreSQL
  contrib module, so it needs no vendor and no paid tooling, and it covers *all* production
  traffic rather than one replayed request. `scripts/runtime_evidence.py` turns that export
  into ranked queries and N+1 signatures — reach for it before guessing. `EXPLAIN (ANALYZE,
  BUFFERS)` is the follow-up on any single suspect query. Full toolchain in
  `references/diagnosis-playbook.md`.
- **Don't audit from application logs.** A dev or staging log reflects one machine's replayed
  traffic at toy data volume, so its query counts and timings don't generalize — and treating
  them as production evidence is how a measure-first review ends up confidently wrong. Rank
  from `pg_stat_statements`, which aggregates real traffic across every request.

## Read-only by default — this reviews, it does not refactor

Do **not** modify application code, migrations, config, or dependencies while reviewing.
Record each fix as a recommendation. A reviewer that rewrites the code it reviews destroys
the trust the review exists to create — and ships a "fix" with no measured delta. Apply a
change only when the user explicitly asks, and then **one at a time, with a before/after
measurement plan** — never a batch of edits. The only files this skill writes are under
`performance-review-report/` (state and reports).

## Relationship to the sibling review skills

This skill is **performance-only** and deliberately narrow so it doesn't collide with:
- general correctness / style review → the code-review skill,
- security → the OWASP / ASVS skills.
If a review surfaces a security or correctness issue, note it in one line and defer to the
right skill rather than expanding scope here.

## Running the scripts

**Run every command from the target repo root**, invoking scripts by their path inside this
skill directory — `checkpoint.py` writes `performance-review-report/` relative to the working directory, so
the working directory must be the repo, not the skill. Set `SKILL_DIR` once:

```bash
cd <target-repo-root>
SKILL_DIR=<absolute path to this skill directory>
"$SKILL_DIR"/scripts/scan.sh app lib
python3 "$SKILL_DIR"/scripts/runtime_evidence.py pgstat pg_stat.csv
python3 "$SKILL_DIR"/scripts/checkpoint.py status <run-date>
```

Use `python3`, not `python` — `python` is absent on macOS and most modern setups.
`scan.sh` prefers ripgrep and falls back to grep. The commands below are written
against `$SKILL_DIR`.

To get `pg_stat.csv`, ask the user to export it from the production database (the module
is PostgreSQL contrib; `runtime_evidence.py --help` prints the enable + export SQL):

```sql
\copy (SELECT query, calls, total_exec_time, mean_exec_time, rows
       FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 200)
  TO 'pg_stat.csv' WITH CSV HEADER;
```

State and reports land in `performance-review-report/` inside the target repo. Mention once
that it can be added to `.gitignore` if the user doesn't want audit state committed.

## Pick the mode from the request

| The user… | Mode | Where the work is |
|---|---|---|
| gives a PR, diff, branch, or "review before I merge" | **A. Review changes** | changed files only |
| wants a full "performance audit" of the app | **B. Audit codebase** | systematic, checkpointed sweep |
| says "X is slow", "why is this slow", "will this scale" | **C. Diagnose a slow path** | measure-first loop on one path |

Confirm the resolved scope in one line before starting.

### Mode A — Review changes
1. Get the changed files (`git diff --name-only <base>...`, or the provided diff).
2. Run `"$SKILL_DIR"/scripts/scan.sh <changed-paths>` to surface high-signal candidates.
3. Assess each candidate and each changed query/view/job against
   `references/rails-antipatterns.md`. Confirm by reading the code — a scan hit is a
   candidate, not a finding.
4. Confirm a suspected N+1 the way the change itself can prove it: an `assert_queries`
   assertion in a request spec for the touched endpoint, or Bullet in development. If the
   change touches a query on a large table, ask for `EXPLAIN (ANALYZE, BUFFERS)` output.
5. Flag only what *this change* introduces or worsens — not the whole codebase's debt.

### Mode B — Audit codebase (checkpointed + carry-forward)
Long audits exceed one context window and are most valuable on re-runs, so use the state
scripts:

1. `python3 "$SKILL_DIR"/scripts/checkpoint.py init <run-date> "<scope>"` — starts or resumes, and loads
   the previous run's findings for regression tracking. **`<run-date>` must be ISO `YYYY-MM-DD`**
   — runs are ordered by string comparison, so any other format picks the wrong prior run and
   silently produces a meaningless diff.
2. Seed candidates: `"$SKILL_DIR"/scripts/scan.sh app lib`, and `runtime_evidence.py pgstat`
   if a pg_stat_statements export is available — ask for one before falling back to static
   evidence alone.
3. Work **one category at a time, in this order** (roughly impact-per-effort), recording
   findings as you go and marking each category done so a run can pause and resume:
   `N+1 → Index → Caching → Jobs → Memory → Views → System`
   - `python3 "$SKILL_DIR"/scripts/checkpoint.py add-finding <run-date> '<finding-json>'`
   - `python3 "$SKILL_DIR"/scripts/checkpoint.py done-category <run-date> <category>`
   - Query/caching/job/index depth is in `references/rails-antipatterns.md`; the `System`
     category is in `references/system-architecture.md`.
4. When all categories are done, render the report from `assets/report-template.md`, and run
   `python3 "$SKILL_DIR"/scripts/checkpoint.py diff <run-date>` to surface NEW / STILL_PRESENT / RESOLVED
   since the last run.

State and reports are written under `performance-review-report/` in the target repo.

### Mode C — Diagnose a slow path
Follow the measure-first loop in `references/diagnosis-playbook.md`: reproduce → isolate
(front-end vs back-end, then to a query/method/asset) → identify → fix → verify → guard.
Do not propose fixes before the bottleneck is isolated. Fastest routes to the true cause:
`scripts/runtime_evidence.py pgstat` on a `pg_stat_statements` export to find which query
shape owns the time, then `EXPLAIN (ANALYZE, BUFFERS)` on that query, and
`rack-mini-profiler`/`stackprof` in development when the cost turns out to be Ruby rather
than SQL.

## Finding record schema

```json
{
  "category": "N+1 | Index | Caching | Jobs | Memory | Views | System",
  "location": "app/models/product.rb:42  (or a config file, or an endpoint)",
  "pattern": "what was found, quoted or paraphrased tightly",
  "impact": "why it's slow AND where it bites — endpoint, request rate, data volume",
  "severity": "Critical | High | Medium | Low",
  "confidence": "confirmed | needs-measurement",
  "fix": "the specific change (code, index, config)",
  "verify": "how to prove the win — EXPLAIN plan change, query-count drop, pg_stat delta"
}
```

**All eight fields are required, and `checkpoint.py add-finding` rejects a finding that is
missing any of them** (exit 2, nothing recorded). This is deliberate: a finding without
`verify` is a claim nobody can check, and one without `impact` is a pattern name pretending
to be a priority. If you can't fill a field, you don't yet have a finding — go get the
evidence, or record it at a lower severity with `confidence: needs-measurement`.

When a finding's `pattern` or `fix` contains quotes, pipe it in instead of fighting shell
escaping: `... | python3 "$SKILL_DIR"/scripts/checkpoint.py add-finding <run-date> -`

**Worked example** (code → finding → verify):

```ruby
# app/views/products/index.html.erb
<% @products.each do |product| %>
  <%= product.category.name %>   <%# category loaded per row → N+1 %>
<% end %>
# app/controllers/products_controller.rb
@products = Product.where(status: "active").limit(25)   # no eager load
```
```json
{
  "category": "N+1",
  "location": "app/controllers/products_controller.rb:8 (rendered by products/index)",
  "pattern": "@products iterated in the view calling product.category without eager loading",
  "impact": "26 queries for a 25-row listing; the product index is the highest-traffic page",
  "severity": "Critical",
  "confidence": "confirmed",
  "fix": "Product.where(status: 'active').includes(:category).limit(25)",
  "verify": "assert_queries(2) { get products_path } in a request spec; after deploy, pg_stat_statements_reset() then confirm the categories-by-id shape's calls fall by ~25× per index request"
}
```

## Severity — impact × reach, not pattern name

Judge by **how much time it costs × how often that path runs**:
- **Critical** — measurably dominates a high-traffic path (N+1 on the main listing page; a
  Seq Scan on `products` in the hot search path).
- **High** — significant cost on a common path, or a clear scaling cliff (deep-offset
  pagination, a sync external call in a controller).
- **Medium** — real waste on a moderate path, or latent risk under growth.
- **Low** — minor or rarely-hit (an N+1 on an admin-only page; a micro-optimization).

If reach is unknown from code, set `confidence: needs-measurement`, give a provisional
severity, and state the measurement that would settle it. **Do not inflate confidence** — an
honest "needs measurement" beats a false Critical.

## Report shape

Fill `assets/report-template.md`: a summary table (counts by severity + category), then
findings sorted by severity — each with location, impact, fix, and verify — then a
**prioritized fix list** (top 5 by impact-per-effort). For a re-run, include the
`checkpoint.py diff` (NEW / STILL_PRESENT / RESOLVED).

## Assessment discipline

- **Evidence or it didn't happen.** Every finding cites a file:line, a query plan, or an
  observed metric. No verdicts from assumption.
- **Rank by impact, not by how easy the pattern is to spot.** The biggest win is usually a
  boring query on a hot path, not the clever refactor.
- **Fix the cause, not the symptom.** Don't recommend caching to paper over an unindexed
  query — fix the query, then cache if still needed.
- **Every fix carries a trade-off note where one exists** (see the caveats in
  `references/rails-antipatterns.md`) — a fix that adds write contention or changes ordering
  is not free.
- **Other stacks:** this skill assumes Rails + PostgreSQL. If pointed at another stack, apply
  the query/caching/job/memory/system *concepts* and state plainly what doesn't transfer —
  don't pretend the ActiveRecord- and Postgres-specific tooling applies.

## Reference files
- `references/rails-antipatterns.md` — the ruleset with detection, cause, fix, caveats, verify.
- `references/system-architecture.md` — the `system` category (pool, replicas, backends, capacity).
- `references/diagnosis-playbook.md` — the measure-first loop and profiling toolchain (Mode C).
