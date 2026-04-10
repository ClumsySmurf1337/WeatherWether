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
