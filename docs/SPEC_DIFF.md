# Weather Whether — Spec Diff & System Rework Plan

> **Status:** Action document. Tells you exactly what changed in the design, what code needs to be rewritten, and provides the complete Linear backlog as task templates ready to seed.
>
> **Last updated:** 2026-04-10
> **Read order:** §1 (what changed) → §2 (code rewrite) → §3 (full task list) → §4 (resync instructions).

---

## 1. What changed from the original design

The original design (`docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md`) and the existing v1 backlog are based on an **instant-resolve model** with abstract terrain transformation. The new design (`docs/GAME_DESIGN.md` v2) introduces several load-bearing changes.

### Major changes (require system rework)

| # | Old | New | Impact |
|---|---|---|---|
| 1 | Cards resolve instantly on tile tap | Cards queue, then resolve in order on PLAY SEQUENCE | **All gameplay code** — input, grid manager, weather system, undo, animation |
| 2 | Win condition = "transform terrain so a path exists" (abstract) | Win condition = "character walks from START to GOAL" (literal) | **New systems**: pathfinding, character entity, walk animation, START/GOAL tile types, level data v2 |
| 3 | No loss states beyond "ran out of moves" | Five death states: drown, burn, electrocute, freeze, fall | **New systems**: death detection, death animations, level failed screen, retry flow |
| 4 | 6 terrain types | 14 terrain types | **All terrain code** — enum, sprites, interaction matrix, solver |
| 5 | Bottom nav with Home/Levels/Stats/Store | Three-button home, no nav, no stats, no store | **All UI scenes** — home, deleted screens, simplified flow |
| 6 | Grid level select | Per-world map with winding path of nodes | **New scene** — map-based level select with per-world path JSON |
| 7 | Flat-shaded 2D art direction | Pixel art (tiles) + painterly key art (worlds, hero) | **All art** — entire art direction document, asset prompts, sprite manifest |
| 8 | Move counter is a turn timer | Move counter is queue size = `available_cards.size()` | Solver, level data, HUD |
| 9 | Generic "premium with maybe IAP" | Confirmed: one-time purchase, no IAP, no ads, no live service | Release-ops scope reduction |

### Minor changes

| # | Change | Impact |
|---|---|---|
| 10 | Hint system tier 1 (free insight) and tier 2 (next move) | New hint system, solver integration |
| 11 | Save schema spec'd (one JSON, atomic write) | New SaveManager autoload |
| 12 | Settings spec'd (audio, visual, gameplay, account) | New settings scene |
| 13 | Star rating spec'd (1=clear, 2=under max, 3=at par) | Solver computes par, save tracks personal best |
| 14 | A* pathfinding rules spec'd (cardinal, walkable enum, tie-break) | New utility class |
| 15 | 22 levels per world × 6 worlds = 132 levels (was 130) | Level batches, content tracking |
| 16 | Sky is the named, gender-neutral, hooded character | Character sprite spec |
| 17 | Linear unlock confirmed (Cut the Rope style) | World map node logic |

### Removed from scope

- Stats screen
- Store screen
- Bottom nav bar
- Daily challenges
- Multiple character skins
- Hint costs (free in v1)
- STEAM as a walkable platform (v1 keeps it visual-only)

---

## 2. Code rewrite plan

The following files in `scripts/` need to change. Status as of repo snapshot 2026-04-10.

### Files to REWRITE (existing but obsolete)

