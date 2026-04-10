param(
    [int]$LaneCount = 3,
    [switch]$EditorLaneTerminals
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

Write-Host "=== Cursor RESUME (recover after interruption) ===`n"
if ($EditorLaneTerminals) {
    Write-Host "(Editor lane terminals: step 3 prepares worktrees + Cursor Tasks — no external PowerShell popups.)`n"
}

Write-Host "[1/3] Refresh PM assignment files (In Progress prioritized)"
npm run linear:pm-assignments

Write-Host "`n[2/3] Sync worktrees with origin/main (conflicts surfaced early)"
npm run worktrees:sync

if ($EditorLaneTerminals) {
    Write-Host "`n[3/3] Ensure lane worktrees + print Task hint (integrated terminals)"
    & "$repoRoot\tools\tasks\prepare-editor-lane-worktrees.ps1" -LaneCount $LaneCount
} else {
    Write-Host "`n[3/3] Launch lanes in resume mode (one external pwsh per lane + cursor-agent)"
    & "$repoRoot\tools\tasks\cursor-autonomous-session.ps1" -SkipNpmCi -SkipValidate -CreateWorktrees -SyncWorktrees -SpawnAgentCli -LaneCount $LaneCount
}

Write-Host "`n=== Cursor RESUME complete ==="
