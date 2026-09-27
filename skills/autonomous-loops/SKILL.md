---
name: autonomous-loops
description: "Use when the user asks Agent Code to run a loop, keep going on its own, work through a list overnight, set up workers, a manager, a steering or watcher agent, a review pipeline, a fleet, or says start the loop, run autonomously, burn down the backlog, or I will be back in an hour. Picks one of five loop layouts (solo goal loop, builder plus reviewers, loops plus a steering watcher, manager plus workers, timed manager tick), then sets up its ledger, briefs, gates and the Agent Code tools that start and keep it running."
license: MIT
---

# Autonomous loops in Agent Code

A loop is a contract that has to survive without you. It needs:

- a written goal;
- a ledger that says what is done;
- gates that stop bad work from landing;
- a way to wake up again.

The agent's memory is not one of those things. Anything that only lives in a conversation is lost at the next compaction, reload or crash.

This skill is for Agent Code, the desktop app that runs Claude Code, Codex, OpenCode, Grok and Pi agents side by side. It gives agents MCP tools to set goals, loop, spawn children, and prompt and read each other. [reference/primitives.md](reference/primitives.md) lists every tool used here and what it really does.

## Pick the layout

Start with the smallest layout that fits. Every extra agent adds quota burn, machine load and coordination bugs.

| # | Layout | Use when | Agents |
|---|---|---|---|
| 1 | [Solo goal loop](reference/layout-1-solo-goal-loop.md) | One outcome, one agent can do it, it takes hours | 1 |
| 2 | [Builder + reviewers](reference/layout-2-builder-reviewers.md) | Work lands as PRs that must be reviewed before merge | 1 + 2–3 per PR |
| 3 | [Loops + steering watcher](reference/layout-3-steering-watcher.md) | One or two long loops run unattended and you want an independent check on direction and process | 2–3 |
| 4 | [Manager + workers](reference/layout-4-manager-workers.md) | A list of many independent items (a backlog, a bug-class sweep) that one agent works through too slowly | 1 + 3–4 + reviewers + watcher |
| 5 | [Timed manager tick](reference/layout-5-manager-tick.md) | The coordinator must act on a clock (every 5 minutes) while the owner is away, not only when it is prompted | the coordinator of 3 or 4 |

Layouts stack. The advanced loop behind this skill, [the 2026-09 quality loop](reference/case-study-quality-loop.md), combined layouts 2, 3, 4 and 5. Between 2026-09-25 and 09-27 it merged 181 PRs across six repos (including 160 in the app, counting the batch PRs). It closed 135 issues and filed 138 new ones found by its own bug hunts. On the last day it took 35 open PRs down to 2. It survived network drops, dead agent processes and two disk-full events along the way.

```
one outcome, hours of work ──────────────► 1 solo goal loop
   └─ lands as PRs ──────────────────────► + 2 reviewers per PR
        └─ runs overnight, unattended ───► + 3 steering watcher
many independent items ──────────────────► 4 manager + workers (each worker = 1 + 2)
   └─ owner away, must act on a clock ───► + 5 manager tick
```

## The five things every loop needs

1. **A ledger in git.** A plan file on its own branch holds the outcome, the "done" definition, the item list with states, the decisions, and an append-only progress log. Commit and push it every iteration. It is the one thing that survives compaction. If it disagrees with GitHub, GitHub wins and you fix the ledger. Use [templates/ledger.md](templates/ledger.md).
2. **A self-contained loop prompt.** `goal_loop_start` re-sends `loopPrompt` every time the agent stops, so write it as if for a stranger: where the ledger is, the steps for each pass, the stop rule. Never write "continue as before".
3. **Briefs as files, prompts as pointers.** Long prompts sent to Claude children fail or get stranded in the composer. Write each brief to a git-ignored file (`temp/<loop>/…md`), then send a one-line prompt: `Read <path> and follow it exactly`. Files are also the fallback channel when a prompt delivery times out.
4. **Gates as scripts, not as memory.** Any check that was once skipped by hand becomes a script that refuses: CI green on the exact head, 0 commits behind base, the review verdicts, the body tripwire, owner holds. See [templates/scripts/merge-gate.sh](templates/scripts/merge-gate.sh).
5. **An explicit stop rule.**
   - Call `goal_loop_complete` only when every item is done.
   - Call it with outcome `blocked` when only owner decisions remain.
   - Never stop just to wait: while CI or reviewers run, work the next item.

## Setting one up

1. **Recite and decide.** Restate the outcome and the "done" state to the user. Propose defaults for the open decisions: reviewer providers, round cap, merge authority, worker count, tick interval. Wait for "start".
2. **Write the ledger** (as its own branch or worktree) and the briefs.
3. **Set your goal** with `goal_set`, in one plain sentence.
4. **Create the agents.**
   - Workers you manage and keep: `ac_agents_create`, with a title, then `ac_dispatch_configure lane-select` to give each a fixed lane.
   - Short-lived reviewers: `orchestration_create_agent`, with a `runId` per PR.
   - Send each agent a one-line pointer to its brief.
5. **Start the loops.**
   - Each long-running agent calls `goal_loop_start` itself (the brief tells it to, with the exact `loopPrompt`; `maxContinuations` up to 200).
   - A coordinator that must act on a clock uses a timer instead (layout 5).
6. **Tell the user** what is running, where the ledger is, and which decisions only they can make. Keep it to 3–6 lines.

## Rules that every layout inherits

These were each learned from a real failure (see [reference/failure-modes.md](reference/failure-modes.md)):

- **Merge authority is explicit and scoped.** "Merge" approval for one PR or one loop does not carry over to the next. Owner-only items (product defaults, UX calls, data deletion) are never auto-merged. Write them into a list and ask once.
- **Never delete user data without the owner**, even when a steering note or a worker says it is safe. Keep the data, collect only new garbage, and ask.
- **Unknown is never empty.** A failed read before a prune means "protect", never "nothing there".
- **One writer per item.** Claims are atomic (`mkdir claims/<N>`). No two agents ever touch the same issue, branch or worktree.
- **Every agent says where it is.**
  - `tldr_update` after each stage.
  - A 5-line status file: `item | PR | stage | blocker | next`.
  - A ledger line per pass.
- **Close finished children.** Every open agent costs renderer CPU. When 60 finished reviewers were left open, the load average hit 330.
- **Cap concurrency to the machine.**
  - Review rounds: at most 3 reviewers per worker at once.
  - Type checks and full test suites: one of each per worker at a time.
  - Batch merges so CI runs once per batch, not once per PR.
- **Spread quota across providers.** Read usage (`ac_usage_read` or the `usage` MCP domain) each tick. Never use a provider at 90% or above. Don't use the workers' provider as a reviewer.
- **Reports to the owner are short.** Lead with 3–6 lines and yes/no questions. The detail goes in the ledger, the PRs and the files.

## Files in this skill

- [reference/primitives.md](reference/primitives.md): the Agent Code and Claude Code tools, their limits and traps.
- `reference/layout-*.md`: one file per layout, each with a setup recipe and a ready loop prompt.
- [reference/case-study-quality-loop.md](reference/case-study-quality-loop.md): the full manager + 4 workers + watcher + tick loop, how it evolved, and its numbers.
- [reference/failure-modes.md](reference/failure-modes.md): every failure that produced a rule.
- `templates/`: ledger, manager plan, worker rules, steering brief, reviewer brief, manager verification, the owner-away tick prompt, and the claim and merge-gate scripts.
