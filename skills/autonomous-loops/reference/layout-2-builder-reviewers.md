# Layout 2: Builder + reviewers

The builder's work lands as PRs. Each PR gets 2–3 independent, read-only reviewers from **other providers**, capped at a fixed number of rounds. This is a component: layout 1 and every worker in layout 4 use it.

## Setup, per PR
1. Create one detached worktree per reviewer at the PR head: `git worktree add --detach .worktrees/review-<pr>-{a,b,c} <sha>`. Each reviewer mutates code in its own worktree and must never touch the builder's.
2. Write one brief per reviewer to `temp/review-<pr>/{a,b,c}.md` ([../templates/reviewer-brief.md](../templates/reviewer-brief.md)), each with a distinct focus:
   - a = correctness and security;
   - b = tests and mutation;
   - c = user impact and evidence.
3. Start them with `orchestration_create_agent`:
   - `kind`: codex, or opencode/pi for the rotating non-Codex slot;
   - `cwd`: the reviewer's worktree;
   - `runId`: `review-<pr>`;
   - `prompt`: `Read <brief path> and follow it exactly`.
4. Don't block. Check for `temp/review-<pr>/report-{a,b,c}.md` between other work. Close each reviewer as soon as its report exists.
5. Triage every finding against the code: fix it, or decline it with a stated reason.
6. **READY rule:** a reviewer whose latest verdict is FIX-BEFORE-MERGE does one focused verification pass (`round2-report-<x>.md`) and must end MERGE-READY. A disposition that says "addressed" is not verification.
7. Post **one public disposition comment** that covers every finding. Make the PR body true for the final head. Then merge, or hand the PR to the manager.

## The two reviewer instructions that find the most bugs
- **Mutate the implementation, one change at a time, and report which mutations survive.** A surviving mutation is a finding about the tests. One reviewer who mutated beat two who only read.
- **Count the real data** (transcripts, recordings, lockfiles) instead of reasoning about what it looks like.

## Round cap
- Pick 1 or 2 rounds and keep to it.
- After the cap, a manager verification ([../templates/manager-verify.md](../templates/manager-verify.md)) closes the loop. It reverts each fix, shows the test fails, restores the fix, and gives a verdict.
- Anything still open is written into the PR body as a precise residual, never another round.

## Provider mix
- Reviewers never share the builder's provider. In the 2026-09 loop the workers were Claude, so Claude was never a reviewer.
- Rotate which focus letter gets the non-Codex model, so each focus sees different models over time.
- Skip any provider at 90% quota or above. At 75%, give it at most one slot per round.
