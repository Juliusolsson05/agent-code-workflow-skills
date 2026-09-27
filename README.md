# agent-code-workflow-skills

Skills for running **autonomous agent loops in [Agent Code](https://github.com/Juliusolsson05/agent-code)**, the desktop app that runs Claude Code, Codex, OpenCode, Grok and Pi agents side by side. They cover how to lay out a fleet of agents, start it, keep it running while you are away, and stop it from merging bad work.

| Skill | Use it for |
|---|---|
| [`autonomous-loops`](skills/autonomous-loops/SKILL.md) | Picking a loop layout (solo goal loop, builder + reviewers, loops + steering watcher, manager + workers, timed manager tick) and setting up its ledger, briefs, gates and tools |

## The layouts

```
one outcome, hours of work ──────────────► 1 solo goal loop
   └─ lands as PRs ──────────────────────► + 2 reviewers per PR
        └─ runs overnight, unattended ───► + 3 steering watcher
many independent items ──────────────────► 4 manager + workers (each worker = 1 + 2)
   └─ owner away, must act on a clock ───► + 5 manager tick
```

The worked example is the [2026-09 quality loop](skills/autonomous-loops/reference/case-study-quality-loop.md): a manager, four Claude workers each with three Codex/GLM reviewers per PR, a Codex steering watcher, and a 5-minute manager tick. In three days it merged 181 PRs across six repos. Every rule in this skill comes from [a failure it hit](skills/autonomous-loops/reference/failure-modes.md).

## Install

With Agent Code: Settings → Skills → install from GitHub → `Juliusolsson05/agent-code-workflow-skills`, then choose the providers.

Anywhere else:

```bash
npx skills add Juliusolsson05/agent-code-workflow-skills
```

## Related

[`agent-skills`](https://github.com/Juliusolsson05/agent-skills): the process skills the workers follow (writing-plans, debugging, staged-decomposition, pr-review).
