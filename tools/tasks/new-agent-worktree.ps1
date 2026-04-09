param(
    [Parameter(Mandatory = $true)]
    [string]$BranchName,
    [string]$BaseBranch = "main"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

$agentRoot = $env:WHETHER_AGENT_ROOT
if ([string]::IsNullOrWhiteSpace($agentRoot)) {
    $agentRoot = "D:\Agents\WeatherWether"
}
if (-not (Test-Path $agentRoot)) {
    New-Item -ItemType Directory -Path $agentRoot -Force | Out-Null
}

$folder = ($BranchName -replace "[^a-zA-Z0-9._-]", "-").Trim("-")
if ([string]::IsNullOrWhiteSpace($folder)) {
    throw "BranchName produced empty folder name."
}
$workPath = Join-Path $agentRoot "wt-$folder"

if (Test-Path $workPath) {
    throw "Path already exists: $workPath. Remove it or pick another branch name."
}

# Ensure base exists locally
$hasBase = git show-ref --verify --quiet "refs/heads/$BaseBranch" 2>$null
if (-not $hasBase) {
    git fetch origin "$BaseBranch`:refs/heads/$BaseBranch" 2>$null
}
if (-not (git show-ref --verify --quiet "refs/heads/$BaseBranch" 2>$null)) {
    throw "Base branch '$BaseBranch' not found locally. Fetch or checkout main first."
}

$existingBranch = git show-ref --verify --quiet "refs/heads/$BranchName" 2>$null
if ($existingBranch) {
    Write-Host "Branch exists; checking out into worktree..."
    git worktree add $workPath $BranchName
} else {
    Write-Host "Creating branch $BranchName from $BaseBranch at $workPath..."
    git worktree add -b $BranchName $workPath $BaseBranch
}

Write-Host "Done. Open $workPath in another Cursor window for a parallel local agent."
Write-Host "Scope: .claude/CLAUDE.md and docs/CURSOR_PARALLEL_AGENTS.md"
Write-Host "Remove: git worktree remove `"$workPath`""
if (-not $existingBranch) {
    Write-Host "If abandoning: git branch -d $BranchName"
}
