# Cursor Cloud Agent Setup

Reference: [Cursor Cloud Agents](https://cursor.com/docs/cloud-agent#cloud-agents)

## Goals

- Keep cloud agent behavior equivalent to local workflows.
- Preserve script-based entry points so any runtime can execute same tasks.

## Setup Checklist

- Ensure `.cursor/mcp.json` is present and valid.
- Ensure MCP contains `linear`, `godot`, optional **`godot-full`** (run `tools/install/setup-godot-mcp-full.ps1` first), and `github` entries. Godot docs: official URLs — `docs/GODOT_DOCS_ACCESS.md` (no separate docs MCP).
- Confirm `.cursor/rules/*.mdc` are loaded in workspace.
- Ensure `tools/tasks/*.ps1` are the command entry points.
- Validate fallback scripts in `tools/dev/`.

## Parity Test

1. Run local: `pwsh ./tools/tasks/daily.ps1`
2. Run cloud equivalent task.
3. Compare outputs for command parity and path policy compliance.

