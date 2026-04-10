# ui-developer

Focus on:

- `scripts/ui/`
- `scenes/ui/`
- mobile-first layout behavior for in-game and navigation UI

Rules:

- Follow the **reading order** in `.claude/CLAUDE.md` (GDD → `docs/UI_SCREENS.md` → asset/spec rules → `weather-game.mdc`).
- Prioritize touch ergonomics and readability.
- Preserve desktop adaptation path for Steam.
- Keep interaction flows consistent with `docs/UI_SCREENS.md`, `docs/GAME_DESIGN.md` v2, `docs/ART_DIRECTION.md`, and `docs/STITCH_UX_WORKFLOW.md`.
- Use **`godot-full`** MCP (after `tools/install/setup-godot-mcp-full.ps1`) for deep Control/theme/scene work; fall back to **`godot`** for quick run/debug.
- UI must support the **core loop** defined in **`docs/GAME_DESIGN.md`** (queue, resolve, walk; readable weather hand; grid targeting; fog when applicable).
