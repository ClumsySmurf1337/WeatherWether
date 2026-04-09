param([switch]$SkipDdriveCheck)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Write-Host "== Whether Daily Check =="
& "$repoRoot\tools\install\check-prereqs.ps1"
if (-not $SkipDdriveCheck) {
    try {
        & "$repoRoot\tools\install\verify-d-drive-usage.ps1"
    } catch {
        Write-Host "[warn] D-drive cache check: $_"
        Write-Host "Run tools\install\configure-d-drive-caches.ps1 or use -SkipDdriveCheck for autonomous lane."
    }
}

if (Test-Path "$repoRoot\package.json") {
    Write-Host "Node tooling present."
}

Write-Host "Daily check complete."
