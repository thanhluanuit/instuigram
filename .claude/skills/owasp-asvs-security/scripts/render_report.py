#!/usr/bin/env python3
"""
Render audit reports from a run's findings.json.

Writes to  asvs-audit/reports/<run-date>/ :
  V1.md ... V14.md   - one per chapter touched (findings first, passes collapsed)
  V1.html ... V14.html - browser-friendly chapter reports, linked from the rollup
  rollup.html        - 14-chapter scorecard (mirrors the workbook Dashboard);
                       each chapter row links to its V<n>.html report

Usage:  python3 scripts/render_report.py <run-date>
Run from the repo root. Reads the pinned requirement catalog from the skill's
data/ dir (for section names and descriptions); the run's verdicts come from
asvs-audit/state/<run-date>/findings.json.
"""
import html
import json
import os
import sys
from datetime import date, datetime

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(HERE, "data", "asvs-4.0.3-l2.json")

SEV_ORDER = {"Critical": 0, "High": 1, "Medium": 2, "Low": 3, None: 4}
# Actionable findings only. NEEDS_REVIEW / CARRY_FORWARD / needs_human land in
# the review bucket instead — see bucketize() — so nothing is counted twice.
FINDING_STATUSES = {"FAIL", "REGRESSION"}
# Which chip/badge kind a severity maps to in the HTML.
SEV_KIND = {"Critical": "bad", "High": "bad", "Medium": "warn",
            "Low": "muted", None: "muted"}
CHAPTER_NAMES = {}  # filled from the catalog


def esc(s):
    """HTML-escape any value (evidence/remediation text may contain <, >, &, quotes)."""
    return html.escape("" if s is None else str(s))


def load():
    with open(CATALOG, encoding="utf-8") as f:
        doc = json.load(f)
    for r in doc["requirements"]:
        CHAPTER_NAMES[r["chapter"]] = r["chapter_name"]
    return doc


def bucketize(results):
    """Partition a chapter's results into mutually exclusive buckets so the
    chapter report and the rollup scorecard always agree and never double-count.
    An item lands in exactly one of: findings (act now), review (human needed),
    passes (clean). Findings are severity-sorted; the caller sorts passes."""
    findings, review, passes = [], [], []
    for r in results:
        if r["status"] in FINDING_STATUSES:
            findings.append(r)
        elif r["status"] in ("NEEDS_REVIEW", "CARRY_FORWARD") or r.get("needs_human"):
            review.append(r)
        elif r["status"] in ("PASS", "RESOLVED_CONFIRMED"):
            passes.append(r)
        else:  # unknown/unexpected status — surface it rather than hide it
            review.append(r)
    findings.sort(key=lambda r: SEV_ORDER.get(r.get("severity"), 4))
    return findings, review, passes


def chapter_report(ch, ch_name, results, baseline_by_id):
    n = len(results)
    status_counts = {}
    for r in results:
        status_counts[r["status"]] = status_counts.get(r["status"], 0) + 1
    findings, review, passes = bucketize(results)

    L = [f"# {ch} — {ch_name}", ""]
    L.append(f"**Assessed:** {n}  |  "
             f"**Findings:** {len(findings)}  |  "
             f"**Needs human review:** {len(review)}  |  "
             f"**Pass/Resolved:** {len(passes)}")
    L.append("")
    L.append("Status breakdown: " +
             ", ".join(f"{k} {v}" for k, v in sorted(status_counts.items())))
    L.append("")

    if findings:
        L += ["## Findings (act on these)", ""]
        for r in findings:
            b = baseline_by_id.get(r["req_id"], {})
            L.append(f"### {r['req_id']} — {r.get('severity','?')} — {r['status']}")
            L.append(f"*{b.get('section')} {b.get('section_name','')}*")
            L.append("")
            L.append(f"> {b.get('description','')}")
            L.append("")
            L.append(f"- **Evidence:** {r.get('evidence','—')}")
            L.append(f"- **Remediation:** {r.get('remediation','—')}")
            if r.get("owner"):
                L.append(f"- **Owner:** {r['owner']}")
            L.append(f"- **Tier:** {r.get('tier','—')}")
            L.append("")

    if review:
        L += ["## Needs human review (carry-forward / not code-verifiable)", ""]
        for r in review:
            b = baseline_by_id.get(r["req_id"], {})
            L.append(f"- **{r['req_id']}** ({b.get('section_name','')}): "
                     f"{r.get('evidence') or r.get('remediation') or 'confirm with team'}")
        L.append("")

    L += ["<details><summary>Passing / resolved "
          f"({len(passes)})</summary>", ""]
    for r in sorted(passes, key=lambda r: r["req_id"]):
        L.append(f"- {r['req_id']} — {r['status']}")
    L += ["", "</details>", ""]
    return "\n".join(L)


