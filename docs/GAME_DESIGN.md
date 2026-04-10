# Weather Whether — Game Design Document v2

> **Status:** Authoritative design spine. Supersedes `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md` for game design. Toolkit and pipeline guidance in that file remain valid.
>
> **Last updated:** 2026-04-10
> **Owner:** Game design / producer agent
> **Version:** 2.0 (sequence model + walking character)

---

## 1. Premise

Weather Whether is a single-player, grid-based puzzle game in which the player **queues a sequence of weather actions** to transform a tile board, then watches a pixel-art **character walk a path** through the transformed board to a goal flag. Six weather types — **Rain, Sun, Frost, Wind, Lightning, Fog** — interact with terrain in deterministic, order-dependent ways. The fun is in deciding *whether* to deploy each card and *in what order*.

The wordplay in the title is the design pillar: every level is a decision about *whether* to use this weather here, *whether* to commit a sequence, *whether* the fog is hiding a problem you can't solve. The decisions belong to the player; the consequences are the character's.

Ship target: Steam first, then Android, then iOS. Premium one-time purchase, no ads, no IAP, no live service.

---

## 2. Design pillars

These rules win every feature debate. If a proposed feature violates a pillar, it goes to Icebox.

1. **One clear insight per level.** Every puzzle teaches or tests exactly one idea. Stacking three mechanics for "depth" is a failure mode, not a feature.
2. **Determinism above all.** Same starting board + same card sequence = identical result, every time. No randomness in puzzle logic. Particle randomness is fine.
3. **The character is the heart.** The player solves problems on behalf of the character. Their walk-out animation is the payoff for the entire level. Loss states are sad, never punishing.
4. **Touch-first, mouse-equal.** Every interaction works with one thumb on a phone. Mouse and keyboard inherit from touch, never the reverse.
5. **No dead ends.** Players can always undo, always restart, always hint. Never trap them in a board state they can't recover from.

---

## 3. Core gameplay loop

The full loop, from tap to win:

```
┌─ Player taps a level on the world map
│
├─ Level loads:
│   • Board renders with starting terrain
│   • Character spawns on START tile, idles
│   • Card hand fills with the level's available weather cards
│   • Move counter shows max moves allowed
│   • Goal hint banner shows the level objective
│
├─ Planning phase (the sequence model):
│   • Player taps a weather card → card "lifts" and is selected
│   • Player taps a grid tile → a numbered ghost appears showing
│     where this card will land (1, 2, 3...)
│   • Card moves to the queue strip above the hand
│   • Tile preview updates to show what the BOARD WILL LOOK LIKE
│     after this card resolves (semi-transparent overlay)
│   • Player can tap any queued card to remove it from the queue
│   • Player can drag queued cards to reorder them
│   • Player can tap UNDO to remove the last queued card
│
├─ Player commits:
│   • Player taps PLAY SEQUENCE button
│   • CONFIRM SEQUENCE popup if level is "deluxe" difficulty (optional)
│   • Cards animate one-by-one from the queue onto their target tiles
│   • Each card triggers its weather effect (~300ms animation)
│   • Tile state mutations cascade visibly
│
├─ Walk phase:
│   • After all cards resolve, character begins walking
│   • A* pathfinder finds shortest path from START to GOAL on
│     walkable tiles (computed once, with the post-sequence board)
│   • Character walks tile-by-tile, ~250ms per step
│   • Camera follows if board is larger than viewport
│   • Player can tap SPEED UP to 2x walk speed
│
└─ Resolution:
    • WIN: character reaches goal → walk pose → level complete screen
    • LOSE: character dies on a tile → loss animation → try again
    • SOFT LOSE: no path exists → "Out of moves" popup
```

This loop is the entire game. Everything else (menus, save, audio) supports it.

### Why the sequence model

A previous draft used an instant-resolve model: every card fired the moment you tapped a tile. We replaced it with the sequence model because:

