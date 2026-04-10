# GitHub CI + local QA merge (default for Weather Whether)

This repo **does not** auto-merge PRs or move Linear issues to Done from GitHub Actions. **Weather Whether CI** only validates (Godot headless on Ubuntu, GUT, levels). Merge and Linear completion are **local** so your **QA agent / you** stay in control and use **`.env.local`** (no `LINEAR_API_KEY` in GitHub required for that path).

## What runs on GitHub

- **`.github/workflows/ci.yml`** — `npm ci`, install Godot to `/usr/local/bin/godot`, import, GUT, level validation on **pull requests and `main`**.

## Local QA handoff (merge + Linear Done)

After the PR’s checks are green:

```powershell
npm run qa:pr -- -PullRequestNumber 42
```

This script (`tools/tasks/qa-pr-handoff-local.ps1`):

1. **`gh pr checks --watch`** — waits for remote CI.
2. **Checkout PR branch** — **`gh pr checkout`** in the main repo, **unless** the PR head is **`agent/cursor-lane-N`**: then the script uses your linked worktree **`wt-agent-cursor-lane-N`** under **`WHETHER_AGENT_ROOT`** (default `D:\Agents\WeatherWether`), because Git cannot check out the same branch in two worktrees.
3. **`tools/tasks/validate.ps1 -GodotProjectPath`** (current PR checkout) — local Godot import, **GUT** (`res://test`), and level validation for that tree (main repo or lane worktree).
4. **Lane heads only (before merge):** put **`wt-agent-cursor-lane-N`** in **detached HEAD** at **`origin/main`** (or **`origin/master`**). **`gh pr merge --delete-branch`** removes the local **`agent/cursor-lane-N`** branch; Git will error if that branch is still checked out in the lane worktree. **`git checkout main`** in the lane worktree is **not** used because **`main`** is already checked out in the primary repo worktree — two worktrees cannot share the same branch name.
5. **`gh pr merge --squash --delete-branch`** — merge from your machine (needs `gh` auth + branch rules). Then **`tools/tasks/git-sync-main.ps1`** runs from the **main** repo: **`git fetch origin`** (so **every** worktree sees the new **`origin/main`**) and fast-forwards local **`main`**. That makes the next PR’s **merge `main` into branch** step use an up-to-date base.
6. **`npm run linear:complete-from-pr`** — reads PR title/body for **`WEA-###`**, moves issue(s) to **Done** via **local** Linear API key.

Flags: **`-SkipChecksWatch`**, **`-SkipLocalValidate`**, **`-SyncMainBeforeValidate`** (merge **`origin/main`** into the PR first; opens **`cursor-agent`** / **`cursor agent`** on conflict — see **`npm run qa:repair-merge`**), **`-NoMerge`** (skips merge and Linear Done), **`-AgentRoot`** (where **`wt-agent-cursor-lane-*`** live; batch passes this automatically).

**Missed Linear Done** (merge succeeded but **`linear:complete-from-pr`** never ran): run **`npm run linear:complete-merged-lane-prs`** — scans recent **merged** PRs whose head is **`agent/cursor-lane-*`**, then runs **`linear:complete-from-pr`** for each (same **`WEA-###`** rules). Optional: **`npm run qa:agent -- -ReconcileLinearFromMergedLanePrs`** (add **`-ReconcileLinearMergedWithinDays 60`** if needed).

**Same `WEA-###` on a new open PR after an earlier merge:** that is usually **new commits on the same lane branch** (e.g. PR #1 merged, then more work + **`lane-ship`** opened PR #4). The title still says **`WEA-520: lane work`** because **`.weather-lane-issue.txt`** still holds **520**. It is **not** re-merging the old PR; it is a **new PR** with additional diff vs **`main`**. After you truly finish the issue, clear or update the marker (next **`resume-pickup`** / new issue) and prefer a **new Linear issue** for follow-up work so titles stay honest.

**CI “no checks reported” on a brand-new PR:** **`qa-pr-handoff-local.ps1`** polls **`gh pr view --json statusCheckRollup`** until checks exist (default up to **15 minutes**, **15 s** interval), then runs **`gh pr checks --watch`**. Tune with **`npm run qa:pr -- -PullRequestNumber N -ChecksPollMaxSeconds 1200`** or from the batch: **`npm run qa:agent -- -ChecksPollMaxSeconds 1200`**.

**Batch lane PRs:** **`npm run qa:agent`** (alias **`npm run qa:lane-prs`**) runs the same handoff for every open PR whose head matches **`agent/cursor-lane-*`** (see **`tools/tasks/qa-lane-pr-batch.ps1`**), including a pre-flight ship pass for stale lane worktrees (**`lane-ship`**: **`validate.ps1`** + **`linear:verify-issue-for-ship`** before **`gh pr create`**). Use **`npm run lane:ship`** / **`lane:ship:lanes`** when needed; **`npm run lane:next-cycle`** after merges to recreate lane branches from **main**.

## Optional: GitHub-side automation later

If you later want Actions to merge on a label, add a **separate** workflow and secrets; keep branch protection strict. The default documented path here remains **local QA**.

## Agent PR checklist

- Include **`LINEAR_TEAM_KEY-###`** in PR title or body.
- Run **`validate.ps1`** before opening the PR when you touch gameplay, tests, or levels.
