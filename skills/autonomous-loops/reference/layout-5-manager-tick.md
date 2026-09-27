# Layout 5: Timed manager tick

A goal loop wakes an agent when it **stops**. A coordinator often has to act when **something else** happens instead: a worker writes READY, CI goes green, a steering note lands, an agent dies. A tick re-fires a fixed prompt on a clock, whatever the coordinator is doing.

Use it when the owner is away ("I'll be back in an hour, make sure I come back to plenty of work done") and the coordinator must keep the fleet moving.

## Setup (Claude Code coordinator)
- `CronCreate` with `*/5 * * * *` and the tick prompt, or `/loop 5m <prompt>`.
- Or dynamic `/loop` with `ScheduleWakeup`: pick the delay from what you are waiting on (one ~8-minute check for an 8-minute CI run), with at least 1,200 s as a heartbeat.
- **Don't run a goal loop in the coordinator at the same time.** Two wake sources double the work and the quota. In 2026-09 the manager's goal loop was stopped when workers started. Workers keep their own goal loops.

## Tick prompt shape
Use [../templates/manager-tick-prompt.md](../templates/manager-tick-prompt.md). It works because:
- it is **ordered**: steering first, then merges, then verifications, then idle workers, then revivals, then the ledger;
- every step is **idempotent**, so running it twice does no harm;
- it caps the reply at 3 lines, because the owner reads the scrollback later;
- it names the owner-proxy boundary: keep data, fail closed on security, never delete user data.

## Each tick's cost discipline
- Read status at `status` depth; no transcript reads unless a worker is stuck.
- If nothing changed, write one ledger line and stop. Don't invent work.
- Refresh `usage.md` about every hour, not every tick.

## Reviving
After a network drop or an app restart, agent processes can die while their panes look alive. On each tick:
- if `ac_agents_batch_read` shows a worker with no process, or one stuck for more than 20 minutes on a stranded prompt, `ac_agents_reload` it;
- then send the pointer to its newest assign file again;
- record the reload in `workers.md`.
