# qa-agent

Focus on:

- `test/`
- validation scripts
- CI workflow checks

## PR handoff (merge + Linear) — local only

- PR **title or body** must include the Linear id (`LINEAR_TEAM_KEY-###`, e.g. `WEA-42`).
- Run from repo root: **`npm run qa:pr -- -PullRequestNumber <N>`** (see `tools/tasks/qa-pr-handoff-local.ps1`). Order: **`validate.ps1`** in the PR checkout first (fail fast — includes **GUT** when `addons/gut` is present), then **`gh pr checks --watch`** for **Weather Whether CI** (with automatic re-watch rounds after failures so you can push fixes), then merge via **`gh`**, then **`linear:complete-from-pr`** using **local** `.env.local` — no GitHub Action closes the issue.
- **Before a PR exists** (`tools/tasks/lane-ship.ps1`, including **`qa:agent`** pre-flight ship): **`validate.ps1`** on the lane worktree (GUT + levels), then **`npm run linear:verify-issue-for-ship`** so the **WEA-###** issue exists on the team and is **not** Done/Canceled. **`-SkipLinearVerify`** / **`-SkipValidate`** on **`lane-ship`** / **`lane:ship:lanes`** skips those gates (emergency only).
- **End-to-end from one terminal:** **`npm run workflow:simple`** (= **`daily:full:apply:lanes`** + lanes **1–3** in parallel subprocesses + **`qa:agent`**); **`npm run workflow:simple -- -SkipQa`** stops before QA. Cursor: **Tasks → Weather Whether — Simple flow (npm: daily+lanes+QA)**.
- **Several lane PRs at once** (heads `agent/cursor-lane-1` …): from repo root **`npm run qa:agent`** (alias: **`npm run qa:lane-prs`**) — in Cursor you can use **Tasks → Weather Whether — QA agent (lane PRs)**. `tools/tasks/qa-lane-pr-batch.ps1` first **ships** lanes **1–3** when a worktree still has uncommitted or unpushed work (same rules as **`lane-ship`**: validate + Linear verify, then PR), then processes each open lane PR with **`SyncMainBeforeValidate`** (conflicts → **`qa:repair-merge`** flow), **`validate.ps1`**, **`gh pr checks --watch`**, merge, moves Linear to **Done**, appends **`docs/CHANGELOG_LANES.md`** and **commits + pushes** that file on **main** when new lines were added (**`-SkipChangelogPush`** to skip push), then **`npm run worktrees:sync`** and **resets lane branches** from **main** (**`-SkipPreflightShip`** skips the ship pass; **`-SkipResetLaneBranches`** skips reset). **`npm run qa:lane-prs:quick`** passes **`-SkipChecksWatch`** if CI is already green.
- **Terminal output:** when the batch **finishes successfully**, the script prints **`--- QA run summary ---`** (wall time, preflight ship count, merged PR lines, changelog/worktrees/lane reset, optional Linear reconcile). If there are **no open lane PRs**, it still prints a **short summary** and exits **0**. Failures **throw** before the summary (fix branch, re-run).
- **Merge conflicts:** from repo root or any worktree path, run **`npm run qa:repair-merge -- -RepoPath "<path-to-checkout>"`** (or `cd` there and omit `-RepoPath`). The script merges **`origin/main`**; on conflict it opens **`cursor-agent`** (fallback **`cursor agent`**) with `tools/tasks/prompts/qa-merge-conflict-repair.md`. After you resolve, commit, and push, re-run **`qa:pr`** (use **`-SkipChecksWatch`** if CI is already green). To merge **`main` into the PR before validate:** **`npm run qa:pr -- -PullRequestNumber <N> -SyncMainBeforeValidate`**.
- **Linear not moved to Done after a merged lane PR:** **`npm run linear:complete-merged-lane-prs`** (backfill from merged **`agent/cursor-lane-*`** PRs), or **`npm run qa:agent -- -ReconcileLinearFromMergedLanePrs`** at the end of a full QA batch.

Rules:

- **`npm run qa:agent` / `qa:pr` do not auto-fix code.** If **`validate.ps1`** fails (GUT or level validation), fix the branch in the lane worktree or PR checkout, commit, push, then re-run. **`validate.ps1` propagates Godot exit codes** — a failing test run stops QA before merge/CI watch.
- **`ERROR:` / `push_error` lines in GUT output** are often **expected** (tests that assert `push_error`); use the **Run Summary** (`Passing Tests` vs `Failing Tests`) and **`---- All tests passed! ----`**, not raw stderr alone.
- Lane PRs should already be **validate-clean** before merge (see **Quality before handoff** in `.claude/CLAUDE.md` and `tools/tasks/prompts/lane-agent-prompt.md`); treat unexpected parse/test failures as process drift, not normal.
- Follow the **reading order** in `.claude/CLAUDE.md` when validating spec drift or regression scope.
- Gameplay / level / UI behavior must match **`docs/GAME_DESIGN.md` v2** (sequence model, terrains, win/lose, UI flow). Flag PRs that reintroduce instant-resolve or contradict the GDD.
- Expand regression coverage before broad refactors.
- Ensure `validate.ps1` and **GitHub Actions** (`ci.yml`) stay aligned — CI uses Ubuntu Godot headless, **no Docker** required.
- Track pipeline truth in `docs/OPEN_SOURCE_AND_PIPELINE.md` when validation or level format changes.
- Report failures with reproduction steps.

