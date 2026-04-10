param(
    [int]$LaneCount = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

Write-Host "=== Cursor RESUME (recover after interruption) ===`n"
Write-Host "[1/3] Refresh PM assignment files (In Progress prioritized)"
npm run linear:pm-assignments

Write-Host "`n[2/3] Sync worktrees with origin/main (conflicts surfaced early)"
npm run worktrees:sync

Write-Host "`n[3/3] Launch lanes in resume mode (resume-pickup per role)"
& "$repoRoot\tools\tasks\cursor-autonomous-session.ps1" -SkipNpmCi -SkipValidate -SyncWorktrees -SpawnAgentCli -LaneCount $LaneCount

Write-Host "`n=== Cursor RESUME complete ==="

