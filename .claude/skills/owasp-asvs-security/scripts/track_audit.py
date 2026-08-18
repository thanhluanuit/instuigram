#!/usr/bin/env python3
"""
Run-state manager for resumable ASVS audits.

State lives under the repo at:  asvs-audit/state/<run-date>/
  progress.json  - scope + which sections are done (resume point)
  findings.json  - accumulating per-requirement verdicts

Usage:
  python3 scripts/track_audit.py init <run-date> <scope>
  python3 scripts/track_audit.py done-section <run-date> <section>
  python3 scripts/track_audit.py add-finding <run-date> '<finding-json>'
  python3 scripts/track_audit.py status <run-date>
  python3 scripts/track_audit.py prior <req-id>
  python3 scripts/track_audit.py promote <run-date>

<scope> is "all", a chapter ("V2"), or a section ("V2.1").

Prior audit history is per-repo. The baseline is resolved (see baseline_path):
$ASVS_BASELINE, else asvs-audit/baseline.json, else a single curated *.json in
asvs-audit/baseline/. `prior` reads it in either schema — the skill's flat
{results:[...]} or a curated rich {meta, requirements:[{..., prior:{...}}]}.
`promote` folds a run's verdicts back: into a rich baseline it MERGES additively
under requirement['prior']['automated'], preserving all human notes; otherwise
it writes the flat findings. There is no baseline on a repo's first audit.

Paths are relative to the repo root (current working directory).
"""
import glob
import json
import os
import sys
from datetime import date

STATE_ROOT = os.path.join("asvs-audit", "state")
BASELINE_DEFAULT = os.path.join("asvs-audit", "baseline.json")
BASELINE_DIR = os.path.join("asvs-audit", "baseline")


def run_dir(run_date):
    return os.path.join(STATE_ROOT, run_date)


def baseline_path():
    """Resolve the baseline file. Precedence:
      1. $ASVS_BASELINE if set (explicit override)
      2. asvs-audit/baseline.json if it exists (skill's flat default)
      3. the single *.json in asvs-audit/baseline/ (a curated rich baseline)
      4. asvs-audit/baseline.json — the target a first `promote` will create
    If asvs-audit/baseline/ holds several *.json files the choice is ambiguous;
    set $ASVS_BASELINE to pick one."""
    env = os.environ.get("ASVS_BASELINE")
    if env:
        return env
    if os.path.exists(BASELINE_DEFAULT):
        return BASELINE_DEFAULT
    curated = sorted(glob.glob(os.path.join(BASELINE_DIR, "*.json")))
    if len(curated) == 1:
        return curated[0]
    if len(curated) > 1:
        sys.stderr.write(
            f"warning: {len(curated)} baselines in {BASELINE_DIR}/; "
            "set $ASVS_BASELINE to choose. Falling back to the flat default.\n")
    return BASELINE_DEFAULT


def is_rich(doc):
    """A curated baseline: {meta, requirements:[{..., prior:{...}}]}.
    The flat baseline the skill promotes is {results:[{req_id, status, ...}]}."""
    return isinstance(doc, dict) and isinstance(doc.get("requirements"), list)


def baseline_record(doc, req_id):
    """Prior record for req_id from either schema (rich requirement, flat
    result), or None if absent."""
    if is_rich(doc):
        return next((r for r in doc["requirements"]
                     if r.get("req_id") == req_id), None)
    return next((r for r in doc.get("results", [])
                 if r.get("req_id") == req_id), None)


def baseline_count(doc):
    """How many prior verdicts the baseline carries, for the init message."""
    if is_rich(doc):
        return sum(1 for r in doc["requirements"] if r.get("prior"))
    return len(doc.get("results", []))


def _load(path, default):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return default


def _save(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)


def init(run_date, scope):
    d = run_dir(run_date)
    prog_path = os.path.join(d, "progress.json")
    if os.path.exists(prog_path):
        prog = _load(prog_path, {})
        print(f"resuming run {run_date} (scope={prog.get('scope')}); "
              f"{len(prog.get('sections_done', []))} sections already done")
        return
    _save(prog_path, {"run_date": run_date, "scope": scope, "sections_done": []})
    _save(os.path.join(d, "findings.json"),
          {"run_date": run_date, "scope": scope, "results": []})
    bp = baseline_path()
    if os.path.exists(bp):
        base = _load(bp, {})
        kind = "rich/curated" if is_rich(base) else "flat"
        print(f"initialised run {run_date} (scope={scope}); "
              f"prior baseline found at {bp} ({kind}, "
              f"{baseline_count(base)} verdicts) — carry forward and compare")
    else:
        print(f"initialised run {run_date} (scope={scope}); "
              f"no prior baseline — this is a first audit, assess fresh")


def done_section(run_date, section):
    prog_path = os.path.join(run_dir(run_date), "progress.json")
    prog = _load(prog_path, None)
    if prog is None:
        sys.exit(f"no run {run_date}; init first")
    if section not in prog["sections_done"]:
        prog["sections_done"].append(section)
    _save(prog_path, prog)
    print(f"section {section} done ({len(prog['sections_done'])} total)")


