# Daily full (audit + validate + Linear PM preview)

Dry-run producer (default):

```powershell
pwsh ./tools/tasks/daily-full.ps1
```

Apply promote + dispatch in Linear:

```powershell
pwsh ./tools/tasks/daily-full.ps1 -ApplyProducer
```

Or: `npm run daily:full`

See `docs/DAILY.md`.
