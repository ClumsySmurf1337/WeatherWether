# Agent Catalog

This catalog aligns agent roles across Cursor cloud/local and Claude-style role files.

**Design spine:** PM and every agent keep work aligned with the **core concept** in `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md` — grid + weather **cards** (order + placement) + **six weathers** + later **fog / uncertainty**.

## PM/Orchestration

- `producer` (`.claude/agents/producer.md`)
  - Runs standup, dispatches Todo work, monitors risk; guards scope against the GDD spine.

## Implementation Roles

- `gameplay-programmer` (`.claude/agents/gameplay-programmer.md`)
- `ui-developer` (`.claude/agents/ui-developer.md`)
- `level-designer` (`.claude/agents/level-designer.md`)
- `qa-agent` (`.claude/agents/qa-agent.md`)
- `art-pipeline` (`.claude/agents/art-pipeline.md`)
- `release-ops` (`.claude/agents/release-ops.md`)

## Task Orchestration Flow

1. Bootstrap workspace with `linear:bootstrap` (projects/labels/states).
2. Seed backlog with `linear:seed`.
3. Producer runs `linear:producer` (dry-run).
4. Producer applies dispatch `linear:producer -- --apply`.
5. Worker agents claim by role using `linear:resume-pickup -- --role=<role> --apply` (resumes in-progress first).
6. Workers execute implementation and validation scripts.

## Godot MCP (what is wired)

| Server | Role |
|--------|------|
| **`godot-full`** | **Primary** — [tugcantopaloglu/godot-mcp](https://github.com/tugcantopaloglu/godot-mcp). Run `pwsh ./tools/install/setup-godot-mcp-full.ps1`; MCP runs `node tools/godot-mcp-full/build/index.js`. Best for **UI/Control**, runtime inspection, exports, broad tool surface. |
| **`godot`** | **Optional** — [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) via `npx -y` when you want a quick tool without the local build. |
| **Paid (not installed)** | [youichi-uda/godot-mcp-pro](https://github.com/youichi-uda/godot-mcp-pro) — evaluate only if `godot-full` is still limiting. |

## Godot API documentation

No `godot-docs` MCP. Use **official** [Godot 4.6 docs](https://docs.godotengine.org/en/4.6/) and `docs/GODOT_DOCS_ACCESS.md`; index in Cursor if you want @-Docs style lookup.

## Local parallel agents (no self-hosted cloud)

**Cursor Cloud is hosted by Cursor only.** For parallel lanes on Windows, use **git worktrees** + multiple Cursor windows:

`pwsh ./tools/tasks/new-agent-worktree.ps1 -BranchName agent/your-lane`

Scopes: `docs/CURSOR_PARALLEL_AGENTS.md`, `.claude/CLAUDE.md`.

Study links and LDtk pipeline gaps: [OPEN_SOURCE_AND_PIPELINE.md](OPEN_SOURCE_AND_PIPELINE.md).
