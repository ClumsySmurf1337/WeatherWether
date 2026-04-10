# Cursor parallel agents (up to 8)

## Goals

- Run **several agents in parallel** without stomping the same files.
- Keep **merge conflicts near zero** via strict directory scopes (see `.claude/CLAUDE.md`).

## Cursor Cloud vs local (Weather Whether default)

- **There is no self-hosted Cursor Cloud.** Cloud agents run on **Cursor-managed** infrastructure only ([dashboard](https://cursor.com/dashboard/cloud-agents), [API](https://cursor.com/docs/cloud-agent/api/endpoints)).
- **Default for this repo:** **local parallel agents** — several Cursor windows, each on a **separate git worktree**, with non-overlapping directory scopes. **Scripted worktree:**  
  `pwsh ./tools/tasks/new-agent-worktree.ps1 -BranchName agent/your-lane`  
  Worktrees live under `D:\Agents\WeatherWether\wt-*` (or `WHETHER_AGENT_ROOT`). See `docs/PATHS_AND_STORAGE_POLICY.md`.
- **Cloud agents:** optional for long unattended tasks; use **local** for Godot/editor-tight loops and to avoid extra cloud minutes.

## Workspace setup

1. **Branch per lane**  
   Example: `agent/grid-weather`, `agent/ui-hud`, `agent/levels-batch3`.

2. **Scope matrix**

   | Lane | Touch only |
   |------|------------|
   | Gameplay | `scripts/grid`, `scripts/weather`, `scripts/puzzle`, `test/` |
   | UI | `scripts/ui`, `scenes/ui`, `assets/` UI |
   | Levels | `levels/`, level loader, validation |
   | QA | `test/`, `scripts/validate_all_levels.gd`, CI |

3. **Linear**  
   One **In Progress** issue per lane; run `linear:resume-pickup -- --role=... --apply` (resume first, then pickup).

## Cursor Cloud vs local

- **Cloud:** best for long tasks where your laptop can sleep.
- **Local:** best for Godot iteration, GPU, and **no extra cloud minutes**.

Use Cursor’s **Cloud Agents** UI (dashboard above) or **multiple local** chats/worktrees; when in doubt, run **one Cloud** + **two local** worktrees rather than maxing Cloud cost.

## Integrated lane terminals (one Cursor window)

Prefer **no floating PowerShell popups**: run **`npm run cursor:resume:editor`** or **`npm run cursor:go:editor`**, then in this repo use **Tasks → Weather Whether — All lane terminals (parallel)** (see `.vscode/tasks.json`). Each task runs **`run-lane-terminal.ps1`** (`linear:resume-pickup` from the main repo, then **`cursor-agent`** in the worktree). **`npm run cursor:open-lanes`** is optional and only adds **extra Cursor windows** on the same worktrees — it does not break resume.

## Practical limit

Above **3–4 parallel implementation agents**, integration tax rises. Keep a **Producer** pass (`linear:producer`) to serialize merges.

`LINEAR_MAX_IN_PROGRESS` (default **3**) and `LINEAR_DISPATCH_ROLES` limit how many **Todo** issues `linear:dispatch` moves to **In Progress** per cycle; **producer** and **qa-agent** work is usually claimed with `linear:resume-pickup` instead.

## PR → CI → local QA → merge → Linear Done

1. Implementer opens a PR with **`WEA-###`** (or your `LINEAR_TEAM_KEY`) in the **title or body**.
2. **Weather Whether CI** must pass on GitHub.
3. **QA / you** run **`npm run qa:pr -- -PullRequestNumber <N>`** locally (`gh` + `validate.ps1` + merge + `linear:complete-from-pr`). See **`docs/GITHUB_AUTOMERGE.md`**.

**Cursor CLI:** install the **`cursor`** CLI and ensure **`cursor-agent`** is on `PATH` ([Cursor CLI docs](https://cursor.com/docs/cli/installation)), then **`npm run cursor:session:apply -- -CreateWorktrees -SpawnAgentCli`** to open one terminal per lane running **`cursor-agent`** (via **`run-cursor-chat.ps1`**; falls back to **`cursor agent`**) — no copy-paste into the IDE chat. Details: **`docs/CURSOR_CLI_AND_WORKTREES.md`** and [DEV: worktrees + parallel agents](https://dev.to/arifszn/git-worktrees-the-power-behind-cursors-parallel-agents-19j1).

**Not automated:** conflict resolution — fix in the branch/worktree before **`qa:pr`** can merge.

## Reference

- [Cursor Cloud Agents](https://cursor.com/docs/cloud-agent#cloud-agents)
