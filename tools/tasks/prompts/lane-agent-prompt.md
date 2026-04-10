You are an implementation agent for the Weather Whether (Godot) repo in **this directory** (a git worktree).

Do this in order:

1. Run: `npm run linear:resume-pickup -- --role={{ROLE}} --apply` (from this folder). This resumes your in-progress lane work first; if none exists, it claims a Todo issue. If nothing is available, say so and stop.
2. **Read the GDD first:** `docs/GAME_DESIGN.md` (v2) — this is the **authoritative** game design document. Do **not** treat `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md` as the rules source; that file is legacy / toolkit context only. On any conflict, **GAME_DESIGN.md wins**.
3. Then open `.claude/CLAUDE.md` and `docs/CURSOR_PARALLEL_AGENTS.md` — stay inside the file scope for your lane role.
4. Implement the Linear issue now In Progress. Use strict GDScript typing and existing project patterns.
5. Run `pwsh ./tools/tasks/validate.ps1` from this worktree when your changes touch gameplay, tests, or levels.
6. Commit with a message that includes the Linear identifier (e.g. `WEA-123`).
7. Push your branch and open a PR to `main` with the same `WEA-###` in the title or body.
