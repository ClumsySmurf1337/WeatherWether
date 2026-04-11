You are an implementation agent for the Weather Whether (Godot) repo in **this directory** (a git worktree).

Do this in order:

1. **Linear claim (do not run pickup from this worktree unless step 1b applies):** Open **`.weather-lane-issue.txt`** in **this directory** (`{{WORKTREE_ROOT}}`). If it contains a **`WEA-###`** id, the lane launcher **already** ran `linear:resume-pickup` from **`{{MAIN_REPO}}`** (where **`.env.local`** and `LINEAR_API_KEY` live). **Do not** run `npm run linear:resume-pickup` **from this worktree** — it will fail with missing Linear env. Use that **WEA-###** for commits and PR titles and go to step 2.
   - **1b (only if** `.weather-lane-issue.txt` is **missing**, **empty**, or has **no** `WEA-` id**): `cd` to **`{{MAIN_REPO}}`** and run exactly:  
     `npm run linear:resume-pickup -- --role={{ROLE}} --apply "--worktree-marker={{WEATHER_LANE_MARKER}}"`  
     Then return to this worktree and re-read `.weather-lane-issue.txt`. If still no issue, say so and stop.
2. **Read the GDD first:** `docs/GAME_DESIGN.md` (v2) — authoritative mechanics and UX. Do **not** treat `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md` as the rules source; it is legacy / toolkit context only. On any conflict, **GAME_DESIGN.md wins**.
3. Continue the **reading order** in `.claude/CLAUDE.md` (after the GDD: `docs/UI_SCREENS.md` → `docs/ASSET_MANIFEST.md` → `docs/SPEC_DIFF.md` → `docs/ANIMATION_DIRECTION_2D.md` → `.cursor/rules/weather-game.mdc`). Use `docs/CODE_REWRITE_PLAN.md` when your issue touches file-level rewrite targets.
4. Open **`.claude/agents/{{ROLE}}.md`** — same role contract as Cursor/Claude; follow it for this lane.
5. Open `docs/CURSOR_PARALLEL_AGENTS.md` — stay inside the file scope for your lane role.
6. Implement the Linear issue that is **In Progress** (id from step 1 / `.weather-lane-issue.txt`). Use strict GDScript typing and existing project patterns.
7. **Fix errors before handoff:** after edits, run **`pwsh {{MAIN_REPO}}/tools/tasks/validate.ps1 -GodotProjectPath (Get-Location).Path`**. **Repeat until it passes** — parser errors, failing GUT tests, and level validation failures are **blockers**; do not rely on “CI will catch it.” If you use a Godot API you are unsure about, check the **stable class reference** (see `docs/GODOT_DOCS_ACCESS.md`; base **https://docs.godotengine.org/en/stable/**) so signatures match **Godot 4.x** (e.g. `Color.from_string` takes `(str, default_color)`).
8. **You are not done until** validate is **green** for this worktree **and** there is an **open PR to `main`** with **`WEA-###`** (or your team key) in the **title** — same id as in `.weather-lane-issue.txt`.

**Ship (automatic):** the lane launcher runs **`resume-pickup`** with **`--worktree-marker`** so your Linear id is stored as **`.weather-lane-issue.txt`** in this worktree. When the launcher finishes, it **auto-runs `lane-ship`** if the worktree is dirty — you do **not** need to pass **`-LinearId`** manually.

**Ship (manual — if auto-ship failed or you are shipping from a shell):** from **main** repo:

```text
npm run lane:ship -- -LaneIndex <1|2|3>
```

Or with explicit id:

```powershell
pwsh {{MAIN_REPO}}/tools/tasks/lane-ship.ps1 -WorktreePath (Get-Location).Path -LinearId WEA-### -MainRepoRoot {{MAIN_REPO}}
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
