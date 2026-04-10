# Agent Sync Checklist

- [ ] `.cursor/rules` reflects current architecture and path policy (including `whether-development.mdc` canonical doc links).
- [ ] `.claude/CLAUDE.md` matches runtime and scope boundaries; **reading order** (GDD → UI_SCREENS → ASSET_MANIFEST → SPEC_DIFF → `weather-game.mdc`) stays in sync with `docs/AGENT_CATALOG.md`, `.cursor/rules/whether-development.mdc`, and `tools/tasks/prompts/lane-agent-prompt.md`.
- [ ] Task entry points still live in `tools/tasks/*.ps1` (including `prepare-editor-lane-worktrees.ps1`, `lane-ship.ps1` + `lane-ship-lib.ps1` (`NeedsShip` = dirty or ahead of `origin/main`; `linear:verify-issue-for-ship` before PR), `lane-ship-all.ps1` / `npm run lane:ship:lanes`, `simple-flow.ps1` / `npm run workflow:simple`, `simple-flow-copilot.ps1` / `npm run workflow:simple:copilot`, `lane-prompt-lib.ps1` (shared lane prompt text), `run-lane-terminal.ps1` + `run-lane-copilot-terminal.ps1`, `qa-lane-pr-batch.ps1` / `npm run qa:agent` (pre-flight ship lanes 1–3, then merge PRs), `git-sync-main.ps1` (fetch + ff `main` before each handoff and after each merge), `linear-complete-from-merged-prs.ps1` / `npm run linear:complete-merged-lane-prs`, `lane-worktrees-reset-for-next-cycle.ps1`). **Copilot instruction sync:** `.github/copilot-instructions.md` ↔ `.claude/CLAUDE.md` / GDD. **Cursor:** `.vscode/tasks.json` (daily + parallel Cursor + parallel Copilot lanes + both simple flows + QA) matches **`docs/DAILY.md`** / **`docs/COPILOT_LANES.md`**.
- [ ] Cloud and local mode switch scripts are operational.
- [ ] Docs mention Windows/Steam-first and mobile-first UX constraints.
- [ ] Deferred iOS lane remains documented but not required for daily work.
- [ ] `godot-full` MCP: `tools/install/setup-godot-mcp-full.ps1` run so `tools/godot-mcp-full/build/index.js` exists (folder is gitignored); **`godot-full` is the primary Godot MCP** for this repo.
- [ ] Parallel local agents: document `tools/tasks/new-agent-worktree.ps1` when changing branch/worktree workflow.
- [ ] After pipeline/LDtk/CI/MCP changes: `README.md`, `docs/OPEN_SOURCE_AND_PIPELINE.md`, and `docs/BLUEPRINT_GAP_AUDIT.md` updated as needed.

