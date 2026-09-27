# Layout 4: Manager + workers

This is the layout for **a list of many independent items**, such as a triaged backlog or a sweep across several bug classes, where one agent is the bottleneck. In the serial version (fix, then ~10 minutes of review, then fix, then merge), the agent spends most of its time waiting. Workers do that waiting in parallel.

## Roles

| Role | Count | Owns | Never |
|---|---|---|---|
| **Manager** | 1 | the queue and ledger, assignments, the merge gate and batches, issue sync, owner questions, reviving workers, the tick | writes feature code |
| **Worker** | 3–4, same provider | ONE item at a time end to end, up to READY: worktree → plan commit → fail-first test → fix → PR → its own reviewers → disposition → READY | merges; touches another worker's claim, branch or worktree; prompts anyone but the manager |
| **Reviewers** | 3 per PR, other providers | one read-only report each | edit, push, comment or spawn |
| **Steering watcher** | 1, another provider | notes on process and direction (layout 3) | builds, merges or closes |

Four workers was the limit on one laptop. With more, the type checks and test suites saturate the CPU: one `tsc -b` took over 14 minutes.

## Lanes
- Each worker owns the bug classes or area it is expert in, for example W1 = prompt delivery/Codex, W2 = identity/rendering, W3 = stores/unbounded growth, W4 = tests/fail-all. Lane affinity only orders the queue; a worker can still take anything.
- Give every agent a fixed Dispatch lane, for example watcher, B-x, manager, B-y on the top row and W1–W4 below, so the owner can watch the fleet.

## Setup
1. **Ledger and queue.** Triage first. Every candidate issue needs a severity label (`sev:P0..P3`), plus `class:*` and `type:*`. Issues that need a decision get `needs-owner`, or `needs-evidence` when data is missing, and the queue skips both.
2. **The manager's files**, in a git-ignored `temp/manager/`:
   - `plan.md`: roles, gates and owner decisions ([../templates/manager-plan.md](../templates/manager-plan.md));
   - `worker-common.md`: every rule a fresh worker needs ([../templates/worker-rules.md](../templates/worker-rules.md));
   - `workers.md`: the sessionId table;
   - `queue.md`: lanes and handovers;
   - `usage.md`: the provider quota table, refreshed each tick;
   - `status/wN.md`: one per worker, 5 lines;
   - `assign/wN-<topic>.md`: one per instruction;
   - `claims/<issue>/owner`: the claim locks;
   - `next-issue.sh`: picks and claims the next issue ([../templates/scripts/next-issue.sh](../templates/scripts/next-issue.sh));
   - `merge-gate.sh`: the only way anything merges ([../templates/scripts/merge-gate.sh](../templates/scripts/merge-gate.sh));
   - `verify-template.md`: the manager verification at the round cap.
3. **Create the workers.**
   - `ac_agents_create`, titled `W1 <lane>` and so on.
   - `ac_dispatch_configure lane-select` into their lanes.
   - Send each a one-line prompt: `Read temp/manager/worker-common.md and temp/manager/assign/wN-1.md, then start your goal loop.`
4. **Workers run their own goal loops** (the loop prompt is inside worker-common.md): pick with `next-issue.sh`, advance one step, write status, repeat.
5. **The manager runs on a tick** (layout 5), or on a goal loop if the owner is present.

## Claims: no two workers on one item
- The lock is `mkdir temp/manager/claims/<N>`. mkdir is atomic, so exactly one worker wins.
- The owner file records the worker, the time and the branch. Append `done <sha|reason>` when finished. Never delete the directory, so the item is never taken again.
- `next-issue.sh W<n>` is the only way to pick work. It ranks by severity, then lane affinity, then oldest first. It skips anything unlabelled, `needs-owner`, `needs-evidence`, owner-only, already claimed, or already named by an open PR's closing references.
- **File overlap:** before editing a file that another open PR changes, the worker stops and tells the manager.

## Worker → manager protocol
- The status file's first line is one of `REVIEW #N`, `READY #N <sha>`, `NEED-MANAGER <why>` or `IDLE`, followed by `item | PR | stage | blocker | next`.
- Workers also call `tldr_update`. The manager reads the whole fleet in one `ac_agents_batch_read` call at `status` depth.
- The manager writes every instruction to `assign/wN-<topic>.md`, then sends a one-line pointer. When a prompt delivery times out it can strand in the worker's composer, and every later prompt is then refused. Workers therefore also `ls -t assign/wN-*` at each continuation.

## Merging: integration batches
Merging each READY PR separately means each one must first merge current main and pass a full CI run. With 16 CI runs queued, that stalls. Batches instead:
1. `git fetch origin`, then create `integration/batch-<id>` from **fresh** origin/main and push it.
2. For each member:
   - `merge-gate.sh <repo> <pr> <review-dir> --member`, which checks reviews, disposition, labels and green CI, but not the behind-count;
   - then `gh pr edit <pr> --base integration/batch-<id>`;
   - then `gh pr merge <pr> --merge`.
   History then reads "Merge pull request #N". On a conflict, stop and hand the PR back to its worker. Never resolve it inside the batch.
3. Open the batch PR as a draft.
   - Build its body with a script and `--body-file`, never `sed` into `--body` (a failed sed wipes the body).
   - Copy each member's `Fixes`/`Refs` line **from the member's own body**, never from GitHub's closing references, which include sidebar links.
   - A merge into a non-default branch closes no issue, so the batch body must carry the trailers.
4. Post a disposition comment listing the members and their gates.
5. Wait for green CI on the exact batch head.
6. Put the body in past tense. Conditions such as "merge only after X" belong in comments. Then check `closingIssuesReferences`.
7. Run `merge-gate.sh <repo> <batch> --dry` and record the PASS in a comment. Then `gh pr ready`, then `gh pr merge --merge`.
8. **After any merge, main has moved.** Every other READY PR or batch re-gates on the new main before it merges. Never merge two old green heads back to back.

## Manager verification at the round cap
When a worker has spent its review rounds and a reviewer still says FIX, the manager spawns check agents with [../templates/manager-verify.md](../templates/manager-verify.md). For each finding, the check agent:
- locates the fix and its test;
- shows the test passes;
- reverts the fix and shows the test fails;
- restores the fix;
- tries one extra real attack.

The result goes to `temp/review-N/manager-verify-<x>.md`, which ends with `MERGE-READY` or `FIX — <exact sequence>`. The gate counts it as that reviewer's latest verdict.

## Freezing
When open PRs pile up (35 at one point), the owner can call a **PR freeze**:
- `next-issue.sh` exits early;
- workers only move their existing PRs to READY;
- newly found bugs become issues.

The manager then drains the PRs through batches. Lift the freeze only on the owner's word.
