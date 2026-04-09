Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-Command {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

$checks = @(
    @{ Name = "git"; Command = "git"; Required = $true },
    @{ Name = "node"; Command = "node"; Required = $true },
    @{ Name = "npm"; Command = "npm"; Required = $true },
    @{ Name = "python"; Command = "python"; Required = $true },
    @{ Name = "gh"; Command = "gh"; Required = $false },
    @{ Name = "cursor"; Command = "cursor"; Required = $false }
)

$missingRequired = @()
foreach ($check in $checks) {
    if (Test-Command -Name $check.Command) {
        Write-Host "[ok] $($check.Name)"
    } else {
        if ($check.Required) {
            $missingRequired += $check.Name
            Write-Host "[missing-required] $($check.Name)"
        } else {
            Write-Host "[missing-optional] $($check.Name)"
        }
    }
}

$godotCandidates = @(
    "D:\Godot\Godot_v4.6-stable_win64.exe",
    "D:\Godot\Godot_v4.6-stable_win64_console.exe",
    "D:\Godot\Godot.exe"
)
$godotPath = $godotCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $godotPath) {
    $missingRequired += "godot(D:\Godot\*.exe)"
    Write-Host "[missing-required] godot executable under D:\Godot"
} else {
    Write-Host "[ok] godot at $godotPath"
}

if ($missingRequired.Count -gt 0) {
    Write-Error "Missing required prerequisites: $($missingRequired -join ', ')"
}

Write-Host "Prerequisite check completed successfully."
