param(
    [int]$LaneCount = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. "$repoRoot\tools\tasks\cursor-cli.ps1"

$agentRoot = $env:WHETHER_AGENT_ROOT
if ([string]::IsNullOrWhiteSpace($agentRoot)) {
    $agentRoot = "D:\Agents\WeatherWether"
}

$exe = Get-CursorCliExecutable
if (-not $exe) {
    throw "Cursor CLI not found. Install Cursor CLI, add ``cursor`` to PATH, or set CURSOR_CLI_BIN."
}

$roles = @("gameplay-programmer", "ui-developer", "level-designer")

Write-Host "=== Open lane worktrees in new Cursor windows ===`n"
Write-Host "Agent root: $agentRoot`n"

for ($i = 1; $i -le $LaneCount; $i++) {
    $wt = Join-Path $agentRoot "wt-agent-cursor-lane-$i"
    if (-not (Test-Path -LiteralPath $wt)) {
        Write-Warning "Missing worktree: $wt — from repo root run: pwsh ./tools/tasks/new-agent-worktree.ps1 -BranchName agent/cursor-lane-$i"
        continue
    }
    Write-Host "Opening lane $i : $wt"
    Start-Process -FilePath $exe -ArgumentList @("-n", $wt)
}

Write-Host "`n--- In each new Cursor window ---"
Write-Host "1. Open Terminal (integrated)."
Write-Host "2. Claim/resume the lane issue:"
for ($i = 1; $i -le $LaneCount; $i++) {
    $role = $roles[($i - 1) % $roles.Length]
    Write-Host "   Lane $i : npm run linear:resume-pickup -- --role=$role --apply"
}
Write-Host "3. Prefer Cursor Agent in the sidebar on the In Progress issue."
Write-Host "   Optional same-terminal CLI: open tools/tasks/prompts/lane-agent-prompt.md, replace {{ROLE}}, then:"
Write-Host '   cursor chat "<pasted prompt text>"'
Write-Host "`nTip: ``cursor:go`` / ``cursor:resume`` spawn separate PowerShell windows; this script opens worktrees inside Cursor instead.`n"
