# Weather Whether - Autonomous Workflow Rundown

Last updated: 2026-04-09

This file captures what was discussed and implemented so far for the Cursor + Linear autonomous build system, including recovery flow, QA handoff, and naming updates.

## 1) Main outcome

You now have a local-first autonomous workflow where:

- PM automation organizes and prepares Linear work.
- Parallel implementation lanes run in isolated git worktrees/branches.
- Agents resume unfinished In Progress work after interruptions.
- QA merges PRs locally after CI and closes Linear from local env keys.
- One-command kickoff and one-command recovery are available.

## 2) Core behavior implemented

### PM + backlog orchestration

- Phase-based ordering and priority via `docs/backlog/pm-phase-plan.json`.
- Role inference and assignment automation.
- Missing-label creation + role label backfill for existing issues.
- Dependency planning and optional dependency edge writing in Linear.
- PM-controlled Todo queue feed from Backlog (ordered by phase/priority).

### Parallel execution lanes

- Lanes use git worktrees under `D:\Agents\WeatherWether\wt-*` (or `WHETHER_AGENT_ROOT`).
- Each lane role claims work by role.
- Scope boundaries documented to reduce file overlap/conflicts.
- Cursor CLI lane spawn support (`cursor agent`) through lane prompts.

### QA local merge + Linear completion

- QA flow is local (not GitHub Action auto-merge):
  - wait CI
  - checkout PR
  - run local validate
  - merge with `gh`
  - close Linear issues from PR title/body (`WEA-###`) using local `.env.local`.

### Recovery after interruption (PC shutdown / stop)

- Resume-first claim behavior implemented:
  - `linear:resume-pickup` checks In Progress for role first.
  - If none exists, it claims top Todo for role.
- Recovery command added:
  - `cursor:resume` regenerates assignment files, syncs worktrees, relaunches lanes in resume mode.
- Safety fix added:
  - `cursor:resume` now auto-creates missing worktrees so recovery cannot silently skip lane setup.

## 3) Key scripts/commands added or updated

### New/important scripts

- `tools/linear/resume-pickup.ts`
- `tools/tasks/cursor-resume.ps1`
- `tools/tasks/cursor-go.ps1` (full kickoff orchestrator)
- `tools/tasks/cursor-autonomous-session.ps1` (lane orchestration)
- `tools/tasks/qa-pr-handoff-local.ps1`
- `tools/tasks/qa-merge-conflicts.ps1`
- `tools/tasks/sync-agent-worktrees.ps1`
- `tools/tasks/run-cursor-chat.ps1`
- `tools/tasks/cursor-cli.ps1`

### NPM entry points in active use

- `npm run cursor:go`
- `npm run cursor:resume`
- `npm run cursor:session`
- `npm run cursor:session:apply`
- `npm run linear:pm-prepare`
- `npm run linear:pm-feed-todo -- --apply --target=<N>`
- `npm run linear:apply-deps -- --apply`
- `npm run linear:kickoff-lanes -- --apply`
- `npm run linear:resume-pickup -- --role=<role> --apply`
- `npm run qa:pr -- -PullRequestNumber <N>`
- `npm run qa:repair-merge`
- `npm run worktrees:sync`

## 4) Current lane lifecycle (authoritative)

1. PM prepares board:
   - `npm run linear:pm-prepare`
2. PM writes dependency edges:
   - `npm run linear:apply-deps -- --apply`
3. PM fills Todo by priority/phase:
   - `npm run linear:pm-feed-todo -- --apply --target=8`
4. Start one issue per lane:
   - `npm run linear:kickoff-lanes -- --apply`
5. Start sessions:
   - `npm run cursor:go`
6. Lane agent action:
   - `npm run linear:resume-pickup -- --role=<role> --apply`
7. Agent opens PR with `WEA-###` in title/body.
8. QA merges locally after CI:
   - `npm run qa:pr -- -PullRequestNumber <N>`

If interrupted:

- `npm run cursor:resume`

## 5) Important operational notes

- GitHub Actions now validate; they do not perform default auto-merge + Linear Done.
- Linear Done update is performed locally by QA path using `.env.local`.
- Godot path handling in validation is dynamic (`GODOT_PATH`/PATH first, local D-drive fallback).
- Worktree branch sync and conflict repair are built into QA/worktree scripts.

## 6) Naming updates completed

Branding text has been updated to:

- `Weather Whether` (no colon)

Applied across high-visibility project surfaces:

- app/project display name (`project.godot`)
- README title/intro
- QA/PM/autonomous docs and prompts
- workflow names (CI/build labels)
- script output banners

Repo identifiers and infrastructure names (for compatibility) remain unchanged where needed, e.g. folder/repo/env prefixes like `WeatherWether`, `WHETHER_*`, and existing file paths.

## 7) Sync instructions for your other agent/system

Use this as the handshake contract:

- Product name: `Weather Whether`
- Queue prep: `linear:pm-prepare` + `linear:pm-feed-todo`
- Lane claim command: `linear:resume-pickup` (resume-first requirement)
- Recovery command: `cursor:resume`
- Merge/close path: local `qa:pr` only
- PR rule: include `WEA-###` in title/body

Recommended boot sequence for external orchestrator:

1. `npm run linear:pm-prepare`
2. `npm run linear:apply-deps -- --apply`
3. `npm run linear:pm-feed-todo -- --apply --target=8`
4. `npm run linear:kickoff-lanes -- --apply`
5. `npm run cursor:session:apply -- -CreateWorktrees -SyncWorktrees -SpawnAgentCli`

Recovery sequence:

1. `npm run cursor:resume`
2. Verify worktrees/branches/PRs:
   - `git worktree list`
   - `git branch --list "agent/*"`
   - `gh pr list --state open --limit 30`

## 8) Known snapshot from recent check

At one point no PRs were visible because no lane worktrees/branches were present in that run. This was addressed by making `cursor:resume` create worktrees automatically.

