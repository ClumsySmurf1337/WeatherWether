param(
    [switch]$SkipChecksWatch,
    [switch]$SkipLocalValidate,
    [bool]$SyncMainBeforeValidate = $true,
    [switch]$NoMerge,
    [ValidateSet("squash", "merge", "rebase")]
    [string]$MergeMode = "squash",
    [string]$HeadBranchPattern = "^agent/cursor-lane-\d+$",
    [bool]$SyncWorktreesAfter = $true,
    [switch]$SkipResetLaneBranches,
    [switch]$SkipChangelog
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

function Test-GhCli {
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $gh) {
        throw "GitHub CLI (gh) not found. Install: https://cli.github.com/"
    }
}

Write-Host ""
Write-Host "  WHETHER — QA AGENT (lane PRs)" -ForegroundColor Cyan
Write-Host "  Open PRs → checks → merge main → validate → merge PR → Linear Done → sync worktrees → reset lane branches (unless -SkipResetLaneBranches)." -ForegroundColor DarkGray
Write-Host ""
Write-Host "=== QA batch: open PRs whose head matches $HeadBranchPattern ===`n"
Test-GhCli

$raw = gh pr list --state open --json number,headRefName,title 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "gh pr list failed."
}

$list = $raw | ConvertFrom-Json
if (-not $list) {
    Write-Host "No open PRs returned."
    $list = @()
}

$lanePrs = @($list | Where-Object { $_.headRefName -match $HeadBranchPattern } | Sort-Object {
        $m = [regex]::Match($_.headRefName, "cursor-lane-(\d+)$")
        if ($m.Success) { [int]$m.Groups[1].Value } else { 999 }
    })

if ($lanePrs.Count -eq 0) {
    Write-Host "No open lane PRs (heads like agent/cursor-lane-1). Nothing to do."
    Write-Host "Tip: create PRs with lane-ship.ps1 or gh pr create from each worktree."
    exit 0
}

Write-Host "Found $($lanePrs.Count) lane PR(s):`n"
foreach ($p in $lanePrs) {
    Write-Host "  #$($p.number)  $($p.headRefName)  $($p.title)"
}
Write-Host ""

function Append-ChangelogLaneEntry {
    param(
        [int]$PrNumber,
        [string]$HeadRef,
        [string]$Title
    )
    if ($SkipChangelog) {
        return
    }
    $changelogPath = Join-Path $repoRoot "docs\CHANGELOG_LANES.md"
    if (-not (Test-Path -LiteralPath $changelogPath)) {
        @"
# Lane merge log

Entries below are appended when you run **``npm run qa:agent``** (or ``qa-lane-pr-batch.ps1``) after a PR merges. Safe to edit by hand.

"@ | Set-Content -LiteralPath $changelogPath -Encoding utf8
    }
    $dup = Select-String -LiteralPath $changelogPath -Pattern "PR #$PrNumber\b" -Quiet -ErrorAction SilentlyContinue
    if ($dup) {
        Write-Host "  Changelog: PR #$PrNumber already logged — skip." -ForegroundColor DarkGray
        return
    }
    $today = Get-Date -Format "yyyy-MM-dd"
    $line = "- PR #$PrNumber — $HeadRef — $Title"
    $sectionHeader = "## $today"
    $fileLines = @(Get-Content -LiteralPath $changelogPath)
    $headerIdx = -1
    for ($i = 0; $i -lt $fileLines.Length; $i++) {
        if ($fileLines[$i] -eq $sectionHeader) {
            $headerIdx = $i
            break
        }
    }
    if ($headerIdx -ge 0) {
        $before = $fileLines[0..$headerIdx]
        $after = @()
        if (($headerIdx + 1) -lt $fileLines.Length) {
            $after = $fileLines[($headerIdx + 1)..($fileLines.Length - 1)]
        }
        @($before + @($line) + $after) | Set-Content -LiteralPath $changelogPath -Encoding utf8
        Write-Host "  Changelog: appended under $sectionHeader" -ForegroundColor DarkGreen
        return
    }
    Add-Content -LiteralPath $changelogPath -Value "`n$sectionHeader`n$line`n" -Encoding utf8
    Write-Host "  Changelog: new section $sectionHeader" -ForegroundColor DarkGreen
}

