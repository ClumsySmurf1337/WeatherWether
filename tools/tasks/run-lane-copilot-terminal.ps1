param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 8)]
    [int]$LaneIndex,
    [Parameter(Mandatory = $true)]
    [string]$MainRepoRoot,
    [string]$AgentRoot = "",
    [switch]$AutoShip,
    [switch]$SkipCopilotCli
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($AgentRoot)) {
    $AgentRoot = $env:WHETHER_AGENT_ROOT
}
if ([string]::IsNullOrWhiteSpace($AgentRoot)) {
    $AgentRoot = "D:\Agents\WeatherWether"
}

. (Join-Path $PSScriptRoot "lane-prompt-lib.ps1")

$role = Get-WeatherLaneRoleForIndex -LaneIndex $LaneIndex
$wtPath = Get-WeatherLaneWorktreePath -LaneIndex $LaneIndex -AgentRoot $AgentRoot

if (-not (Test-Path -LiteralPath $wtPath)) {
    Write-Host "Worktree missing: $wtPath" -ForegroundColor Red
    Write-Host "From main repo run: pwsh ./tools/tasks/new-agent-worktree.ps1 -BranchName agent/cursor-lane-$LaneIndex"
    exit 1
}

$mainResolved = (Resolve-Path -LiteralPath $MainRepoRoot).Path
. (Join-Path $mainResolved "tools\tasks\lane-ship-lib.ps1")

function Get-WeatherCopilotCliExecutable {
    if ($env:WEATHER_COPILOT_CLI -and (Test-Path -LiteralPath $env:WEATHER_COPILOT_CLI)) {
        return $env:WEATHER_COPILOT_CLI.Trim()
    }
    $cmd = Get-Command copilot -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }
    return $null
}

Write-Host ""
Write-Host "========== Lane $LaneIndex | $role (Copilot path) ==========" -ForegroundColor Cyan
Write-Host "Worktree:    $wtPath"
Write-Host "Linear env:  $mainResolved (.env.local)"
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location -LiteralPath $mainResolved
$markerPath = Join-Path $wtPath ".weather-lane-issue.txt"
npm run linear:resume-pickup -- --role=$role --apply "--worktree-marker=$markerPath"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "resume-pickup ran from main repo (reads .env.local there)." -ForegroundColor DarkGray
Write-Host ""

Set-Location -LiteralPath $wtPath

$copilotHeader = @"
# Weather Whether — Copilot lane session

**Lane:** $LaneIndex | **Role:** $role | **Worktree:** this folder

Read **``.github/copilot-instructions.md``** at the repo root before making changes (instruction-file sync with Claude/Cursor).

---

"@
$note = Build-WeatherLaneCopilotLauncherNote -LaneIndex $LaneIndex -Role $role
$body = Get-WeatherLaneAgentPromptText -MainRepoRoot $mainResolved -Role $role -LauncherNote $note
$full = $copilotHeader + $body

$outFile = Join-Path $wtPath "WEATHER_COPILOT_LANE_PROMPT.md"
$full | Out-File -LiteralPath $outFile -Encoding utf8

Write-Host "Wrote prompt file:" -ForegroundColor Green
Write-Host "  $outFile" -ForegroundColor White
Write-Host ""
Write-Host "--- DeedWise-style Copilot Chat (recommended) ---" -ForegroundColor Yellow
Write-Host "  1. Open this worktree in VS Code or Cursor (**File > Open Folder** -> $wtPath)." -ForegroundColor White
Write-Host "  2. Open **GitHub Copilot Chat** (e.g. Ctrl+Shift+I in VS Code) -> **Agent** mode." -ForegroundColor White
Write-Host "  3. Add context: **@workspace** or attach **WEATHER_COPILOT_LANE_PROMPT.md** + **.github/copilot-instructions.md**." -ForegroundColor White
Write-Host "  4. Paste the contents of WEATHER_COPILOT_LANE_PROMPT.md (or ask Copilot to read that file)." -ForegroundColor White
Write-Host ""
Write-Host "--- Optional: GitHub Copilot CLI (experimental) ---" -ForegroundColor DarkYellow
Write-Host "  Set WEATHER_COPILOT_CLI_RUN=1 and install **copilot** on PATH (or WEATHER_COPILOT_CLI=full path)." -ForegroundColor Gray
Write-Host "  See: https://docs.github.com/copilot/how-tos/use-copilot-agents/use-copilot-cli" -ForegroundColor DarkGray
Write-Host ""

$cliExit = 0
if (-not $SkipCopilotCli -and ($env:WEATHER_COPILOT_CLI_RUN -eq "1" -or $env:WEATHER_COPILOT_CLI_RUN -eq "true")) {
    $cx = Get-WeatherCopilotCliExecutable
    if ($cx) {
        Write-Host "Running Copilot CLI: $cx" -ForegroundColor Magenta
        $raw = Get-Content -LiteralPath $outFile -Raw
        & $cx -p $raw
        $cliExit = $LASTEXITCODE
        Write-Host "Copilot CLI exited: $cliExit" -ForegroundColor DarkGray
    }
    else {
        Write-Warning "WEATHER_COPILOT_CLI_RUN is set but copilot executable not found. Install CLI or set WEATHER_COPILOT_CLI."
    }
}

if ($AutoShip) {
    $shipState = Get-LaneWorktreeShipState -RepoPath $wtPath
    if ($shipState.NeedsShip) {
        Write-Host ""
        Write-Host "========== Auto-ship (-AutoShip) ==========" -ForegroundColor Magenta
        & "$mainResolved\tools\tasks\lane-ship.ps1" -LaneIndex $LaneIndex -MainRepoRoot $mainResolved -AgentRoot $AgentRoot
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
    else {
        Write-Host ""
        Write-Host "Auto-ship skipped: nothing to ship (same rules as Cursor lanes)." -ForegroundColor DarkYellow
    }
}
else {
    Write-Host "Auto-ship is **off** for Copilot lanes (finish in Chat/CLI, then ``npm run lane:ship`` or ``npm run qa:agent``)." -ForegroundColor DarkGray
}

if ($cliExit -ne 0) {
    exit $cliExit
}
exit 0
