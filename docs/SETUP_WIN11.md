# Win11 Setup

## Prerequisites

- Windows 11
- PowerShell 7+
- Git
- Node.js **22+** (matches repo `engines` and GitHub Actions)
- Python 3.11+
- Cursor
- Godot installed at `D:\Godot`

## Node.js on Windows (if `nvm install 22` fails)

**Two different tools:** Unix/macOS **nvm** (shell script) and **[nvm-windows](https://github.com/coreybutler/nvm-windows)** use the same commands but are not the same install. In PowerShell you need **nvm-windows**, and it must be on `PATH`.

Common **nvm-windows** fixes:

1. **Run the terminal as Administrator** for `nvm install` / `nvm use` (symlink to `NVM_SYMLINK` needs elevation on many setups).
2. Use a **full version** if `22` is rejected: `nvm install 22.22.2` then `nvm use 22.22.2`.
3. Ensure **`NVM_HOME`** and **`NVM_SYMLINK`** are set and the symlink path is **not** inside `Program Files` (installer defaults are usually fine).
4. **Corporate proxy / SSL** — download errors often mean proxy or MITM; try another network or configure proxy for `curl`/`nvm`.

**Simplest path without nvm:** install Node 22 with **winget** (side-by-side major versions use different package IDs):

```powershell
winget install --id OpenJS.NodeJS.22 -e --source winget
```

Close and reopen the terminal, then `node -v` (expect v22.x). For repo tooling: `cd` to the project and `npm ci`.

### Multiple Node installs (Nodist, Scoop, winget)

If `node -v` stays on **v20** after installing Node 22+, another manager is **earlier on `PATH`**. Check order:

```powershell
where.exe node
```

- **Nodist** often wins with a **global** pin (e.g. `20.10.0`). Install and select 22+:

  ```powershell
  nodist + 22.22.2
  nodist global 22.22.2
  ```

  Then **new** terminals should report `v22.22.2`.

- **Scoop** `nodejs-lts` may also be present; only the **first** `node.exe` in `where.exe` output is used unless you reorder **User** or **System** environment variable **Path**.

More detail: `docs/GODOT_DOCS_ACCESS.md` → **Node.js (tooling + CI)**.

## Bootstrap

Run:

```powershell
pwsh ./tools/install/bootstrap-win11.ps1
```

This script validates tools, prepares D-drive directories, and writes cache-friendly defaults.

## Verify

```powershell
pwsh ./tools/install/check-prereqs.ps1
pwsh ./tools/install/verify-d-drive-usage.ps1
pwsh ./tools/tasks/daily.ps1
```

## First Launch

```powershell
pwsh ./tools/tasks/launch.ps1
```