foreach ($p in $lanePrs) {
    $n = $p.number
    Write-Host "========== QA handoff PR #$n ($($p.headRefName)) ==========" -ForegroundColor Cyan

    $detailRaw = gh pr view $n --json "title,body" 2>$null
    if ($LASTEXITCODE -eq 0 -and $detailRaw) {
        $detail = $detailRaw | ConvertFrom-Json
        $bodyText = if ($null -eq $detail.body) { "" } else { [string]$detail.body }
        $hay = [string]$detail.title + "`n" + $bodyText
        $tok = "\b$([regex]::Escape($teamKey))-\d+\b"
        if ($hay -notmatch $tok) {
            Write-Warning "PR #$n : title/body missing ${teamKey}-### token — linear:complete-from-pr may not move an issue to Done."
        }
        else {
            Write-Host "  Linear verify: ${teamKey}-### present in PR title/body." -ForegroundColor DarkGreen
        }
    }

    Set-Location $repoRoot
    git fetch origin --prune 2>$null
    $onBase = $false
    foreach ($b in @("main", "master")) {
        git show-ref --verify --quiet "refs/heads/$b" 2>$null
        if ($LASTEXITCODE -eq 0) {
            git checkout $b
            if ($LASTEXITCODE -eq 0) { $onBase = $true; break }
        }
        git show-ref --verify --quiet "refs/remotes/origin/$b" 2>$null
        if ($LASTEXITCODE -eq 0) {
            git checkout -B $b "origin/$b"
            if ($LASTEXITCODE -eq 0) { $onBase = $true; break }
        }
    }
    if ($onBase) {
        git pull --ff-only 2>$null
    }

    $splat = @{
        PullRequestNumber = $n
        MergeMode         = $MergeMode
    }
    if ($SkipChecksWatch) { $splat.SkipChecksWatch = $true }
    if ($SkipLocalValidate) { $splat.SkipLocalValidate = $true }
    if ($SyncMainBeforeValidate) {
        $splat.SyncMainBeforeValidate = $true
    }
    if ($NoMerge) { $splat.NoMerge = $true }

    & "$repoRoot\tools\tasks\qa-pr-handoff-local.ps1" @splat
    if ($LASTEXITCODE -ne 0) {
        throw "qa-pr-handoff-local failed for PR #$n (exit $LASTEXITCODE). Fix and re-run; remaining PRs were not processed."
    }
    if (-not $NoMerge) {
        Set-Location $repoRoot
        foreach ($baseName in @("main", "master")) {
            git show-ref --verify --quiet "refs/heads/$baseName" 2>$null
            if ($LASTEXITCODE -eq 0) {
                git checkout $baseName
                if ($LASTEXITCODE -eq 0) {
                    git pull --ff-only 2>$null
                    break
                }
            }
        }
        Append-ChangelogLaneEntry -PrNumber $n -HeadRef $p.headRefName -Title $p.title
    }
    Write-Host ""
}

if ($SyncWorktreesAfter) {
    Write-Host "=== Syncing agent worktrees with origin/main ===`n"
    Set-Location $repoRoot
    npm run worktrees:sync
}

if (-not $SkipResetLaneBranches) {
    Write-Host "`n=== Resetting lane worktrees to fresh branches from main ===`n"
    & "$repoRoot\tools\tasks\lane-worktrees-reset-for-next-cycle.ps1"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  QA AGENT FINISHED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next cycle: run daily full (lanes) again so agents pick up new work:" -ForegroundColor Cyan
Write-Host "  npm run daily:full:apply:lanes" -ForegroundColor White
Write-Host "  (or npm run daily:full:apply + your lane tasks)`n" -ForegroundColor DarkGray
Write-Host 'If docs/CHANGELOG_LANES.md was updated, commit it on main when you are ready.' -ForegroundColor DarkGray
Write-Host ""
if ($SkipResetLaneBranches) {
    Write-Host "You skipped lane branch reset. To reset lane worktrees to fresh agent/cursor-lane-N from main:" -ForegroundColor Yellow
    Write-Host "  npm run lane:next-cycle" -ForegroundColor Gray
}
