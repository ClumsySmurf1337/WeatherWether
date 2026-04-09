# Agent Catalog

This catalog aligns agent roles across Cursor cloud/local and Claude-style role files.

## PM/Orchestration

- `producer` (`.claude/agents/producer.md`)
  - Runs standup, dispatches Todo work, monitors risk.

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
5. Worker agents claim by role using `linear:pickup -- --role=<role> --apply`.
6. Workers execute implementation and validation scripts.

## Godot Documentation Access

Cursor MCP includes:

- `godot` server for project/editor operations ([Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp), configured in `.cursor/mcp.json`).
- `godot-docs` server for API/class reference lookups.

Optional upgrade for heavier scene/animation automation: [youichi-uda/godot-mcp-pro](https://github.com/youichi-uda/godot-mcp-pro) (paid, larger toolset) — swap or add as a second MCP server if needed.

### Godot MCP: Coding-Solo vs tugcantopaloglu fork

| | [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) (current) | [tugcantopaloglu/godot-mcp](https://github.com/tugcantopaloglu/godot-mcp) |
|---|----------------|---------------|
| **Scope** | ~20 tools: editor/run/stop, debug output, scene CRUD, sprites, UIDs | **149 tools**: extends Coding-Solo with runtime `game_eval`, property/method calls, signals, input simulation, `export_project`, scene-file JSON ops, TileMap, HTTP/WS, etc. |
| **Install** | `npx @coding-solo/godot-mcp` | **Clone + `npm install` + `npm run build`**, then `node …/build/index.js` in MCP config ([their README](https://github.com/tugcantopaloglu/godot-mcp)) |
| **Tradeoff** | Simple, npm-updatable, less to misconfigure | Much more agent power; larger attack surface; more moving parts and Godot-version coupling |

**Recommendation:** keep **Coding-Solo** as default. Consider **tugcantopaloglu** when you need headless **export** or heavy **runtime inspection** from agents; use a **separate MCP server name** (e.g. `godot-full`) if you run both.

