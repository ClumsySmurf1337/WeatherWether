# Weather Whether

Weather Whether is a mobile-first weather puzzle game built with Godot 4.6 and GDScript, with Windows/Steam delivery first and mobile lanes prepared from day one.

## Quick Start (Win11)

1. Open this repo in Cursor.
2. Run `tools/install/bootstrap-win11.ps1` in PowerShell.
3. Run `tools/tasks/daily.ps1`.
4. Launch the game with `tools/tasks/launch.ps1`.
5. Optional — **full Godot MCP** for agents (UI/scene/runtime tools): `pwsh ./tools/install/setup-godot-mcp-full.ps1`, then restart Cursor (`godot-full` in `.cursor/mcp.json`).

## Current Delivery Order

1. Windows/Steam playable loop and build pipeline.
2. Android compatibility and packaging.
3. iOS remote-mac pipeline activation (deferred, prewired docs/templates included).

## Canonical Local Paths

- `D:\Godot` for Godot binaries.
- `D:\Dev\WeatherWether` for source checkout.
- `D:\Caches\WeatherWether` for package and tool caches.
- `D:\Builds\WeatherWether` for artifacts.
- `D:\Agents\WeatherWether` for local agent logs/worktrees.

See `docs/PATHS_AND_STORAGE_POLICY.md` for details.

## Key Docs

- `docs/SETUP_WIN11.md`
- `docs/AGENT_RUNTIME_MATRIX.md`
- `docs/FALLBACK_PLAYBOOK.md`
- `docs/CURSOR_CLOUD_AGENT_SETUP.md`
- `docs/DAILY.md`
- `docs/CURSOR_CLI_AND_WORKTREES.md`
- `docs/LINEAR_ENV_VARS.md`
- `docs/AUTONOMOUS_ORCHESTRATION.md`
- `docs/CURSOR_PARALLEL_AGENTS.md`
- `docs/MOBILE_RELEASE_PATHS.md`
- `docs/AGENT_CATALOG.md`
- `docs/TOOL_AGENT_MATRIX.md`
- `docs/BLUEPRINT_GAP_AUDIT.md`
- `docs/PM_AGENT_LINEAR.md`
- `docs/OPEN_SOURCE_AND_PIPELINE.md`
- `docs/GODOT_DOCS_ACCESS.md`
- `docs/STITCH_UX_WORKFLOW.md`

## Daily Commands

