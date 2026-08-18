#!/usr/bin/env python3
"""
checkpoint.py — state + carry-forward for performance audits (Mode B).

Why: a full-codebase audit is too big for one context window, and the skill earns
its keep on RE-runs — showing what regressed and what got fixed since last time.
This persists findings per run and diffs against the previous run.

State lives under  performance-review-report/state/<run-date>/progress.json  in the target repo.
Reports go under    performance-review-report/reports/<run-date>/.

Commands:
  checkpoint.py init <run-date> "<scope>"        # start/resume; loads prior run for carry-forward
  checkpoint.py add-finding <run-date> '<json>'  # record one finding (schema in SKILL.md)
  checkpoint.py add-finding <run-date> -         # ...or read the JSON from stdin
                                                 # all 8 schema fields are required; see REQUIRED
  checkpoint.py done-category <run-date> <cat>   # mark a category complete (resumability)
  checkpoint.py status <run-date>                # progress + counts
  checkpoint.py diff <run-date>                  # NEW / STILL_PRESENT / RESOLVED vs prior run
"""
import argparse, glob, json, os, re, sys

ROOT = "performance-review-report"
STATE = os.path.join(ROOT, "state")
# Same names as the finding schema's `category` field in SKILL.md — one vocabulary, so
# `done-category N+1` and a finding tagged "N+1" refer to the same thing.
CATEGORIES = ["N+1", "Index", "Caching", "Jobs", "Memory", "Views", "System"]
CANONICAL = {c.lower(): c for c in CATEGORIES}
LINE_NO = re.compile(r":\d+(?:-\d+)?\b")  # "app/models/product.rb:42" → "app/models/product.rb"


def state_dir(run): return os.path.join(STATE, run)
def progress_path(run): return os.path.join(state_dir(run), "progress.json")


def load(run):
    """Load a run's state, or exit with an actionable message.

    An uncaught traceback here reads as a broken tool rather than a missing step,
    and sends the reader hunting for a bug instead of running `init`.
    """
    try:
        with open(progress_path(run)) as fh:
            return json.load(fh)
    except FileNotFoundError:
        sys.exit(f"error: no run '{run}' under {STATE}/. "
                 f"Start it with: checkpoint.py init {run} \"<scope>\"\n"
                 f"(Run from the target repo root — state is written relative to the cwd.)")
    except json.JSONDecodeError as e:
        sys.exit(f"error: corrupt state file {progress_path(run)}: {e}")


def save(run, data):
    os.makedirs(state_dir(run), exist_ok=True)
    with open(progress_path(run), "w") as fh:
        json.dump(data, fh, indent=2)


def signature(f):
    """Stable identity for a finding, for carry-forward matching.

    Line numbers are stripped from the location: unrelated edits shift them every
    run, and a signature that tracks them reports an untouched finding as RESOLVED
    plus NEW — a false 'you fixed it' that makes the re-run diff worthless.
    """
    location = LINE_NO.sub("", (f.get("location") or "?").strip())
    return f"{f.get('category','?')}|{location}|{f.get('pattern','?')[:80]}"


def prior_run(run):
    runs = sorted(d for d in glob.glob(os.path.join(STATE, "*"))
                  if os.path.isdir(d) and os.path.basename(d) < run
                  and os.path.exists(os.path.join(d, "progress.json")))
    return os.path.basename(runs[-1]) if runs else None


def cmd_init(run, scope):
    if os.path.exists(progress_path(run)):
        data = load(run)
        print(f"Resuming {run}. Done: {data['categories_done']} · findings: {len(data['findings'])}")
        remaining = [c for c in CATEGORIES if c not in data["categories_done"]]
        print(f"Remaining categories: {remaining or 'none — ready to render'}")
        return
    prev = prior_run(run)
    carry = load(prev)["findings"] if prev else []
    save(run, {
        "run_date": run, "scope": scope, "categories_done": [],
        "findings": [], "prior_run": prev, "carry_forward": carry,
    })
    msg = f"Initialised {run} (scope: {scope})."
    if prev:
        msg += f" Carrying forward {len(carry)} findings from {prev} for regression tracking."
    else:
        msg += " No prior run found — this is the baseline."
    print(msg)
    print(f"Categories to audit, in order: {CATEGORIES}")


REQUIRED = ["category", "location", "pattern", "impact", "severity", "confidence", "fix", "verify"]
SEVERITIES = {"Critical", "High", "Medium", "Low"}
CONFIDENCES = {"confirmed", "needs-measurement"}


def validate(f):
    """Reject incomplete findings at the point of entry.

    A finding with no `verify` is a claim with no way to check it, and one with no
    `impact` is a pattern name pretending to be a priority — both read as real work
    in the final report. Catching them here beats discovering them at render time,
    when the evidence is no longer in context.
    """
    errs = [f"missing required field: {k}" for k in REQUIRED
            if not str(f.get(k) or "").strip()]
    sev, conf = f.get("severity"), f.get("confidence")
    if sev and sev not in SEVERITIES:
        errs.append(f"severity must be one of {sorted(SEVERITIES)}, got {sev!r}")
    if conf and conf not in CONFIDENCES:
        errs.append(f"confidence must be one of {sorted(CONFIDENCES)}, got {conf!r}")
    return errs


