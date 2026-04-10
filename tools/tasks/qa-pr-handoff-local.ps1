param(
    [Parameter(Mandatory = $true)]
    [int]$PullRequestNumber,
    [switch]$SkipChecksWatch,
    [switch]$SkipLocalValidate,
    [switch]$SyncMainBeforeValidate,
    [switch]$NoMerge,
    [ValidateSet("squash", "merge", "rebase")]
    [string]$MergeMode = "squash",
    [string]$AgentRoot = "",
    [int]$ChecksPollMaxSeconds = 900,
    [int]$ChecksPollIntervalSeconds = 15,
    [int]$ChecksWatchMaxRounds = 8,
    [int]$ChecksWatchRetrySleepSeconds = 25
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot
. "$repoRoot\tools\tasks\load-repo-env.ps1"

function Test-GhCli {
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $gh) {
        throw "GitHub CLI (gh) not found. Install: https://cli.github.com/"
    }
}

function Resolve-AgentRootHandoff {
    if (-not [string]::IsNullOrWhiteSpace($AgentRoot)) {
        return $AgentRoot.TrimEnd('\', '/')
    }
    if (-not [string]::IsNullOrWhiteSpace($env:WHETHER_AGENT_ROOT)) {
        return $env:WHETHER_AGENT_ROOT.TrimEnd('\', '/')
    }
    return "D:\Agents\WeatherWether"
}

## `gh pr merge --delete-branch` deletes the local branch in the shared git repo; Git refuses if any
## worktree still has that branch checked out (e.g. wt-agent-cursor-lane-N on agent/cursor-lane-N).
function Release-LaneWorktreeBeforePrBranchDelete {
    param(
        [Parameter(Mandatory = $true)]
        [int]$PrNumber
    )
    $headJson = gh pr view $PrNumber --json headRefName 2>$null
    if ($LASTEXITCODE -ne 0) {
        return
    }
    $headRef = [string](($headJson | ConvertFrom-Json).headRefName)
    if ($headRef -notmatch '^agent/cursor-lane-(\d+)$') {
        return
    }
    $laneIdx = [int]$Matches[1]
    $wt = Join-Path (Resolve-AgentRootHandoff) "wt-agent-cursor-lane-$laneIdx"
    if (-not (Test-Path -LiteralPath $wt)) {
        return
    }
    git -C $wt rev-parse --git-dir *>$null
    if ($LASTEXITCODE -ne 0) {
        return
    }
    Write-Host "  Lane worktree cannot stay on $headRef while gh deletes that branch — detaching $wt at origin (same tip as main)..." -ForegroundColor DarkCyan
    $porcelain = git -C $wt status --porcelain
    if (-not [string]::IsNullOrWhiteSpace($porcelain)) {
        throw "Lane worktree $wt has uncommitted changes. Commit, stash, or discard, then re-run QA."
    }
    git -C $wt fetch origin --prune
    if ($LASTEXITCODE -ne 0) {
        throw "git fetch failed in lane worktree $wt"
    }
    $base = $null
    foreach ($b in @("main", "master")) {
        git -C $wt rev-parse "refs/remotes/origin/$b" *>$null
        if ($LASTEXITCODE -eq 0) {
            $base = $b
            break
        }
    }
    if ($null -eq $base) {
        throw "No origin/main or origin/master in lane worktree $wt"
    }
    # Cannot `git checkout main` here: branch `main` is usually already checked out in the primary
    # repo worktree. Detached HEAD at origin/<base> releases the PR branch so local delete succeeds.
    git -C $wt checkout --detach "origin/$base"
    if ($LASTEXITCODE -ne 0) {
        throw "Could not detach lane worktree $wt at origin/$base (git checkout --detach failed)."
    }
}

function Wait-PrChecksRegisteredAndWatch {
    param(
        [int]$PrNumber,
        [int]$MaxWaitSeconds,
        [int]$PollSeconds
    )
    Write-Host "[remote CI] Waiting for GitHub checks on PR #$PrNumber..."
    $deadline = (Get-Date).AddSeconds($MaxWaitSeconds)
    while ((Get-Date) -lt $deadline) {
        $json = gh pr view $PrNumber --json statusCheckRollup 2>$null
        if ($LASTEXITCODE -eq 0 -and $json) {
            $rollup = ($json | ConvertFrom-Json).statusCheckRollup
            $n = 0
            if ($null -ne $rollup) {
                $n = @($rollup).Count
            }
            if ($n -gt 0) {
                Write-Host "  $n check run(s) on PR; watching to completion..." -ForegroundColor DarkGreen
                gh pr checks $PrNumber --watch
                if ($LASTEXITCODE -ne 0) {
                    throw "PR checks failed or gh pr checks exited non-zero after watch."
                }
                return
            }
        }
        Write-Host "  No CI checks on PR yet (new PR or workflow still queuing). Retry in ${PollSeconds}s (max $MaxWaitSeconds s)..." -ForegroundColor DarkYellow
        Start-Sleep -Seconds $PollSeconds
    }
    throw "Timed out after $MaxWaitSeconds s waiting for checks on PR #$PrNumber. Confirm Actions run on pull_request, then re-run: npm run qa:pr -- -PullRequestNumber $PrNumber"
}

Write-Host "=== Local QA handoff: PR #$PullRequestNumber ===`n"
Test-GhCli

## Fail fast: local validate before waiting on GitHub (catches parse errors in seconds).
if (-not $SkipLocalValidate) {
    Write-Host "[1] Checkout PR branch and run local validate.ps1 (before remote CI)"
    $headJson = gh pr view $PullRequestNumber --json headRefName 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "gh pr view (headRefName) failed."
    }
    $headObj = $headJson | ConvertFrom-Json
    $headRef = [string]$headObj.headRefName

    $laneWtPath = $null
    if ($headRef -match '^agent/cursor-lane-(\d+)$') {
        $laneIdx = [int]$Matches[1]
        $wtCandidate = Join-Path (Resolve-AgentRootHandoff) "wt-agent-cursor-lane-$laneIdx"
        if (Test-Path -LiteralPath $wtCandidate) {
            Push-Location -LiteralPath $wtCandidate
            try {
                git rev-parse --git-dir *>$null
                if ($LASTEXITCODE -eq 0) {
                    $laneWtPath = $wtCandidate
                }
            }
            finally {
                Pop-Location
            }
        }
    }

    if ($null -ne $laneWtPath) {
        Write-Host "  Using lane worktree (branch already linked here): $laneWtPath" -ForegroundColor Cyan
        Set-Location -LiteralPath $laneWtPath
        git fetch origin --prune 2>$null
        git checkout $headRef 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "git checkout $headRef failed in lane worktree $laneWtPath."
        }
        git merge --ff-only "origin/$headRef" 2>$null
        if ($LASTEXITCODE -ne 0) {
            git merge --no-edit "origin/$headRef" 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "Could not sync origin/$headRef in lane worktree (conflicts). Fix in $laneWtPath, push, re-run."
            }
        }
    }
    else {
        gh pr checkout $PullRequestNumber
        if ($LASTEXITCODE -ne 0) {
            throw "gh pr checkout failed. If the error mentions a worktree, ensure wt-agent-cursor-lane-* exists under $(Resolve-AgentRootHandoff) for PR heads agent/cursor-lane-N."
        }
    }
    if ($SyncMainBeforeValidate) {
        Write-Host "  Merging origin/main into PR branch (conflicts → Cursor repair window)..."
        $here = (Get-Location).Path
        & "$repoRoot\tools\tasks\qa-merge-conflicts.ps1" -RepoPath $here -BaseRef "origin/main"
        if ($LASTEXITCODE -eq 2) {
            throw "Merge conflicts with origin/main — fix in the Cursor window that opened, push, then re-run: npm run qa:pr -- -PullRequestNumber $PullRequestNumber -SkipChecksWatch -SyncMainBeforeValidate"
        }
        if ($LASTEXITCODE -ne 0) {
            throw "qa-merge-conflicts.ps1 failed (exit $LASTEXITCODE)."
        }
    }
    $validateProjectPath = (Get-Location).Path
    Write-Host "  validate.ps1 using Godot project: $validateProjectPath" -ForegroundColor DarkGray
    & "$repoRoot\tools\tasks\validate.ps1" -GodotProjectPath $validateProjectPath
    Set-Location -LiteralPath $repoRoot
} else {
    Write-Host "[1] Skipped local validate (-SkipLocalValidate)"
}

