#!/usr/bin/env python3
"""
List the ASVS requirements in a scope, joined with their tier from tiering.json,
so the agent can assess a section without loading the whole 137 KB catalog.

For each requirement it prints: id, tier, signal (the run_tools.py subcommand for
`auto` items), the requirement text, and the tiering check hint.

Usage:
  python3 scripts/list_requirements.py            # all 259, grouped by section
  python3 scripts/list_requirements.py V2          # one chapter
  python3 scripts/list_requirements.py V2.1         # one section

Scope is "all" (default), a chapter ("V2"), or a section ("V2.1").
Reads data/ relative to this skill folder; safe to run from anywhere.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(HERE, "data", "asvs-4.0.3-l2.json")
TIERING = os.path.join(HERE, "data", "tiering.json")


def in_scope(req, scope):
    if scope in ("all", "", None):
        return True
    if "." in scope:                       # section, e.g. V2.1
        return req["section"] == scope
    return req["chapter"] == scope         # chapter, e.g. V2


def main():
    scope = sys.argv[1] if len(sys.argv) > 1 else "all"
    with open(CATALOG, encoding="utf-8") as f:
        reqs = json.load(f)["requirements"]
    tiers = json.load(open(TIERING, encoding="utf-8"))["tiering"]

    rows = [r for r in reqs if in_scope(r, scope)]
    if not rows:
        sys.exit(f"no requirements match scope '{scope}' "
                 "(use 'all', a chapter like V2, or a section like V2.1)")

    counts = {"auto": 0, "inspect": 0, "manual": 0}
    current_section = None
    for r in rows:
        if r["section"] != current_section:
            current_section = r["section"]
            print(f"\n=== {r['section']}  {r['section_name']} "
                  f"({r['chapter']} {r['chapter_name']}) ===")
        t = tiers.get(r["req_id"], {"tier": "inspect", "signal": "code",
                                    "check": "Read the relevant code path"})
        counts[t["tier"]] = counts.get(t["tier"], 0) + 1
        print(f"\n{r['req_id']}  [{t['tier']}/{t['signal']}]")
        print(f"  {r['description']}")
        print(f"  check: {t['check']}")

    print(f"\n--- {len(rows)} requirement(s) in scope '{scope}': "
          + ", ".join(f"{k} {v}" for k, v in counts.items()) + " ---")


if __name__ == "__main__":
    main()
