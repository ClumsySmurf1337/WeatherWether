# Weather Whether — agent instructions

This file exists so **GitHub Copilot agents** (and any tool that loads `AGENTS.md`) follow the **same contract** as **Claude Code** and **Cursor** in this repository. See [GitHub Docs: repository custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions).

## Mandatory sources (read before editing)

1. **`.claude/CLAUDE.md`** — canonical reading order, quality bar, scope boundaries, roles, Linear/runtime rules. **Read it in full.**
2. **`.github/copilot-instructions.md`** — same contract plus **Copilot CLI** lane pointers, **`WEATHER_COPILOT_LANE_PROMPT.md`**, optional **`/fleet`**, and explicit **validate.ps1** / CI expectations.
3. **Your role** — open the matching file under **`.claude/agents/`** (listed in **`docs/AGENT_CATALOG.md`**).

## Non‑negotiables

- **GDD wins:** `docs/GAME_DESIGN.md` v2 is authoritative for mechanics and UX.
- **Validate before handoff:** `pwsh tools/tasks/validate.ps1` (add **`-GodotProjectPath`** when working in a git worktree). Fix GUT and level validation failures before PRs.
- **Strict typed GDScript**, deterministic puzzle rules, mobile-first UI — as in `.claude/CLAUDE.md` and `.cursor/rules/`.

When `.claude/CLAUDE.md` or agent role files change, update **`.github/copilot-instructions.md`** in the same PR so Copilot and Cursor stay aligned.
