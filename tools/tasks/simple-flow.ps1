param(
    [string]$MainRepoRoot = "",
    [string]$AgentRoot = "",
    [switch]$SkipQa
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($MainRepoRoot)) {
    $MainRepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$mainResolved = (Resolve-Path -LiteralPath $MainRepoRoot).Path

if ([string]::IsNullOrWhiteSpace($AgentRoot)) {
    $AgentRoot = $env:WHETHER_AGENT_ROOT
}
if ([string]::IsNullOrWhiteSpace($AgentRoot)) {
    $AgentRoot = "D:\Agents\WeatherWether"
}

Set-Location -LiteralPath $mainResolved

Write-Host ""
Write-Host "  WHETHER — SIMPLE FLOW (daily apply:lanes + 3 lanes parallel + qa:agent)" -ForegroundColor Cyan
Write-Host "  Repo: $mainResolved" -ForegroundColor DarkGray
Write-Host ""

Write-Host "[1/3] npm run daily:full:apply:lanes ..." -ForegroundColor Cyan
npm run daily:full:apply:lanes
if ($LASTEXITCODE -ne 0) {
    throw "daily:full:apply:lanes failed (exit $LASTEXITCODE)."
}

$scriptPath = Join-Path $mainResolved "tools\tasks\run-lane-terminal.ps1"
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Missing lane launcher: $scriptPath"
}

Write-Host "`n[2/3] Lane terminals 1–3 in parallel (output captured per lane)..." -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "whether-simple-flow-$([Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
$keepLogs = $false
try {
    $launches = @()
    foreach ($lane in @(1, 2, 3)) {
        $outLog = Join-Path $tempDir "lane${lane}-stdout.log"
        $errLog = Join-Path $tempDir "lane${lane}-stderr.log"
        $p = Start-Process -FilePath "pwsh" -ArgumentList @(
            "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $scriptPath,
            "-LaneIndex", "$lane",
            "-MainRepoRoot", $mainResolved,
            "-AgentRoot", $AgentRoot
        ) -WorkingDirectory $mainResolved -PassThru -Wait:$false -NoNewWindow `
            -RedirectStandardOutput $outLog -RedirectStandardError $errLog
        $launches += [pscustomobject]@{ Lane = $lane; Proc = $p; Out = $outLog; Err = $errLog }
    }

    $laneFailed = $false
    foreach ($x in $launches) {
        $x.Proc | Wait-Process
        $code = $x.Proc.ExitCode
        $ok = ($null -eq $code -or $code -eq 0)
        Write-Host "`n---------- Lane $($x.Lane) (exit $code) ----------" -ForegroundColor $(if ($ok) { "Green" } else { "Red" })
        if (Test-Path -LiteralPath $x.Out) {
            Get-Content -LiteralPath $x.Out -ErrorAction SilentlyContinue | Write-Host
        }
        if (Test-Path -LiteralPath $x.Err) {
            $errTxt = Get-Content -LiteralPath $x.Err -Raw -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($errTxt)) {
                Write-Host "--- stderr ---" -ForegroundColor Yellow
                Write-Host $errTxt
            }
        }
        if (-not $ok) {
            $laneFailed = $true
        }
    }

    if ($laneFailed) {
        $keepLogs = $true
        throw "One or more lane terminals failed. Logs: $tempDir"
    }
}
finally {
    if (-not $keepLogs) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Host "`nLane logs preserved under: $tempDir" -ForegroundColor Yellow
    }
}

if (-not $SkipQa) {
    Write-Host "`n[3/3] npm run qa:agent ..." -ForegroundColor Cyan
    npm run qa:agent
    if ($LASTEXITCODE -ne 0) {
        throw "qa:agent failed (exit $LASTEXITCODE)."
    }
}
else {
    Write-Host "`n[3/3] Skipped qa:agent (-SkipQa)." -ForegroundColor DarkYellow
}

Write-Host "`n=== Simple flow complete ===" -ForegroundColor Green
