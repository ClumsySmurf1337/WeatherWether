Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

Write-Host "== Whether Win11 bootstrap =="
Write-Host "Repo root: $repoRoot"

$requiredRoots = @(
    "D:\Godot",
    "D:\Dev",
    "D:\Caches\WeatherWether",
    "D:\Builds\WeatherWether",
    "D:\Agents\WeatherWether"
)

foreach ($root in $requiredRoots) {
    if (-not (Test-Path $root)) {
        New-Item -Path $root -ItemType Directory -Force | Out-Null
        Write-Host "[created] $root"
    } else {
        Write-Host "[ok] $root"
    }
}

& "$repoRoot\tools\install\check-prereqs.ps1"
& "$repoRoot\tools\install\configure-d-drive-caches.ps1"

if (Test-Path "$repoRoot\package.json") {
    Write-Host "Installing node tooling dependencies..."
    npm install
}

Write-Host "Bootstrap complete."
Write-Host "Next: pwsh ./tools/tasks/daily.ps1"
