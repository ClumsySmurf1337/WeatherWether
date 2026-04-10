# Cursor CLI + git worktrees (parallel agents)

## How this fits Weather Whether

- **Git worktrees** give each agent an isolated checkout (shared object DB). That matches Cursor’s parallel-agent model and the classic workflow described for Cursor + worktrees ([DEV: Git worktrees and parallel agents](https://dev.to/arifszn/git-worktrees-the-power-behind-cursors-parallel-agents-19j1)).
- **This repo adds:** Linear **producer/dispatch/resume-pickup**, WIP caps, **`validate.ps1`**, and a **local QA handoff** script — complementary to worktrees, not a replacement.
- **DEV article vs our scripts:** The article explains *why* worktrees; our **`new-agent-worktree.ps1`**, **`sync-agent-worktrees.ps1`**, and **`cursor-autonomous-session.ps1`** automate *your* paths and lanes. Use both.

## Cursor Agent CLI (terminal, no paste into the IDE chat)

Official install (see [Cursor CLI installation](https://cursor.com/docs/cli/installation)):

- **macOS / Linux / WSL:** `curl https://cursor.com/install -fsS | bash`
- **Windows (native PowerShell):** `irm 'https://cursor.com/install?win32=true' | iex`

Ensure **`cursor-agent`** is on `PATH` for lane automation (or set **`CURSOR_AGENT_CLI_BIN`**). For opening the editor from the CLI, ensure **`cursor`** is on `PATH`, or set **`CURSOR_CLI_BIN`**. If you still use the legacy shim, **`CURSOR_AGENT_BIN`** / `agent` is used as a fallback for **`Get-CursorCliExecutable`** only.

Then one command can open **multiple** terminals that each run **`cursor-agent "<prompt>"`** (via **`tools/tasks/run-cursor-chat.ps1`**) with a generated prompt — see **`npm run cursor:session:apply -- -SpawnAgentCli`**. Scripts **prefer `cursor-agent`** on `PATH` (or **`CURSOR_AGENT_CLI_BIN`**). If it is missing, they fall back to **`cursor agent "<prompt>"`** (override subcommand with **`CURSOR_CLI_AGENT_SUBCOMMAND`**). **`chat`** is not a `cursor` subcommand (passing `chat` behaves like stray path args).

Prefer fixing **`PATH`** / **`CURSOR_AGENT_CLI_BIN`** so **`cursor-agent`** resolves. If you only have the editor wrapper, set **`CURSOR_CLI_AGENT_SUBCOMMAND`** for the fallback `cursor <subcommand>` line in **`tools/tasks/cursor-cli.ps1`** / **`run-cursor-chat.ps1`**.

## Merge conflicts → QA Cursor session

```powershell
npm run qa:repair-merge -- -RepoPath "D:\Agents\WeatherWether\wt-agent-cursor-lane-1"
```

Or `cd` into the worktree and run **`npm run qa:repair-merge`**. This runs **`git merge origin/main`** and, on conflict, launches **`cursor-agent`** (or **`cursor agent`** fallback) with **`tools/tasks/prompts/qa-merge-conflict-repair.md`**.

## One- or two-command local flow

1. **Start lanes (PM + optional agent spawn):**  
   `npm run cursor:session:apply -- -CreateWorktrees -SpawnAgentCli`  
   Optional: **`-SyncWorktrees`** before resume/pickup to merge **`origin/main`** into each lane.

Recovery after interruption/shutdown:

- `npm run cursor:resume` (refresh PM assignments, sync worktrees, relaunch lanes; each lane runs `linear:resume-pickup` so In Progress work is continued first).

2. **After a PR exists and GitHub CI is green:** local QA (or you) runs:  
   `npm run qa:pr -- -PullRequestNumber <N>`  
   That waits on checks, checks out the PR, runs **`validate.ps1`**, merges with **`gh`**, then runs **`linear:complete-from-pr`** using **your local** Linear API key — **no** GitHub Action closes the issue.

Requires **GitHub CLI** `gh` authenticated for the repo.

## Worktree isolation in Cursor

When using the Cursor app, open each **worktree folder** as its own workspace (or use Cursor’s worktree workflow when available) so each agent’s index matches its directory — same idea as the DEV article.
