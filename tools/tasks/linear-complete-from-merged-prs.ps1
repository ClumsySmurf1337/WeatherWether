param(
    [int]$Limit = 40,
    [int]$WithinDays = 30,
    [string]$HeadBranchRegex = "^agent/cursor-lane-\d+$"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot
. "$repoRoot\tools\tasks\load-repo-env.ps1"

$teamKey = $env:LINEAR_TEAM_KEY
if ([string]::IsNullOrWhiteSpace($teamKey)) {
    $teamKey = "WEA"
}
$tok = "\b$([regex]::Escape($teamKey))-\d+\b"

function Test-GhCli {
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $gh) {
        throw "GitHub CLI (gh) not found."
    }
}

Write-Host ""
Write-Host "=== Linear catch-up: merged lane PRs → Done (last $WithinDays days, limit $Limit) ===" -ForegroundColor Cyan
Write-Host "Uses PR title/body tokens like ${teamKey}-### (same as linear:complete-from-pr).`n"
Test-GhCli

$raw = gh pr list --state merged --limit $Limit --json "number,title,body,headRefName,closedAt" 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "gh pr list --state merged failed."
}

$list = $raw | ConvertFrom-Json
if (-not $list) {
    Write-Host "No merged PRs returned."
    exit 0
}

$cutoff = (Get-Date).ToUniversalTime().AddDays(-$WithinDays)
$rx = [regex]::new($HeadBranchRegex)
$processed = 0

foreach ($pr in @($list)) {
    $head = [string]$pr.headRefName
    if (-not $rx.IsMatch($head)) {
        continue
    }
    $closedRaw = [string]$pr.closedAt
    if ([string]::IsNullOrWhiteSpace($closedRaw)) {
        continue
    }
    $closedUtc = [datetime]::Parse($closedRaw, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
    if ($closedUtc.ToUniversalTime() -lt $cutoff) {
        continue
    }

    $title = [string]$pr.title
    $body = if ($null -eq $pr.body) { "" } else { [string]$pr.body }
    $hay = $title + "`n" + $body
    if ($hay -notmatch $tok) {
        Write-Host "PR #$($pr.number) ($head): no ${teamKey}-### in title/body — skip." -ForegroundColor DarkGray
        continue
    }

    Write-Host "PR #$($pr.number) ($head) closed $closedRaw → linear:complete-from-pr" -ForegroundColor Yellow
    $env:PR_TITLE = $title
    $env:PR_BODY = $body
    npm run linear:complete-from-pr
    if ($LASTEXITCODE -ne 0) {
        throw "linear:complete-from-pr failed for merged PR #$($pr.number)."
    }
    $processed++
    Write-Host ""
}

Write-Host "Processed $processed merged lane PR(s). Done." -ForegroundColor Green
