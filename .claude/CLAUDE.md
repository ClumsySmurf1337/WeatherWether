# Weather Whether Agent Instructions

## Reading order for new agents

Read these in order before touching code or Linear. They are the source of truth for v2 (sequence model + walking character).

1. `docs/GAME_DESIGN.md` — game design spine (READ FIRST)
2. `docs/UI_SCREENS.md` — every screen with mockups
3. `docs/ASSET_MANIFEST.md` — sprite/audio contract
4. `docs/SPEC_DIFF.md` — what changed and the rewrite plan
5. `.cursor/rules/weather-game.mdc` — runtime architecture rules

If anything in those five files contradicts an older doc (including `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md` or the old `ART_DIRECTION.md`), the v2 spec wins. Flag the contradiction in your PR description so the producer agent can clean up the older doc.

## Project

- Godot 4.6 + strict typed GDScript.
- Mobile-first UX and controls.
- Windows/Steam shipping lane is current priority.
- **Design spine:** Sequence model + walking character (Sky). See `docs/GAME_DESIGN.md` v2. The old "Building Whether..." doc is superseded for game design but still valid for toolkit/pipeline info.

## Path Policy

- Godot path: `D:\Godot`.
- Caches/build/temp/logs must stay on D drive.

## Runtime Parity

- Keep behavior aligned with `.cursor/rules/*.mdc`.
- Use repo task scripts in `tools/tasks/` as entry points.
- Do not bypass validation (`tools/tasks/validate.ps1`) before handoff.
- Use Linear orchestration scripts for PM loops (`linear:producer`, `linear:dispatch`, `linear:resume-pickup`).
- Prefer **`godot-full`** ([tugcantopaloglu/godot-mcp](https://github.com/tugcantopaloglu/godot-mcp)) after `tools/install/setup-godot-mcp-full.ps1`; optional **`godot`** (Coding-Solo, `npx -y`). API docs: **https://docs.godotengine.org/en/4.6/** (`docs/GODOT_DOCS_ACCESS.md`).
- **Parallel agents:** Cursor Cloud is **not** self-hosted. Use **local** git worktrees: `pwsh ./tools/tasks/new-agent-worktree.ps1 -BranchName agent/lane` + `docs/CURSOR_PARALLEL_AGENTS.md`.

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