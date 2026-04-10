# Weather Whether — Asset Manifest

> **Status:** Authoritative list of every art and audio asset the game needs for v1. Pairs with `docs/GAME_DESIGN.md`, `docs/UI_SCREENS.md`, `docs/ART_DIRECTION.md`, and `docs/ASSET_PROMPTS_GEMINI.md`.
>
> **For agents:** This manifest is the contract. The art-pipeline agent's job is to produce every file in this list. The gameplay-programmer agent expects every file to exist at the path listed. If you add or rename an asset, update this file in the same PR.
>
> **Last updated:** 2026-04-10

---

## Conventions

- **Pixel art**, all sprites at integer scale. Base unit is **16px**. Tiles are 16×16 source, rendered at 4x in-game. UI is 32px or 48px source.
- **Color palette**: 32 fixed colors. See `assets/styleguide/Assets.png`. **No anti-aliasing**, no gradients, no soft shadows except where explicitly noted (key art only).
- **Format**: PNG with transparency. Sprite sheets are horizontal strips of frames.
- **Naming**: `snake_case`. State variants: `_default`, `_pressed`, `_disabled`, `_glow`. Animation frames: numbered suffix `_01.png` through `_NN.png` OR a single horizontal strip with `frames=N` in the import file.
- **Import settings**: filter=Nearest (no smoothing), mipmaps=off, repeat=disabled.

Per-category counts at the bottom.

---

## 1. Tile sprites

Path: `assets/sprites/tiles/`

Source size: **16×16 px**. Each terrain has a base sprite, and most have an "edge" variant (4 directions for clean borders). Edge variants are optional for v1 — flat tiles are acceptable launch quality.

| File | Description | Frames | Source size |
|---|---|---|---|
| `tile_empty.png` | Pit / void — checkered dark pattern | 1 | 16×16 |
| `tile_dry_grass.png` | Default grass tile | 1 | 16×16 |
| `tile_wet_grass.png` | Wet grass with droplets | 1 | 16×16 |
| `tile_water.png` | Animated water — 4 frame loop | 4 | 16×16 |
| `tile_ice.png` | Frozen with crack details | 1 | 16×16 |
| `tile_mud.png` | Muddy brown with squelch detail | 1 | 16×16 |
| `tile_snow.png` | White with flakes | 1 | 16×16 |
| `tile_scorched.png` | Burnt black with embers | 2 | 16×16 |
| `tile_steam.png` | Translucent rising steam | 4 | 16×16 |
| `tile_plant.png` | Green seedling/sapling | 1 | 16×16 |
| `tile_stone.png` | Gray stone block, impassable | 1 | 16×16 |
| `tile_fog_covered.png` | Foggy slate-gray with low-opacity drift | 4 | 16×16 |
| `tile_start.png` | Glowing welcome mat | 1 | 16×16 |
| `tile_goal.png` | Red flag, animated waving | 4 | 16×16 |

**Total tile assets: 14 base sprites, ~28 frames total.**

### Tile transition animations (optional, v1.1)

Short 4-frame strips played when a tile changes state. Skip for v1 launch — use a simple particle burst at the tile center instead.

---

## 2. Weather card sprites

Path: `assets/sprites/cards/`

Source size: **32×48 px** for the card body, **32×32 px** for the icon alone. Each card has 4 visual states.

| File | Description | Source size |
|---|---|---|
| `card_rain_default.png` | Rain card, idle | 32×48 |
| `card_rain_pressed.png` | Rain card, finger down | 32×48 |
| `card_rain_disabled.png` | Rain card, exhausted (in queue) | 32×48 |
| `card_rain_glow.png` | Rain card, selected/lifted | 32×48 |
| `card_sun_*.png` | Same 4 states | 32×48 |
| `card_frost_*.png` | Same 4 states | 32×48 |
| `card_wind_*.png` | Same 4 states | 32×48 |
| `card_lightning_*.png` | Same 4 states | 32×48 |
| `card_fog_*.png` | Same 4 states | 32×48 |
| `card_icon_rain.png` | Just the icon, for HUD/queue strip | 32×32 |
| `card_icon_sun.png` | " | 32×32 |
| `card_icon_frost.png` | " | 32×32 |
| `card_icon_wind.png` | " | 32×32 |
| `card_icon_lightning.png` | " | 32×32 |
| `card_icon_fog.png` | " | 32×32 |

