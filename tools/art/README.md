# Art generation — simple playbook

> **Prompts:** `docs/ASSET_PROMPTS_GEMINI.md` · **Ship filenames:** `docs/ASSET_MANIFEST.md` · **Palette / cleanup:** `docs/ART_DIRECTION.md` §8.  
> **Secrets:** `.env.local` only (gitignored).

---

## How this fits Linear and “agents”

| Piece | Role |
|--------|------|
| **Linear** | Tracks **what** to make (issues with **Art-Visual**, or rows from the manifest). That’s scope and priority — same as other work. |
| **Code lanes / `workflow:simple`** | **Does not** run art generation. Keep art separate so you control **cost** and **quality**. |
| **You (or art-pipeline agent in Cursor)** | **Runs** Gemini CLI or `npm run art:replicate`, picks winners, **signs off** before anything goes into `assets/sprites/`. |
| **Final sign-off** | **You.** No PNG is “shipped” until you approve after visual check (and palette pass for pixel art). |

**Practical rule:** Use Linear to list assets (“tile set tranche 1”, “world_card_w3”), then run the tools below when you’re ready — not on every daily automatically.

---

## The 5-step flow (repeat per asset or batch)

1. **Scope** — Open the right prompt block in `docs/ASSET_PROMPTS_GEMINI.md` (or the Linear issue body).
2. **Generate** — Use **A or B** below (your choice per task).
3. **Review** — Open outputs in `nanobanana-output/` or `art/reference/`. Bad → tweak prompt, regenerate **small** batches.
4. **Sign-off** — When one image is good enough, **you** mark it approved (mental or a checklist in the issue).  
5. **Integrate** — Quantize / slice in Aseprite if needed → save to the **exact path** in `docs/ASSET_MANIFEST.md` → run **Validate** (Cursor task or `pwsh tools/tasks/validate.ps1`).

`art/reference/` is **gitignored** on purpose (drafts). Only **approved** files under `assets/` get committed.

---

## A — Gemini CLI + nanobanana (pixel-friendly, your install)

You already installed the extension. In **PowerShell** (repo root optional):

```powershell
$env:NANOBANANA_API_KEY = $env:GEMINI_API_KEY   # match the name you use in .env.local
gemini
```

Inside the CLI, paste prompts from **`ASSET_PROMPTS_GEMINI.md`** (include style anchor + **framing addendum** + negative — see doc section *Framing addendum* so the grass **fills the square**, not a tiny island on a huge canvas).

**Dry grass — retry example** (one line; paste as one `/generate`):

```text
/generate "pixel art 16-bit SNES, hard edges, 32 color feel, top-down dry grass tile, yellow-green blades, faint brown soil, tileable edges, sun from top-left. Square 1:1 full-bleed: texture fills entire image edge to edge, no letterboxing, no tiny sprite centered in large empty space, no huge transparent margins. no text no UI." --styles="pixel-art" --count=2 --preview
```

More examples:

```text
/generate "…short subject line from doc + framing addendum…" --styles="pixel-art" --count=2 --preview
/pattern "…" --type="seamless"   # backgrounds / tiles exploration
```

Defaults save under **`./nanobanana-output/`**. Move keepers to `art/reference/` while deciding.

---

## B — Replicate (FLUX, fast concepts / painterly)

Uses **`REPLICATE_API_TOKEN`** in `.env.local`. Good for **mood comps** and painterly key-style shots; **not** strict 32-color pixel until you process in Aseprite.

From repo root:

```bash
npm run art:replicate -- --dry-run --prompt "smoke"
npm run art:replicate -- --prompt "your full prompt text"
npm run art:replicate -- --batch tools/art/batch-prompts.example.txt
```

Writes to **`art/reference/`** (gitignored). Override model: `--model owner/name` or env `REPLICATE_IMAGE_MODEL`.

---

## Cursor menu: Run Task

Use **Tasks → Run Task** → group **art**:

- **Art: Replicate dry run** — checks env + script without spending credits.  
- **Art: Validate project** — run after you drop sprites in and reimport in Godot.

---

## Non-artist: LibreSprite / editors / “clean” in plain English

**Your `D:\Godot\libresprite` folder:** If there is **no `.exe`**, you don’t have the Windows app — you likely copied **data-only** or source. **LibreSprite:** download a **Release** archive for Windows from the [LibreSprite releases](https://github.com/LibreSprite/LibreSprite/releases) page (look for a **`.zip`** that contains **`LibreSprite.exe`**). Extract the whole folder and run that `.exe`.

**Easiest paid option (most tutorials match it): [Aseprite](https://www.aseprite.org/)** ( Steam / site ) — one purchase, best match for this repo’s docs.

**Free / simpler (good enough to start):**

| Tool | Notes |
|------|--------|
| **[Piskel](https://www.piskelapp.com/)** (browser) | Free, dead simple, pixel grid. Export PNG. Good for **resize + touch-up** after AI. |
| **[Paint.NET](https://www.getpaint.net/)** (Windows) | Free. Use **nearest neighbor** when resizing; harder palette lock than Aseprite. |
| **LibreSprite** | Free Aseprite-like fork — **must** install from a release **with** `.exe`. |

**What “clean the sprite” means** (no art degree required):

1. **Shrink** the AI image to the right size (e.g. **16×16** for a tile) using **nearest neighbor** / **pixel resize** so it stays crunchy, not blurry.  
2. **Reduce colors** so everything snaps to the game palette (indexed / ~32 colors). AI loves soft edges; we need **hard** blocks of color.  
3. **Fix odd pixels** — zoom in, erase stray dots along edges with a **1×1 pencil**. If it still looks mushy, **regenerate** in Gemini with a stronger prompt instead of fighting it for an hour.

**Plugins / helpers:** pixel workflow is mostly **the editor + eyeball**. Optional: load a **`.gpl` palette** in Aseprite/LibreSprite (Lospec has community palettes; your game’s truth is still `assets/styleguide/Assets.png`). No Godot plugin replaces **editing the PNG** before import.

---

## Cost

- **Gemini / AI Studio:** your API quota.  
- **Replicate:** [dashboard](https://replicate.com/) — per prediction.

---

## What *not* to automate yet

Fully automatic “Linear issue → charge API → commit to `assets/`” would skip **your** sign-off and burn credit on rejects. Keep **human approval** as the gate between **draft folders** and **`assets/`**.
