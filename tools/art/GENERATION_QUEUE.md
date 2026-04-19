# Generation queue — checkboxes, links, copy-paste prompts (v2 pipeline)

> **Pipeline:** [`docs/ART_PIPELINE.md`](../docs/ART_PIPELINE.md) (pixel board + painterly key art; desktop + mobile **same** PNGs).  
> **Spec (reject rules + anchors):** [`docs/ASSET_PROMPTS_GEMINI.md`](../docs/ASSET_PROMPTS_GEMINI.md)  
> **Save paths:** [`docs/ASSET_MANIFEST.md`](../docs/ASSET_MANIFEST.md)  
> **Visual ref:** [`assets/styleguide/README.md`](../assets/styleguide/README.md) — `Level Mockup.png`, `Referene2.png`, `Assets.png` (32-color quantize).  
> **GDD weather FX:** sprite sheets below = gameplay feedback; optional `GPUParticles2D` in-engine later ([`GAME_DESIGN.md` §17](../docs/GAME_DESIGN.md)).  
> **Workflow / outputs:** [`tools/art/README.md`](README.md)

---

## Simple workflow — what to run in the terminal

Follow this file **top to bottom** (§1 tiles → §2 cards → §3 character → §4 VFX → §5 UI pixel → §6 painterly → §7 optional particle textures → §8 fonts). For each asset copy **one** command unless noted.

### A — Gemini CLI (pixel art — default)

| Step | Where | What to paste / type |
|------|--------|-------------------------|
| 1 | **PowerShell** | Set API key once per session (same key as in `.env.local`; never commit it): `$env:NANOBANANA_API_KEY = $env:GEMINI_API_KEY` — or assign your key string if that env isn’t set. |
| 2 | **PowerShell** | `gemini` — wait for the interactive prompt. |
| 3 | **Inside `gemini`** | Open the asset section below (e.g. `tile_dry_grass.png`). Copy the **entire single line** from the **Gemini** code block — it must start with `/generate "` and end with `--preview`. Paste once, Enter. |
| 4 | Disk | Grab outputs from the nanobanana / CLI output path (see [`README.md`](README.md)). |
| 5 | Checklist | Mark **Generated** when you have a pick; **Approved** after Aseprite + palette pass + file saved to **Save as**. |

**Rule:** Each `/generate` line in this file is **already complete** (style + subject + negatives). You do **not** add the doc anchor again unless you are improvising (use **C**). **§6 Painterly** uses **Replicate** (or Gemini without `--styles="pixel-art"`); do not run painterly prompts with the pixel-art style flag.

### B — Replicate (`npm run art:replicate`)

| Step | Where | What |
|------|--------|------|
| 1 | **PowerShell, repo root** | `.env.local` contains `REPLICATE_API_TOKEN`. |
| 2 | Same window | Copy the **`npm run art:replicate -- --prompt '...'`** line under that asset. Use **single quotes** around the prompt so spaces work. Run it. |
| 3 | Optional | If the queue says to set `$env:REPLICATE_ASPECT_RATIO` for a wide strip, run that **before** `npm` on the same line or same session, then clear it when done if you need 1:1 again. |

### C — Custom prompt (not listed below)

Paste this **stem** first, then your subject, then negatives (`no text`, `no UI`, full-bleed for tiles). Aligns with [`ASSET_PROMPTS_GEMINI.md`](../docs/ASSET_PROMPTS_GEMINI.md) **Pixel art anchor**.

```text
Whether pixel art, bright modern indie puzzle, vibrant readable colors, chunky tactile, limited 32-color flat bands, hard edges no anti-aliasing, transparent background, game asset, sun-lit cheerful mood not retro-console dull,
```

---

**Checklist convention**

- **Generated** — you have a candidate image.  
- **Approved** — quantized / sliced / cleaned and exported to the path in [`ASSET_MANIFEST.md`](../docs/ASSET_MANIFEST.md).

**What’s inside each pre-built line**