**Total card assets: 30 sprites (24 cards + 6 icons).**

---

## 3. Character (Sky) sprites

Path: `assets/sprites/character/`

Source size: **24×24 px** (16 is too small for expressive death anims, 32 too big for a single tile). The character renders 1.5x the tile size — slightly oversized for visual prominence.

| File | Description | Frames | Animation length |
|---|---|---|---|
| `sky_idle.png` | Idle bob, looped | 4 | 500ms |
| `sky_surprised.png` | Reaction to nearby card placement | 2 | 200ms one-shot |
| `sky_walk_n.png` | Walking north | 4 | 250ms loop |
| `sky_walk_s.png` | Walking south | 4 | 250ms loop |
| `sky_walk_e.png` | Walking east | 4 | 250ms loop |
| `sky_walk_w.png` | Walking west | 4 | 250ms loop |
| `sky_cheer.png` | Win pose, jumps once | 6 | 700ms one-shot |
| `sky_drown.png` | Splashes, sinks | 5 | 600ms one-shot |
| `sky_burn.png` | Catches fire, becomes ash | 6 | 700ms one-shot |
| `sky_electrocute.png` | White flash, skeleton flicker | 4 | 500ms one-shot |
| `sky_freeze.png` | Frozen statue | 5 | 600ms one-shot |
| `sky_fall.png` | Drops below grid plane | 4 | 500ms one-shot |

**Total character assets: 12 sprite sheets, ~52 frames total.**

The character is **gender-neutral** and **wears a hooded cape**. Reference: small Celeste-style figures, Sword & Sworcery sage. NOT chibi anime style.

---

## 4. Weather VFX sprites

Path: `assets/sprites/vfx/`

These are spawned on top of tiles when weather effects resolve. They are decorative — gameplay state lives in the tile sprites underneath.

Source size: **32×32 px** unless noted.

| File | Description | Frames |
|---|---|---|
| `vfx_rain_burst.png` | Rain droplets falling on a single tile | 6 |
| `vfx_sun_pulse.png` | Warm radial pulse | 5 |
| `vfx_frost_crystal.png` | Ice crystals growing outward | 6 |
| `vfx_wind_sweep.png` | Directional gust streaks (3-tile wide) | 5, 96×32 |
| `vfx_lightning_bolt.png` | Single sharp bolt + afterglow | 4 |
| `vfx_lightning_chain.png` | Arc connecting two tiles | 4, variable width |
| `vfx_fog_roll.png` | Fog rolling in (3×3 area) | 6, 48×48 |
| `vfx_splash.png` | Water splash (used by drown death) | 5 |
| `vfx_flame.png` | Flame particles (used by burn death and SCORCHED tiles) | 6 |
| `vfx_sparkle.png` | Generic golden sparkle | 4 |
| `vfx_dust.png` | Generic dust puff | 4 |
| `vfx_confetti.png` | Win celebration | 8 |

**Total VFX assets: 12 sprite sheets, ~63 frames.**

---

## 5. UI sprites

Path: `assets/sprites/ui/`

Source size: varies per element. All UI is **32×32** or larger.

### Buttons

| File | Description | Source size |
|---|---|---|
| `button_primary_default.png` | Big blue button | 96×24 |
| `button_primary_pressed.png` | Big blue button, depressed | 96×24 |
| `button_primary_disabled.png` | Big blue button, gray | 96×24 |
| `button_success_default.png` | Big green PLAY SEQUENCE button | 96×24 |
| `button_success_pressed.png` | " | 96×24 |
| `button_secondary_default.png` | Smaller dark button | 64×20 |
| `button_secondary_pressed.png` | " | 64×20 |
| `button_secondary_disabled.png` | " | 64×20 |
| `button_icon_default.png` | 24×24 icon button frame | 24×24 |
| `button_icon_pressed.png` | " | 24×24 |

