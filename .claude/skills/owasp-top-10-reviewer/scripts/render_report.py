#!/usr/bin/env python3
"""
render_report.py — render a consolidated findings JSON into the repo-mode Markdown report
defined in SKILL.md.

The findings JSON is the reviewer's CONSOLIDATED output (static leads confirmed + inspection
findings), not the raw run_static.py dump. Expected shape:

{
  "repo": "name-or-path",
  "tools": {"brakeman": "3.x / absent", "bundler_audit": "0.9.x / absent"},
  "findings": [
    {"severity": "Critical|High|Medium|Low|Info",
     "category": "A01".."A10", "category_name": "...",
     "title": "...", "file": "app/...", "line": 42,
     "issue": "what & why exploitable", "evidence": "snippet or tool ref",
     "fix": "remediation", "secondary": "A08 (optional)"}
  ],
  "manual_checks": ["securityheaders.com ...", "SSL Labs ..."],
  "coverage_notes": "categories reviewed; anything skipped and why"
}

Usage:
    python3 render_report.py findings.json [--out owasp-review-<date>.md]
"""
import argparse
import datetime
import json
import sys
from collections import Counter, OrderedDict

SEV_ORDER = ["Critical", "High", "Medium", "Low", "Info"]
CATS = ["A01", "A02", "A03", "A04", "A05", "A06", "A07", "A08", "A09", "A10"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("findings_json")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()

    with open(args.findings_json) as f:
        data = json.load(f)

    repo = data.get("repo", "repository")
    date = datetime.date.today().isoformat()
    findings = data.get("findings", [])

    sev_counts = Counter(f.get("severity", "Info") for f in findings)
    cat_counts = Counter(f.get("category", "?") for f in findings)

    tools = data.get("tools", {})
    brakeman = tools.get("brakeman", "unknown")
    bundler = tools.get("bundler_audit", "unknown")

    lines = []
    lines.append(f"# OWASP Top 10:2025 Security Review — {repo} — {date}\n")

    lines.append("## Summary\n")
    sev_line = " / ".join(f"{s} {sev_counts.get(s, 0)}" for s in SEV_ORDER)
    lines.append(f"- Findings by severity: {sev_line}")
    cat_line = " · ".join(f"{c} {cat_counts.get(c, 0)}" for c in CATS if cat_counts.get(c, 0))
    lines.append(f"- Findings by category: {cat_line or 'none'}")
    lines.append(f"- Total findings: {len(findings)}")
    lines.append(f"- Tools: Brakeman {brakeman}, bundler-audit {bundler}\n")

    # Sort by severity then category.
    def sort_key(f):
        s = f.get("severity", "Info")
        return (SEV_ORDER.index(s) if s in SEV_ORDER else len(SEV_ORDER),
                f.get("category", "Z"))

    lines.append("## Findings\n")
    if not findings:
        lines.append("_No findings. Codebase is clean against the reviewed OWASP Top 10:2025 "
                     "categories at the stated coverage._\n")
    for f in sorted(findings, key=sort_key):
        sev = f.get("severity", "Info")
        cat = f.get("category", "?")
        cname = f.get("category_name", "")
        title = f.get("title", "").strip()
        loc = f.get("file", "")
        if f.get("line"):
            loc = f"{loc}:{f['line']}"
        lines.append(f"### [{sev}] {cat} {cname} — {title}")
        if loc:
            lines.append(f"- **Location:** `{loc}`")
        if f.get("secondary"):
            lines.append(f"- **Also relates to:** {f['secondary']}")
        if f.get("issue"):
            lines.append(f"- **Issue:** {f['issue']}")
        if f.get("evidence"):
            lines.append(f"- **Evidence:** {f['evidence']}")
        if f.get("fix"):
            lines.append(f"- **Fix:** {f['fix']}")
        lines.append("")

    manual = data.get("manual_checks", [])
    if manual:
        lines.append("## Recommended manual checks\n")
        lines.append("_Need a running instance; advisory, not findings._")
        for m in manual:
            lines.append(f"- {m}")
        lines.append("")

    if data.get("coverage_notes"):
        lines.append("## Coverage notes\n")
        lines.append(data["coverage_notes"] + "\n")

    report = "\n".join(lines)
    out = args.out or f"owasp-review-{date}.md"
    with open(out, "w") as fh:
        fh.write(report)
    print(f"wrote report to {out}", file=sys.stderr)


if __name__ == "__main__":
    main()
