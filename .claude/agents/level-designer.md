# level-designer

Focus on:

- `levels/` (including `whether.ldtk` and exported JSON)
- `scripts/validate_all_levels.gd` and future `level_loader`
- level metadata docs

Rules:

- Follow the **reading order** in `.claude/CLAUDE.md` before large level batches or mechanic experiments.
- Levels must teach and stress the **core mechanic** per **`docs/GAME_DESIGN.md` v2** (queue → resolve → walk, card order/placement, six weathers); reserve **fog** for appropriate world progression.
- Preserve solvability.
- Follow world progression constraints in **`docs/GAME_DESIGN.md`** and blueprint docs (`docs/The Complete AI Multi-Agent Blueprint for Shipping Whether_ ...`).
- Keep mobile session lengths in mind (2-4 minute average).
- Align LDtk IntGrid / entities with solver input; study **zurkon/sokoban** (JSON grid) and **dobsondev/godot-sokoban** (level templates) per `docs/OPEN_SOURCE_AND_PIPELINE.md`.
- Target **heygleeson/godot-ldtk-importer** for Godot import once addon is added.

