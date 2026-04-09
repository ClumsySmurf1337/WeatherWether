# Win11 Setup

## Prerequisites

- Windows 11
- PowerShell 7+
- Git
- Node.js 20+
- Python 3.11+
- Cursor
- Godot installed at `D:\Godot`

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

