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
    [switch]$SkipChangelog,
    [switch]$SkipChangelogPush,
    [int[]]$PreflightShipLaneIndexes = @(1, 2, 3),
    [switch]$SkipPreflightShip,
    [string]$AgentRoot = "",
    [switch]$ReconcileLinearFromMergedLanePrs,
    [int]$ReconcileLinearMergedWithinDays = 30,
    [int]$ChecksPollMaxSeconds = 900,
    [int]$ChecksPollIntervalSeconds = 15
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot
$mainResolved = (Resolve-Path -LiteralPath $repoRoot).Path
. "$repoRoot\tools\tasks\load-repo-env.ps1"
. "$repoRoot\tools\tasks\lane-ship-lib.ps1"

if ([string]::IsNullOrWhiteSpace($AgentRoot)) {
    $AgentRoot = $env:WHETHER_AGENT_ROOT
}
if ([string]::IsNullOrWhiteSpace($AgentRoot)) {
    $AgentRoot = "D:\Agents\WeatherWether"
}

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
Write-Host "  Preflight: ship when dirty or ahead of origin/main (validate + Linear verify → PR if diff vs main) → per PR: checks → merge main → validate → merge → Linear Done → sync → lane reset (unless -SkipResetLaneBranches)." -ForegroundColor DarkGray
Write-Host ""
Test-GhCli

$qaRunStart = Get-Date
$qaPreflightShipInvocations = 0
$qaMergedPrLines = [System.Collections.Generic.List[string]]::new()

if (-not $SkipPreflightShip -and $PreflightShipLaneIndexes.Count -gt 0) {
    Write-Host "=== Pre-flight: lane worktrees that need ship (lanes $($PreflightShipLaneIndexes -join ', ')) ===`n" -ForegroundColor Cyan
    $rolesForMarker = @("gameplay-programmer", "ui-developer", "level-designer")
    foreach ($laneIdx in $PreflightShipLaneIndexes) {
        $wtPath = Join-Path $AgentRoot "wt-agent-cursor-lane-$laneIdx"
        if (-not (Test-Path -LiteralPath $wtPath)) {
            Write-Host "Lane $laneIdx : worktree not found — skip ($wtPath)" -ForegroundColor DarkGray
            continue
        }
        try {
            $st = Get-LaneWorktreeShipState -RepoPath $wtPath
        }
        catch {
            Write-Warning "Lane $laneIdx : could not inspect git state — skip. ($($_.Exception.Message))"
            continue
        }
        if (-not $st.NeedsShip) {
            Write-Host "Lane $laneIdx : OK (nothing to ship; ahead-of-main=$($st.CommitsAheadOfMain))." -ForegroundColor DarkGray
            continue
        }
        $markerPath = Join-Path $wtPath ".weather-lane-issue.txt"
        $markerOk = $false
        if (Test-Path -LiteralPath $markerPath) {
            $mt = (Get-Content -LiteralPath $markerPath -Raw).Trim()
            if ($mt -match '^[A-Za-z]+-\d+$') {
                $markerOk = $true
            }
        }
        if (-not $markerOk) {
            $role = $rolesForMarker[($laneIdx - 1) % $rolesForMarker.Length]
            Write-Host "Lane $laneIdx : refreshing .weather-lane-issue.txt via resume-pickup (role=$role)..." -ForegroundColor DarkYellow
            Push-Location -LiteralPath $mainResolved
            try {
                npm run linear:resume-pickup -- --role=$role --apply "--worktree-marker=$markerPath"
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "resume-pickup exited $LASTEXITCODE for lane $laneIdx — lane-ship will try commit message or may fail without -LinearId."
                }
            }
            finally {
                Pop-Location
            }
        }
        if ($st.Branch -eq "HEAD") {
            Write-Host "Lane $laneIdx : detached HEAD (e.g. after PR branch delete) — attaching agent/cursor-lane-$laneIdx for ship..." -ForegroundColor Yellow
            $laneBranch = "agent/cursor-lane-$laneIdx"
            git -C $wtPath fetch origin --prune 2>$null
            git -C $wtPath rev-parse "refs/remotes/origin/$laneBranch" 2>$null
            if ($LASTEXITCODE -eq 0) {
                git -C $wtPath checkout $laneBranch
                if ($LASTEXITCODE -ne 0) {
                    throw "Lane $laneIdx : checkout $laneBranch failed in $wtPath."
                }
                git -C $wtPath merge --ff-only "origin/$laneBranch" 2>$null
            }
            else {
                git -C $wtPath checkout -b $laneBranch
                if ($LASTEXITCODE -ne 0) {
                    throw "Lane $laneIdx : could not create $laneBranch from detached HEAD in $wtPath."
                }
            }
            $st = Get-LaneWorktreeShipState -RepoPath $wtPath
        }
        Write-Host "Lane $laneIdx : shipping — uncommitted=$($st.HasUncommitted); ahead-of-main=$($st.CommitsAheadOfMain); vs-tracking=$($st.UnpushedCount); branch=$($st.Branch)" -ForegroundColor Yellow
        $qaPreflightShipInvocations += 1
        & "$repoRoot\tools\tasks\lane-ship.ps1" -LaneIndex $laneIdx -MainRepoRoot $mainResolved -AgentRoot $AgentRoot
        if ($LASTEXITCODE -ne 0) {
            throw "Pre-flight lane-ship failed for lane $laneIdx (exit $LASTEXITCODE). Fix the worktree, then re-run npm run qa:agent."
        }
        Write-Host ""
    }
    Write-Host "=== Pre-flight ship pass complete ===`n" -ForegroundColor Green
}