| File | What's wrong | What it needs to be |
|---|---|---|
| `scripts/grid/grid_manager.gd` | 6-terrain enum, no queue, no undo, no sequence playback | 14 terrains, queue API, undo/redo stack, sequence playback hook, signals for grid_changed/card_queued/sequence_started/sequence_finished |
| `scripts/weather/weather_system.gd` | Only RAIN/SUN/FROST/FOG, no chains, mutates grid directly | All 6 cards, full interaction matrix, lightning flood-fill, wind cross effect, fog 3×3 area, **PURE function** that takes a grid copy and returns a new grid |
| `scripts/puzzle/puzzle_solver.gd` | Stub returning `(true, 0, [])` | Real BFS solver. Goal predicate: A* path exists from START to GOAL on walkable tiles. State hash key (terrain + sorted remaining cards). 200k state cap. Returns SolverResult with min_moves, path, states_explored, elapsed_ms |
| `scripts/core/game_manager.gd` | State enum only | Add level loading, queue management, sequence playback orchestration, win/lose detection |
| `scripts/animation/animation_director.gd` | Placeholder timer | Real card-to-tile tween, sequence playback orchestration, character walk animation, death animation playback |
| `scripts/main/main_root.gd` | Two-line stub | Boot into Splash → Home flow via UIManager |
| `test/test_grid_system.gd` | 2 trivial tests | Coverage for terrain enum, neighbor lookup, queue, undo, sequence playback |
| `test/test_weather_cards.gd` | 2 trivial tests | Coverage for full interaction matrix (6 cards × 14 terrains = 84 cases minimum), chain reactions, area effects |
| `test/test_puzzle_solver.gd` | Empty | Coverage for solver: trivial level, multi-step level, unsolvable level, hash collision sanity, state cap behavior |
| `test/test_save_load.gd` | Empty | Coverage for save schema, atomic write, migration, settings persistence |
| `scripts/validate_all_levels.gd` | Stub | Walks `levels/*/level_*.json`, runs solver on each, exits non-zero if any unsolvable |

### Files to CREATE (new)

| File | Purpose |
|---|---|
| `scripts/weather/weather_type.gd` | Canonical `Card` and `Terrain` enums + helpers (is_walkable, is_conductive, is_death_tile) |
| `scripts/weather/weather_card.gd` | `WeatherCard extends Resource` with type, icon, display_name, description, cost, radius |
| `scripts/level/level_data.gd` | `LevelData extends Resource` per GDD §7 |
| `scripts/level/level_loader.gd` | JSON load/save for levels (and `.tres` if needed) |
| `scripts/level/world_data.gd` | `WorldData extends Resource` containing world ID, name, mood, level list, path JSON ref |
| `scripts/level/world_loader.gd` | Loads worlds + their level lists |
| `scripts/character/character_controller.gd` | Sky's animation state machine, A* walk execution, death state triggers |
| `scripts/character/pathfinder.gd` | Pure A* over a grid+walkable predicate |
| `scripts/puzzle/puzzle_state.gd` | Immutable state for BFS (terrain + remaining_cards + moves) with hash_key() |
| `scripts/puzzle/solver_result.gd` | Result type with is_solvable, min_moves, solution, states_explored, elapsed_ms, difficulty_score() |
| `scripts/autoload/save_manager.gd` | Autoload. Loads/saves `user://save_default.json`. Atomic writes. Schema versioning. |
| `scripts/autoload/audio_manager.gd` | Autoload. Music/SFX/Ambient buses. Crossfades on world change. |
| `scripts/autoload/event_bus.gd` | Autoload. Global signals: level_started, level_completed, level_failed, card_queued, sequence_started, etc. |
| `scripts/ui/ui_manager.gd` | Scene push/pop with transitions per GDD §13 |
| `scripts/ui/ui_theme.gd` | Color tokens, font references — single source of truth for UI styling |
| `scripts/ui/screens/splash.gd` | Splash screen logic |
| `scripts/ui/screens/home.gd` | Home screen logic, save load, continue button |
| `scripts/ui/screens/world_select.gd` | 2×3 world card grid |
| `scripts/ui/screens/level_select.gd` | Per-world map with path nodes |
| `scripts/ui/screens/gameplay.gd` | The main gameplay screen — input handling, queue display, sequence playback |
| `scripts/ui/screens/level_complete.gd` | Win screen with stars |
| `scripts/ui/screens/level_failed.gd` | Lose modal |
| `scripts/ui/screens/no_path.gd` | Soft lose modal |
| `scripts/ui/screens/pause.gd` | Pause modal |
| `scripts/ui/screens/settings.gd` | Settings screen |
| `scripts/ui/popups/hint_popup.gd` | Hint modal |
| `scripts/ui/popups/confirm_sequence.gd` | Confirm modal |
| `scripts/ui/widgets/card_view.gd` | Visual representation of a single weather card (default/pressed/disabled/glow states) |
| `scripts/ui/widgets/queue_strip.gd` | The queue display widget |
| `scripts/ui/widgets/grid_view.gd` | TileMapLayer-based grid renderer |
| `scripts/ui/widgets/character_view.gd` | Character sprite visual (delegates to character_controller for state) |
| `scripts/ui/widgets/world_node.gd` | A single level node on the world map |

### Files to DELETE

