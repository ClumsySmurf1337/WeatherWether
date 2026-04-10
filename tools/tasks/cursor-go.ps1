param(
    [int]$LaneCount = 3,
    [int]$TodoTarget = 8,
    [switch]$SkipSessionLaunch,
    [switch]$EditorLaneTerminals
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

Write-Host "=== Cursor GO (PM prep -> deps -> todo -> lanes -> session) ===`n"
if ($EditorLaneTerminals) {
    Write-Host "(Editor lane terminals: step 5 uses Cursor Tasks — no external PowerShell popups.)`n"
}

Write-Host "[1/5] PM prepare (bootstrap/labels/organize/assignments)"
npm run linear:pm-prepare

Write-Host "`n[2/5] Apply dependency edges (Linear blocks relations)"
npm run linear:apply-deps -- --apply

Write-Host "`n[3/5] Feed Todo by PM phase order (target=$TodoTarget)"
npm run linear:pm-feed-todo -- --apply --target=$TodoTarget

Write-Host "`n[4/5] Kick off one issue per build lane"
npm run linear:kickoff-lanes -- --apply

if ($EditorLaneTerminals) {
    Write-Host "`n[5/5] Lane worktrees + sync (open terminals via Cursor Task next)"
    & "$repoRoot\tools\tasks\prepare-editor-lane-worktrees.ps1" -LaneCount $LaneCount
} elseif (-not $SkipSessionLaunch) {
    Write-Host "`n[5/5] Launch parallel Cursor session (external PowerShell + cursor-agent)"
    & "$repoRoot\tools\tasks\cursor-autonomous-session.ps1" -ApplyProducer -CreateWorktrees -SyncWorktrees -SpawnAgentCli -LaneCount $LaneCount
} else {
    Write-Host "`n[5/5] Skipped session launch (-SkipSessionLaunch)"
}

Write-Host "`n=== Cursor GO complete ==="

