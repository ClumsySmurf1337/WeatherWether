# Cursor parallel agents (up to 8)

## Goals

- Run **several agents in parallel** without stomping the same files.
- Keep **merge conflicts near zero** via strict directory scopes (see `.claude/CLAUDE.md`).

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

Use **Mission Control / multi-agent UI** in Cursor per product version; when in doubt, run **one Cloud** + **two local** worktrees rather than maxing Cloud cost.

## Practical limit

Above **3–4 parallel implementation agents**, integration tax rises. Keep a **Producer** pass (`linear:producer`) to serialize merges.

## Reference

- [Cursor Cloud Agents](https://cursor.com/docs/cloud-agent#cloud-agents)
