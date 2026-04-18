# Styleguide — canonical art references

These PNGs are the **source of truth** for how Whether should **look** (palette, brightness, UI chunkiness). Full rules live in [`docs/ART_DIRECTION.md`](../../docs/ART_DIRECTION.md) §7.

| File | What it is |
|------|------------|
| **`Assets.png`** | **32-color palette** — every pixel sprite must quantize to these swatches. |
| **`Level Mockup.png`** | **Gameplay + UI kit** — level grid, weather cards/icons, button states, navy chrome, HUD layout. |
| **`Referene2.png`** | **Multi-screen mockup** (filename spelling is legacy) — title, world cards, flows; shows **painterly backgrounds + pixel UI** together. |

**Not the spec:** older SVG layout refs live under `assets/mocks/` (see `assets/mocks/README.md`). Those communicate structure only; **these PNGs** win on color and mood.

**Prompting:** Prefer **bright, modern indie puzzle pixel** language. Do **not** anchor generation to **SNES / generic 16-bit console** — that conflicts with the saturated, sun-lit look of the mockups. Use the updated **pixel art anchor** in [`docs/ASSET_PROMPTS_GEMINI.md`](../../docs/ASSET_PROMPTS_GEMINI.md).
