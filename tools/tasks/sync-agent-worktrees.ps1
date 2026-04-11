param(
    [string]$BaseRef = "origin/main"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$agentRoot = $env:WHETHER_AGENT_ROOT
if ([string]::IsNullOrWhiteSpace($agentRoot)) {
    $agentRoot = "D:\Agents\WeatherWether"
}

if (-not (Test-Path $agentRoot)) {
    Write-Host "No agent root at $agentRoot — nothing to sync."
    exit 0
}

Write-Host "=== Sync worktrees under $agentRoot with $BaseRef ===`n"

$copyAssignmentsScript = Join-Path $repoRoot "tools\tasks\copy-generated-assignments-to-worktree.ps1"

Get-ChildItem -Path $agentRoot -Directory -Filter "wt-*" -ErrorAction SilentlyContinue | ForEach-Object {
    $wt = $_.FullName
    $gitDir = Join-Path $wt ".git"
    if (-not (Test-Path $gitDir)) {
        return
    }
    Write-Host "-> $wt"
    git -C $wt fetch origin
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "  fetch failed"
        return
    }
    git -C $wt merge $BaseRef --no-edit
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "  merge $BaseRef failed — run: npm run qa:repair-merge -- -RepoPath `"$wt`""
    } else {
        Write-Host "  merged $BaseRef"
    }
    # Always refresh handoffs (merge may have failed; agents still need local scope for Copilot).
    & $copyAssignmentsScript -MainRepoRoot $repoRoot -WorktreePath $wt
}

Write-Host "`nDone. Tip: run from repo root before parallel lanes: pwsh ./tools/tasks/sync-agent-worktrees.ps1"
