# Copilot CLI lanes (Weather Whether) — mirror of Cursor lanes

This path is for when **Cursor `cursor-agent` hits usage limits** or you prefer **GitHub Copilot CLI** in the **integrated terminal** (still inside Cursor IDE). It mirrors **`run-lane-terminal.ps1`**: same **`linear:resume-pickup`**, same **`lane-agent-prompt.md`** body, same **auto-ship** via **`lane-ship.ps1`**.

## How it runs (non-interactive)

Per [Run multiple agents at once with `/fleet` in Copilot CLI](https://github.blog/ai-and-ml/github-copilot/run-multiple-agents-at-once-with-fleet-in-copilot-cli/) and [Copilot CLI `/fleet` concept](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/fleet):

- Each lane executes **`copilot -p "<pointer>" --no-ask-user`** from **that lane’s worktree** (parallel **three** terminals = three independent agents, same pattern as three **`cursor-agent`** processes).
- The **pointer** tells the agent to read **`WEATHER_COPILOT_LANE_PROMPT.md`** (full task spec) and **`.github/copilot-instructions.md`** so we avoid huge `-p` strings and Windows command-line limits.

Optional **`WEATHER_COPILOT_USE_FLEET=1`**: the pointer is sent as **`/fleet …`** so the **orchestrator** may split work into subagents **inside that worktree** ([`/fleet` behavior](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/fleet)). Use only when you want decomposition; default is a **single** agent per lane (parallelism = **lane count**, like Cursor).

## Prerequisites

1. **Install [GitHub Copilot CLI](https://docs.github.com/copilot/how-tos/use-copilot-agents/use-copilot-cli)** and ensure **`copilot`** is on `PATH`, or set **`WEATHER_COPILOT_CLI`** to the executable path.
2. **Authenticate** per GitHub docs (`gh auth` / Copilot login as required by your install).
3. **`.env.local`** on the **main** repo for Linear (unchanged).

## Tasks / npm

| Cursor (unchanged) | Copilot CLI |
|--------------------|-------------|
| **Weather Whether — Lane N** | **Weather Whether — Lane N Copilot** |
| **All lane terminals (parallel)** | **All Copilot lane terminals (parallel)** |
| **Daily apply:lanes, then parallel lane agents** | **Daily apply:lanes, then parallel Copilot lanes** |
| **Simple flow: daily+lanes+QA** | **Simple flow Copilot: daily+Copilot lanes+QA** |
| **`npm run workflow:simple`** | **`npm run workflow:simple:copilot`** |

## Instruction sync

- **`AGENTS.md`** (repo root) — Copilot **agent** entry point; directs agents to **`.claude/CLAUDE.md`** and this repo’s **`.github/copilot-instructions.md`**.
- **`.github/copilot-instructions.md`** ↔ **`.claude/CLAUDE.md`**, **`.claude/agents/*.md`**, and **`docs/GAME_DESIGN.md` v2** (same rules as Cursor/Claude).
- Optional VS Code/Cursor settings to load instruction files into **Copilot Chat** when you open Chat manually — not required for **CLI** lanes.

## Environment variables

| Variable | Purpose |
|----------|---------|
| **`WEATHER_COPILOT_CLI`** | Full path to **`copilot`** if not on `PATH` |
| **`WEATHER_COPILOT_USE_FLEET`** | **`1`** / **`true`** — prefix CLI prompt with **`/fleet`** for orchestrator-style splits **within** that lane’s worktree |
| **`WHETHER_AGENT_ROOT`** | Agent worktrees root (default `D:\Agents\WeatherWether`) |

## Flags (advanced)

- **`run-lane-copilot-terminal.ps1 -SkipCopilotRun`** — only write **`WEATHER_COPILOT_LANE_PROMPT.md`** (e.g. paste into **Copilot Chat** if CLI unavailable).
- **`-SkipAutoShip`** — do not run **`lane-ship.ps1`** after the CLI exits (default is **auto-ship** when the worktree **needs ship**, same as Cursor).

## Premium / billing

GitHub bills **premium requests** for Copilot CLI LLM turns; **`/fleet`** may use **more** turns because of subagents ([billing note in docs](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/fleet)). Prefer default (no `/fleet`) for steady lane usage; enable fleet when one lane benefits from explicit decomposition.
