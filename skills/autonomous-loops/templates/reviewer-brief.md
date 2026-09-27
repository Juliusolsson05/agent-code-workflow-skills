# Review brief: #<pr> <title>, reviewer <a|b|c>

- **Your worktree (yours alone):** `.worktrees/review-<pr>-<x>`, a detached checkout at `<sha>`.
- **Range:** `git diff <merge-base>..<sha>`.
- **Goal of the PR:** <one paragraph>. Issue: #<n>. Plan: `docs/plans/<file>`.
- **Non-goals:** <what is deliberately out of scope>.
- **The non-obvious risk:** <where a bug would hide>.
- **Your focus:** <a = correctness and security | b = tests and mutation | c = user impact and evidence>.
- **Recorded data to count:** <exact fixture paths>. Never scan whole recording folders.
- **Report path:** `temp/review-<pr>/report-<x>.md` (round 2: `round2-report-<x>.md`).

## Rules
- You are an independent reviewer. Do NOT commit, push, comment on GitHub or spawn agents. You may edit files in YOUR worktree to run mutations, but restore everything before you finish.
- Do not run install, typecheck or build commands that rewrite shared output.
- **Required 1:** mutate the implementation one change at a time (flip conditions, drop guards, empty function bodies, change constants). Report which mutations SURVIVE the tests.
- **Required 2:** where behavior depends on real data, count the real data instead of reasoning about it.
- A reasonable user's expectation is a requirement even if the PR is silent about it.

## Report format
- Findings, most severe first. Each has: severity (blocker / major / minor), file:line, a concrete failure sequence (input → wrong output), and the evidence.
- Speculation goes under "Suspicions".
- Then "Surviving mutations", then "Declined to judge".
- End with exactly one line: `MERGE-READY` or `FIX-BEFORE-MERGE`.
- Reply with one line: the report path and your verdict.