if (-not $SkipChecksWatch) {
    Write-Host "`n[2] Wait for GitHub Actions (re-watch after failures so post-fix pushes can re-run CI)"
    $round = 0
    while ($true) {
        $round++
        try {
            Wait-PrChecksRegisteredAndWatch -PrNumber $PullRequestNumber -MaxWaitSeconds $ChecksPollMaxSeconds -PollSeconds $ChecksPollIntervalSeconds
            break
        } catch {
            $msg = $_.Exception.Message
            if ($round -ge $ChecksWatchMaxRounds) {
                throw
            }
            if ($msg -notmatch 'checks failed') {
                throw
            }
            Write-Host "  PR checks failed (round $round / $ChecksWatchMaxRounds). Fix, push to the PR branch, then waiting ${ChecksWatchRetrySleepSeconds}s for a new Actions run..." -ForegroundColor Yellow
            Start-Sleep -Seconds $ChecksWatchRetrySleepSeconds
        }
    }
} else {
    Write-Host "`n[2] Skipped gh pr checks --watch (-SkipChecksWatch)"
}

if (-not $NoMerge) {
    Write-Host "`n[3] Merge PR (--$MergeMode, delete branch)"
    # gh merge updates local git refs; must run from the worktree that has `main` (not a lane wt).
    Set-Location -LiteralPath $repoRoot
    Release-LaneWorktreeBeforePrBranchDelete -PrNumber $PullRequestNumber
    gh pr merge $PullRequestNumber --$MergeMode --delete-branch
    if ($LASTEXITCODE -ne 0) {
        throw "gh pr merge failed (branch protection, conflicts, or not mergeable)."
    }
    & "$repoRoot\tools\tasks\git-sync-main.ps1" -RepoRoot $repoRoot -Reason "after merge PR #$PullRequestNumber (fetch refreshes origin/main for every linked worktree)"
} else {
    Write-Host "`n[3] Skipped merge (-NoMerge) — Linear Done step skipped (merge first, then run linear:complete-from-pr with PR text)."
}

if (-not $NoMerge) {
    Write-Host "`n[4] Move Linear issue(s) to Done from PR title/body (local .env.local API key)"
    $raw = gh pr view $PullRequestNumber --json "title,body"
    if ($LASTEXITCODE -ne 0) {
        throw "gh pr view failed."
    }
    $pr = $raw | ConvertFrom-Json
    $env:PR_TITLE = [string]$pr.title
    $env:PR_BODY = if ($null -eq $pr.body) { "" } else { [string]$pr.body }
    Set-Location $repoRoot
    npm run linear:complete-from-pr
    if ($LASTEXITCODE -ne 0) {
        throw "linear:complete-from-pr failed."
    }
}

Write-Host "`n=== QA handoff complete ==="
