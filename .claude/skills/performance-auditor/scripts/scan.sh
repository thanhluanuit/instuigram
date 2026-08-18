#!/usr/bin/env bash
# Candidate scanner for HIGH-SIGNAL Rails performance anti-patterns.
# Every hit is a CANDIDATE to verify by reading the code — not a confirmed finding.
# Deliberately narrow: an 8-pattern scan people trust beats a noisy one they mute.
# For N+1 that only shows at runtime, and for cache/index issues, use
# scripts/runtime_evidence.py on a pg_stat_statements export and reference-guided
# inspection instead.
# Usage: scripts/scan.sh [paths...]   (defaults to app lib)
set -uo pipefail

PATHS=("$@")
[ ${#PATHS[@]} -eq 0 ] && PATHS=(app lib)

# Fail loudly on a bad path: a scan that silently finds nothing reads as "all clear".
missing=0
for p in "${PATHS[@]}"; do
  [ -e "$p" ] || { echo "error: no such path: $p" >&2; missing=1; }
done
[ "$missing" -eq 1 ] && { echo "Run this from the repo root, with paths relative to it." >&2; exit 2; }

if command -v rg >/dev/null 2>&1; then
  search() { rg -n --no-heading "$1" "${PATHS[@]}"; }
  searchv() { rg -n --no-heading "$1" "${PATHS[@]}" | rg -v "$2"; }
else
  search() { grep -rEn "$1" "${PATHS[@]}"; }
  searchv() { grep -rEn "$1" "${PATHS[@]}" | grep -vE "$2"; }
fi

section() {
  local title="$1" pattern="$2" out
  out="$(search "$pattern")"
  [ -n "$out" ] && { echo "── ${title} ──────────────────────────────────"; echo "$out"; echo; }
}
section_excluding() {
  local title="$1" pattern="$2" exclude="$3" out
  out="$(searchv "$pattern" "$exclude")"
  [ -n "$out" ] && { echo "── ${title} ──────────────────────────────────"; echo "$out"; echo; }
}

echo "Rails performance candidate scan (high-signal only) — verify each hit in the code."
echo "paths: ${PATHS[*]}"; echo

# High precision: these regexes rarely fire on correct code.
section "N+1 count/exists  (.count > 0 / .length == 0 → .exists?)"  '\.count\s*[<>=!]=?\s*0|\.length\s*==\s*0'
# Bare '.map(&:' matches every plain-Ruby array map — hundreds of hits on a real app, which
# is exactly the noise that gets a scan muted. Require an AR-relation receiver on the line.
section "map vs pluck  (relation.map(&:attr) → .pluck(:attr))"     '\.(all|where\([^)]*\)|order\([^)]*\)|limit\([^)]*\)|includes\([^)]*\))\.map\(&:'
section "includes used only to filter  (.includes(...).where → .joins)" '\.includes\([^)]*\)\.where\('
section "load full collection  (.all.each/.map → find_each)"       '\.all\.(each|map|select|reject|find)\b'
section "sync mail in request  (deliver_now → deliver_later)"      'deliver_now'
section "sync external HTTP in web layer  (→ background job)"      'Net::HTTP|Faraday|HTTParty|RestClient|Typhoeus'
section "sync heavy processing in request  (image/pdf → job)"     'MiniMagick|ImageProcessing|Prawn|image_processing'
# Same-line heuristic: fetch without a visible TTL. Multi-line blocks may false-positive; labeled as a review prompt.
section_excluding "cache TTL review  (Rails.cache.fetch without expires_in on the line)" 'Rails\.cache\.fetch\(' 'expires_in'

echo "Done. Next:"
echo "  • confirm each hit against references/rails-antipatterns.md"
echo "  • for N+1 that hides at runtime, export pg_stat_statements and run:"
echo "      scripts/runtime_evidence.py pgstat <pg_stat.csv>"
