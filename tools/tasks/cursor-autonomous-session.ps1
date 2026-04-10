param(
    [switch]$ApplyProducer,
    [switch]$SkipNpmCi,
    [switch]$SkipValidate,
    [switch]$CreateWorktrees,
    [switch]$LaunchWTerminal,
    [switch]$SyncWorktrees,
    [switch]$SpawnAgentCli,
    [int]$LaneCount = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot
. "$repoRoot\tools\tasks\load-repo-env.ps1"
. "$repoRoot\tools\tasks\cursor-cli.ps1"

$agentRoot = $env:WHETHER_AGENT_ROOT
if ([string]::IsNullOrWhiteSpace($agentRoot)) {
    $agentRoot = "D:\Agents\WeatherWether"
}

function Get-WorktreePath([string]$branchName, [string]$root) {
    $folder = ($branchName -replace "[^a-zA-Z0-9._-]", "-").Trim("-")
    return Join-Path $root "wt-$folder"
}

Write-Host "=== Cursor autonomous session (repo + Linear + parallel lanes) ===`n"

if (-not $SkipNpmCi) {
    Write-Host "[1] npm ci"
    npm ci
} else {
    Write-Host "[1] Skipped npm ci (-SkipNpmCi)"
}

Write-Host "`n[2] Linear producer (promote + dispatch; assignees from role env vars)"
if ($ApplyProducer) {
    npm run linear:producer -- --apply
} else {
    npm run linear:producer
    Write-Host "  (Dry-run dispatch/promote. Re-run with -ApplyProducer to write Linear.)"
}

if ($SyncWorktrees) {
    Write-Host "`n[2b] Sync agent worktrees with origin/main"
    & "$repoRoot\tools\tasks\sync-agent-worktrees.ps1"
}

if (-not $SkipValidate) {
    Write-Host "`n[3] Local Godot validation (GODOT_PATH or PATH or D:\Godot fallback)"
    & "$repoRoot\tools\tasks\validate.ps1"
} else {
    Write-Host "`n[3] Skipped validate (-SkipValidate)"
}

$roles = @("gameplay-programmer", "ui-developer", "level-designer")

if ($CreateWorktrees) {
    Write-Host "`n[4] Worktrees under $agentRoot (idempotent)"
    for ($i = 1; $i -le $LaneCount; $i++) {
        $branch = "agent/cursor-lane-$i"
        $wtPath = Get-WorktreePath $branch $agentRoot
        if (-not (Test-Path $wtPath)) {
            & "$repoRoot\tools\tasks\new-agent-worktree.ps1" -BranchName $branch
        } else {
            Write-Host "  Exists: $wtPath — use -SyncWorktrees or: git -C `"$wtPath`" fetch origin && git -C `"$wtPath`" merge origin/main"
        }
    }
} else {
    Write-Host "`n[4] Skipped worktrees (-CreateWorktrees). Use new-agent-worktree.ps1 or open folders manually."
}

$teamKey = if ($env:LINEAR_TEAM_KEY) { $env:LINEAR_TEAM_KEY.Trim() } else { "WEA" }
$cliExe = Get-CursorCliExecutable
$runner = Join-Path $repoRoot "tools\tasks\run-cursor-chat.ps1"
$promptTemplatePath = Join-Path $repoRoot "tools\tasks\prompts\lane-agent-prompt.md"
$promptTemplate = if (Test-Path $promptTemplatePath) {
    Get-Content -LiteralPath $promptTemplatePath -Raw
} else {
    "Run npm run linear:resume-pickup -- --role={{ROLE}} --apply then implement per .claude/CLAUDE.md. Commit with ${teamKey}-### in message."
}

Write-Host "`n[5] Parallel lanes"
if ($SpawnAgentCli) {
    if (-not $cliExe) {
        Write-Warning "Cursor CLI not found. Install from https://cursor.com/docs/cli/installation and ensure ``cursor`` is on PATH, or set CURSOR_CLI_BIN."
    } else {
        Write-Host "  Using CLI: $cliExe (prefers ``cursor``, falls back to ``agent``)"
        Write-Host "  Spawner: $runner — if chat fails, run ``cursor --help`` and adjust run-cursor-chat.ps1`n"
    }
} else {
    Write-Host "  (Add -SpawnAgentCli to open one terminal per lane running ``cursor chat`` via run-cursor-chat.ps1.)"
}
Write-Host "  Merge conflicts: npm run qa:repair-merge -- -RepoPath `"<worktree>`""
Write-Host "  PR + Linear: put ${teamKey}-### in PR title/body; after CI green:"
Write-Host "    npm run qa:pr -- -PullRequestNumber <N>`n"

for ($i = 1; $i -le $LaneCount; $i++) {
    $branch = "agent/cursor-lane-$i"
    $wtPath = Get-WorktreePath $branch $agentRoot
    $role = $roles[($i - 1) % $roles.Length]
    Write-Host "Lane $i  ($role)"
    Write-Host "  Folder: $wtPath"
    Write-Host "  Resume/Pickup: npm run linear:resume-pickup -- --role=$role --apply"
    if ($SpawnAgentCli -and $cliExe -and (Test-Path -LiteralPath $wtPath)) {
        $promptText = $promptTemplate.Replace("{{ROLE}}", $role)
        $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "whether-lane-$i-prompt.md"
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($tempFile, $promptText, $utf8NoBom)
        Start-Process -FilePath "pwsh" -ArgumentList @(
            "-NoExit",
            "-NoProfile",
            "-File", $runner,
            "-WorkDir", $wtPath,
            "-PromptFile", $tempFile
        )
        Write-Host "  Spawned: cursor chat (prompt: $tempFile)"
    }
    Write-Host ""
}

if ($LaunchWTerminal -and -not $SpawnAgentCli) {
    $wtCmd = Get-Command wt.exe -ErrorAction SilentlyContinue
    if (-not $wtCmd) {
        Write-Warning "wt.exe not found. Install Windows Terminal or open folders manually."
    } else {
        $wtArgs = @("-w", "0")
        for ($i = 1; $i -le $LaneCount; $i++) {
            $branch = "agent/cursor-lane-$i"
            $wtPath = Get-WorktreePath $branch $agentRoot
            if (-not (Test-Path $wtPath)) {
                Write-Warning "Missing worktree: $wtPath — run with -CreateWorktrees first."
                continue
            }
            $role = $roles[($i - 1) % $roles.Length]
            $pickup = "npm run linear:resume-pickup -- --role=$role --apply"
            if ($wtArgs.Count -gt 2) {
                $wtArgs += ";"
            }
            $wtArgs += @("new-tab", "-d", $wtPath, "pwsh", "-NoExit", "-NoProfile", "-c", $pickup)
        }
        if ($wtArgs.Count -gt 2) {
            Write-Host "Launching Windows Terminal tabs..."
            Start-Process -FilePath $wtCmd.Source -ArgumentList $wtArgs
        }
    }
}

Write-Host "Docs: docs/CURSOR_CLI_AND_WORKTREES.md, docs/DAILY.md, docs/GITHUB_AUTOMERGE.md"