None — the existing stubs become the rewrite targets.

### Project structure additions

```
scripts/
├── autoload/        # NEW
├── character/       # NEW
├── level/           # NEW
└── ui/
    ├── popups/      # NEW
    ├── screens/     # NEW
    └── widgets/     # NEW
```

`project.godot` needs autoload entries:
```
GameManager="*res://scripts/core/game_manager.gd"
SaveManager="*res://scripts/autoload/save_manager.gd"
AudioManager="*res://scripts/autoload/audio_manager.gd"
EventBus="*res://scripts/autoload/event_bus.gd"
UIManager="*res://scripts/ui/ui_manager.gd"
```

---

## 3. Full Linear backlog for system rework

This is the complete list of tasks needed to ship v1 from current state. **It replaces the existing backlog entirely.** 

Organized by phase from `docs/backlog/pm-phase-plan.json`. Each task has a title, priority, labels, acceptance criteria, and a hint at file scope (which agent role should own it).

**Counts:** 38 system tasks (rewrite + new features) + 24 level batch tasks (4 per world × 6) + 12 art/audio tasks + 8 release-ops tasks = **82 system rework tasks** (plus all the existing world content tasks the current backlog already has).

### Phase 0: Core foundation rewrite (P1, urgent)

| # | Title | Labels | Owner |
|---|---|---|---|
| 1 | `[REWRITE] Terrain enum expansion to 14 types` | Core-Engine | gameplay-programmer |
| 2 | `[REWRITE] WeatherCard Resource and canonical card enum` | Core-Engine | gameplay-programmer |
| 3 | `[REWRITE] WeatherSystem pure-function interaction matrix (6×14)` | Core-Engine, Puzzle-Design | gameplay-programmer |
| 4 | `[REWRITE] Lightning flood-fill chain through conductive tiles` | Core-Engine, Puzzle-Design | gameplay-programmer |
| 5 | `[REWRITE] Wind 3-tile cross effect for fog/steam dispersal` | Core-Engine, Puzzle-Design | gameplay-programmer |
| 6 | `[REWRITE] Fog 3×3 area effect with START/GOAL/STONE exclusion` | Core-Engine, Puzzle-Design | gameplay-programmer |
| 7 | `[CORE] GridManager v2 with queue API + undo/redo stack` | Core-Engine | gameplay-programmer |
| 8 | `[CORE] LevelData Resource (v2 schema with start/goal/cards/par)` | Core-Engine | gameplay-programmer |
| 9 | `[CORE] LevelLoader JSON read/write` | Core-Engine | gameplay-programmer |
| 10 | `[CORE] WorldData and WorldLoader for world meta + path JSON` | Core-Engine | gameplay-programmer |
| 11 | `[CORE] EventBus autoload (level_started, sequence_started, etc.)` | Core-Engine | gameplay-programmer |
| 12 | `[CORE] AudioManager autoload with Music/SFX/Ambient buses` | Core-Engine | gameplay-programmer |
| 13 | `[CORE] SaveManager autoload — schema v1 with atomic writes` | Core-Engine, QA-Testing | gameplay-programmer |
| 14 | `[CORE] GameManager state machine (BOOT/MENU/PLAYING/PAUSED/COMPLETE/FAILED)` | Core-Engine | gameplay-programmer |

**Acceptance for phase 0:** All 14 tasks merged. `npm run validate` passes. Test coverage > 80% on core systems. No references to old enum or old WeatherSystem signature anywhere in codebase.

### Phase 1: Puzzle mechanics + sequence model (P1, urgent)

