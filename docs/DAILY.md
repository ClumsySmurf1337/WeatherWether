# DAILY — autonomous lane, PM (Linear), and parallel agents

This doc is the **single operator contract**: what runs once a day, how **PM** uses **Linear**, and how **agents** work **in parallel**.

## How the pieces fit together

```text
┌─────────────────────────────────────────────────────────────────┐
│  DAILY FULL (you or Task Scheduler)                              │
│  validate repo + tooling + (optional) Linear PM preview/apply      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  LINEAR = PM system of record                                      │
│  Producer: standup → promote (Backlog→Todo) → dispatch (Todo→     │
│  In Progress + assignee). Issues list what “done” means.          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  PARALLEL BUILD (local by default)                               │
│  One Cursor window per lane = git worktree + `linear:resume-pickup`│
│  Cursor Cloud is optional; not self-hosted.                      │
└─────────────────────────────────────────────────────────────────┘
```

1. **DAILY** does **not** replace humans entirely: it **aligns** health checks and surfaces **what** Linear says is ready.  
2. **PM in Linear** (producer automation + your judgment) **moves** issues and **assigns** work so the board matches capacity.  
3. **Agents** (you + AI in Cursor) **build in parallel** by using **separate folders** (worktrees) and **non-overlapping scopes** — each lane runs `linear:resume-pickup -- --role=... --apply` so shutdowns resume existing **In Progress** work before claiming new Todo.

Full policy: [AUTONOMOUS_ORCHESTRATION.md](AUTONOMOUS_ORCHESTRATION.md), scopes: [CURSOR_PARALLEL_AGENTS.md](CURSOR_PARALLEL_AGENTS.md).

---

## Cheat sheet — validate, play, lanes (most days)

| Goal | Command |
|------|---------|
| **Tests + level validation** (local “did the project build?”) | `pwsh ./tools/tasks/validate.ps1` |
| **Godot import + build scaffold** (export presets still in Godot UI) | `pwsh ./tools/tasks/build.ps1` |
| **Run the game** | `pwsh ./tools/tasks/launch.ps1` |
| **Full health pass** (npm ci + Linear PM dry-run + validate + **lane prep** when run from Cursor’s terminal) | `npm run daily:full` |
| **Simplest daily + parallel agents (one Task)** | **Tasks → Run Task →** **Weather Whether — Daily apply:lanes, then parallel lane agents** (`daily:full:apply:lanes`, then three lanes). Lane task terminals use **`presentation.close`** so each **closes when that lane finishes** (success or failure — re-run a single lane Task to debug). |
| **Daily apply + lane prep only** (no agents yet) | **Tasks →** **Weather Whether — Daily full (apply + lane prep)** — same as `npm run daily:full:apply:lanes` |
| **Resume lanes — terminals inside this Cursor window** (neatest) | `npm run cursor:resume:editor` → then **Tasks: Run Task** → **Weather Whether — All lane terminals (parallel)** |
| **Resume lanes — one external PowerShell window per lane** | `npm run cursor:resume` |
| **Full PM kickoff — editor terminals** | `npm run cursor:go:editor` → same **All lane terminals** task |
| **Full PM kickoff — external pwsh** | `npm run cursor:go` |

**`cursor:open-lanes` after `cursor:resume`?** It does **not** break Linear or undo resume-pickup. It only opens **extra Cursor IDE windows** (one folder per worktree). Skip it if you already use **integrated Tasks** in one window; use it when you want **separate Cursor windows** per lane instead.

### Typical loop (lanes in Cursor)

**Recommended (three steps in Cursor):**

1. **Tasks → Run Task →** **Weather Whether — Daily apply:lanes, then parallel lane agents** — runs **`npm run daily:full:apply:lanes`**, then **three lane terminals in parallel**. Each lane terminal **auto-closes when that lane’s script exits** (see `.vscode/tasks.json` **`presentation.close`**).
2. **Tasks → Run Task →** **Weather Whether — QA agent (lane PRs)** (or `npm run qa:agent` in the terminal) when you are ready to merge — waits on GitHub checks unless you use **`npm run qa:lane-prs:quick`**. This merges lane PRs, moves Linear to Done, **`worktrees:sync`**, resets lane branches, and prints what to run next.
3. Repeat **step 1** (and **step 2** when you have PRs to land) for the next cycle.

**Equivalent commands** (if you prefer typing): **`npm run daily:full:apply:lanes`**, then **Tasks →** **All lane terminals (parallel)**, then **`npm run qa:agent`**.

`daily:full:apply:lanes` does **not** start the agents by itself unless you use the **compound Task** above; by itself it runs validate, optional Linear producer, worktree prep, and prints the Tasks hint.

### Lane ship → QA batch → next cycle

