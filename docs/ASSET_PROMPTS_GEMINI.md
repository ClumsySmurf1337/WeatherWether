# Gemini Prompt Pack (Art + UI References)

Use these prompts to generate **design references**, not final shipping assets.

## Prompt 1: World Mood Board

```text
Create a cohesive 2D puzzle game visual mood board for a mobile-first game called "Weather Whether".
Theme: weather as puzzle mechanics (rain, sun, frost, wind, lightning, fog).
Style: clean stylized 2D, readable at small mobile sizes, premium indie aesthetic.
Output panels:
1) Terrain tile concepts
2) Weather card icon concepts
3) UI panel/button concepts
4) VFX style frames
Constraints:
- Distinct visual language per weather type
- High puzzle readability
- No photorealism
- Keep color harmony and clarity
```

## Prompt 2: Tile Set Concepts

```text
Generate a tile set concept sheet for a grid-based puzzle game.
Include: dry grass, wet grass, shallow water, ice bridge, scorched tile, fog-covered tile.
Show each tile in 3 variants for visual variety while preserving clear state identity.
Style: minimalist painterly flat 2D.
Mobile-first readability required.
```

## Prompt 3: Weather Card Icons

```text
Design six weather card icons for a puzzle game: rain, sun, frost, wind, lightning, fog.
Card style: clean geometric symbols with subtle texture.
Output as a consistent icon family on transparent background references.
Prioritize instant recognition at small size.
```

## Prompt 4: Main Menu UI Reference

```text
Create a mobile-first game UI concept for main menu and level select.
Game theme: weather puzzle, premium indie.
Include:
- Main menu
- World selection
- Level selection grid
- Card hand HUD mockup
Constraints:
- Thumb-friendly spacing
- One-handed comfort zones
- Portrait-first layout with desktop adaptation notes
```

## Prompt 5: Animation Keyframe Reference

```text
Generate a 2D keyframe concept sheet for weather card play animations.
Include short sequences for:
- Rain placement ripple
- Frost crystallization spread
- Sun evaporation pulse
- Lightning impact flash
- Fog reveal/clear transition
Style: smooth, readable, not overly noisy.
```

## Using this with agents and Godot

1. Generate references in **Gemini / Google AI Studio** (or any image model) using the prompts above; export PNGs to `assets/reference/` (or a dated folder).
2. **Art/UI agents** align exports with `docs/ART_DIRECTION.md` (sizes, palette, readability).
3. **Implementation** happens in Godot scenes/themes; agents can use **Godot MCP** (`run_project`, `get_debug_output`) to verify layout and errors.
4. **Mobile + “console” readability:** pair reference prompts with editor checks using `tools/tasks/mobile-preview.ps1` and small display sizes; Steam Deck counts as a touch-biased, limited-resolution target.
5. **Gemini CLI** (and the Google **Gemini IDE companion**) are enough to refine prompts locally; paste results into Stitch or AI Studio. Optional **Gemini MCP** is for when Cursor agents must call Gemini inside chat — see [STITCH_UX_WORKFLOW.md](STITCH_UX_WORKFLOW.md).
6. Full UX mockup flow (Stitch + ART_DIRECTION): [STITCH_UX_WORKFLOW.md](STITCH_UX_WORKFLOW.md).

