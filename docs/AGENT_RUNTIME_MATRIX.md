# Agent Runtime Matrix

## Modes

- `cloud`: Cursor Cloud Agents handle long-running and parallel work.
- `local`: Cursor IDE + Claude Code/Copilot fallback.
- `hybrid`: Use cloud by default with scripted fallback to local.

## Responsibilities

| Area | Cloud | Local |
|---|---|---|
| Long async implementation | Primary | Backup |
| Sensitive/secrets tasks | Optional | Preferred |
| Fast edits and local playtest | Optional | Primary |
| Offline/cloud outage continuity | N/A | Primary |

## Shared Rules

- Follow `.cursor/rules/*.mdc`.
- Use `tools/tasks/*.ps1` entry points.
- Respect file-scope boundaries for parallel agents.
- Keep all generated caches/builds on D drive.

