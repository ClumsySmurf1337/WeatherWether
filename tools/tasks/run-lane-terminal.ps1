param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 8)]
    [int]$LaneIndex,
    [Parameter(Mandatory = $true)]
    [string]$MainRepoRoot,
    [string]$AgentRoot = "",
    [switch]$SkipCursorChat
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($AgentRoot)) {
    $AgentRoot = $env:WHETHER_AGENT_ROOT
}
if ([string]::IsNullOrWhiteSpace($AgentRoot)) {
    $AgentRoot = "D:\Agents\WeatherWether"
}

$roles = @("gameplay-programmer", "ui-developer", "level-designer")
$role = $roles[($LaneIndex - 1) % $roles.Length]

$wtFolder = "wt-agent-cursor-lane-$LaneIndex"
$wtPath = Join-Path $AgentRoot $wtFolder

if (-not (Test-Path -LiteralPath $wtPath)) {
    Write-Host "Worktree missing: $wtPath" -ForegroundColor Red
    Write-Host "From repo root run: pwsh ./tools/tasks/new-agent-worktree.ps1 -BranchName agent/cursor-lane-$LaneIndex"
    exit 1
}

$mainResolved = (Resolve-Path -LiteralPath $MainRepoRoot).Path

Write-Host ""
Write-Host "========== Lane $LaneIndex | $role ==========" -ForegroundColor Cyan
Write-Host "Worktree:    $wtPath"
Write-Host "Linear env:  $mainResolved (.env.local)"
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location -LiteralPath $mainResolved
npm run linear:resume-pickup -- --role=$role --apply

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

$templatePath = Join-Path $mainResolved "tools\tasks\prompts\lane-agent-prompt.md"
if (-not (Test-Path -LiteralPath $templatePath)) {
    throw "Missing lane prompt template: $templatePath"
}
$template = Get-Content -LiteralPath $templatePath -Raw
$launcherNote = @"
**Launcher:** `linear:resume-pickup` for role **$role** was already run from the main repo. Skip prompt step 1 if the correct issue is already **In Progress**; otherwise run it once from this worktree.

"@
$promptText = $launcherNote + "`n`n" + $template.Replace("{{ROLE}}", $role)

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
exit $code