| # | Title | Labels | Owner |
|---|---|---|---|
| 15 | `[MECH] Sequence queue model — players queue cards, commit on PLAY` | Core-Engine, Puzzle-Design | gameplay-programmer |
| 16 | `[MECH] Sequence playback orchestration (card-by-card resolve with anims)` | Core-Engine, UI-UX | gameplay-programmer |
| 17 | `[MECH] BFS PuzzleSolver with state hashing and 200k cap` | Puzzle-Design, QA-Testing | gameplay-programmer |
| 18 | `[MECH] PuzzleSolver goal predicate uses A* path existence` | Puzzle-Design | gameplay-programmer |
| 19 | `[MECH] SolverResult difficulty_score() and par_moves derivation` | Puzzle-Design | gameplay-programmer |
| 20 | `[MECH] A* pathfinder over walkable terrain with cardinal moves + tie-break` | Core-Engine | gameplay-programmer |
| 21 | `[MECH] Character controller — idle, walk, death state machine` | Core-Engine | gameplay-programmer |
| 22 | `[MECH] Death detection — drown/burn/fall (v1 active set)` | Core-Engine, Puzzle-Design | gameplay-programmer |
| 23 | `[MECH] Sequence undo and full-queue cancel` | Core-Engine, UI-UX | gameplay-programmer |
| 24 | `[MECH] Move counter = queue size, max enforcement` | Core-Engine | gameplay-programmer |
| 25 | `[MECH] Star rating computation (clear / under max / at par)` | Puzzle-Design | gameplay-programmer |
| 26 | `[MECH] Hint system tier 1 (insight) + tier 2 (next move from solver)` | Puzzle-Design, UI-UX | gameplay-programmer |
| 27 | `[MECH] No Path Forward soft-lose detection and recovery` | Core-Engine, UI-UX | gameplay-programmer |

### Phase 2: Levels (P2, high)

| # | Title | Labels | Owner |
|---|---|---|---|
| 28 | `[LEVEL] World 1 path layout JSON (winding map of 22 nodes)` | Level-Design | level-designer |
| 29 | `[LEVEL] World 2 path layout JSON` | Level-Design | level-designer |
| 30 | `[LEVEL] World 3 path layout JSON` | Level-Design | level-designer |
| 31 | `[LEVEL] World 4 path layout JSON` | Level-Design | level-designer |
| 32 | `[LEVEL] World 5 path layout JSON` | Level-Design | level-designer |
| 33 | `[LEVEL] World 6 path layout JSON` | Level-Design | level-designer |

Plus the 24 batch tasks `[LEVEL-DESIGN/IMPLEMENT/PLAYTEST/VALIDATE]` per world per 5-level batch — these are auto-generated by `tools/linear/backlog-outline-generator.ts` and just need that generator updated for **22 levels per world** (currently it assumes 20).

### Phase 3: UI/UX (P3, medium)

| # | Title | Labels | Owner |
|---|---|---|---|
| 34 | `[UI] UIManager autoload with push/pop transitions` | UI-UX | ui-developer |
| 35 | `[UI] UI theme tokens (colors, fonts, sizing)` | UI-UX | ui-developer |
| 36 | `[UI] Splash screen scene + auto-advance` | UI-UX | ui-developer |
| 37 | `[UI] Home screen — Continue / Select Level / Settings + progress strip` | UI-UX | ui-developer |
| 38 | `[UI] World Select screen (2×3 painterly grid)` | UI-UX | ui-developer |
| 39 | `[UI] Level Select world map with winding path nodes` | UI-UX | ui-developer |
| 40 | `[UI] Gameplay screen — header, hint banner, queue strip, grid, hand, controls` | UI-UX | ui-developer |
| 41 | `[UI] Card hand widget (tap-to-select, lift, glow)` | UI-UX | ui-developer |
| 42 | `[UI] Queue strip widget (numbered placement, drag reorder)` | UI-UX | ui-developer |
| 43 | `[UI] Grid view widget (TileMapLayer with state-driven tile changes)` | UI-UX | ui-developer |
| 44 | `[UI] Character view widget (sprite, animation state, position tween)` | UI-UX | ui-developer |
| 45 | `[UI] Level Complete screen with star reveal animation` | UI-UX | ui-developer |
| 46 | `[UI] Level Failed modal with death-specific copy and try again` | UI-UX | ui-developer |
| 47 | `[UI] No Path Forward modal` | UI-UX | ui-developer |
| 48 | `[UI] Pause modal — resume / restart / settings / quit` | UI-UX | ui-developer |
| 49 | `[UI] Settings screen — audio sliders, visual toggles, gameplay options, reset` | UI-UX | ui-developer |
| 50 | `[UI] Hint popup with optimal next move display` | UI-UX | ui-developer |
| 51 | `[UI] Confirm Sequence popup (when setting enabled)` | UI-UX | ui-developer |
| 52 | `[UI] Touch input — tap thresholds, drag detection, multi-touch ignore` | UI-UX | ui-developer |
| 53 | `[UI] Mouse + keyboard parity (click maps to tap, ESC = pause, Z = undo)` | UI-UX | ui-developer |

