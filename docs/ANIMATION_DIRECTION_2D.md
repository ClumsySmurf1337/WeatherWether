# Animation Direction (v2 — 2D)

> **Status:** Replaces the v1 stub. Pairs with `docs/GAME_DESIGN.md`, `docs/CODE_REWRITE_PLAN.md` (the `animation_director.gd` and `character_controller.gd` specs), `docs/ART_DIRECTION.md`, `docs/ASSET_PROMPTS_GEMINI.md` (frame counts per sprite sheet), and `docs/UI_SCREENS.md`.
>
> **For the gameplay-programmer agent:** §9 is the contract. Implement `animation_director.gd` against it.
>
> **For the art-pipeline agent:** §3 and §4 are the timing budgets. Frame counts in `ASSET_PROMPTS_GEMINI.md` must match the timings here.
>
> **Last updated:** 2026-04-10

---

## 1. Goals

Animation in Weather Whether serves three purposes, in order:

1. **Communicate cause and effect.** Every weather card resolution must clearly show what changed and where. The player learns the rules by watching, not by reading.
2. **Make Sky feel alive.** The character is the heart of the game (per `GAME_DESIGN.md` §4). Idle bobs, walk cycles, and reaction beats sell the emotional stakes.
3. **Stay out of the way.** Animations can be skipped (PLAY SEQUENCE → tap = 2× speed) and reduce-motion users get instant resolution. Nothing blocks input for more than 3 seconds at default speed.

The non-goals are equally important: no juicy bouncy springs everywhere, no screen-shake on every action, no flashy particle storms. Calm beats kinetic.

---

## 2. Master timing reference

All times in milliseconds at default speed (1.0×). Multiply by `1.0 / speed_multiplier` for scaled playback. Fast mode = 2.0×, slow accessibility mode = 0.5×.

| Beat | Duration | Notes |
|---|---|---|
| Tile sprite frame | 100 ms | All animated tiles (water, fog, steam, goal) loop at 10 fps |
| Character walk step | 250 ms | One tile traversal: 4 frames × ~62 ms each |
| Character turn | 80 ms | Snap to new facing, no in-between frames |
| Weather card resolve | 500-900 ms | Per card type, see §3 |
| Tile transition flash | 120 ms | Brief white flash on tile state change |
| Card draw to queue | 200 ms | Card flies from hand to queue strip |
| Queue commit | 350 ms | Queue strip "locks" with brief glow |
| Win celebration | 1500 ms | Sky cheer + sunrise overlay |
| Death animation | 800-1200 ms | Per cause, see §4 |
| Screen transition (fade) | 250 ms | Default scene change |
| Screen transition (push) | 350 ms | World/level select navigation |
| UI button press | 80 ms | Press-down + release |
| Toast notification slide | 250 ms | In or out |
| HUD panel slide | 300 ms | Pause menu, settings, hint |

**Frame budget:** at 60 fps the engine has 16.6 ms per frame. Animation work should not exceed 4 ms in any single frame (24% of budget) so logic and rendering have room.

---

## 3. Weather effect animations

Each weather card has its own timing budget. The animation_director plays them in queue order during the RESOLVING state. Effects do not overlap — each runs to completion before the next starts.

### Rain (single tile, 500 ms)

| Frame | Time | Visual | Sound |
|---|---|---|---|
| 0 | 0 ms | 2 droplets above target | rain_burst.ogg start |
| 1 | 100 ms | 4 droplets, leading edge hits | — |
| 2 | 200 ms | 6 droplets + small ripple ring forms | — |
| 3 | 300 ms | Ripple expands, terrain commits new state | — |
| 4 | 400 ms | Ripple fades | — |
| End | 500 ms | All particles cleared | rain_burst.ogg end |

Sprite sheet: `vfx_rain_burst.png` (6 frames at 100 ms each, but frames 5-6 fade after the terrain commit at 300 ms, so total visible duration is 500 ms).

### Sun (single tile, 600 ms)

Warm pulse expanding from center. Tile state commits at the brightest moment (frame 3, 240 ms in).

| Frame | Time | Visual |
|---|---|---|
| 0 | 0 ms | Bright yellow center forms |
| 1 | 120 ms | Disc expands, orange edge appears |
| 2 | 240 ms | Disc at full radius, **terrain commits** |
| 3 | 360 ms | Ring fades, warm glow lingers |
| 4 | 480 ms | Almost gone, faint warmth |
| End | 600 ms | Cleared |

