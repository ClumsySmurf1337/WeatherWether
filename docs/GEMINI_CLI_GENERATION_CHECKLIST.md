# Gemini CLI — generation checklist (game flow, art, versioning)

> **Purpose:** Paste-friendly workflow for terminal/Gemini image generation, aligned with `docs/GAME_DESIGN.md` v2, `docs/ASSET_MANIFEST.md`, and `docs/ASSET_PROMPTS_GEMINI.md`. **Authoritative prompts** remain in `ASSET_PROMPTS_GEMINI.md`; this file orders work and ties it to shipping flow.
>
> **Last updated:** 2026-04-10

---

## 1. Game flow (runtime)

Linear player journey (see GDD for mechanics detail):

1. **Boot** → splash / load save.
2. **Main menu (Home)** → Continue, Select Level, Settings.
3. **World / level pick** → linear unlock per world.
4. **Gameplay (Planning)** → build weather card queue, optional hints, undo.
5. **Commit** → **Resolve** weather on grid (deterministic).
6. **Walk** → character auto-paths; win (goal) or lose (death / no path).
7. **Results** → stars, return to level list or retry.

**UI wireframes:** `docs/UI_SCREENS.md` — mobile reference **1080×1920**; desktop layout references: `assets/mocks/gameplay_desktop.svg`, `assets/mocks/world_select_desktop.svg`.

---

## 2. Art inventory (what to generate)

| Category | Manifest keys | Prompt source |
|----------|---------------|---------------|
| Terrain tiles (14 types) | `docs/ASSET_MANIFEST.md` §tiles | `ASSET_PROMPTS_GEMINI.md` §1 |
| Weather cards (6) | §cards | §2 |
| Character states (Sky) | §character | §3 |
| UI / HUD | §ui | §4–5 |
| Key art / worlds | §key_art | painterly sections |

**Mocks** (`assets/mocks/*.svg`) are layout-only; **do not** ship them as game art.

---

## 3. Prompt-by-prompt order (paste into Gemini CLI)

Run in this order so dependencies (palette, silhouette) stay consistent:

1. **Style anchors** — paste **pixel art** or **painterly** anchor + **universal negative** from `ASSET_PROMPTS_GEMINI.md` (top of file).
2. **Tiles** — `tile_dry_grass` → `tile_wet_grass` → … follow §1 order in `ASSET_PROMPTS_GEMINI.md` (matches terrain enum in code).
3. **Cards** — one prompt per card type (Rain … Fog).
4. **Character** — idle first, then walk frames, then fail/win states per manifest.
5. **UI chrome** — buttons, panels, then HUD pieces.
6. **Key art** — world thumbnails / hero last (painterly anchor).

After each batch: **Reject-if** checks from the prompt block, then Aseprite cleanup per `docs/ART_DIRECTION.md` §8 if applicable.

---

## 4. Versioning and paths

- **Reference captures:** `art/reference/YYYY-MM-DD-short-description.png` (gitignored if large; see `docs/ART_DIRECTION.md`).
- **Shipped sprites:** paths and filenames must match `docs/ASSET_MANIFEST.md` so `ResourceLoader` and scenes stay stable.
- When replacing an asset: bump a note in PR description (`asset: tile_wet_grass v2 — contrast fix`).

**Agent task after generation:** export final PNG → correct `res://` path → reimport in Godot → run `tools/tasks/validate.ps1` → spot-check in `ui/screens` scenes that reference the texture.

---

## 5. Validation

- **Automated:** `pwsh ./tools/tasks/validate.ps1` (GUT + level validation).
- **Visual:** Editor run on Windows; set **`WHETHER_DISPLAY_PRESET`** (see **`docs/DISPLAY_PROFILE.md`**) to compare **simulated phone** sizes vs **native** 1080×1920; compare **desktop** HUD layout to `assets/mocks/gameplay_desktop.svg`.

---

## 6. Related docs

- `docs/ASSET_PROMPTS_GEMINI.md` — full prompts.
- `docs/ASSET_MANIFEST.md` — filenames and screen usage.
- `docs/ART_DIRECTION.md` — palette, export rules, cleanup.
- `assets/mocks/README.md` — mock contract.
