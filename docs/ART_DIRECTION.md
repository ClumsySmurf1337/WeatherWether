# Art Direction (v2 — pixel art + painterly key art)

> **Status:** Replaces the v1 flat-shaded direction. Pairs with `docs/GAME_DESIGN.md`, `docs/UI_SCREENS.md`, `docs/ASSET_MANIFEST.md`, `docs/ANIMATION_DIRECTION_2D.md`, `docs/ASSET_PROMPTS_GEMINI.md`.
>
> **Last updated:** 2026-04-10
> **Owner:** art-pipeline agent

---

## 1. The two visual languages

Weather Whether uses **two distinct visual styles**, applied to non-overlapping parts of the game. This is intentional and load-bearing — they reinforce each other.

### Style A: Pixel art (the game itself)

Everything inside a level — tiles, character, weather effects, cards, UI buttons — is **pure pixel art** at integer scale. No anti-aliasing, no soft shadows, no gradients. 32-color palette locked.

**Mood vs. era:** The **visual target** is **bright, saturated, and readable** — modern indie puzzle / “HD pixel” clarity — as shown in `assets/styleguide/Level Mockup.png` and `assets/styleguide/Referene2.png`. That is **not** the same as **muted 16-bit console** or **SNES-era** shorthand; avoid those references in prompts. Technical constraints (palette, snapping, no-AA) stay strict; **lighting and saturation** follow the styleguide PNGs.

### Style B: Painterly key art (the in-between)

The home hero, world select cards, world map backgrounds, and level complete celebration scenes are **painterly illustrations**. Soft brushstrokes, atmospheric lighting, depth, color grading. Not pixel art.

The transition between the two happens at world select → level select → gameplay. The painterly biome you saw in world select becomes the painterly background of the level select map, and then the pixel-art level board sits *on top of* that painterly background — the pixel art literally sits on the painting. It feels like dropping into a postcard.

---

## 2. Pixel art rules

These are non-negotiable. Every pixel sprite the art-pipeline agent ships must satisfy all of them.

### Scale and grid

- **Base unit:** 16×16 pixels for tiles. 24×24 for the character. 32×32 for icons and VFX. 32×48 for cards.
- **Integer scale only.** Render at 4× in the game (so a 16×16 source tile is 64×64 on screen). Never 1.5×, never 2.7×.
- **Pixel-perfect snapping.** All transforms snap to whole pixels. Set Godot project: `rendering/2d/snap/snap_2d_transforms_to_pixel = true`, `snap_2d_vertices_to_pixel = true`.
- **Filter mode:** Nearest neighbor only. Never linear. Set in import settings per file.
- **No mipmaps.**

### Color

- **32-color palette.** Locked to `assets/styleguide/Assets.png`. Every sprite must pull from these 32 colors only — no in-between values.
- **No anti-aliasing.** Hard edges only. If a curve looks jagged, redraw it instead of softening.
- **No gradients.** Use 2-3 color shading bands instead.
- **No alpha blending** between colors except at the sprite edge against transparency. Inside a sprite, every pixel is a flat palette index.

### Composition

- **Readable silhouette first.** A pixel sprite must be identifiable by its silhouette alone before color. This is the test: render the sprite black-on-white at full size and ask "do I know what this is?"
- **Maximum 3 shading values** per sprite (highlight, base, shadow). More than 3 = overworked.
- **One light source per scene.** Top-left for outdoor, top for indoor. Be consistent.
- **Avoid pixel hunting.** No important detail smaller than 2×2 pixels. The player must read the screen at arm's length on a phone.

### Anti-patterns to reject

- Anti-aliased outlines ("blurry edges")
- HD pixel art that's actually high-res illustration with a pixel filter
- Inconsistent pixel scale within one sprite (e.g. 1px outline on a 4px-grid sprite)
- Gradients faked with dithering for "realism" — only use dithering for atmospheric texture in painterly key art, never in tiles
- Drop shadows
- Out-of-palette colors (any AI-generated sprite needs a color quantization pass)

---

## 3. Painterly key art rules

The painterly assets are the marketing face of the game. They sell the player on the world before they touch a card.

### What counts as painterly art

| Asset | Purpose |
|---|---|
| `home_hero.png` (480×320) | Splash and home screen background |
| `world_card_w1.png` through `w6.png` (240×160) | World select cards |
| `world_bg_w1.png` through `w6.png` (360×800) | Level select scrolling backgrounds |
| `level_complete_sunrise_w1.png` through `w6.png` (360×280) | Per-world celebration scene |
| `splash_clouds.png` (640×80) | Parallax cloud band |

That's it. Everything else in the game is pixel art.

### Style anchors

Reference points for the painterly style:

