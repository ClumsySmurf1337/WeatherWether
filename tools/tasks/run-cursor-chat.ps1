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

$exe = if ($CliExe) { $CliExe } else { Get-CursorCliExecutable }
if (-not $exe) {
    throw "Cursor CLI not found. Install Cursor CLI and ensure 'cursor' is on PATH, or set CURSOR_CLI_BIN."
}

Set-Location -LiteralPath $resolvedWork
Write-Host "Running: $exe chat <prompt> in $resolvedWork"

# Primary: `cursor chat "<prompt>"` (Cursor CLI). Legacy: `agent chat "<prompt>"`.
& $exe @("chat", $prompt)
exit $LASTEXITCODE