Write-Host "=== QA batch: open PRs whose head matches $HeadBranchPattern ===`n"

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
    Write-Host "No open lane PRs (heads like agent/cursor-lane-1). Nothing left to merge."
    if ($SkipPreflightShip) {
        Write-Host "Tip: you used -SkipPreflightShip — stale work may still need: npm run lane:ship:lanes" -ForegroundColor DarkYellow
    }
    else {
        Write-Host "Tip: if work is still only local, check lane worktrees and .weather-lane-issue.txt (Linear id for ship)." -ForegroundColor DarkGray
    }
    $elapsed = (Get-Date) - $qaRunStart
    Write-Host ""
    Write-Host "--- QA run summary ---" -ForegroundColor Cyan
    Write-Host "  Wall time:   $($elapsed.ToString('mm\:ss'))" -ForegroundColor Gray
    Write-Host "  Lane PRs:    0 open (nothing merged this run)" -ForegroundColor Gray
    if ($SkipPreflightShip) {
        Write-Host "  Preflight:   skipped (-SkipPreflightShip)" -ForegroundColor Gray
    }
    else {
        Write-Host "  Preflight:   $qaPreflightShipInvocations lane-ship run(s) (lanes $($PreflightShipLaneIndexes -join ', '))" -ForegroundColor Gray
    }
    Write-Host "  Next:        npm run daily:full:apply:lanes (or open a lane PR, then re-run npm run qa:agent)" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

Write-Host "Found $($lanePrs.Count) lane PR(s):`n"
foreach ($p in $lanePrs) {
    Write-Host "  #$($p.number)  $($p.headRefName)  $($p.title)"
}
Write-Host ""

$changelogPushPrNumbers = [System.Collections.Generic.List[int]]::new()

function Append-ChangelogLaneEntry {
    param(
        [int]$PrNumber,
        [string]$HeadRef,
        [string]$Title
    )
    if ($SkipChangelog) {
        return $false
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
        return $false
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
        return $true
    }
    Add-Content -LiteralPath $changelogPath -Value "`n$sectionHeader`n$line`n" -Encoding utf8
    Write-Host "  Changelog: new section $sectionHeader" -ForegroundColor DarkGreen
    return $true
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

    & "$repoRoot\tools\tasks\git-sync-main.ps1" -RepoRoot $repoRoot -Reason "before QA handoff PR #$n"

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
    $splat.AgentRoot = $AgentRoot
    $splat.ChecksPollMaxSeconds = $ChecksPollMaxSeconds
    $splat.ChecksPollIntervalSeconds = $ChecksPollIntervalSeconds

    & "$repoRoot\tools\tasks\qa-pr-handoff-local.ps1" @splat
    if ($LASTEXITCODE -ne 0) {
        throw "qa-pr-handoff-local failed for PR #$n (exit $LASTEXITCODE). Fix and re-run; remaining PRs were not processed."
    }
    if (-not $NoMerge) {
        $qaMergedPrLines.Add("PR #$n  $($p.headRefName)  $($p.title)")
        Set-Location $repoRoot
        # main already synced in qa-pr-handoff-local after gh pr merge; changelog only here
        $appended = Append-ChangelogLaneEntry -PrNumber $n -HeadRef $p.headRefName -Title $p.title
        if ($appended) {
            [void]$changelogPushPrNumbers.Add($n)
        }
    }
    Write-Host ""
}