def scope_label(scope, by_chapter):
    """Derive the rollup subtitle from the chapters actually rendered.

    The stored `scope` in findings.json is frozen at the first `init` for a
    run-date and does not accumulate when later chapters are audited under the
    same date (init resumes without updating it). Deriving from the chapters
    present keeps the label truthful, while still preserving a more precise
    single-chapter/section scope (e.g. "V2.1") when only that chapter was run.
    """
    chapters = sorted(by_chapter, key=lambda c: int(c[1:]))
    if scope == "all":
        return "all"
    if scope and len(chapters) == 1 and (
            scope == chapters[0] or scope.startswith(chapters[0] + ".")):
        return scope
    return ", ".join(chapters) or (scope or "all")


def _chip(value, kind):
    """Material-style status pill. kind: bad | warn | good | muted."""
    if value == 0 and kind in ("bad", "warn"):
        kind = "zero"
    return f"<span class='chip {kind}'>{value}</span>"


# Shared Material-style CSS for the rollup and per-chapter pages. Kept as a plain
# string (not an f-string) so the braces need no escaping.
CSS = """
 :root{
   --font:'Google Sans','Roboto','Helvetica Neue',Arial,sans-serif;
   --mono:'Roboto Mono',ui-monospace,SFMono-Regular,Menlo,monospace;
   --ink:#202124; --ink2:#5f6368; --line:#e8eaed; --line2:#dadce0;
   --surface:#fff; --bg:#f8f9fa; --blue:#1a73e8;
   --red-bg:#fce8e6; --red:#c5221f; --amber-bg:#fef7e0; --amber:#b06000;
   --green-bg:#e6f4ea; --green:#137333; --zero-bg:#f1f3f4; --zero:#5f6368;
 }
 *{box-sizing:border-box}
 body{font-family:var(--font);margin:0;padding:40px 24px;background:var(--bg);
   color:var(--ink);-webkit-font-smoothing:antialiased}
 .card{max-width:1080px;margin:0 auto 20px;background:var(--surface);
   border:1px solid var(--line2);border-radius:12px;overflow:hidden;
   box-shadow:0 1px 2px rgba(60,64,67,.10),0 2px 6px 1px rgba(60,64,67,.08)}
 .hd{padding:24px 28px 20px;border-bottom:1px solid var(--line)}
 h1{font-size:22px;font-weight:500;letter-spacing:.1px;margin:0 0 4px}
 .sub{color:var(--ink2);font-size:14px;line-height:1.5}
 .sub+.sub{margin-top:1px}
 .sub .lbl{font-weight:500;color:var(--ink)}
 .sub .mono{font-family:var(--mono);font-size:13px}
 .back{display:inline-block;margin-bottom:14px;color:var(--blue);
   text-decoration:none;font-size:14px;font-weight:500}
 .back:hover{text-decoration:underline}
 table{border-collapse:collapse;width:100%;font-size:14px}
 thead th{text-align:center;font-weight:700;font-size:11px;letter-spacing:.8px;
   text-transform:uppercase;color:var(--ink2);padding:14px 20px;
   border-bottom:1px solid var(--line2);white-space:nowrap;background:var(--surface)}
 thead th:nth-child(2){text-align:left}
 tbody td{padding:16px 20px;border-bottom:1px solid var(--line);color:#3c4043}
 tbody tr:hover{background:#f8fbff}
 td.ch{text-align:center;font-weight:500;width:96px}
 td.ch a{color:var(--blue);text-decoration:none}
 td.nm a{color:inherit;text-decoration:none}
 tbody tr:hover td.ch a,tbody tr:hover td.nm a{text-decoration:underline}
 td.nm{text-align:left}
 td.num{text-align:center;font-variant-numeric:tabular-nums;
   font-family:var(--mono);white-space:nowrap}
 .chip{display:inline-block;min-width:34px;padding:3px 10px;border-radius:999px;
   font-family:var(--font);font-weight:500;font-size:13px;line-height:18px;
   text-align:center}
 .chip.bad{background:var(--red-bg);color:var(--red)}
 .chip.warn{background:var(--amber-bg);color:var(--amber)}
 .chip.good{background:var(--green-bg);color:var(--green)}
 .chip.muted{background:var(--zero-bg);color:var(--zero)}
 .chip.zero{background:var(--zero-bg);color:var(--zero)}
 tfoot td{padding:16px 20px;font-weight:500;color:var(--ink);
   background:#f1f6fc;border-top:1px solid var(--line2)}
 tfoot td.num{text-align:center;font-family:var(--mono)}
 tfoot td.ch{text-align:center}
 .body{padding:8px 28px 24px}
 .summary{display:flex;flex-wrap:wrap;gap:20px;padding:18px 28px;
   border-bottom:1px solid var(--line);font-size:14px}
 .summary .n{font-family:var(--mono);font-weight:500}
 h2{font-size:13px;font-weight:700;letter-spacing:.8px;text-transform:uppercase;
   color:var(--ink2);margin:26px 0 12px}
 .finding{border:1px solid var(--line2);border-left:4px solid var(--zero);
   border-radius:10px;padding:16px 18px;margin:0 0 14px;background:var(--surface)}
 .finding.bad{border-left-color:var(--red)}
 .finding.warn{border-left-color:var(--amber)}
 .finding.muted{border-left-color:var(--zero)}
 .fhd{display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-bottom:2px}
 .fhd .rid{font-family:var(--mono);font-weight:500;font-size:15px;color:var(--ink)}
 .badge{display:inline-block;padding:2px 9px;border-radius:999px;font-size:12px;
   font-weight:500;line-height:18px}
 .badge.bad{background:var(--red-bg);color:var(--red)}
 .badge.warn{background:var(--amber-bg);color:var(--amber)}
 .badge.muted{background:var(--zero-bg);color:var(--zero)}
 .badge.status{background:var(--zero-bg);color:var(--zero)}
 .sec{color:var(--ink2);font-size:13px;margin:2px 0 10px}
 blockquote{margin:0 0 12px;padding:10px 14px;background:var(--bg);
   border-radius:8px;color:#3c4043;font-size:13.5px;line-height:1.5}
 .kv{font-size:13.5px;line-height:1.6;margin:6px 0;color:#3c4043;
   overflow-wrap:anywhere}
 .kv .k{font-weight:500;color:var(--ink)}
 .kv code,.mono{font-family:var(--mono);font-size:12.5px}
 .review{list-style:none;padding:0;margin:0}
 .review li{padding:12px 14px;border:1px solid var(--line);border-radius:8px;
   margin-bottom:10px;font-size:13.5px;line-height:1.55;color:#3c4043;
   overflow-wrap:anywhere}
 .review li .rid{font-family:var(--mono);font-weight:500;color:var(--ink)}
 details{margin-top:20px;border-top:1px solid var(--line);padding-top:14px}
 summary{cursor:pointer;font-size:13px;font-weight:700;letter-spacing:.6px;
   text-transform:uppercase;color:var(--ink2)}
 .passes{list-style:none;padding:0;margin:14px 0 0;display:grid;
   grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:8px}
 .passes li{font-family:var(--mono);font-size:13px;color:#3c4043;
   padding:8px 10px;background:var(--bg);border-radius:6px}
 .passes li .ok{color:var(--green);font-weight:500}
 @media (prefers-color-scheme:dark){
   :root{--ink:#e8eaed;--ink2:#9aa0a6;--line:#3c4043;--line2:#5f6368;
     --surface:#202124;--bg:#17181a;--blue:#8ab4f8;
     --red-bg:#3a1e1c;--red:#f28b82;--amber-bg:#3a2f17;--amber:#fdd663;
     --green-bg:#1c3025;--green:#81c995;--zero-bg:#2a2b2e;--zero:#9aa0a6}
   tbody td{color:#c8ccd0} tbody tr:hover{background:#25272b}
   tfoot td{background:#1e2a3a}
   .summary,.kv,.review li,.finding{color:#c8ccd0}
   .summary{color:inherit}
 }
"""


