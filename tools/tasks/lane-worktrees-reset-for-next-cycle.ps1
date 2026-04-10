param(
    [int]$LaneCount = 3,
    [string]$AgentRoot = "",
    [string]$BaseBranch = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($AgentRoot)) {
    $AgentRoot = $env:WHETHER_AGENT_ROOT
}
if ([string]::IsNullOrWhiteSpace($AgentRoot)) {
    $AgentRoot = "D:\Agents\WeatherWether"
}

$mainRepo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Get-DefaultBaseBranch {
    Set-Location $mainRepo
    git fetch origin --prune 2>$null
    $sym = git symbolic-ref -q refs/remotes/origin/HEAD 2>$null
    if ($sym -and $sym -match "origin/(.+)$") {
        return $Matches[1]
    }
    foreach ($c in @("main", "master")) {
        git show-ref --verify --quiet "refs/remotes/origin/$c" 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $c
        }
    }
    return "main"
}

if ([string]::IsNullOrWhiteSpace($BaseBranch)) {
    $BaseBranch = Get-DefaultBaseBranch
}

Write-Host "=== Reset lane worktrees for next cycle (base: origin/$BaseBranch) ===`n"
Write-Host "Agent root: $AgentRoot`n"

for ($i = 1; $i -le $LaneCount; $i++) {
    $wt = Join-Path $AgentRoot "wt-agent-cursor-lane-$i"
    $laneBranch = "agent/cursor-lane-$i"

    if (-not (Test-Path -LiteralPath $wt)) {
        Write-Warning "Skip lane $i — missing worktree: $wt"
        continue
    }

    Write-Host "---- Lane $i : $wt ----" -ForegroundColor Cyan
    Set-Location -LiteralPath $wt

    git rev-parse --git-dir *>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Not a git repo, skip."
        continue
    }

    git fetch origin --prune
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "fetch failed for lane $i"
        continue
    }

    # Primary repo worktree already has `main` checked out; this lane worktree cannot attach to the
    # same branch name. Detach at origin/<base>, drop the old lane branch, recreate from that tip.
    git checkout --detach "origin/$BaseBranch"
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "detach at origin/$BaseBranch failed in lane $i — resolve manually."
        continue
    }

    git branch -D $laneBranch 2>$null

    git checkout -b $laneBranch
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not create $laneBranch in lane $i"
        continue
    }

    git push -u origin $laneBranch --force-with-lease
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "push --force-with-lease failed for $laneBranch (remote may differ). Resolve manually."
        continue
    }

    Write-Host "  OK: $laneBranch reset from $BaseBranch`n" -ForegroundColor Green
}

Set-Location $mainRepo
Write-Host "=== Lane reset complete ==="
Write-Host "Run: npm run cursor:resume:editor (or lane Tasks) to pick up new work on fresh branches."
