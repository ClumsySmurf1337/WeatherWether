# Autonomous orchestration: what is real vs roadmap

## Cursor Cloud agents

- **Hosting:** Cursor Cloud agents run on **Cursor-managed infrastructure**, not on your Windows PC. There is **no supported “self-hosted Cursor Cloud”** mode to reduce spend; local work uses **Cursor IDE agents** (your machine) instead.
- **Cost control:** Prefer **local parallel agents / worktrees** for bulk edits, and reserve Cloud for long-running branches you are OK paying for.
- **Parallel agents:** Cursor allows multiple agents (up to workspace limits). See [CURSOR_PARALLEL_AGENTS.md](CURSOR_PARALLEL_AGENTS.md).

## Copilot + GPT / Gemini fallback

When Cloud is unavailable or throttled:

1. **Cursor IDE:** Chat + Composer with your logged-in models.
2. **GitHub Copilot Chat** in VS Code / Cursor: implementation + review.
3. **Claude Code / Codex / other CLIs** in separate terminals with **git worktrees** (same task boundaries as agents in `.claude/agents/`).

Keep a single source of truth: **Linear issue → branch name → file scope** from [AGENT_CATALOG.md](AGENT_CATALOG.md).

## Windows “orchestrator”

There is no official Conductor.app for Windows today. Practical replacements:

- **Terminal multiplexer:** Windows Terminal tabs + `pwsh` scripts in `tools/tasks/`.
- **Git worktrees:** one folder per agent, merge via PR.
- **Scheduled Task:** run `daily-autonomous.ps1` on a schedule.

## Fully autonomous PR merge (roadmap)

True **auto-merge on green** requires:

- Branch protection with **required checks** passing.
- GitHub **auto-merge** or a carefully scoped workflow using `GITHUB_TOKEN` / bot PAT.

See [GITHUB_AUTOMERGE.md](GITHUB_AUTOMERGE.md). The repo does **not** enable silent merge-by-default (safety); use an `automerge` label + green CI when you intentionally want hands-off merges.

## QA and bugs on each PR

Target workflow:

1. Author opens PR referencing Linear issue id in title/body.
2. CI runs `npm ci` and basic tooling checks; **Godot headless tests are not in CI yet** (see `docs/BLUEPRINT_GAP_AUDIT.md`).
3. Human or **QA agent** runs `tools/tasks/validate.ps1` locally for gameplay changes (levels + GUT when installed).
4. Optional: add **automerge** label after review.

## Linear PM automation (this repo)

Scripts implement a **Phased PM loop**:

| Step | Script |
|------|--------|
| Standup | `npm run linear:standup` |
| Promote queue | `npm run linear:promote -- --apply` |
| Auto-assign + start | `npm run linear:dispatch -- --apply` |
| Combined | `npm run linear:producer -- --apply` |

Dispatch **skips Linear onboarding issues** (“Get familiar…”, etc.).

## Key loading

Use `.env.local` + `tools/tasks/init-linear-env.ps1` so keys never appear on the command line. See [LINEAR_ENV_VARS.md](LINEAR_ENV_VARS.md).
