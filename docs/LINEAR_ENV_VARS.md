# Linear environment variables

All scripts load env in this order (later overrides): `.env` → `.env.linear.generated` → `.env.local`.  
Put your **API key only** in `.env.local` (gitignored). IDs can live in `.env.linear.generated` (no secrets).

## Required for API scripts

| Variable | Meaning | How to get it |
|----------|---------|----------------|
| `LINEAR_API_KEY` | Personal API key | Linear → Settings → API → Create key |
| `LINEAR_TEAM_ID` | UUID of team **Weather whether** | From `npm run linear:bootstrap -- --apply` output file `.env.linear.generated` or team URL in Linear (devtools) |
| `LINEAR_TEAM_KEY` | Short key (e.g. `WEA`) | Shown in Linear next to team name |

## Workflow state IDs (team-scoped UUIDs)

Each **workflow state** row in Linear has a stable ID. Dispatch/promote/close-loop need these.

| Variable | Typical Linear name | How to get |
|----------|---------------------|------------|
| `LINEAR_STATE_TRIAGE_ID` | Triage | Written by `linear:bootstrap` into `.env.linear.generated` |
| `LINEAR_STATE_BACKLOG_ID` | Backlog | Same — **new issues are created here** to stay under active caps |
| `LINEAR_STATE_TODO_ID` | Todo | Same |
| `LINEAR_STATE_IN_PROGRESS_ID` | In Progress | Same |
| `LINEAR_STATE_IN_REVIEW_ID` | In Review | Same |
| `LINEAR_STATE_DONE_ID` | Done | Same |

Run `npm run linear:bootstrap -- --apply` whenever you add/rename states; it refreshes `.env.linear.generated`.

## Assignee UUIDs (optional, for auto-assign)

| Variable | Role |
|----------|------|
| `LINEAR_ASSIGNEE_PRODUCER_ID` | Producer / catch-all onboarding |
| `LINEAR_ASSIGNEE_GAMEPLAY_ID` | Gameplay / Core-Engine |
| `LINEAR_ASSIGNEE_UI_ID` | UI-UX |
| `LINEAR_ASSIGNEE_LEVEL_ID` | Level-Design |
| `LINEAR_ASSIGNEE_QA_ID` | QA-Testing |
| `LINEAR_ASSIGNEE_ART_ID` | Art-Visual / Audio Music |
| `LINEAR_DEFAULT_ASSIGNEE_ID` | Fallback if a role env is empty |

**How to get a user ID:** Linear → Workspace or team members → open a profile; the GraphQL `User` id is easiest via **Linear API** or Settings → **API** examples. Quick path: create a one-off API query in the Linear API explorer, or use `linear` CLI if installed.

## Caps and phased intake (250 active issue ceiling)

Linear enforces a **maximum number of open/active issues** on many plans (often cited as 250). This repo treats “active” as issues whose state type is **not** `completed` or `canceled`.

| Variable | Default | Meaning |
|----------|---------|---------|
| `LINEAR_ACTIVE_ISSUE_CAP` | `230` | Stop creating/promoting when this many non-terminal issues exist (buffer under 250) |
| `LINEAR_SEED_BATCH_MAX` | `40` | Max **new** issues per `linear:seed` run |
| `LINEAR_PROMOTE_BATCH_MAX` | `25` | Max issues moved **Backlog → Todo** per `linear:promote` run |
| `LINEAR_MAX_IN_PROGRESS` | `3` | Max issues in **In Progress** before `linear:dispatch` stops moving **Todo → In Progress** (implementation WIP) |
| `LINEAR_DISPATCH_ROLES` | (see below) | Comma-separated roles auto-dispatched. Default: `gameplay-programmer,ui-developer,level-designer,art-pipeline` (**excludes** `producer` and `qa-agent`; use `linear:resume-pickup` for those) |

Default dispatch roles match ~3 implementation lanes; raise `LINEAR_MAX_IN_PROGRESS` to `4` if you routinely run four dev lanes.

## Optional

| Variable | Meaning |
|----------|---------|
| `LINEAR_WORKSPACE_ID` | Workspace/org UUID — rarely needed for our scripts; reserve for future org-level API |
| `GITHUB_TOKEN` | For GitHub MCP / future PR automation (repo `contents` + `pull_requests` if auto-merge) |
| `CURSOR_CLI_BIN` | Full path to **`cursor`** if not on PATH (editor wrapper; folder open + fallback terminal agent) |
| `CURSOR_AGENT_CLI_BIN` | Full path to **`cursor-agent`** if not on PATH (preferred terminal agent for lane / merge scripts) |
| `CURSOR_CLI_AGENT_SUBCOMMAND` | When **`cursor-agent`** is missing, scripts run **`cursor <subcommand> <prompt>`** — default subcommand is **`agent`** |
| `CURSOR_AGENT_BIN` | Legacy **`agent`** shim path if `cursor` is unavailable (`Get-CursorCliExecutable` only) |
| `LINEAR_PM_AUTO_ASSIGN` | If `false`, `linear:pm-organize -- --apply` skips setting assignees (priorities still update unless `--assign-only`) |
| `LINEAR_FALLBACK_ASSIGNEE_TO_VIEWER` | Default `true`. If role/default assignee IDs are missing, assign to the API-key user for `linear:dispatch`, `linear:resume-pickup`, and `linear:pm-organize` |
| `LINEAR_PM_LABEL_BACKFILL_STATE_IDS` | Optional comma-separated extra state IDs for `linear:label-backfill` scan (Todo/Backlog/In Progress are included by default) |

## Setup helpers

- One-time merge of API key + generated IDs: `tools/tasks/init-linear-env.ps1`
- Full bootstrap + seed + preview: `tools/tasks/linear-full-setup.ps1`

## Security

If an API key was ever pasted into chat or committed, **revoke and rotate** it in Linear immediately.
