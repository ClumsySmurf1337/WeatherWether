# Cursor CLI + git worktrees (parallel agents)

## How this fits Whether

- **Git worktrees** give each agent an isolated checkout (shared object DB). That matches Cursor’s parallel-agent model and the classic workflow described for Cursor + worktrees ([DEV: Git worktrees and parallel agents](https://dev.to/arifszn/git-worktrees-the-power-behind-cursors-parallel-agents-19j1)).
- **This repo adds:** Linear **producer/dispatch/pickup**, WIP caps, **`validate.ps1`**, and a **local QA handoff** script — complementary to worktrees, not a replacement.
- **DEV article vs our scripts:** The article explains *why* worktrees; our **`new-agent-worktree.ps1`**, **`sync-agent-worktrees.ps1`**, and **`cursor-autonomous-session.ps1`** automate *your* paths and lanes. Use both.

## Cursor Agent CLI (terminal, no paste into the IDE chat)

Official install (see [Cursor CLI installation](https://cursor.com/docs/cli/installation)):

- **macOS / Linux / WSL:** `curl https://cursor.com/install -fsS | bash`
- **Windows (native PowerShell):** `irm 'https://cursor.com/install?win32=true' | iex`

Ensure **`cursor`** is on `PATH`, or set **`CURSOR_CLI_BIN`** to the full path of `cursor.exe`. If you still use the legacy shim, **`CURSOR_AGENT_BIN`** / `agent` is used as a fallback.

Then one command can open **multiple** terminals that each run **`cursor chat`** (via **`tools/tasks/run-cursor-chat.ps1`**) with a generated prompt — see **`npm run cursor:session:apply -- -SpawnAgentCli`**.

If your CLI uses different subcommands, run **`cursor --help`** and edit **`tools/tasks/run-cursor-chat.ps1`** (the `& $exe @("chat", $prompt)` line).

## Merge conflicts → QA Cursor session

```powershell
npm run qa:repair-merge -- -RepoPath "D:\Agents\WeatherWether\wt-agent-cursor-lane-1"
```

Or `cd` into the worktree and run **`npm run qa:repair-merge`**. This runs **`git merge origin/main`** and, on conflict, launches **`cursor chat`** with **`tools/tasks/prompts/qa-merge-conflict-repair.md`**.

## One- or two-command local flow

1. **Start lanes (PM + optional agent spawn):**  
   `npm run cursor:session:apply -- -CreateWorktrees -SpawnAgentCli`  
   Optional: **`-SyncWorktrees`** before pickup to merge **`origin/main`** into each lane.

2. **After a PR exists and GitHub CI is green:** local QA (or you) runs:  
   `npm run qa:pr -- -PullRequestNumber <N>`  
   That waits on checks, checks out the PR, runs **`validate.ps1`**, merges with **`gh`**, then runs **`linear:complete-from-pr`** using **your local** Linear API key — **no** GitHub Action closes the issue.

Requires **GitHub CLI** `gh` authenticated for the repo.

## Worktree isolation in Cursor

When using the Cursor app, open each **worktree folder** as its own workspace (or use Cursor’s worktree workflow when available) so each agent’s index matches its directory — same idea as the DEV article.
