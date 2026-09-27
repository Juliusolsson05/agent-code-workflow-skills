# Layout 3: Loops + steering watcher

One or two long loops run unattended. A separate **watcher** agent, ideally on a different provider (a Codex watcher over Claude builders), reads what they do and steers them. The watcher never builds, fixes, merges or closes anything. Its output is notes and a log.

The idea: a loop cannot audit itself. It rationalizes its own shortcuts, and it doesn't notice slow drift. An independent reader with a brief of the rules catches both. In the 2026-09 loop the watcher wrote 130+ notes. Several of them became hard rules, including "Fixes only if the whole issue is fixed", "body must match the final head", "unknown is never empty" and "curated messages must be bounded".

## Setup
1. Write the brief ([../templates/steering-brief.md](../templates/steering-brief.md)). It covers:
   - who it oversees, by sessionId;
   - which rule files it enforces;
   - what to review on each pass;
   - how to act;
   - its rate limit.
2. Create the watcher and send it a one-line pointer to the brief. It sets its goal and calls `goal_loop_start` with the loop prompt from the brief.
3. Give it `agent_management` (to read and prompt the loops) and read access to the repo. It does not need root management.

## The note protocol
- **Watcher → loop:**
  - write `temp/steering-loop/note-q<n>.md`: what, where (file:line or PR), why, and a suggested change, ranked;
  - send the responsible agent one line pointing at it;
  - log it in `LOG.md`.
- **Rate limit:** one batched note per agent per hour. Send sooner only for real harm: a bad or ungated merge, a security leak, a destructive action, or two agents colliding.
- **Loop → watcher:** the loop answers with `reply-q<n>.md`, saying applied, declined with a reason, or forwarded to worker X. It answers every note. An unanswered note is how a rule gets forgotten.
- **Owner items:** anything that needs the owner goes in the "Owner" section of `LOG.md` and to the coordinator. The watcher never waits on them.

## What the watcher checks
- **Root cause:** is it a root-cause fix, or a second conditional stacked on the first?
- **Tests:** are they fail-first from recorded real data, with the fixture read in full? Would they catch a mutation?
- **Trailers:** `Fixes #N` only when the whole issue is fixed; otherwise `Refs`.
- **Scope:** is new behavior being smuggled into a fix?
- **Messages and ambiguity:** are user-visible messages bounded, and does ambiguity fail closed?
- **Merges:** were the gates run for real before the merge, and was the next merge re-gated on the new main?
- **Direction:** is the fleet spending hours on what matters to the owner? Flag rabbit holes and churn on the same file.