def _page(title, run_date, inner):
    """Wrap page-body HTML in the shared document shell + CSS."""
    return f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc(title)}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Google+Sans:wght@400;500&family=Roboto:wght@400;500&family=Roboto+Mono&display=swap" rel="stylesheet">
<style>{CSS}</style></head><body>
{inner}
</body></html>"""


def chapter_html(ch, ch_name, results, baseline_by_id, run_date, run_time=""):
    """Browser-friendly chapter report, linked from the rollup scorecard."""
    n = len(results)
    findings, review, passes = bucketize(results)

    parts = [f'<a class="back" href="rollup.html">&larr; Back to rollup</a>',
             '<div class="card">',
             '<div class="hd">',
             f'<h1>{esc(ch)} — {esc(ch_name)}</h1>',
             '<div class="sub"><span class="lbl">OWASP ASVS 4.0.3 — Level 2</span></div>',
             f'<div class="sub"><span class="lbl">Run at:</span> '
             f'<span class="mono">{esc(run_date)}{esc(run_time)}</span></div>',
             '</div>',
             '<div class="summary">',
             f'<div><span class="n">{n}</span> assessed</div>',
             f'<div>{_chip(len(findings),"bad")} findings</div>',
             f'<div>{_chip(len(review),"warn")} needs review</div>',
             f'<div>{_chip(len(passes),"good")} pass/resolved</div>',
             '</div>',
             '<div class="body">']

    if findings:
        parts.append('<h2>Findings (act on these)</h2>')
        for r in findings:
            b = baseline_by_id.get(r["req_id"], {})
            kind = SEV_KIND.get(r.get("severity"), "muted")
            parts.append(f'<div class="finding {kind}">')
            parts.append('<div class="fhd">')
            parts.append(f'<span class="rid">{esc(r["req_id"])}</span>')
            parts.append(f'<span class="badge {kind}">{esc(r.get("severity","?"))}</span>')
            parts.append(f'<span class="badge status">{esc(r["status"])}</span>')
            parts.append('</div>')
            parts.append(f'<div class="sec">{esc(b.get("section",""))} '
                         f'{esc(b.get("section_name",""))}</div>')
            parts.append(f'<blockquote>{esc(b.get("description",""))}</blockquote>')
            parts.append(f'<div class="kv"><span class="k">Evidence:</span> '
                         f'{esc(r.get("evidence","—"))}</div>')
            parts.append(f'<div class="kv"><span class="k">Remediation:</span> '
                         f'{esc(r.get("remediation","—"))}</div>')
            if r.get("owner"):
                parts.append(f'<div class="kv"><span class="k">Owner:</span> '
                             f'{esc(r["owner"])}</div>')
            parts.append(f'<div class="kv"><span class="k">Tier:</span> '
                         f'{esc(r.get("tier","—"))}</div>')
            parts.append('</div>')

    if review:
        parts.append('<h2>Needs human review (carry-forward / not code-verifiable)</h2>')
        parts.append('<ul class="review">')
        for r in review:
            b = baseline_by_id.get(r["req_id"], {})
            detail = r.get("evidence") or r.get("remediation") or "confirm with team"
            parts.append(f'<li><span class="rid">{esc(r["req_id"])}</span> '
                         f'({esc(b.get("section_name",""))}): {esc(detail)}</li>')
        parts.append('</ul>')

    parts.append(f'<details open><summary>Passing / resolved ({len(passes)})</summary>')
    parts.append('<ul class="passes">')
    for r in sorted(passes, key=lambda r: r["req_id"]):
        parts.append(f'<li>{esc(r["req_id"])} — '
                     f'<span class="ok">{esc(r["status"])}</span></li>')
    parts.append('</ul></details>')

    parts.append('</div></div>')  # .body, .card
    return _page(f"{ch} — {ch_name} — ASVS L2 Audit", run_date, "\n".join(parts))


def rollup_html(by_chapter, run_date, scope, run_time=""):
    scope = scope_label(scope, by_chapter)
    rows = []
    tot = {"findings": 0, "review": 0, "pass": 0, "assessed": 0}
    for ch in sorted(by_chapter, key=lambda c: int(c[1:])):
        rs = by_chapter[ch]
        findings, review, passes = bucketize(rs)
        f, rev, p = len(findings), len(review), len(passes)
        tot["findings"] += f; tot["review"] += rev; tot["pass"] += p
        tot["assessed"] += len(rs)
        href = f"{ch}.html"
        rows.append(
            f"<tr>"
            f"<td class='ch'><a href='{href}'>{ch}</a></td>"
            f"<td class='nm'><a href='{href}'>{esc(CHAPTER_NAMES.get(ch,''))}</a></td>"
            f"<td class='num'>{len(rs)}</td>"
            f"<td class='num'>{_chip(f,'bad')}</td>"
            f"<td class='num'>{_chip(rev,'warn')}</td>"
            f"<td class='num'>{_chip(p,'good')}</td>"
            f"</tr>")
    inner = f"""<div class="card">
 <div class="hd">
  <h1>OWASP ASVS 4.0.3 — Level 2 Audit Rollup</h1>
  <div class="sub"><span class="lbl">Scope:</span> {esc(scope)}</div>
  <div class="sub"><span class="lbl">Run at:</span> <span class="mono">{esc(run_date)}{esc(run_time)}</span></div>
 </div>
 <table>
 <thead><tr><th>Chapter</th><th>Name</th><th>Assessed</th>
 <th>Findings</th><th>Needs review</th><th>Pass/Resolved</th></tr></thead>
 <tbody>{''.join(rows)}</tbody>
 <tfoot><tr><td class="ch">TOTAL</td><td class="nm"></td>
 <td class="num">{tot['assessed']}</td>
 <td class="num">{_chip(tot['findings'],'bad')}</td>
 <td class="num">{_chip(tot['review'],'warn')}</td>
 <td class="num">{_chip(tot['pass'],'good')}</td></tr></tfoot>
 </table>
