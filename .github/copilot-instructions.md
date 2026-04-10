# Weather Whether — GitHub Copilot instructions

> Copilot Chat / Agent reads this file when your editor is configured to include **instruction files** (same idea as DeedWise `.github/copilot-instructions.md`). Keep this aligned with **`.claude/CLAUDE.md`**; on mechanics or UX disputes, **`docs/GAME_DESIGN.md` v2** wins.

## Product

- **Godot 4.6**, strict typed **GDScript**, **signal-based** systems, **deterministic** puzzle logic (no randomness in rules).
- **Mobile-first** UI; **Windows/Steam** shipping lane.
- **Six** weather cards × **fourteen** terrain types; win = reach goal after queue → resolve → walk.

## Before you edit

1. **`docs/GAME_DESIGN.md` v2** — authoritative mechanics and UI contract.
2. **`.claude/CLAUDE.md`** reading order for agents: `UI_SCREENS.md`, `ASSET_MANIFEST.md`, `SPEC_DIFF.md`, then `.cursor/rules/weather-game.mdc`.
3. **`docs/CURSOR_PARALLEL_AGENTS.md`** — stay inside the file scope for your **lane role** (gameplay / UI / levels).

## Lane roles (parallel worktrees)

| Lane | Role | Typical scope |
|------|------|----------------|
| 1 | gameplay-programmer | `scripts/grid`, `scripts/weather`, `scripts/puzzle` |
| 2 | ui-developer | `scripts/ui`, `scenes/ui`, `assets/ui` |
| 3 | level-designer | `levels`, validation, level JSON |

## Linear + ship

- Issue ids use team key **`WEA-###`** in PR titles and **`.weather-lane-issue.txt`** in the worktree.
- **Validate before handoff:** `pwsh <MAIN_REPO>/tools/tasks/validate.ps1 -GodotProjectPath <worktree>` until GUT + levels pass.
- **Ship:** from main repo `npm run lane:ship -- -LaneIndex <1|2|3>` or QA **`npm run qa:agent`** (preflight ship + merge).

## Copilot ↔ Cursor sync

- **Cursor lane Tasks** run **`cursor-agent`** with the same task text written to **`WEATHER_COPILOT_LANE_PROMPT.md`** for Copilot lanes.
- Update **this file** when you change global agent rules so Copilot and Claude/Cursor stay consistent.
