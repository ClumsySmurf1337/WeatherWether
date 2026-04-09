# Tool Agent Matrix

This matrix maps the same role model across tools so handoff is predictable.

| Role | Cursor Cloud/IDE | Claude Code | Copilot Chat | Codex CLI |
|---|---|---|---|---|
| Producer/PM | `linear:producer`, **`linear:pm-organize`**, **`linear:pm-assignments`** | `.claude/agents/producer.md` | `docs/PM_AGENT_LINEAR.md` | use linear scripts |
| Gameplay | Cursor rules + scope constraints | `.claude/agents/gameplay-programmer.md` | assisted review/fixes | use task scripts |
| UI | Cursor rules + mobile-first prompts | `.claude/agents/ui-developer.md` | UI pass support | use task scripts |
| Levels | level validation scripts | `.claude/agents/level-designer.md` | support only | use task scripts |
| QA | `validate.ps1`, CI, **`npm run qa:pr`**, **`npm run qa:repair-merge`**, `linear:complete-from-pr` | `.claude/agents/qa-agent.md` | bug triage | use task scripts |
| Art | prompt packs + style docs | `.claude/agents/art-pipeline.md` | asset review | n/a |
| Release Ops | workflow + checklist docs | `.claude/agents/release-ops.md` | release notes assistance | use CI templates |

## Shared Ground Rules

- Use Linear issues as source of truth.
- Move tasks through Todo -> In Progress -> In Review.
- Keep D-drive storage policy enforced.
- Keep Windows/Steam-first milestones while preserving mobile-first UX.

