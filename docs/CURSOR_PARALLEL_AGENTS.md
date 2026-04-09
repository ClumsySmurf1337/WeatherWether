# Cursor parallel agents (up to 8)

## Goals

- Run **several agents in parallel** without stomping the same files.
- Keep **merge conflicts near zero** via strict directory scopes (see `.claude/CLAUDE.md`).

## Cursor Cloud agents (simplest mental model)

- **Dashboard:** [cursor.com/dashboard/cloud-agents](https://cursor.com/dashboard/cloud-agents) — see and manage cloud runs.
- **API:** [Cloud Agent API endpoints](https://cursor.com/docs/cloud-agent/api/endpoints) — automate spawning/status if you outgrow clicking in the UI.
- **Local:** Multiple **local** agent sessions or **git worktrees** in Cursor — same task boundaries, no cloud minutes.

Use **cloud** for long unattended runs; use **local** for Godot/editor-tight loops. You do not need the API until you are scripting agents from outside Cursor.

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
