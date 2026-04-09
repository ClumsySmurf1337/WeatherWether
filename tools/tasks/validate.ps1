param(
    [switch]$LevelsOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$godotCandidates = @(
    "D:\Godot\Godot_v4.6.2-stable_win64_console.exe",
    "D:\Godot\Godot_v4.6.2-stable_win64.exe",
    "D:\Godot\Godot.exe"
)
$godotPath = $godotCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $godotPath) {
    throw "Godot executable not found under D:\Godot."
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $LevelsOnly) {
    if (Test-Path "$repoRoot\addons\gut\gut_cmdln.gd") {
        Write-Host "Running GUT tests..."
        & $godotPath --headless --path "$repoRoot" -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit
    } else {
        Write-Host "GUT not installed yet; skipping unit tests."
    }
}

Write-Host "Running level validation..."
& $godotPath --headless --path "$repoRoot" -s scripts/validate_all_levels.gd --quit
