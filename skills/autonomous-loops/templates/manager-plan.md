# Manager + <N> workers: plan

## Why
<The bottleneck this layout removes.>

## Roles
- **Manager (<label>, <sessionId>).** Never writes feature code. Owns the queue and ledger, assignments, the merge gate and batches, issue sync and labels, owner questions (short, yes/no), steering replies, and reviving workers.
- **W1–W<N> (<provider>, one lane each).** One item at a time, end to end, up to READY. Workers never merge.
- **Reviewers.** 3 per PR, on providers other than the workers'. The workers start them.
- **Steering watcher (<provider>, <sessionId>).** Notes only.

## Communication
- Worker → manager: `status/wN.md` (first line REVIEW / READY / NEED-MANAGER / IDLE, then `item | PR | stage | blocker | next`), plus `tldr_update`.
- Manager → worker: `assign/wN-<topic>.md`, plus a one-line `ac_agents_prompt` pointer.
- The manager polls with `ac_agents_batch_read` at `status` depth. It never busy-waits.

## Owner decisions (yes/no), recorded with time
1. …

## Manager gates
- **Before a PR joins a batch:** 3 reviewer reports; each reviewer's latest verdict is MERGE-READY; one public disposition covers every finding; the body matches the head; Fixes vs Refs is correct; labels are set; `merge-gate.sh --member` passes.
- **Batch:** built from fresh origin/main; members are retargeted and merged through GitHub; trailers are copied from member bodies; the body is in past tense; CI is green on the exact head; the `--dry` PASS is recorded; then merge.
- **After any merge:** re-gate everything else on the new main.
- **Owner-only work is never assigned:** <list>.
- **Body truth:** read the body top to bottom against the final head before every merge.

## Every tick
See `manager-tick-prompt.md`.
