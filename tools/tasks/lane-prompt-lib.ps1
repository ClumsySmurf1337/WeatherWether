Set-StrictMode -Version Latest

function Get-WeatherLaneRoleForIndex {
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 8)]
        [int]$LaneIndex
    )
    $roles = @("gameplay-programmer", "ui-developer", "level-designer")
    return $roles[($LaneIndex - 1) % $roles.Length]
}

function Get-WeatherLaneWorktreePath {
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 8)]
        [int]$LaneIndex,
        [Parameter(Mandatory)]
        [string]$AgentRoot
    )
    return (Join-Path $AgentRoot "wt-agent-cursor-lane-$LaneIndex")
}

function Build-WeatherLaneCursorLauncherNote {
    param([Parameter(Mandatory)][string]$Role)
    return @"
**Launcher:** ``linear:resume-pickup`` for role **$Role** was already run from the main repo. **``.weather-lane-issue.txt``** should list **WEA-###** — follow prompt **step 1** (skip pickup from this worktree; use **1b** only from **main** if the marker is empty).

"@
}

function Build-WeatherLaneCopilotLauncherNote {
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 8)]
        [int]$LaneIndex,
        [Parameter(Mandatory)][string]$Role,
        [Parameter(Mandatory)][string]$MainRepoRoot
    )
    $mainResolved = (Resolve-Path -LiteralPath $MainRepoRoot).Path
    $validateScript = Join-Path $mainResolved "tools\tasks\validate.ps1"
    return @"
**Copilot lane launcher (Weather Whether)**

- ``linear:resume-pickup`` for role **$Role** was **already run** from the main repo. **``.weather-lane-issue.txt``** in this worktree holds the **WEA-###** marker for shipping.
- In the numbered task list below, **step 1** tells you to **skip** re-running pickup from this worktree when **``.weather-lane-issue.txt``** has **WEA-###**; use **step 1b** from **`$mainResolved`** only if the marker is empty.
- After implementation: run **``pwsh `"$validateScript`" -GodotProjectPath (Get-Location).Path``** until green, then from **main**: **``npm run lane:ship -- -LaneIndex $LaneIndex``** or let **``npm run qa:agent``** preflight ship.

**Instruction sync:** GitHub Copilot loads root **``AGENTS.md``** and **``.github/copilot-instructions.md``** (and VS Code **instruction files** if enabled). Cursor/Claude agents use **``.claude/CLAUDE.md``** and **``.claude/agents/<role>.md``** — same expectations. On disputes, **``docs/GAME_DESIGN.md``** v2 wins.

"@
}

function Get-WeatherLaneAgentPromptText {
    param(
        [Parameter(Mandatory)][string]$MainRepoRoot,
        [Parameter(Mandatory)][string]$Role,
        [Parameter(Mandatory)][string]$LauncherNote,
        [Parameter(Mandatory)][string]$WorktreeRoot
    )
    $mainResolved = (Resolve-Path -LiteralPath $MainRepoRoot).Path
    $wtResolved = (Resolve-Path -LiteralPath $WorktreeRoot).Path
    $markerPath = Join-Path $wtResolved ".weather-lane-issue.txt"
    $templatePath = Join-Path $mainResolved "tools\tasks\prompts\lane-agent-prompt.md"
    if (-not (Test-Path -LiteralPath $templatePath)) {
        throw "Missing lane prompt template: $templatePath"
    }
    $template = Get-Content -LiteralPath $templatePath -Raw
    $body = $LauncherNote + "`n`n" + $template
    return $body.Replace("{{ROLE}}", $Role).Replace("{{MAIN_REPO}}", $mainResolved).Replace("{{WORKTREE_ROOT}}", $wtResolved).Replace("{{WEATHER_LANE_MARKER}}", $markerPath)
}
