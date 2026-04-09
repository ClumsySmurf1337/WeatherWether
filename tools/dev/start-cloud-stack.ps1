Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

[Environment]::SetEnvironmentVariable("WHETHER_AGENT_MODE", "cloud", "User")
Write-Host "Set WHETHER_AGENT_MODE=cloud (User scope)."
Write-Host "Use Cursor Cloud Agents with local fallback scripts kept ready."
