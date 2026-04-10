param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 8)]
    [int]$LaneIndex,
    [Parameter(Mandatory = $true)]
    [string]$MainRepoRoot,
    [string]$AgentRoot = "",
    [switch]$SkipCursorChat,
    [switch]$SkipAutoShip
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
    Write-Host "From repo root run: pwsh ./tools/tasks/new-agent-worktree.ps1 -BranchName agent/cursor-lane-$LaneIndex"
    exit 1
}

$mainResolved = (Resolve-Path -LiteralPath $MainRepoRoot).Path
. (Join-Path $mainResolved "tools\tasks\lane-ship-lib.ps1")

Write-Host ""
Write-Host "========== Lane $LaneIndex | $role ==========" -ForegroundColor Cyan
Write-Host "Worktree:    $wtPath"
Write-Host "Linear env:  $mainResolved (.env.local)"
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location -LiteralPath $mainResolved
$markerPath = Join-Path $wtPath ".weather-lane-issue.txt"
npm run linear:resume-pickup -- --role=$role --apply "--worktree-marker=$markerPath"

Write-Host ""
Write-Host "resume-pickup ran from main repo (reads .env.local there)." -ForegroundColor DarkGray
Write-Host ""

Set-Location -LiteralPath $wtPath

if ($SkipCursorChat) {
    Write-Host "Shell cwd is now the worktree — use Cursor Agent manually (SkipCursorChat)." -ForegroundColor Green
    Write-Host ""
    exit 0
}

. (Join-Path $mainResolved "tools\tasks\cursor-cli.ps1")
if (-not (Get-CursorAgentCliExecutable) -and -not (Get-CursorCliExecutable)) {
    Write-Warning "No cursor-agent on PATH (or CURSOR_AGENT_CLI_BIN) and no cursor CLI (CURSOR_CLI_BIN). Open Agent manually in this worktree."
    exit 0
}

$launcherNote = Build-WeatherLaneCursorLauncherNote -Role $role
$promptText = Get-WeatherLaneAgentPromptText -MainRepoRoot $mainResolved -Role $role -LauncherNote $launcherNote

Write-Host "Starting Cursor CLI agent (auto) in worktree — no terminal typing required." -ForegroundColor Yellow
$agentExe = Get-CursorAgentCliExecutable
if ($agentExe) {
    Write-Host "CLI: $agentExe (cursor-agent)" -ForegroundColor DarkGray
} else {
    $wrap = Get-CursorCliExecutable
    $sub = Get-CursorTerminalAgentSubcommand
    Write-Host "CLI: $wrap $sub (fallback; install cursor-agent for the supported entry point)" -ForegroundColor DarkGray
}
Write-Host ""

$code = Invoke-CursorTerminalAgent -Prompt $promptText

if (-not $SkipAutoShip) {
    $shipState = Get-LaneWorktreeShipState -RepoPath $wtPath
    if ($shipState.NeedsShip) {
        Write-Host ""
        Write-Host "========== Auto-ship (validate, commit if needed, push, PR) ==========" -ForegroundColor Magenta
        & "$mainResolved\tools\tasks\lane-ship.ps1" -LaneIndex $LaneIndex -MainRepoRoot $mainResolved -AgentRoot $AgentRoot
        $shipExit = $LASTEXITCODE
        if ($shipExit -ne 0) {
            Write-Host "Auto-ship failed (exit $shipExit). From main repo: npm run lane:ship -- -LaneIndex $LaneIndex" -ForegroundColor Red
            exit $shipExit
        }
    }
    else {
        Write-Host ""
        Write-Host "After agent: nothing to auto-ship (clean tree, branch not ahead of origin/main)." -ForegroundColor DarkYellow
        Write-Host "  Detail: commits ahead of main=$($shipState.CommitsAheadOfMain); uncommitted=$($shipState.HasUncommitted); ahead of lane remote=$($shipState.UnpushedCount)." -ForegroundColor DarkGray
        Write-Host "  If you wanted a new PR: confirm the agent wrote & committed files. For a fresh Linear task use daily with -ApplyProducer (``npm run daily:full:apply:lanes``). To realign branches: ``npm run lane:next-cycle`` or ``npm run worktrees:sync``." -ForegroundColor DarkGray
    }
}

exit $code
