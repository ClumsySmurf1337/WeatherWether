Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$godotCandidates = @(
    "D:\Godot\Godot_v4.6-stable_win64_console.exe",
    "D:\Godot\Godot_v4.6-stable_win64.exe",
    "D:\Godot\Godot.exe"
)
$godotPath = $godotCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $godotPath) {
    throw "Godot executable not found under D:\Godot."
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$buildRoot = $env:WHETHER_BUILD_ROOT
if ([string]::IsNullOrWhiteSpace($buildRoot)) {
    $buildRoot = "D:\Builds\WeatherWether"
}
if (-not (Test-Path $buildRoot)) {
    New-Item -Path $buildRoot -ItemType Directory -Force | Out-Null
}

Write-Host "Build output root: $buildRoot"
Write-Host "Running import step..."
& $godotPath --headless --path "$repoRoot" --import --quit

Write-Host "Build scaffold complete. Add export presets in Godot for actual platform binaries."
