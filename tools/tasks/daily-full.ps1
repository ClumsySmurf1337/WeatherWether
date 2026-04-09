param(
    [switch]$ApplyProducer,
    [switch]$StrictDdrive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

. "$repoRoot\tools\tasks\load-repo-env.ps1"

Write-Host "=== Whether DAILY FULL (audit + validate + Linear PM preview) ===`n"

$skipDdrive = -not $StrictDdrive
Write-Host "[1/5] Prerequisites + D-drive policy (SkipDdriveCheck=$skipDdrive)"
& "$repoRoot\tools\tasks\daily.ps1" -SkipDdriveCheck:$skipDdrive

Write-Host "`n[2/5] npm ci (tooling)"
if (-not (Test-Path "$repoRoot\package.json")) {
    throw "package.json missing."
}
npm ci

Write-Host "`n[3/5] Optional godot-full MCP (informational)"
$gf = Join-Path $repoRoot "tools\godot-mcp-full\build\index.js"
if (-not (Test-Path $gf)) {
    Write-Host "  [info] godot-full not built — run: pwsh ./tools/install/setup-godot-mcp-full.ps1"
} else {
    Write-Host "  [ok] godot-full build present."
}

if (Test-Path "$repoRoot\.env.local") {
    Write-Host "`n[4/5] Linear — workspace status + producer cycle"
    npm run linear:status
    if ($ApplyProducer) {
        Write-Host "  Applying producer (promote + dispatch)..."
        npm run linear:producer -- --apply
    } else {
        Write-Host "  Producer dry-run only (use -ApplyProducer to promote/dispatch)."
        npm run linear:producer
    }
} else {
    Write-Host "`n[4/5] Linear skipped (no .env.local). Run: pwsh ./tools/tasks/init-linear-env.ps1"
}

Write-Host "`n[5/5] Godot validation (import + GUT + levels)"
& "$repoRoot\tools\tasks\validate.ps1"

Write-Host "`n=== DAILY FULL complete ==="
Write-Host "Next: open parallel lanes — pwsh ./tools/tasks/new-agent-worktree.ps1 -BranchName agent/your-lane"
Write-Host "Then per window: npm run linear:pickup -- --role=<role> --apply"
Write-Host "Doc: docs/DAILY.md"
