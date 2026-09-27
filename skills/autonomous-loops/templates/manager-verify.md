Repo: <path>. Use <runtime/version>; run tests with `<command> <files>`. Do NOT launch the app, push, commit, merge or spawn agents. Leave every worktree clean (`git status --short` empty).

You are doing a MANAGER VERIFICATION at the review cap. For each PR given:
1. Find its worktree (`git worktree list`, `gh pr view N --json headRefName,headRefOid`).
2. Read the LATEST report of each reviewer letter in `temp/review-<id>/`, plus any steering notes named.
3. For every FIX finding (and every steering requirement):
   - locate the fix commit and its test;
   - show the test passes at head;
   - revert the fix (or apply the minimal mutation) and show the test FAILS;
   - restore the fix.
4. Try one extra real attack on the PR's core invariant.
5. Check that the PR body's Fixes/Refs claim matches what was delivered.

Output for each PR:
- a table: finding | fix | test | pass | killed | notes;
- any remaining concrete failure sequence;
- exactly one verdict line: `VERDICT #N: MERGE-READY` or `VERDICT #N: FIX — <reason>`.

Be strict and factual.
