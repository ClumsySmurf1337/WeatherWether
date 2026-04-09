Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

$localPath = Join-Path $repoRoot ".env.local"
$generatedPath = Join-Path $repoRoot ".env.linear.generated"

if (-not (Test-Path $generatedPath)) {
    Write-Host "Run bootstrap first: npm run linear:bootstrap -- --apply"
    exit 1
}

$apiKey = $null
if ($env:LINEAR_API_KEY) {
    $apiKey = $env:LINEAR_API_KEY
} else {
    $secure = Read-Host "Linear API Key" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $apiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
}

$genLines = Get-Content $generatedPath | Where-Object {
    $_ -notmatch '^\s*#' -and -not [string]::IsNullOrWhiteSpace($_)
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Local secrets and overrides — gitignored")
$lines.Add("LINEAR_API_KEY=$apiKey")
foreach ($line in $genLines) {
    if ($line.StartsWith("LINEAR_API_KEY=")) { continue }
    $lines.Add($line)
}

Set-Content -Path $localPath -Value ($lines -join "`n") -Encoding UTF8
Write-Host "Wrote $localPath"
