#!/usr/bin/env bash
# The merge gate as ONE command, so no check can be skipped by hand. Every check must
# pass; otherwise it prints why and exits 1 without merging.
#
# Usage: merge-gate.sh <owner/repo> <pr> [review-dir] [--dry|--member]
#   --dry     check only (workers ALWAYS pass this; a bare run MERGES)
#   --member  check a batch member: it may be behind main (the batch brings main in)
set -uo pipefail
REPO="${1:?owner/repo}"; PR="${2:?pr}"; REVIEW="${3:-}"; MODE="${4:-}"
case "$REVIEW" in --dry|--member) MODE=$REVIEW; REVIEW="";; esac
ROOT="${LOOP_ROOT:-$PWD}"
fail() { echo "GATE FAIL #$PR: $*"; exit 1; }

json=$(gh pr view "$PR" -R "$REPO" --json headRefOid,headRefName,baseRefName,mergeStateStatus,isDraft,body,comments,labels) || fail "cannot read PR"
head=$(jq -r .headRefOid <<<"$json"); branch=$(jq -r .headRefName <<<"$json"); base=$(jq -r .baseRefName <<<"$json")
body=$(jq -r .body <<<"$json")

# 1. Owner-held items need a recorded owner approval.
if grep -qiE 'UNCONFIRMED|needs-owner|owner decision' <<<"$body"; then
  jq -r '.comments[].body' <<<"$json" | grep -q 'OWNER-APPROVED:' || fail "owner items without an OWNER-APPROVED: comment"
fi
# 2. Body tripwire: stale-state wording means the body does not describe the final head.
grep -qiE 'not done yet|not yet done|stacked on|needs? retarget|TODO|merge only after' <<<"$body" \
  && fail "body has stale-state wording; make it true for the final head (past tense)"
# 3. Contains the current base (members are exempt: their batch is built from main).
if [ "$MODE" != "--member" ]; then
  behind=$(gh api "repos/$REPO/compare/$base...$branch" -q .behind_by) || fail "compare failed"
  [ "$behind" = "0" ] || fail "$behind commits behind $base"
fi
# 4. Mergeable.
state=$(jq -r .mergeStateStatus <<<"$json")
if [ "$MODE" = "--member" ]; then [ "$state" = "DIRTY" ] && fail "conflicts with $base"
else case "$state" in CLEAN|HAS_HOOKS) ;; *) fail "mergeStateStatus=$state";; esac; fi
# 5. Every check green on this exact head.
checks=$(gh pr checks "$PR" -R "$REPO" --json state -q '[.[].state]|unique|join(",")')
[ "$checks" = "SUCCESS" ] || fail "checks=$checks"
run_head=$(gh run list -R "$REPO" --branch "$branch" --limit 1 --json headSha -q '.[0].headSha')
[ "$run_head" = "$head" ] || fail "latest CI run is on ${run_head:0:8}, not head ${head:0:8}"
# 6. A public disposition exists.
[ "$(jq '.comments|length' <<<"$json")" -ge 1 ] || fail "no disposition comment"
# 7. Each reviewer's LATEST verdict is MERGE-READY (a manager-verify file counts when newest).
if [ -n "$REVIEW" ]; then
  for x in a b c; do
    latest=$(ls -t "$ROOT/$REVIEW"/*report*-"$x".md "$ROOT/$REVIEW"/manager-verify-"$x".md 2>/dev/null | head -1)
    [ -n "$latest" ] || fail "no report for reviewer $x"
    v=$(grep -oE 'MERGE-READY|FIX-BEFORE-MERGE|FIX —' "$latest" | tail -1)
    [ "$v" = "MERGE-READY" ] || fail "reviewer $x latest ($(basename "$latest")) is ${v:-no verdict}"
  done
fi

echo "GATE PASS #$PR (${head:0:8}, checks green, reviews OK)"
[ -n "$MODE" ] && exit 0
[ "$(jq -r .isDraft <<<"$json")" = "true" ] && gh pr ready "$PR" -R "$REPO" >/dev/null
gh pr merge "$PR" -R "$REPO" --merge
