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

- `LINEAR_TEAM_ID`
- `LINEAR_STATE_TODO_ID`
- `LINEAR_STATE_IN_PROGRESS_ID`
- `LINEAR_STATE_IN_REVIEW_ID`

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

- Backlog templates are in `docs/backlog/*.json`.
- Seeding is idempotent by convention only; reruns can create duplicates.
- Dispatch/pickup scripts default to dry-run unless `--apply` is provided.