</div>"""
    return _page(f"ASVS L2 Audit Rollup — {run_date}", run_date, inner)


def main():
    run_date = sys.argv[1] if len(sys.argv) > 1 else date.today().isoformat()
    doc = load()
    baseline_by_id = {r["req_id"]: r for r in doc["requirements"]}

    fpath = os.path.join("asvs-audit", "state", run_date, "findings.json")
    if not os.path.exists(fpath):
        sys.exit(f"no findings for run {run_date} at {fpath}")
    with open(fpath, encoding="utf-8") as f:
        run_doc = json.load(f)
    results = run_doc["results"]
    scope = run_doc.get("scope", "all")
    # HH:MM the findings were last written — the effective run time
    run_time = datetime.fromtimestamp(os.path.getmtime(fpath)).strftime(" %H:%M")

    by_chapter = {}
    for r in results:
        # add-finding validates these, but a hand-edited findings.json might not;
        # skip with a warning rather than crash at the end of the run.
        if not r.get("chapter") or not r.get("status") or not r.get("req_id"):
            sys.stderr.write(
                f"warning: skipping malformed finding (need req_id/chapter/"
                f"status): {json.dumps(r)[:120]}\n")
            continue
        by_chapter.setdefault(r["chapter"], []).append(r)

    out_dir = os.path.join("asvs-audit", "reports", run_date)
    os.makedirs(out_dir, exist_ok=True)
    for ch, rs in by_chapter.items():
        ch_name = CHAPTER_NAMES.get(ch, "")
        md = chapter_report(ch, ch_name, rs, baseline_by_id)
        with open(os.path.join(out_dir, f"{ch}.md"), "w", encoding="utf-8") as f:
            f.write(md)
        page = chapter_html(ch, ch_name, rs, baseline_by_id, run_date, run_time)
        with open(os.path.join(out_dir, f"{ch}.html"), "w", encoding="utf-8") as f:
            f.write(page)
    with open(os.path.join(out_dir, "rollup.html"), "w", encoding="utf-8") as f:
        f.write(rollup_html(by_chapter, run_date, scope, run_time))

    n = len(by_chapter)
    print(f"wrote {n} chapter report(s) (.md + .html) + rollup.html to {out_dir}")


if __name__ == "__main__":
    main()
