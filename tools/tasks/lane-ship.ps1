param(
    [string]$LinearId = "",
    [int]$LaneIndex = 0,
    [string]$WorktreePath = "",
    [string]$MainRepoRoot = "",
    [string]$AgentRoot = "",
    [switch]$SkipValidate
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

if ([string]::IsNullOrWhiteSpace($LinearId)) {
    $markerFile = Join-Path $WorktreePath ".weather-lane-issue.txt"
    if (Test-Path -LiteralPath $markerFile) {
        $LinearId = (Get-Content -LiteralPath $markerFile -Raw).Trim()
    }
}
if ($LinearId -notmatch '^[A-Za-z]+-\d+$') {
    throw "No Linear issue id: pass -LinearId WEA-123, or run lane terminal so resume-pickup writes .weather-lane-issue.txt in the worktree (got: '$LinearId')."
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
    Write-Host "Running validate.ps1 against this worktree..."
    & "$mainResolved\tools\tasks\validate.ps1" -GodotProjectPath $WorktreePath
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
