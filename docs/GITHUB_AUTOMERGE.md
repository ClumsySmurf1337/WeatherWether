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
2. **`gh pr checkout`** — your tree matches the PR.
3. **`tools/tasks/validate.ps1`** — local Godot validation.
4. **`gh pr merge --squash --delete-branch`** — merge from your machine (needs `gh` auth + branch rules).
5. **`npm run linear:complete-from-pr`** — reads PR title/body for **`WEA-###`**, moves issue(s) to **Done** via **local** Linear API key.

Flags: **`-SkipChecksWatch`**, **`-SkipLocalValidate`**, **`-SyncMainBeforeValidate`** (merge **`origin/main`** into the PR first; opens **`cursor-agent`** / **`cursor agent`** on conflict — see **`npm run qa:repair-merge`**), **`-NoMerge`** (skips merge and Linear Done).

**Batch lane PRs:** **`npm run qa:lane-prs`** runs the same handoff for every open PR whose head matches **`agent/cursor-lane-*`** (see **`tools/tasks/qa-lane-pr-batch.ps1`**). Use **`npm run lane:ship`** when agents left uncommitted work; **`npm run lane:next-cycle`** after merges to recreate lane branches from **main**.

## Optional: GitHub-side automation later

If you later want Actions to merge on a label, add a **separate** workflow and secrets; keep branch protection strict. The default documented path here remains **local QA**.

## Agent PR checklist

- Include **`LINEAR_TEAM_KEY-###`** in PR title or body.
- Run **`validate.ps1`** before opening the PR when you touch gameplay, tests, or levels.
