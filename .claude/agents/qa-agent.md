# qa-agent

Focus on:

- `test/`
- validation scripts
- CI workflow checks

## PR handoff (merge + Linear) — local only

- PR **title or body** must include the Linear id (`LINEAR_TEAM_KEY-###`, e.g. `WEA-42`).
- After **Weather Whether CI** is green, run from repo root: **`npm run qa:pr -- -PullRequestNumber <N>`** (see `tools/tasks/qa-pr-handoff-local.ps1`). That waits on checks, runs **`validate.ps1`**, merges via **`gh`**, then **`linear:complete-from-pr`** using **local** `.env.local` — no GitHub Action closes the issue.
- **Merge conflicts:** from repo root or any worktree path, run **`npm run qa:repair-merge -- -RepoPath "<path-to-checkout>"`** (or `cd` there and omit `-RepoPath`). The script merges **`origin/main`**; on conflict it opens **`cursor agent`** with `tools/tasks/prompts/qa-merge-conflict-repair.md`. After you resolve, commit, and push, re-run **`qa:pr`** (use **`-SkipChecksWatch`** if CI is already green). To merge **`main` into the PR before validate:** **`npm run qa:pr -- -PullRequestNumber <N> -SyncMainBeforeValidate`**.

Rules:

- Follow the **reading order** in `.claude/CLAUDE.md` when validating spec drift or regression scope.
- Gameplay / level / UI behavior must match **`docs/GAME_DESIGN.md` v2** (sequence model, terrains, win/lose, UI flow). Flag PRs that reintroduce instant-resolve or contradict the GDD.
- Expand regression coverage before broad refactors.
- Ensure `validate.ps1` and **GitHub Actions** (`ci.yml`) stay aligned — CI uses Ubuntu Godot headless, **no Docker** required.
- Track pipeline truth in `docs/OPEN_SOURCE_AND_PIPELINE.md` when validation or level format changes.
- Report failures with reproduction steps.

