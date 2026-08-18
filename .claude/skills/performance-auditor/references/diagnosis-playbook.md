# Diagnosis Playbook — the measure-first loop (Mode C)

Use this when the user says something is slow, or asks why. The goal is to turn "the page is
slow" into "*this query / method / asset* is the cause" **before** proposing a fix. Do not skip
to fixes.

## The loop
```
1. MEASURE   → what's slow, for whom, how slow? (metric + percentile)
2. REPRODUCE → recreate it at the right percentile / data volume
3. ISOLATE   → front-end or back-end? then to a specific query/method/asset
4. FIX       → the smallest change targeting the isolated cause
5. VERIFY    → measure the delta under the same conditions
6. GUARD     → add a budget/test so it can't silently regress
```
If you can't complete step 3, you are not ready to recommend a fix.

## Read the metric correctly
- **Percentiles, not averages.** Optimize the tail (p75 for Core Web Vitals, p95/p99 for SLA
  breaches). A 200ms average hides a 3s p95.
- **Lab vs field.** Lighthouse/PageSpeed = controlled, great for debugging. CrUX (real-user data
  from Chrome) = real users, the number that counts. Debug with lab, fix for field.

## Isolate: front-end or back-end?
Split on **TTFB** — the server's share of the wall clock — against total load time. Read both
from the DevTools Network panel (the first document request's timing breakdown), or get TTFB
alone without a browser:

```bash
curl -w 'dns %{time_namelookup}s · connect %{time_connect}s · ttfb %{time_starttransfer}s · total %{time_total}s\n' \
     -o /dev/null -s 'https://example.com/products'
```

High TTFB → back-end (§ back-end below). Low TTFB but slow LCP/INP/CLS → front-end. Don't open a
Ruby profiler for a JavaScript problem. (The "80% is front-end" rule of thumb is from 2007 and
assumes a static page — for a dynamic, logged-in application the back-end share is often much
larger. Measure your own split.)

## Back-end toolchain
- **pg_stat_statements** (production, and the first thing to ask for): ranks query shapes by
  `total_exec_time` across *all* traffic — it finds the query that's expensive *because it runs a
  million times*, which no single request trace reveals. It ships with PostgreSQL, so there's no
  vendor to buy and nothing to instrument in the app.
  ```sql
  -- one-time: shared_preload_libraries = 'pg_stat_statements' in postgresql.conf, then restart
  CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

  SELECT pg_stat_statements_reset();          -- start a clean measurement window
  -- ...let real traffic run...
  SELECT calls, mean_exec_time, total_exec_time, rows, query
  FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 20;
  ```
- **`scripts/runtime_evidence.py pgstat <file.csv>`**: feed it a CSV export of the above and it
  ranks by total time and by call count, and flags the shapes whose fingerprint says N+1 (many
  calls, cheap each, filtering on an id) — separating per-row association loads from repeated
  `COUNT`s, which need different fixes.
- **Do not rank from `log/development.log`.** One machine replaying traffic at toy data volume
  produces query counts and timings that don't generalize to production. Use it, at most, to
  eyeball a single request you're actively debugging — never as the evidence behind a finding.
- **rack-mini-profiler** (dev): per-request SQL count + timings; add `stackprof` for flamegraphs.
  This is the right tool for "which part of *this one request* is slow", where pg_stat answers
  "which query costs the most overall".
- **EXPLAIN (ANALYZE, BUFFERS)** on the suspect query. Read for:
  - **Seq Scan** on a large table → likely missing/unused index.
  - **estimated rows ≫/≪ actual** → stale planner stats → `ANALYZE <table>`.
  - **Nested Loop over many rows** → often an N+1 or a join that should be a hash join.
  - **high shared read / Buffers** → reading from disk, data/index cold or too big.
  - **index present but unused** → wrong column order, type mismatch, or low selectivity.
  Rails shortcut: `Relation.explain(:analyze, :buffers)` (Rails 7.1+).
- **Bullet** (dev): names the exact view line triggering an N+1 and what to `includes`.
- **stackprof / memory_profiler / derailed_benchmarks**: when the trace shows a big Ruby segment —
  CPU flamegraph, what allocated the objects, per-request allocations.

## Front-end toolchain
- **DevTools Performance panel:** record a load/interaction → find **Long Tasks** (>50ms, the INP
  killers), the **LCP element**, and layout-shift entries.
- **DevTools Coverage tab:** unused JS/CSS shipped on the page → code-split or defer.
- **Attribute the metric:** LCP → is the element render-blocked or a huge image? INP → which
  interaction's long task? CLS → which element shifted (reserve space)?
- **WebPageTest:** waterfall + filmstrip for network-shaped problems (render-blocking chains,
  missing preconnect, third-party scripts).

## Verify & guard (don't skip)
- **Verify** under the same conditions (same percentile, data volume, device/network). For prod
  changes, `pg_stat_statements_reset()` after deploy and compare the same query shape's `calls`
  and `total_exec_time` over a comparable window — same time of day, same traffic shape. Beware a
  "win" that's really just a warm cache, and beware comparing a quiet window to a busy one.
- **Guard:** a performance budget in CI (Lighthouse CI asserts LCP ≤ target), a query-count
  assertion in a request spec (`assert_queries(3) { get products_path }`), or an alert on the SLA
  metric. A win with no guard erodes within a few sprints.
