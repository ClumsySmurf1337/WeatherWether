param(
    [Parameter(Mandatory = $true)]
    [int]$PullRequestNumber,
    [switch]$SkipChecksWatch,
    [switch]$SkipLocalValidate,
    [switch]$SyncMainBeforeValidate,
    [switch]$NoMerge,
    [ValidateSet("squash", "merge", "rebase")]
    [string]$MergeMode = "squash",
    [string]$AgentRoot = ""
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

Write-Host "=== Local QA handoff: PR #$PullRequestNumber ===`n"
Test-GhCli

if (-not $SkipChecksWatch) {
    Write-Host "[1] Waiting for GitHub checks on PR #$PullRequestNumber (remote CI)..."
    gh pr checks $PullRequestNumber --watch
    if ($LASTEXITCODE -ne 0) {
        throw "PR checks failed or gh pr checks exited non-zero."
    }
} else {
    Write-Host "[1] Skipped gh pr checks --watch (-SkipChecksWatch)"
}

if (-not $SkipLocalValidate) {
    Write-Host "`n[2] Checkout PR branch and run local validate.ps1"
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
} else {
    Write-Host "`n[2] Skipped local validate (-SkipLocalValidate)"
}

if (-not $NoMerge) {
    Write-Host "`n[3] Merge PR (--$MergeMode, delete branch)"
    # gh merge updates local git refs; must run from the worktree that has `main` (not a lane wt).
    Set-Location -LiteralPath $repoRoot
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
    $raw = gh pr view $PullRequestNumber --json title, body
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
