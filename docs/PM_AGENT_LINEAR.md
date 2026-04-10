# PM agent + Linear (Weather Whether)

This repo combines **scripted** Linear operations with **agent** behavior modeled on the DeedWise PM pattern (`docs/Examples/DeedWise — Project Manager Agent.md`): phase ordering, role routing, and **assignment markdown** per lane.

## Source of truth

- **GDD spine:** `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md`
- **Phase → priority mapping:** `docs/backlog/pm-phase-plan.json` (edit labels/title prefixes to match your board)
- **Role from labels/title:** `tools/linear/role-map.ts` (`[CORE]` / `[MECH]` → gameplay programmer, etc.)

## Commands (run from repo root)

| Command | Purpose |
|---------|---------|
| `npm run linear:pm-organize` | Dry-run: for every issue in **Todo + Backlog**, compute **phase**, proposed **Linear priority**, and **role assignee** (if env ids set). |
| `npm run linear:pm-organize -- --apply` | Write **priority** + **assignee** (only when unassigned) to Linear. |
| `npm run linear:pm-organize -- --assign-only --apply` | Only fill **assignee** from role. |
| `npm run linear:pm-organize -- --priority-only --apply` | Only set **priority** from phase. |
| `npm run linear:pm-organize -- --todo-only` | Restrict to **Todo** (skip Backlog). |
| `npm run linear:label-backfill -- --apply` | Create missing role labels and add one inferred role label to unlabeled Backlog/Todo/In Progress issues. |
| `npm run linear:pm-assignments` | Regenerate **`assignments/generated/<role>.md`** (DeedWise-style handoffs; includes **Backlog**). |
| `npm run linear:plan-deps` | Generate `assignments/generated/dependency-scope-plan.md` with suggested dependencies and role file scopes to reduce overlap. |
| `npm run linear:apply-deps` | Dry-run/apply real Linear **blocks** relations; writes `assignments/generated/dependency-relations-plan.md`. |
| `npm run linear:kickoff-first -- --role=gameplay-programmer --apply` | Promote/claim the first role-matching issue (Todo first, else Backlog) into **In Progress** for build testing. |
| `npm run linear:kickoff-lanes -- --apply` | Kick off one issue per default build lane (**gameplay/ui/level**) from Todo or Backlog into **In Progress**. |
| `npm run linear:pm-prepare` | One command: bootstrap labels/projects/states + role-label backfill + PM organize apply + assignment file generation. |

**Auto-assign toggle:** `LINEAR_PM_AUTO_ASSIGN=false` disables assignee updates (priorities still apply unless `--assign-only`).

**Assignee IDs:** `LINEAR_ASSIGNEE_GAMEPLAY_ID`, `LINEAR_ASSIGNEE_UI_ID`, … or `LINEAR_DEFAULT_ASSIGNEE_ID` — see `docs/LINEAR_ENV_VARS.md`.
If those are unset, scripts fall back to the API-key user by default (`LINEAR_FALLBACK_ASSIGNEE_TO_VIEWER=true`).

## Agent workflow (producer)

1. Session start: `npm run linear:standup`, then `npm run linear:pm-organize` (preview).
2. Apply board hygiene: `npm run linear:pm-organize -- --apply` when priorities/assignees should match the phase plan.
3. Generate handoffs: `npm run linear:pm-assignments`; agents read **`assignments/generated/gameplay_programmer.md`** (etc.).
4. Execution lanes use **`linear:resume-pickup`** (resume first) / **`linear:dispatch`** / **`cursor:session`** per `docs/DAILY.md`.

If labels are missing or role inference is noisy, run **`npm run linear:pm-prepare`** first.

## How issues reach Todo

1. `linear:seed` creates into **Backlog** by default.
2. `linear:promote -- --apply` moves Backlog -> Todo (subject to `LINEAR_ACTIVE_ISSUE_CAP` headroom).
3. `linear:kickoff-first` / `linear:kickoff-lanes` can force-start from Backlog when Todo is empty (Backlog -> Todo -> In Progress).
4. Manual board moves in Linear are always valid.

## What this still does **not** do

- **Semantic/manual dependency curation** beyond heuristics: `linear:apply-deps` writes bulk `blocks` edges from title/phase patterns; you may still adjust critical paths manually in Linear.
- **Create** issues from scratch without `linear:seed` / templates — PM agent can drive MCP or web for ad-hoc tickets.

Tune **`pm-phase-plan.json`** so “build first” matches your label taxonomy; re-run organize + assignments.
