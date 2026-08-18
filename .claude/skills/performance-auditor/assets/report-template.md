# Performance Review — {{repo / PR / endpoint}}
_Scope: {{Mode A changes | Mode B full audit | Mode C: <path>}} · Date: {{date}}_

## Summary
| Severity | Count |
|---|---|
| Critical | {{n}} |
| High | {{n}} |
| Medium | {{n}} |
| Low | {{n}} |

By category: N+1 {{n}} · Index {{n}} · Caching {{n}} · Jobs {{n}} · Memory {{n}} · Views {{n}} · System {{n}}

One-paragraph verdict: {{the headline — the single biggest lever, and whether this ships/scales}}.

## Prioritized fix list (do these first)
Top items by impact-per-effort:
1. {{fix}} — {{expected win}} — verify by {{method}}
2. …
3. …

## Findings
Sorted by severity. Each finding:

### [{{SEVERITY}}] {{category}} — {{short title}}
- **Location:** {{file:line / config / endpoint}}
- **Pattern:** {{what was found}}
- **Impact:** {{why it's slow + where it bites: endpoint, request rate, data volume}}
- **Confidence:** {{confirmed | needs-measurement — and what would settle it}}
- **Fix:** {{specific change}}
- **Verify:** {{EXPLAIN plan change / query-count drop / pg_stat_statements delta / load-test}}

_(repeat per finding; group by category for a full audit)_

## Since last run (re-runs only)
_From `checkpoint.py diff`._
- **NEW:** {{findings not present last run}}
- **STILL_PRESENT:** {{carried over — not yet fixed}}
- **RESOLVED:** {{gone since last run — confirm fixed, not just moved}}

## Notes & deliberate skips
{{anything checked and intentionally not flagged, with the reason — so a re-review doesn't re-litigate it}}
