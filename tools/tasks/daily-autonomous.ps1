Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

. "$repoRoot\tools\tasks\load-repo-env.ps1"

Write-Host "=== Whether autonomous daily lane ==="

Write-Host "`n[1] D-drive and tooling health"
& "$repoRoot\tools\tasks\daily.ps1" -SkipDdriveCheck

if (Test-Path "$repoRoot\.env.local") {
    Write-Host "`n[2] Linear workspace status"
    npm run linear:status
    Write-Host "`n[3] Producer cycle (dry-run)"
    npm run linear:producer
} else {
    Write-Host "`n[2] Skipping Linear (no .env.local). Run tools\tasks\init-linear-env.ps1"
}

Write-Host "`n[4] Validation (skips GUT if addon missing)"
& "$repoRoot\tools\tasks\validate.ps1"

Write-Host "`nDaily lane complete. With Linear: run `npm run linear:producer -- --apply` to promote/dispatch."
Write-Host "Copilot / local fallback: see docs\AUTONOMOUS_ORCHESTRATION.md"
