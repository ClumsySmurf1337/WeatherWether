param(
    [string]$TeamKey = "WEA"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

$env:LINEAR_TEAM_KEY = $TeamKey

Write-Host "Step 1/4: Bootstrap Linear workspace..."
npm run linear:bootstrap -- --apply

$generated = Join-Path $repoRoot ".env.linear.generated"
if (-not (Test-Path $generated)) {
    throw "Expected $generated after bootstrap."
}

. "$repoRoot\tools\tasks\load-repo-env.ps1"
if (-not $env:LINEAR_API_KEY) {
    Write-Host "Step 2/4: Create .env.local (API key prompt)..."
    & "$repoRoot\tools\tasks\init-linear-env.ps1"
} else {
    Write-Host "Step 2/4: LINEAR_API_KEY already set (.env.local or environment)"
}

. "$repoRoot\tools\tasks\load-repo-env.ps1"
if (-not $env:LINEAR_API_KEY) {
    throw "LINEAR_API_KEY still missing. Run tools\tasks\init-linear-env.ps1"
}

Write-Host "Step 3/4: Seed backlog (batched, deduped, Backlog state)..."
npm run linear:seed

Write-Host "Step 4/4: Producer cycle (standup + promote + dispatch, preview)..."
npm run linear:producer

Write-Host "Linear setup complete."
Write-Host "Apply full PM cycle (promote Backlog→Todo, then dispatch): npm run linear:producer -- --apply"
Write-Host "Daily lane: pwsh ./tools/tasks/daily.ps1 -Autonomous"
