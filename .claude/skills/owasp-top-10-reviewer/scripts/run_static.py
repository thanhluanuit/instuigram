#!/usr/bin/env python3
"""
run_static.py (v2) — run Brakeman + bundler-audit against a Rails repo and normalize output
into OWASP Top 10:2025-tagged findings.

Key v2 corrections:
- Maps on Brakeman's `warning_type` (documented, stable), NOT `check_name` (class name).
- Unknown warning types go to an explicit "uncategorized" bucket for inspection — never
  silently defaulted to a category.
- Detects Ruby/Rails versions from Gemfile.lock so the reviewer can gate version-dependent
  rules (YAML.load on Psych 4, open-redirect on Rails >= 7.0). See data/*.json version_gated_rules.
- bundler-audit parsing tolerates missing fields and reports stale-DB risk.

Usage:
    python3 run_static.py <repo_root> [--update-advisories] [--out findings.json]

Output: JSON { versions, tools, findings[], uncategorized[] }. Findings are LEADS — confirm each
in code before reporting (Brakeman has false positives). See ../references/tooling.md.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
RULES_PATH = os.path.join(HERE, "..", "data", "owasp-top-10-2025-rails-rules.json")


def load_rules():
    with open(RULES_PATH) as f:
        return json.load(f)


def build_warning_map(rules):
    """warning_type string -> (category_id, category_name). First mapping wins."""
    wmap, names = {}, {}
    for cat in rules["categories"]:
        names[cat["id"]] = cat["name"]
        for wt in cat.get("brakeman_warning_types", []):
            wmap.setdefault(wt, cat["id"])
    return wmap, names


def run(cmd, cwd):
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=1800)
        return p.returncode, p.stdout, p.stderr
    except FileNotFoundError:
        return None, "", "not-installed"
    except subprocess.TimeoutExpired:
        return None, "", "timeout"


def detect_versions(repo):
    """Best-effort ruby/rails version detection from Gemfile.lock for rule gating."""
    versions = {"ruby": None, "rails": None, "source": None}
    lock = os.path.join(repo, "Gemfile.lock")
    if os.path.isfile(lock):
        text = open(lock, errors="ignore").read()
        m = re.search(r"^\s*rails \((\d+\.\d+\.\d+)", text, re.M)
        if m:
            versions["rails"] = m.group(1)
        m = re.search(r"RUBY VERSION\s*\n\s*ruby (\d+\.\d+\.\d+)", text)
        if m:
            versions["ruby"] = m.group(1)
        versions["source"] = "Gemfile.lock"
    return versions


def version_gate_notes(versions):
    """Emit reviewer guidance on which version-dependent rules apply to THIS repo."""
    notes = []

    def tup(v):
        return tuple(int(x) for x in v.split(".")) if v else None

    ruby, rails = tup(versions.get("ruby")), tup(versions.get("rails"))
    if ruby is None:
        notes.append("Ruby version unknown — verify YAML.load handling manually (safe by default only on Psych 4 / Ruby >= 3.1).")
    elif ruby >= (3, 1, 0):
        notes.append(f"Ruby {versions['ruby']}: YAML.load is safe_load by default (Psych 4). Do NOT flag plain YAML.load; flag YAML.unsafe_load / Marshal.load only.")
    else:
        notes.append(f"Ruby {versions['ruby']} (< 3.1): YAML.load is UNSAFE (pre-Psych-4). Treat YAML.load on untrusted data as a finding.")

    if rails is None:
        notes.append("Rails version unknown — verify open-redirect protection manually (default only on Rails >= 7.0 new apps).")
    elif rails >= (7, 0, 0):
        notes.append(f"Rails {versions['rails']}: open-redirect protection is the default for NEW apps, but UPGRADED apps must set config.action_controller.raise_on_open_redirects = true. Confirm it's enabled before treating redirect_to(user_input) as safe.")
    else:
        notes.append(f"Rails {versions['rails']} (< 7.0): no default open-redirect protection. redirect_to of user input IS a finding.")
    return notes


def brakeman_findings(repo, wmap, names):
    tool = {"name": "brakeman", "ran": False, "note": "", "version": None}
    findings, uncategorized = [], []
    cmd = ["brakeman", "-q", "-f", "json", "--no-exit-on-warn", "--no-exit-on-error"]
    if shutil.which("brakeman") is None:
        if shutil.which("bundle") is not None:
            cmd = ["bundle", "exec"] + cmd
        else:
            tool["note"] = "not installed"
            return tool, findings, uncategorized
    code, out, err = run(cmd, repo)
    if code is None:
        tool["note"] = err or "not installed"
        return tool, findings, uncategorized
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        tool["note"] = "could not parse Brakeman JSON (is stdout clean? try -o file)"
        return tool, findings, uncategorized
    tool["ran"] = True
    tool["version"] = (data.get("scan_info", {}) or {}).get("brakeman_version") \
        or data.get("brakeman_version")
    tool["note"] = f"brakeman {tool['version'] or '?'}"
    for w in data.get("warnings", []):
        wt = w.get("warning_type", "")
        conf = w.get("confidence", "")
        sev = {"High": "High", "Medium": "Medium", "Weak": "Info"}.get(conf, "Medium")
        rec = {
            "source": "brakeman",
            "warning_type": wt,
            "check_name": w.get("check_name", ""),
            "severity_hint": sev,
            "file": w.get("file", ""),
            "line": w.get("line"),
            "confidence": conf,
            "message": (w.get("message", "") or "").strip(),
        }
        cat = wmap.get(wt)
        if cat is None:
            # Explicitly surface for inspection instead of guessing a category.
            rec["category"] = None
            rec["note"] = "warning_type not in verified map — assign category by inspection"
            uncategorized.append(rec)
        else:
            rec["category"] = cat
            rec["category_name"] = names[cat]
            findings.append(rec)
    return tool, findings, uncategorized


def bundler_audit_findings(repo, names, update):
    tool = {"name": "bundler-audit", "ran": False, "note": "", "db_updated": update}
    findings = []
    have = shutil.which("bundle-audit") is not None or shutil.which("bundle") is not None
    if not have:
        tool["note"] = "not installed"
        return tool, findings
    audit = ["bundle-audit"] if shutil.which("bundle-audit") else ["bundle", "audit"]
    if update:
        run(audit + ["update"], repo)
    code, out, err = run(audit + ["check"], repo)
    if code is None:
        tool["note"] = err or "not installed"
        return tool, findings
    tool["ran"] = True
    if not update:
        tool["note"] = ("advisory DB NOT updated this run (no --update) — results may be stale; "
                        "re-run with --update-advisories in CI where network allows")
    crit_map = {"Critical": "Critical", "High": "High", "Medium": "Medium", "Low": "Low"}
    for b in re.split(r"\n\s*\n", out.strip()):
        if "Name:" not in b and "Advisory:" not in b and "Insecure Source" not in b:
            continue

        def field(label, blk=b):
            m = re.search(rf"{label}:\s*(.+)", blk)
            return m.group(1).strip() if m else ""

        name = field("Name")
        version = field("Version")
        advisory = field("Advisory") or field("CVE")
        criticality = field("Criticality")
        title = field("Title")
        solution = field("Solution")
        # Tolerate advisories that only report an insecure source / unpatched gem.
        insecure_source = "Insecure Source" in b
        if not (name or advisory or insecure_source):
            continue
        sev = crit_map.get(criticality, "High" if advisory else "Medium")
        msg_bits = [x for x in [f"{name} {version}".strip(), title,
                                f"({advisory}, {criticality or 'unrated'})" if advisory else "",
                                "insecure gem source" if insecure_source else "",
                                solution] if x]
        findings.append({
            "source": "bundler-audit",
            "category": "A03",
            "category_name": names.get("A03", "Software Supply Chain Failures"),
            "warning_type": advisory or ("insecure-source" if insecure_source else "advisory"),
            "severity_hint": sev,
            "file": "Gemfile.lock",
            "line": None,
            "confidence": "High",
            "message": ": ".join(msg_bits) if msg_bits else "advisory (details unparsed)",
        })
    if not findings and "No vulnerabilities found" in out:
        tool["note"] = (tool["note"] + " | " if tool["note"] else "") + "no known-vulnerable gems"
    return tool, findings


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("repo_root")
    ap.add_argument("--update-advisories", action="store_true",
                    help="run bundle audit update first (needs network)")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()

    repo = os.path.abspath(args.repo_root)
    if not os.path.isdir(repo):
        print(f"error: {repo} is not a directory", file=sys.stderr)
        sys.exit(2)

    rules = load_rules()
    wmap, names = build_warning_map(rules)
    versions = detect_versions(repo)
    bt, bf, unc = brakeman_findings(repo, wmap, names)
    at, af = bundler_audit_findings(repo, names, args.update_advisories)

    # Dedup A03: prefer bundler-audit CVE over Brakeman "Unmaintained Dependencies" on same gem.
    audit_gems = {f["message"].split()[0].lower() for f in af if f.get("message")}
    bf = [f for f in bf if not (f.get("category") == "A03"
          and f.get("message", "").split(":")[0].split()[0].lower() in audit_gems)]

    result = {
        "repo": repo,
        "ruleset": "owasp-top-10-2025",
        "versions": versions,
        "version_gate_notes": version_gate_notes(versions),
        "tools": {"brakeman": bt, "bundler_audit": at},
        "findings": bf + af,
        "uncategorized": unc,
    }
    payload = json.dumps(result, indent=2)
    if args.out:
        with open(args.out, "w") as f:
            f.write(payload)
        print(f"wrote {len(result['findings'])} leads + {len(unc)} uncategorized to {args.out}",
              file=sys.stderr)
    else:
        print(payload)


if __name__ == "__main__":
    main()
