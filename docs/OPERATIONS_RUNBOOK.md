# Operations Runbook

## Weather Whether — Cursor lane loop (local, recommended)

See **`docs/DAILY.md`**. Short path:

1. **Tasks → Run Task →** **Weather Whether — Daily apply:lanes, then parallel lane agents**
2. **Tasks → Run Task →** **Weather Whether — QA agent (lane PRs)** when PRs are ready to merge
3. Repeat step 1 (and step 2 as needed)

## Daily Start

1. `pwsh ./tools/tasks/daily.ps1`
2. `pwsh ./tools/tasks/run-agent-batch.ps1 -Mode cloud`
3. Dispatch scoped tasks.

## Local Fallback

1. `pwsh ./tools/dev/start-local-stack.ps1`
2. Continue same tasks with local agents.
3. Validate before merge.

## Validation Gate

Use:

```powershell
pwsh ./tools/tasks/validate.ps1
```

## Build Gate

Use:

```powershell
pwsh ./tools/tasks/build.ps1
```

## Incident Priority

- P0: crash/data loss/build-blocking
- P1: puzzle logic regression
- P2: UX polish issue
- P3: non-blocking style debt

