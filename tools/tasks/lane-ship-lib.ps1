Set-StrictMode -Version Latest

function Get-LaneWorktreeShipState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath
    )
    Push-Location -LiteralPath $RepoPath
    try {
        git rev-parse --git-dir *>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Not a git repo: $RepoPath"
        }

        # Refresh remotes so origin/main matches GitHub (avoids false "unpushed" after merges).
        git fetch origin --prune 2>$null | Out-Null

        $dirty = git status --porcelain
        $hasUncommitted = -not [string]::IsNullOrWhiteSpace($dirty)
        $branch = (git rev-parse --abbrev-ref HEAD).Trim()

        if ($branch -eq "HEAD") {
            return [pscustomobject]@{
                Branch               = $branch
                HasUncommitted       = $hasUncommitted
                UnpushedCount        = 0
                CommitsAheadOfMain   = 0
                NeedsShip            = $hasUncommitted
            }
        }

        $unpushedToTracked = 0
        git rev-parse --verify '@{u}' *>$null 2>&1
        if ($LASTEXITCODE -eq 0) {
            $unpushedToTracked = [int](git rev-list --count '@{u}..HEAD' 2>$null)
        }
        else {
            git rev-parse --verify "refs/remotes/origin/$branch" *>$null 2>&1
            if ($LASTEXITCODE -eq 0) {
                $unpushedToTracked = [int](git rev-list --count "origin/$branch..HEAD" 2>$null)
            }
            else {
                foreach ($base in @("origin/main", "origin/master")) {
                    git rev-parse --verify $base *>$null 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $unpushedToTracked = [int](git rev-list --count "$base..HEAD" 2>$null)
                        break
                    }
                }
            }
        }

        $mainRef = $null
        foreach ($b in @("origin/main", "origin/master")) {
            git rev-parse --verify $b *>$null 2>&1
            if ($LASTEXITCODE -eq 0) {
                $mainRef = $b
                break
            }
        }

        $aheadOfMain = 0
        if ($null -ne $mainRef) {
            $aheadOfMain = [int](git rev-list --count "${mainRef}..HEAD" 2>$null)
        }

        # Ship only when there is real work: dirty tree OR commits not yet on main.
        # (Avoids treating "remote lane branch behind local tip that already equals main" as NeedsShip.)
        $needsShip = $hasUncommitted -or ($aheadOfMain -gt 0)
        if ($null -eq $mainRef) {
            $needsShip = $hasUncommitted -or ($unpushedToTracked -gt 0)
        }

        return [pscustomobject]@{
            Branch               = $branch
            HasUncommitted       = $hasUncommitted
            UnpushedCount        = $unpushedToTracked
            CommitsAheadOfMain   = $aheadOfMain
            MainRef              = $mainRef
            NeedsShip            = $needsShip
        }
    }
    finally {
        Pop-Location
    }
}
