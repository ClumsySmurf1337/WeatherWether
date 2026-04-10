# Agent Sync Checklist

- [ ] `.cursor/rules` reflects current architecture and path policy (including `whether-development.mdc` canonical doc links).
- [ ] `.claude/CLAUDE.md` matches runtime and scope boundaries; **reading order** (GDD → UI_SCREENS → ASSET_MANIFEST → SPEC_DIFF → `weather-game.mdc`) stays in sync with `docs/AGENT_CATALOG.md`, `.cursor/rules/whether-development.mdc`, and `tools/tasks/prompts/lane-agent-prompt.md`.
- [ ] Task entry points still live in `tools/tasks/*.ps1` (including `prepare-editor-lane-worktrees.ps1` for `cursor:go:editor` / `cursor:resume:editor`).
- [ ] Cloud and local mode switch scripts are operational.
- [ ] Docs mention Windows/Steam-first and mobile-first UX constraints.
- [ ] Deferred iOS lane remains documented but not required for daily work.
- [ ] `godot-full` MCP: `tools/install/setup-godot-mcp-full.ps1` run so `tools/godot-mcp-full/build/index.js` exists (folder is gitignored); **`godot-full` is the primary Godot MCP** for this repo.
- [ ] Parallel local agents: document `tools/tasks/new-agent-worktree.ps1` when changing branch/worktree workflow.
- [ ] After pipeline/LDtk/CI/MCP changes: `README.md`, `docs/OPEN_SOURCE_AND_PIPELINE.md`, and `docs/BLUEPRINT_GAP_AUDIT.md` updated as needed.