### Frames and panels

| File | Description | Source size |
|---|---|---|
| `panel_navy.png` | 9-slice navy panel | 32×32 |
| `panel_navy_alt.png` | Inset variant | 32×32 |
| `frame_gold.png` | 9-slice gold border frame for modals | 32×32 |
| `frame_red.png` | Red border for level failed | 32×32 |
| `frame_amber.png` | Amber border for warnings | 32×32 |
| `divider.png` | Horizontal line divider | 96×4 |

### Icons

| File | Description | Source size |
|---|---|---|
| `icon_back.png` | Left arrow | 24×24 |
| `icon_pause.png` | Pause icon | 24×24 |
| `icon_play.png` | Play triangle | 24×24 |
| `icon_settings.png` | Gear | 24×24 |
| `icon_undo.png` | Curved undo arrow | 24×24 |
| `icon_redo.png` | Curved redo arrow | 24×24 |
| `icon_hint.png` | Lightbulb | 24×24 |
| `icon_lock.png` | Padlock for locked levels | 24×24 |
| `icon_speed.png` | Fast-forward | 24×24 |
| `icon_close.png` | X | 24×24 |
| `icon_check.png` | Checkmark | 24×24 |
| `star_filled.png` | Gold star | 24×24 |
| `star_empty.png` | Empty star outline | 24×24 |
| `star_burst.png` | Star burst particle | 32×32 |

### World select cards

| File | Description | Source size |
|---|---|---|
| `world_card_w1.png` | Downpour painterly biome | 240×160 |
| `world_card_w2.png` | Heatwave painterly biome | 240×160 |
| `world_card_w3.png` | Cold Snap painterly biome | 240×160 |
| `world_card_w4.png` | Gale Force painterly biome | 240×160 |
| `world_card_w5.png` | Thunderstorm painterly biome | 240×160 |
| `world_card_w6.png` | Whiteout painterly biome | 240×160 |

### Level select backgrounds

| File | Description | Source size |
|---|---|---|
| `world_bg_w1.png` | Full vertical biome painting | 360×800 |
| `world_bg_w2.png` | " | 360×800 |
| `world_bg_w3.png` | " | 360×800 |
| `world_bg_w4.png` | " | 360×800 |
| `world_bg_w5.png` | " | 360×800 |
| `world_bg_w6.png` | " | 360×800 |
| `node_complete.png` | Green level node | 32×32 |
| `node_current.png` | Blue pulsing node | 32×32 |
| `node_locked.png` | Dark silhouette node | 32×32 |
| `path_dash.png` | Dashed path segment | 16×4 |

### Splash and home

| File | Description | Source size |
|---|---|---|
| `wordmark.png` | Big "Weather Whether" wordmark | 480×120 |
| `wordmark_small.png` | Small home variant | 240×60 |
| `splash_clouds.png` | Parallax cloud band | 640×80 |
| `home_hero.png` | Painterly home key art | 480×320 |

### Level complete

| File | Description | Source size |
|---|---|---|
| `level_complete_sunrise_w1.png` | Win celebration sky for world 1 | 360×280 |
| `level_complete_sunrise_w2.png` | " | 360×280 |
| ... (one per world) ... | | |
| `confetti_burst.png` | Confetti explosion sprite | 96×96 |

**Total UI assets: ~70 individual files.**

### Note on painterly art

The world cards, world backgrounds, home hero, splash clouds, and sunrise key art are the **painterly** assets — they're allowed to be high-resolution detailed paintings, not pixel art. They're the only exception to the pixel-art rule. Generate via Gemini Imagen or Midjourney with prompts in `docs/ASSET_PROMPTS_GEMINI.md`. Everything else stays pixel.

---

## 6. Fonts

Path: `assets/fonts/`

| File | Use | Source |
|---|---|---|
| `whether_display.ttf` | Wordmark, large titles, level numbers | Pixel serif. Recommendation: **Pixelify Sans** (Google Fonts, OFL) or commission. |
| `whether_body.ttf` | All UI body text | Pixel sans. Recommendation: **Press Start 2P** (Google Fonts, OFL) sized down, or **m5x7** by Damien Guard. |
| `whether_numbers.ttf` | Move counter, star counts (monospace digits) | Same as display, monospace variant. |