- Every **`/generate`** line opens with the **v2 style DNA** (Whether, modern indie puzzle, chunky tactile, 32-color flat, hard edges, styleguide mockup mood — **not** SNES/muted retro). Subject + negatives follow.  
- After generation: **quantize** to [`Assets.png`](../assets/styleguide/Assets.png) in Aseprite, then ship paths in [`ASSET_MANIFEST.md`](../docs/ASSET_MANIFEST.md).  
- Tiles: **full-bleed square**; strips: **strip fills frame**. **Hazard tiles** (e.g. `tile_empty`) stay **dark by design** — still use the same DNA for edge discipline.

---

## 1. Tiles — `assets/sprites/tiles/`

| Save as | Spec link |
|---------|-----------|
| `tile_empty.png` | [`tile_empty.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_emptypng) |
| `tile_dry_grass.png` | [`tile_dry_grass.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_dry_grasspng) |
| `tile_wet_grass.png` | [`tile_wet_grass.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_wet_grasspng) |
| `tile_water.png` | [`tile_water.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_waterpng-4-frame-loop) |
| `tile_ice.png` | [`tile_ice.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_icepng) |
| `tile_mud.png` | [`tile_mud.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_mudpng) |
| `tile_snow.png` | [`tile_snow.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_snowpng) |
| `tile_scorched.png` | [`tile_scorched.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_scorchedpng) |
| `tile_steam.png` | [`tile_steam.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_steampng-4-frame-loop) |
| `tile_plant.png` | [`tile_plant.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_plantpng) |
| `tile_stone.png` | [`tile_stone.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_stonepng) |
| `tile_fog_covered.png` | [`tile_fog_covered.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_fog_coveredpng-4-frame-loop) |
| `tile_start.png` | [`tile_start.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_startpng) |
| `tile_goal.png` | [`tile_goal.png`](../docs/ASSET_PROMPTS_GEMINI.md#tile_goalpng-4-frame-loop) |

*(If a hash link doesn’t jump in your viewer, search **`### \`tile_`** in [`ASSET_PROMPTS_GEMINI.md`](../docs/ASSET_PROMPTS_GEMINI.md). GitHub-style anchors vary; the headings match filenames.)*

### `tile_empty.png` — `assets/sprites/tiles/tile_empty.png`

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA. Top-down 16x16 empty pit tile deep dark checkered void pattern no ground faint dark blue glow at edges fall hazard tileable. Square 1:1 full-bleed edge to edge no letterboxing. no anti-aliasing no blur no gradients no photorealism no text no UI no watermarks" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA top-down empty pit void tile checkered dark transparent game tile square full-bleed 1:1 no text no UI'
```

---

### `tile_dry_grass.png` — `assets/sprites/tiles/tile_dry_grass.png`

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA 32 color flat top-down transparent game asset. Top-down grass tile dry yellow-green blades faint brown soil spots tileable edges light top-left. Square 1:1 full-bleed texture fills entire image no tiny centered blob no letterboxing. no anti-aliasing no blur no gradients no photorealism no text no UI" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA top-down 16x16 style dry grass tile yellow green soil tileable square full-bleed edge to edge no margins no text'
```

---

### `tile_wet_grass.png` — `assets/sprites/tiles/tile_wet_grass.png`

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA top-down transparent game asset. Top-down grass after rain dark green water droplets white pixel clusters blue-grey wet sheen tileable. Square 1:1 full-bleed no letterboxing. no blur no text no UI no photorealism" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art top-down wet grass tile rain droplets dark green tileable square full-bleed Whether styleguide saturation no text'
```

---

### `tile_water.png` — `assets/sprites/tiles/tile_water.png` (4‑frame **64×16** strip)

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA top-down transparent. Single row 4-frame horizontal WATER strip 64x16 pixels deep blue water cyan ripples white sparkle looping waves tileable left-right. Entire strip must fill image width and height no huge empty margins. no text no UI no photorealism" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
$env:REPLICATE_ASPECT_RATIO='4:1'
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art horizontal sprite strip 64x16 four frame water ripple animation top-down game tile loop transparent vibrant no text'
```
*(Uses env var from `tools/art/replicate-generate.ts` default override. Clear after if you want 1:1 again: `Remove-Item Env:REPLICATE_ASPECT_RATIO`. Or generate **1:1** and slice the strip in Aseprite.)*

---

### `tile_ice.png` — `assets/sprites/tiles/tile_ice.png`

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA top-down ice tile pale blue white crack lines branches tileable square full-bleed 1:1 no letterboxing hard edges no blur no text no UI" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA top-down ice ground tile cracks pale blue tileable square full bleed'
```

---

### `tile_mud.png` — `assets/sprites/tiles/tile_mud.png`

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA top-down mud tile dark brown puddles wet shine tileable square full-bleed no margins no text no UI" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art top-down mud tile brown wet puddle tileable square'
```

---

### `tile_snow.png` — `assets/sprites/tiles/tile_snow.png`

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA top-down fresh snow white pale blue specks texture tileable square full-bleed no pure white void no text" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art snow ground tile top-down white blue tint tileable square'
```

---

### `tile_scorched.png` — `assets/sprites/tiles/tile_scorched.png`

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA top-down scorched earth black charred red ember dots grey ash cracks dangerous dead tileable square full-bleed no flames no text" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art burnt scorched ground tile black ember ash top-down tileable square'
```

---

### `tile_steam.png` — `assets/sprites/tiles/tile_steam.png` (4‑frame **64×16** strip)

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA horizontal strip 64x16 four frame steam rising wisps grey white loop ephemeral transparent background strip fills frame no huge canvas" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art steam animation strip top-down 4 frames horizontal cloudy wisp soft'
```

---

### `tile_plant.png` — `assets/sprites/tiles/tile_plant.png`

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA top-down plant seedling small green leaves soil center tileable square full-bleed friendly no text" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art small plant sprout tile top-down bright square tileable'
```

---

### `tile_stone.png` — `assets/sprites/tiles/tile_stone.png`

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA top-down grey cobblestone mortar impassable wall tileable square full-bleed stone blocks visible no text" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art stone brick cobble path tile top-down chunky grey mortar square tileable'
```

---

### `tile_fog_covered.png` — `assets/sprites/tiles/tile_fog_covered.png` (4‑frame **64×16** strip)

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA horizontal strip 64x16 four frame fog wisps drifting slate grey loop mysterious strip fills frame" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art fog mist animation 4 frame horizontal strip grey mysterious mood'
```

---

### `tile_start.png` — `assets/sprites/tiles/tile_start.png`

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA top-down start spawn tile stone or wood floor golden glowing circle center welcoming warm light tileable square full-bleed no text" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art game start marker tile golden glow top-down bright square spawn point'
```

---

### `tile_goal.png` — `assets/sprites/tiles/tile_goal.png` (4‑frame **64×16** strip)

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA horizontal strip 64x16 four frame goal flag red on pole waving loop stone floor strip fills frame" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art red flag goal marker animation strip 4 frames top-down puzzle game'
```

---

## 2. Weather cards — `assets/sprites/cards/` (see [§2](../docs/ASSET_PROMPTS_GEMINI.md))

One **base look** per type → derive **default / pressed / disabled / glow** in Aseprite + **icons** (`card_icon_*`) as in [`ASSET_MANIFEST.md`](../docs/ASSET_MANIFEST.md). **Reject rules** for each card are in the linked headings under **§2** in [`ASSET_PROMPTS_GEMINI.md`](../docs/ASSET_PROMPTS_GEMINI.md).

### `card_rain` family — [`card_rain` family](../docs/ASSET_PROMPTS_GEMINI.md#card_rain-family)

- [ ] Generated (base + icon path)  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA 32 color flat clear silhouette transparent background game asset. Single playing card 32x48 vertical blue frame white border top label RAIN center cloud raindrops bottom cost 1 cyan background hex 3aa8e8 inner art white pixels game UI card clean readable. Full-bleed card fills image edge to edge no tiny card on huge canvas. no anti-aliasing no blur no photorealism no extra text no watermarks no UI chrome beyond card" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA game card 32x48 vertical rain weather cyan 3aa8e8 blue frame white border label RAIN cloud droplets cost 1 clean UI'
```

---

### `card_sun` — [`card_sun`](../docs/ASSET_PROMPTS_GEMINI.md#card_sun)

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA 32 color game asset. Single playing card 32x48 vertical amber orange frame top label SUN center sun with rays bottom cost 1 background amber hex f0b340 inner illustration white pixels game UI card clean. Full-bleed card fills frame. no blur no photorealism no watermarks" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA game card 32x48 sun rays amber orange f0b340 weather UI label SUN cost 1'
```

---

### `card_frost` — [`card_frost`](../docs/ASSET_PROMPTS_GEMINI.md#card_frost)

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA. Single playing card 32x48 vertical pale ice-blue frame top label FROST center snowflake or ice crystal bottom cost 1 card background ice blue hex 7ad8e8 inner art white game UI. Full-bleed fills image. no photorealism no extra text" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA game card 32x48 frost snowflake ice blue 7ad8e8 weather card label FROST'
```

---

### `card_wind` — [`card_wind`](../docs/ASSET_PROMPTS_GEMINI.md#card_wind)

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA. Single playing card 32x48 vertical sage green frame top label WIND center swirling wind lines or small cyclone bottom cost 1 background green hex 5fc97e illustration white game UI. Full-bleed card. no photorealism" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA game card 32x48 wind gust cyclone green 5fc97e weather label WIND'
```

---

### `card_lightning` — [`card_lightning`](../docs/ASSET_PROMPTS_GEMINI.md#card_lightning)

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA. Single playing card 32x48 vertical violet frame top label LIGHT center lightning bolt bottom cost 1 background violet hex a06fe8 illustration white-yellow slightly dangerous mood game UI. Full-bleed card. no photorealism" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA game card 32x48 lightning bolt violet a06fe8 dangerous vibe label LIGHT'
```

---

### `card_fog` — [`card_fog`](../docs/ASSET_PROMPTS_GEMINI.md#card_fog)

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA. Single playing card 32x48 vertical slate grey frame top label FOG center wavy horizontal fog cloud bottom cost 1 background slate hex 8a9bb4 illustration white mysterious mood game UI. Full-bleed card. no photorealism" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA game card 32x48 fog mist slate grey 8a9bb4 mysterious label FOG'
```

---

## 3. Character Sky — `assets/sprites/character/` ([§3](../docs/ASSET_PROMPTS_GEMINI.md))

| Asset | - [ ] Gen | - [ ] OK | Link |
|-------|-----------|---------|------|
| `sky_idle.png` | [ ] | [ ] | [sky_idle](../docs/ASSET_PROMPTS_GEMINI.md) |
| `sky_surprised.png` | [ ] | [ ] | manifest |
| `sky_walk_n/e/s/w.png` | [ ] | [ ] | [walk template](../docs/ASSET_PROMPTS_GEMINI.md) |
| `sky_cheer.png` | [ ] | [ ] | §3 |
| `sky_drown.png` | [ ] | [ ] | §3 |
| `sky_burn.png` | [ ] | [ ] | §3 |
| `sky_fall.png` | [ ] | [ ] | §3 |
| `sky_electrocute.png` | [ ] | [ ] | §3 v1.5 |
| `sky_freeze.png` | [ ] | [ ] | §3 v1.5 |

**Gemini (idle strip — paste full block from doc for precision)**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA 24x24 hooded figure blue-grey cloak gender neutral hood only two eye dots brown boots facing viewer 4-frame horizontal strip 96x24 idle bob calm. Full strip bleeds frame horizontally. no anime no chibi no big eyes no blood" --styles="pixel-art" --count=2 --preview
```

---

## 4. VFX — `assets/sprites/vfx/` ([§4](../docs/ASSET_PROMPTS_GEMINI.md))

| Asset | - [ ] Gen | - [ ] OK | Spec |
|-------|-----------|---------|------|
| `vfx_rain_burst.png` | [ ] | [ ] | [§](../docs/ASSET_PROMPTS_GEMINI.md#vfx_rain_burstpng-6-frames) |
| `vfx_sun_pulse.png` | [ ] | [ ] | [§](../docs/ASSET_PROMPTS_GEMINI.md#vfx_sun_pulsepng-5-frames) |
| `vfx_frost_crystal.png` | [ ] | [ ] | [§](../docs/ASSET_PROMPTS_GEMINI.md#vfx_frost_crystalpng-6-frames) |
| `vfx_wind_sweep.png` | [ ] | [ ] | [§](../docs/ASSET_PROMPTS_GEMINI.md#vfx_wind_sweeppng-5-frames-9632-wide-for-3-tile-cross) |
| `vfx_lightning_bolt.png` | [ ] | [ ] | [§](../docs/ASSET_PROMPTS_GEMINI.md#vfx_lightning_boltpng-4-frames) |
| `vfx_lightning_chain.png` | [ ] | [ ] | *(manifest only — prompt below)* |
| `vfx_fog_roll.png` | [ ] | [ ] | [§](../docs/ASSET_PROMPTS_GEMINI.md#vfx_fog_rollpng-6-frames-4848-for-33-area) |
| `vfx_splash.png` | [ ] | [ ] | [§ pattern](../docs/ASSET_PROMPTS_GEMINI.md#vfx_splashpng-vfx_flamepng-vfx_sparklepng-vfx_dustpng-vfx_confettipng) |
| `vfx_flame.png` | [ ] | [ ] | [§ pattern](../docs/ASSET_PROMPTS_GEMINI.md#vfx_splashpng-vfx_flamepng-vfx_sparklepng-vfx_dustpng-vfx_confettipng) |
| `vfx_sparkle.png` | [ ] | [ ] | [§ pattern](../docs/ASSET_PROMPTS_GEMINI.md#vfx_splashpng-vfx_flamepng-vfx_sparklepng-vfx_dustpng-vfx_confettipng) |
| `vfx_dust.png` | [ ] | [ ] | [§ pattern](../docs/ASSET_PROMPTS_GEMINI.md#vfx_splashpng-vfx_flamepng-vfx_sparklepng-vfx_dustpng-vfx_confettipng) |
| `vfx_confetti.png` | [ ] | [ ] | [§ pattern](../docs/ASSET_PROMPTS_GEMINI.md#vfx_splashpng-vfx_flamepng-vfx_sparklepng-vfx_dustpng-vfx_confettipng) |

### `vfx_rain_burst.png` — [spec](../docs/ASSET_PROMPTS_GEMINI.md#vfx_rain_burstpng-6-frames)

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA 32 color transparent game asset. 32x32 weather effect sprite sheet 6 frames horizontal 192x32 rain droplets onto tile frame progression droplets ripples cyan blue white rings transparent bg. no blur no photorealism no text" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA 6 frame horizontal strip 192x32 rain droplets ripple cyan white weather VFX transparent'
```

### `vfx_sun_pulse.png` — [spec](../docs/ASSET_PROMPTS_GEMINI.md#vfx_sun_pulsepng-5-frames)

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA. 32x32 weather VFX 5 frames horizontal 160x32 warm radial sun pulse expanding yellow orange center ring fade transparent bg. no text" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA sun pulse expanding ring animation 5 frames 160x32 yellow orange transparent'
```

### `vfx_frost_crystal.png` — [spec](../docs/ASSET_PROMPTS_GEMINI.md#vfx_frost_crystalpng-6-frames)

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA. 32x32 ice crystals growing inward 6 frames horizontal 192x32 corners to center snap freeze pale cyan-white transparent. no text" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art ice crystal grow animation 6 frames frost tile effect 192x32 transparent'
```

### `vfx_wind_sweep.png` — [spec](../docs/ASSET_PROMPTS_GEMINI.md#vfx_wind_sweeppng-5-frames-9632-wide-for-3-tile-cross)

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA. 96x32 weather effect 5 frames horizontal 480x32 directional wind gust streaks across 3-tile width sage-grey white transparent. no text" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
$env:REPLICATE_ASPECT_RATIO='21:9'
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA wide wind gust streak animation 5 frames horizontal transparent sage grey game VFX top-down'
Remove-Item Env:REPLICATE_ASPECT_RATIO
```
*(Flux defaults to `1:1` from env in `replicate-generate.ts`; wide strips need a wider `REPLICATE_ASPECT_RATIO` if the model accepts it — otherwise use Gemini for layout fidelity, or stitch frames.)*

### `vfx_lightning_bolt.png` — [spec](../docs/ASSET_PROMPTS_GEMINI.md#vfx_lightning_boltpng-4-frames)

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA. 32x32 lightning 4 frames horizontal 128x32 white violet zigzag bolt flash afterglow dramatic transparent. no text" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art lightning strike tile effect 4 frames crisp white violet flash transparent 128x32'
```

### `vfx_lightning_chain.png` — (see [manifest](../docs/ASSET_MANIFEST.md) — arc between tiles)

No separate `###` in prompts doc yet; use this merged line or add a matching block to [`ASSET_PROMPTS_GEMINI.md`](../docs/ASSET_PROMPTS_GEMINI.md) later.

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA. Weather VFX sprite sheet horizontal strip 4 frames electric arc lightning chain jumping between two anchor points on ground tiles violet-white jagged path variable width top-down game effect transparent background no UI" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA lightning chain arc between two points ground tiles 4 frame animation transparent wide strip'
```

### `vfx_fog_roll.png` — [spec](../docs/ASSET_PROMPTS_GEMINI.md#vfx_fog_rollpng-6-frames-4848-for-33-area)

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA. 48x48 fog rolling 6 frames horizontal 288x48 wisps cover 3x3 area slate grey settled drift transparent edges. no text" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile styleguide mockup pixel art fog rolling mist 6 frames 288x48 wide slate grey atmospheric game VFX transparent'
```

### Particle burst family (`vfx_splash`, `vfx_flame`, `vfx_sparkle`, `vfx_dust`, `vfx_confetti`)

[Shared pattern in spec](../docs/ASSET_PROMPTS_GEMINI.md#vfx_splashpng-vfx_flamepng-vfx_sparklepng-vfx_dustpng-vfx_confettipng) — swap palette: water cyan-white, flame red-orange, sparkle gold-white, dust grey-tan, confetti mixed festival.

**Gemini (splash example — adapt noun + colors)**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA. Simple water splash particle burst 5 frames horizontal strip cyan white transparent game VFX no text" --styles="pixel-art" --count=2 --preview
```

**Replicate (flame example)**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA flame particle burst 6 frames horizontal strip red orange transparent game effect'
```

---

## 5. UI pixel — `assets/sprites/ui/` ([§5](../docs/ASSET_PROMPTS_GEMINI.md))

**Batch checklist**

- [ ] Buttons (`button_*` — default / pressed / disabled / primary / secondary)  
- [ ] Panels / frames (`panel_*`, `frame_*`, `divider`)  
- [ ] Icons (`icon_*`, `star_*`)  
- [ ] Nodes / path (`node_*`, `path_dash`)  
- [ ] Wordmarks (`wordmark.png`, etc. per manifest)

### `button_primary_default.png` — `assets/sprites/ui/button_primary_default.png` (96×24)

- [ ] Generated  
- [ ] Approved → on disk  

**Gemini**

```text
/generate "Whether pixel v2 modern indie puzzle chunky tactile styleguide mockup 32-color flat hard edges no AA. UI button 96x24 pixels bright blue rounded rectangle 2px darker blue border inner highlight top edge color hex 4a90e2 empty interior chunky clickable game HUD navy chrome style. Transparent background. no text on button no icons no gradient blur photorealism" --styles="pixel-art" --count=2 --preview
```

**Replicate**

```powershell
npm run art:replicate -- --prompt 'Whether pixel v2 chunky tactile 32-color UI button 96x24 bright blue hex 4a90e2 rounded rectangle border highlight empty interior game HUD transparent'
```

**Icons (24×24):** merge [§5 Icons](../docs/ASSET_PROMPTS_GEMINI.md#icons-2424-each) — use stem **C** + description (back, pause, gear, undo, …).

---

## 6. Painterly key art — `assets/sprites/ui/` ([§6](../docs/ASSET_PROMPTS_GEMINI.md))

**Not pixel art.** Use **painterly anchor** text from [`ASSET_PROMPTS_GEMINI.md`](../docs/ASSET_PROMPTS_GEMINI.md) §6. Replicate **`flux-schnell`** (default in `replicate-generate.ts`) is a good default; set **`$env:REPLICATE_ASPECT_RATIO`** when noted.

**Painterly one-line stem** (prepend to custom subjects, or rely on full prompts below):

```text
painterly digital illustration visible brushstrokes soft atmospheric golden hour Studio Ghibli Sea of Stars style hopeful no characters landscape no text no UI no watermark,
```

| Asset | - [ ] Gen | - [ ] OK |
|-------|-----------|---------|
| `home_hero.png` | [ ] | [ ] |
| `world_card_w1`–`w6` | [ ] | [ ] |
| `world_bg_w1`–`w6` | [ ] | [ ] |
| `level_complete_sunrise_w1`–`w6` | [ ] | [ ] |
| `splash_clouds.png` | [ ] | [ ] |

### `home_hero.png` — generate large, then scale to manifest size

**Replicate** (16:9 hero; tweak prompt with full [§6 home_hero](../docs/ASSET_PROMPTS_GEMINI.md#home_heropng-480320-source-generate-at-19201280) if needed)

```powershell
$env:REPLICATE_ASPECT_RATIO='16:9'
npm run art:replicate -- --model black-forest-labs/flux-schnell --prompt 'painterly digital illustration wide cinematic landscape three biomes left coastal rain valley middle Mediterranean sun hillside right alpine snow peaks golden hour soft transitions dreamlike unified light visible brushstrokes no characters hopeful peaceful 16:9 no text no UI'
Remove-Item Env:REPLICATE_ASPECT_RATIO -ErrorAction SilentlyContinue
```

### `world_card_w1.png` (Downpour) — 3:2 card

**Replicate**

```powershell
$env:REPLICATE_ASPECT_RATIO='3:2'
npm run art:replicate -- --model black-forest-labs/flux-schnell --prompt 'painterly illustration world biome card coastal valley winding river low cliffs distant lighthouse headland light rain cool grey clouds golden break on horizon slate blue sage green cream hopeful melancholy no characters no text 3:2'
Remove-Item Env:REPLICATE_ASPECT_RATIO -ErrorAction SilentlyContinue
```

**`world_card_w2`–`w6`, `world_bg_*`, `level_complete_*`:** copy the block text from [§6 world cards / BG / level complete](../docs/ASSET_PROMPTS_GEMINI.md) into the same Replicate pattern (`--prompt '…'`), keeping **no characters** and **no UI** per asset.

### `splash_clouds.png` — ultra-wide cloud band

**Replicate**

```powershell
$env:REPLICATE_ASPECT_RATIO='21:9'
npm run art:replicate -- --model black-forest-labs/flux-schnell --prompt 'painterly horizontal cloud band parallax soft cumulus warm sunset palette low contrast behind text tileable wide ultra wide no text no characters'
Remove-Item Env:REPLICATE_ASPECT_RATIO -ErrorAction SilentlyContinue
```

---

## 7. Optional — Godot particle textures (`GPUParticles2D` polish)

Ship **sprite-sheet VFX** (§4) first. These are **extra** single textures for particle systems ([`GAME_DESIGN.md` §17](../docs/GAME_DESIGN.md)); they do **not** replace manifest strips. Save to `art/reference/` until a manifest slot exists.

| Use | - [ ] Gen | Notes |
|-----|-----------|--------|
| Rain streak / droplet | [ ] | Small soft blob, cyan-white, transparent |
| Mist wisp | [ ] | Grey-blue, feathered edge OK for particles |
| Spark | [ ] | White-violet, tiny |

**Replicate (rain droplet — example)**

```powershell
npm run art:replicate -- --prompt 'single soft rain droplet sprite cyan blue white glow transparent background small game particle texture 32x32 simple'
```

*(Tune opacity in Godot material; **Reduce Motion** in settings scales emission.)*

---

## 8. Fonts — `assets/fonts/` ([manifest](../docs/ASSET_MANIFEST.md))

- [ ] `whether_display.ttf` / `whether_body.ttf` / `whether_numbers.ttf` — **license and import**, not AI-generated.
