Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Write-Host "== Whether Daily Check =="
& "$repoRoot\tools\install\check-prereqs.ps1"
& "$repoRoot\tools\install\verify-d-drive-usage.ps1"

if (Test-Path "$repoRoot\package.json") {
    Write-Host "Node tooling present."
}

Write-Host "Daily check complete."
