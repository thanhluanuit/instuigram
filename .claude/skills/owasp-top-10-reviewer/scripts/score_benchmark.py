#!/usr/bin/env python3
"""
score_benchmark.py — measure the skill's false-negative rate against a ground-truth set
(RailsGoat by default). Turns "coverage" from a claim into a number.

Usage:
    # Primary: you (or a harness) list which planted vulns the skill actually flagged.
    python3 score_benchmark.py --expected evals/railsgoat-expected.json \
        --detected results.json
    #   results.json:  {"detected": ["sql_injection", "mass_assignment", ...]}

    # Rough auto-estimate from a skill findings dump (category overlap — OVER-counts,
    # because a finding in category X is credited to every planted X). Use only as an upper bound.
    python3 score_benchmark.py --expected evals/railsgoat-expected.json \
        --findings owasp-findings.json --by-category

Output: overall + per-tier (must/should/may) + per-OWASP recall, and an explicit
false-negative list. A missed 'must' is a DEFECT; a missed 'should' is an inspection-pass gap;
a missed 'may' is a tracked limitation.
"""
import argparse
import json
import sys
from collections import defaultdict


def load(p):
    with open(p) as f:
        return json.load(f)


def pct(n, d):
    return f"{(100.0 * n / d):.0f}%" if d else "n/a"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--expected", required=True)
    ap.add_argument("--detected", help="JSON with {'detected': [vuln_id, ...]}")
    ap.add_argument("--findings", help="skill findings JSON (with findings[].category)")
    ap.add_argument("--by-category", action="store_true",
                    help="derive detection from findings by OWASP-category overlap (over-counts)")
    args = ap.parse_args()

    exp = load(args.expected)
    vulns = exp["vulns"]

    if args.detected:
        detected_ids = set(load(args.detected).get("detected", []))
    elif args.findings and args.by_category:
        cats = {f.get("category") for f in load(args.findings).get("findings", [])}
        # Credit a planted vuln if the skill produced ANY finding in its category (upper bound).
        detected_ids = {v["id"] for v in vulns if v["owasp_2025"] in cats}
        print("NOTE: --by-category is an UPPER BOUND (category presence != specific-bug detection).\n")
    else:
        ap.error("provide --detected results.json, or --findings ... --by-category")

    tiers = defaultdict(lambda: [0, 0])   # tier -> [hit, total]
    bycat = defaultdict(lambda: [0, 0])
    misses = []
    for v in vulns:
        hit = v["id"] in detected_ids
        tiers[v["expected"]][1] += 1
        bycat[v["owasp_2025"]][1] += 1
        if hit:
            tiers[v["expected"]][0] += 1
            bycat[v["owasp_2025"]][0] += 1
        else:
            misses.append(v)

    total_hit = sum(t[0] for t in tiers.values())
    total = len(vulns)

    print(f"=== RailsGoat strong-tier recall: {total_hit}/{total} ({pct(total_hit, total)}) ===")
    print("(strong-tier only — does NOT measure multi-tenancy/SSRF/webhooks/A10/logging)\n")

    print("By expectation tier:")
    for tier in ("must", "should", "may"):
        h, t = tiers[tier]
        label = {"must": "DEFECT if missed", "should": "inspection-gap if missed",
                 "may": "known limitation"}[tier]
        print(f"  {tier:<6} {h}/{t} ({pct(h, t)})  — {label}")

    print("\nBy OWASP 2025 category:")
    for cat in sorted(bycat):
        h, t = bycat[cat]
        print(f"  {cat}: {h}/{t} ({pct(h, t)})")

    if misses:
        print("\nFalse negatives:")
        for v in sorted(misses, key=lambda x: {"must": 0, "should": 1, "may": 2}[x["expected"]]):
            flag = {"must": "*** DEFECT", "should": "!! inspection gap",
                    "may": ".. limitation"}[v["expected"]]
            print(f"  {flag}: {v['id']} ({v['owasp_2025']}, {v['mechanism']}) — {v['desc']}")
    else:
        print("\nNo false negatives against this set.")

    # Non-zero exit if any 'must' was missed — usable as a CI gate on the skill itself.
    missed_must = [v for v in misses if v["expected"] == "must"]
    if missed_must:
        print(f"\nFAIL: {len(missed_must)} deterministic 'must' finding(s) missed.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
