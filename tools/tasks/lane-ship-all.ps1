param(
    [int[]]$LaneIndexes = @(1, 2, 3),
    [string]$MainRepoRoot = "",
    [string]$AgentRoot = "",
    [switch]$SkipValidate,
    [switch]$SkipLinearVerify
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($MainRepoRoot)) {
    $MainRepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$mainResolved = (Resolve-Path -LiteralPath $MainRepoRoot).Path

Write-Host ""
Write-Host "=== lane-ship-all: try ship for lane(s) $($LaneIndexes -join ', ') ===" -ForegroundColor Cyan
Write-Host "Use after agents left uncommitted or unpushed work (no PR yet).`n"

$failed = $false
foreach ($idx in $LaneIndexes) {
    Write-Host "---------- Lane $idx ----------" -ForegroundColor DarkCyan
    $splat = @{
        LaneIndex     = $idx
        MainRepoRoot  = $mainResolved
        AgentRoot     = $AgentRoot
    }
    if ($SkipValidate) {
        $splat.SkipValidate = $true
    }
    if ($SkipLinearVerify) {
        $splat.SkipLinearVerify = $true
    }
    & (Join-Path $PSScriptRoot "lane-ship.ps1") @splat
    if ($LASTEXITCODE -ne 0) {
        $failed = $true
        Write-Host "Lane $idx ship failed (exit $LASTEXITCODE)." -ForegroundColor Red
    }
    Write-Host ""
}

if ($failed) {
    exit 1
}
Write-Host "=== lane-ship-all complete ===" -ForegroundColor Green
