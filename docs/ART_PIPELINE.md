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

## Day-to-day generation workflow

1. **Scope** — Filenames and folders: **`docs/ASSET_MANIFEST.md`**.
2. **Prompts** — Full blocks + reject rules: **`docs/ASSET_PROMPTS_GEMINI.md`**.
3. **Copy-paste queue** — Checklists + CLI lines: **`tools/art/GENERATION_QUEUE.md`** (Gemini `/generate` or `npm run art:replicate`).
4. **Tooling detail** — Keys, outputs, Replicate: **`tools/art/README.md`**.
5. **Palette / mockup feel** — **`assets/styleguide/README.md`** (`Level Mockup.png`, `Referene2.png`, `Assets.png`).
6. **Before commit** — Quantize pixel art → 32 colors, then **`pwsh tools/tasks/validate.ps1`**.

---

## Repo tools (what exists)

| Tool | Role |
|------|------|
| `tools/art/replicate-generate.ts` | `npm run art:replicate` — FLUX/Replicate stills; loads `.env.local` |
| `tools/tasks/validate.ps1` | GUT + level validation (run after asset changes that touch game data) |

There is **no** shipped `batch-generate-hybrid.sh`, `verify-hybrid-assets.sh`, or `assets/backgrounds/` tree from exploratory briefs — do not add those paths as spec without a GDD/manifest update.

---

## Godot import (summary)

- **Gameplay sprites** (`tiles`, `character`, `cards`, `vfx`, pixel UI): **nearest** filter, **no** mipmaps, **snap** transforms — `docs/ART_DIRECTION.md` §2.
- **Painterly PNGs**: follow manifest dimensions; compression/filter per `ART_DIRECTION.md` §3 and import notes in `ASSET_MANIFEST.md`.

Weather **resolve** VFX in v2 are **sprite sheets** aligned to the grid rules in `GAME_DESIGN.md`, not a mandatory **GPUParticles2D** replacement for all weather (particles may come later; see `docs/BLUEPRINT_GAP_AUDIT.md` if scope shifts).

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
- `docs/UI_SCREENS.md` — HUD contract  
- `.claude/agents/art-pipeline.md` — agent focus list
