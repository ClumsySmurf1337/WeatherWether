# Copilot parallel lanes (Weather Whether)

This mirrors the **DeedWise** pattern: **same Linear resume + injected prompt per lane**, but the **execution surface** is **GitHub Copilot Chat (Agent)** or an optional **Copilot CLI** — not **`cursor-agent`**.

DeedWise today mostly **prints** paste-ready blocks (`switch-to-copilot.ps1`, VS Code extension) and relies on **`.github/copilot-instructions.md`** staying aligned with **`AGENTS.md`**. Here we write **`WEATHER_COPILOT_LANE_PROMPT.md`** per worktree and keep **`.github/copilot-instructions.md`** aligned with **`.claude/CLAUDE.md`** and **`docs/GAME_DESIGN.md`**.

## Cursor lanes (unchanged)

- **Tasks →** **Weather Whether — Lane 1/2/3** → **`run-lane-terminal.ps1`** → **`cursor-agent`** + auto-ship when configured.
- **Simple flow** → **`npm run workflow:simple`** or the matching compound Task.

## Copilot lanes (new)

- **Tasks →** **Weather Whether — Lane N Copilot** or **All Copilot lane terminals (parallel)** → **`run-lane-copilot-terminal.ps1`**:
  1. Runs **`linear:resume-pickup`** from the **main** repo (same as Cursor lanes).
  2. Writes **`WEATHER_COPILOT_LANE_PROMPT.md`** in the lane worktree (same task body as **`tools/tasks/prompts/lane-agent-prompt.md`**, plus Copilot-specific launcher notes).
  3. Prints steps to open the worktree in **VS Code / Cursor**, use **Copilot Chat → Agent**, attach the prompt file + **`.github/copilot-instructions.md`**.
- **Auto-ship is off by default** (Copilot does not exit like `cursor-agent`). After work: **`npm run lane:ship -- -LaneIndex N`** from main, or **`npm run qa:agent`** (preflight ship).
- **Optional:** set **`WEATHER_COPILOT_CLI_RUN=1`** and install **[Copilot CLI](https://docs.github.com/copilot/how-tos/use-copilot-agents/use-copilot-cli)** (`copilot` on PATH or **`WEATHER_COPILOT_CLI`**). The script will run **`copilot -p "<full prompt>"`** (experimental; long prompts may need a future file-based flag).

## Simplified flows

| Flow | Task / command |
|------|----------------|
| Cursor | **Simple flow: daily+lanes+QA** or **`npm run workflow:simple`** |
| Copilot | **Simple flow Copilot: daily+Copilot lanes+QA** or **`npm run workflow:simple:copilot`** |

## VS Code settings (recommended for instruction sync)

Same idea as DeedWise **`.vscode/settings.json`**: enable **instruction files** for Copilot Chat so **`.github/copilot-instructions.md`** loads automatically. Example:

```json
"github.copilot.chat.codeGeneration.useInstructionFiles": true,
"github.copilot.chat.codeGeneration.instructions": [
  ".github/copilot-instructions.md",
  ".claude/CLAUDE.md"
]
```

Adjust if your editor schema differs.

## Environment variables

| Variable | Purpose |
|----------|---------|
| **`WEATHER_COPILOT_CLI_RUN`** | **`1`** / **`true`** — run **`copilot`** after writing the prompt file |
| **`WEATHER_COPILOT_CLI`** | Full path to **`copilot`** if not on PATH |

See also **`docs/LINEAR_ENV_VARS.md`** for Cursor lane vars.
