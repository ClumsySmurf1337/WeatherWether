Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$godotCandidates = @(
    "D:\Godot\Godot_v4.6-stable_win64.exe",
    "D:\Godot\Godot_v4.6-stable_win64_console.exe",
    "D:\Godot\Godot.exe"
)
$godotPath = $godotCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $godotPath) {
    throw "Godot executable not found under D:\Godot."
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Start-Process -FilePath $godotPath -ArgumentList "--path `"$repoRoot`""
Write-Host "Launched Godot using $godotPath"
