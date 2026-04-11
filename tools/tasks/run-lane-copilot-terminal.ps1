param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 8)]
    [int]$LaneIndex,
    [Parameter(Mandatory = $true)]
    [string]$MainRepoRoot,
    [string]$AgentRoot = "",
    [switch]$SkipAutoShip,
    [switch]$SkipCopilotRun
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
. (Join-Path $PSScriptRoot "copilot-cli-lib.ps1")

$role = Get-WeatherLaneRoleForIndex -LaneIndex $LaneIndex
$wtPath = Get-WeatherLaneWorktreePath -LaneIndex $LaneIndex -AgentRoot $AgentRoot

if (-not (Test-Path -LiteralPath $wtPath)) {
    Write-Host "Worktree missing: $wtPath" -ForegroundColor Red
    Write-Host "From main repo run: pwsh ./tools/tasks/new-agent-worktree.ps1 -BranchName agent/cursor-lane-$LaneIndex"
    exit 1
}

$mainResolved = (Resolve-Path -LiteralPath $MainRepoRoot).Path
. (Join-Path $mainResolved "tools\tasks\lane-ship-lib.ps1")

Write-Host ""
Write-Host "========== Lane $LaneIndex | $role (Copilot CLI — non-interactive) ==========" -ForegroundColor Cyan
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
# Weather Whether — Copilot CLI lane (mirror of Cursor `run-lane-terminal`)

**Lane:** $LaneIndex | **Role:** $role | **Worktree:** this folder

Read **``AGENTS.md``**, **``.github/copilot-instructions.md``**, and **``.claude/CLAUDE.md``** before coding (same contract as Cursor; role file: **``.claude/agents/$role.md``**).

---

"@
$note = Build-WeatherLaneCopilotLauncherNote -LaneIndex $LaneIndex -Role $role -MainRepoRoot $mainResolved
$body = Get-WeatherLaneAgentPromptText -MainRepoRoot $mainResolved -Role $role -LauncherNote $note -WorktreeRoot $wtPath
$full = $copilotHeader + $body

$outFile = Join-Path $wtPath "WEATHER_COPILOT_LANE_PROMPT.md"
$full | Out-File -LiteralPath $outFile -Encoding utf8
Write-Host "Wrote full task spec: $outFile" -ForegroundColor Green

$useFleet = ($env:WEATHER_COPILOT_USE_FLEET -eq "1" -or $env:WEATHER_COPILOT_USE_FLEET -eq "true")

$pointerPrompt = @"
You are the Weather Whether lane agent. NON-INTERACTIVE session: do not ask the user questions; apply reasonable defaults.

1. At this repository root (current worktree), read `AGENTS.md`, `.github/copilot-instructions.md`, `.claude/CLAUDE.md`, and `.claude/agents/$role.md` — same behavior as Cursor `cursor-agent` lanes.
2. Read `WEATHER_COPILOT_LANE_PROMPT.md` in this directory and carry out every step. **Do not** run `npm run linear:resume-pickup` from this worktree (no `.env.local` here). If `.weather-lane-issue.txt` has **WEA-###**, skip prompt step 1b; only use step 1b from the main repo if that marker is empty.
3. Run `pwsh` validate as specified in that file until it passes; then commit and push with WEA-### in the message as for Cursor lanes.

Stay within the lane file scope in `.github/copilot-instructions.md` / `docs/CURSOR_PARALLEL_AGENTS.md`. If a step cannot complete non-interactively, document the blocker in a short `COPILOT_LANE_BLOCKER.md` in this worktree and exit.
"@

$cliExit = 0
if (-not $SkipCopilotRun) {
    $cx = Get-WeatherCopilotCliExecutable
    if (-not $cx) {
        Write-Host ""
        Write-Host "ERROR: GitHub Copilot CLI (`copilot`) not found." -ForegroundColor Red
        Write-Host "  Install: https://docs.github.com/copilot/how-tos/use-copilot-agents/use-copilot-cli" -ForegroundColor Yellow
        Write-Host "  Or set WEATHER_COPILOT_CLI to the full path to the executable." -ForegroundColor Yellow
        Write-Host "  Task spec is still in: $outFile" -ForegroundColor Gray
        Write-Host "  Re-run with -SkipCopilotRun to only write the prompt file (e.g. for Copilot Chat paste)." -ForegroundColor Gray
        exit 1
    }

    if ($useFleet) {
        Write-Host "WEATHER_COPILOT_USE_FLEET: prepending /fleet to CLI prompt (orchestrator may split subtasks)." -ForegroundColor DarkYellow
        Write-Host "  See: https://docs.github.com/en/copilot/concepts/agents/copilot-cli/fleet" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "Running: copilot -p <pointer> --no-ask-user" -ForegroundColor Magenta
    Write-Host "  (Full instructions in WEATHER_COPILOT_LANE_PROMPT.md — avoids huge -p strings.)" -ForegroundColor DarkGray

    $cliExit = Invoke-WeatherCopilotCliNonInteractive -CopilotExe $cx -WorkingDirectory $wtPath -Prompt $pointerPrompt -UseFleet:$useFleet
    Write-Host "Copilot CLI exit code: $cliExit" -ForegroundColor $(if ($cliExit -eq 0) { "Green" } else { "Red" })
}
else {
    Write-Host "-SkipCopilotRun: skipped CLI. Open this worktree in Cursor/VS Code and paste from $outFile if needed." -ForegroundColor Yellow
}

if ($cliExit -ne 0 -and -not $SkipCopilotRun) {
    exit $cliExit
}

if (-not $SkipAutoShip) {
    $shipState = Get-LaneWorktreeShipState -RepoPath $wtPath
    if ($shipState.NeedsShip) {
        Write-Host ""
        Write-Host "========== Auto-ship (same as Cursor lanes) ==========" -ForegroundColor Magenta
        & "$mainResolved\tools\tasks\lane-ship.ps1" -LaneIndex $LaneIndex -MainRepoRoot $mainResolved -AgentRoot $AgentRoot
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
    else {
        Write-Host ""
        Write-Host "Auto-ship skipped: nothing to ship (clean / not ahead of origin/main)." -ForegroundColor DarkYellow
    }
}

exit 0