- **It earns the title.** "Whether" is about commitment under uncertainty. You stage a plan, then commit. Instant resolve is just placement.
- **It's safer for players.** Mistakes happen during planning, not during play. You can stage 8 cards and unstage them all without consequence.
- **It validates against the solver.** The solver also produces a sequence; the player's queue is directly comparable to the optimal solution.
- **It produces a moment.** "Hit play and watch your plan unfold" is a satisfying beat. Instant resolve has no beat.
- **It matches the mockups.** The PLAY SEQUENCE button in your art is canonical.

---

## 4. The character

Every level has exactly one character. The character is the player's avatar but **does not move during the planning phase** — the character is a passenger inside the board the player is sculpting.

### Identity

- Visual: small (16×16 or 24×24 pixel) hooded figure, gender-neutral, expressive silhouette. Default name: **Sky**.
- Personality: curious, brave, slightly clumsy. Shown through idle bobs, occasional looks at the player, surprise reactions to weather.
- No dialogue, no story text. Personality is animation-only. Like Baba.

### States

| State | Trigger | Anim length | Notes |
|---|---|---|---|
| `idle` | Default during planning | 4 frames, looped, ~500ms cycle | Subtle bob, occasional blink |
| `surprised` | Card placed adjacent | 2 frames, one-shot | Reaction beat, sells player input |
| `walk_n` `walk_s` `walk_e` `walk_w` | During walk phase | 4 frames each, looped, ~250ms cycle | One animation per cardinal direction |
| `cheer` | Reaches goal | 6 frames, one-shot | Arms raised, jumps once |
| `drown` | Steps into unbridged water | 5 frames, one-shot | Splash particles, sinks below tile |
| `burn` | Steps onto SCORCHED or fire-spreading tile | 6 frames, one-shot | Flame particles, ash silhouette flash |
| `electrocute` | Standing on conductive tile during lightning chain | 4 frames, one-shot | White flash + skeleton-flicker |
| `freeze` | Caught in frost effect on own tile | 5 frames, one-shot | Ice crystals grow up, becomes statue |
| `fall` | Walks into EMPTY tile or off grid edge | 4 frames, one-shot | Drops below grid plane |

### Pathfinding

When the player commits a sequence, after all cards resolve, the game runs **A\*** on the post-sequence board. The character walks the resulting shortest path. If there is no path, the character does NOT move — instead the OUT OF MOVES popup appears immediately.

A\* rules:
- Cardinal movement only (no diagonals)
- Walkable tiles: `DRY_GRASS`, `WET_GRASS`, `ICE`, `MUD`, `SNOW`, `PLANT`, `START`, `GOAL`
- Non-walkable: `EMPTY`, `WATER`, `STONE`, `SCORCHED`, `FOG_COVERED`, `STEAM`
- Cost: 1 per step. No weighted tiles in v1.
- Tie-break: prefer straight lines over zigzags (visually nicer)

### Death tiles

If the character is forced to walk through a death tile (e.g. `WATER`, `SCORCHED`), they don't pathfind around it — they die on it. This means the player's sequence must produce a fully walkable path; the character cannot improvise.

---

## 5. Weather cards

Six cards. Each is a `Resource` (`scripts/weather/weather_card.gd`) with a type enum, an icon, a display name, and a description. Cards are deterministic: identical inputs produce identical outputs.

### Card overview

| Card | Color | Primary effect | Secondary effects |
|---|---|---|---|
| **RAIN** ☔ | Cyan | Wet things | Fills basins → water; melts SCORCHED → mud; clears FOG_COVERED |
| **SUN** ☀ | Amber | Dry & evaporate | Water → steam; ice → water; wet grass → dry; dry grass → scorched |
| **FROST** ❄ | Ice blue | Freeze | Water → ice; wet grass → ice; dry grass → snow; mud → ice |
| **WIND** 🍃 | Green | Push & disperse | 3-tile cross: clears fog & steam, pushes light objects |
| **LIGHTNING** ⚡ | Violet | Electrify | Chains through conductive tiles (water/wet/ice/mud), shatters ice, scorches grass |
| **FOG** 🌫 | Slate | Hide | Covers a 3×3 area in FOG_COVERED, dampens other previews |