1. **Implementation** (Tasks / `cursor-agent`): each lane Task runs **`run-lane-terminal.ps1`**, which runs **`linear:resume-pickup`** with **`--worktree-marker`** (writes **`.weather-lane-issue.txt`** in the worktree), then **`cursor-agent`**. When the agent exits, if there are **uncommitted changes *or* unpushed commits**, the launcher **auto-runs `lane-ship`** (validate, commit if needed, push, **`gh pr create`** if there is no open PR) — **no `-LinearId`** needed. **Stuck (finished work, no PR)?** Often the agent **committed locally but did not push**; that is fixed now. If something still did not ship, from main repo run **`npm run lane:ship:lanes`** (lanes 1–3) or **`npm run lane:ship -- -LaneIndex N`**. Pass **`-LinearId WEA-###`** only if **`.weather-lane-issue.txt`** is missing.
2. Run **`npm run qa:agent`** from the main repo (visible in terminal; VS Code: **Tasks → Weather Whether — QA agent (lane PRs)**). It first **scans lanes 1–3** for **uncommitted or unpushed** work and runs **`lane-ship`** so missing PRs get opened, then for each open PR whose head is **`agent/cursor-lane-*`**: wait on GitHub checks (use **`npm run qa:lane-prs:quick`** to skip that wait), verify **`LINEAR_TEAM_KEY`-###** in PR text, merge **`origin/main`** into the PR (conflicts → repair), **`validate.ps1`**, **`gh pr merge`**, **`linear:complete-from-pr`** (Done), append **`docs/CHANGELOG_LANES.md`**, then **`worktrees:sync`** and **lane branch reset** (use **`npm run qa:agent -- -SkipResetLaneBranches`** to skip reset). To **only** merge existing PRs without a ship pre-pass: **`npm run qa:agent -- -SkipPreflightShip`**.
3. **Lane reset** is **on by default** after **`qa:agent`**. If you skipped it: **`npm run lane:next-cycle`**.
4. **`npm run daily:full:apply:lanes`** or the **Daily apply:lanes, then parallel lane agents** Task for the next batch — **`qa:agent`** prints this at the end.

---

## One command — run almost everything

From repo root (PowerShell):

```powershell
pwsh ./tools/tasks/daily-full.ps1
```

**Cursor session** (producer preview or apply + local validate + printed parallel-lane / optional worktrees):

```powershell
npm run cursor:session
npm run cursor:session:apply -- -CreateWorktrees
```

See `.cursor/commands/cursor-session.md`, `docs/CURSOR_CLI_AND_WORKTREES.md`, and `docs/GITHUB_AUTOMERGE.md` (local **`npm run qa:pr`** after CI green).

**`daily-full.ps1`** runs:

- Prerequisites, D-drive check (lenient unless you pass **`-StrictDdrive`**), **`npm ci`**, Linear **status** + producer **dry-run** (if `.env.local` exists), **Godot import + GUT + level validation**.
- **When run from a Cursor or VS Code integrated terminal** (or with **`-EditorLaneTerminals`**): **`linear:pm-assignments`**, **`worktrees:sync`**, **`prepare-editor-lane-worktrees.ps1`**, then prints **Tasks → Weather Whether — All lane terminals** so parallel lanes stay **inside this editor**. Use **`-SkipEditorLanePrep`** for Task Scheduler / headless runs that should not touch worktrees (`npm run daily:full:lean`).

**Apply** PM moves in Linear (promote + dispatch) when you are happy with the dry-run:

```powershell
pwsh ./tools/tasks/daily-full.ps1 -ApplyProducer
npm run daily:full:apply
```

npm aliases:

```bash
npm run daily:full
npm run daily:full:apply
npm run daily:full:lanes          # force lane prep even outside Cursor terminal
npm run daily:full:lean           # validate-only tail; no lane prep
npm run daily:full:apply:lanes    # apply producer + lane prep
```

**Cursor / VS Code Tasks** (`.vscode/tasks.json`): **Weather Whether — Daily full (apply + lane prep)**, **Weather Whether — All lane terminals (parallel)**, **Weather Whether — Daily apply:lanes, then parallel lane agents** (daily then lanes), **Weather Whether — QA agent (lane PRs)**.

---

## Lighter lane (no `npm ci` every time)

```powershell
pwsh ./tools/tasks/daily-autonomous.ps1
```

Then, when ready:

```powershell
npm run linear:producer -- --apply
```

---

## First-time setup (once per machine / repo)

Do these **before** relying on DAILY + Linear automation:

| Step | Command / action |
|------|-------------------|
| 1. Bootstrap Win + D paths | `pwsh ./tools/install/bootstrap-win11.ps1` |
| 2. Node 22+ | See [SETUP_WIN11.md](SETUP_WIN11.md) |
| 3. `npm ci` | In repo root |
| 4. Linear API + generated IDs | `npm run linear:bootstrap -- --apply` then `pwsh ./tools/tasks/init-linear-env.ps1` |
| 5. Optional: full Linear seed | `pwsh ./tools/tasks/linear-full-setup.ps1` or `npm run linear:seed` |
| 6. Optional: **godot-full** MCP | `pwsh ./tools/install/setup-godot-mcp-full.ps1` |
| 7. Git: at least one commit on **main** | Required for `new-agent-worktree.ps1` |

---

