#!/usr/bin/env python3
"""
Seed the tiering map: classify each ASVS 4.0.3 L2 requirement as
  auto     - a tool or pattern check settles it (agent runs + interprets)
  inspect  - agent must read the relevant code and reason about it
  manual   - process/architecture/human judgment; not code-verifiable

Heuristic seed only. A maintainer reviews and corrects data/tiering.json by
hand; that hand-tuned map is the real asset and survives across audits.

Run from the skill root:  python3 scripts/generate_tiering.py
"""
import json
import os
import re

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASELINE = os.path.join(HERE, "data", "asvs-4.0.3-l2.json")
OUT = os.path.join(HERE, "data", "tiering.json")

# Strong "auto" signals: concrete, tool-testable controls. The `signal` MUST be
# an exact run_tools.py subcommand so the agent can map signal -> tool directly.
# Controls that need a live URL or HTML parsing (cookie flags, CORS, SRI) are
# deliberately NOT auto here — they fall through to `inspect` (read the config /
# templates), which is more reliable for a source audit than probing a URL.
AUTO = [
    (r"\beval\(", "grep-eval", "Run run_tools.py grep-eval for dynamic code execution"),
    (r"content security policy|\bCSP\b|X-Content-Type|Referrer-Policy|"
     r"security header|Strict-Transport|\bHSTS\b|X-Frame-Options",
     "headers", "Run run_tools.py headers <url> and assess CSP/HSTS/etc"),
    (r"\bTLS\b|cipher|certificate|\bHTTPS\b only|forward secrecy|\bSSL\b",
     "tls", "Run run_tools.py tls <host> (confirm full grade via SSL Labs)"),
    (r"dependency|dependencies|components with known|outdated|vulnerable "
     r"components|third party librar|unmaintained",
     "bundler-audit", "Run run_tools.py bundler-audit for dependency CVEs"),
]

# "manual" signals: process, governance, architecture, human judgment.
MANUAL = [
    r"documented|documentation|policy|process\b|governance|runbook|playbook",
    r"threat model|secure software development|\bSDLC\b|design review",
    r"inventory|classification|classif|data retention|retention|privacy "
    r"regulation|GDPR",
    r"trusted|trust boundar|segregat|architecture|architectural|responsib",
    r"defined and|agreed|budget|verified as part of|independent",
]

# Brakeman helps (raises tier to inspect w/ tool assist) for these code smells.
BRAKEMAN = re.compile(
    r"inject|\bXSS\b|cross-site scripting|SQL|mass assignment|open redirect|"
    r"command execution|path traversal|SSRF|deserializ|CSRF|forgery",
    re.I)


def classify(req):
    desc = (req.get("description") or "")
    ch = req.get("chapter", "")
    low = desc.lower()

    # 1. strong auto signals win — they are the most testable
    for pat, sig, hint in AUTO:
        if re.search(pat, desc, re.I):
            return "auto", sig, hint

    # 2. V1 (Architecture, Design & Threat Modeling) defaults to manual
    base_manual = (ch == "V1")

    # 3. explicit process/governance language -> manual
    for pat in MANUAL:
        if re.search(pat, low):
            return "manual", "process", ("Not code-verifiable — confirm with "
                                         "team; carry prior answer forward for sign-off")
    if base_manual:
        return "manual", "architecture", ("Architecture/design item — confirm with "
                                          "team; carry prior answer forward")

    # 4. everything else -> inspect (agent reads code); note Brakeman assist
    if BRAKEMAN.search(desc):
        return "inspect", "brakeman", ("Read the relevant code path; Brakeman "
                                       "static analysis assists this class of check")
    return "inspect", "code", "Read the relevant code path and assess against the requirement"


def main():
    with open(BASELINE, encoding="utf-8") as f:
        doc = json.load(f)
    tiers = {}
    counts = {"auto": 0, "inspect": 0, "manual": 0}
    for req in doc["requirements"]:
        tier, sig, hint = classify(req)
        tiers[req["req_id"]] = {"tier": tier, "signal": sig, "check": hint}
        counts[tier] += 1

    out = {
        "meta": {
            "note": "Heuristic seed — REVIEW AND CORRECT BY HAND. Ships as a seed; "
                    "hand-tuning this map over successive audits is the durable asset. "
                    "Every 'auto' signal is an exact run_tools.py subcommand.",
            "tiers": {
                "auto": "Tool/pattern check settles it; agent runs and interprets.",
                "inspect": "Agent reads the relevant code and reasons about it.",
                "manual": "Process/architecture/judgment; not code-verifiable.",
            },
            "counts": counts,
        },
        "tiering": tiers,
    }
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print("tiering counts:", counts)
    # show a few examples per tier for a sanity check
    doc_by_id = {r["req_id"]: r for r in doc["requirements"]}
    for t in ("auto", "inspect", "manual"):
        ex = [rid for rid, v in tiers.items() if v["tier"] == t][:3]
        print(f"\n[{t}] examples:")
        for rid in ex:
            print(f"  {rid}: {doc_by_id[rid]['description'][:70]}...")


if __name__ == "__main__":
    main()