# Keys a finding must carry so render_report can bucket and place it. Validated
# at write time so a typo fails here with a clear message, not with a cryptic
# KeyError at render time — after the whole audit is already assessed.
REQUIRED_FINDING_KEYS = ("req_id", "chapter", "section", "status")
VALID_STATUSES = {"PASS", "FAIL", "REGRESSION", "RESOLVED_CONFIRMED",
                  "NEEDS_REVIEW", "CARRY_FORWARD"}


def add_finding(run_date, finding_json):
    path = os.path.join(run_dir(run_date), "findings.json")
    doc = _load(path, None)
    if doc is None:
        sys.exit(f"no run {run_date}; init first")
    try:
        finding = json.loads(finding_json)
    except json.JSONDecodeError as e:
        sys.exit(f"finding is not valid JSON: {e}")
    if not isinstance(finding, dict):
        sys.exit("finding must be a JSON object")
    missing = [k for k in REQUIRED_FINDING_KEYS
               if finding.get(k) in (None, "")]
    if missing:
        sys.exit(f"finding missing required field(s): {', '.join(missing)}; "
                 f"need {', '.join(REQUIRED_FINDING_KEYS)}")
    if finding["status"] not in VALID_STATUSES:
        sys.exit(f"invalid status {finding['status']!r}; "
                 f"one of {', '.join(sorted(VALID_STATUSES))}")
    # replace any existing verdict for the same req_id (idempotent re-runs)
    doc["results"] = [r for r in doc["results"]
                      if r.get("req_id") != finding.get("req_id")]
    doc["results"].append(finding)
    _save(path, doc)
    print(f"recorded {finding.get('req_id')} = {finding.get('status')}")


def status(run_date):
    prog = _load(os.path.join(run_dir(run_date), "progress.json"), None)
    fnd = _load(os.path.join(run_dir(run_date), "findings.json"), {"results": []})
    if prog is None:
        sys.exit(f"no run {run_date}")
    counts = {}
    for r in fnd["results"]:
        counts[r.get("status")] = counts.get(r.get("status"), 0) + 1
    print(f"run {run_date}  scope={prog['scope']}")
    print(f"  sections done: {len(prog['sections_done'])}")
    print(f"  results: {len(fnd['results'])}  {counts}")


def prior(req_id):
    bp = baseline_path()
    base = _load(bp, None)
    if base is None:
        print(f"no baseline yet ({bp}); first audit — assess {req_id} fresh")
        return
    rec = baseline_record(base, req_id)
    if rec is None:
        print(f"{req_id}: not in baseline ({bp}) — assess fresh")
    else:
        print(json.dumps(rec, ensure_ascii=False, indent=2))


def _status_counts(results):
    counts = {}
    for r in results:
        counts[r.get("status")] = counts.get(r.get("status"), 0) + 1
    return counts


def _merge_into_rich(baseline, run_doc, run_date):
    """Fold this run's flat findings into a curated rich baseline, additively.
    Each verdict lands under requirement['prior']['automated']; every existing
    human field (l1/l2 status + details, finding, meta.prior_audits) is left
    untouched. Returns (baseline, updated_count)."""
    index = {r.get("req_id"): r for r in baseline["requirements"]}
    updated = 0
    for f in run_doc.get("results", []):
        req = index.get(f.get("req_id"))
        if req is None:
            continue
        prior = req.setdefault("prior", {})
        prior["automated"] = {
            "status": f.get("status"), "severity": f.get("severity"),
            "tier": f.get("tier"), "evidence": f.get("evidence"),
            "remediation": f.get("remediation"),
            "needs_human": f.get("needs_human"), "owner": f.get("owner"),
            "run_date": run_date,
        }
        updated += 1
    baseline.setdefault("meta", {})["last_automated_run"] = {
        "run_date": run_date, "scope": run_doc.get("scope"),
        "results": _status_counts(run_doc.get("results", [])),
        "tool": "owasp-asvs-security",
    }
    return baseline, updated


def promote(run_date):
    src = os.path.join(run_dir(run_date), "findings.json")
    doc = _load(src, None)
    if doc is None:
        sys.exit(f"no findings for run {run_date}; nothing to promote")
    bp = baseline_path()
    target = _load(bp, None)
    if target is not None and is_rich(target):
        merged, updated = _merge_into_rich(target, doc, run_date)
        _save(bp, merged)
        print(f"promoted run {run_date}: merged {updated} verdict(s) into "
              f"rich baseline {bp} (human notes preserved). Commit it.")
    else:
        _save(bp, doc)
        print(f"promoted run {run_date} -> {bp} "
              f"({len(doc.get('results', []))} verdicts, flat). Commit it.")


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd = sys.argv[1]
    if cmd == "prior":
        if len(sys.argv) < 3:
            sys.exit(__doc__)
        prior(sys.argv[2])
        return
    rd = sys.argv[2] if len(sys.argv) > 2 else date.today().isoformat()
    if cmd == "init":
        init(rd, sys.argv[3] if len(sys.argv) > 3 else "all")
    elif cmd == "done-section":
        done_section(rd, sys.argv[3])
    elif cmd == "add-finding":
        add_finding(rd, sys.argv[3])
    elif cmd == "status":
        status(rd)
    elif cmd == "promote":
        promote(rd)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
