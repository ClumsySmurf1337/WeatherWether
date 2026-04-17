# PM agent + Linear (Weather Whether)

This repo combines **scripted** Linear operations with **agent** behavior modeled on the DeedWise PM pattern (`docs/Examples/DeedWise — Project Manager Agent.md`): phase ordering, role routing, and **assignment markdown** per lane.

## Source of truth

- **GDD (authoritative):** `docs/GAME_DESIGN.md` v2 — `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md` is legacy toolkit / study context only.
- **Phase → priority mapping:** `docs/backlog/pm-phase-plan.json` (edit labels/title prefixes to match your board)
- **Role from labels/title:** `tools/linear/role-map.ts` (`[CORE]` / `[MECH]` → gameplay programmer, etc.)
- **Parallel lane scopes (Cursor + Copilot):** `docs/CURSOR_PARALLEL_AGENTS.md` — gameplay lane includes `scripts/core` (e.g. `game_manager.gd`), `scripts/grid`, `scripts/weather`, `scripts/puzzle`, and gameplay-owned tests under `test/`. Keep aligned with `.github/copilot-instructions.md` and `.claude/CLAUDE.md` so Linear-assigned work matches what agents are allowed to touch.

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
| `npm run linear:pm-doc-intake` | **Dry-run:** draft **detailed** PM issues from **GDD / UI_SCREENS / ASSET_MANIFEST / SPEC_DIFF** (excerpts + acceptance) → **`assignments/generated/pm-doc-intake-dry-run.md`**. No Linear API. |
| `npm run linear:pm-doc-intake -- --apply` | Create **missing** issues in **Backlog** (dedupe by title). Optional `--max=12`. Requires `.env.local` + **`LINEAR_STATE_BACKLOG_ID`**. |
| `npm run linear:plan-deps` | Generate `assignments/generated/dependency-scope-plan.md` with suggested dependencies and role file scopes to reduce overlap. |
| `npm run linear:apply-deps` | Dry-run/apply real Linear **blocks** relations; writes `assignments/generated/dependency-relations-plan.md`. |
| `npm run linear:kickoff-first -- --role=gameplay-programmer --apply` | Promote/claim the first role-matching issue (Todo first, else Backlog) into **In Progress** for build testing. |
| `npm run linear:kickoff-lanes -- --apply` | Kick off one issue per default build lane (**gameplay/ui/level**) from Todo or Backlog into **In Progress**. |
| `npm run linear:pm-prepare` | One command: bootstrap labels/projects/states + role-label backfill + PM organize apply + assignment file generation. |
| `npm run linear:pm-handoff` | **Doc-driven + board preview + assignments:** `pm-doc-intake` (writes `assignments/generated/pm-doc-intake-dry-run.md` from GDD/UI/ASSET/SPEC_DIFF/BLUEPRINT candidates) → **`pm-organize`** (dry-run) → **`pm-assignments`**. Requires `.env.local` for organize + assignments. |
| `npm run linear:pm-handoff:apply` | Same chain with **`--apply`** on doc-intake and organize (creates missing Backlog issues; updates priorities/assignees), then regenerates assignment markdown. |

**Auto-assign toggle:** `LINEAR_PM_AUTO_ASSIGN=false` disables assignee updates (priorities still apply unless `--assign-only`).

**Assignee IDs:** `LINEAR_ASSIGNEE_GAMEPLAY_ID`, `LINEAR_ASSIGNEE_UI_ID`, … or `LINEAR_DEFAULT_ASSIGNEE_ID` — see `docs/LINEAR_ENV_VARS.md`.
If those are unset, scripts fall back to the API-key user by default (`LINEAR_FALLBACK_ASSIGNEE_TO_VIEWER=true`).

## Simple / daily flows vs PM handoff

- **`npm run workflow:simple`** / **`npm run daily:full:apply:lanes`** (Tasks: *Daily apply:lanes*) run **`linear:producer -- --apply`** (when using apply variants), **`validate.ps1`**, then **`linear:pm-assignments`** + **`worktrees:sync`** + lane worktree prep — **they do not** run **`linear:pm-organize`** or **`linear:pm-doc-intake`**. Use **`npm run linear:pm-handoff`** (or **`linear:pm-prepare`** for full bootstrap) when you want board phase/priority alignment and fresh doc-grounded drafts before lanes pick up work.

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
- **Create** issues from scratch: use **`npm run linear:pm-doc-intake -- --apply`** (doc-grounded drafts), **`linear:seed`**, or templates; the human/LLM PM can still add ad-hoc tickets in Linear.

Tune **`pm-phase-plan.json`** so “build first” matches your label taxonomy; re-run organize + assignments.