Slightly longer than rain to reinforce sun = restorative, not destructive.

### Frost (single tile, 700 ms)

Crystals grow inward from corners, then snap. Slowest of the single-tile effects to make the freeze read as deliberate.

| Frame | Time | Visual |
|---|---|---|
| 0 | 0 ms | Tiny white specks at 4 corners |
| 1 | 117 ms | Crystal arms growing inward |
| 2 | 233 ms | Crystals halfway across |
| 3 | 350 ms | Crystals nearly meeting |
| 4 | 467 ms | Full coverage, **terrain commits** |
| 5 | 583 ms | Snap-frozen with white-blue highlight |
| End | 700 ms | Cleared |

### Wind (3-tile cross, 600 ms)

Wind sweeps across the target + 4 cardinal neighbors as a directional gust.

| Frame | Time | Visual |
|---|---|---|
| 0 | 0 ms | Streak lines form on the upwind edge |
| 1 | 120 ms | Streaks at 30% across the cross |
| 2 | 240 ms | Streaks fully visible mid-cross |
| 3 | 360 ms | Streaks at 70%, **all 5 terrains commit simultaneously** |
| 4 | 480 ms | Streaks fading on downwind edge |
| End | 600 ms | Cleared |

All affected tiles commit on the same frame (frame 3, 360 ms in). Do not stagger. The whole gust is one event.

### Lightning (chain, 700 ms base + 80 ms per chained tile)

The dramatic one. Animation length scales with chain length but caps at **1500 ms total** to prevent lightning chains across huge boards from blocking the player.

| Frame | Time | Visual |
|---|---|---|
| 0 | 0 ms | Bright white-violet bolt strikes target |
| 1 | 100 ms | Full white screen flash overlay (8% opacity max — not jarring) |
| 2 | 200 ms | Flash fading, target tile commits, conductive flood-fill begins |
| 3+n×80ms | varies | Each chained tile briefly pulses violet as it receives the charge |
| End | 700 + n×80 ms | All chained tiles committed, afterglow fades |

Implementation note: the chain pulse uses a single shader pass tinted violet, not individual sprite swaps. Cap n at 10 to enforce the 1500 ms ceiling. Chains longer than 10 tiles still resolve correctly in logic — only the visual is capped.

### Fog (3×3 area, 900 ms)

Slowest because fog is the most uncertain mechanic. Players need time to see where it landed.

| Frame | Time | Visual |
|---|---|---|
| 0 | 0 ms | Thin wisps appear at the 3×3 edges |
| 1 | 150 ms | Wisps moving inward |
| 2 | 300 ms | Half coverage |
| 3 | 450 ms | 75% coverage with dense center |
| 4 | 600 ms | Full coverage settling, **all terrains commit** |
| 5 | 750 ms | Settled fog with subtle drift |
| End | 900 ms | Cleared, tiles now FOG_COVERED |

After the fog effect ends, the FOG_COVERED tiles continue their own ambient drift loop indefinitely.

### Sequence pause between cards

After each card resolves, wait **150 ms** before starting the next. Gives the eye a beat to register what changed. Skipped if speed_multiplier ≥ 2.0.

---

## 4. Character animations

Sky has 12 animation states. All sprites are 24×24 source. Frame counts come from `ASSET_PROMPTS_GEMINI.md` §3.

### Idle (loop, 4 frames)

| Frame | Duration | Notes |
|---|---|---|
| 1 | 250 ms | Base position |
| 2 | 250 ms | 1 px up |
| 3 | 250 ms | Base |
| 4 | 250 ms | 1 px down |

Total cycle: **1000 ms**. Loops indefinitely while in PLANNING state. Subtle so it doesn't compete with weather card animations.

### Walk N / S / E / W (loop while walking, 4 frames)

| Frame | Duration | Notes |
|---|---|---|
| 1 | 62 ms | Contact pose, leg forward |
| 2 | 63 ms | Passing pose |
| 3 | 62 ms | Contact pose, opposite leg forward |
| 4 | 63 ms | Passing pose |

Total cycle: **250 ms** = one tile traversal at default speed. The character_controller advances one tile per cycle, syncing position lerp with the cycle so feet appear to land on tile boundaries.

E and W are mirrors of each other in code (`flip_h = true`).