License every font with OFL or commercial-with-redistribution. Document license in `assets/fonts/LICENSES.md`.

---

## 7. Audio assets

Path: `assets/audio/`

### Music — `assets/audio/music/`

Format: `.ogg` Vorbis, stereo, 44.1kHz. Looping (set loop point in import).

| File | World | Mood | Length |
|---|---|---|---|
| `music_w1_downpour.ogg` | Downpour | Gentle, contemplative | 2:30 loop |
| `music_w2_heatwave.ogg` | Heatwave | Warm, slow | 2:30 loop |
| `music_w3_coldsnap.ogg` | Cold Snap | Crystalline, sparse | 2:30 loop |
| `music_w4_galeforce.ogg` | Gale Force | Airy, motion | 2:30 loop |
| `music_w5_thunderstorm.ogg` | Thunderstorm | Tense, low strings | 2:30 loop |
| `music_w6_whiteout.ogg` | Whiteout | Mysterious, choral | 2:30 loop |
| `music_menu.ogg` | Home / world select | Reflective | 1:30 loop |
| `music_level_complete.ogg` | Win sting | Triumphant flourish | 4 sec one-shot |

### Ambient — `assets/audio/ambient/`

| File | World |
|---|---|
| `ambient_rain.ogg` | W1 |
| `ambient_cicadas.ogg` | W2 |
| `ambient_wind_cold.ogg` | W3 |
| `ambient_wind_strong.ogg` | W4 |
| `ambient_thunder_distant.ogg` | W5 |
| `ambient_silence_low.ogg` | W6 (very subtle hum) |

### SFX — `assets/audio/sfx/`

Format: `.wav`, mono, 44.1kHz, normalized. Each ~0.2-1.5 sec.

**Card placement (planning):**
- `sfx_card_select.wav`
- `sfx_card_queue.wav`
- `sfx_card_unqueue.wav`

**Card resolution (sequence playback):**
- `sfx_weather_rain.wav`
- `sfx_weather_sun.wav`
- `sfx_weather_frost.wav`
- `sfx_weather_wind.wav`
- `sfx_weather_lightning.wav`
- `sfx_weather_fog.wav`

**Character:**
- `sfx_step_grass.wav`
- `sfx_step_ice.wav`
- `sfx_step_mud.wav`
- `sfx_step_snow.wav`

**Death (5 variants, even though only 3 ship in v1):**
- `sfx_death_drown.wav`
- `sfx_death_burn.wav`
- `sfx_death_electrocute.wav`
- `sfx_death_freeze.wav`
- `sfx_death_fall.wav`

**Win/lose:**
- `sfx_win_sting.wav`
- `sfx_lose_sting.wav`
- `sfx_no_path.wav`

**UI:**
- `sfx_button_tap.wav`
- `sfx_button_release.wav`
- `sfx_modal_open.wav`
- `sfx_modal_close.wav`
- `sfx_level_unlock.wav`
- `sfx_world_unlock.wav`
- `sfx_star_award.wav`
- `sfx_denied.wav` (locked level tap)

**Total audio assets: 8 music tracks, 6 ambient layers, 30 SFX files.**

---

## 8. Per-world summary table

| World | Music | Ambient | World Card | World BG | Sunrise |
|---|---|---|---|---|---|
| 1 Downpour | ✅ | ✅ | ✅ | ✅ | ✅ |
| 2 Heatwave | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3 Cold Snap | ✅ | ✅ | ✅ | ✅ | ✅ |
| 4 Gale Force | ✅ | ✅ | ✅ | ✅ | ✅ |
| 5 Thunderstorm | ✅ | ✅ | ✅ | ✅ | ✅ |
| 6 Whiteout | ✅ | ✅ | ✅ | ✅ | ✅ |

Per-world art deliverables: 4 painterly images + 1 music track + 1 ambient layer = **6 assets per world × 6 worlds = 36 unique art/audio assets** at the per-world level, on top of the shared sprite library.

