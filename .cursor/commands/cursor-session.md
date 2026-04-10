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

Resume after shutdown/interruption (rebuild handoffs + relaunch resume-first lanes):

```powershell
npm run cursor:resume
```

Prep only (no session launch):

```powershell
npm run cursor:go -- -SkipSessionLaunch
```
