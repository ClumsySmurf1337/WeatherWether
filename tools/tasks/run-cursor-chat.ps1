param(
    [Parameter(Mandatory = $true)]
    [string]$WorkDir,
    [Parameter(Mandatory = $true)]
    [string]$PromptFile,
    [string]$CliExe = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\cursor-cli.ps1"

if (-not (Test-Path -LiteralPath $PromptFile)) {
    throw "Prompt file not found: $PromptFile"
}
$resolvedWork = (Resolve-Path -LiteralPath $WorkDir).Path
$prompt = Get-Content -LiteralPath $PromptFile -Raw

Set-Location -LiteralPath $resolvedWork

if ($CliExe) {
    Write-Host "Running: $CliExe <prompt> in $resolvedWork (forced -CliExe)"
    & $CliExe @($prompt)
    exit $LASTEXITCODE
}

$agentExe = Get-CursorAgentCliExecutable
if ($agentExe) {
    Write-Host "Running: $agentExe <prompt> in $resolvedWork"
} else {
    $wrap = Get-CursorCliExecutable
    $sub = Get-CursorTerminalAgentSubcommand
    Write-Host "Running: $wrap $sub <prompt> in $resolvedWork (fallback; prefer cursor-agent on PATH)"
}
Write-Host "(See tools/tasks/cursor-cli.ps1: CURSOR_AGENT_CLI_BIN, CURSOR_CLI_AGENT_SUBCOMMAND.)" -ForegroundColor DarkGray

$code = Invoke-CursorTerminalAgent -Prompt $prompt
exit $code
