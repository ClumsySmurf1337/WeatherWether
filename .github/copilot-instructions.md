# Weather Whether — GitHub Copilot instructions

> Repository-wide instructions for [GitHub Copilot](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions) (Chat, CLI, code review, cloud agent). **Behavior must match Cursor and Claude Code** in this repo. On mechanics or UX disputes, **`docs/GAME_DESIGN.md` v2** wins.

## Reading order (do this before editing)

Read in order; they define the v2 sequence model + walking character.

1. `docs/GAME_DESIGN.md` — game design spine (**READ FIRST**)
2. `docs/UI_SCREENS.md` — screens and UX contract
3. `docs/ASSET_MANIFEST.md` — sprite/audio contract
4. `docs/SPEC_DIFF.md` — delta vs legacy instant-resolve; file targets in `docs/CODE_REWRITE_PLAN.md`
5. `docs/ANIMATION_DIRECTION_2D.md` — character and tile animation specs for v2
6. `.cursor/rules/weather-game.mdc` — runtime and arc rules; defers to `docs/GAME_DESIGN.md` on disputes

For UI layout and sprite reference, use `assets/mocks/README.md` and SVGs there (`level_mockup.svg` is canonical for `ui/screens/gameplay.tscn`). If older docs contradict the v2 list above, **v2 wins** — note the contradiction in the PR for the producer to clean up.

## Role files (same as Claude / Cursor)

Pick the file that matches your assignment and follow it in addition to this document:

| Role | File |
|------|------|
| producer | `.claude/agents/producer.md` |
| gameplay-programmer | `.claude/agents/gameplay-programmer.md` |
| ui-developer | `.claude/agents/ui-developer.md` |
| level-designer | `.claude/agents/level-designer.md` |
| qa-agent | `.claude/agents/qa-agent.md` |
| art-pipeline | `.claude/agents/art-pipeline.md` |
| release-ops | `.claude/agents/release-ops.md` |

Index: `docs/AGENT_CATALOG.md`. Canonical workspace rules for humans/agents: `.claude/CLAUDE.md` — **keep this file aligned when `.claude/CLAUDE.md` changes.**

**Current issue scope (WEA-###):** After `npm run linear:pm-assignments` on the **main** repo, read **`assignments/generated/<role>.md`** (e.g. `level_designer.md`) in this worktree — lane launchers and **`npm run worktrees:sync`** copy those gitignored handoffs from main into each lane worktree so you can implement without Linear API access here.

## Product

- **Godot 4.6**, strict typed **GDScript**, **signal-based** systems, **deterministic** puzzle logic (no randomness in rules).
- **Mobile-first** UI; **Windows/Steam** shipping lane.
- **Six** weather cards × **fourteen** terrain types; win = reach goal after queue → resolve → walk.

## Path policy

- Godot install path: `D:\Godot` (team default).
- Caches, build artifacts, temp files, and logs stay on **D:** — see `docs/PATHS_AND_STORAGE_POLICY.md` if you touch tooling.

## Quality before handoff (do not break CI)

- **Fix what you break:** Resolve GDScript parse errors, failing GUT tests, and level validation **on your branch** before you consider work done or open/refresh a PR.
- **Always validate:** From repo root (or pass your worktree):

  `pwsh tools/tasks/validate.ps1`

  In a **git worktree**, point at the worktree Godot project:

  `pwsh <MAIN_REPO>/tools/tasks/validate.ps1 -GodotProjectPath <worktree_path>`

- **CI:** `.github/workflows/ci.yml` mirrors validation — same failures block merge.
- **API truth:** For unfamiliar Godot APIs use **stable** class reference — `docs/GODOT_DOCS_ACCESS.md` (Godot **4.x**). Wrong signatures cause parse/runtime failures.

## Runtime parity

- Follow `.cursor/rules/*.mdc` (especially `whether-development.mdc`, `weather-game.mdc`, `godot-gdscript.mdc`).
- Prefer repo scripts in `tools/tasks/` over ad-hoc commands.
- **Godot MCP:** prefer **`godot-full`** after `pwsh ./tools/install/setup-godot-mcp-full.ps1`; optional lighter **`godot`** via `npx`. No `godot-docs` MCP — use official docs.
- **Parallel work:** Cursor Cloud is not self-hosted; local parallel lanes use git worktrees — `docs/CURSOR_PARALLEL_AGENTS.md`, `pwsh ./tools/tasks/new-agent-worktree.ps1 -BranchName agent/your-lane`.

## Parallel scope (avoid merge conflicts)

Stay inside the lane/role scope. Full matrix (including QA): **`docs/CURSOR_PARALLEL_AGENTS.md`**.

| Lane | Role | Typical scope |
|------|------|----------------|
| 1 | gameplay-programmer | `scripts/grid`, `scripts/weather`, `scripts/puzzle` (and gameplay-related tests under `test/` when your issue owns them) |
| 2 | ui-developer | `scripts/ui`, `scenes/ui`, `assets/ui` |
| 3 | level-designer | `levels`, level loader, validation, level JSON |

**QA agent** (often scripted, not lane 1–3): `test/`, `scripts/validate_all_levels.gd`, CI. **Release-ops:** `.github/workflows`, release docs.

## Linear + ship

- Issue ids: team key **`WEA-###`** in PR titles and **`.weather-lane-issue.txt`** in the worktree.
- Claim work: `linear:resume-pickup -- --role=<role> --apply` (resume in-progress first).
- **Ship:** from main repo `npm run lane:ship -- -LaneIndex <1|2|3>` or **`npm run qa:agent`** (preflight ship lanes + merge). See `docs/GITHUB_AUTOMERGE.md`, `docs/DAILY.md`.

## Copilot CLI ↔ Cursor lanes

- **Cursor lane Tasks** run **`cursor-agent`** with the same body as **`WEATHER_COPILOT_LANE_PROMPT.md`** (generated in the worktree).
- **Copilot CLI** runs **`copilot -p "<pointer>" --no-ask-user`** from the worktree; the pointer tells the agent to read **this file** and **`WEATHER_COPILOT_LANE_PROMPT.md`** ([non-interactive pattern](https://github.blog/ai-and-ml/github-copilot/run-multiple-agents-at-once-with-fleet-in-copilot-cli/)).
- Optional **`WEATHER_COPILOT_USE_FLEET=1`**: prepend **`/fleet`** for orchestrator-style subagents in one worktree ([`/fleet` docs](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/fleet)).

## Doc updates

When you change **CI**, **pipelines**, **LDtk import**, **level format**, **validation**, or **MCP**, update the smallest necessary set from `.cursor/rules/whether-development.mdc` (README, `docs/OPEN_SOURCE_AND_PIPELINE.md`, `docs/BLUEPRINT_GAP_AUDIT.md`, etc.).
