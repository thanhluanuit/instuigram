#!/usr/bin/env python3
"""
runtime_evidence.py — turn a pg_stat_statements export into ranked performance evidence.

Static scanning finds *candidates*; this finds what actually happened, in production,
across every request — not one replayed page load. It ranks query shapes by total
execution time and by call count, and flags the shapes whose fingerprint says N+1.

pg_stat_statements is a PostgreSQL contrib module, so this needs no APM vendor and no
log capture. Enable it once:

    -- postgresql.conf:  shared_preload_libraries = 'pg_stat_statements'   (needs restart)
    CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

Then export the CSV this script reads:

    \\copy (SELECT query, calls, total_exec_time, mean_exec_time, rows
           FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 200)
      TO 'pg_stat.csv' WITH CSV HEADER;

On PostgreSQL 12 and earlier the columns are total_time / mean_time; both spellings
are accepted. Reset the counters with SELECT pg_stat_statements_reset() before a
measured window so the numbers describe that window and not all history.

Usage:
  runtime_evidence.py pgstat <path/to/pg_stat.csv> [--top 20]
                             [--nplus1-calls 1000] [--nplus1-mean-ms 5.0]

No third-party deps. Output is a plain-text report meant to be read into findings.
"""
import argparse
import csv
import re
import sys

WHITESPACE = re.compile(r"\s+")
# An N+1 seen from the database looks like a per-row lookup: equality on a primary key
# or a foreign key against a normalized $n placeholder. This is the shape Rails emits
# when it resolves an association one record at a time.
# The optional quotes matter — ActiveRecord quotes every identifier, so the predicate
# reads `"categories"."id" = $1`, and a pattern that only handles bare `id = $1` misses
# essentially every real Rails query.
PER_ROW_LOOKUP = re.compile(
    r'WHERE\b.*?(?:"?\w+"?\.)?"?(?:id|\w+_id)"?\s*=\s*\$\d+',
    re.IGNORECASE | re.DOTALL,
)
# A COUNT repeated per row is the counter_cache case, not the eager-load case, so the
# advice differs — see §8.1 in references/rails-antipatterns.md.
COUNT_QUERY = re.compile(r"\bCOUNT\s*\(", re.IGNORECASE)


def flatten(sql: str, width: int) -> str:
    return WHITESPACE.sub(" ", sql).strip()[:width]


def analyze_pgstat(path: str, top: int, nplus1_calls: int, nplus1_mean_ms: float) -> int:
    """Rank a pg_stat_statements CSV export and flag likely N+1 shapes."""
    try:
        with open(path, newline="", errors="replace") as fh:
            rows = list(csv.DictReader(fh))
    except FileNotFoundError:
        print(f"error: no such file: {path}", file=sys.stderr)
        return 2
    if not rows:
        print("Empty CSV.")
        return 0

    cols = {c.lower().strip(): c for c in rows[0].keys()}

    def col(*names):
        for n in names:
            if n in cols:
                return cols[n]
        return None

    q = col("query")
    total = col("total_exec_time", "total_time")
    calls = col("calls")
    mean = col("mean_exec_time", "mean_time")
    if not q or not total:
        print("CSV needs at least 'query' and 'total_exec_time' (or 'total_time') columns. "
              f"Found: {list(cols.values())}", file=sys.stderr)
        return 2

    def num(r, c):
        if not c:
            return 0.0
        try:
            return float(r.get(c, 0) or 0)
        except ValueError:
            return 0.0

    grand_total = sum(num(r, total) for r in rows) or 1.0

    # === Likely N+1 ===
    # Cheap per-call, run enormously often, filtering on an id/fk: that combination is a
    # per-row association load, not a deliberate query. Ranked by total time, because a
    # 0.2ms query called 900k times is the one actually costing you the database.
    if calls and mean:
        suspects = [
            r for r in rows
            if flatten(r[q], 400).upper().startswith("SELECT")
            and num(r, calls) >= nplus1_calls
            and num(r, mean) <= nplus1_mean_ms
            and PER_ROW_LOOKUP.search(r[q])
        ]
        suspects.sort(key=lambda r: -num(r, total))
        if suspects:
            print("=== LIKELY N+1 / per-row lookup "
                  f"(≥{nplus1_calls} calls, ≤{nplus1_mean_ms}ms each, filtering on an id) ===")
            print("Cheap per call, ruinous in aggregate — one of these is not a query you wrote,\n"
                  "it's a loop.\n")
            for r in suspects[:top]:
                kind = "repeated COUNT → counter_cache candidate (§8.1)" if COUNT_QUERY.search(r[q]) \
                    else "per-row association load → eager-load with includes/preload (§1.1)"
                print(f"  {int(num(r, calls)):>9}× · {num(r, mean):>7.2f}ms avg · "
                      f"{num(r, total):>11.1f}ms total ({num(r, total) / grand_total * 100:.1f}% of DB time)")
                print("      " + flatten(r[q], 200))
                print(f"      → {kind}")
            print("\n  Confirm the source: pg_stat_statements gives the query shape, not the app line.")
            print("  Locate the caller with scripts/scan.sh, Bullet in development, or by reading")
            print("  the action that renders this association — then prove the fix with an")
            print("  assert_queries assertion in a request spec.\n")

    # === Top by total time ===
    rows.sort(key=lambda r: -num(r, total))
    print(f"=== TOP QUERIES BY total_exec_time (from {path}) ===")
    print("These dominate DB time — a cheap query called millions of times outranks a rare slow one.\n")
    for r in rows[:top]:
        line = f"  {num(r, total):>12.1f}ms total ({num(r, total) / grand_total * 100:>4.1f}%)"
        if calls:
            line += f"  {int(num(r, calls)):>9}×"
        if mean:
            line += f"  {num(r, mean):>8.2f}ms avg"
        print(line)
        print("      " + flatten(r[q], 200))
    print()

    # === Top by call count ===
    if calls:
        rows.sort(key=lambda r: -num(r, calls))
        print("=== TOP QUERIES BY CALL COUNT (chattiness — where N+1s hide) ===")
        for r in rows[:top]:
            line = f"  {int(num(r, calls)):>9}×  {num(r, total):>11.1f}ms total"
            if mean:
                line += f"  {num(r, mean):>7.2f}ms avg"
            print(line)
            print("      " + flatten(r[q], 200))
        print()

    print("Next: EXPLAIN (ANALYZE, BUFFERS) the top offenders; look for Seq Scan / stale stats.")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    gp = sub.add_parser("pgstat", help="analyze a pg_stat_statements CSV export")
    gp.add_argument("path")
    gp.add_argument("--top", type=int, default=20)
    gp.add_argument("--nplus1-calls", type=int, default=1000,
                    help="minimum call count to consider a shape an N+1 suspect (default 1000)")
    gp.add_argument("--nplus1-mean-ms", type=float, default=5.0,
                    help="maximum mean ms for an N+1 suspect (default 5.0)")
    args = p.parse_args()
    return analyze_pgstat(args.path, args.top, args.nplus1_calls, args.nplus1_mean_ms)


if __name__ == "__main__":
    raise SystemExit(main())
