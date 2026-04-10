You are an implementation agent for the Weather Whether (Godot) repo in **this directory** (a git worktree).

Do this in order:

1. Run: `npm run linear:resume-pickup -- --role={{ROLE}} --apply` (from this folder). This resumes your in-progress lane work first; if none exists, it claims a Todo issue. If nothing is available, say so and stop.
2. **Read the GDD first:** `docs/GAME_DESIGN.md` (v2) — authoritative mechanics and UX. Do **not** treat `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md` as the rules source; it is legacy / toolkit context only. On any conflict, **GAME_DESIGN.md wins**.
3. Then follow the **full reading order** in `.claude/CLAUDE.md` (UI_SCREENS → ASSET_MANIFEST → SPEC_DIFF → `weather-game.mdc`). Use `docs/CODE_REWRITE_PLAN.md` when your issue touches file-level rewrite targets.
4. Open `docs/CURSOR_PARALLEL_AGENTS.md` — stay inside the file scope for your lane role.
5. Implement the Linear issue now In Progress. Use strict GDScript typing and existing project patterns.
6. Run `pwsh <MAIN_REPO>/tools/tasks/validate.ps1 -GodotProjectPath (Get-Location).Path` when your changes touch gameplay, tests, or levels (`<MAIN_REPO>` is the Weather Whether repo that contains `package.json`).
7. **You are not done until** there is an **open PR to `main`** with **`WEA-###`** (or your team key) in the **title** — same id as the issue **In Progress** after step 1.

**Ship (automatic):** the lane launcher runs **`resume-pickup`** with **`--worktree-marker`** so your Linear id is stored as **`.weather-lane-issue.txt`** in this worktree. When the launcher finishes, it **auto-runs `lane-ship`** if the worktree is dirty — you do **not** need to pass **`-LinearId`** manually.

**Ship (manual — if auto-ship failed or you are shipping from a shell):** from **main** repo:

```text
npm run lane:ship -- -LaneIndex <1|2|3>
```

Or with explicit id:

```powershell
pwsh <MAIN_REPO>/tools/tasks/lane-ship.ps1 -WorktreePath (Get-Location).Path -LinearId WEA-### -MainRepoRoot <MAIN_REPO>
```

**Ship (fully manual git/gh):**

```powershell
git add -A
git status
git commit -m "WEA-###: short summary"
git push -u origin HEAD
gh pr create --base main --title "WEA-###: short summary" --body "Linear WEA-###"
```

If `gh` or push fails, report the exact error — do **not** stop after only writing files.