---

## 9. Counts at a glance

| Category | Files | Frames |
|---|---|---|
| Tiles | 14 | ~28 |
| Cards | 30 | 30 |
| Character | 12 | ~52 |
| VFX | 12 | ~63 |
| UI | ~70 | ~80 |
| Per-world art | 24 | 24 |
| Fonts | 3 | — |
| Music | 8 | — |
| Ambient | 6 | — |
| SFX | 30 | — |
| **Total** | **~209 files** | **~277 frames** |

This is a real but tractable list for a solo dev with AI assistance. About 60% of art can be Gemini-generated and hand-cleaned in Aseprite. The remaining 40% (especially the character animations) need hand-pixel-art or commissioned work.

---

## 10. Pipeline notes for the art-pipeline agent

1. **Source files** (`.aseprite`, `.psd`, `.kra`) live in `art/working/` (gitignored). Only export `.png` and `.ogg`/`.wav` to `assets/`.
2. **Reference sheets** generated by Gemini live in `art/reference/` with date prefixes. Never ship them.
3. **Style guide canonical** is `assets/styleguide/Assets.png`. New tile art must visually match this sheet.
4. **Animation export**: each animation is a horizontal strip PNG. Frame width is constant per file. Set `animation_frames` in the import file.
5. **Power-of-2 textures preferred** for mobile but not required for tiny sprites.
6. **Atlas packing** is handled by Godot at import — do NOT pre-pack atlases.
7. **Naming exceptions** logged in `assets/NAMING_EXCEPTIONS.md` if the convention conflicts with a third-party tool (LDtk, Aseprite tags, etc.).

---

## 11. What's NOT in the manifest

- **No 3D models.** This is a pure 2D pixel art game.
- **No video files.** Cutscenes (if added in v1.5) will be Spine animations or frame-by-frame, not video.
- **No localized art.** Text is rendered in font, never baked into images. (Wordmark is the only exception — and we ship one per supported language eventually.)
- **No social media assets.** Those live in `marketing/` and are tracked separately by release-ops.
- **No store-page art.** Steam capsule, Apple screenshots, Google Play feature graphic — release-ops scope.

---

## Mock pack (reference only, not shipped)

Located at assets/mocks/. SVG placeholder mocks for AI agent visual reference
during implementation. NOT shippable game assets.

| File | Purpose |
|---|---|
| README.md | Contract — what mocks are, how agents use them, what they exclude |
| tiles.svg | All 14 v2 terrain types with locked colors and colorblind-safe pattern cues |
| cards.svg | All 6 weather cards at 96×144 with per-card colors from ART_DIRECTION.md §4 |
| character.svg | All 10 Sky character states (idle, walk, surprised, cheer, drown, burn, fall, electrocute v1.5, freeze v1.5, hidden) |
| level_mockup.svg | Full 360×640 mobile gameplay screen layout (HUD, grid, queue, hand, PLAY SEQUENCE) |
| world_select.svg | 360×640 world picker with 6 world cards showing locked/unlocked/in-progress states |
| level_select.svg | 360×800 vertical scrolling world map with 22 level nodes and winding path |
| level_complete.svg | Win screen with painterly sunrise placeholder, 3-star rating, stats, NEXT LEVEL |
| level_failed.svg | Loss screen with cause illustration, reason text, TRY AGAIN, hint, skip options |
| pause_menu.svg | Modal pause overlay with RESUME, RESTART, HINT, SETTINGS, QUIT over darkened gameplay |
| weather_resolve_sequence.svg | 760×420 4-panel storyboard of PLANNING → RESOLVING → WALKING → COMPLETE transitions |
| gameplay_desktop.svg | 1920×1080 desktop/Steam gameplay layout with three-column landscape, 100px grid, keyboard overlays |
| world_select_desktop.svg | 1920×1080 desktop world picker with 3×2 grid, biome thumbnails, keyboard focus and shortcut hints |

Updates to the mock pack happen via Linear tickets against assets/mocks/.
Real pixel art is generated separately per docs/ART_DIRECTION.md and
docs/ASSET_PROMPTS_GEMINI.md.
