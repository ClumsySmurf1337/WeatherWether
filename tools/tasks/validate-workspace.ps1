Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

. "$repoRoot\tools\tasks\load-repo-env.ps1"

Write-Host "== Workspace validation =="
& "$repoRoot\tools\install\check-prereqs.ps1"

try {
    & "$repoRoot\tools\install\verify-d-drive-usage.ps1"
} catch {
    Write-Host "[warn] D-drive temp policy: $_"
}

if (Test-Path "$repoRoot\.env.local") {
    npm run linear:status
} else {
    Write-Host "[info] No .env.local yet — Linear status skipped"
}

if (Test-Path "$repoRoot\package.json") {
    Push-Location $repoRoot
    try {
        npm run linear:seed -- --dry-run | Out-Null
        Write-Host "[ok] linear:seed --dry-run"
    } finally {
        Pop-Location
    }
}

Write-Host "Workspace validation finished."
