param(
    [switch]$ApplyProducer,
    [switch]$StrictDdrive,
    [int]$LaneCount = 3,
    [switch]$EditorLaneTerminals,
    [switch]$SkipEditorLanePrep
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

. "$repoRoot\tools\tasks\load-repo-env.ps1"

function Test-ProbablyCursorOrVsCodeIntegratedTerminal {
    if ($env:TERM_PROGRAM -eq "vscode") {
        return $true
    }
    if ($env:VSCODE_IPC_HOOK_CLI) {
        return $true
    }
    return $false
}

$runEditorLanePrep = ($EditorLaneTerminals -or (Test-ProbablyCursorOrVsCodeIntegratedTerminal)) -and -not $SkipEditorLanePrep

Write-Host "=== Weather Whether DAILY FULL (audit + validate + Linear PM preview) ===`n"
if ($runEditorLanePrep) {
    Write-Host "(After validate: lane worktrees + integrated-terminal hint — Cursor/VS Code terminal detected or -EditorLaneTerminals.)`n"
} elseif (-not $SkipEditorLanePrep -and -not (Test-ProbablyCursorOrVsCodeIntegratedTerminal)) {
    Write-Host "(Tip: run this script from Cursor's integrated terminal for automatic lane prep, or pass -EditorLaneTerminals.)`n"
}

$skipDdrive = -not $StrictDdrive
Write-Host "[1/6] Prerequisites + D-drive policy (SkipDdriveCheck=$skipDdrive)"
& "$repoRoot\tools\tasks\daily.ps1" -SkipDdriveCheck:$skipDdrive

Write-Host "`n[2/6] npm ci (tooling)"
if (-not (Test-Path "$repoRoot\package.json")) {
    throw "package.json missing."
}
npm ci

Write-Host "`n[3/6] Optional godot-full MCP (informational)"
$gf = Join-Path $repoRoot "tools\godot-mcp-full\build\index.js"
if (-not (Test-Path $gf)) {
    Write-Host "  [info] godot-full not built — run: pwsh ./tools/install/setup-godot-mcp-full.ps1"
} else {
    Write-Host "  [ok] godot-full build present."
}

if (Test-Path "$repoRoot\.env.local") {
    Write-Host "`n[4/6] Linear — workspace status + producer cycle"
    npm run linear:status
    if ($ApplyProducer) {
        Write-Host "  Applying producer (promote + dispatch)..."
        npm run linear:producer -- --apply
    } else {
        Write-Host "  Producer dry-run only (use -ApplyProducer to promote/dispatch)."
        npm run linear:producer
    }
} else {
    Write-Host "`n[4/6] Linear skipped (no .env.local). Run: pwsh ./tools/tasks/init-linear-env.ps1"
}

Write-Host "`n[5/6] Godot validation (import + GUT + levels)"
& "$repoRoot\tools\tasks\validate.ps1"

if ($runEditorLanePrep) {
    Write-Host "`n[6/6] Lane worktrees for integrated Cursor terminals"
    if (Test-Path "$repoRoot\.env.local") {
        Write-Host "  Refreshing PM assignment markdown (In Progress prioritized)..."
        npm run linear:pm-assignments
    } else {
        Write-Host "  Skipping linear:pm-assignments (no .env.local)."
    }
    Write-Host "  Syncing existing wt-* worktrees with origin/main..."
    npm run worktrees:sync
    & "$repoRoot\tools\tasks\prepare-editor-lane-worktrees.ps1" -LaneCount $LaneCount
} else {
    Write-Host "`n[6/6] Skipped integrated lane prep (-SkipEditorLanePrep or run outside Cursor/VS Code terminal)."
}

Write-Host "`n=== DAILY FULL complete ==="
if ($runEditorLanePrep) {
    Write-Host "Next IN THIS CURSOR WINDOW:"
    Write-Host "  Ctrl+Shift+P -> Tasks: Run Task -> Weather Whether — All lane terminals (parallel)"
    Write-Host "Doc: docs/DAILY.md (cheat sheet)"
} else {
    Write-Host "Next (integrated terminals — recommended in Cursor):"
    Write-Host "  npm run cursor:resume:editor"
    Write-Host "  or re-run: pwsh ./tools/tasks/daily-full.ps1 -EditorLaneTerminals"
    Write-Host "Next (external pwsh per lane): npm run cursor:resume"
    Write-Host "Doc: docs/DAILY.md"
}
