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
- `LINEAR_MAX_IN_PROGRESS` — max **In Progress** count before `linear:dispatch` stops pulling from Todo (default **3**).
- `LINEAR_DISPATCH_ROLES` — comma-separated roles for dispatch (default: gameplay, UI, level-design, art — not `producer` / `qa-agent`; use `linear:resume-pickup` for those).

If **`npm run linear:status`** shows **headroom 0**, `linear:promote` will not move Backlog → Todo until you complete/cancel issues or adjust **`LINEAR_ACTIVE_ISSUE_CAP`** (documented in `LINEAR_ENV_VARS.md`).

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

## If your Linear workspace has no labels yet

Run this once to create missing required labels and backfill role labels on unlabeled Backlog/Todo/In Progress issues:

```powershell
npm run linear:label-backfill -- --apply
```

Then run PM ordering + assignment files:

```powershell
npm run linear:pm-organize -- --apply
npm run linear:pm-feed-todo -- --apply
npm run linear:pm-assignments
```

Or all-in-one:

```powershell
npm run linear:pm-prepare
```

To auto-fill Todo by PM phase order (foundation-first) up to a queue target:

```powershell
npm run linear:pm-feed-todo -- --apply
# optional target override
npm run linear:pm-feed-todo -- --apply --target=12
```

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
npm run linear:resume-pickup -- --role=gameplay-programmer --apply
```

Supported roles:

- `producer`
- `gameplay-programmer`
- `ui-developer`
- `level-designer`
- `qa-agent`
- `art-pipeline`

### Solo dev: what “role” means here

You only need **one** Linear user (yourself). `--role` does **not** require six people. It chooses **which lane of work** to pull next: scripts infer role from issue **title prefixes** (for example `[LEVEL-IMPLEMENT]` → gameplay-programmer) and from team **labels** (for example `Core-Engine`, `UI-UX`, `QA-Testing`). See `tools/linear/role-map.ts`.

Set **either**:

- `LINEAR_DEFAULT_ASSIGNEE_ID` to your Linear **user id** (simplest), or
- every `LINEAR_ASSIGNEE_*` to that same id if you prefer explicit wiring.

Then `pickup --role=qa-agent --apply` still makes sense: it finds the next **Todo** issue classified as QA, moves it to **In Progress**, and assigns it to you. You can run different terminals or sessions “as” different roles without separate Linear accounts.

Close-loop (In Progress → In Review):

```powershell
npm run linear:close -- --issue=WHT-123 --apply
```

Before closing UI or level work, run automated checks (GUT + level validation):

```powershell
pwsh ./tools/tasks/validate.ps1
```

### Visual QA (godogen-style) and this repo

[godogen](https://github.com/htdt/godogen) runs Godot, captures **screenshots**, and feeds them to vision models for a closed-loop visual QA pass — powerful for “does it look right”, not just “does it compile”. It targets **Godot 4 + C#** and **Claude Code** skills, which is a different stack than Weather Whether’s **GDScript** + Cursor tooling.

**Current Weather Whether flow:** headless **GUT** tests and **level solver validation** via `validate.ps1` (see `tools/tasks/validate.ps1`) — deterministic, CI-friendly, no screenshot pipeline yet.

**Recommended:** keep validate + CI as the **required** gate before `linear:close`; treat **screenshot → model review** as an **optional** follow-on (manual captures, Playwright against an export, or a small Godot capture script) when you want godogen-like polish without rewriting the project in C#. The blueprint also references godogen for inspiration: `docs/The Complete AI Multi-Agent Blueprint for Shipping Whether_ Parallel Agents, Orchestration, and Indie Game Development Toolkit.md`.

## Required Env IDs for State Transitions

- `LINEAR_STATE_TODO_ID`
- `LINEAR_STATE_IN_PROGRESS_ID`
- `LINEAR_STATE_IN_REVIEW_ID` (reserved for close-loop automation)

## Notes

- Backlog templates are in `docs/backlog/*.json` and `outline-master.json`.
- Seeding **dedupes by exact title** against existing team issues (paginated); safe reruns within the same template set.
- Full variable reference: `docs/LINEAR_ENV_VARS.md`.
- Dispatch/pickup scripts default to dry-run unless `--apply` is provided.

