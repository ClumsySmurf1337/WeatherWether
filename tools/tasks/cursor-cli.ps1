# Shared Cursor CLI resolution:
# - **Terminal agent (headless / lane scripts):** prefer standalone **`cursor-agent`** (`Get-CursorAgentCliExecutable`).
#   Override: **CURSOR_AGENT_CLI_BIN** (full path). If missing, fall back to **`cursor <subcommand>`** (default subcommand `agent`).
# - **Editor / folder open:** **`cursor`** wrapper. Override: **CURSOR_CLI_BIN** or legacy **CURSOR_AGENT_BIN** / `agent` shim.
#
# The string `chat` is not a CLI subcommand on `cursor`; `cursor chat ...` is treated like stray path args.

function Get-CursorAgentCliExecutable {
    if ($env:CURSOR_AGENT_CLI_BIN -and (Test-Path -LiteralPath $env:CURSOR_AGENT_CLI_BIN)) {
        return $env:CURSOR_AGENT_CLI_BIN.Trim()
    }
    $cursorAgentCmd = Get-Command cursor-agent -ErrorAction SilentlyContinue
    if ($cursorAgentCmd -and $cursorAgentCmd.Source) {
        return $cursorAgentCmd.Source
    }
    return $null
}

function Get-CursorCliExecutable {
    if ($env:CURSOR_CLI_BIN -and (Test-Path -LiteralPath $env:CURSOR_CLI_BIN)) {
        return $env:CURSOR_CLI_BIN.Trim()
    }
    $cursorCmd = Get-Command cursor -ErrorAction SilentlyContinue
    if ($cursorCmd -and $cursorCmd.Source) {
        return $cursorCmd.Source
    }
    if ($env:CURSOR_AGENT_BIN -and (Test-Path -LiteralPath $env:CURSOR_AGENT_BIN)) {
        return $env:CURSOR_AGENT_BIN.Trim()
    }
    $agentCmd = Get-Command agent -ErrorAction SilentlyContinue
    if ($agentCmd -and $agentCmd.Source) {
        return $agentCmd.Source
    }
    return $null
}

function Get-CursorTerminalAgentSubcommand {
    $s = $env:CURSOR_CLI_AGENT_SUBCOMMAND
    if ($s -and $s.Trim().Length -gt 0) {
        return $s.Trim()
    }
    return "agent"
}

# cursor-agent.ps1 stops for "Workspace Trust" unless you pass e.g. --trust, --yolo, or -f.
# Lane / merge scripts default to non-interactive: prepend trust flags. Opt out with CURSOR_AGENT_INTERACTIVE=1 or CURSOR_AGENT_NO_TRUST=1.
function Get-CursorAgentAutomationTrustArgs {
    if ($env:CURSOR_AGENT_INTERACTIVE -eq "1" -or $env:CURSOR_AGENT_INTERACTIVE -eq "true") {
        return @()
    }
    if ($env:CURSOR_AGENT_NO_TRUST -eq "1" -or $env:CURSOR_AGENT_NO_TRUST -eq "true") {
        return @()
    }
    $custom = $env:CURSOR_AGENT_TRUST_ARGS
    if ($null -ne $custom -and $custom.Trim().Length -gt 0) {
        return @($custom.Trim() -split '\s+')
    }
    return @("--trust")
}

function Invoke-CursorTerminalAgent([string]$Prompt) {
    $agentExe = Get-CursorAgentCliExecutable
    if ($agentExe) {
        $trust = Get-CursorAgentAutomationTrustArgs
        & $agentExe @($trust + @($Prompt))
        return $LASTEXITCODE
    }
    $exe = Get-CursorCliExecutable
    if (-not $exe) {
        throw "No terminal agent: put cursor-agent on PATH or set CURSOR_AGENT_CLI_BIN; or install cursor and set CURSOR_CLI_BIN."
    }
    $sub = Get-CursorTerminalAgentSubcommand
    $cliTrust = $env:CURSOR_CLI_AGENT_TRUST_ARGS
    $extra = @()
    if ($null -ne $cliTrust -and $cliTrust.Trim().Length -gt 0) {
        $extra = @($cliTrust.Trim() -split '\s+')
    }
    & $exe @(@($sub) + $extra + @($Prompt))
    return $LASTEXITCODE
}

function Get-CursorElectronLaunch {
    $wrapper = Get-CursorCliExecutable
    if (-not $wrapper) {
        return $null
    }
    if ($wrapper -notmatch '\.(cmd|bat)\s*$') {
        return $null
    }
    $bin = Split-Path -Path $wrapper -Parent
    $cursorExe = [System.IO.Path]::GetFullPath((Join-Path $bin '..\..\..\Cursor.exe'))
    $cliJs = [System.IO.Path]::GetFullPath((Join-Path $bin '..\out\cli.js'))
    if (-not (Test-Path -LiteralPath $cursorExe)) {
        return $null
    }
    if (-not (Test-Path -LiteralPath $cliJs)) {
        return $null
    }
    return [pscustomobject]@{
        CursorExe = $cursorExe
        CliJs     = $cliJs
        Wrapper   = $wrapper
    }
}