### Surprised (one-shot, 3 frames, 240 ms)

Plays before any death animation. Brief intake-of-breath beat that gives the player a "oh no" moment.

| Frame | Duration | Notes |
|---|---|---|
| 1 | 80 ms | Eyes widen, body straightens |
| 2 | 80 ms | Arms slightly raised |
| 3 | 80 ms | Hold pose |

### Cheer (one-shot, 6 frames, 1000 ms)

Plays on level win during the celebration overlay.

| Frame | Duration | Notes |
|---|---|---|
| 1 | 100 ms | Idle pose |
| 2 | 150 ms | Arms starting up |
| 3 | 250 ms | Arms full up + jumping |
| 4 | 250 ms | Peak of jump (hold) |
| 5 | 150 ms | Landing |
| 6 | 100 ms | Settled with arms still raised |

After this, transitions to a "happy idle" loop reusing the cheer frame 6 pose until the player taps Continue.

### Drown (one-shot, 5 frames, 1000 ms)

| Frame | Duration | Notes |
|---|---|---|
| 1 | 240 ms | Surprised reaction (reuses surprised state) |
| 2 | 200 ms | Water splash particles around character |
| 3 | 200 ms | Lower half disappearing |
| 4 | 200 ms | Only head and shoulders, blue-tinted |
| 5 | 160 ms | Final ripple, character gone |

Sound: `splash.ogg` on frame 2, `bubble_sink.ogg` on frame 3.

### Burn (one-shot, 6 frames, 1200 ms)

| Frame | Duration | Notes |
|---|---|---|
| 1 | 240 ms | Surprised reaction |
| 2 | 160 ms | Red flame particles erupt at feet, character flashes red |
| 3 | 200 ms | Orange flames cover lower body |
| 4 | 200 ms | Character silhouette becomes ash-grey |
| 5 | 200 ms | Ash silhouette begins crumbling |
| 6 | 200 ms | Small ash pile on ground |

Sound: `whoosh_fire.ogg` on frame 2, `crumble.ogg` on frame 5.

### Fall (one-shot, 4 frames, 900 ms)

| Frame | Duration | Notes |
|---|---|---|
| 1 | 240 ms | Surprised + arms windmilling |
| 2 | 160 ms | Feet leaving ground, body tilting forward |
| 3 | 250 ms | Falling, character at 60% scale + motion lines |
| 4 | 250 ms | Tiny silhouette disappearing into darkness |

Particles: light dust at the original tile position from frame 2 onward.

Sound: `gasp.ogg` on frame 1, `wind_fall.ogg` frames 2-4.

### Electrocute (v1.5 — placeholder in v1, 5 frames, 800 ms)

| Frame | Duration | Notes |
|---|---|---|
| 1 | 80 ms | Electric arc touches |
| 2 | 80 ms | Skeleton flicker through silhouette (white) |
| 3 | 240 ms | Hold flicker |
| 4 | 200 ms | Silhouette darkens |
| 5 | 200 ms | Smoke wisp rising |

### Freeze (v1.5 — placeholder in v1, 5 frames, 1000 ms)

Ice crystals encase the body in 5 stages until fully frozen statue.

### Win pose (loop, single frame held)

After cheer completes, hold the final pose until input. Not really an animation, just the resting state for the celebration screen.

### Hidden (zero-frame state)

Used during scene transitions, splash screens, and any moment Sky should not be on screen. The character_view simply hides its sprite.

---

## 5. Tile transition animations

When a tile changes terrain type during weather resolution, the visual transition is **not** a crossfade or morph. It's a brief flash:

1. The new tile sprite is swapped instantly (single frame replacement)
2. A 120 ms white flash quad overlay scales 0% → 100% → 0% on top of the tile
3. The flash uses 50% peak opacity so it doesn't blow out the screen

This is faster and more readable than morphing sprites, especially with the limited palette. The art-pipeline agent does not need to draw transition frames.

**Exception:** the tile lock-in moment for area effects (wind 5 tiles, fog 9 tiles, lightning chains) uses a single shared flash quad spanning all affected tiles. One quad, not many.

---

## 6. UI element animations

### Card draw to queue (200 ms)

When the player taps a card in the hand and then taps a target tile:

1. The card sprite tweens from its hand position to the queue strip slot
2. Easing: `Tween.EASE_OUT, Tween.TRANS_QUAD`
3. On arrival, a tiny scale bounce (0.95 → 1.05 → 1.0 over 80 ms)

