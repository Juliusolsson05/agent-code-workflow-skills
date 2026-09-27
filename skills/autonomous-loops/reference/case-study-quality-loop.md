# Case study: the 2026-09 quality loop (layouts 2 + 3 + 4 + 5)

The owner's brief (2026-09-25): the app is good, but it doesn't yet feel fully thought through for serious users, with a perfect UI and no bugs. Set up a loop that works on a long horizon, digs deep for bugs, resolves every finding, and merges autonomously after review. The open-issue list is "a fat mess" and needs a real audit.

## How it evolved
1. **Day 1: two solo loops plus a watcher (layouts 1, 2, 3).**
   - A *quality loop* agent ran on a goal loop. It audited every open issue: 84 of 90 had no label, and 62 had no comment. From recurring history it named nine bug classes, among them prompt delivery inferred from the terminal screen, identity across reload and replace, silent failure, global input traps, one bad record taking everything down, unbounded growth, new-feature bug clusters, rendering order, and test hygiene. It then fixed them class by class, one small PR each.
   - A second *keyboard-first loop* built one long draft PR, which the owner merged personally.
   - A Codex **steering watcher** oversaw both.
   - Reviews: 2 Codex + 1 Pi per PR, at most 2 rounds.
2. **Day 2: manager + 4 Claude workers (layout 4).**
   - The single quality loop was the bottleneck: it sat idle through each 10-minute review.
   - The owner approved: the loop agent becomes the manager, with 4 Claude workers, each in its own lane.
   - Workers started their own 3 reviewers. Pi's bridge was flaky, so reviewers became Codex plus a rotating OpenCode (GLM) slot.
   - The watcher was re-briefed (BRIEF-v2) to oversee the fleet.
3. **Day 2–3: the manager goes on a 5-minute tick (layout 5)**, so the fleet kept moving while the owner was away.
4. **Day 3: PR freeze.** The workers produced PRs faster than the manager could gate them, and 35 were open, some 13 hours old. The owner froze new work. The manager drained the PRs through integration batches (A–U) until 2 were left, both waiting on purpose.

## Numbers (2026-09-25 → 09-27)
- 181 PRs merged across six repos. 160 were in the app, including the batch PRs; the rest were in five provider packages.
- 135 issues closed. 138 issues opened, most of them found by the loop's own hunts. That is why the open count barely moved even though the fixes were real. The owner asked about exactly this.
- One stable release was cut from the result (0.1.4), with user-facing notes written from every merged PR.

## What made it work
- **One ledger, pushed every pass.** It survived many compactions, and the manager re-read it after each one.
- **Rules accumulate in worker-common.md** with the incident that produced each rule. A fresh or revived worker gets the fleet's full history in one read. By the end it held about 40 rules.
- **Gates became scripts.** After two manual gate misses (a merge with an unconfirmed default, and a merge 6 commits behind main), merges were only allowed through `merge-gate.sh`.
- **Independent steering.** The watcher's notes (q1–q132) turned into rules and gates. Examples: Fixes vs Refs; the body must match the final head; the disposition goes up before merge; fixtures are read in full; curated messages are bounded; ambiguity fails closed; unknown is never empty.
- **Owner decisions batched.** Product calls were collected into one list and asked once, in yes/no form.

## What went wrong (each is now a rule in failure-modes.md)
- **The machine:** a flood of reviewers, parallel type checks and leftover worktrees caused CPU overload and two disk-full events.
- **Stranded prompts** after timeouts, and **dead processes** after a Wi-Fi drop.
- **Batches built on a stale main.** One batch was merged without its gate or disposition.
- **Merge commits named "Merge #N into batch"** hid the PR titles. The owner objected, and batches moved to GitHub member merges.
- **`sed` into `gh pr edit --body`** wiped a PR body. Sidebar links closed the wrong issue.
- **The manager nearly approved deleting user data** because a note said it was safe. That was caught and reversed, and the owner decides.
