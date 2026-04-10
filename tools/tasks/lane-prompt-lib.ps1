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
**Launcher:** ``linear:resume-pickup`` for role **$Role** was already run from the main repo. Skip prompt step 1 if the correct issue is already **In Progress**; otherwise run it once from this worktree.

"@
}

function Build-WeatherLaneCopilotLauncherNote {
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 8)]
        [int]$LaneIndex,
        [Parameter(Mandatory)][string]$Role
    )
    return @"
**Copilot lane launcher (Weather Whether)**

- ``linear:resume-pickup`` for role **$Role** was **already run** from the main repo. **``.weather-lane-issue.txt``** in this worktree holds the **WEA-###** marker for shipping.
- In the numbered task list below, **step 1** (resume-pickup) is **already done** unless that marker is wrong — re-run from **main** using the same ``npm run linear:resume-pickup`` command shown in step 1 if you must fix it.
- After implementation: run **``pwsh <MAIN_REPO>/tools/tasks/validate.ps1 -GodotProjectPath (Get-Location).Path``** until green, then from **main**: **``npm run lane:ship -- -LaneIndex $LaneIndex``** or let **``npm run qa:agent``** preflight ship.

**Instruction sync:** GitHub Copilot loads root **``AGENTS.md``** and **``.github/copilot-instructions.md``** (and VS Code **instruction files** if enabled). Cursor/Claude agents use **``.claude/CLAUDE.md``** and **``.claude/agents/<role>.md``** — same expectations. On disputes, **``docs/GAME_DESIGN.md``** v2 wins.

"@
}

function Get-WeatherLaneAgentPromptText {
    param(
        [Parameter(Mandatory)][string]$MainRepoRoot,
        [Parameter(Mandatory)][string]$Role,
        [Parameter(Mandatory)][string]$LauncherNote
    )
    $templatePath = Join-Path $MainRepoRoot "tools\tasks\prompts\lane-agent-prompt.md"
    if (-not (Test-Path -LiteralPath $templatePath)) {
        throw "Missing lane prompt template: $templatePath"
    }
    $template = Get-Content -LiteralPath $templatePath -Raw
    return $LauncherNote + "`n`n" + $template.Replace("{{ROLE}}", $Role)
}