### Card unqueue (150 ms)

Reverse: card flies back to hand, fades to 50% on arrival.

### Queue commit / PLAY SEQUENCE (350 ms)

When the player hits PLAY SEQUENCE:

1. Queue strip glows gold (0 → 100% opacity over 150 ms)
2. Glow holds for 100 ms
3. Glow fades (100% → 0 over 100 ms) as the first card resolution begins

### Hand refill (250 ms)

After a sequence completes, cards slide back into the hand from the deck position. Stagger of 50 ms between cards.

### Screen fade (250 ms)

Default scene transition. Black quad: 0 → 100% opacity (125 ms) → swap scene → 100 → 0% (125 ms).

### Screen push (350 ms)

Used for world select → level select → gameplay drilldown. The new scene slides in from the right while the old scene slides out to the left. Both at 350 ms with `Tween.EASE_IN_OUT, Tween.TRANS_CUBIC`.

### Toast notification (500 ms total visible time + 250 ms slide each side)

Bottom-anchored toast slides up from below screen, holds for 500 ms, slides back down. Used for hint reveals and "no path forward" warnings.

### HUD panels (300 ms)

Pause, Settings, Hint, No Path Forward modals. Slide in from the bottom on phone, fade in from center on desktop. The animation_director picks based on viewport aspect ratio at runtime.

### Level node pop (180 ms)

When a level on the world map unlocks (triggered by completing the prior level), the lock icon fades out, the node scales 1.0 → 1.2 → 1.0, and a small sparkle particle plays.

---

## 7. Reduce motion fallback

Setting: `settings.reduce_motion = true` (off by default, persisted in save).

When enabled:

| Normal animation | Reduce motion behavior |
|---|---|
| Weather card 500-900 ms resolve | Instant terrain swap + 120 ms white flash |
| Lightning chain | Instant + single 200 ms flash on all chained tiles |
| Character walk 250 ms/tile | 80 ms/tile linear position lerp, no walk cycle (idle pose held) |
| Death animations | 200 ms fade-to-black on character sprite, no particles |
| Cheer animation | 400 ms scale bounce on idle pose, no jump |
| Screen transitions | 100 ms fade only, no slide |
| Card draw to queue | Instant snap |
| Queue commit glow | Skipped |
| Toast slides | Instant appear |
| HUD panel slides | Instant appear |
| Level node pop | Skipped, lock icon disappears instantly |
| Tile sprite loops (water/fog/steam) | Static frame 1 only |
| Idle character bob | Static frame 1 only |

The animation_director checks `SaveManager.get_setting("reduce_motion", false)` at the start of each public method. Implement this check once in `animation_director.gd` and route to the fallback path.

Reduce motion is **not** the same as fast mode. Fast mode plays the same animations 2× faster. Reduce motion replaces animations with instant or minimal alternatives.

---

## 8. Performance guardrails

Mobile devices are the constraint. Test budgets on a 2019-era mid-range Android (Snapdragon 660 equivalent) at 60 fps.

| Limit | Value |
|---|---|
| Max concurrent tweens | 16 |
| Max concurrent particle emitters | 8 |
| Max particles per emitter | 24 |
| Max simultaneous tile flashes | 12 (covers any wind/fog/lightning area effect) |
| Max sprite layers per tile | 3 (base + state overlay + flash) |
| Animation frame texture size | ≤ 256×256 per sheet |
| Pre-allocated tween pool | 32 (avoid runtime allocation during play) |

The animation_director must reuse tween instances from a pool, not create new ones each call. Use `Tween.kill()` and `Tween.set_loops(0)` to reset pooled tweens before reuse.

Particle emitters live as child nodes of the tile they're tied to. They auto-deactivate (not free) on completion. The animation_director caches emitter references by tile position.

**Profiling target:** during a 5-card sequence resolution on a 7×7 board with one lightning chain, the frame time must stay under 16.6 ms throughout. If it exceeds, drop quality (cut particle counts in half) before dropping framerate.

---

## 9. `animation_director.gd` contract

This is what `gameplay-programmer` agents implement. The class lives at `scripts/animation/animation_director.gd` and is instantiated as a child of `game_manager.gd`. It does not need to be an autoload.

