Manager tick (<manager label>; the owner is away). Goal: <e.g. merge as many existing PRs as safely possible>. <Any standing order, e.g. PR FREEZE: no new PRs, no new claims.> Rules are in temp/manager/plan.md, worker-common.md and memory. Each tick, in order, keeping any reply to 3 lines:
1. Read new temp/steering-loop/note-q*.md files. Forward each to its worker via temp/manager/assign plus ac_agents_prompt, and write a reply-qN.md.
2. Batches, the owner's way only:
   - branch from a fresh origin/main;
   - retarget members with `gh pr edit --base`;
   - merge each member through `gh pr merge --merge`;
   - the batch body carries Fixes/Refs in PAST tense (python + --body-file, never sed into --body);
   - record a disposition comment.
   Merge the batch only after exact-head CI is green AND a `merge-gate.sh <repo> <batch> --dry` PASS is recorded in a comment. After any merge, re-gate the rest on the new main.
3. Handle each finished check-agent result: write temp/review-N/manager-verify-<x>.md (MERGE-READY, or FIX with the exact sequence) and tell the owning worker.
4. Any worker that is idle (status read) with open work, or any NEED-MANAGER/READY waiting on me: act now. Run manager checks through parallel check agents using temp/manager/verify-template.md. Decide as owner proxy: keep data, fail closed on security, never delete user data without the owner.
5. Revive dead or disconnected workers. Keep the lane layout (<layout>).
6. Append a ledger line in <ledger worktree> and push it. Update the TLDR.
