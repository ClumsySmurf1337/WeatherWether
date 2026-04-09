# Daily autonomous lane (Whether)

Goal: one predictable loop for **build health**, **Linear hygiene**, and **validation** — with fallbacks when Cursor Cloud is down.

## Morning (5–10 min)

1. **Install / load env**
   - Ensure `.env.local` exists (`tools/tasks/init-linear-env.ps1` once).
   - Confirm `.env.linear.generated` is current (re-run `npm run linear:bootstrap -- --apply` if you changed Linear workflow states).

2. **Autonomous script (Windows)**

   ```powershell
   pwsh ./tools/tasks/daily-autonomous.ps1
   ```

   This runs prerequisites, optional Linear status + producer **dry-run**, and `tools/tasks/validate.ps1`.

3. **Apply PM automation (optional)**

   ```powershell
   npm run linear:producer -- --apply
   ```

   This runs **promote** (Backlog → Todo within cap) then **dispatch** (Todo → In Progress + assignee).

4. **Godot**

   ```powershell
   pwsh ./tools/tasks/launch.ps1
   ```

## Worker agents

Pick a role and claim one issue:

```powershell
npm run linear:pickup -- --role=gameplay-programmer --apply
```

Roles: `producer`, `gameplay-programmer`, `ui-developer`, `level-designer`, `qa-agent`, `art-pipeline`.

## Phased backlog (stay under 250 active)

- New work is created in **Backlog** (not Todo) when `LINEAR_STATE_BACKLOG_ID` is set.
- Run **`npm run linear:seed`** repeatedly; it **dedupes by title** and only creates up to `LINEAR_SEED_BATCH_MAX` per run while under `LINEAR_ACTIVE_ISSUE_CAP`.
- When you have capacity, **`npm run linear:promote -- --apply`** moves the next batch **Backlog → Todo**.

## D-drive policy

If temp/cache vars still point at `C:` and `verify-d-drive-usage` fails, run:

```powershell
pwsh ./tools/install/configure-d-drive-caches.ps1
```

Open a **new** terminal, or use `daily.ps1 -SkipDdriveCheck` (already used inside `daily-autonomous.ps1`).

## Full workspace audit

```powershell
pwsh ./tools/tasks/validate-workspace.ps1
```

## If Cursor Cloud is down

See [AUTONOMOUS_ORCHESTRATION.md](AUTONOMOUS_ORCHESTRATION.md): use local Cursor agents + Copilot + CLI in parallel, same git task boundaries.

## Security note

Never commit `.env.local`. Rotate any leaked Linear keys.
