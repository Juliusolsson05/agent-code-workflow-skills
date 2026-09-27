# Layout 1: Solo goal loop

One agent and one outcome, over many turns. It has no other agents to coordinate, so it is the cheapest and most reliable layout. Start here.

## When to use it
- The work is one coherent outcome: a feature, a refactor, a readiness sweep.
- One agent can hold it, and parallel agents would mostly collide on the same files.
- It takes longer than one turn, and you want it to continue without you.

## Setup
1. Recite the outcome, then agree on the "done" state and the default for each decision.
2. Write the ledger ([../templates/ledger.md](../templates/ledger.md)) on its own branch, for example `docs/<loop>` in `.worktrees/<loop>`. Commit and push it.
3. Call `goal_set`.
4. Call `goal_loop_start` with the prompt below and `maxContinuations` 50–200.

## Loop prompt
> Continue the <name> loop. Ledger: `<path>` (branch `<branch>`). Every continuation:
> 1. Re-read the ledger's status block and the last 10 progress lines. If it disagrees with GitHub, GitHub wins; fix the ledger first.
> 2. Pick the next open item in ledger order. Advance it by one real step: plan commit, then fail-first test, then fix, then PR, then review, then fix the findings, then merge per the merge rule.
> 3. Anything slow (CI, a full test suite) runs in the background. Never end the turn just to wait; take the next item.
> 4. Append one progress line to the ledger, commit and push it, and call `tldr_update`.
> Never <the things only the owner decides>. Call `goal_loop_complete` only when every item is done, or with outcome "blocked" when only owner decisions remain. Put those decisions in the ledger's Owner section.

## Traps
- **Compaction.** After a context compaction the agent knows only the summary. The ledger must hold every decision, including "we tried X, it failed because Y".
- **Stopping to wait.** Every stop costs a continuation, and the goal loop's gate holds up to 30 minutes of silence before it re-prompts. Background the wait and keep working.
- **Scope creep.** A long loop turns up bugs outside its scope. File them as issues and move on. Fixing them inline is how a 3-hour loop becomes a 3-day one.
