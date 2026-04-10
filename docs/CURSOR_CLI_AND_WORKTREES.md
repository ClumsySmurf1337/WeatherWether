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

Then one command can open **multiple** terminals that each run **`cursor-agent "<prompt>"`** (via **`tools/tasks/run-cursor-chat.ps1`**) with a generated prompt — see **`npm run cursor:session:apply -- -SpawnAgentCli`**. Scripts **prefer `cursor-agent`** on `PATH` (or **`CURSOR_AGENT_CLI_BIN`**). They **prepend `--trust` by default** so lane terminals are not blocked by the Workspace Trust prompt (override with **`CURSOR_AGENT_TRUST_ARGS`**, or opt out with **`CURSOR_AGENT_NO_TRUST=1`** / **`CURSOR_AGENT_INTERACTIVE=1`**). If **`cursor-agent`** is missing, they fall back to **`cursor agent "<prompt>"`** (override subcommand with **`CURSOR_CLI_AGENT_SUBCOMMAND`**; optional trust flags via **`CURSOR_CLI_AGENT_TRUST_ARGS`**). **`chat`** is not a `cursor` subcommand (passing `chat` behaves like stray path args).

Prefer fixing **`PATH`** / **`CURSOR_AGENT_CLI_BIN`** so **`cursor-agent`** resolves. If you only have the editor wrapper, set **`CURSOR_CLI_AGENT_SUBCOMMAND`** for the fallback `cursor <subcommand>` line in **`tools/tasks/cursor-cli.ps1`** / **`run-cursor-chat.ps1`**.

### Terminal agent model (limits, fallbacks, Godot / GDScript)

Lane and merge scripts invoke **`cursor-agent`** via **`Invoke-CursorTerminalAgent`** in **`tools/tasks/cursor-cli.ps1`**. They pass an ordered **model chain**: try the first slug, and if the process exits non-zero **and** the combined output looks like a **usage cap**, **rate limit**, **unknown model**, or **`not available for your account`**, they automatically try the next slug.

**Defaults (when you do not set env vars):** primary **`CURSOR_AGENT_MODEL`** (default **`claude-4.6-sonnet-medium`**), then built-in fallbacks **`gpt-5.2`**, **`composer-2`** — both are usually cheaper tiers on **Cursor Pro** than **Claude 4.6 Opus**. Slugs must exist for your account; run **`cursor-agent --help`** or check Cursor’s model list and override if a step fails with “unknown model” without a retry.

**Configure the chain (PowerShell, before Tasks / lane scripts):**

```powershell
# Full order (overrides primary + fallbacks):
$env:CURSOR_AGENT_MODELS = "claude-4.6-sonnet-medium;gpt-5.2;composer-2"

# Or primary + extra fallbacks only (defaults still append gpt + composer if FALLBACKS unset — set FALLBACKS to control):
$env:CURSOR_AGENT_MODEL = "claude-4.6-sonnet-medium"
$env:CURSOR_AGENT_MODEL_FALLBACKS = "gpt-5.2-low,gpt-5.2,composer-2-fast"

# Disable auto-fallback (old single-model behavior):
$env:CURSOR_AGENT_MODEL_DISABLE_FALLBACK = "1"
```

See **`docs/LINEAR_ENV_VARS.md`** for the variable table.

### GitHub Copilot — not inside `cursor-agent`, but parallel lane script

**`cursor-agent`** only uses **Cursor’s** router. Copilot does **not** plug into **`--model`** unless Cursor lists a Copilot-backed slug (then add it to **`CURSOR_AGENT_MODELS`**).

For **full lane parity** when Cursor usage is exhausted, this repo runs **`tools/tasks/run-lane-copilot-terminal.ps1`**: same **resume-pickup** + **`WEATHER_COPILOT_LANE_PROMPT.md`** + **`lane-ship`**, using **`copilot -p … --no-ask-user`** ([blog](https://github.blog/ai-and-ml/github-copilot/run-multiple-agents-at-once-with-fleet-in-copilot-cli/)). See **`docs/COPILOT_LANES.md`**. Optional **`WEATHER_COPILOT_USE_FLEET`** enables **`/fleet`** inside a single worktree ([docs](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/fleet)).

**Practical split:** **model chaining** for Cursor lanes; **Copilot CLI Tasks** or **`npm run workflow:simple:copilot`** when you want GitHub’s agent in the terminal from the same IDE.

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

- **`npm run cursor:resume:editor`** — refresh PM assignments, sync worktrees, ensure lane worktrees; then use **Tasks → Weather Whether — All lane terminals** so **`cursor-agent`** runs in **integrated** terminals (recommended).
- **`npm run cursor:resume`** — same prep, but spawns **one external PowerShell window per lane** (older flow).

2. **After a PR exists and GitHub CI is green:** local QA (or you) runs:  
   `npm run qa:pr -- -PullRequestNumber <N>`  
   That waits on checks, checks out the PR, runs **`validate.ps1`**, merges with **`gh`**, then runs **`linear:complete-from-pr`** using **your local** Linear API key — **no** GitHub Action closes the issue.

Requires **GitHub CLI** `gh` authenticated for the repo.

## Worktree isolation in Cursor

When using the Cursor app, open each **worktree folder** as its own workspace (or use Cursor’s worktree workflow when available) so each agent’s index matches its directory — same idea as the DEV article.
