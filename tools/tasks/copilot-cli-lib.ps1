Set-StrictMode -Version Latest

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

# Non-interactive agent run (GitHub Copilot CLI). See:
# https://github.blog/ai-and-ml/github-copilot/run-multiple-agents-at-once-with-fleet-in-copilot-cli/
# https://docs.github.com/en/copilot/concepts/agents/copilot-cli/fleet
function Invoke-WeatherCopilotCliNonInteractive {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CopilotExe,
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        [switch]$UseFleet
    )
    $p = $Prompt.Trim()
    if ($UseFleet) {
        if (-not ($p.StartsWith("/fleet "))) {
            $p = "/fleet " + $p
        }
    }
    Push-Location -LiteralPath $WorkingDirectory
    try {
        Write-Host "  copilot -p <...> --no-ask-user (cwd: $WorkingDirectory)" -ForegroundColor DarkGray
        & $CopilotExe -p $p --no-ask-user
        return $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
}
