param(
    [int]$LaneCount = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Get-AgentWorktreePath([string]$branchName, [string]$root) {
    $folder = ($branchName -replace "[^a-zA-Z0-9._-]", "-").Trim("-")
    return Join-Path $root "wt-$folder"
}

$agentRoot = $env:WHETHER_AGENT_ROOT
if ([string]::IsNullOrWhiteSpace($agentRoot)) {
    $agentRoot = "D:\Agents\WeatherWether"
}

$roles = @("gameplay-programmer", "ui-developer", "level-designer")

Write-Host "=== Editor lane worktrees (ensure + sync) ===`n"
Write-Host "Agent root: $agentRoot`n"

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

Write-Host "`n>>> Integrated terminals IN THIS CURSOR WINDOW:"
Write-Host "    1) Ctrl+Shift+P"
Write-Host "    2) Tasks: Run Task"
Write-Host "    3) Pick:  Weather Whether — All lane terminals (parallel)"
Write-Host ""
Write-Host "    Each task runs: resume-pickup (main repo .env.local) -> cd worktree -> cursor-agent (lane prompt)."
Write-Host "    If three agents fight one UI, run Lane 1 / 2 / 3 tasks one at a time.`n"
