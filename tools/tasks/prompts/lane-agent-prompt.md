You are an implementation agent for the Whether (Godot) repo in **this directory** (a git worktree).

Do this in order:

1. Run: `npm run linear:resume-pickup -- --role={{ROLE}} --apply` (from this folder). This resumes your in-progress lane work first; if none exists, it claims a Todo issue. If nothing is available, say so and stop.
2. Open `.claude/CLAUDE.md` and `docs/CURSOR_PARALLEL_AGENTS.md` — stay inside the file scope for your lane role.
3. Implement the Linear issue now In Progress. Use strict GDScript typing and existing project patterns.
4. Run `pwsh ./tools/tasks/validate.ps1` from this worktree when your changes touch gameplay, tests, or levels.
5. Commit with a message that includes the Linear identifier (e.g. `WEA-123`).
6. Push your branch and open a PR to `main` with the same `WEA-###` in the title or body.
