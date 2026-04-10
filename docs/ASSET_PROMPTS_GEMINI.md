# Asset Prompts for Gemini Imagen / Midjourney (v2)

> **Status:** Replaces the v1 generic prompts. Pairs with `docs/ART_DIRECTION.md`, `docs/ASSET_MANIFEST.md`, `docs/UI_SCREENS.md`.
>
> **For the art-pipeline agent:** These are generation prompts for Gemini Imagen, Midjourney, or any comparable image model. Run them, save the references to `art/reference/YYYY-MM-DD-description.png`, then quantize and clean per the pipeline in `docs/ART_DIRECTION.md` §8.
>
> **Last updated:** 2026-04-10

---

## How to use this file

Each prompt has four parts:

1. **Subject** — what to generate
2. **Style anchor** — keywords that lock the visual language (paste these verbatim)
3. **Negative prompt** — what to exclude (some models support this directly; for others, append "no X, no Y" to the main prompt)
4. **Reject if** — quick visual checks to throw away bad outputs before committing time to cleanup

For **pixel art** prompts, expect to generate 4-8 candidates, pick 1, then spend 2-4× the generation time on Aseprite cleanup. AI pixel art is always slightly off and needs hand fixing.

For **painterly** prompts, expect to generate 2-4 candidates and pick 1. Painterly outputs need less cleanup but should be color-graded to match the world palette in Photoshop / Krita.

---

## Style anchors (paste verbatim into every prompt)

### Pixel art anchor

```
pixel art, 16-bit era SNES style, hard-edged, no anti-aliasing, no smoothing,
limited palette of 32 colors, flat shading with at most 3 value bands,
clear silhouette, top-down or 3/4 isometric perspective, transparent background,
single-tile composition, game asset
```

### Painterly anchor

```
painterly digital illustration, visible brushstrokes, soft atmospheric lighting,
golden hour warmth, cinematic composition, low horizon line, sky takes 60% of frame,
Studio Ghibli background style, Sea of Stars environment art reference,
hopeful and contemplative mood, no characters, landscape focus
```

### Universal negative prompt

```
no anti-aliasing, no blur, no gradients, no soft edges, no photorealism,
no anime characters, no text, no UI elements, no logos, no watermarks,
no 3D rendering, no specular highlights, no PBR materials
```

---

## 1. Tile sprites (pixel art, 16×16 source)

Generate each at 256×256 (4× the source size) and downsample to 16×16 in Aseprite.

### `tile_dry_grass.png`

**Subject:** Top-down grass tile, dry late-summer grass, slightly yellowed, with subtle blade texture.

**Prompt:**
```
[pixel art anchor]. Top-down view of a single 16x16 grass tile. Dry yellow-green
grass, individual blade pixels visible, faint brown soil showing through in a few
spots. Tileable edges. Bright daytime lighting from top-left.
[negative prompt]
```

**Reject if:** smooth gradient instead of pixel blades, anti-aliased edges, drop shadow.

---

### `tile_wet_grass.png`

**Subject:** Same grass tile but rain-soaked, with visible droplets.

**Prompt:**
```
[pixel art anchor]. Top-down view of a single 16x16 grass tile after rain.
Saturated dark green grass, 3-4 visible water droplets as small white pixel clusters,
slight blue-grey reflection on the wettest spots. Tileable edges.
[negative prompt]
```

**Reject if:** rain falling in the air (we want post-rain), too dark to read, no droplets visible.

---

### `tile_water.png` (4-frame loop)

**Subject:** Animated water tile, gentle ripple loop.

**Prompt:**
```
[pixel art anchor]. Top-down view of a single 16x16 water tile. Deep blue base
color, 2 lighter cyan ripple highlights, 1 white sparkle. Generate as a 4-frame
horizontal sprite strip showing the ripples shifting position smoothly across the
4 frames. Tileable edges. Total strip size 64x16.
[negative prompt]
```

**Reject if:** frames don't loop seamlessly, ripples too small to see, water looks flat.

---

### `tile_ice.png`