```gdscript
class_name AnimationDirector extends Node

# --- Signals ---
signal weather_effect_finished(card_type: int)
signal sequence_complete
signal walk_started
signal walk_finished
signal death_finished(cause: int)
signal cheer_finished

# --- State ---
var speed_multiplier: float = 1.0
var reduce_motion: bool = false

# --- Setup ---
func _ready() -> void:
    reduce_motion = SaveManager.get_setting("reduce_motion", false)
    EventBus.settings_changed.connect(_on_settings_changed)

# --- Public sequence playback (called by game_manager.gd) ---

# Plays an entire queued sequence in order. Awaits each card to completion
# plus the inter-card pause. Emits sequence_complete when done.
func play_sequence(queue: Array, grid_manager: GridManager) -> void

# Plays a single card resolution at the target tile.
# Emits weather_effect_finished(card_type) when done.
# Does NOT mutate the grid — game_manager handles that.
func play_card_resolution(card_type: int, target: Vector2i) -> void

# Plays the character walk along a precomputed path.
# Steps once per 250ms / speed_multiplier.
# Emits walk_started, then walk_finished on the last tile.
func play_character_walk(path: Array) -> void

# Plays a death animation for the given cause.
# Emits death_finished(cause) when done.
func play_character_death(cause: int) -> void

# Plays the win celebration. Emits cheer_finished when done.
func play_character_win() -> void

# --- Speed control ---

func set_speed_multiplier(multiplier: float) -> void
func toggle_fast_mode() -> void  # 1.0 ↔ 2.0

# --- Internal helpers (not part of the public contract) ---

func _resolve_card_animation(card_type: int) -> Dictionary
# Returns { duration_ms, frame_count, vfx_path } for the given card type.

func _spawn_tile_flash(pos: Vector2i, color: Color, duration_ms: int) -> void
# Spawns a pooled flash quad at the tile.

func _await_ms(ms: int) -> void
# Wraps get_tree().create_timer().timeout, scaled by speed_multiplier.

func _on_settings_changed(key: String, value: Variant) -> void
# Updates reduce_motion when SaveManager fires the signal.
```

**Implementation notes:**

1. `play_sequence` is the main entry point. It iterates the queue, calls `play_card_resolution` for each, awaits its completion, then awaits the 150 ms inter-card pause (if not in fast mode). After the queue is exhausted, it computes the path via Pathfinder and calls `play_character_walk`. After the walk, if the character died, it calls `play_character_death`; if it reached the goal, `play_character_win`.

2. `play_card_resolution` looks up timing for the card type from §3 of this doc, plays the VFX sprite sheet at the right frame rate, and emits `weather_effect_finished` after the total duration.

3. The character_controller owns position state. The animation_director only animates the visual sprite, not the logical position. They communicate via EventBus signals.

4. Reduce motion path: at the top of every public method, check `if reduce_motion: <play minimal version>; return`. The minimal versions are documented in §7.

5. All `await` calls go through `_await_ms` so speed_multiplier and reduce_motion behavior are centralized.

---

## 10. Testing checklist

For each animation, the gameplay-programmer agent verifies:

- [ ] Plays at 60 fps on the target mobile device throughout
- [ ] Frame timings match this doc within ±10 ms tolerance
- [ ] Reduce motion fallback works and skips the right beats
- [ ] Fast mode (2×) compresses correctly
- [ ] Slow mode (0.5×) expands correctly
- [ ] No tween leaks across scene transitions (use `Performance.get_monitor(Performance.OBJECT_NODE_COUNT)` before/after)
- [ ] No particle emitters left active after animation completes
- [ ] Audio sync points hit on the correct frames
- [ ] Reduce motion respects all 13 entries in §7 table
- [ ] Skipping mid-animation (player hits SKIP) cleans up gracefully
- [ ] Lightning chain caps at 10 tile pulses (visual cap, not logic cap)
- [ ] Wind/fog area effects commit all tiles on the same frame (no stagger)

Run the integration test `test/test_animation_director.gd` after any changes.

---

## 11. What this doc supersedes

- The previous `docs/ANIMATION_DIRECTION_2D.md` stub
- Any `[CORE]` or `[MECH]` task in the old generator hand-coded section that referenced "animation timing" without specifics
- Generic "polish animations" tasks in older backlog files

If you find an older doc that describes animation behavior contradicting §3 or §4, this doc wins. Update the older doc in the same PR.
