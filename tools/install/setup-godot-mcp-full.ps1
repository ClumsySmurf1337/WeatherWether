Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$target = Join-Path $repoRoot "tools/godot-mcp-full"

if (-not (Test-Path (Join-Path $target "package.json"))) {
    Write-Host "Cloning tugcantopaloglu/godot-mcp into tools/godot-mcp-full ..."
    New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
    git clone --depth 1 https://github.com/tugcantopaloglu/godot-mcp.git $target
}

Push-Location $target
try {
    Write-Host "npm install..."
    npm install
    Write-Host "npm run build..."
    npm run build
} finally {
    Pop-Location
}

$built = Join-Path $target "build/index.js"
if (-not (Test-Path $built)) {
    throw "Expected $built after build."
}

Write-Host "godot-full MCP ready. Restart Cursor; ensure .cursor/mcp.json lists godot-full."
Write-Host "Set GODOT_PATH in mcp.json to your Godot 4.6 executable if it differs from the default."
