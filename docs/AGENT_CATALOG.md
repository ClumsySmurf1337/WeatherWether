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

- `godot` server for project/editor operations.
- `godot-docs` server for API/class reference lookups.

