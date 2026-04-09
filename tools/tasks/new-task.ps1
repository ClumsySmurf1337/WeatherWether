param(
    [Parameter(Mandatory = $true)][string]$TaskName,
    [string]$Scope = "scripts"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$safeName = $TaskName.ToLower().Replace(" ", "-")
$taskDir = "D:\Agents\WeatherWether\$safeName"
if (-not (Test-Path $taskDir)) {
    New-Item -Path $taskDir -ItemType Directory -Force | Out-Null
}

$template = @"
Task: $TaskName
Scope: $Scope
Rules:
- Use repo scripts for build/validate.
- Keep changes in scope boundary.
- Add tests for behavior changes.
"@

$templatePath = Join-Path $taskDir "task-brief.txt"
Set-Content -Path $templatePath -Value $template -Encoding UTF8
Write-Host "Created task brief: $templatePath"