## Parallel agents (after PM has Todo / In Progress work)

**1. Create a second checkout** (per lane — use a **new** branch name each time):

```powershell
pwsh ./tools/tasks/new-agent-worktree.ps1 -BranchName agent/test-lane
```

- Auto-detects **main** / **master** / `origin/HEAD` if you omit `-BaseBranch`.  
- Needs a **real git history** (initial commit + remote optional). If you see “No commits yet”, commit and push first.

**2. Open** `D:\Agents\WeatherWether\wt-agent-test-lane` (or your `WHETHER_AGENT_ROOT`) **in another Cursor window**.

**3. In each window**, claim **one** issue for that lane’s role:

```powershell
npm run linear:resume-pickup -- --role=gameplay-programmer --apply
```

Roles: `producer`, `gameplay-programmer`, `ui-developer`, `level-designer`, `qa-agent`, `art-pipeline`.

That is how **multiple agents build in parallel** without stomping the same tree: **different worktrees**, **different branches**, **different Linear issues**, **scoped directories** in [CURSOR_PARALLEL_AGENTS.md](CURSOR_PARALLEL_AGENTS.md).

---

## Other one-off tasks (audit / ops)

| Task | Command |
|------|---------|
| Full workspace audit (prereqs + optional Linear + seed dry-run) | `pwsh ./tools/tasks/validate-workspace.ps1` |
| Godot tests + levels only | `pwsh ./tools/tasks/validate.ps1` (add **`-GodotProjectPath <worktree>`** to validate a lane checkout) |
| Linear snapshot | `npm run linear:status` |
| PM phase order + auto-assign preview/apply | `npm run linear:pm-organize` / `npm run linear:pm-organize -- --apply` |
| PM label generation + backfill | `npm run linear:label-backfill -- --apply` |
| PM assignment markdown (per role) | `npm run linear:pm-assignments` → `assignments/generated/` |
| PM fill Todo from Backlog by phase order | `npm run linear:pm-feed-todo -- --apply` (`--target=<N>` optional) |
| PM dependency + file-scope plan | `npm run linear:plan-deps` → `assignments/generated/dependency-scope-plan.md` |
| Apply dependency edges in Linear (blocks relations) | `npm run linear:apply-deps` (dry-run) / `npm run linear:apply-deps -- --apply` |
| Kick off first build issue by role | `npm run linear:kickoff-first -- --role=gameplay-programmer --apply` |
| Kick off default 3 lanes (gameplay/ui/level) | `npm run linear:kickoff-lanes -- --apply` |
| One command kickoff (prepare+deps+todo+lanes+session) | `npm run cursor:go` (add `-- -SkipSessionLaunch` to prep only) |
| Resume after interruption/shutdown (integrated terminals — recommended) | `npm run cursor:resume:editor` → **Tasks → All lane terminals** |
| Resume after interruption (external PowerShell per lane) | `npm run cursor:resume` |
| Open each lane worktree in a **new Cursor window** (optional; additive) | `npm run cursor:open-lanes` |
| PM all-in-one prep (bootstrap + labels + organize + assignments) | `npm run linear:pm-prepare` |
| Promote backlog only | `npm run linear:promote -- --apply` |
| Dispatch only | `npm run linear:dispatch -- --apply` |
| Merge conflicts → Cursor QA prompt | `npm run qa:repair-merge` (see `.cursor/commands/qa-repair-merge.md`) |
| PR merge + Linear Done (local) | `npm run qa:pr -- -PullRequestNumber <N>` |
| Ship one lane worktree (commit + push + PR) | `npm run lane:ship -- -LaneIndex <1-3>` (optional **`-LinearId`**; else **`.weather-lane-issue.txt`**) |
| Ship **all** default lanes (1–3) — recovery when work exists but no PR | `npm run lane:ship:lanes` |
| QA merge **all** open lane PRs + Linear Done + sync + changelog + lane reset | `npm run qa:agent` (**`-SkipResetLaneBranches`** to skip branch reset) |
| QA lane PRs, CI already green | `npm run qa:lane-prs:quick` |
| Reset lane worktrees to fresh `agent/cursor-lane-*` from main | `npm run lane:next-cycle` |
| Sync all agent worktrees with `main` | `npm run worktrees:sync` |
| Play game | `pwsh ./tools/tasks/launch.ps1` |
| Mobile preview posture | `pwsh ./tools/tasks/mobile-preview.ps1` |

---

## Phased backlog (Linear ~250 cap)

- Seed: `npm run linear:seed` (dedupe + batch caps).  
- Promote: `npm run linear:promote -- --apply`.  
- Details: [LINEAR_SETUP.md](LINEAR_SETUP.md), [LINEAR_ENV_VARS.md](LINEAR_ENV_VARS.md).

---

## Design spine (PM + agents)

All work should stay aligned with **`docs/GAME_DESIGN.md` v2** (authoritative GDD). See `.cursor/rules/weather-game.mdc`. Legacy toolkit context: `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md`.

---

## Security

Never commit `.env.local`. Rotate leaked Linear keys.
