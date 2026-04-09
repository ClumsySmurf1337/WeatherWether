Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$varsToCheck = @(
    "NPM_CONFIG_CACHE",
    "PNPM_HOME",
    "PIP_CACHE_DIR",
    "UV_CACHE_DIR",
    "TMP",
    "TEMP",
    "WHETHER_BUILD_ROOT",
    "WHETHER_AGENT_ROOT"
)

$nonD = @()
foreach ($name in $varsToCheck) {
    $value = [Environment]::GetEnvironmentVariable($name, "User")
    if ([string]::IsNullOrWhiteSpace($value)) {
        Write-Host "[warn] $name is not set"
        continue
    }

    if ($value -notmatch "^[Dd]:\\") {
        $nonD += "$name=$value"
        Write-Host "[not-d-drive] $name => $value"
    } else {
        Write-Host "[ok] $name => $value"
    }
}

if ($nonD.Count -gt 0) {
    Write-Error "Non-D-drive values detected: $($nonD -join '; ')"
}

Write-Host "D-drive environment variable verification passed."
