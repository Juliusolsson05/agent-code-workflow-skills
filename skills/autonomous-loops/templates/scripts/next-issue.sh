#!/usr/bin/env bash
# Pick AND claim the next issue for a worker, so nobody hands out work by hand.
#
#   candidates = open issues with a sev:* label (triaged)
#                minus needs-owner / needs-evidence
#                minus OWNER_ONLY issues
#                minus issues already claimed (claims/<N> exists)
#                minus issues an open PR already names in its closing references
#   order      = severity (P0 > P1 > P2 > P3), then lane affinity, then oldest first
#   claim      = the first candidate whose `mkdir claims/<N>` succeeds. mkdir is atomic,
#                so when two workers race for one issue, exactly one wins.
#
# Usage: next-issue.sh W1         -> prints the claimed issue number, or NONE
#        next-issue.sh W1 --dry   -> prints the top 10 candidates, claims nothing
#
# Freeze: uncomment the next line to stop all new claims (exit 3).
# echo "PR FREEZE: no new issues. Work only on your open PRs." >&2; exit 3
set -euo pipefail
WORKER="${1:?usage: next-issue.sh W1|W2|... [--dry]}"
DRY="${2:-}"
ROOT="${LOOP_ROOT:?set LOOP_ROOT to the repo checkout}"
CLAIMS="$ROOT/temp/manager/claims"
OWNER_ONLY="${OWNER_ONLY:-}"          # space-separated issue numbers only the owner decides
mkdir -p "$CLAIMS"; cd "$ROOT"

# Lane affinity: each lane's labels are picked first. Everything else is still pickable, just later.
case "$WORKER" in
  W1) LANE="class:C1 provider:codex" ;;
  W2) LANE="class:C2 class:C8" ;;
  W3) LANE="class:C6 class:C3" ;;
  W4) LANE="class:C9 class:C5" ;;
  *) echo "unknown worker $WORKER" >&2; exit 2 ;;
esac

ISSUES=$(gh issue list --state open --limit 500 --json number,labels)
LINKED=$(gh pr list --state open --limit 100 --json closingIssuesReferences -q '[.[].closingIssuesReferences[].number] | map(tostring) | join(" ")')

CANDIDATES=$(ISSUES="$ISSUES" LINKED="$LINKED" LANE="$LANE" OWNER_ONLY="$OWNER_ONLY" CLAIMS="$CLAIMS" python3 - <<'PY'
import json, os
issues = json.loads(os.environ["ISSUES"])
linked = set(os.environ["LINKED"].split()); lane = set(os.environ["LANE"].split())
owner_only = set(os.environ["OWNER_ONLY"].split())
claims = {c.split(".")[0] for c in os.listdir(os.environ["CLAIMS"])}
rank = {"sev:P0": 0, "sev:P1": 1, "sev:P2": 2, "sev:P3": 3}
rows = []
for issue in issues:
    n = str(issue["number"]); labels = {l["name"] for l in issue["labels"]}
    sev = [rank[l] for l in labels if l in rank]
    if not sev or labels & {"needs-owner", "needs-evidence"}: continue
    if n in owner_only or n in linked or n in claims: continue
    rows.append((min(sev), 0 if labels & lane else 1, int(n)))
for sev, affinity, n in sorted(rows):
    print(f"{n} P{sev} {'lane' if affinity == 0 else 'other'}")
PY
)

if [ "$DRY" = "--dry" ]; then echo "$CANDIDATES" | head -10; exit 0; fi
while read -r N _; do
  [ -z "$N" ] && continue
  if mkdir "$CLAIMS/$N" 2>/dev/null; then
    echo "$WORKER $(date -u +%FT%TZ) claimed by next-issue.sh" > "$CLAIMS/$N/owner"; echo "$N"; exit 0
  fi
done <<< "$CANDIDATES"
echo "NONE"