### Phase 4: QA + validation (P3, medium)

| # | Title | Labels | Owner |
|---|---|---|---|
| 54 | `[QA] Test coverage for WeatherSystem interaction matrix (84+ cases)` | QA-Testing | qa-agent |
| 55 | `[QA] Test coverage for PuzzleSolver (trivial / multi-step / unsolvable / cap)` | QA-Testing | qa-agent |
| 56 | `[QA] Test coverage for SaveManager schema + atomic writes + migrations` | QA-Testing | qa-agent |
| 57 | `[QA] Test coverage for A* pathfinder edge cases` | QA-Testing | qa-agent |
| 58 | `[QA] Test coverage for sequence playback (queue → resolve → walk)` | QA-Testing | qa-agent |
| 59 | `[QA] validate_all_levels.gd walks every level JSON and runs solver` | QA-Testing, Core-Engine | qa-agent |
| 60 | `[QA] CI green-on-main gate: no merge if validate or tests fail` | QA-Testing, Release-Ops | qa-agent |
| 61 | `[QA] External playtest checkpoint at 25% / 50% / 75% / 100% content` | QA-Testing | qa-agent |

### Phase 5: Art + audio (P4, low — but long lead time)

| # | Title | Labels | Owner |
|---|---|---|---|
| 62 | `[ART] Replace ART_DIRECTION.md with pixel-art + painterly key art direction` | Art-Visual | art-pipeline |
| 63 | `[ART] Replace ANIMATION_DIRECTION_2D.md with character + death + weather anim spec` | Art-Visual | art-pipeline |
| 64 | `[ART] Replace ASSET_PROMPTS_GEMINI.md with prompts for new mechanics` | Art-Visual | art-pipeline |
| 65 | `[ART] Generate 14 terrain tile sprites at 16×16 pixel art` | Art-Visual | art-pipeline |
| 66 | `[ART] Generate 6 weather card sprites with 4 states each (24 files)` | Art-Visual | art-pipeline |
| 67 | `[ART] Generate Sky character — idle/walk/cheer + 5 death anims` | Art-Visual | art-pipeline |
| 68 | `[ART] Generate weather VFX sprite sheets (rain/sun/frost/wind/lightning/fog/splash/flame)` | Art-Visual | art-pipeline |
| 69 | `[ART] Generate UI sprites — buttons (4 states), frames, icons, stars` | Art-Visual | art-pipeline |
| 70 | `[ART] Commission or generate 6 painterly world cards (240×160)` | Art-Visual | art-pipeline |
| 71 | `[ART] Commission or generate 6 painterly world backgrounds (360×800)` | Art-Visual | art-pipeline |
| 72 | `[AUDIO] Compose 6 world music loops + menu loop + win sting (8 tracks)` | Audio-Music | art-pipeline |
| 73 | `[AUDIO] Generate 30 SFX files with ElevenLabs SFX` | Audio-Music | art-pipeline |
| 74 | `[AUDIO] Record 6 ambient layers (rain, cicadas, wind, etc.)` | Audio-Music | art-pipeline |

### Phase 6: Release ops (P4, low until launch)

| # | Title | Labels | Owner |
|---|---|---|---|
| 75 | `[RELEASE] GitHub Actions: Windows + Linux + Android export matrix` | Release-Ops | release-ops |
| 76 | `[RELEASE] Steam Cloud save sync configuration` | Release-Ops | release-ops |
| 77 | `[RELEASE] Steam page draft (capsule, screenshots, trailer placeholder)` | Release-Ops, Marketing | release-ops |
| 78 | `[RELEASE] Privacy policy + EULA + acknowledgements page` | Release-Ops, Legal-Business | release-ops |
| 79 | `[RELEASE] Crash reporter integration (Sentry or similar)` | Release-Ops, QA-Testing | release-ops |
| 80 | `[RELEASE] Analytics event taxonomy + integration (PostHog free tier)` | Release-Ops, Analytics | release-ops |
| 81 | `[RELEASE] Steam Next Fest demo build (World 1 only)` | Release-Ops, Marketing | release-ops |
| 82 | `[RELEASE] Launch trailer storyboard + final cut` | Release-Ops, Marketing | release-ops |

### Producer / PM tasks (always-on)

These are not one-off — they're continuous duties for the producer agent and don't go in the seed file. They're already enforced via `tools/linear/producer-cycle.ts`.

