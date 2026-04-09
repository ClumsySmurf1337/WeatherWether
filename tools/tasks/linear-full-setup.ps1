param(
    [Parameter(Mandatory = $true)][string]$LinearApiKey,
    [string]$TeamKey = "WEA"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

$env:LINEAR_API_KEY = $LinearApiKey
$env:LINEAR_TEAM_KEY = $TeamKey

Write-Host "Step 1/3: Bootstrap Linear workspace..."
npm run linear:bootstrap -- --apply

$generated = Join-Path $repoRoot ".env.linear.generated"
if (-not (Test-Path $generated)) {
    throw "Expected $generated after bootstrap."
}

$envMap = @{}
foreach ($line in Get-Content $generated) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
        continue
    }
    $parts = $line.Split("=", 2)
    if ($parts.Count -ne 2) {
        continue
    }
    $envMap[$parts[0]] = $parts[1]
}

$env:LINEAR_TEAM_ID = $envMap["LINEAR_TEAM_ID"]
$env:LINEAR_STATE_TODO_ID = $envMap["LINEAR_STATE_TODO_ID"]
$env:LINEAR_STATE_IN_PROGRESS_ID = $envMap["LINEAR_STATE_IN_PROGRESS_ID"]
$env:LINEAR_STATE_IN_REVIEW_ID = $envMap["LINEAR_STATE_IN_REVIEW_ID"]

Write-Host "Step 2/3: Seed full backlog..."
npm run linear:seed

Write-Host "Step 3/3: Run producer preview..."
npm run linear:producer

Write-Host "Linear setup complete."
Write-Host "You can dispatch live with: npm run linear:producer -- --apply"
