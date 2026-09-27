# Primitives: the tools a loop is built from

Agent Code exposes its features to agents as built-in MCP domains. An agent sees a domain's tools only when that domain is enabled for it. You enable domains in Settings → MCP, per provider. For an orchestration child, the parent chooses them with `builtInMcpDomains`, and it can only grant domains it holds itself.

Always address agents by **sessionId**. Visible labels such as B6 or W2 shift when lanes change.

## Identity and progress (domains `goal`, `tldr`)

| Tool | Use | Trap |
|---|---|---|
| `goal_set` | One plain sentence: what this agent is trying to achieve and why. Set it at the start. Change it only when the goal changes. | Progress does not go here. |
| `tldr_update` | 1–2 sentences: the decision the user must make, or else the verified outcome and the next step. Update after every stage. | A stop hook nags when you used tools without updating it. If nothing changed, say so and skip the update. |
| `goal_complete` | Only after the user has accepted the work (PR merged, or the user said done). | Never call it while a PR, review or CI is still open. The user closes agents based on it (Close Completed Agents…). |

## Goal loop (domain `goal_loop`)

| Tool | Use |
|---|---|
| `goal_loop_start({goal, loopPrompt, maxContinuations})` | The harness re-sends `loopPrompt` every time the agent stops, until it completes or the budget runs out. The default budget is 25; use up to 200 for overnight work. Use it only when the user asked for a loop. |
| `goal_loop_complete({outcome})` | Use `done` only when utterly done. Use `blocked` when only user decisions remain. |

How the goal loop decides a turn has ended: no provider signal proves it, so the gate **holds and polls**.
- 30 minutes of silence counts as ended, but running tools are exempt.
- 2 hours is the absolute limit.

A loop that waits on CI "by stopping" wastes continuations. Run long waits in the background (a Bash `run_in_background` job) and keep working instead.

**loopPrompt checklist:**
- where the ledger and briefs are;
- the ordered steps for one pass;
- what "one real step" means;
- the stop rule;
- the things the agent must never do.

The prompt is capped at 4,000 characters, so point to files for the rest.

## Children you spawn and own (domain `orchestration`)

| Tool | Use | Trap |
|---|---|---|
| `orchestration_create_agent({kind, cwd, prompt, runId, title, builtInMcpDomains})` | Reviewers, verifiers, one-off helpers. Use one `runId` per purpose, for example `review-1325`. | Children start with a **clean conversation**; context inheritance is disabled, so the brief must be self-contained. For Claude children, a long `prompt` fails. Send a one-line pointer to a brief file instead. |
| `orchestration_wait_agents({runId, timeoutMs})` | Wait for a run's children. | One call returns after 30 s at most. Keep each wait under about 110 s, and prefer checking whether the report file exists between other work. |
| `orchestration_send_prompt` | Retry a child whose first prompt failed. Pi sometimes answers "bridge not connected" at creation. | |
| `orchestration_close_agent` | Close a child as soon as its report file exists. | Every open agent is rendered: 60 finished reviewers pushed the renderer to 244% CPU. |
| `orchestration_read_agent`, `orchestration_read_run_outputs` | Read what a child said. | Output is capped; read the report file instead. |

When a parent agent is replaced or reloaded, its children follow it, including closed ones that can still be restored.

## Agents you manage like a user (domain `root_management`, gated behind a confirmation)

Use these for long-lived workers and for anything outside your own children.

| Tool | Use |
|---|---|
| `ac_agents_list` / `ac_agents_search` | Find agents by id, label, title, cwd or provider. |
| `ac_agents_create({tabId, anchorSessionId, provider, title, selectCreated:false})` | Create a pool agent in a project. |
| `ac_dispatch_configure` (`grid`, `lane-select`) | Give each worker a fixed lane (manager, workers, watcher), so the owner can watch the fleet at a glance. Read `ac_layout_read` for the revision first. |
| `ac_agents_prompt` | Send a one-line prompt to an agent. The tool refuses when the agent's composer holds a draft (a human's, or a stranded earlier prompt). |
| `ac_agents_batch_read({items:[{read:{sessionId, depth:"status"}}]})` | Check the whole fleet's status in one call. `status` depth does no transcript I/O and never wakes an agent. |
| `ac_agents_reload` | Revive an agent whose process died (after a network drop, a crash or an app restart). The native conversation id is kept. |
| `ac_agents_close` | Close an agent. It is recorded in Undo Close. |
| `ac_usage_read` | Quota for every provider. Only root management can read it; agents without that domain get the `usage` domain's `usage_read`. |

## Usage (domain `usage`, off by default)

`usage_read` returns the same sanitized snapshot as the Usage window. Give it to orchestrating agents so they can check quota before starting more work. Never pass a force refresh: a fleet polling with force hits every provider's quota endpoint on every call.

## Other agents' transcripts (domain `agent_transcripts`, and `agent_management`)

`agent_management_send_prompt` / `read_agent` let a watcher that doesn't own the workers steer and read them. A steering watcher uses these; it never needs root management.

## Timers (Claude Code, not Agent Code)

The goal loop wakes an agent when it stops. For work that must happen **on a clock**, a Claude Code agent can schedule itself:
- `/loop` with an interval, or `CronCreate` with a cron expression and a prompt, re-fires the prompt on schedule. The 2026-09 manager used a 5-minute cron.
- `ScheduleWakeup` (dynamic `/loop` mode) picks its own next delay. Use at least 1,200 s as the fallback heartbeat.

A tick prompt must be self-contained and short: it is the whole instruction every 5 minutes. See [../templates/manager-tick-prompt.md](../templates/manager-tick-prompt.md).

## Workflows (domain `workflows`)

`ac_workflows_start` runs a named workflow script: a deterministic fan-out of sub-agents with an approval dialog. Use one for a one-shot parallel job (review N dimensions, verify each finding). Use a loop layout for work that needs judgment across hours.
