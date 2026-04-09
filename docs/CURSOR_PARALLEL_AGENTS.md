# Cursor parallel agents (up to 8)

## Goals

- Run **several agents in parallel** without stomping the same files.
- Keep **merge conflicts near zero** via strict directory scopes (see `.claude/CLAUDE.md`).

## Cursor Cloud vs local (Whether default)

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
   One **In Progress** issue per lane; run `linear:pickup -- --role=... --apply`.

## Cursor Cloud vs local

- **Cloud:** best for long tasks where your laptop can sleep.
- **Local:** best for Godot iteration, GPU, and **no extra cloud minutes**.

Use Cursor’s **Cloud Agents** UI (dashboard above) or **multiple local** chats/worktrees; when in doubt, run **one Cloud** + **two local** worktrees rather than maxing Cloud cost.

## Practical limit

Above **3–4 parallel implementation agents**, integration tax rises. Keep a **Producer** pass (`linear:producer`) to serialize merges.

## Reference

- [Cursor Cloud Agents](https://cursor.com/docs/cloud-agent#cloud-agents)
