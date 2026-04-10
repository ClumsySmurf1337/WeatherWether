# Stitch UX workflow (mockups → Godot)

Use this when you want **high-fidelity UI/UX screens** to design against before building Control trees in Godot.

## Roles of each tool

| Tool | Role |
|------|------|
| **Stitch** (or similar UI mock generator) | Produces **screen-level** layouts: menus, HUD, level select, settings — fast iteration on look and hierarchy. |
| **`docs/ART_DIRECTION.md`** | Non-negotiable **readability, palette, and mobile-first** rules; paste a short excerpt into every Stitch session. |
| **Gemini CLI + VS Code IDE companion** | Refine prompts locally, summarize feedback, or generate variant copy — **no MCP required**. |
| **Gemini MCP** (optional later) | Lets Cursor **agents** invoke Gemini from chat; add only if you want automated prompt↔response loops inside the IDE. |

**Simplest path:** ART_DIRECTION → Stitch prompt (below) → export PNG/PDF → `assets/reference/ui/` → implement in `scenes/ui/` with Godot themes.

## Workflow (5 steps)

1. Copy **Prompt A (master)** below into Stitch; add **Prompt B** for the specific screen you need.
2. Export mockups; name files by screen (`main_menu_v1.png`, `level_select_v1.png`).
3. In Godot, create a **reference TextureRect** (editor-only) or side-by-side monitor; match **spacing and tap targets** before pixel-perfect art.
4. Run `pwsh ./tools/tasks/mobile-preview.ps1` and shrink the window — **thumb zones** must still work.
5. When the scene matches the mockup **structure**, drop the reference from the shipped scene (or move to a `debug/` layer).

## Prompt A — Master style (paste first)

Use verbatim or tweak adjectives; keep the constraints.

```text
Design a premium mobile game UI for "Weather Whether" — a puzzle game where you sequence weather powers (rain, sun, frost, wind, lightning, fog) on a grid.

Brand feeling: calm, clever, atmospheric — "cozy brain teaser" not arcade loud. Think Monument Valley polish meets readable board-game clarity.

Visual style:
- Clean 2D UI: soft rounded cards, subtle depth (light shadow), no clutter.
- Weather is the hero: each weather type gets a distinct accent color (rain = slate/teal, sun = warm amber, frost = icy cyan, wind = soft sage, lightning = violet-white, fog = misty gray) but keep backgrounds restrained so the puzzle stays readable.
- Typography: modern geometric sans, high legibility at small sizes; generous line height.

UX constraints (must follow):
- Portrait-first, 1080×1920 logical layout; safe areas for notches.
- Thumb-friendly: primary actions in lower third; secondary in upper corners.
- Minimum touch targets ~48dp equivalent; clear pressed/disabled states.
- One-handed comfort: no critical buttons in top corners unless paired with bottom alternatives.
- Accessibility: do not rely on color alone — use icons + labels for weather states.

Deliver: high-fidelity UI screens suitable for App Store / Play Store and Steam Deck (scaled); marketing-worthy first impression.
```

## Prompt B — Per-screen add-ons

**Main menu**

```text
Screen: Main menu. Logo wordmark "Weather Whether" with a subtle weather motif (abstract, not cheesy). Buttons: Play, Continue, Settings, Credits. Optional: tiny forecast-style decorative element that does not compete with buttons. CTA hierarchy obvious in 2 seconds.
```

**World / level select**

```text
Screen: World select then level grid. Six biomes as large tappable cards (Downpour, Heatwave, Cold Snap, Gale, Thunderstorm, Whiteout). Locked worlds clearly grayed with lock icon. Level grid: 3 columns, stars/progress per level, back navigation.
```

**In-game HUD**

```text
Screen: In-game HUD overlay on abstract blurred puzzle background. Bottom: horizontal hand of weather cards (5–6 slots) with drag affordance. Top: compact objective text, pause, undo. No element may cover the central grid "danger zone" — keep margins generous.
```

**Settings / pause**

```text
Screen: Pause sheet over dimmed game. Sections: Audio (master, music, SFX), Display (reduce motion, high contrast), Controls hints. Destructive actions absent; Resume is primary.
```

## Gemini CLI (local) without MCP

Use the CLI or IDE companion to:

- Tighten copy ("button labels that sound premium and short").
- Generate 3 variants of a Stitch prompt for A/B mood (minimal vs richer).
- Summarize `ART_DIRECTION.md` into a one-paragraph Stitch preamble.

Keep API keys in your environment or Google account — not in the repo.

## When to add Gemini MCP

Add MCP if you want **Cursor agents** to call Gemini tools directly (e.g. generate prompt text, parse a mockup checklist). For solo iteration, **CLI + copy-paste into Stitch** stays simpler and easier to audit.