**Subject:** Frozen tile with visible cracks (the cracks are the colorblind-safe pattern cue).

**Prompt:**
```
[pixel art anchor]. Top-down view of a single 16x16 ice tile. Pale ice-blue base,
3-4 white crack lines branching across the surface, faint shadow on one edge.
Cracks are the most distinctive feature. Tileable edges.
[negative prompt]
```

**Reject if:** no cracks visible, too white (must read as ice not snow), gradient instead of flat shading.

---

### `tile_mud.png`

**Subject:** Wet mud tile, brown and squishy-looking.

**Prompt:**
```
[pixel art anchor]. Top-down view of a single 16x16 mud tile. Dark warm brown,
3-4 darker brown puddles, faint reflective shine on one puddle. Tileable edges.
[negative prompt]
```

---

### `tile_snow.png`

**Subject:** Fresh snow tile, white with subtle texture.

**Prompt:**
```
[pixel art anchor]. Top-down view of a single 16x16 fresh snow tile. Pure white
base, 3-4 pale blue shadow specks for texture, 1-2 tiny darker blue dots for
depth. Slight bluish tint on one edge for shadow direction. Tileable edges.
[negative prompt]
```

**Reject if:** pure white with no texture (unreadable), looks like ice (blue cracks).

---

### `tile_scorched.png`

**Subject:** Burned earth, the death-by-fire tile.

**Prompt:**
```
[pixel art anchor]. Top-down view of a single 16x16 scorched earth tile. Charred
black base, 2-3 dark red ember dots, faint grey ash specks, irregular cracked
pattern across the surface. Should look dangerous and dead. Tileable edges.
[negative prompt]
```