### Effect counts (read this before the matrix)

Agents implementing the WeatherSystem must hit these numbers exactly. If you implement fewer state transitions than are listed here, the level solver will reject levels that depend on the missing ones.

**6 cards × 14 terrains = 84 cells total.**

| | Active state changes | "(none)" cells |
|---|---|---|
| Total | **37** | **47** |

Per-card breakdown:

| Card | Active effects | Notes |
|---|---|---|
| **RAIN** | 6 | Wets dry, fills empty → water, melts scorched → mud, clears fog, grows plant, melts snow → wet |
| **SUN** | 8 | Evaporates water → steam, melts ice → water, dries wet → dry, scorches dry, kills plant → dry, clears fog → dry, dries mud → dry, melts snow → wet |
| **FROST** | 6 | Freezes water → ice, freezes wet → ice, freezes mud → ice, freezes empty → snow, freezes dry → snow, freezes plant → ice |
| **WIND** | 2 | Disperses fog → dry, disperses steam → empty |
| **LIGHTNING** | 6 | Scorches dry/wet/water/mud/plant (each starts the chain), shatters ice → empty |
| **FOG** | 9 | Covers any non-stone/start/goal tile with fog (9 tile types eligible) |
| **Total** | **37** | |

**Three cards have area effects**, multiplying their gameplay impact beyond a single tile:

| Card | Shape | Max tiles per play | Behavior |
|---|---|---|---|
| **WIND** | 3-tile cross | 5 (target + 4 cardinal neighbors) | Each tile in the cross independently checks the WIND row of the matrix |
| **FOG** | 3×3 area | 9 | Each tile in the 3×3 independently checks the FOG row, with STONE/START/GOAL excluded from coverage |
| **LIGHTNING** | Flood fill | Unbounded (entire connected conductive region) | Targets a tile; if conductive (WATER, WET_GRASS, ICE, MUD), flood fills all connected conductive tiles and applies the LIGHTNING row to each |

This means the **functional surface area is much larger than 37**. A single LIGHTNING played on a fully-connected water region can scorch 15+ tiles in one card. A single FOG can hide 9 tiles. A single WIND can clear 5 fog tiles. The solver and the level designer must account for this — never treat any of these three cards as single-tile.

**Implementation contract for `WeatherSystem.apply()`:**

```gdscript
# Pure function. Takes a grid copy + width/height + card_type + target position.
# Returns a NEW grid (does not mutate input).
# Implementation must:
#   1. Match every active row in the matrix below exactly.
#   2. Handle WIND as a 3-tile cross (one apply per neighbor).
#   3. Handle FOG as a 3x3 area, excluding STONE/START/GOAL inside the area.
#   4. Handle LIGHTNING as a flood fill across conductive tiles.
#   5. Be deterministic. Same inputs = same output, every call.
static func apply(grid: Array, width: int, height: int, card_type: int, pos: Vector2i) -> Array
```

Tests in `test/test_weather_cards.gd` must cover **all 37 active transitions** plus at least one test case per area-effect card showing the multi-tile behavior. That's a minimum of **40 test cases** for the WeatherSystem to be considered complete.

### Full interaction matrix (v1)

The matrix is the source of truth. The puzzle solver, the agents, and the level designer all pull from this table. **If you change a row, regenerate the level batches.**