- **Mood:** Calm, hopeful, contemplative. Never grim, never cute, never twee.
- **Time of day:** Predominantly golden hour (warm low sun, long shadows). World 5 (Thunderstorm) is dusk-with-storms, World 6 (Whiteout) is overcast midday, but golden hour is the baseline.
- **Brushwork:** Visible but controlled. Looser than concept art, tighter than impressionism. Reference: Studio Ghibli backgrounds, *Gris*, *Sea of Stars* environment art, Ian McQue.
- **Composition:** Low horizon line. Sky is 60-70% of frame. Foreground silhouettes against the sky. The character's place in the world is implied (a path leading off, a small structure, a distant figure) but never the focus — the *world* is the focus.
- **Color:** Saturated but harmonious. Each world has a dominant temperature (W1 cool blue-green, W2 warm yellow-orange, W3 cyan-white, W4 sage-grey, W5 violet-bronze, W6 desaturated white-blue).

### What painterly art is NOT

- Not photorealistic
- Not anime (no character close-ups, no big eyes, no speed lines)
- Not vector art (no flat colors with hard edges — that's the pixel art's job)
- Not 3D-rendered (no specular highlights, no PBR materials)

---

## 4. Per-world art briefs

Each world has a fixed mood, palette, and reference. The art-pipeline agent generates all painterly assets for a world from the same brief so they feel cohesive.

### World 1 — Downpour

**Mood:** Gentle melancholy. Spring rain, fresh growth, hope arriving slowly.
**Palette:** Slate blue, sage green, soft cream, weathered grey-brown.
**Setting:** A coastal valley with a winding river, low cliffs, a distant lighthouse on a headland. Light rain falling. A break in the clouds revealing a soft golden patch of sky on the horizon.
**Avoid:** Storms, lightning, dramatic angles. This world is about *steady rain*, not weather as enemy.

### World 2 — Heatwave

**Mood:** Drowsy warmth. Late afternoon, summer haze, cicada-loud.
**Palette:** Burnt sienna, ochre, terracotta, dusty olive, pale gold.
**Setting:** Mediterranean hillside, dry grass, scattered olive trees, terracotta-roofed buildings in the distance, white limestone bluffs. Heat shimmer above the ground.
**Avoid:** Beach scenes, tropical colors, water (this is a *land* world). No green lushness.

### World 3 — Cold Snap

