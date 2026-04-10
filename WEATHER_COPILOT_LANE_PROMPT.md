# Weather Whether — Copilot CLI lane (mirror of Cursor un-lane-terminal)

**Lane:** 3 | **Role:** level-designer | **Worktree:** this folder

Read **`AGENTS.md`**, **`.github/copilot-instructions.md`**, and **`.claude/CLAUDE.md`** before coding (same contract as Cursor; role file: **`.claude/agents/level-designer.md`**).

---
**Copilot lane launcher (Weather Whether)**

- `linear:resume-pickup` for role **level-designer** was **already run** from the main repo. **`.weather-lane-issue.txt`** in this worktree holds the **WEA-###** marker for shipping.
- In the numbered task list below, **step 1** (resume-pickup) is **already done** unless that marker is wrong — re-run from **main** using the same `npm run linear:resume-pickup` command shown in step 1 if you must fix it.
- After implementation: run **`pwsh <MAIN_REPO>/tools/tasks/validate.ps1 -GodotProjectPath (Get-Location).Path`** until green, then from **main**: **`npm run lane:ship -- -LaneIndex 3`** or let **`npm run qa:agent`** preflight ship.

**Instruction sync:** GitHub Copilot loads root **`AGENTS.md`** and **`.github/copilot-instructions.md`** (and VS Code **instruction files** if enabled). Cursor/Claude agents use **`.claude/CLAUDE.md`** and **`.claude/agents/<role>.md`** — same expectations. On disputes, **`docs/GAME_DESIGN.md`** v2 wins.


You are an implementation agent for the Weather Whether (Godot) repo in **this directory** (a git worktree).

Do this in order:

1. Run: `npm run linear:resume-pickup -- --role=level-designer --apply` (from this folder). This resumes your in-progress lane work first; if none exists, it claims a Todo issue. If nothing is available, say so and stop.
2. **Read the GDD first:** `docs/GAME_DESIGN.md` (v2) — authoritative mechanics and UX. Do **not** treat `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md` as the rules source; it is legacy / toolkit context only. On any conflict, **GAME_DESIGN.md wins**.
3. Continue the **reading order** in `.claude/CLAUDE.md` (after the GDD: `docs/UI_SCREENS.md` → `docs/ASSET_MANIFEST.md` → `docs/SPEC_DIFF.md` → `docs/ANIMATION_DIRECTION_2D.md` → `.cursor/rules/weather-game.mdc`). Use `docs/CODE_REWRITE_PLAN.md` when your issue touches file-level rewrite targets.
4. Open **`.claude/agents/level-designer.md`** — same role contract as Cursor/Claude; follow it for this lane.
5. Open `docs/CURSOR_PARALLEL_AGENTS.md` — stay inside the file scope for your lane role.
6. Implement the Linear issue now In Progress. Use strict GDScript typing and existing project patterns.
7. **Fix errors before handoff:** after edits, run **`pwsh <MAIN_REPO>/tools/tasks/validate.ps1 -GodotProjectPath (Get-Location).Path`** (`<MAIN_REPO>` = repo with `package.json`). **Repeat until it passes** — parser errors, failing GUT tests, and level validation failures are **blockers**; do not rely on “CI will catch it.” If you use a Godot API you are unsure about, check the **stable class reference** (see `docs/GODOT_DOCS_ACCESS.md`; base **https://docs.godotengine.org/en/stable/**) so signatures match **Godot 4.x** (e.g. `Color.from_string` takes `(str, default_color)`).
8. **You are not done until** validate is **green** for this worktree **and** there is an **open PR to `main`** with **`WEA-###`** (or your team key) in the **title** — same id as the issue **In Progress** after step 1.

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

