# Failure modes → rules

Every rule in this skill exists because the failure below happened at least once.

## Communication
| Failure | Rule |
|---|---|
| A long prompt to a Claude child fails, or arrives truncated. | Put the brief in a file and send a one-line pointer prompt. |
| A prompt delivery times out and strands the text in the agent's composer. Every later prompt is then refused. | Every instruction is also written to `assign/wN-*.md`. Workers check the newest one at each continuation. The manager reloads a stuck agent. |
| Labels (B6, W2) shift after lane changes, and a note goes to the wrong agent. | Address agents by sessionId only. Keep the id table in `workers.md`. |
| A steering note goes unanswered, and its rule is forgotten. | Every `note-qN` gets a `reply-qN`. |
| The owner comes back to 40 lines of relay. | Reply in 3–6 lines with yes/no questions. The detail goes in files. |

## Machine and quota
| Failure | Rule |
|---|---|
| 60 finished reviewers left open pushed the renderer to 244% CPU (load ~330). | Close each reviewer when its report file exists. Cap each worker at 3 concurrent reviewers. |
| Four workers running parallel `tsc` and full suites took a type check to 14 minutes. | One type check and one full suite per worker at a time, queued in a background script. |
| About 250 leftover worktrees filled the disk twice. | Remove the PR worktree and the review worktrees after merge, but only when `git status` is clean. |
| Reviewers grepped many GB of recordings. | Briefs name the exact fixture files. Never scan the proxy or transcript folders recursively. |
| One provider hit 100% quota mid-loop. | Read usage each tick. Skip a provider at 90% or above, and give it one slot at 75%. The workers' provider is never a reviewer. |
| A worker merged main into its PR to "stay current", and 16 CI runs queued. | Merge main into a PR only on a real conflict. Batches bring in main. |
| A Wi-Fi drop killed the agent processes while their panes still looked alive. | The tick checks status and runs `ac_agents_reload`, then sends the assignment again. |

## Merging
| Failure | Rule |
|---|---|
| A PR with an UNCONFIRMED product default was merged. | The gate refuses UNCONFIRMED, needs-owner or owner-decision wording unless an `OWNER-APPROVED:` comment exists. |
| A package PR was merged 6 commits behind its main. | The gate requires 0 behind (except `--member` inside a batch). |
| A batch was built on a stale main. | Run `git fetch` first, and branch from `origin/main`, never local `main`. |
| A batch was merged without its gate or disposition. | Record the `--dry` PASS as a comment before merge. |
| `Fixes #N` closed an issue that was only partly fixed. | `Fixes` only for the whole issue, otherwise `Refs` with the residual written down. |
| A sidebar "linked issue" closed an unrelated issue at batch merge. | Copy Fixes/Refs from member bodies. Check `closingIssuesReferences` before merge. |
| Batch bodies said "merge only after X" after the merge. | Bodies are in past tense and conditions go in comments. The gate's tripwire rejects stale wording. |
| `gh pr edit --body "$(sed …)"` wiped a body (restored from edit history). | Edit bodies with a script plus an assertion, write to a file, and use `--body-file`. |
| "Merge #N into batch" local merge commits hid the PR titles in history. | Retarget each member to the batch branch and merge it through `gh pr merge --merge`. |
| `merge-gate.sh` run without a flag actually merged. | Workers always pass `--dry` or `--member`. Only the manager runs it bare. |
| Two old green heads were merged back to back, and the combined main broke. | After any merge, re-gate everything else on the new main. |
| A disposition that said "addressed" had not been verified. | The READY rule: the reviewer who said FIX re-verifies. At the cap, a manager verification reverts each fix and shows its test fails. |

## Correctness habits
| Failure | Rule |
|---|---|
| A prune treated a failed read as "empty" and deleted live data. | Unknown is never empty: a failed read means protect or skip. Pin this with a real-filesystem fail-first test. |
| Raw provider or IPC error text reached a toast and could carry tokens. | Show only curated messages, and keep them bounded. |
| A committed fixture contained provider instruction text. | Decode every recording end to end before committing it, and redact to the same length. |
| A test tied to wall-clock time or personal history broke on another machine. | Tests use recorded fixtures and a fake clock at the edges. |
| A "flaky" timeout was widened and the bug stayed. | A timeout that fails is a bug. Never widen budgets. |
| The manager wrote "delete the data = YES" on the owner's behalf. | Data deletion is owner-only, whatever any note or agent claims. |
