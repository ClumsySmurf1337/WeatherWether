param(
    [string]$RepoRoot = "",
    [string]$Reason = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
Set-Location -LiteralPath $resolved

if (-not [string]::IsNullOrWhiteSpace($Reason)) {
    Write-Host "  Sync main: $Reason" -ForegroundColor DarkCyan
}

Write-Host "  git fetch origin --prune" -ForegroundColor DarkGray
git fetch origin --prune
if ($LASTEXITCODE -ne 0) {
    throw "git fetch origin failed in $resolved"
}

$base = $null
foreach ($b in @("main", "master")) {
    git rev-parse "refs/remotes/origin/$b" *>$null
    if ($LASTEXITCODE -eq 0) {
        $base = $b
        break
    }
}
if ($null -eq $base) {
    throw "No origin/main or origin/master in $resolved"
}

git checkout $base
if ($LASTEXITCODE -ne 0) {
    throw "git checkout $base failed in $resolved"
}

git merge --ff-only "origin/$base"
if ($LASTEXITCODE -ne 0) {
    throw "Fast-forward $base to origin/$base failed. Resolve locally (rebase/merge), then re-run qa:agent."
}

Write-Host "  $base matches origin/$base (fetch + ff-only)." -ForegroundColor DarkGreen