- `npm run daily:full` (or `pwsh ./tools/tasks/daily-full.ps1`) — prerequisites, `npm ci`, Linear PM preview, Godot validation; from **Cursor’s integrated terminal** it also refreshes assignments, syncs lane worktrees, and prints **Tasks → All lane terminals** (use **`npm run daily:full:lean`** or **`-SkipEditorLanePrep`** to skip that). **`npm run daily:full:apply`** applies producer; see `docs/DAILY.md`
- **Cursor Tasks** (`.vscode/tasks.json`) — **Weather Whether — Daily apply:lanes, then parallel lane agents** runs **`daily:full:apply:lanes`** then **three lane agents in parallel**; each lane terminal **closes when that lane finishes** (`presentation.close`). **Weather Whether — QA agent (lane PRs)** runs **`npm run qa:agent`**. See **`docs/DAILY.md`** for the full loop.
- `npm run cursor:session` / `cursor:session:apply` — Linear producer + validate + parallel lanes; add `-CreateWorktrees` **`-SpawnAgentCli`** to launch **`cursor-agent`** (fallback: **`cursor agent`**) per worktree (see `docs/CURSOR_CLI_AND_WORKTREES.md`)
- `npm run cursor:resume:editor` — recover after interruption **without** extra PowerShell popups: refresh assignments, sync worktrees, ensure lane worktrees, then run **Tasks → Weather Whether — All lane terminals (parallel)** in this window
- `npm run cursor:resume` — same prep, but spawns **one external `pwsh` per lane** running `cursor-agent` (use if you prefer separate windows)
- `npm run cursor:go:editor` — full PM kickoff + same integrated-terminal hint (no external lane popups)
- `npm run cursor:open-lanes` — optional: open **new Cursor windows** on each lane worktree (does not conflict with resume; skip if you use integrated Tasks)
- `npm run qa:pr -- -PullRequestNumber <N>` — wait on CI, local validate, `gh pr merge`, **Linear Done** via local API key (see `docs/GITHUB_AUTOMERGE.md`); add **`-SyncMainBeforeValidate`** to merge `main` first (conflicts → **`cursor-agent`** / **`cursor agent`**)
- `npm run lane:ship -- -LaneIndex <1-3>` — commit + push + open PR when a lane worktree has **uncommitted changes or unpushed commits** (Linear id from **`.weather-lane-issue.txt`** after `resume-pickup`, or **`-LinearId WEA-###`**); validates via `validate.ps1 -GodotProjectPath`
- `npm run lane:ship:lanes` — run **`lane:ship`** for lanes **1–3** (recovery when agents left local commits without a PR)
- `npm run qa:agent` (alias: **`npm run qa:lane-prs`**) — **Pre-flight:** ship lanes **1–3** if a worktree has uncommitted or unpushed work (opens PRs). Then QA **open** PRs with head **`agent/cursor-lane-*`**: merge main, validate, merge, **Linear Done**, `worktrees:sync`, **`docs/CHANGELOG_LANES.md`**, reset lane branches. **`-SkipPreflightShip`** skips the ship scan; **`-SkipResetLaneBranches`** skips branch reset; **`npm run lane:next-cycle`** if you skipped reset
- `npm run qa:lane-prs:quick` — same batch but **`-SkipChecksWatch`** (use when CI already green)
- `npm run lane:next-cycle` — reset each **`wt-agent-cursor-lane-*`** to a new **`agent/cursor-lane-N`** branch from **main** after merges
- `npm run qa:repair-merge` — merge `origin/main` in current repo/worktree; on conflict opens **Cursor CLI** with the QA merge prompt (see `.cursor/commands/qa-repair-merge.md`)
- `npm run linear:pm-prepare` — one command PM pass: bootstrap labels/states/projects, role-label backfill, phase-priority organize apply, and assignment file generation
- `npm run linear:pm-organize -- --apply` / `npm run linear:pm-feed-todo -- --apply` / `npm run linear:pm-assignments` — dependency-aware ordering + Todo queue fill + DeedWise-style per-role assignment markdown
- `npm run linear:plan-deps` — generate dependency + file-scope plan for non-overlapping lanes
- `npm run linear:apply-deps -- --apply` — write real Linear `blocks` relations from dependency heuristics
- `npm run linear:kickoff-first -- --role=gameplay-programmer --apply` — force-start first role issue (Todo first, otherwise Backlog) for build testing
- `npm run linear:kickoff-lanes -- --apply` — force-start one issue each for gameplay/UI/level lanes
- `npm run cursor:go` — full kickoff (PM prepare + dependency edges + Todo feed + lane kickoff + **external** `pwsh` per lane)
- `npm run linear:resume-pickup -- --role=gameplay-programmer --apply` — resume existing in-progress lane work first, otherwise claim a Todo issue
- `npm run worktrees:sync` — merge `origin/main` into each `wt-*` under the agent root
- `tools/tasks/daily.ps1` quick health/status checks
- `tools/tasks/build.ps1` local build/export workflow
- `tools/tasks/validate.ps1` tests and level validation
- `tools/tasks/launch.ps1` open game in Godot
- `tools/tasks/mobile-preview.ps1` mobile-oriented preview settings
- `tools/tasks/new-agent-worktree.ps1 -BranchName agent/your-lane` second checkout under `D:\Agents\WeatherWether` for **parallel local** Cursor agents

## Backlog and PM Automation

- `tools/linear/seed-backlog.ts`
- `tools/linear/daily-standup.ts`
- `tools/linear/dispatch-tasks.ts`
- `tools/linear/pickup-task.ts`
- `tools/linear/producer-cycle.ts`
- `docs/LINEAR_SETUP.md`
- `tools/tasks/linear-full-setup.ps1`

