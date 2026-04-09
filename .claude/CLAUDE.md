# Whether Agent Instructions

## Project

- Godot 4.6 + strict typed GDScript.
- Mobile-first UX and controls.
- Windows/Steam shipping lane is current priority.

## Path Policy

- Godot path: `D:\Godot`.
- Caches/build/temp/logs must stay on D drive.

## Runtime Parity

- Keep behavior aligned with `.cursor/rules/*.mdc`.
- Use repo task scripts in `tools/tasks/` as entry points.
- Do not bypass validation (`tools/tasks/validate.ps1`) before handoff.

## Parallel Scope Boundaries

- `scripts/grid`, `scripts/weather`, `scripts/puzzle` for gameplay systems.
- `scripts/ui`, `scenes/ui`, `assets/ui` for UI tasks.
- `levels` and validation scripts for level-design tasks.

