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
    $forcedArgs = @($prompt)
    if ($CliExe -like '*cursor-agent*') {
        $forcedArgs = @(Get-CursorAgentAutomationTrustArgs) + @($prompt)
    }
    Write-Host "Running: $CliExe in $resolvedWork (forced -CliExe; trust flags applied if path matches cursor-agent)"
    & $CliExe @forcedArgs
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
Write-Host "(Trust: default ``--trust`` for cursor-agent; CURSOR_AGENT_TRUST_ARGS / CURSOR_AGENT_NO_TRUST / CURSOR_AGENT_INTERACTIVE — see cursor-cli.ps1.)" -ForegroundColor DarkGray

$code = Invoke-CursorTerminalAgent -Prompt $prompt
exit $code
