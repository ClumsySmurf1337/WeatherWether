param(
    [Parameter(Mandatory = $true)]
    [string]$BranchName,
    [string]$BaseBranch = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

function Test-GitRepo {
    git rev-parse --git-dir *>$null
    return ($LASTEXITCODE -eq 0)
}

function Test-GitRef([string]$ref) {
    git show-ref --verify --quiet $ref *>$null
    return ($LASTEXITCODE -eq 0)
}

function Get-DefaultBaseBranch {
    $remotes = @(git remote 2>$null)
    $hasOrigin = $remotes -contains "origin"
    if ($hasOrigin) {
        git fetch origin --prune 2>$null
        $sym = git symbolic-ref -q refs/remotes/origin/HEAD 2>$null
        if ($sym -and $sym -match "origin/(.+)$") {
            return $Matches[1]
        }
        foreach ($cand in @("main", "master")) {
            if (Test-GitRef "refs/remotes/origin/$cand") {
                return $cand
            }
        }
    }
    foreach ($cand in @("main", "master")) {
        if (Test-GitRef "refs/heads/$cand") {
            return $cand
        }
    }
    $head = git rev-parse --abbrev-ref HEAD 2>$null
    if ($head -and $head -ne "HEAD") {
        return $head
    }
    return ""
}

if (-not (Test-GitRepo)) {
    throw "Not a git repository: $repoRoot"
}

git rev-parse HEAD *>$null
if ($LASTEXITCODE -ne 0) {
    throw "No commits yet. Run: git add . && git commit -m `"Initial commit`" && push (or create main on GitHub), then retry."
}

if ([string]::IsNullOrWhiteSpace($BaseBranch)) {
    $BaseBranch = Get-DefaultBaseBranch
    if ([string]::IsNullOrWhiteSpace($BaseBranch)) {
        throw "Could not detect base branch. Pass -BaseBranch explicitly (e.g. main)."
    }
    Write-Host "Detected base branch: $BaseBranch"
}

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

# Resolve base to a local ref (create tracking branch if needed)
$localBase = $false
if (Test-GitRef "refs/heads/$BaseBranch") {
    $localBase = $true
} elseif (Test-GitRef "refs/remotes/origin/$BaseBranch") {
    Write-Host "Creating local branch $BaseBranch from origin/$BaseBranch..."
    git branch $BaseBranch "origin/$BaseBranch"
    $localBase = $true
}

if (-not $localBase) {
    throw "Base branch '$BaseBranch' not found locally or as origin/$BaseBranch. Fetch/push main first or pass -BaseBranch."
}

$branchExists = Test-GitRef "refs/heads/$BranchName"
if ($branchExists) {
    Write-Host "Branch exists; checking out into worktree..."
    git worktree add $workPath $BranchName
} else {
    Write-Host "Creating branch $BranchName from $BaseBranch at $workPath..."
    git worktree add -b $BranchName $workPath $BaseBranch
}

Write-Host "Done. Open $workPath in another Cursor window for a parallel local agent."
Write-Host "Scope: .claude/CLAUDE.md and docs/CURSOR_PARALLEL_AGENTS.md"
Write-Host "Remove: git worktree remove `"$workPath`""
if (-not $branchExists) {
    Write-Host "If abandoning: git branch -d $BranchName"
}