def cmd_add_finding(run, raw):
    data = load(run)
    if raw == "-":
        raw = sys.stdin.read()          # avoids shell-quoting findings that contain quotes
    try:
        f = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"error: invalid finding JSON: {e}", file=sys.stderr); return 2
    errs = validate(f)
    if errs:
        print("error: incomplete finding — not recorded:", file=sys.stderr)
        for e in errs:
            print(f"  · {e}", file=sys.stderr)
        print(f"  schema: {{{', '.join(REQUIRED)}}}", file=sys.stderr)
        return 2
    # tag status vs the previous run
    prior_sigs = {signature(p) for p in data.get("carry_forward", [])}
    f["status"] = "STILL_PRESENT" if signature(f) in prior_sigs else "NEW"
    data["findings"].append(f)
    save(run, data)
    print(f"Recorded [{f['status']}] {f['severity']} {f['category']} @ {f['location']}")


def cmd_done_category(run, cat):
    data = load(run)
    cat = CANONICAL.get(cat.strip().lower(), cat)   # accept any casing
    if cat not in CATEGORIES:
        # Reject rather than warn: recording a typo'd name marks progress that never
        # happened while the real category stays silently open, so the run reports
        # itself complete with a category unaudited. Same hard-fail as add-finding.
        print(f"error: '{cat}' is not a category — nothing recorded.", file=sys.stderr)
        print(f"  valid categories: {CATEGORIES}", file=sys.stderr)
        return 2
    if cat not in data["categories_done"]:
        data["categories_done"].append(cat)
        save(run, data)
    remaining = [c for c in CATEGORIES if c not in data["categories_done"]]
    print(f"Category '{cat}' done. Remaining: {remaining or 'none — ready to render report'}")


def cmd_status(run):
    data = load(run)
    # Both tallies the report template asks for, so they aren't hand-counted at render
    # time — the point in a long run where the evidence is furthest out of context.
    by_sev, by_cat = {}, {}
    for f in data["findings"]:
        sev = f.get("severity", "?")
        cat = CANONICAL.get(str(f.get("category", "?")).lower(), f.get("category", "?"))
        by_sev[sev] = by_sev.get(sev, 0) + 1
        by_cat[cat] = by_cat.get(cat, 0) + 1
    print(f"Run {run} · scope: {data['scope']} · prior: {data['prior_run']}")
    print(f"Categories done: {data['categories_done']}")
    print(f"Findings: {len(data['findings'])}")
    print("  by severity: " + (" · ".join(f"{s} {by_sev[s]}"
          for s in ["Critical", "High", "Medium", "Low"] if s in by_sev) or "none"))
    print("  by category: " + (" · ".join(f"{c} {by_cat[c]}"
          for c in CATEGORIES if c in by_cat) or "none"))


def cmd_diff(run):
    data = load(run)
    cur = {signature(f): f for f in data["findings"]}
    prev = {signature(f): f for f in data.get("carry_forward", [])}
    new = [f for s, f in cur.items() if s not in prev]
    still = [f for s, f in cur.items() if s in prev]
    resolved = [f for s, f in prev.items() if s not in cur]
    if not data["prior_run"]:
        print("No prior run — baseline only. All findings are NEW.")
    print(f"vs {data['prior_run']}:  NEW {len(new)} · STILL_PRESENT {len(still)} · RESOLVED {len(resolved)}\n")
    for label, items in (("NEW", new),
                         ("STILL_PRESENT (carried over — not yet fixed)", still),
                         ("RESOLVED (fixed since last run)", resolved)):
        if items:
            print(f"== {label} ==")
            for f in items:
                print(f"  [{f.get('severity','?')}] {f.get('category','?')} @ {f.get('location','?')}")
            print()
    print("Note: RESOLVED means the finding's signature is gone; confirm it was fixed, not just moved.")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("init"); a.add_argument("run"); a.add_argument("scope")
    a = sub.add_parser("add-finding"); a.add_argument("run"); a.add_argument("json")
    a = sub.add_parser("done-category"); a.add_argument("run"); a.add_argument("category")
    a = sub.add_parser("status"); a.add_argument("run")
    a = sub.add_parser("diff"); a.add_argument("run")
    args = p.parse_args()
    return {
        "init": lambda: cmd_init(args.run, args.scope),
        "add-finding": lambda: cmd_add_finding(args.run, args.json),
        "done-category": lambda: cmd_done_category(args.run, args.category),
        "status": lambda: cmd_status(args.run),
        "diff": lambda: cmd_diff(args.run),
    }[args.cmd]()


if __name__ == "__main__":
    raise SystemExit(main())
