# Paths and Storage Policy

All project tools should prefer D drive to avoid C drive exhaustion.

## Canonical Paths

- Godot binary root: `D:\Godot`
- Repo root (recommended): `D:\Dev\WeatherWether`
- Shared caches: `D:\Caches\WeatherWether`
- Build outputs: `D:\Builds\WeatherWether`
- Agent logs/worktrees: `D:\Agents\WeatherWether`

## Required Behavior

- NPM/PNPM/PIP/UV caches point to `D:\Caches\WeatherWether`.
- Godot temp/export directories point to `D:\Builds\WeatherWether`.
- Agent runtime logs/worktrees point to `D:\Agents\WeatherWether`.

## Validation

Run:

```powershell
pwsh ./tools/install/verify-d-drive-usage.ps1
```

The script reports non-D drive paths for quick correction.

