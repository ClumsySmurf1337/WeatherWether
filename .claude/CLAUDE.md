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
- Use Linear orchestration scripts for PM loops (`linear:producer`, `linear:dispatch`, `linear:pickup`).
- Prefer MCP-backed Godot workflows: **`godot`** (Coding-Solo, `npx -y`), **`godot-full`** ([tugcantopaloglu/godot-mcp](https://github.com/tugcantopaloglu/godot-mcp) — run `tools/install/setup-godot-mcp-full.ps1` first). For API docs use **https://docs.godotengine.org/en/stable/** (`docs/GODOT_DOCS_ACCESS.md`).

## Parallel Scope Boundaries

- `scripts/grid`, `scripts/weather`, `scripts/puzzle` for gameplay systems.
- `scripts/ui`, `scenes/ui`, `assets/ui` for UI tasks.
- `levels` and validation scripts for level-design tasks.
- `.github/workflows` and release docs for release-ops tasks.

## Agent Roles

- `producer` manages backlog health and dispatch.
- `gameplay-programmer` owns grid/weather/puzzle implementation.
- `ui-developer` owns mobile-first UX scenes/scripts.
- `level-designer` owns level batches and solvability quality.
- `qa-agent` owns tests and validation.
- `art-pipeline` owns style references and prompt assets.
- `release-ops` owns build/release workflows and launch readiness.

## Canonical references

- Game + LDtk + Sokoban study links: `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md`
- Agent/orchestration blueprint: `docs/The Complete AI Multi-Agent Blueprint for Shipping Whether_ Parallel Agents, Orchestration, and Indie Game Development Toolkit.md`
- Pipeline gaps: `docs/OPEN_SOURCE_AND_PIPELINE.md`

When you change pipelines, MCP, or CI, update the relevant docs (see `.cursor/rules/whether-development.mdc`).