| Card → / Terrain ↓ | RAIN | SUN | FROST | WIND | LIGHTNING | FOG |
|---|---|---|---|---|---|---|
| `EMPTY`         | WATER | (none) | SNOW | (none) | (none) | FOG_COVERED |
| `DRY_GRASS`     | WET_GRASS | SCORCHED | SNOW | (none) | SCORCHED | FOG_COVERED |
| `WET_GRASS`     | (none) | DRY_GRASS | ICE | (none) | SCORCHED + chain | FOG_COVERED |
| `WATER`         | (none) | STEAM | ICE | (none) | SCORCHED + chain | FOG_COVERED |
| `ICE`           | (none) | WATER | (none) | (none) | EMPTY (shatter) | FOG_COVERED |
| `MUD`           | (none) | DRY_GRASS | ICE | (none) | SCORCHED + chain | FOG_COVERED |
| `SNOW`          | WET_GRASS | WET_GRASS | (none) | (none) | (none) | FOG_COVERED |
| `SCORCHED`      | MUD | (none) | (none) | (none) | (none) | FOG_COVERED |
| `STEAM`         | (none) | (none) | (none) | EMPTY | (none) | (none) |
| `PLANT`         | PLANT (grow) | DRY_GRASS | ICE | (none) | SCORCHED | FOG_COVERED |
| `STONE`         | (none) | (none) | (none) | (none) | (none) | (none) |
| `FOG_COVERED`   | WET_GRASS | DRY_GRASS | (none) | DRY_GRASS | (none) | (none) |
| `START` / `GOAL` | (none) | (none) | (none) | (none) | (none) | (none) |

Notes:
- `(none)` = card has no effect on this tile (the card is still consumed from the queue)
- LIGHTNING + conductive: starts a flood fill. All connected conductive tiles become SCORCHED. See `_apply_lightning` in `weather_system.gd`.
- WIND targets a 3-tile cross (target + 4 cardinal neighbors), all other cards target a single tile.
- FOG targets a 3×3 area centered on the target. STONE/START/GOAL inside the 3×3 are not covered.

### Card costs

In v1, **every card costs 1 move**. The "Moves: 6" counter on the gameplay HUD is the size of the player's queue, not a turn timer. If the level allows 6 moves and the player queues 6 cards, no more can be added until they undo one.

We may experiment with multi-cost cards (e.g. LIGHTNING costs 2) in v1.5 if specific puzzles need it. Not in scope for launch.

---

## 6. Terrain catalog

14 terrain types. Defined as an enum in `scripts/weather/weather_type.gd`. The art pipeline produces one tile sprite per type plus state-transition sprites where needed.

| Terrain | Walkable? | Conductive? | Death? | Notes |
|---|---|---|---|---|
| `EMPTY` | ❌ | ❌ | Fall | A pit. Bridge it with ICE or fill with WATER+FROST. |
| `DRY_GRASS` | ✅ | ❌ | — | The default ground. |
| `WET_GRASS` | ✅ | ✅ | — | Conductive! Don't stand here during lightning. |
| `WATER` | ❌ | ✅ | Drown | Freeze it to ICE to walk across. |
| `ICE` | ✅ | ✅ | — | Conductive — lightning shatters it. |
| `MUD` | ✅ | ✅ | — | Slow tiles (visually). Conductive. |
| `SNOW` | ✅ | ❌ | — | Walkable, soft. |
| `SCORCHED` | ❌ | ❌ | Burn | Burnt earth. Rain → MUD. |
| `STEAM` | ❌ | ❌ | Fall | Temporary platform — actually NOT walkable in v1 (visual only). Wind disperses it. |
| `PLANT` | ✅ | ❌ | — | Decorative + bridge. Rain grows it bigger. Sun kills it. |
| `STONE` | ❌ | ❌ | — | Wall. Cannot be transformed by any card. Level geometry. |
| `FOG_COVERED` | ❌ | ❌ | — | Hides what's underneath. Cleared by RAIN, SUN, or WIND. |
| `START` | ✅ | ❌ | — | Character spawn point. Exactly one per level. |
| `GOAL` | ✅ | ❌ | — | Win tile. Usually one per level; multi-goal levels possible. |

**Design note on STEAM:** Originally STEAM was a temporary walkable platform. In v1 it's non-walkable (visual only) because it created weird timing puzzles that didn't fit the static-then-walk model. STEAM exists so SUN+WATER does *something*, and so WIND has a clear use beyond fog. Reconsider for v1.5.

**Conductive tiles** form lightning chains. When you target lightning at any conductive tile, a flood fill finds all connected conductive tiles and converts them all to SCORCHED at once. This is the most spectacular weather effect and the most dangerous one for the character — a single misplaced lightning bolt can scorch half the board.

