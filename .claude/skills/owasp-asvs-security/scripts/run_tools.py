#!/usr/bin/env python3
"""
Read-only security tool runner for the ASVS security audit (Rails + PostgreSQL stack).

Runs stack security tools and returns structured JSON the agent interprets
against ASVS requirements. Every tool is READ-ONLY. Missing tools degrade
gracefully (status "unavailable") so a partial environment still produces a
partial result instead of crashing.

Usage:
  python3 scripts/run_tools.py brakeman
  python3 scripts/run_tools.py bundler-audit
  python3 scripts/run_tools.py grep-eval
  python3 scripts/run_tools.py headers  https://your-app.example.com
  python3 scripts/run_tools.py tls      your-app.example.com
  python3 scripts/run_tools.py all      [https://your-app.example.com]

'all' runs the local static checks; pass your deployed app's URL to also run
headers+tls. Run from the repo root.
"""
import json
import re
import shutil
import subprocess
import sys
import urllib.request
import ssl


def _run(cmd, timeout=300):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout, p.stderr
    except FileNotFoundError:
        return None, "", "not-installed"
    except subprocess.TimeoutExpired:
        return None, "", "timeout"


def brakeman():
    """Static analysis for Rails: SQLi, XSS, mass assignment, redirects, etc.
    Maps to many V5 (validation/encoding) requirements."""
    if not shutil.which("brakeman"):
        return {"tool": "brakeman", "status": "unavailable",
                "hint": "gem install brakeman"}
    code, out, err = _run(["brakeman", "-f", "json", "-q", "--no-pager"])
    if out.strip().startswith("{"):
        data = json.loads(out)
        warns = data.get("warnings", [])
        return {"tool": "brakeman", "status": "ok",
                "warning_count": len(warns),
                "by_type": _tally(w.get("warning_type") for w in warns),
                "warnings": [{"type": w.get("warning_type"),
                              "message": w.get("message"),
                              "file": w.get("file"),
                              "line": w.get("line"),
                              "confidence": w.get("confidence")}
                             for w in warns]}
    return {"tool": "brakeman", "status": "error", "stderr": err[:500]}


def bundler_audit():
    """Dependency CVEs via bundler-audit + ruby-advisory-db. Maps to V14.2.x."""
    if not shutil.which("bundle-audit") and not shutil.which("bundler-audit"):
        return {"tool": "bundler-audit", "status": "unavailable",
                "hint": "gem install bundler-audit && bundle-audit update"}
    _run(["bundle-audit", "update"], timeout=120)
    code, out, err = _run(["bundle-audit", "check"])
    # Each advisory block starts with a "Name:" line; a gem can appear in more
    # than one block. (Don't count "CVE:"/"GHSA:" — a block may carry both, and
    # older bundler-audit used "Advisory:" instead, which this once relied on.)
    gems = re.findall(r"^Name: (.+)$", out, re.M)
    return {"tool": "bundler-audit", "status": "ok",
            "advisories": len(gems),
            "vulnerable_gems": len(set(gems)),
            "clean": len(gems) == 0,
            "raw": out[:4000]}


def grep_eval():
    """Locate eval()/dynamic execution. Maps to V5.2.4, V5.5.4.

    Deliberately does NOT match bare `send(` — it is pervasive in idiomatic
    Ruby and buries the real signal in false positives. `public_send(` is the
    intentional dynamic-dispatch form worth inspecting; Brakeman's
    "Dangerous Send" check covers untrusted-input dispatch more precisely."""
    if not shutil.which("grep"):
        return {"tool": "grep-eval", "status": "unavailable"}
    code, out, err = _run(
        ["grep", "-rnE", r"\beval\(|instance_eval|class_eval|\bpublic_send\(",
         "app", "lib"])
    hits = [l for l in out.splitlines() if l.strip()]
    return {"tool": "grep-eval", "status": "ok",
            "hit_count": len(hits), "hits": hits[:100]}


def headers(url):
    """Fetch response headers; assess CSP/HSTS/etc. Maps to V14.4.x."""
    checks = ["Content-Security-Policy", "Strict-Transport-Security",
              "X-Content-Type-Options", "X-Frame-Options", "Referrer-Policy",
              "Permissions-Policy"]
    try:
        ctx = ssl.create_default_context()
        req = urllib.request.Request(url, method="GET",
                                     headers={"User-Agent": "asvs-security"})
        with urllib.request.urlopen(req, timeout=30, context=ctx) as r:
            got = {k: v for k, v in r.headers.items()}
        present = {h: got.get(h) for h in checks}
        return {"tool": "headers", "status": "ok", "url": url,
                "present": {h: (v is not None) for h, v in present.items()},
                "values": present}
    except Exception as e:
        return {"tool": "headers", "status": "error", "url": url, "error": str(e)}


def tls(host):
    """Note: full TLS grading is best done via SSL Labs. This is a liveness/
    cert presence probe only. Maps to V9.1.x/V9.2.x (confirm with SSL Labs)."""
    try:
        ctx = ssl.create_default_context()
        with ctx.wrap_socket(__import__("socket").socket(),
                             server_hostname=host) as s:
            s.settimeout(15)
            s.connect((host, 443))
            cert = s.getpeercert()
            ver = s.version()
        return {"tool": "tls", "status": "ok", "host": host,
                "protocol": ver, "cert_subject": dict(x[0] for x in cert["subject"]),
                "note": "Run https://www.ssllabs.com/ssltest for full grade"}
    except Exception as e:
        return {"tool": "tls", "status": "error", "host": host, "error": str(e)}


def _tally(it):
    out = {}
    for x in it:
        out[x] = out.get(x, 0) + 1
    return out


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd = sys.argv[1]
    arg = sys.argv[2] if len(sys.argv) > 2 else None
    if cmd == "brakeman":
        res = brakeman()
    elif cmd == "bundler-audit":
        res = bundler_audit()
    elif cmd == "grep-eval":
        res = grep_eval()
    elif cmd == "headers":
        res = headers(arg)
    elif cmd == "tls":
        res = tls(arg)
    elif cmd == "all":
        res = {"brakeman": brakeman(), "bundler_audit": bundler_audit(),
               "grep_eval": grep_eval()}
        if arg:
            res["headers"] = headers(arg)
            res["tls"] = tls(arg.replace("https://", "").replace("http://", "").strip("/"))
    else:
        sys.exit(__doc__)
    print(json.dumps(res, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
