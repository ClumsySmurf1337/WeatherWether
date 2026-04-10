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

function Get-AgentWorktreePath([string]$branchName, [string]$root) {
    $folder = ($branchName -replace "[^a-zA-Z0-9._-]", "-").Trim("-")
    return Join-Path $root "wt-$folder"
}

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
    $agentRoot = $env:WHETHER_AGENT_ROOT
    if ([string]::IsNullOrWhiteSpace($agentRoot)) {
        $agentRoot = "D:\Agents\WeatherWether"
    }
    $roles = @("gameplay-programmer", "ui-developer", "level-designer")
    for ($i = 1; $i -le $LaneCount; $i++) {
        $branch = "agent/cursor-lane-$i"
        $wtPath = Get-AgentWorktreePath $branch $agentRoot
        if (-not (Test-Path -LiteralPath $wtPath)) {
            Write-Host "  Creating worktree: $wtPath"
            & "$repoRoot\tools\tasks\new-agent-worktree.ps1" -BranchName $branch
        } else {
            Write-Host "  Exists: $wtPath"
        }
    }
    Write-Host "`n  Syncing worktrees with origin/main..."
    & "$repoRoot\tools\tasks\sync-agent-worktrees.ps1"

    Write-Host "`n--- Lane map ---"
    for ($i = 1; $i -le $LaneCount; $i++) {
        $branch = "agent/cursor-lane-$i"
        $role = $roles[($i - 1) % $roles.Length]
        $wtPath = Get-AgentWorktreePath $branch $agentRoot
        Write-Host "  Lane $i  $role"
        Write-Host "           $wtPath"
    }

    Write-Host "`n>>> Open 3 integrated terminals IN THIS CURSOR WINDOW:"
    Write-Host "    1) Ctrl+Shift+P"
    Write-Host "    2) Tasks: Run Task"
    Write-Host "    3) Pick:  Weather Whether — All lane terminals (parallel)"
    Write-Host ""
    Write-Host "    Each task runs: resume-pickup (main repo .env.local) -> cd worktree -> ``cursor agent`` (lane prompt)."
    Write-Host "    No manual typing in the terminal. If 3 parallel agents fight for one Cursor UI, run lanes one at a time from Tasks.`n"
} elseif (-not $SkipSessionLaunch) {
    Write-Host "`n[5/5] Launch parallel Cursor session (external PowerShell + cursor agent)"
    & "$repoRoot\tools\tasks\cursor-autonomous-session.ps1" -ApplyProducer -CreateWorktrees -SyncWorktrees -SpawnAgentCli -LaneCount $LaneCount
} else {
    Write-Host "`n[5/5] Skipped session launch (-SkipSessionLaunch)"
}

Write-Host "`n=== Cursor GO complete ==="

