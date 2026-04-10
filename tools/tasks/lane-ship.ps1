param(
    [string]$LinearId = "",
    [int]$LaneIndex = 0,
    [string]$WorktreePath = "",
    [string]$MainRepoRoot = "",
    [string]$AgentRoot = "",
    [switch]$SkipValidate,
    [switch]$SkipLinearVerify
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($MainRepoRoot)) {
    $MainRepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$mainResolved = (Resolve-Path -LiteralPath $MainRepoRoot).Path

if ([string]::IsNullOrWhiteSpace($AgentRoot)) {
    $AgentRoot = $env:WHETHER_AGENT_ROOT
}
if ([string]::IsNullOrWhiteSpace($AgentRoot)) {
    $AgentRoot = "D:\Agents\WeatherWether"
}

if ($LaneIndex -gt 0 -and -not [string]::IsNullOrWhiteSpace($WorktreePath)) {
    throw "Pass either -LaneIndex (1..8) or -WorktreePath, not both."
}

if ($LaneIndex -gt 0) {
    $WorktreePath = Join-Path $AgentRoot "wt-agent-cursor-lane-$LaneIndex"
}

if ([string]::IsNullOrWhiteSpace($WorktreePath)) {
    throw "Set -LaneIndex (1..8) or -WorktreePath to the lane worktree."
}

if (-not (Test-Path -LiteralPath $WorktreePath)) {
    throw "Worktree not found: $WorktreePath"
}

$markerFile = Join-Path $WorktreePath ".weather-lane-issue.txt"
if ([string]::IsNullOrWhiteSpace($LinearId)) {
    if (Test-Path -LiteralPath $markerFile) {
        $LinearId = (Get-Content -LiteralPath $markerFile -Raw).Trim()
    }
}
if ($LinearId -notmatch '^[A-Za-z]+-\d+$') {
    Push-Location -LiteralPath $WorktreePath
    try {
        git rev-parse HEAD *>$null
        if ($LASTEXITCODE -eq 0) {
            $subj = git log -1 --pretty=%s 2>$null
            if ($subj -match '\b([A-Za-z]+-\d+)\b') {
                $LinearId = $Matches[1].ToUpper()
                Write-Host "Linear id from last commit message: $LinearId" -ForegroundColor DarkCyan
                [System.IO.File]::WriteAllText($markerFile, "$LinearId`n")
            }
        }
    }
    finally {
        Pop-Location
    }
}
if ($LinearId -notmatch '^[A-Za-z]+-\d+$') {
    throw "No Linear issue id: pass -LinearId WEA-123, run resume-pickup with --worktree-marker, or use a commit message containing WEA-### (got: '$LinearId')."
}
$LinearId = $LinearId.ToUpper()

function Test-GhCli {
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $gh) {
        throw "GitHub CLI (gh) not found. Install: https://cli.github.com/"
    }
}

Test-GhCli

. (Join-Path $PSScriptRoot "lane-ship-lib.ps1")

Set-Location -LiteralPath $WorktreePath

$state = Get-LaneWorktreeShipState -RepoPath $WorktreePath
if (-not $state.NeedsShip) {
    Write-Host "Nothing to ship — no uncommitted changes and no unpushed commits: $WorktreePath" -ForegroundColor Yellow
    exit 0
}

if ($state.Branch -eq "HEAD") {
    throw "Detached HEAD in $WorktreePath — checkout a branch first."
}
$branch = $state.Branch

if ($state.HasUncommitted) {
    Write-Host "Uncommitted changes in $WorktreePath (branch $branch)." -ForegroundColor Cyan
}
if ($state.UnpushedCount -gt 0) {
    Write-Host "Unpushed commits: $($state.UnpushedCount) (will push / open PR)." -ForegroundColor Cyan
}

if (-not $SkipValidate) {
    Write-Host "Running validate.ps1 against this worktree (GUT + level checks when GUT is installed)..."
    & "$mainResolved\tools\tasks\validate.ps1" -GodotProjectPath $WorktreePath
}

if (-not $SkipLinearVerify) {
    Write-Host "Verifying Linear issue $LinearId exists and is not Done/Canceled (repo root for .env.local)..."
    Push-Location -LiteralPath $mainResolved
    try {
        $env:LINEAR_SHIP_ISSUE_ID = $LinearId
        npm run linear:verify-issue-for-ship
        if ($LASTEXITCODE -ne 0) {
            throw "linear:verify-issue-for-ship failed (exit $LASTEXITCODE)."
        }
    }
    finally {
        Remove-Item Env:\LINEAR_SHIP_ISSUE_ID -ErrorAction SilentlyContinue
        Pop-Location
    }
    Set-Location -LiteralPath $WorktreePath
}

if ($state.HasUncommitted) {
    Write-Host "Staging and committing in $WorktreePath (branch $branch)..." -ForegroundColor Cyan
    git add -A
    $msg = "${LinearId}: lane work"
    git commit -m $msg
    if ($LASTEXITCODE -ne 0) {
        throw "git commit failed."
    }
}

Write-Host "Pushing $branch..." -ForegroundColor Cyan
git push -u origin $branch
if ($LASTEXITCODE -ne 0) {
    throw "git push failed."
}

$existingJson = gh pr list --head $branch --state open --json number 2>$null
if ($LASTEXITCODE -eq 0 -and $existingJson) {
    $existingArr = @($existingJson | ConvertFrom-Json)
    if ($existingArr.Count -gt 0 -and $null -ne $existingArr[0].number) {
        Write-Host "Open PR already exists for $branch : #$($existingArr[0].number)" -ForegroundColor Green
        exit 0
    }
}

$title = "${LinearId}: lane work"
$body = "Linear: $LinearId`n`nShipped via tools/tasks/lane-ship.ps1"
Write-Host "Creating PR to main..." -ForegroundColor Cyan
gh pr create --base main --head $branch --title $title --body $body
if ($LASTEXITCODE -ne 0) {
    throw "gh pr create failed."
}

Write-Host "`nShip complete. Next: after CI green, run QA from main repo:" -ForegroundColor Green
Write-Host "  npm run qa:agent" -ForegroundColor Gray