---

## 7. Level anatomy

A level is a `LevelData` Resource (`scripts/level/level_data.gd`) containing:

```gdscript
class_name LevelData extends Resource

@export var id: String                    # "w1_l03"
@export var world: int                    # 1-6
@export var level_number: int             # 1-22
@export var display_name: String          # "Rainfall Channels"
@export var hint_text: String             # One sentence shown in the goal banner

@export var width: int                    # Grid dimensions
@export var height: int

@export var initial_terrain: Array        # Flat width*height array of Terrain ints
@export var start_position: Vector2i      # Character spawn (must be walkable)
@export var goal_positions: Array[Vector2i]  # Win condition tiles

@export var available_cards: Array[int]   # Multi-set of WeatherType.Card ints
@export var max_moves: int                # = available_cards.size() in v1

@export var par_moves: int                # 3-star threshold (solver-validated)
@export var target_difficulty: int        # 1-10, used by level gen tooling

@export var min_solution_length: int      # Cached solver result
@export var unique_solution: bool         # Cached: did solver find exactly one?
```

### Constraints

- `start_position` must be walkable in the initial board (typically `START` tile).
- `goal_positions` must be reachable from `start_position` *somehow* — i.e. the solver must find at least one solution.
- `available_cards.size() == max_moves` in v1.
- `par_moves <= max_moves`. Star thresholds derive from par.

### Star ratings

Three stars. Tied to move efficiency, not time:

