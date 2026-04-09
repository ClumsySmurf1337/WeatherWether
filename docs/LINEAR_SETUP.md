# Linear Setup

## Prerequisites

- Linear workspace and team created.
- API key generated.
- `.env` contains:
  - `LINEAR_API_KEY`
  - `LINEAR_TEAM_ID`

## Install Dependencies

```powershell
npm install
```

## Bootstrap Team Workspace (projects/labels/states)

Dry-run:

```powershell
npm run linear:bootstrap
```

Apply:

```powershell
npm run linear:bootstrap -- --apply
```

This writes `.env.linear.generated` with discovered IDs for:

- `LINEAR_TEAM_ID`, `LINEAR_TEAM_KEY`, `LINEAR_WORKSPACE_ID`
- `LINEAR_STATE_TODO_ID`, `LINEAR_STATE_IN_PROGRESS_ID`, `LINEAR_STATE_IN_REVIEW_ID`
- `LINEAR_STATE_TRIAGE_ID`, `LINEAR_STATE_BACKLOG_ID`, `LINEAR_STATE_DONE_ID`
- Optional: `BACKLOG`, `TODO`, `IN_PROGRESS`, `IN_REVIEW`, `DONE` (human-readable names for scripts)

Put your API key in `.env.local` (gitignored):

```powershell
pwsh ./tools/tasks/init-linear-env.ps1
```

## Caps and phased intake

Linear teams often hit an **active issue ceiling** (~250). This repo caps and batches seeding by env:

- `LINEAR_ACTIVE_ISSUE_CAP` — stop creating issues when non-terminal count reaches this (default 230).
- `LINEAR_SEED_BATCH_MAX` — max new issues per seed run.
- `LINEAR_PROMOTE_BATCH_MAX` — max Backlog → Todo per `linear:promote` run.

Promote backlog when you have headroom:

```powershell
npm run linear:promote -- --dry-run
npm run linear:promote -- --apply
```

Workspace snapshot:

```powershell
npm run linear:status
```

## One-command full setup

```powershell
pwsh ./tools/tasks/linear-full-setup.ps1 -LinearApiKey "<your key>" -TeamKey "WEA"
```

This executes:

1. workspace bootstrap (`linear:bootstrap --apply`)
2. full backlog creation (`linear:seed`)
3. producer cycle preview (`linear:producer`)

## Dry Run

```powershell
npm run linear:seed -- --dry-run
```

The seeding script includes expanded outline-derived generation and targets 150+ tasks by default.

## Create Backlog

```powershell
npm run linear:seed
```

## Daily Standup Summary

```powershell
npm run linear:standup
```

## PM Dispatch Cycle (Producer Agent)

Dry-run cycle:

```powershell
npm run linear:producer
```

Apply cycle (moves matching Todo issues to In Progress):

```powershell
npm run linear:producer -- --apply
```

Direct dispatch only:

```powershell
npm run linear:dispatch -- --apply
```

Worker pickup by role:

```powershell
npm run linear:pickup -- --role=gameplay-programmer --apply
```

Supported roles:

- `producer`
- `gameplay-programmer`
- `ui-developer`
- `level-designer`
- `qa-agent`
- `art-pipeline`

Close-loop (In Progress -> In Review):

```powershell
npm run linear:close -- --issue=WHT-123 --apply
```

## Required Env IDs for State Transitions

- `LINEAR_STATE_TODO_ID`
- `LINEAR_STATE_IN_PROGRESS_ID`
- `LINEAR_STATE_IN_REVIEW_ID` (reserved for close-loop automation)

## Notes

- Backlog templates are in `docs/backlog/*.json` and `outline-master.json`.
- Seeding **dedupes by exact title** against existing team issues (paginated); safe reruns within the same template set.
- Full variable reference: `docs/LINEAR_ENV_VARS.md`.
- Dispatch/pickup scripts default to dry-run unless `--apply` is provided.

