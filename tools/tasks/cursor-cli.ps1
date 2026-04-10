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

# Primary model when using fallbacks. Override via CURSOR_AGENT_MODEL.
# Opus hits Pro usage caps quickly; Sonnet is the usual balance for GDScript + repo refactors.
function Get-CursorAgentModel {
    $m = $env:CURSOR_AGENT_MODEL
    if ($null -ne $m -and $m.Trim().Length -gt 0) {
        return $m.Trim()
    }
    return "claude-4.6-sonnet-medium"
}

function Split-CursorAgentModelList([string]$Raw) {
    $Raw -split '[,;]' | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 }
}

# Ordered models for cursor-agent: try each until success, or until a non-retryable failure.
# CURSOR_AGENT_MODELS overrides (comma/semicolon list). Else CURSOR_AGENT_MODEL + CURSOR_AGENT_MODEL_FALLBACKS + built-ins.
# CURSOR_AGENT_MODEL_DISABLE_FALLBACK=1 — only the primary (Get-CursorAgentModel).
function Get-CursorAgentModelChain {
    if ($env:CURSOR_AGENT_MODEL_DISABLE_FALLBACK -eq "1" -or $env:CURSOR_AGENT_MODEL_DISABLE_FALLBACK -eq "true") {
        return ,@( (Get-CursorAgentModel) )
    }
    $explicit = $env:CURSOR_AGENT_MODELS
    if ($null -ne $explicit -and $explicit.Trim().Length -gt 0) {
        return [string[]](Split-CursorAgentModelList $explicit)
    }
    $chain = New-Object System.Collections.ArrayList
    [void]$chain.Add((Get-CursorAgentModel))
    $fb = $env:CURSOR_AGENT_MODEL_FALLBACKS
    if ($null -ne $fb -and $fb.Trim().Length -gt 0) {
        foreach ($x in (Split-CursorAgentModelList $fb)) {
            [void]$chain.Add($x)
        }
    }
    else {
        foreach ($x in @("gpt-5.2", "composer-2")) {
            [void]$chain.Add($x)
        }
    }
    $out = New-Object System.Collections.ArrayList
    $seen = @{}
    foreach ($x in $chain) {
        $k = [string]$x
        if (-not $seen.ContainsKey($k)) {
            $seen[$k] = $true
            [void]$out.Add($k)
        }
    }
    return [string[]]$out.ToArray()
}

function Test-CursorAgentRetryableFailure([string]$CombinedOutput, [int]$ExitCode) {
    if ($ExitCode -eq 0) {
        return $false
    }
    $t = $CombinedOutput
    if ([string]::IsNullOrWhiteSpace($t)) {
        return $false
    }
    $patterns = @(
        'usage limit',
        "you've hit your",
        'hit your usage',
        'rate limit',
        'rate_limit',
        '\b429\b',
        'too many requests',
        'Unknown model',
        'unknown model',
        'not available for your account',
        'spend limit',
        '\bquota\b'
    )
    foreach ($p in $patterns) {
        if ($t -imatch $p) {
            return $true
        }
    }
    return $false
}

# `Get-CursorAgentAutomationTrustArgs` may return a [string] scalar (PowerShell unrolls single-element `return @("--trust")`).
# `$scalar + @($prompt)` coerces the RHS and concatenates as strings → `--trustYou are...`. Build argv with an ArrayList instead.
function Build-CursorAgentArgvWithTrustForModel([string]$Prompt, [string]$Model) {
    $list = New-Object System.Collections.ArrayList
    if ($null -ne $Model -and $Model.Trim().Length -gt 0) {
        [void]$list.Add("--model")
        [void]$list.Add($Model.Trim())
    }
    $raw = Get-CursorAgentAutomationTrustArgs
    if ($null -ne $raw) {
        if ($raw -is [System.Array]) {
            foreach ($x in $raw) {
                [void]$list.Add([string]$x)
            }
        }
        else {
            [void]$list.Add([string]$raw)
        }
    }
    [void]$list.Add($Prompt)
    return [string[]]$list.ToArray()
}

function Build-CursorAgentArgvWithTrust([string]$Prompt) {
    return (Build-CursorAgentArgvWithTrustForModel -Prompt $Prompt -Model (Get-CursorAgentModel))
}

function Invoke-CursorTerminalAgent([string]$Prompt) {
    $agentExe = Get-CursorAgentCliExecutable
    if ($agentExe) {
        $chain = Get-CursorAgentModelChain
        $attempt = 0
        $lastExit = 1
        foreach ($model in $chain) {
            $attempt++
            $cursorAgentArgv = Build-CursorAgentArgvWithTrustForModel -Prompt $Prompt -Model $model
            Write-Host "  Model ($attempt/$($chain.Length)): $model" -ForegroundColor DarkGray
            $buf = New-Object System.Collections.ArrayList
            & $agentExe @cursorAgentArgv 2>&1 | ForEach-Object {
                $line = if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.ToString() } else { "$_" }
                [void]$buf.Add($line)
                Write-Host $line
            }
            $lastExit = $LASTEXITCODE
            $text = ($buf -join "`n")
            if ($lastExit -eq 0) {
                return 0
            }
            if (-not (Test-CursorAgentRetryableFailure $text $lastExit)) {
                Write-Host "  Agent failed (exit $lastExit); not retrying with another model." -ForegroundColor Red
                return $lastExit
            }
            if ($attempt -lt $chain.Length) {
                Write-Host "  Retrying with next model in chain..." -ForegroundColor Yellow
            }
        }
        Write-Host "  All models in chain exhausted (last exit $lastExit)." -ForegroundColor Red
        return $lastExit
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
    $subArr = @($sub)
    & $exe @($subArr + $extra + @($Prompt))
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