| Stars | Condition |
|---|---|
| ⭐ | Level completed. |
| ⭐⭐ | Completed with `moves_used <= max_moves - 1` |
| ⭐⭐⭐ | Completed with `moves_used <= par_moves` (the solver's optimal) |

The ⭐⭐⭐ "perfect" rating means you found the same solution the solver did. For levels with multiple optimal solutions (`unique_solution == false`), any solution at par length earns three stars.

No time pressure, no penalty for thinking. Stars are aspirational, not gating.

---

## 8. Win and lose conditions

### Win

Character reaches any `GOAL` tile during the walk phase. Triggers `cheer` animation, then the **Level Complete** screen.

### Lose — five flavors

| Lose state | Trigger | Animation | Recovery |
|---|---|---|---|
| **Drown** | Character walks onto WATER | `drown` (5 frames) | Try Again popup |
| **Burn** | Character walks onto SCORCHED | `burn` (6 frames) | Try Again popup |
| **Electrocute** | LIGHTNING chains through the tile the character is currently on (only relevant if walk has begun, but in v1 walk happens after sequence resolves so this can't happen — keep the anim for v1.5 multi-phase) | `electrocute` (4 frames) | Try Again popup |
| **Freeze** | FROST applied to character's current tile (also v1.5) | `freeze` (5 frames) | Try Again popup |
| **Fall** | Character walks onto EMPTY or off the grid edge | `fall` (4 frames) | Try Again popup |

In v1, the only loss states reachable are **drown**, **burn**, and **fall** because the character is stationary during the sequence resolution. We're shipping all 5 anim sets anyway because v1.5 introduces interleaved movement.

### Soft lose — no path

If after the sequence resolves there is no walkable path from START to GOAL, the character does not move. Instead a "No Path Forward" popup appears with options:
- **Undo Last** — pops the last queued card and returns to planning
- **Restart** — clears the entire queue
- **Hint** — costs nothing in v1 (we may add hint costs for "deluxe" levels)

Soft loses are **not failures** — no death animation, no lose screen. The player simply rejoins planning.

---

## 9. World progression

Six worlds, **22 levels each**, **132 levels total**. Earlier doc said 130; we're standardizing on 22 per world for math reasons.

### Unlock model

**Linear, Cut the Rope style.** Beat level N to unlock level N+1. Beat the last level of a world to unlock the next world's first level.

- No skipping
- No "stuck on level 13 forever" rescue. The hint system has to be good enough to unstick anyone.
- The world map shows locked levels as silhouetted nodes. The current level pulses gently. Completed levels show their star count.

**Why linear over branching:** Tutorial-style mechanics introduction breaks if players can skip the level that teaches the new mechanic. Linear unlock guarantees the difficulty curve.

### Mechanic introduction per world

| World | Name | New cards | Total cards available | Levels |
|---|---|---|---|---|
| 1 | **Downpour** | RAIN | RAIN | 1–22 |
| 2 | **Heatwave** | SUN | RAIN, SUN | 23–44 |
| 3 | **Cold Snap** | FROST | RAIN, SUN, FROST | 45–66 |
| 4 | **Gale Force** | WIND | RAIN, SUN, FROST, WIND | 67–88 |
| 5 | **Thunderstorm** | LIGHTNING | RAIN, SUN, FROST, WIND, LIGHTNING | 89–110 |
| 6 | **Whiteout** | FOG | All six | 111–132 |

Each world's first 5 levels are pure tutorials for the new card. Levels 6–17 are the "main course". Levels 18–22 are challenge levels that test the world's unique combinations.

### Difficulty curve

Per world, the curve looks like this:

```
Diff
 10 |                                       ╭─
  9 |                                  ╭───╯
  8 |                              ╭──╯
  7 |                          ╭──╯
  6 |                      ╭──╯
  5 |                  ╭──╯
  4 |              ╭──╯
  3 |          ╭──╯
  2 |      ╭──╯
  1 |╮ ╭──╯
  0 └┴─┴────────────────────────────────────────
     1  3   5   7   9  11  13  15  17  19  21
                Level number
```

Levels 1-2 are the gentle re-entry; the player just learned the mechanic. By level 22 we're at challenge-level difficulty. Then the next world resets to "easy with a new mechanic."

The solver computes a `difficulty_score()` for every level (see `scripts/puzzle/solver_result.gd`). Level designers + agents target the curve and the solver enforces it on PR.

---

## 10. Hint system

A puzzle game lives or dies on its hint system. Whether's hint system is **non-punishing** in v1.

### Two hint tiers

- **Tier 1 — Soft hint.** Free. One sentence describing the level's *insight*. ("Sun turns water into steam.") Always available, shown on the goal banner.
- **Tier 2 — Hard hint.** Free in v1. Highlights the *next correct card* in the optimal solution and the tile to play it on. Available after the player has been planning for >60 seconds OR has tapped Hint.

For "deluxe" challenge levels (the last 5 of each world), Tier 2 may cost 1 move from the player's allowance. Not in v1 scope but the data structure supports it.

### How it works

The `PuzzleSolver` produces an `Array[[card_type, Vector2i]]` of optimal moves. The hint system replays the player's current queue against the solver's path:

1. If the player's queue matches the start of the optimal path, hint shows the **next** optimal move.
2. If the player's queue diverges, hint shows the **first divergence** (i.e. "this card is wrong, try X here").

This means agents must not generate levels with multiple drastically different optimal solutions if the hint system is to make sense — or alternatively, the solver has to track all optimal paths and the hint chooses the closest.

---

## 11. Save system

A single autoload (`scripts/autoload/save_manager.gd`) that writes one JSON file per profile.

### Schema (v1)

```json
{
  "version": 1,
  "profile_id": "default",
  "created_at": "2026-04-10T14:32:11Z",
  "updated_at": "2026-04-10T14:32:11Z",
  "settings": {
    "master_volume": 1.0,
    "music_volume": 0.8,
    "sfx_volume": 1.0,
    "color_blind_mode": "off",
    "reduce_motion": false,
    "language": "en"
  },
  "progress": {
    "current_world": 1,
    "current_level": 7,
    "highest_unlocked": "w1_l07",
    "total_stars": 18
  },
  "levels": {
    "w1_l01": { "completed": true, "stars": 3, "best_moves": 4, "best_time_ms": 8200 },
    "w1_l02": { "completed": true, "stars": 2, "best_moves": 6, "best_time_ms": 14500 },
    "w1_l03": { "completed": true, "stars": 3, "best_moves": 5, "best_time_ms": 11200 }
  },
  "stats": {
    "total_play_time_ms": 285000,
    "hints_used": 4,
    "perfect_solves": 12
  }
}
```

### Storage

| Platform | Path |
|---|---|
| Windows | `%APPDATA%/Whether/save_default.json` |
| macOS | `~/Library/Application Support/Whether/save_default.json` |
| Linux | `~/.local/share/Whether/save_default.json` |
| Android | Godot `user://save_default.json` |
| iOS | Godot `user://save_default.json` |

### Cloud sync

We do not write a custom cloud sync. Steam Cloud, iCloud, and Google Play Saved Games each handle the save file natively if we configure them in the platform export settings. This is platform work, not engine work — shows up as a release-ops task.

### Save triggers

- On level complete → save
- On settings change → save
- On app pause / focus loss → save
- On manual "Reset Progress" from settings → wipe and save

Atomic writes only. Always write to `save_default.json.tmp` then rename. Schema version field for migrations.

---

## 12. Audio direction

Three buses: **Music**, **SFX**, **Ambient**. Master mixes all three.

### Music

One looping track per world (6 tracks total). Mood matches the world name:

| World | Mood | Reference |
|---|---|---|
| Downpour | Gentle, contemplative, light percussion | A Short Hike, Stardew Valley spring |
| Heatwave | Warm, slow, sun-bleached | Monument Valley, Journey opening |
| Cold Snap | Crystalline, sparse | Celeste chapter 2 |
| Gale Force | Airy, strings, motion | Hollow Knight City of Tears low-energy |
| Thunderstorm | Tense, low strings, distant rumbles | Inside ambient |
| Whiteout | Mysterious, choral, muted | Cocoon |

Generate with Suno or ElevenLabs Music. Hand-edit loops in Audacity.

### Ambient

Each world has a constant ambient layer underneath the music: rain in Downpour, cicadas in Heatwave, wind in Gale Force, etc. Stop ambient during Level Complete so the win sting plays clean.

### SFX

Roughly 30 sounds for v1:
- 6 weather card place sounds (one per card type)
- 6 weather effect resolution sounds (rain pour, sun warm, frost crystal, wind gust, thunder crack, fog whoosh)
- Character footsteps (3 variants randomized: grass, ice, mud)
- 5 death sounds (drown, burn, electrocute, freeze, fall)
- Win sting, lose sting
- UI: button tap, button release, card select, card queue, card unqueue, level start, level complete

Generate with ElevenLabs SFX. Spot-check on phone speakers.

---

## 13. Animation feel and timing

Numbers below are starting points. Tune in playtest.

### Card placement (planning phase)

| Beat | Duration |
|---|---|
| Card lifts from hand on tap | 80ms |
| Card flies to queue strip | 180ms ease-out |
| Tile preview overlay fades in | 120ms |
| Tile preview overlay holds | until next action |

### Sequence playback

| Beat | Duration |
|---|---|
| PLAY SEQUENCE button press → first card resolves | 200ms |
| Card flies from queue to target tile | 200ms |
| Weather effect animation | 300–500ms (per card type) |
| Pause between cards | 100ms |
| All cards resolved → walk begins | 250ms |

### Walk phase

| Beat | Duration |
|---|---|
| Character takes one step (one tile) | 250ms |
| Walk-to-walk transition (changing direction) | 50ms |
| Death animation | 600ms (varies by type) |
| Win celebration → Level Complete screen | 700ms |

### UI transitions

- Screen push: 280ms ease-out
- Screen pop: 200ms ease-in
- Modal slide-up: 220ms ease-out
- Modal dismiss: 160ms ease-in

### Reduced motion mode

If the player enables Reduce Motion in settings, all card placement and weather effect anims drop to 50% duration, particle counts drop 75%, screen shake is disabled, character walk animation skips frame interpolation. Functionality identical.

---

## 14. Settings

The Settings screen is reachable from the home screen. One screen, scrollable.

### Sections

**Audio**
- Master volume slider
- Music volume slider
- SFX volume slider

**Visual**
- Color-blind mode (Off / Protanopia / Deuteranopia / Tritanopia)
- Reduce motion (toggle)
- Show grid overlay (toggle)

**Gameplay**
- Show optimal hint after... (Off / 30s / 60s / 120s of inactivity)
- Confirm before playing sequence (toggle, default Off)

**Account**
- Reset progress (button, double-confirm)
- Cloud sync status (read-only label per platform)

**About**
- Version
- Credits link
- Privacy policy link
- Acknowledgements

No language selector in v1. Adding one is a release-ops task with localization tooling.

---

## 15. Accessibility

Indie puzzle games punch above their weight on accessibility because the audience is broad. Minimum bar for v1:

- **Color-blind modes** — three palettes plus "off". Tile colors shift, NOT shapes. Card icons stay visually distinct.
- **Never color-only state.** Every terrain type has a unique pattern or shape, not just a color. WET_GRASS has visible droplets, ICE has visible cracks, etc.
- **Reduce motion** — see §13.
- **Touch target minimum** — 48×48 device pixels for all interactive elements (Apple HIG and Material Design baseline).
- **No timed challenges.** No level fails due to slow play.
- **Pause anywhere.** Tap pause icon mid-sequence-playback to halt. Tap again to resume.
- **Skippable cutscenes.** None in v1, but if we add story cutscenes, they're skippable.

Out of scope for v1: screen reader support (most puzzle games don't have it; revisit for v1.1 if requested by players), one-handed mode beyond default thumb-friendly layout.

---

## 16. What is NOT in this game

Defining the negative space is as important as defining the positive. None of these are in scope for v1:

- ❌ Multiplayer of any kind
- ❌ User-generated content / level editor
- ❌ Microtransactions, ads, energy systems, lives
- ❌ Daily challenges, login streaks, FOMO mechanics
- ❌ Story cutscenes or dialogue
- ❌ Multiple character skins, character customization
- ❌ Weather card upgrades / RPG progression
- ❌ Procedurally generated levels at runtime (the level *generator tool* is for designers, the game ships with hand-curated levels)
- ❌ Online leaderboards in v1 (we may add Steam leaderboards for "perfect solves" in v1.1)
- ❌ Achievements that require grinding (achievements that map to natural play are fine)
- ❌ Difficulty modes (the hint system handles this)

If the producer agent finds itself flagging a feature request that hits this list, it goes to Icebox without discussion.

---

## 17. Glossary for agents

When agents read this doc, they should treat these terms as canonical:

- **Card** — A weather action the player can place. Represented as `WeatherCard` Resource.
- **Hand** — The set of available cards for the current level, displayed at the bottom of the gameplay screen.
- **Queue** — The ordered list of cards the player has staged but not yet played. Displayed in the queue strip above the hand.
- **Sequence** — The full set of queued cards at the moment PLAY SEQUENCE is tapped. Immutable after that.
- **Board** — The grid of tiles. Has `width × height` cells.
- **Terrain** — The state of a single grid cell. One of 14 enum values.
- **Tile** — A single cell of the board. Tiles have a position (Vector2i) and a terrain (int).
- **Sequence resolution** — The phase where queued cards animate onto the board one by one and mutate terrain.
- **Walk phase** — The phase after sequence resolution where the character A*-pathfinds from START to GOAL.
- **Solver** — The BFS algorithm in `scripts/puzzle/puzzle_solver.gd` that finds optimal solutions.
- **Par moves** — The solver's optimal solution length. Tied to ⭐⭐⭐ rating.
- **Death tile** — A terrain that kills the character on contact: WATER, SCORCHED, EMPTY (off-grid), STEAM.
- **Conductive** — Terrain that LIGHTNING chains through: WATER, WET_GRASS, ICE, MUD.
- **Walkable** — Terrain the character can stand on. See §4.
- **Insight** — The single idea a level teaches. Used by hint system and level design.
