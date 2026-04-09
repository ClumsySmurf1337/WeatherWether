# QA: repair merge conflicts with Cursor CLI

From the **conflicted** repo or worktree directory:

```powershell
npm run qa:repair-merge
```

Or specify path:

```powershell
npm run qa:repair-merge -- -RepoPath "D:\Agents\WeatherWether\wt-agent-cursor-lane-1"
```

Dry-run (no Cursor window — exit 1 if conflicts):

```powershell
npm run qa:repair-merge -- -RepoPath "D:\path\to\repo" -NoLaunch
```

Requires **`cursor`** on PATH or **`CURSOR_CLI_BIN`**. Merges **`origin/main`** by default (`-BaseRef` to override).

After resolving, commit, push, then continue with **`npm run qa:pr -- -PullRequestNumber <N>`**.
