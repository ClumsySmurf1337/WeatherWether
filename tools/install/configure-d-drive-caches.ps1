Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$cacheRoot = "D:\Caches\WeatherWether"
$buildRoot = "D:\Builds\WeatherWether"
$agentRoot = "D:\Agents\WeatherWether"

$dirs = @(
    $cacheRoot,
    "$cacheRoot\npm",
    "$cacheRoot\pnpm",
    "$cacheRoot\pip",
    "$cacheRoot\uv",
    "$cacheRoot\temp",
    $buildRoot,
    "$buildRoot\godot",
    $agentRoot
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

[Environment]::SetEnvironmentVariable("NPM_CONFIG_CACHE", "$cacheRoot\npm", "User")
[Environment]::SetEnvironmentVariable("PNPM_HOME", "$cacheRoot\pnpm", "User")
[Environment]::SetEnvironmentVariable("PIP_CACHE_DIR", "$cacheRoot\pip", "User")
[Environment]::SetEnvironmentVariable("UV_CACHE_DIR", "$cacheRoot\uv", "User")
[Environment]::SetEnvironmentVariable("TMP", "$cacheRoot\temp", "User")
[Environment]::SetEnvironmentVariable("TEMP", "$cacheRoot\temp", "User")
[Environment]::SetEnvironmentVariable("WHETHER_BUILD_ROOT", $buildRoot, "User")
[Environment]::SetEnvironmentVariable("WHETHER_AGENT_ROOT", $agentRoot, "User")

Write-Host "Configured user cache/temp/build environment variables to D drive."
Write-Host "Open a new terminal/session to pick up updated variables."