**Reject if:** flames visible (we're showing AFTER burning), too dark to read.

---

### `tile_steam.png` (4-frame loop)

**Subject:** Animated steam wisps rising from a tile.

**Prompt:**
```
[pixel art anchor]. Top-down view of a 16x16 steam tile. Dark base barely visible,
white-grey wisps rising and curling. Generate as a 4-frame horizontal sprite strip
showing the steam shifting upward and outward. Steam should look ephemeral, not
solid. Total strip size 64x16.
[negative prompt]
```

---

### `tile_plant.png`

**Subject:** Small green seedling/sapling, the growable terrain.

**Prompt:**
```
[pixel art anchor]. Top-down view of a single 16x16 plant tile. Dark soil base,
small bright green sapling in the center with 2-3 visible leaves, single small
stem. Friendly, cared-for look. Tileable edges.
[negative prompt]
```

---

### `tile_stone.png`

**Subject:** Stone wall block, impassable level geometry.

**Prompt:**
```
[pixel art anchor]. Top-down view of a single 16x16 stone wall tile. Gray cobblestone
texture with 4-5 distinct stones visible, dark mortar lines between them, faint
highlight on the top-left of each stone. Should look solid and impassable.
Tileable edges.
[negative prompt]
```

---

### `tile_fog_covered.png` (4-frame loop)

**Subject:** Foggy slate-gray tile that hides what's underneath.

**Prompt:**
```
[pixel art anchor]. Top-down view of a 16x16 fog-covered tile. Slate gray base,
3-4 lighter grey wisp swirls. Generate as a 4-frame horizontal sprite strip showing
the wisps drifting slowly. Should feel mysterious and obscuring. Total strip 64x16.
[negative prompt]
```

---

### `tile_start.png`

**Subject:** The character spawn tile, a glowing welcome marker.

**Prompt:**
```
[pixel art anchor]. Top-down view of a single 16x16 start tile. Stone or wood floor
base, glowing golden circle pattern in the center, faint warm light radiating outward,
inviting and welcoming look. Tileable edges.
[negative prompt]
```

---

### `tile_goal.png` (4-frame loop)

**Subject:** Win-condition tile with a waving flag.

**Prompt:**
```
[pixel art anchor]. Top-down view of a 16x16 goal tile. Stone floor base, small
red flag on a wooden pole in the center, flag waving subtly. Generate as a 4-frame
horizontal sprite strip showing the flag wave cycle. Total strip 64x16.
[negative prompt]
```

**Reject if:** flag doesn't wave (looks static across frames), no pole, wrong color (must be red).

---

### `tile_empty.png`

**Subject:** A pit/void tile, dangerous-looking.

**Prompt:**
```
[pixel art anchor]. Top-down view of a single 16x16 empty pit tile. Deep dark
checkered void pattern, no ground, faint dark blue glow at the edges suggesting
depth. Should clearly read as "you would fall here". Tileable edges.
[negative prompt]
```

---

## 2. Weather card sprites (pixel art, 32×48 source)

Each card has 4 states (default, pressed, disabled, glow) plus a standalone 32×32 icon. Generate a single 32×48 prompt and produce variants in Aseprite.

### `card_rain` family

**Subject:** Weather card showing rain.

**Prompt:**
```
[pixel art anchor]. Single playing card 32x48 pixels, vertical orientation.
Blue card frame with white border, top label "RAIN", center icon of falling
rain droplets in a cloud silhouette, bottom area shows the cost number "1".
Background of card is cyan blue (#3aa8e8). Inner illustration is white pixels.
Game UI card style, clean and readable.
[negative prompt]
```

### `card_sun`

```
[pixel art anchor]. Single playing card 32x48 pixels, vertical orientation.
Amber/orange card frame, top label "SUN", center icon of a sun with rays,
bottom area shows cost number "1". Card background amber (#f0b340), inner
illustration is white pixels. Game UI card style.
[negative prompt]
```

### `card_frost`

```
[pixel art anchor]. Single playing card 32x48 pixels, vertical orientation.
Pale ice-blue card frame, top label "FROST", center icon of a snowflake
or ice crystal, bottom shows cost "1". Card background ice blue (#7ad8e8),
inner illustration white. Game UI card style.
[negative prompt]
```

### `card_wind`

```
[pixel art anchor]. Single playing card 32x48 pixels, vertical orientation.
Sage green card frame, top label "WIND", center icon of swirling wind lines
or a small cyclone, bottom shows cost "1". Background green (#5fc97e),
illustration white. Game UI card style.
[negative prompt]
```

### `card_lightning`

```
[pixel art anchor]. Single playing card 32x48 pixels, vertical orientation.
Violet card frame, top label "LIGHT" (abbreviation for lightning), center
icon of a lightning bolt, bottom shows cost "1". Background violet (#a06fe8),
illustration white-yellow. Card should look slightly more dangerous than the
others. Game UI card style.
[negative prompt]
```

### `card_fog`

```
[pixel art anchor]. Single playing card 32x48 pixels, vertical orientation.
Slate grey card frame, top label "FOG", center icon of a wavy horizontal
fog cloud, bottom shows cost "1". Background slate (#8a9bb4), illustration
white. Card should look mysterious. Game UI card style.
[negative prompt]
```

---

## 3. Sky character (pixel art, 24×24 source)

Sky is gender-neutral, hooded, expressive in silhouette. The character is the heart of the game per `GAME_DESIGN.md` §4 — invest extra cleanup time here.

### `sky_idle` (4 frames, 96×24 strip)

**Subject:** Default standing pose with subtle bob animation.

**Prompt:**
```
[pixel art anchor]. 24x24 character sprite. Small hooded figure in blue-grey cloak,
gender-neutral, no visible face (just a darker hood interior with two small eye dots).
Brown boots. Standing facing the viewer. Generate as a 4-frame horizontal animation
strip 96x24, showing a subtle vertical bob animation: frame 1 base position, frame 2
1px up, frame 3 base, frame 4 1px down. Calm and curious posture.
[negative prompt]. No anime style, no big eyes, no chibi proportions.
```

**Reject if:** face is detailed (we want hood-shadow only), anime style, proportions wrong, frames don't loop.

### `sky_walk_n` `sky_walk_s` `sky_walk_e` `sky_walk_w` (4 frames each)

**Subject:** Walking animation in each cardinal direction.

**Prompt template (substitute direction):**
```
[pixel art anchor]. 24x24 character sprite. Same hooded figure as idle.
Walking [DIRECTION] (north/south/east/west). Generate as a 4-frame horizontal
animation strip 96x24 showing a clean walk cycle: leg forward, mid-step, opposite
leg forward, mid-step. Cloak should have subtle motion. Frame 1 and frame 3 are
"contact" poses, 2 and 4 are "passing" poses.
[negative prompt]
```

Generate 4 versions, one per direction. East and West are mirrors of each other.

### `sky_cheer` (6 frames, 144×24 strip)

**Prompt:**
```
[pixel art anchor]. 24x24 character sprite. Same hooded figure. Win celebration
animation: arms raise upward, character jumps once, lands. Generate as a 6-frame
horizontal animation strip 144x24. Frame 1 idle, frame 2 arms starting up,
frame 3 arms full up + jumping, frame 4 peak of jump, frame 5 landing, frame 6
back to idle pose with arms still slightly raised. Joyful but contained.
[negative prompt]
```

### `sky_drown` (5 frames)

**Prompt:**
```
[pixel art anchor]. 24x24 character sprite. Same hooded figure. Drowning animation:
character is shocked, then sinks. Generate as a 5-frame horizontal strip 120x24.
Frame 1: surprised reaction with arms out. Frame 2: water splash particles around
character (white pixel cluster). Frame 3: character begins sinking, lower half
disappearing. Frame 4: only head and shoulders visible, blue-tinted. Frame 5:
final ripple, character gone, just water surface. Sad but not gory.
[negative prompt]. No blood, no horror imagery.
```

### `sky_burn` (6 frames)

**Prompt:**
```
[pixel art anchor]. 24x24 character sprite. Same hooded figure. Burning animation:
catches fire, becomes ash silhouette. Generate as a 6-frame horizontal strip 144x24.
Frame 1: surprised reaction. Frame 2: red flame particles erupt around feet, character
flashes red. Frame 3: orange flames cover lower body. Frame 4: character silhouette
becomes ash-grey. Frame 5: ash silhouette begins crumbling. Frame 6: small ash pile
on ground. Sad but not gory.
[negative prompt]. No blood, no horror imagery.
```

### `sky_fall` (4 frames)

**Prompt:**
```
[pixel art anchor]. 24x24 character sprite. Same hooded figure. Falling animation:
character walks off an edge. Generate as a 4-frame horizontal strip 96x24. Frame 1:
arms windmilling in surprise. Frame 2: feet leaving the ground, body tilting forward.
Frame 3: falling, character smaller (60% scale) with motion lines above. Frame 4:
tiny silhouette disappearing into darkness. Light dust particles at the original
position.
[negative prompt]
```

### `sky_electrocute` and `sky_freeze` (v1.5 — generate but don't ship in v1)

Use the same hooded figure base. Electrocute = white skeleton flicker through silhouette + electric arcs. Freeze = ice crystals growing up the body in 5 stages until fully encased statue.

---

## 4. Weather VFX sprite sheets (pixel art, 32×32 unless noted)

These overlay tiles when weather effects resolve. Particle-style, decorative.

### `vfx_rain_burst.png` (6 frames)

```
[pixel art anchor]. 32x32 weather effect sprite sheet, 6 frames horizontal (192x32).
Rain droplets falling onto a tile. Frame 1: 2 droplets above. Frame 2: 4 droplets,
some hitting. Frame 3: 6 droplets + small ripple ring. Frame 4: 4 droplets + larger
ripple. Frame 5: 2 droplets + fading ripple. Frame 6: just fading ripple. Cyan blue
droplets, white ripple rings, transparent background.
[negative prompt]
```

### `vfx_sun_pulse.png` (5 frames)

```
[pixel art anchor]. 32x32 weather effect sprite sheet, 5 frames horizontal (160x32).
Warm radial sun pulse expanding from center. Frame 1: small bright yellow center.
Frame 2: medium yellow disc with orange edge. Frame 3: large yellow-orange ring at
80% of tile width. Frame 4: ring fading at full tile width. Frame 5: barely visible
warm glow. Yellow-orange palette, transparent background.
[negative prompt]
```

### `vfx_frost_crystal.png` (6 frames)

```
[pixel art anchor]. 32x32 weather effect sprite sheet, 6 frames horizontal (192x32).
Ice crystals growing inward from the tile corners. Frame 1: tiny white crystal
specks at 4 corners. Frame 2: small crystal arms growing inward. Frame 3: crystals
halfway across. Frame 4: nearly meeting in center. Frame 5: full crystal pattern
covering tile. Frame 6: snap-frozen with white-blue highlight. Pale cyan-white,
transparent background.
[negative prompt]
```

### `vfx_wind_sweep.png` (5 frames, 96×32 wide for 3-tile cross)

```
[pixel art anchor]. 96x32 weather effect sprite sheet, 5 frames horizontal (480x32).
Directional wind gust streaks moving across a 3-tile-wide area. Frame 1: thin streak
lines starting on left. Frame 2: streaks at 30% across. Frame 3: streaks fully visible,
darker mid-streak. Frame 4: streaks at 70%, fading on left. Frame 5: streaks almost
gone on right. White-grey sage-tinted streaks, transparent background.
[negative prompt]
```

### `vfx_lightning_bolt.png` (4 frames)

```
[pixel art anchor]. 32x32 weather effect sprite sheet, 4 frames horizontal (128x32).
Lightning bolt striking a tile. Frame 1: bright white-violet vertical zigzag bolt
from top to bottom of tile. Frame 2: same bolt + white screen flash overlay (full
white tile). Frame 3: bolt fading, afterglow violet on tile. Frame 4: only faint
violet glow remaining. Sharp, dramatic, 1 frame total length 160ms.
[negative prompt]
```

### `vfx_fog_roll.png` (6 frames, 48×48 for 3×3 area)

```
[pixel art anchor]. 48x48 weather effect sprite sheet, 6 frames horizontal (288x48).
Fog rolling in to cover a 3x3 tile area. Frame 1: thin wisps at edges. Frame 2: wisps
moving inward. Frame 3: half coverage. Frame 4: 75% coverage with dense center.
Frame 5: full coverage settling. Frame 6: settled fog with subtle drift. Slate grey
wisps, transparent in unfogged areas.
[negative prompt]
```

### `vfx_splash.png`, `vfx_flame.png`, `vfx_sparkle.png`, `vfx_dust.png`, `vfx_confetti.png`

Each follows the same pattern. Simple particle bursts, 4-8 frames each, transparent background, palette-matched to their use case (water = cyan-white, flame = red-orange, sparkle = gold-white, dust = grey-tan, confetti = mixed festival colors).

---

## 5. UI sprites (pixel art, sizes vary)

### `button_primary_default.png` (96×24)

```
[pixel art anchor]. UI button 96x24 pixels. Bright blue rounded-rectangle button
with 2px darker blue border, slight inner highlight on top edge for depth.
Color #4a90e2. Empty interior (text added in-game). Game UI style, mobile-friendly,
chunky and clickable.
[negative prompt]. No text on the button, no icons, no gradient.
```

### `button_success_default.png` (96×24)

Same as above but green (#5fc97e). This is the PLAY SEQUENCE button style.

### `button_secondary_default.png` (64×20)

Smaller dark navy button (#142844) with light blue border (#3a5f8a).

### `panel_navy.png` (32×32, 9-slice)

```
[pixel art anchor]. UI panel 32x32 pixels, designed for 9-slice scaling. Dark navy
fill (#142844), 2px lighter blue border (#3a5f8a) on all 4 sides, 4px corner radius.
Empty interior. Should tile cleanly when scaled.
[negative prompt]
```

### `frame_gold.png` (32×32, 9-slice)

Same as `panel_navy.png` but with a thicker golden border (#f5e89c) for modal frames.

### Icons (24×24 each)

For each icon listed in `ASSET_MANIFEST.md` §5:

```
[pixel art anchor]. Single 24x24 icon pixel art. [DESCRIPTION]. White or light grey
on transparent background. Game UI icon style, readable at small scale, clear silhouette.
[negative prompt]
```

Substitute `[DESCRIPTION]` with: "left arrow" (back), "two vertical bars" (pause), "triangle pointing right" (play), "gear with 8 teeth" (settings), "curved arrow looping back" (undo), "lightbulb" (hint), "padlock closed" (lock), "fast-forward double-triangle" (speed), "X mark" (close), "checkmark" (check), "5-point star filled gold" (star_filled), "5-point star outline" (star_empty).

---

## 6. Painterly key art prompts (NOT pixel art)

These are the marketing-grade illustrations. Generate at 4× the source size and downsample carefully.

### `home_hero.png` (480×320 source, generate at 1920×1280)

**Subject:** A wide hero image for the home screen showing "the world of Weather Whether" — a montage feel of multiple biomes.

**Prompt:**
```
[painterly anchor]. A wide cinematic landscape composition showing a transition
between weather biomes: left third is a coastal valley with light rain falling
(World 1: Downpour), middle third is a sun-warmed Mediterranean hillside (World 2:
Heatwave), right third is a frosty alpine peak (World 3: Cold Snap). The transitions
between biomes are soft and dreamlike, like one continuous landscape. Golden hour
lighting unifies everything. No characters. 16:9 cinematic aspect ratio.
[negative prompt]
```

**Reject if:** characters appear, biomes have hard edges, photo-realistic, anime style.

### `world_card_w1.png` (240×160, generate at 960×640) — Downpour

**Subject:** Iconic biome illustration for World 1.

**Prompt:**
```
[painterly anchor]. World 1 Downpour biome card. Coastal valley with a winding
river snaking through it, low cliffs on either side, a distant lighthouse on a
headland on the right. Light rain falling from cool grey clouds. A break in the
clouds reveals a soft golden patch of sky on the horizon. Slate blue and sage green
palette with cream highlights. Hopeful melancholy mood. 3:2 aspect ratio.
[negative prompt]. No storms, no lightning, no dramatic angles, no characters.
```

### `world_card_w2.png` — Heatwave

```
[painterly anchor]. World 2 Heatwave biome card. Mediterranean hillside in late
afternoon sun. Dry yellow grass, scattered olive trees with grey-green foliage,
white limestone bluffs, terracotta-roofed buildings in the distance. Heat shimmer
visible above the ground. Burnt sienna, ochre, terracotta palette with pale gold
highlights. Drowsy warm mood. 3:2 aspect ratio.
[negative prompt]. No beach, no ocean, no tropical colors, no green lushness,
no characters.
```

### `world_card_w3.png` — Cold Snap

```
[painterly anchor]. World 3 Cold Snap biome card. Alpine valley after fresh snow.
Frozen river winding through pine forest dusted in snow, small log cabin with
smoking chimney in the middle distance. Dawn light, blue hour transitioning to
warm gold on the eastern peaks. Ice blue, white, pale lavender palette with
hints of pink in snow shadows. Crystalline still mood. 3:2 aspect ratio.
[negative prompt]. No blizzard, no Christmas iconography, no decorative snowflakes,
no characters.
```

### `world_card_w4.png` — Gale Force

```
[painterly anchor]. World 4 Gale Force biome card. High moor or steppe with tall
grass bending dramatically in the wind. A single windmill or stone tower in the
middle distance. A flock of birds wheeling against the sky. Cumulus clouds racing
across a wide blue sky. Sage green, slate, cream palette with warm grey highlights.
Wide and windy mood. 3:2 aspect ratio.
[negative prompt]. No tornadoes, no destruction, no dramatic storms, no characters.
```

### `world_card_w5.png` — Thunderstorm

```
[painterly anchor]. World 5 Thunderstorm biome card. Late dusk over rolling hills.
Massive anvil-shaped storm clouds backlit by the last sliver of sunset. A single
distant lightning bolt visible in the cloud bank. A small ruined stone tower
silhouetted in the foreground. Deep purple, bronze, charcoal palette with
white-violet lightning highlights. Tense beauty mood. 3:2 aspect ratio.
[negative prompt]. No apocalyptic vibes, no horror imagery, no heavy rain,
no characters.
```

### `world_card_w6.png` — Whiteout

```
[painterly anchor]. World 6 Whiteout biome card. Frozen tundra or high arctic.
A thick fog layer obscures the middle ground. A single distant figure silhouetted
on a small rise, barely visible through the fog. Faint suggestion of mountain
peaks beyond the fog. Off-white, pale grey, washed-out blue palette with faint
pastel highlights. Mysterious quiet mood. 3:2 aspect ratio.
[negative prompt]. No pure white frame (needs grounding detail), no blizzard,
no polar wildlife, no Christmas iconography.
```

### `world_bg_w1.png` through `world_bg_w6.png` (360×800, generate at 1440×3200)

**Subject:** Tall vertical extensions of each world card, used as scrollable backgrounds for the level select screen.

**Prompt template:**
```
[painterly anchor]. Tall vertical 9:20 portrait composition. Same biome and palette
as world_card_wN [insert world brief from above]. The scene extends vertically with
a winding path or river that travels from the bottom of the frame to the top. The
path should accommodate 22 stopping points (level nodes) along its length, evenly
distributed but with varied positioning (sometimes left, sometimes right, sometimes
center). Sky takes the top 30% of the frame, midground 40%, foreground 30%.
[negative prompt]. No characters, no game UI elements, no level number labels.
```

Generate one per world, swapping in the world-specific brief.

### `level_complete_sunrise_w1.png` through `_w6.png` (360×280, generate at 1440×1120)

**Subject:** Per-world celebration scene shown on the Level Complete screen.

**Prompt template:**
```
[painterly anchor]. Sunrise / golden hour celebration scene for the [WORLD NAME]
biome. Same palette and setting as world_card_wN but at the most beautiful moment
of the day — first light breaking through, warm rays. Composition is hopeful and
triumphant but quiet, not loud. 5:4 aspect ratio, slightly wider than tall.
[negative prompt]. No characters, no fireworks, no text, no UI.
```

### `splash_clouds.png` (640×80, generate at 2560×320)

```
[painterly anchor]. Wide horizontal cloud band suitable for parallax scrolling.
Soft cumulus clouds in a warm sunset palette, low contrast so it can sit behind
text without competing. 8:1 ultra-wide aspect ratio. Tileable horizontally if
possible.
[negative prompt]
```

---

## 7. Quality bar — when to regenerate vs. when to clean up

| Issue | Action |
|---|---|
| Anti-aliased edges on pixel art | **Regenerate** with stronger pixel art anchor |
| Wrong palette but correct composition | **Quantize in Aseprite**, no regen |
| Composition wrong | **Regenerate** with adjusted prompt |
| Character has visible face / anime style | **Regenerate**, the hood is non-negotiable |
| Painterly art looks photo-realistic | **Regenerate** with stronger painterly anchor |
| Painterly art has hard edges | **Regenerate** |
| Painterly mood doesn't match world brief | **Regenerate** |
| Off by one pixel after downsample | **Hand-fix in Aseprite** |
| Animation frame doesn't loop | **Hand-fix or regen**, depends on severity |

---

## 8. Saving and committing

1. Generated reference: `art/reference/2026-04-DD-asset-name.png` (gitignored)
2. Cleaned working file: `art/working/asset-name.aseprite` (gitignored)
3. Final exported sprite: `assets/sprites/category/asset_name.png` (committed)
4. Update `docs/ASSET_MANIFEST.md` if filename changes
5. Commit message: `art: add [category] [asset_name] sprite`
6. Open PR with the cleaned final + a side-by-side comparison vs. styleguide reference

---

## 9. What this doc replaces

- The previous `docs/ASSET_PROMPTS_GEMINI.md` (generic, no v2 mechanic alignment) — fully superseded
- Any prompts in older docs that reference the v1 6-terrain enum or instant-resolve cards
- Generic "weather effect" prompts without per-card timing or composition

If you find an older prompt that references v1 mechanics, flag it in your PR comment.
