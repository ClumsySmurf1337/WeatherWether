param(
    [switch]$LevelsOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$godotPath = $null
if ($env:GODOT_PATH -and (Test-Path -LiteralPath $env:GODOT_PATH)) {
    $godotPath = $env:GODOT_PATH
}
if (-not $godotPath) {
    $cmd = Get-Command godot -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        $godotPath = $cmd.Source
    }
}
if (-not $godotPath) {
    $godotCandidates = @(
        "D:\Godot\Godot_v4.6.2-stable_win64_console.exe",
        "D:\Godot\Godot_v4.6.2-stable_win64.exe",
        "D:\Godot\Godot.exe"
    )
    $godotPath = $godotCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $godotPath) {
    throw "Godot not found. Set GODOT_PATH, add godot to PATH, or install under D:\Godot (see docs/PATHS_AND_STORAGE_POLICY.md)."
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $LevelsOnly) {
    if (Test-Path "$repoRoot\addons\gut\gut_cmdln.gd") {
        Write-Host "Importing project (GUT class_names)..."
        & $godotPath --headless --path "$repoRoot" --import --quit
        Write-Host "Running GUT tests..."
        & $godotPath --headless --path "$repoRoot" -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit
    } else {
        Write-Host "GUT not installed yet; skipping unit tests."
    }
}

Write-Host "Running level validation..."
& $godotPath --headless --path "$repoRoot" -s scripts/validate_all_levels.gd --quit