- Daily standup
- Weekly sprint planning
- Stalled-issue check
- Risk register
- Difficulty curve audit
- External playtest scheduling

---

## 4. How to apply this and resync agents

This is the part you asked for: **where each file goes**, and **how to tell the agents to use the new spec**.

### Step A — Save the four Pass 1 docs

I wrote them inside the cloned repo at:

```
/home/claude/WeatherWether/docs/GAME_DESIGN.md
/home/claude/WeatherWether/docs/UI_SCREENS.md
/home/claude/WeatherWether/docs/ASSET_MANIFEST.md
/home/claude/WeatherWether/docs/SPEC_DIFF.md
```

You'll get them as downloadable files at the end of this message. Drop them into your repo at the **same paths** (`docs/GAME_DESIGN.md`, etc.) — no other location.

### Step B — Update the existing docs that point at the old design

Two existing files reference the old "Building Whether..." doc as the design spine. Update both to point at GAME_DESIGN.md instead:

**`.claude/CLAUDE.md`** — change the line:
```diff
- - **Design spine:** grid + weather **cards** (order + placement) + **six weathers** + **fog/uncertainty** later — `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md`.
+ - **Design spine:** Sequence model + walking character. See `docs/GAME_DESIGN.md` (v2). The old "Building Whether..." doc is superseded for game design but still valid for toolkit/pipeline info.
```

And add a section near the top:
```markdown
## Reading order for new agents

1. `docs/GAME_DESIGN.md` — game design spine (READ FIRST)
2. `docs/UI_SCREENS.md` — every screen with mockups
3. `docs/ASSET_MANIFEST.md` — sprite/audio contract
4. `docs/SPEC_DIFF.md` — what changed and the rewrite plan
5. `.cursor/rules/weather-game.mdc` — runtime architecture rules
```

**`.cursor/rules/weather-game.mdc`** — replace the entire "Core concept" section with:

```markdown
## Core concept (align all features)

Grid puzzle where the player **queues a sequence of weather cards**, then watches a pixel-art **character (Sky)** auto-walk from START to GOAL across the transformed board. Six weather cards (Rain, Sun, Frost, Wind, Lightning, Fog) interact deterministically with 14 terrain types. Win = character reaches goal. Lose = character dies on a death tile or no path exists.

**Authoritative spec:** `docs/GAME_DESIGN.md` v2. Always defer to that doc on disputes.

- Mobile-first. Touch is canonical, mouse/keyboard inherit.
- Windows/Steam first release lane.
- Strictly deterministic mechanics. No randomness in puzzle logic.
- Linear unlock per world (Cut the Rope style).
- Sequence model: queue → commit → resolve → walk.
- Pixel art tiles + painterly key art only.
- One-time premium purchase. No IAP, no ads, no live service.
```

### Step C — Replace the existing backlog templates

The existing files in `docs/backlog/` are based on the old design. Replace them by:

