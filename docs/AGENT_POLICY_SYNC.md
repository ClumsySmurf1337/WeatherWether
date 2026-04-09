# Agent Policy Sync

This project keeps one policy contract across Cursor cloud, Cursor local, Claude Code, and Copilot-assisted workflows.

## Source of Truth

- Architecture and coding behavior: `.cursor/rules/*.mdc`
- Runtime behavior and boundaries: `.claude/CLAUDE.md`
- Operational commands: `tools/tasks/*.ps1`

## Sync Rules

When changing standards:

1. Update `.cursor/rules` first.
2. Mirror intent in `.claude/CLAUDE.md` and specific `.claude/agents/*`.
3. Verify command references still point to `tools/tasks/*`.
4. Update `docs/AGENT_SYNC_CHECKLIST.md` if process changed.