**Mood:** Crystalline stillness. The hush after fresh snowfall. Cold but not hostile.
**Palette:** Ice blue, white, pale lavender, cool grey, hint of pink in the snow shadows.
**Setting:** An alpine valley, frozen river, pine forest dusted in snow, small cabin with smoking chimney. Dawn light, blue hour transitioning to gold.
**Avoid:** Blizzards (that's W6), Christmas iconography, decorative snowflakes.

### World 4 — Gale Force

**Mood:** Wide and windy. Big sky, bigger horizon. The weather is in motion.
**Palette:** Sage green, slate, cream, warm grey, ochre highlights.
**Setting:** A high moor or steppe, tall grass bending in the wind, a single windmill or stone tower in the distance, a flock of birds wheeling. Cumulus clouds racing across.
**Avoid:** Tornadoes, destruction, dramatic storms. Wind here is *powerful but not violent*.

### World 5 — Thunderstorm

**Mood:** Tense beauty. The storm has arrived but is contained. Dangerous-looking, not dangerous-feeling.
**Palette:** Deep purple, bronze, charcoal, white-violet lightning highlights.
**Setting:** Late dusk over rolling hills, anvil-shaped storm clouds backlit by the last sun. A single bolt of lightning in the distance. A small ruined tower in the foreground silhouette.
**Avoid:** Apocalyptic vibes, horror imagery, heavy rain (let lightning carry the drama).

### World 6 — Whiteout

**Mood:** Mysterious and quiet. Visibility low, sound muffled. The most uncertain world.
**Palette:** Off-white, pale grey, washed-out blue, faint pastel highlights.
**Setting:** Frozen tundra or high arctic, fog layer obscuring the middle ground, a lone figure standing on a rise (silhouette), faint suggestion of mountains beyond the fog. No sky visible — fog and ground only.
**Avoid:** Pure white frame (needs grounding), blizzards, polar wildlife, anything cute.

---

## 5. UI design language (pixel + dark navy)

The UI sits between the two styles — it's pixel art (chunky borders, hard edges, no AA) but it lives over the painterly backgrounds. The navy frame gives it cohesion.

### Color tokens

Use only the tokens defined in `docs/UI_SCREENS.md` "Color tokens" table. Do not introduce new colors. If a new color seems necessary, raise it as a Linear ticket against this doc instead.

### Frames and panels

- **Panel borders:** 2px thick, color `border.frame` (#3a5f8a)
- **Panel fills:** `bg.panel` (#142844) or `bg.panel_alt` (#1f3a5c)
- **Corner radius:** 4-6 source pixels, never round
- **9-slice on all panels** so they scale per screen without distortion
- **Drop shadow:** None on UI. Depth comes from layering navy panels at different brightnesses.

### Buttons

Four states required for every button: `default`, `pressed`, `disabled`, `primary`. The `primary` state replaces `default` for the most important button on each screen (e.g. PLAY SEQUENCE). Reference: `docs/UI_SCREENS.md` Screen 5.

### Text

- **Display font** (titles, level numbers, wordmark): `whether_display.ttf` — pixel serif. White or `text.title` (#f5e89c).
- **Body font** (everything else): `whether_body.ttf` — pixel sans. `text.body` (#e8eef7) on dark, `bg.deep` on light buttons.
- **No text smaller than 12 device px** (3 source px at 4×). 16 device px minimum for body copy.
- **No bold weights** — use the display font for emphasis, not bold styling.

---

## 6. Color-blind & accessibility

Color is never the only signal. Every state has a shape or pattern cue too:

- WET_GRASS has visible droplets, not just darker green
- ICE has visible cracks, not just lighter blue
- SCORCHED has black ash specks, not just dark color
- FOG_COVERED has visible swirling lines, not just gray fill
- Cards have unique icons, not just colored backgrounds

The art-pipeline agent **must** test every tile sprite by rendering it in greyscale and verifying the state is still readable. If you can't tell WET_GRASS from DRY_GRASS in greyscale, redraw it.

Three color-blind palettes (Protanopia / Deuteranopia / Tritanopia) ship in v1. They are color shifts of the base 32-color palette, applied at runtime via a shader. The art-pipeline agent does NOT need to draw separate palettes — they're computed.

---

## 7. The styleguide is the source of truth

These files are the **canonical visual references** (palette + layout + overall brightness):

| File | Role |
|------|------|
| `assets/styleguide/Assets.png` | **32-color palette** swatches — quantization target for all pixel sprites |
| `assets/styleguide/Level Mockup.png` | **Gameplay + UI kit** — grid, cards, buttons, icons, chunky navy chrome, saturated terrain |
| `assets/styleguide/Referene2.png` | **Full-screen flows** — title, world select, level wireframes; confirms **painterly key art + pixel HUD** split |

New tile art, card art, and UI art must match the **feel** of those PNGs: **bright**, **high-contrast**, **tactile** — not dim retro-console mud. If generated art drifts toward generic “SNES-style” murk or wrong saturation, **re-prompt or redraw** against these references.

When the styleguide and this doc conflict, **the styleguide wins.** Update this doc in the same PR if you find a contradiction.

See also `assets/styleguide/README.md` for a short folder contract.

---

## 8. Pipeline workflow

**Platforms:** Author **one** sprite set (`docs/ASSET_MANIFEST.md`). **Desktop** and **mobile** use the same PNGs; framing differs via `docs/DISPLAY_PROFILE.md` (windowed 9:16 vs fullscreen). Validate gameplay HUD on both.

1. **Reference generation.** Use prompts in `docs/ASSET_PROMPTS_GEMINI.md` to generate references in Gemini Imagen / Midjourney. Save to `art/reference/YYYY-MM-DD-description.png`. Never ship references.
2. **Quantize.** Run all AI-generated pixel art through a 32-color palette quantizer (Aseprite "Color Mode > Indexed" or PixelPalette). Verify every pixel is on-palette.
3. **Hand cleanup.** Open in Aseprite. Remove off-palette pixels. Fix silhouette. Adjust shading bands. This step usually takes longer than the generation.
4. **Animation strips.** For animated sprites, lay out frames horizontally with constant frame width. Document frame count in the import file (`*.png.import`).
5. **Verify import.** Run the game with the new sprite. Check it renders pixel-perfect at 4× scale on a 1080p display.
6. **Greyscale test** for tiles and characters. If state is unreadable in greyscale, redraw.
7. **Commit** working file to `art/working/` (gitignored), exported PNG to `assets/sprites/...`. Update `docs/ASSET_MANIFEST.md` if filename changes.

Painterly assets skip steps 2-3 (no quantization, no Aseprite cleanup) but still need the verify and greyscale steps.

---

## 9. What this doc replaces

- The previous `docs/ART_DIRECTION.md` (flat-shaded 2D direction) — fully superseded
- Any references to "clean stylized 2D" or "limited palette per biome" in older docs
- Generic asset prompts in the previous `docs/ASSET_PROMPTS_GEMINI.md`

If you find an older doc that references the v1 art direction, flag it in your PR comment — the producer agent will queue a cleanup task.
