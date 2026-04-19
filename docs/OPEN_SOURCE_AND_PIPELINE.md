# Open-source references and pipeline audit

Agents should **study** these repos (patterns only; licenses differ — do not copy-paste large blocks without checking license and attribution).

## Reference games (Godot 4, grid, levels)

| Repository | URL | What to steal conceptually |
|------------|-----|----------------------------|
| **zurkon/sokoban** | [github.com/zurkon/sokoban](https://github.com/zurkon/sokoban) | Data-driven **JSON levels**, **grid** state and movement — compare to `scripts/grid/grid_manager.gd` and future level JSON from LDtk. |
| **dobsondev/godot-sokoban** | [github.com/dobsondev/godot-sokoban](https://github.com/dobsondev/godot-sokoban) | **Inherited scenes / templates** so dozens of levels do not duplicate full scene files. |

Neither matches weather rules; both inform **structure** for 100+ puzzles.

## Level authoring (LDtk)

| Piece | URL / path | Role |
|-------|------------|------|
| **LDtk editor** | [ldtk.io](https://ldtk.io) | Visual design for `levels/whether.ldtk` and per-world layouts. |
| **godot-ldtk-importer** | [github.com/heygleeson/godot-ldtk-importer](https://github.com/heygleeson/godot-ldtk-importer) | Import `.ldtk` → Godot scenes / tile layers; auto-reload on save. |

## Gap audit (repo state vs target pipeline)

| Target | Status | Next action |
|--------|--------|-------------|
| Strict GDScript + `class_name` core | **Partial** — grid, weather, puzzle stubs exist | Extend toward full weather matrix; keep GUT coverage. |
| JSON / LDtk-driven level loading | **Partial** — `levels/whether.ldtk` present; worlds mostly `.gitkeep` | Flesh levels in LDtk; add **`scripts/level_loader.gd`** (or agreed name) to parse LDtk/export JSON into `GridManager` state. |
| godot-ldtk-importer addon | **Missing** | Add addon under `addons/` per importer docs; document in README. |
| Puzzle solver validation | **Stub** — `scripts/puzzle/puzzle_solver.gd`, `validate_all_levels.gd` placeholder | Wire solver to real level format; fail CI on unsolvable campaign levels. |
| UI/UX scene iteration with agents | **Improved** — `godot-full` MCP after `setup-godot-mcp-full.ps1` | Use for Control trees, themes, runtime checks; still follow `docs/ART_DIRECTION.md` / `docs/STITCH_UX_WORKFLOW.md`. |
| Export presets + artifact CI | **Missing** — no `export_presets.cfg`; `build.yml` scaffold | Editor export once → commit preset; extend GitHub Actions (see `BLUEPRINT_GAP_AUDIT.md`). |

## Autonomous build alignment

- **CI** runs on **GitHub-hosted runners** (Ubuntu) — you do **not** need Docker on your PC for CI.
- **Local** Windows path policy and `validate.ps1` stay the truth for day-to-day; keep **Godot 4.6.x** aligned with `project.godot` and CI `GODOT_VERSION`.

## Art generation (canonical)

Hybrid pipeline (**pixel in-level + painterly key art**) is summarized in **`docs/ART_PIPELINE.md`**. **Platforms:** same assets for **desktop (Steam)** and **mobile**; framing via **`docs/DISPLAY_PROFILE.md`**. **Weather:** manifest **sprite VFX** first; optional **`GPUParticles2D`** layers per **`docs/GAME_DESIGN.md` §17**. Prompts and CLI copy-paste live in **`docs/ASSET_PROMPTS_GEMINI.md`** and **`tools/art/GENERATION_QUEUE.md`**. Do not follow ad-hoc “hybrid illustrated tile” briefs that contradict **`docs/ART_DIRECTION.md`** (e.g. 64×64 painted board tiles).

## When this file changes

Update **`docs/BLUEPRINT_GAP_AUDIT.md`** if gaps close, and mention any new addon paths in **`README.md`** and **`docs/AGENT_CATALOG.md`**.
