# Troubleshooting

## Godot Not Found

- Ensure executable exists under `D:\Godot`.
- Re-run `pwsh ./tools/install/check-prereqs.ps1`.

## C Drive Filling Up

- Run `pwsh ./tools/install/configure-d-drive-caches.ps1`.
- Verify with `pwsh ./tools/install/verify-d-drive-usage.ps1`.

## Validation Script Fails

- Confirm project opens in Godot.
- Ensure level files are valid JSON.
- Run `pwsh ./tools/tasks/validate.ps1 -LevelsOnly`.

## Cloud Agent Unavailable

- Switch to local mode: `pwsh ./tools/dev/start-local-stack.ps1`.
- Continue via fallback playbook.

