param(
    [string]$RepoPath = "",
    [string]$BaseRef = "origin/main",
    [switch]$NoLaunch,
    [switch]$SkipFetch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. "$PSScriptRoot\cursor-cli.ps1"

if ([string]::IsNullOrWhiteSpace($RepoPath)) {
    $RepoPath = (Get-Location).Path
}
$RepoPath = (Resolve-Path -LiteralPath $RepoPath).Path

$gitMarker = Join-Path $RepoPath ".git"
if (-not (Test-Path -LiteralPath $gitMarker)) {
    throw "Not a git repository: $RepoPath"
}

Write-Host "=== QA merge conflict repair: $RepoPath vs $BaseRef ===`n"

if (-not $SkipFetch) {
    Write-Host "[fetch] git fetch origin"
    git -C $RepoPath fetch origin
    if ($LASTEXITCODE -ne 0) {
        throw "git fetch failed."
    }
}

Write-Host "[merge] git merge $BaseRef --no-edit"
git -C $RepoPath merge $BaseRef --no-edit
if ($LASTEXITCODE -eq 0) {
    Write-Host "`nClean: merge completed (or already up to date)."
    exit 0
}

Write-Host "`nConflicts detected."
git -C $RepoPath status --short
$unmerged = @(git -C $RepoPath diff --name-only --diff-filter=U)
$unmergedText = if ($unmerged.Count -gt 0) { $unmerged -join "`n" } else { "(none listed — check git status)" }

$promptTemplatePath = Join-Path $repoRoot "tools\tasks\prompts\qa-merge-conflict-repair.md"
if (-not (Test-Path -LiteralPath $promptTemplatePath)) {
    throw "Missing prompt template: $promptTemplatePath"
}
$body = (Get-Content -LiteralPath $promptTemplatePath -Raw).Replace("{{BASEREF}}", $BaseRef)
$extra = "`n`n## Detected unmerged paths`n``````text`n$unmergedText`n```````n"
$fullPrompt = $body + $extra

$tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "whether-qa-merge-$(Get-Random).md"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($tempFile, $fullPrompt, $utf8NoBom)

if ($NoLaunch) {
    Write-Host "`nNoLaunch: prompt written to $tempFile"
    Write-Host "Run: npm run qa:repair-merge -- -RepoPath `"$RepoPath`""
    Write-Host "Or: pwsh -NoProfile -File `"$repoRoot\tools\tasks\run-cursor-chat.ps1`" -WorkDir `"$RepoPath`" -PromptFile `"$tempFile`""
    exit 1
}

$cli = Get-CursorCliExecutable
if (-not $cli) {
    throw "Cursor CLI not found (need 'cursor' on PATH or CURSOR_CLI_BIN). Prompt saved at: $tempFile"
}

Write-Host "`nLaunching Cursor CLI for conflict repair..."
Write-Host "  CLI: $cli"
Write-Host "  Prompt: $tempFile"
$runner = Join-Path $repoRoot "tools\tasks\run-cursor-chat.ps1"
Start-Process -FilePath "pwsh" -ArgumentList @(
    "-NoExit",
    "-NoProfile",
    "-File", $runner,
    "-WorkDir", $RepoPath,
    "-PromptFile", $tempFile
)

Write-Host "`nExit 2 = conflicts opened in Cursor — resolve, commit, push, then re-run your pipeline (e.g. npm run qa:pr)."
exit 2
