# Daily full (audit + validate + Linear PM preview)

Dry-run producer (default). From **Cursor’s integrated terminal**, lane worktrees + **Tasks → All lane terminals** run at the end automatically:

```powershell
pwsh ./tools/tasks/daily-full.ps1
```

Apply promote + dispatch in Linear:

```powershell
pwsh ./tools/tasks/daily-full.ps1 -ApplyProducer
npm run daily:full:apply
```

No lane prep (Task Scheduler / headless):

```powershell
pwsh ./tools/tasks/daily-full.ps1 -SkipEditorLanePrep
npm run daily:full:lean
```

Force lane prep even outside Cursor:

```powershell
npm run daily:full:lanes
```

npm: `npm run daily:full`, `daily:full:apply`, `daily:full:lanes`, `daily:full:lean`, `daily:full:apply:lanes`.

See `docs/DAILY.md`.
