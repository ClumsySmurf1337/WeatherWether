Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

[Environment]::SetEnvironmentVariable("WHETHER_AGENT_MODE", "local", "User")
Write-Host "Set WHETHER_AGENT_MODE=local (User scope)."
Write-Host "Use Cursor IDE agent, Claude Code worktrees, and Copilot fallback."