1. **Don't** delete them yet — first make sure your producer agent can re-seed
2. Create a new file `docs/backlog/system-rework.json` containing the 82 tasks from §3 above (use the same shape as `core-engine.json` — I'll generate this in Pass 2)
3. Update `tools/linear/seed-backlog.ts` line ~92 to include the new file
4. Update `tools/linear/backlog-outline-generator.ts` to use **22 levels per world** (currently 20) and to include the `[REWRITE]` tasks
5. Update `docs/backlog/pm-phase-plan.json` to add a `p-1-rewrite` phase that runs before `p0-core-grid`, matching label `Core-Engine` with title prefix `[REWRITE]`

### Step D — Wipe and resync Linear

Because there are 200+ existing issues and many are now obsolete, you need a wipe-and-reseed. The repo doesn't have a wipe tool yet — I'll write one in Pass 2 (`tools/linear/wipe-team.ts`). For now, the manual workflow is:

```powershell
# 1. Mark all existing open issues as Cancelled (they're obsolete)
# (manual in Linear UI: filter status != Done, select all, set status = Cancelled)
# OR write a one-shot script using mcp.linear.app

# 2. Pull the new docs
git pull

# 3. Re-seed from new templates
npm run linear:seed

# 4. Apply phase ordering and dependency edges
npm run linear:pm-prepare
npm run linear:apply-deps -- --apply

# 5. Fill the Todo queue with the new top of backlog
npm run linear:pm-feed-todo -- --apply --target=8
```

If the `wipe-team` script exists by the time you read this (it'll be in Pass 2), the first step becomes `npm run linear:wipe -- --confirm`.

### Step E — Tell currently-running agents to sync

Any agent (Cursor, Claude Code, Codex) currently in a worktree needs to know the spec changed mid-stream. Three patterns work:

**Pattern 1: Stop and resume.** Cleanest. Cancel running agents, pull main, restart with `npm run cursor:resume`. The resume flow re-reads `CLAUDE.md` and `.cursor/rules/*.mdc` on launch, so it picks up the new design spine automatically.

**Pattern 2: In-flight nudge.** If an agent is mid-task and you don't want to interrupt it, drop a comment in its terminal: `STOP. The design has changed. Pull main, read docs/GAME_DESIGN.md and docs/SPEC_DIFF.md, then re-evaluate your current task against the new spec. If your current task is now obsolete, mark the Linear issue Cancelled and pick up a new one with linear:resume-pickup.`

**Pattern 3: Do nothing, let CI catch it.** The validate gate will fail any PR that uses the old terrain enum or instant-resolve model. Slowest but lowest-effort. Not recommended — you'll burn agent compute on dead branches.

### Step F — Verify the sync

After steps A–E, run:

```powershell
# Confirm files exist
ls docs/GAME_DESIGN.md, docs/UI_SCREENS.md, docs/ASSET_MANIFEST.md, docs/SPEC_DIFF.md

# Confirm agents will read them
grep "GAME_DESIGN" .claude/CLAUDE.md
grep "GAME_DESIGN" .cursor/rules/weather-game.mdc

# Confirm Linear has the new tasks
npm run linear:pm-prepare -- --dry-run

# Confirm validate still runs (should — code hasn't changed yet)
npm run validate
```

If all four checks pass, agents are synced and ready to pick up the rewrite tasks.

---

## 5. What's in Pass 2

After you review the four Pass 1 docs and confirm the design, I'll deliver Pass 2:

1. **`docs/backlog/system-rework.json`** — the 82 tasks above as Linear seed templates ready to drop in
2. **`docs/backlog/pm-phase-plan.json`** — updated with `p-1-rewrite` phase
3. **`docs/ART_DIRECTION.md`** — replacement for the existing flat-shaded version, written for pixel art + painterly key art
4. **`docs/ANIMATION_DIRECTION_2D.md`** — replacement with character anim, death anim, weather VFX timing
5. **`docs/ASSET_PROMPTS_GEMINI.md`** — replacement with prompts tuned to the new mechanics and pixel art style
6. **`.claude/CLAUDE.md`** — updated to point at the new docs (full file, not a diff)
7. **`.cursor/rules/weather-game.mdc`** — updated rule (full file)
8. **`tools/linear/wipe-team.ts`** — new wipe tool with `--confirm` flag and `--dry-run`
9. **`package.json`** — adds `linear:wipe` script
10. **`docs/CODE_REWRITE_PLAN.md`** — file-by-file rewrite spec for the gameplay-programmer agent so it has a concrete target for each task in §2 above

That's 10 files. Mostly mechanical at that point — the design work is done in Pass 1.

---

## 6. Quick reference: where everything goes

| File from Pass 1 | Save to | Tell agents via |
|---|---|---|
| `GAME_DESIGN.md` | `docs/GAME_DESIGN.md` | `.claude/CLAUDE.md` reading order, `.cursor/rules/weather-game.mdc` |
| `UI_SCREENS.md` | `docs/UI_SCREENS.md` | Same |
| `ASSET_MANIFEST.md` | `docs/ASSET_MANIFEST.md` | Same |
| `SPEC_DIFF.md` | `docs/SPEC_DIFF.md` | Producer agent reads first |

After saving:
1. `git add docs/GAME_DESIGN.md docs/UI_SCREENS.md docs/ASSET_MANIFEST.md docs/SPEC_DIFF.md`
2. `git commit -m "docs: spec v2 — sequence model + walking character"`
3. `git push`
4. Update `.claude/CLAUDE.md` and `.cursor/rules/weather-game.mdc` per Step B
5. `git commit -am "docs: point agents at GAME_DESIGN.md v2"`
6. `git push`
7. In any active Cursor or Claude Code window: `/refresh` or restart the chat. Agents re-read the rules and CLAUDE.md on next message.
