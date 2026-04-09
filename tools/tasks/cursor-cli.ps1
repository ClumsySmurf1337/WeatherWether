# Shared Cursor CLI resolution: prefer `cursor`, then legacy `agent` shim.
# Override: CURSOR_CLI_BIN (full path to cursor.exe) or CURSOR_AGENT_BIN.

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
