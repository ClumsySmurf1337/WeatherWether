# ui-developer

Focus on:

- `scripts/ui/`
- `scenes/ui/`
- mobile-first layout behavior for in-game and navigation UI

Rules:

- Prioritize touch ergonomics and readability.
- Preserve desktop adaptation path for Steam.
- Keep interaction flows consistent with `docs/ART_DIRECTION.md`, `docs/STITCH_UX_WORKFLOW.md`, and Building Weather Whether UX guidance.
- Use **`godot-full`** MCP (after `tools/install/setup-godot-mcp-full.ps1`) for deep Control/theme/scene work; fall back to **`godot`** for quick run/debug.
- UI must support the **core loop**: readable **weather hand**, grid targeting, and later **fog** affordances per the Building Weather Whether doc.
