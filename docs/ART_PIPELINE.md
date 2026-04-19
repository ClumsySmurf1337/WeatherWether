# Art pipeline (v2 — hybrid, one page)

> **Status:** Canonical workflow summary. On disputes, **`docs/ART_DIRECTION.md`** and **`docs/GAME_DESIGN.md` v2** win.  
> **Last updated:** 2026-04-10

---

## What “hybrid” means here

Weather Whether uses **two non-overlapping visual languages** (see `docs/ART_DIRECTION.md` §1):

| Layer | Style | Examples | Ship paths |
|--------|--------|----------|------------|
| **In-level gameplay** | **Pixel art** — integer scale, **32-color** palette (`assets/styleguide/Assets.png`), **hard edges**, **nearest-neighbor** import | Tiles, Sky, cards, HUD buttons, VFX sheets | `assets/sprites/**` per `docs/ASSET_MANIFEST.md` |
| **Between-level / marketing face** | **Painterly illustration** — soft light, brushy, **not** indexed pixel | `home_hero`, world cards, world BGs, level-complete art | `assets/sprites/ui/` entries in manifest |

There is **no** third “64×64 isometric painted tile” mode in the v2 contract: the **board** reads as **crisp pixel art** at **4×** scale (16×16 source tiles), not smooth illustrated terrain.

---

## Mobile vs desktop (same assets, different frame)

| | **Mobile** (Android / iOS) | **Desktop** (Steam: Windows first; Linux / macOS) |
|---|---------------------------|--------------------------------------------------|
| **Goal** | Full-screen portrait; safe areas for notch/home indicator | Comfortable **window**; no stretched HUD on ultrawide |
| **Spec** | `docs/UI_SCREENS.md` — touch targets, 1080×1920 logical | Same **logical** resolution and **same PNGs**; layout reference `assets/mocks/gameplay_desktop.svg` for chrome placement |
| **Runtime** | OS controls surface size | **`docs/DISPLAY_PROFILE.md`** — `DisplayProfile` autoload, `stretch/aspect=keep`, window ~9:16, optional `WHETHER_DISPLAY_PRESET` for simulated phone sizes |

**Art generation** does **not** fork for desktop: you still author **one** set of sprites at manifest sizes. Godot scales the **whole** UI; QA both **fullscreen mobile** and **windowed desktop** presets.

**Input:** GDD §2 — *touch-first, mouse-equal*. Desktop may add hover affordances in UI code; pixel assets stay shared.

---

## Day-to-day generation workflow

1. **Scope** — Filenames and folders: **`docs/ASSET_MANIFEST.md`**.
2. **Prompts** — Full blocks + reject rules: **`docs/ASSET_PROMPTS_GEMINI.md`**.
3. **Copy-paste queue** — Checklists + CLI lines: **`tools/art/GENERATION_QUEUE.md`** (Gemini `/generate` or `npm run art:replicate`).
4. **Tooling detail** — Keys, outputs, Replicate: **`tools/art/README.md`**.
5. **Palette / mockup feel** — **`assets/styleguide/README.md`** (`Level Mockup.png`, `Referene2.png`, `Assets.png`).
6. **Before commit** — Quantize pixel art → 32 colors, then **`pwsh tools/tasks/validate.ps1`**.

---

## Weather effects: sprite VFX + particles (GDD §17)

| Layer | Role | Determinism |
|-------|------|-------------|
| **Manifest VFX** (`assets/sprites/vfx/*.png`) | Strip / tile overlays during **sequence resolution** — primary read for “what weather did” | Driven by game logic; frames are authored, not RNG-dependent |
| **Optional `GPUParticles2D` / `CPUParticles2D`** | Extra atmosphere (mist, streaks, sparks) on top of the board | **Cosmetic only** — must not affect terrain or solver; see GDD §2 (*particle randomness is fine*) |
| **Reduce Motion** | Scales durations + cuts particle emission | Same rules on mobile and desktop (`GAME_DESIGN.md` §13) |

**Pipeline order:** implement and ship **sprite VFX** from the manifest first; add **particles** in-engine when polishing. Death / character moments may combine sprite strips + particles per animation notes in GDD §4.

---

## Repo tools (what exists)

| Tool | Role |
|------|------|
| `tools/art/replicate-generate.ts` | `npm run art:replicate` — FLUX/Replicate stills; loads `.env.local` |
| `tools/tasks/validate.ps1` | GUT + level validation (run after asset changes that touch game data) |

There is **no** shipped `batch-generate-hybrid.sh`, `verify-hybrid-assets.sh`, or alternate `assets/tiles/` tree — do not add those paths as spec without a GDD/manifest update.

---

## Godot import (summary)

- **Gameplay sprites** (`tiles`, `character`, `cards`, `vfx`, pixel UI): **nearest** filter, **no** mipmaps, **snap** transforms — `docs/ART_DIRECTION.md` §2.
- **Painterly PNGs**: follow manifest dimensions; compression/filter per `docs/ART_DIRECTION.md` §3 and import notes in `ASSET_MANIFEST.md`.

---

## Briefs that conflicted with v2 (do not follow)

Older one-off Cursor task files sometimes described:

- **Illustrated 64×64 isometric tiles** with **linear** filtering on the **puzzle board**
- **Generic “ArtStation fantasy”** prompts without the **locked palette**
- **Output paths** like `assets/tiles/` or `assets/backgrounds/` that **aren’t** the manifest layout

Those approaches **contradict** the shipped design (pixel board + painterly chrome). If you find such a file in chat history or forks, **ignore it** and use this doc + `ART_DIRECTION.md` instead.

---

## See also

- `docs/ANIMATION_DIRECTION_2D.md` — strips, frame counts  
- `docs/DISPLAY_PROFILE.md` — desktop window vs mobile fullscreen  
- `docs/UI_SCREENS.md` — HUD contract  
- `.claude/agents/art-pipeline.md` — agent focus list
