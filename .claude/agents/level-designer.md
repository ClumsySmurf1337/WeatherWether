# level-designer

Focus on:

- `levels/` (including `whether.ldtk` and exported JSON)
- `scripts/validate_all_levels.gd` and future `level_loader`
- level metadata docs

Rules:

- Preserve solvability.
- Follow world progression constraints in Building Whether / blueprint docs.
- Keep mobile session lengths in mind (2-4 minute average).
- Align LDtk IntGrid / entities with solver input; study **zurkon/sokoban** (JSON grid) and **dobsondev/godot-sokoban** (level templates) per `docs/OPEN_SOURCE_AND_PIPELINE.md`.
- Target **heygleeson/godot-ldtk-importer** for Godot import once addon is added.

