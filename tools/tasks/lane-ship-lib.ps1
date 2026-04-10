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

        $dirty = git status --porcelain
        $hasUncommitted = -not [string]::IsNullOrWhiteSpace($dirty)
        $branch = (git rev-parse --abbrev-ref HEAD).Trim()

        if ($branch -eq "HEAD") {
            return [pscustomobject]@{
                Branch           = $branch
                HasUncommitted   = $hasUncommitted
                UnpushedCount    = 0
                NeedsShip        = $hasUncommitted
            }
        }

        $unpushed = 0
        git rev-parse --verify '@{u}' *>$null 2>&1
        if ($LASTEXITCODE -eq 0) {
            $unpushed = [int](git rev-list --count '@{u}..HEAD' 2>$null)
        }
        else {
            git fetch origin --prune 2>$null | Out-Null
            git rev-parse --verify "refs/remotes/origin/$branch" *>$null 2>&1
            if ($LASTEXITCODE -eq 0) {
                $unpushed = [int](git rev-list --count "origin/$branch..HEAD" 2>$null)
            }
            else {
                foreach ($base in @("origin/main", "origin/master")) {
                    git rev-parse --verify $base *>$null 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $unpushed = [int](git rev-list --count "$base..HEAD" 2>$null)
                        break
                    }
                }
            }
        }

        $needsShip = $hasUncommitted -or ($unpushed -gt 0)
        return [pscustomobject]@{
            Branch           = $branch
            HasUncommitted   = $hasUncommitted
            UnpushedCount    = $unpushed
            NeedsShip        = $needsShip
        }
    }
    finally {
        Pop-Location
    }
}
