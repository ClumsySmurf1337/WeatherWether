# Cursor autonomous session (Linear + validate + parallel lanes)

**Install Cursor Agent CLI** (terminal): [Cursor CLI installation](https://cursor.com/docs/cli/installation) — Windows: `irm 'https://cursor.com/install?win32=true' | iex`. See **`docs/CURSOR_CLI_AND_WORKTREES.md`**.

Dry-run producer + validate + print lane commands:

```powershell
npm run cursor:session
```

Full local PM apply + worktrees + **spawn `cursor chat` per lane** (no IDE paste):

```powershell
npm run cursor:session:apply -- -CreateWorktrees -SyncWorktrees -SpawnAgentCli
```

After a PR exists and GitHub CI is green, **local QA** merge + Linear Done:

```powershell
npm run qa:pr -- -PullRequestNumber 12
```

Sync all `wt-*` worktrees with `main`:

```powershell
npm run worktrees:sync
```

One-command kickoff (PM prepare + dependency edges + Todo feed + lane kickoff + session launch):

```powershell
npm run cursor:go
```

**Same kickoff, but lane shells inside Cursor (integrated terminals via Tasks — no external `pwsh` popups):**

```powershell
npm run cursor:go:editor
```

Then: **Ctrl+Shift+P** → **Tasks: Run Task** → **Weather Whether — All lane terminals (parallel)**.  
Each task runs `linear:resume-pickup` from the **main repo** (`.env.local`), `cd`s into the worktree, then runs **`cursor chat`** with the lane prompt automatically (no typing in the terminal). If three parallel chats conflict in one Cursor window, run **Lane 1 / 2 / 3** tasks separately.

Resume after shutdown/interruption (rebuild handoffs + relaunch resume-first lanes):

```powershell
npm run cursor:resume
```

Prep only (no session launch):

```powershell
npm run cursor:go -- -SkipSessionLaunch
```