if ($changelogPushPrNumbers.Count -gt 0 -and -not $SkipChangelogPush) {
    Write-Host "`n=== Commit and push docs/CHANGELOG_LANES.md ===`n" -ForegroundColor Cyan
    Set-Location -LiteralPath $mainResolved
    & "$repoRoot\tools\tasks\git-sync-main.ps1" -RepoRoot $mainResolved -Reason "before lane changelog commit"
    git add -- "docs/CHANGELOG_LANES.md"
    git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Changelog: nothing staged after git-sync — skip push (unexpected)." -ForegroundColor Yellow
    }
    else {
        $sorted = @($changelogPushPrNumbers | Sort-Object -Unique)
        $prBits = ($sorted | ForEach-Object { "PR #$_" }) -join ", "
        git commit -m "docs: lane merge log ($prBits)" -- docs/CHANGELOG_LANES.md
        if ($LASTEXITCODE -ne 0) {
            throw "git commit failed for docs/CHANGELOG_LANES.md."
        }
        git push origin HEAD
        if ($LASTEXITCODE -ne 0) {
            throw "git push failed for changelog commit (auth or branch protection). Commit exists locally — push manually from $mainResolved."
        }
        Write-Host "  Changelog: committed and pushed ($prBits)." -ForegroundColor Green
    }
}
elseif ($changelogPushPrNumbers.Count -gt 0 -and $SkipChangelogPush) {
    Write-Host "`n  Changelog: new entries on disk; -SkipChangelogPush — commit and push docs/CHANGELOG_LANES.md manually when ready." -ForegroundColor DarkYellow
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

if ($ReconcileLinearFromMergedLanePrs) {
    Write-Host "`n=== Linear catch-up (merged lane PRs in last $ReconcileLinearMergedWithinDays days) ===`n"
    & "$repoRoot\tools\tasks\linear-complete-from-merged-prs.ps1" -WithinDays $ReconcileLinearMergedWithinDays
}

$qaElapsed = (Get-Date) - $qaRunStart
$changelogDidPush = ($changelogPushPrNumbers.Count -gt 0 -and -not $SkipChangelogPush)

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  QA AGENT FINISHED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "--- QA run summary ---" -ForegroundColor Cyan
Write-Host "  Wall time:     $($qaElapsed.ToString('mm\:ss'))" -ForegroundColor Gray
if ($SkipPreflightShip) {
    Write-Host "  Preflight:     skipped (-SkipPreflightShip)" -ForegroundColor Gray
}
else {
    Write-Host "  Preflight:     $qaPreflightShipInvocations lane-ship run(s) (lanes $($PreflightShipLaneIndexes -join ', '))" -ForegroundColor Gray
}
Write-Host "  Batch PRs:     $($lanePrs.Count) open lane PR(s); $($qaMergedPrLines.Count) merged (mode: $MergeMode; -NoMerge: $NoMerge)" -ForegroundColor Gray
foreach ($line in $qaMergedPrLines) {
    Write-Host "    merged — $line" -ForegroundColor DarkGreen
}
if ($qaMergedPrLines.Count -eq 0 -and $NoMerge -and $lanePrs.Count -gt 0) {
    Write-Host "    (no merges — -NoMerge)" -ForegroundColor DarkGray
}
if ($changelogDidPush) {
    $prBits = (@($changelogPushPrNumbers | Sort-Object -Unique) | ForEach-Object { "PR #$_" }) -join ", "
    Write-Host "  Changelog:     committed + pushed — $prBits → docs/CHANGELOG_LANES.md" -ForegroundColor Gray
}
elseif ($changelogPushPrNumbers.Count -gt 0) {
    Write-Host "  Changelog:     entries staged on disk; -SkipChangelogPush (push manually)" -ForegroundColor Yellow
}
else {
    Write-Host "  Changelog:     no new lane-merge lines this run" -ForegroundColor Gray
}
if ($SyncWorktreesAfter) {
    Write-Host "  Worktrees:     npm run worktrees:sync — ran" -ForegroundColor Gray
}
else {
    Write-Host "  Worktrees:     sync skipped" -ForegroundColor Gray
}
if ($SkipResetLaneBranches) {
    Write-Host "  Lane reset:    skipped (-SkipResetLaneBranches); run: npm run lane:next-cycle" -ForegroundColor Yellow
}
else {
    Write-Host "  Lane reset:    lane-worktrees-reset-for-next-cycle — ran" -ForegroundColor Gray
}
if ($ReconcileLinearFromMergedLanePrs) {
    Write-Host "  Linear reconcile: linear-complete-from-merged-prs — ran (last $ReconcileLinearMergedWithinDays days)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Next cycle: run daily full (lanes) again so agents pick up new work:" -ForegroundColor Cyan
Write-Host "  npm run daily:full:apply:lanes" -ForegroundColor White
Write-Host "  (or npm run daily:full:apply + your lane tasks)`n" -ForegroundColor DarkGray
Write-Host ""
if ($SkipResetLaneBranches) {
    Write-Host "You skipped lane branch reset. To reset lane worktrees to fresh agent/cursor-lane-N from main:" -ForegroundColor Yellow
    Write-Host "  npm run lane:next-cycle" -ForegroundColor Gray
}
