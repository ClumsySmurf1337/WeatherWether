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

**Apply** PM moves in Linear (promote + dispatch) when you are happy with the dry-run:

```powershell
pwsh ./tools/tasks/daily-full.ps1 -ApplyProducer
```

npm alias (Windows):

```bash
npm run daily:full
```

(`package.json` maps this to the same script.)

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
| Godot tests + levels only | `pwsh ./tools/tasks/validate.ps1` |
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
| Resume after interruption/shutdown | `npm run cursor:resume` |
| PM all-in-one prep (bootstrap + labels + organize + assignments) | `npm run linear:pm-prepare` |
| Promote backlog only | `npm run linear:promote -- --apply` |
| Dispatch only | `npm run linear:dispatch -- --apply` |
| Merge conflicts → Cursor QA prompt | `npm run qa:repair-merge` (see `.cursor/commands/qa-repair-merge.md`) |
| PR merge + Linear Done (local) | `npm run qa:pr -- -PullRequestNumber <N>` |
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

All work should stay aligned with **Building Weather Whether** (grid, weather **cards**, six weathers, fog layer). See `.cursor/rules/weather-game.mdc` and `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md`.

---

## Security

Never commit `.env.local`. Rotate leaked Linear keys.
