# Blueprint Gap Audit

Source audited:

- `docs/The Complete AI Multi-Agent Blueprint for Shipping Whether_ Parallel Agents, Orchestration, and Indie Game Development Toolkit.md`

## Audit Summary

### Previously Missing

1. Producer/PM role file and explicit PM loop.
2. Automated dispatch/pickup scripts for Linear task flow.
3. Godot docs MCP server in Cursor MCP config.
4. Complete cross-tool agent catalog beyond initial four role files.

### Fixes Applied

1. Added producer and expanded role definitions:
   - `.claude/agents/producer.md`
   - `.claude/agents/ui-developer.md`
   - `.claude/agents/release-ops.md`
2. Added Linear orchestration scripts:
   - `tools/linear/dispatch-tasks.ts`
   - `tools/linear/pickup-task.ts`
   - `tools/linear/producer-cycle.ts`
   - `tools/linear/role-map.ts`
3. Added `godot-docs` MCP server to `.cursor/mcp.json`.
4. Added operator docs/commands:
   - `docs/AGENT_CATALOG.md`
   - updated `docs/LINEAR_SETUP.md`
   - `.cursor/commands/linear-*.md`
5. Expanded outline-driven backlog templates:
   - `docs/backlog/outline-master.json`
   - included in `tools/linear/seed-backlog.ts`

## Remaining Intentional Deferments

- Automatic PR-link comment posting is not yet auto-wired.
- Project/label/state creation in Linear is still partly manual (seed currently creates issues from templates).
- Full 250+ issue generation from complete GDD can be expanded further in a dedicated backlog-generation pass.

## Recommended Next Expansion

1. Add PR-link auto-comment support in close-loop step.
2. Add `tools/linear/bootstrap-workspace.ts` to create labels/projects/states where missing.
3. Add per-role SLA reporting (stalled >3 days, blocked issues).

