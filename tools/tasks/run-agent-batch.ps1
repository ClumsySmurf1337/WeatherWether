param(
    [ValidateSet("cloud", "local")]
    [string]$Mode = "cloud"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

if ($Mode -eq "cloud") {
    & "$repoRoot\tools\dev\start-cloud-stack.ps1"
    Write-Host "Cloud batch preset active. Dispatch tasks via Cursor Cloud Agents."
} else {
    & "$repoRoot\tools\dev\start-local-stack.ps1"
    Write-Host "Local batch preset active. Use Cursor + Claude worktrees."
}

Write-Host "Recommended first three tasks:"
Write-Host "1) Gameplay core update (scripts/grid + scripts/weather)"
Write-Host "2) UI iteration (scripts/ui + scenes/ui)"
Write-Host "3) Level validation batch (levels + validate script)"
