# Fallback Playbook

Use this when Cursor Cloud Agents are degraded or unavailable.

## Immediate Switch

```powershell
pwsh ./tools/dev/start-local-stack.ps1
```

## Local Agent Stack

- Cursor IDE agent for implementation.
- Claude Code worktrees for parallel tasks.
- Copilot Chat for secondary review/support.

## Operational Rules

- Keep same task boundaries as cloud execution.
- Keep commit and issue linking unchanged.
- Run `tools/tasks/validate.ps1` before handoff/merge.

## Return to Cloud

```powershell
pwsh ./tools/dev/start-cloud-stack.ps1
```

