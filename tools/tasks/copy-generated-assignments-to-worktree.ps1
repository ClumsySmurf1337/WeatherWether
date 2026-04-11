param(
    [Parameter(Mandatory)][string]$MainRepoRoot,
    [Parameter(Mandatory)][string]$WorktreePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$mainResolved = (Resolve-Path -LiteralPath $MainRepoRoot).Path
$wtResolved = (Resolve-Path -LiteralPath $WorktreePath).Path
$src = Join-Path $mainResolved "assignments\generated"
if (-not (Test-Path -LiteralPath $src)) {
    exit 0
}
$dst = Join-Path $wtResolved "assignments\generated"
if (-not (Test-Path -LiteralPath $dst)) {
    New-Item -ItemType Directory -Path $dst -Force | Out-Null
}
Get-ChildItem -LiteralPath $src -Filter "*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dst $_.Name) -Force
}
exit 0
