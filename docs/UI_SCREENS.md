# Weather Whether — UI Screens Spec

> **Status:** Authoritative UI spec for v1. Pairs with `docs/GAME_DESIGN.md` and `docs/ASSET_MANIFEST.md`.
>
> **For agents:** Each screen below has an SVG wireframe, exact layout regions, behavior for every interactive element, and a list of which sprites/fonts it uses. SVGs are wireframes for structure — they are NOT the final art. Final art is generated separately per `docs/ASSET_PROMPTS_GEMINI.md`.
>
> **Last updated:** 2026-04-10

---

## Color tokens

All UIs pull from this palette. Hex values match `assets/styleguide/Assets.png`.

| Token | Hex | Use |
|---|---|---|
| `bg.deep` | `#0a1428` | Page background |
| `bg.panel` | `#142844` | Card/panel backgrounds |
| `bg.panel_alt` | `#1f3a5c` | Inset panels (move counter, hint banner) |
| `border.frame` | `#3a5f8a` | Panel borders |
| `text.title` | `#f5e89c` | Wordmark, large titles |
| `text.body` | `#e8eef7` | Body copy |
| `text.muted` | `#8a9bb4` | Subtitles, locked labels |
| `accent.primary` | `#4a90e2` | Primary buttons |
| `accent.success` | `#5fc97e` | Confirm/success/PRIMARY state |
| `accent.warning` | `#e8a73a` | Hint button, warnings |
| `accent.danger` | `#e8584a` | Lose state, destructive |
| `card.rain` | `#3aa8e8` | Rain card glow |
| `card.sun` | `#f0b340` | Sun card glow |
| `card.frost` | `#7ad8e8` | Frost card glow |
| `card.wind` | `#5fc97e` | Wind card glow |
| `card.lightning` | `#a06fe8` | Lightning card glow |
| `card.fog` | `#8a9bb4` | Fog card glow |

---

## Layout fundamentals

- **Reference resolution:** 1080×1920 portrait. All screens design at this size.
- **Safe area:** 48px top, 64px bottom (for iPhone notch and home indicator).
- **Touch target minimum:** 144×144 px (= 48 device px @ 3x).
- **Side margins:** 48px left/right.
- **Vertical rhythm:** 32px between major sections.
- **Font:** Display = `assets/fonts/whether_display.ttf` (custom pixel serif). Body = `assets/fonts/whether_body.ttf` (pixel sans).

---

## Screen 1 — Splash

**Purpose:** Brand impression while save loads. Auto-advances after 1.5s or earlier on tap.

**SVG wireframe:**

```svg
<svg viewBox="0 0 280 498" xmlns="http://www.w3.org/2000/svg">
  <rect width="280" height="498" fill="#0a1428"/>
  <text x="140" y="220" font-family="serif" font-size="42" fill="#f5e89c" text-anchor="middle" font-weight="bold">Weather</text>
  <text x="140" y="270" font-family="serif" font-size="42" fill="#f5e89c" text-anchor="middle" font-weight="bold">Whether</text>
  <text x="140" y="310" font-family="sans-serif" font-size="11" fill="#8a9bb4" text-anchor="middle">CLEVER WEATHER. BRIGHTER TOMORROW.</text>
  <text x="140" y="460" font-family="sans-serif" font-size="9" fill="#8a9bb4" text-anchor="middle">tap to begin</text>
</svg>
```

**Layout:**
- Background: `bg.deep` with subtle parallax cloud sprite scrolling slowly at 10% opacity
- Wordmark centered vertically, 380pt display font, color `text.title`
- Tagline below wordmark, 28pt body font, `text.muted`
- "tap to begin" hint at bottom, fades in after 800ms

**Interactions:**
- Any tap → push **Home** screen
- Auto-advance after 1500ms

**Sprites used:** `wordmark.png`, `splash_clouds.png`

---

## Screen 2 — Home

**Purpose:** Main hub. Three-button vertical layout. No bottom nav.

**SVG wireframe:**

```svg
<svg viewBox="0 0 280 498" xmlns="http://www.w3.org/2000/svg">
  <rect width="280" height="498" fill="#0a1428"/>
  <!-- key art region -->
  <rect x="20" y="20" width="240" height="200" fill="#1f3a5c" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="140" y="115" font-family="serif" font-size="11" fill="#8a9bb4" text-anchor="middle">[ painterly hero key art ]</text>
  <!-- progress strip -->
  <rect x="20" y="230" width="240" height="22" fill="#142844" stroke="#3a5f8a" stroke-width="1" rx="3"/>
  <text x="32" y="245" font-family="sans-serif" font-size="9" fill="#e8eef7">47/132 levels</text>
  <text x="248" y="245" font-family="sans-serif" font-size="9" fill="#f5e89c" text-anchor="end">★ 89</text>
  <!-- buttons -->
  <rect x="40" y="280" width="200" height="44" fill="#4a90e2" stroke="#3a5f8a" stroke-width="2" rx="5"/>
  <text x="140" y="307" font-family="sans-serif" font-size="14" fill="#0a1428" text-anchor="middle" font-weight="bold">CONTINUE</text>
  <rect x="40" y="336" width="200" height="40" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="5"/>
  <text x="140" y="361" font-family="sans-serif" font-size="12" fill="#e8eef7" text-anchor="middle">SELECT LEVEL</text>
  <rect x="40" y="388" width="200" height="40" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="5"/>
  <text x="140" y="413" font-family="sans-serif" font-size="12" fill="#e8eef7" text-anchor="middle">SETTINGS</text>
  <text x="140" y="475" font-family="serif" font-size="14" fill="#f5e89c" text-anchor="middle" font-weight="bold">Weather Whether</text>
</svg>
```

**Layout:**
- Top 40%: Painterly hero image (`assets/sprites/ui/home_hero.png`), 1080×800
- Progress strip below hero: "47/132 levels" left-aligned, "★ 89" right-aligned. Pulled from save data.
- Three buttons stacked center, 200px tall, 32px gap:
  - **CONTINUE** — primary style (`accent.primary`), large
  - **SELECT LEVEL** — secondary style (`bg.panel`)
  - **SETTINGS** — secondary style
- Wordmark at bottom, smaller than splash

**Interactions:**
- CONTINUE → load `save.progress.current_world`/`current_level`, push **Gameplay**
  - If no save (first launch), label changes to "BEGIN" and goes to W1L1
- SELECT LEVEL → push **World Select**
- SETTINGS → push **Settings**

**State variations:**
- First launch (no save): CONTINUE button reads "BEGIN", progress strip shows "0/132 levels"
- All levels complete: CONTINUE button reads "FREEPLAY" and reopens current level

**Sprites used:** `home_hero.png`, `wordmark_small.png`, `button_primary_*.png`, `button_secondary_*.png`

---

## Screen 3 — World Select

**Purpose:** Pick which world to enter. Six worlds in a 2×3 grid, painterly biome cards.

**SVG wireframe:**

```svg
<svg viewBox="0 0 280 498" xmlns="http://www.w3.org/2000/svg">
  <rect width="280" height="498" fill="#0a1428"/>
  <!-- header -->
  <rect x="14" y="14" width="22" height="22" fill="#142844" stroke="#3a5f8a" rx="3"/>
  <text x="25" y="29" font-family="sans-serif" font-size="12" fill="#e8eef7" text-anchor="middle">←</text>
  <text x="140" y="32" font-family="sans-serif" font-size="13" fill="#f5e89c" text-anchor="middle" font-weight="bold">SELECT WORLD</text>
  <!-- 2x3 grid -->
  <g>
    <rect x="20" y="56" width="115" height="120" fill="#1f3a5c" stroke="#3a5f8a" stroke-width="2" rx="4"/>
    <text x="77" y="120" font-family="serif" font-size="9" fill="#8a9bb4" text-anchor="middle">[ Downpour ]</text>
    <text x="77" y="155" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle" font-weight="bold">1. DOWNPOUR</text>
    <text x="77" y="167" font-family="sans-serif" font-size="7" fill="#f5e89c" text-anchor="middle">★★★ 22/22</text>
  </g>
  <g>
    <rect x="145" y="56" width="115" height="120" fill="#1f3a5c" stroke="#3a5f8a" stroke-width="2" rx="4"/>
    <text x="202" y="120" font-family="serif" font-size="9" fill="#8a9bb4" text-anchor="middle">[ Heatwave ]</text>
    <text x="202" y="155" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle" font-weight="bold">2. HEATWAVE</text>
    <text x="202" y="167" font-family="sans-serif" font-size="7" fill="#f5e89c" text-anchor="middle">★★· 7/22</text>
  </g>
  <g>
    <rect x="20" y="186" width="115" height="120" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
    <text x="77" y="250" font-family="sans-serif" font-size="20" fill="#3a5f8a" text-anchor="middle">🔒</text>
    <text x="77" y="285" font-family="sans-serif" font-size="9" fill="#8a9bb4" text-anchor="middle">3. COLD SNAP</text>
  </g>
  <g>
    <rect x="145" y="186" width="115" height="120" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
    <text x="202" y="250" font-family="sans-serif" font-size="20" fill="#3a5f8a" text-anchor="middle">🔒</text>
    <text x="202" y="285" font-family="sans-serif" font-size="9" fill="#8a9bb4" text-anchor="middle">4. GALE FORCE</text>
  </g>
  <g>
    <rect x="20" y="316" width="115" height="120" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
    <text x="77" y="380" font-family="sans-serif" font-size="20" fill="#3a5f8a" text-anchor="middle">🔒</text>
    <text x="77" y="415" font-family="sans-serif" font-size="9" fill="#8a9bb4" text-anchor="middle">5. THUNDERSTORM</text>
  </g>
  <g>
    <rect x="145" y="316" width="115" height="120" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
    <text x="202" y="380" font-family="sans-serif" font-size="20" fill="#3a5f8a" text-anchor="middle">🔒</text>
    <text x="202" y="415" font-family="sans-serif" font-size="9" fill="#8a9bb4" text-anchor="middle">6. WHITEOUT</text>
  </g>
</svg>
```

**Layout:**
- Top header: back arrow (left), "SELECT WORLD" title (center)
- 2×3 grid of world cards, 16px gap
- Each card shows:
  - Painterly biome image filling the top 60%
  - World number + name in display font
  - Star count "★★· 7/22" (filled and unfilled stars + level count)
- Locked worlds: dimmed, padlock icon, no image, no stars

**Interactions:**
- Back arrow → pop to **Home**
- Tap unlocked world card → push **Level Select** for that world
- Tap locked world → shake animation + play "denied" sound

**Sprites used:** `world_card_w1.png` through `world_card_w6.png` (painterly biome art), `lock_icon.png`, `star_filled.png`, `star_empty.png`

---

## Screen 4 — Level Select (in-world map)

**Purpose:** Show all 22 levels of the selected world as a vertical scroll of nodes on a winding path over the world's biome art.

**SVG wireframe:**

```svg
<svg viewBox="0 0 280 498" xmlns="http://www.w3.org/2000/svg">
  <rect width="280" height="498" fill="#0a1428"/>
  <!-- biome bg -->
  <rect x="0" y="48" width="280" height="450" fill="#1f3a5c"/>
  <text x="140" y="280" font-family="serif" font-size="11" fill="#3a5f8a" text-anchor="middle">[ painterly biome bg, scrolls vertically ]</text>
  <!-- header overlay -->
  <rect x="0" y="0" width="280" height="48" fill="#0a1428" opacity="0.85"/>
  <rect x="14" y="14" width="22" height="22" fill="#142844" stroke="#3a5f8a" rx="3"/>
  <text x="25" y="29" font-family="sans-serif" font-size="12" fill="#e8eef7" text-anchor="middle">←</text>
  <text x="140" y="22" font-family="sans-serif" font-size="11" fill="#f5e89c" text-anchor="middle" font-weight="bold">WORLD 1: DOWNPOUR</text>
  <text x="140" y="36" font-family="sans-serif" font-size="8" fill="#e8eef7" text-anchor="middle">7/22 levels • 18 stars</text>
  <!-- winding path with nodes -->
  <path d="M 60 460 Q 100 420 140 400 Q 180 380 200 340 Q 220 300 160 280 Q 100 260 80 220 Q 60 180 130 160 Q 200 140 220 100 Q 240 60 180 80" fill="none" stroke="#3a5f8a" stroke-width="2" stroke-dasharray="3,3"/>
  <!-- completed nodes -->
  <circle cx="60" cy="460" r="11" fill="#5fc97e" stroke="#3a5f8a" stroke-width="2"/>
  <text x="60" y="464" font-family="sans-serif" font-size="9" fill="#0a1428" text-anchor="middle" font-weight="bold">1</text>
  <text x="60" y="482" font-family="sans-serif" font-size="6" fill="#f5e89c" text-anchor="middle">★★★</text>
  <circle cx="140" cy="400" r="11" fill="#5fc97e" stroke="#3a5f8a" stroke-width="2"/>
  <text x="140" y="404" font-family="sans-serif" font-size="9" fill="#0a1428" text-anchor="middle" font-weight="bold">2</text>
  <text x="140" y="422" font-family="sans-serif" font-size="6" fill="#f5e89c" text-anchor="middle">★★·</text>
  <circle cx="200" cy="340" r="11" fill="#5fc97e" stroke="#3a5f8a" stroke-width="2"/>
  <text x="200" y="344" font-family="sans-serif" font-size="9" fill="#0a1428" text-anchor="middle" font-weight="bold">3</text>
  <text x="200" y="362" font-family="sans-serif" font-size="6" fill="#f5e89c" text-anchor="middle">★★★</text>
  <circle cx="160" cy="280" r="11" fill="#5fc97e" stroke="#3a5f8a" stroke-width="2"/>
  <text x="160" y="284" font-family="sans-serif" font-size="9" fill="#0a1428" text-anchor="middle" font-weight="bold">4</text>
  <circle cx="80" cy="220" r="11" fill="#5fc97e" stroke="#3a5f8a" stroke-width="2"/>
  <text x="80" y="224" font-family="sans-serif" font-size="9" fill="#0a1428" text-anchor="middle" font-weight="bold">5</text>
  <circle cx="130" cy="160" r="11" fill="#5fc97e" stroke="#3a5f8a" stroke-width="2"/>
  <text x="130" y="164" font-family="sans-serif" font-size="9" fill="#0a1428" text-anchor="middle" font-weight="bold">6</text>
  <circle cx="220" cy="100" r="11" fill="#5fc97e" stroke="#3a5f8a" stroke-width="2"/>
  <text x="220" y="104" font-family="sans-serif" font-size="9" fill="#0a1428" text-anchor="middle" font-weight="bold">7</text>
  <!-- current level -->
  <circle cx="180" cy="80" r="13" fill="#4a90e2" stroke="#f5e89c" stroke-width="3"/>
  <text x="180" y="84" font-family="sans-serif" font-size="9" fill="#0a1428" text-anchor="middle" font-weight="bold">8</text>
  <!-- locked -->
  <circle cx="180" cy="80" r="13" fill="#4a90e2" stroke="#f5e89c" stroke-width="3" opacity="0"/>
</svg>
```

**Layout:**
- Header bar (48px tall, semi-transparent over biome): back arrow, world title, progress subtitle
- Below header: full-bleed biome painting (the same painting from world select), scrollable vertically
- 22 level nodes positioned along a hand-authored winding path (one path per world, defined in `levels/world1/path.json`)
- Completed nodes: green circle, level number, star rating below
- Current/playable node: blue circle with golden border, gently pulsing
- Locked nodes: dark silhouette, no number visible
- Path between nodes: dashed line (lighter for unwalked-yet)

**Interactions:**
- Back → pop to **World Select**
- Tap completed node → push **Gameplay** for that level (replay)
- Tap current node → push **Gameplay**
- Tap locked node → shake + denied sound + show tooltip "Beat level N to unlock"
- Vertical drag → scroll the biome and path

**Implementation notes:**
- Path JSON for each world: `levels/worldN/path.json` containing `[{level: 1, x: 0.21, y: 0.92}, ...]` with normalized coordinates
- Camera scrolls to keep current level centered on entry
- Locked rule: `node.level <= save.progress.highest_unlocked_level_in_world + 1`

**Sprites used:** `world_bg_w1.png` (full biome), `node_complete.png`, `node_current.png`, `node_locked.png`, `star_*.png`

---

## Screen 5 — Gameplay (the main screen)

**Purpose:** Where the game happens. The most important screen.

**SVG wireframe:**

```svg
<svg viewBox="0 0 280 498" xmlns="http://www.w3.org/2000/svg">
  <rect width="280" height="498" fill="#0a1428"/>
  <!-- header -->
  <rect x="14" y="14" width="22" height="22" fill="#142844" stroke="#3a5f8a" rx="3"/>
  <text x="25" y="29" font-family="sans-serif" font-size="12" fill="#e8eef7" text-anchor="middle">←</text>
  <text x="140" y="22" font-family="sans-serif" font-size="11" fill="#f5e89c" text-anchor="middle" font-weight="bold">LEVEL 12</text>
  <text x="140" y="36" font-family="sans-serif" font-size="8" fill="#e8eef7" text-anchor="middle">Melt the way forward</text>
  <rect x="244" y="14" width="22" height="22" fill="#142844" stroke="#3a5f8a" rx="3"/>
  <text x="255" y="29" font-family="sans-serif" font-size="11" fill="#e8eef7" text-anchor="middle">⏸</text>
  <!-- moves + hint banner -->
  <rect x="20" y="50" width="240" height="36" fill="#142844" stroke="#3a5f8a" stroke-width="1" rx="4"/>
  <text x="36" y="64" font-family="sans-serif" font-size="7" fill="#8a9bb4">MOVES</text>
  <text x="36" y="78" font-family="sans-serif" font-size="14" fill="#f5e89c" font-weight="bold">6</text>
  <circle cx="78" cy="68" r="6" fill="#3aa8e8"/>
  <text x="92" y="71" font-family="sans-serif" font-size="9" fill="#e8eef7">→</text>
  <circle cx="106" cy="68" r="6" fill="#7ad8e8"/>
  <text x="120" y="71" font-family="sans-serif" font-size="8" fill="#8a9bb4">Rain freezes → Ice</text>
  <rect x="226" y="56" width="24" height="24" fill="#142844" stroke="#e8a73a" stroke-width="1" rx="3"/>
  <text x="238" y="73" font-family="sans-serif" font-size="11" fill="#e8a73a" text-anchor="middle">💡</text>
  <!-- queue strip -->
  <rect x="20" y="96" width="240" height="28" fill="#0a1428" stroke="#3a5f8a" stroke-width="1" stroke-dasharray="3,3" rx="3"/>
  <rect x="28" y="100" width="20" height="20" fill="#3aa8e8" rx="2"/>
  <text x="38" y="115" font-family="sans-serif" font-size="9" fill="#0a1428" text-anchor="middle" font-weight="bold">1</text>
  <rect x="52" y="100" width="20" height="20" fill="#7ad8e8" rx="2"/>
  <text x="62" y="115" font-family="sans-serif" font-size="9" fill="#0a1428" text-anchor="middle" font-weight="bold">2</text>
  <text x="140" y="115" font-family="sans-serif" font-size="7" fill="#3a5f8a" text-anchor="middle">tap a card, tap a tile</text>
  <!-- grid -->
  <rect x="20" y="136" width="240" height="200" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <g>
    <rect x="32" y="148" width="36" height="36" fill="#5fc97e" stroke="#3a5f8a"/>
    <rect x="72" y="148" width="36" height="36" fill="#3aa8e8" stroke="#3a5f8a"/>
    <rect x="112" y="148" width="36" height="36" fill="#7ad8e8" stroke="#3a5f8a"/>
    <rect x="152" y="148" width="36" height="36" fill="#1f3a5c" stroke="#3a5f8a"/>
    <rect x="192" y="148" width="36" height="36" fill="#5fc97e" stroke="#3a5f8a"/>
    <rect x="32" y="188" width="36" height="36" fill="#3aa8e8" stroke="#3a5f8a"/>
    <rect x="72" y="188" width="36" height="36" fill="#3aa8e8" stroke="#3a5f8a"/>
    <rect x="112" y="188" width="36" height="36" fill="#7ad8e8" stroke="#3a5f8a"/>
    <rect x="152" y="188" width="36" height="36" fill="#1f3a5c" stroke="#3a5f8a"/>
    <rect x="192" y="188" width="36" height="36" fill="#5fc97e" stroke="#3a5f8a"/>
    <rect x="32" y="228" width="36" height="36" fill="#5fc97e" stroke="#3a5f8a"/>
    <rect x="72" y="228" width="36" height="36" fill="#7ad8e8" stroke="#3a5f8a"/>
    <rect x="112" y="228" width="36" height="36" fill="#7ad8e8" stroke="#3a5f8a"/>
    <rect x="152" y="228" width="36" height="36" fill="#5fc97e" stroke="#3a5f8a"/>
    <rect x="192" y="228" width="36" height="36" fill="#5fc97e" stroke="#3a5f8a"/>
    <rect x="32" y="268" width="36" height="36" fill="#3a5f8a" stroke="#3a5f8a"/>
    <rect x="72" y="268" width="36" height="36" fill="#5fc97e" stroke="#3a5f8a"/>
    <rect x="112" y="268" width="36" height="36" fill="#5fc97e" stroke="#3a5f8a"/>
    <rect x="152" y="268" width="36" height="36" fill="#5fc97e" stroke="#3a5f8a"/>
    <rect x="192" y="268" width="36" height="36" fill="#e8584a" stroke="#f5e89c" stroke-width="2"/>
  </g>
  <!-- character on start -->
  <circle cx="50" cy="166" r="6" fill="#f5e89c"/>
  <!-- card hand -->
  <g>
    <rect x="20" y="350" width="36" height="44" fill="#3aa8e8" stroke="#3a5f8a" stroke-width="2" rx="4"/>
    <text x="38" y="378" font-family="sans-serif" font-size="6" fill="#0a1428" text-anchor="middle" font-weight="bold">RAIN</text>
    <rect x="60" y="350" width="36" height="44" fill="#f0b340" stroke="#3a5f8a" stroke-width="2" rx="4"/>
    <text x="78" y="378" font-family="sans-serif" font-size="6" fill="#0a1428" text-anchor="middle" font-weight="bold">SUN</text>
    <rect x="100" y="350" width="36" height="44" fill="#7ad8e8" stroke="#3a5f8a" stroke-width="2" rx="4"/>
    <text x="118" y="378" font-family="sans-serif" font-size="6" fill="#0a1428" text-anchor="middle" font-weight="bold">FROST</text>
    <rect x="140" y="350" width="36" height="44" fill="#5fc97e" stroke="#3a5f8a" stroke-width="2" rx="4"/>
    <text x="158" y="378" font-family="sans-serif" font-size="6" fill="#0a1428" text-anchor="middle" font-weight="bold">WIND</text>
    <rect x="180" y="350" width="36" height="44" fill="#a06fe8" stroke="#3a5f8a" stroke-width="2" rx="4"/>
    <text x="198" y="378" font-family="sans-serif" font-size="6" fill="#0a1428" text-anchor="middle" font-weight="bold">LIGHT</text>
    <rect x="220" y="350" width="36" height="44" fill="#8a9bb4" stroke="#3a5f8a" stroke-width="2" rx="4"/>
    <text x="238" y="378" font-family="sans-serif" font-size="6" fill="#0a1428" text-anchor="middle" font-weight="bold">FOG</text>
  </g>
  <!-- bottom controls -->
  <rect x="20" y="408" width="40" height="36" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="40" y="430" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle">UNDO</text>
  <rect x="68" y="408" width="144" height="36" fill="#5fc97e" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="140" y="430" font-family="sans-serif" font-size="11" fill="#0a1428" text-anchor="middle" font-weight="bold">▶ PLAY SEQUENCE</text>
  <rect x="220" y="408" width="40" height="36" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="240" y="430" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle">×</text>
</svg>
```

**Layout regions (top to bottom):**

1. **Header bar (48px):** back arrow (left), level number + insight text (center), pause button (right)
2. **Hint banner (40px):** "MOVES 6" counter on the left, then iconographic insight `[card1] → [card2]` and one-line text. Hint button on the right.
3. **Queue strip (40px):** Dashed-border container showing queued cards as small numbered tiles. Empty state shows hint text "tap a card, tap a tile".
4. **Grid (variable, ~960px max):** The puzzle board. Each tile 144×144 px at base. Auto-scales for grids larger than 5×6. Character sprite overlays the START tile during planning.
5. **Card hand (160px):** Horizontal scrollable strip of 6 weather cards. Each card 144×176 px. Available cards in full color, exhausted cards (already in queue) at 30% opacity.
6. **Bottom controls (160px):** UNDO (left, 144px), PLAY SEQUENCE (center, 580px, primary green button), CANCEL (right, 144px) — clears entire queue.

**Interactions:**

| Element | Tap | Long-press | Drag |
|---|---|---|---|
| Back arrow | Pause game, push **Pause** screen | — | — |
| Pause icon | Push **Pause** | — | — |
| Hint button | Show **Hint** popup | — | — |
| Card in hand | Select (lift) | Show card description tooltip | Drag onto grid for visual placement |
| Grid tile (when card selected) | Place card at this position, add to queue, update preview | — | — |
| Grid tile (no card selected) | Show terrain name tooltip | — | — |
| Queued card | Remove from queue (with confirm shake) | Show details | Reorder within queue |
| UNDO | Pop the last card from queue | — | — |
| PLAY SEQUENCE | Begin sequence resolution | — | — |
| CANCEL | Clear entire queue | — | — |

**Sequence resolution sub-state:** Once PLAY SEQUENCE is tapped, the entire control strip is replaced with a single SPEED button that toggles 1x/2x. UNDO/CANCEL/PLAY are disabled until the walk phase completes.

**State variations:**

- **Empty queue:** PLAY SEQUENCE button disabled (grayed out).
- **Full queue (queue.size == max_moves):** Card hand shows "no more moves" overlay; only UNDO/CANCEL/PLAY are interactive.
- **Sequence playing:** UNDO/CANCEL hidden, PLAY SEQUENCE replaced with SPEED toggle.
- **Walk phase:** All controls disabled. Only header pause works.
- **Win:** Push **Level Complete** after walk anim finishes.
- **Lose:** Push **Level Failed** popup over current state.

**Sprites used:** Every tile sprite (`tile_*.png`), every card sprite (`card_*.png`), `character_*.png`, button sprites, hint icons.

---

## Screen 6 — Level Complete

**Purpose:** Reward the player for solving a level. The big payoff moment.

**SVG wireframe:**

```svg
<svg viewBox="0 0 280 498" xmlns="http://www.w3.org/2000/svg">
  <rect width="280" height="498" fill="#0a1428"/>
  <!-- celebration bg -->
  <rect x="0" y="0" width="280" height="280" fill="#1f3a5c"/>
  <text x="140" y="160" font-family="serif" font-size="11" fill="#3a5f8a" text-anchor="middle">[ painterly sunrise key art ]</text>
  <!-- stars -->
  <text x="80" y="220" font-family="serif" font-size="42" fill="#f5e89c" text-anchor="middle">★</text>
  <text x="140" y="220" font-family="serif" font-size="42" fill="#f5e89c" text-anchor="middle">★</text>
  <text x="200" y="220" font-family="serif" font-size="42" fill="#f5e89c" text-anchor="middle">★</text>
  <!-- title -->
  <text x="140" y="270" font-family="serif" font-size="22" fill="#f5e89c" text-anchor="middle" font-weight="bold">BRILLIANT.</text>
  <text x="140" y="290" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle">You found the perfect path.</text>
  <!-- stat panel -->
  <rect x="40" y="310" width="200" height="60" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="80" y="330" font-family="sans-serif" font-size="7" fill="#8a9bb4" text-anchor="middle">MOVES</text>
  <text x="80" y="354" font-family="sans-serif" font-size="14" fill="#f5e89c" text-anchor="middle" font-weight="bold">6</text>
  <text x="140" y="330" font-family="sans-serif" font-size="7" fill="#8a9bb4" text-anchor="middle">BEST</text>
  <text x="140" y="354" font-family="sans-serif" font-size="14" fill="#f5e89c" text-anchor="middle" font-weight="bold">6</text>
  <text x="200" y="330" font-family="sans-serif" font-size="7" fill="#8a9bb4" text-anchor="middle">PAR</text>
  <text x="200" y="354" font-family="sans-serif" font-size="14" fill="#5fc97e" text-anchor="middle" font-weight="bold">6</text>
  <!-- buttons -->
  <rect x="40" y="395" width="200" height="40" fill="#5fc97e" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="140" y="420" font-family="sans-serif" font-size="12" fill="#0a1428" text-anchor="middle" font-weight="bold">NEXT LEVEL ▶</text>
  <rect x="40" y="445" width="95" height="32" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="87" y="465" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle">REPLAY</text>
  <rect x="145" y="445" width="95" height="32" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="192" y="465" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle">WORLD MAP</text>
</svg>
```

**Layout:**
- Top half: Painterly sunrise/celebration art (per-world variant)
- Three stars centered (animate in one at a time, 200ms between, with sparkle particles)
- "BRILLIANT." title (text changes by star count: ⭐ "Done.", ⭐⭐ "Nice.", ⭐⭐⭐ "Brilliant.")
- Tagline (changes by star count)
- Stat panel: Moves used / Personal best / Par
- Big NEXT LEVEL button
- Replay + World Map secondary buttons

**Interactions:**
- NEXT LEVEL → load next level, push **Gameplay** (or **World Complete** if last level of world)
- REPLAY → reload current level, push **Gameplay**
- WORLD MAP → pop to **Level Select**

**State variations:**
- New high score: extra "NEW BEST!" badge
- First time perfect (3 stars): extra confetti burst
- Last level of world: NEXT LEVEL button reads "NEXT WORLD ▶"
- Last level of game: NEXT LEVEL button reads "EPILOGUE" → cutscene (v1.5)

**Sprites used:** `level_complete_sunrise_w*.png`, `star_filled.png`, `confetti_*.png`

---

## Screen 7 — Level Failed

**Purpose:** Sad-but-gentle "try again" overlay when the character dies.

**SVG wireframe:**

```svg
<svg viewBox="0 0 280 498" xmlns="http://www.w3.org/2000/svg">
  <!-- dimmed gameplay behind -->
  <rect width="280" height="498" fill="#0a1428"/>
  <rect width="280" height="498" fill="#0a1428" opacity="0.7"/>
  <!-- modal -->
  <rect x="30" y="160" width="220" height="200" fill="#142844" stroke="#e8584a" stroke-width="2" rx="6"/>
  <text x="140" y="200" font-family="serif" font-size="20" fill="#e8584a" text-anchor="middle" font-weight="bold">OH NO.</text>
  <text x="140" y="222" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle">Sky drowned in the river.</text>
  <text x="140" y="248" font-family="sans-serif" font-size="42" text-anchor="middle">💧</text>
  <rect x="50" y="270" width="180" height="34" fill="#4a90e2" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="140" y="291" font-family="sans-serif" font-size="11" fill="#0a1428" text-anchor="middle" font-weight="bold">TRY AGAIN</text>
  <rect x="50" y="312" width="86" height="30" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="93" y="331" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle">UNDO LAST</text>
  <rect x="144" y="312" width="86" height="30" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="187" y="331" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle">HINT</text>
</svg>
```

**Layout:**
- Background dims to 70% opacity
- Centered modal with red border
- Title varies by death type:
  - Drown: "Sky drowned in the river."
  - Burn: "The ground was too hot."
  - Fall: "Sky fell into the gap."
  - (Electrocute, Freeze: v1.5)
- Big icon (💧 / 🔥 / 🕳)
- TRY AGAIN button (resets queue, reloads board state)
- UNDO LAST + HINT secondary

**Interactions:**
- TRY AGAIN → restore initial board, clear queue, push back to **Gameplay**
- UNDO LAST → restore initial board, queue all cards EXCEPT the last one, push back to **Gameplay**
- HINT → push **Hint** popup over this modal

**Sprites used:** `death_drown.png`, `death_burn.png`, `death_fall.png`, modal frame sprites

---

## Screen 8 — No Path Forward (soft lose)

**Purpose:** When the sequence resolves but no walkable path exists, show this instead of letting the character do nothing.

**SVG wireframe:**

```svg
<svg viewBox="0 0 280 498" xmlns="http://www.w3.org/2000/svg">
  <rect width="280" height="498" fill="#0a1428"/>
  <rect width="280" height="498" fill="#0a1428" opacity="0.7"/>
  <rect x="30" y="170" width="220" height="180" fill="#142844" stroke="#e8a73a" stroke-width="2" rx="6"/>
  <text x="140" y="208" font-family="serif" font-size="18" fill="#e8a73a" text-anchor="middle" font-weight="bold">NO PATH FORWARD</text>
  <text x="140" y="232" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle">Sky can't reach the goal.</text>
  <text x="140" y="246" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle">Try a different order.</text>
  <rect x="50" y="265" width="180" height="32" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="140" y="285" font-family="sans-serif" font-size="10" fill="#e8eef7" text-anchor="middle">UNDO LAST</text>
  <rect x="50" y="303" width="180" height="32" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="140" y="323" font-family="sans-serif" font-size="10" fill="#e8eef7" text-anchor="middle">RESTART</text>
</svg>
```

**Layout / Interactions:** Less alarming than Level Failed (yellow border, not red). No death anim. Two options to recover.

---

## Screen 9 — Pause

**Purpose:** Let the player pause mid-level.

**SVG wireframe:**

```svg
<svg viewBox="0 0 280 498" xmlns="http://www.w3.org/2000/svg">
  <rect width="280" height="498" fill="#0a1428"/>
  <rect width="280" height="498" fill="#0a1428" opacity="0.85"/>
  <text x="140" y="120" font-family="serif" font-size="28" fill="#f5e89c" text-anchor="middle" font-weight="bold">PAUSED</text>
  <rect x="60" y="170" width="160" height="40" fill="#4a90e2" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="140" y="195" font-family="sans-serif" font-size="11" fill="#0a1428" text-anchor="middle" font-weight="bold">RESUME</text>
  <rect x="60" y="220" width="160" height="36" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="140" y="243" font-family="sans-serif" font-size="10" fill="#e8eef7" text-anchor="middle">RESTART LEVEL</text>
  <rect x="60" y="266" width="160" height="36" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="140" y="289" font-family="sans-serif" font-size="10" fill="#e8eef7" text-anchor="middle">SETTINGS</text>
  <rect x="60" y="312" width="160" height="36" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="140" y="335" font-family="sans-serif" font-size="10" fill="#e8eef7" text-anchor="middle">QUIT TO WORLD MAP</text>
</svg>
```

**Interactions:**
- RESUME → close pause, return to **Gameplay** in exact same state
- RESTART LEVEL → reload level, clear queue, return to **Gameplay**
- SETTINGS → push **Settings** (modal style — pops back here)
- QUIT TO WORLD MAP → pop to **Level Select**

---

## Screen 10 — Settings

**Purpose:** Single scrollable settings screen. See GDD §14 for full content.

**SVG wireframe:**

```svg
<svg viewBox="0 0 280 498" xmlns="http://www.w3.org/2000/svg">
  <rect width="280" height="498" fill="#0a1428"/>
  <rect x="14" y="14" width="22" height="22" fill="#142844" stroke="#3a5f8a" rx="3"/>
  <text x="25" y="29" font-family="sans-serif" font-size="12" fill="#e8eef7" text-anchor="middle">←</text>
  <text x="140" y="28" font-family="sans-serif" font-size="13" fill="#f5e89c" text-anchor="middle" font-weight="bold">SETTINGS</text>
  <!-- audio section -->
  <text x="20" y="64" font-family="sans-serif" font-size="9" fill="#8a9bb4">AUDIO</text>
  <rect x="20" y="72" width="240" height="80" fill="#142844" stroke="#3a5f8a" stroke-width="1" rx="3"/>
  <text x="32" y="90" font-family="sans-serif" font-size="9" fill="#e8eef7">Master</text>
  <rect x="100" y="84" width="148" height="6" fill="#1f3a5c" rx="3"/>
  <rect x="100" y="84" width="120" height="6" fill="#4a90e2" rx="3"/>
  <text x="32" y="113" font-family="sans-serif" font-size="9" fill="#e8eef7">Music</text>
  <rect x="100" y="107" width="148" height="6" fill="#1f3a5c" rx="3"/>
  <rect x="100" y="107" width="100" height="6" fill="#4a90e2" rx="3"/>
  <text x="32" y="136" font-family="sans-serif" font-size="9" fill="#e8eef7">SFX</text>
  <rect x="100" y="130" width="148" height="6" fill="#1f3a5c" rx="3"/>
  <rect x="100" y="130" width="148" height="6" fill="#4a90e2" rx="3"/>
  <!-- visual section -->
  <text x="20" y="172" font-family="sans-serif" font-size="9" fill="#8a9bb4">VISUAL</text>
  <rect x="20" y="180" width="240" height="68" fill="#142844" stroke="#3a5f8a" stroke-width="1" rx="3"/>
  <text x="32" y="198" font-family="sans-serif" font-size="9" fill="#e8eef7">Color blind mode</text>
  <text x="248" y="198" font-family="sans-serif" font-size="9" fill="#8a9bb4" text-anchor="end">Off ▾</text>
  <text x="32" y="220" font-family="sans-serif" font-size="9" fill="#e8eef7">Reduce motion</text>
  <rect x="228" y="214" width="22" height="12" fill="#1f3a5c" rx="6"/>
  <circle cx="234" cy="220" r="5" fill="#8a9bb4"/>
  <text x="32" y="240" font-family="sans-serif" font-size="9" fill="#e8eef7">Show grid overlay</text>
  <rect x="228" y="234" width="22" height="12" fill="#5fc97e" rx="6"/>
  <circle cx="244" cy="240" r="5" fill="#f5e89c"/>
  <!-- gameplay section -->
  <text x="20" y="266" font-family="sans-serif" font-size="9" fill="#8a9bb4">GAMEPLAY</text>
  <rect x="20" y="274" width="240" height="48" fill="#142844" stroke="#3a5f8a" stroke-width="1" rx="3"/>
  <text x="32" y="292" font-family="sans-serif" font-size="9" fill="#e8eef7">Show hint after</text>
  <text x="248" y="292" font-family="sans-serif" font-size="9" fill="#8a9bb4" text-anchor="end">60s ▾</text>
  <text x="32" y="314" font-family="sans-serif" font-size="9" fill="#e8eef7">Confirm sequence</text>
  <rect x="228" y="308" width="22" height="12" fill="#1f3a5c" rx="6"/>
  <circle cx="234" cy="314" r="5" fill="#8a9bb4"/>
  <!-- account -->
  <text x="20" y="340" font-family="sans-serif" font-size="9" fill="#8a9bb4">ACCOUNT</text>
  <rect x="20" y="348" width="240" height="32" fill="#142844" stroke="#e8584a" stroke-width="1" rx="3"/>
  <text x="140" y="367" font-family="sans-serif" font-size="9" fill="#e8584a" text-anchor="middle">RESET PROGRESS</text>
  <text x="140" y="478" font-family="sans-serif" font-size="8" fill="#8a9bb4" text-anchor="middle">Weather Whether v0.1.0</text>
</svg>
```

**Interactions:** Sliders adjust live, toggles persist immediately to save, reset progress requires double-confirm modal.

---

## Screen 11 — Hint Popup

**Purpose:** Show the player the next correct move without solving the whole puzzle for them.

**SVG wireframe:**

```svg
<svg viewBox="0 0 280 498" xmlns="http://www.w3.org/2000/svg">
  <rect width="280" height="498" fill="#0a1428" opacity="0.7"/>
  <rect x="40" y="180" width="200" height="170" fill="#142844" stroke="#e8a73a" stroke-width="2" rx="6"/>
  <text x="140" y="208" font-family="serif" font-size="16" fill="#e8a73a" text-anchor="middle" font-weight="bold">HINT</text>
  <text x="140" y="228" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle">Try this next:</text>
  <rect x="100" y="244" width="36" height="44" fill="#3aa8e8" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="118" y="270" font-family="sans-serif" font-size="6" fill="#0a1428" text-anchor="middle" font-weight="bold">RAIN</text>
  <text x="148" y="270" font-family="sans-serif" font-size="14" fill="#e8eef7">→</text>
  <rect x="160" y="252" width="28" height="28" fill="#5fc97e" stroke="#e8a73a" stroke-width="2"/>
  <text x="174" y="298" font-family="sans-serif" font-size="6" fill="#8a9bb4" text-anchor="middle">tile (3,2)</text>
  <rect x="60" y="305" width="160" height="32" fill="#4a90e2" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="140" y="325" font-family="sans-serif" font-size="10" fill="#0a1428" text-anchor="middle" font-weight="bold">GOT IT</text>
</svg>
```

**Layout:** Modal showing the next card from the optimal solution and the tile to play it on. Tapping GOT IT highlights that tile briefly on the board behind.

---

## Screen 12 — Confirm Sequence Popup (optional)

**Purpose:** For "Confirm Sequence" setting users, double-check before playing.

**SVG wireframe:**

```svg
<svg viewBox="0 0 280 498" xmlns="http://www.w3.org/2000/svg">
  <rect width="280" height="498" fill="#0a1428" opacity="0.7"/>
  <rect x="30" y="170" width="220" height="180" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="6"/>
  <text x="140" y="200" font-family="serif" font-size="16" fill="#f5e89c" text-anchor="middle" font-weight="bold">PLAY SEQUENCE?</text>
  <text x="140" y="220" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle">Play these 5 cards in order?</text>
  <g transform="translate(70, 235)">
    <rect x="0" y="0" width="22" height="28" fill="#3aa8e8" rx="3"/>
    <text x="11" y="18" font-family="sans-serif" font-size="6" fill="#0a1428" text-anchor="middle" font-weight="bold">RAIN</text>
    <rect x="28" y="0" width="22" height="28" fill="#f0b340" rx="3"/>
    <text x="39" y="18" font-family="sans-serif" font-size="6" fill="#0a1428" text-anchor="middle" font-weight="bold">SUN</text>
    <rect x="56" y="0" width="22" height="28" fill="#7ad8e8" rx="3"/>
    <text x="67" y="18" font-family="sans-serif" font-size="5" fill="#0a1428" text-anchor="middle" font-weight="bold">FROST</text>
    <rect x="84" y="0" width="22" height="28" fill="#5fc97e" rx="3"/>
    <text x="95" y="18" font-family="sans-serif" font-size="6" fill="#0a1428" text-anchor="middle" font-weight="bold">WIND</text>
    <rect x="112" y="0" width="22" height="28" fill="#a06fe8" rx="3"/>
    <text x="123" y="18" font-family="sans-serif" font-size="5" fill="#0a1428" text-anchor="middle" font-weight="bold">LIGHT</text>
  </g>
  <rect x="50" y="290" width="180" height="34" fill="#5fc97e" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="140" y="311" font-family="sans-serif" font-size="11" fill="#0a1428" text-anchor="middle" font-weight="bold">▶ PLAY</text>
  <rect x="50" y="328" width="180" height="20" fill="#142844" stroke="#3a5f8a" stroke-width="2" rx="4"/>
  <text x="140" y="342" font-family="sans-serif" font-size="9" fill="#e8eef7" text-anchor="middle">CANCEL</text>
</svg>
```

**Interactions:** PLAY commits the sequence, CANCEL returns to planning. Only shown if `settings.confirm_sequence == true`.

---

## Navigation map

```
Splash
  ↓ tap
Home ──────────┬──────────┐
  │            │          │
  ↓            ↓          ↓
Continue   World Select  Settings
              │
              ↓ tap world
            Level Select (in-world map)
              │
              ↓ tap level
            Gameplay ─────────┬─────────┐
              │               │         │
              ├ pause        win       lose
              ↓               ↓         ↓
            Pause     Level Complete  Level Failed
              ↓               ↓         ↓
              ↑          Gameplay  Gameplay
              ↑           (next)    (retry)
              │
              ├ Hint popup (overlay, dismisses to Gameplay)
              ├ Confirm Sequence popup (overlay)
              └ No Path Forward popup (overlay)
```

---

## Implementation notes for agents

1. **Every screen is a Godot scene** in `scenes/ui/`. Filenames: `splash.tscn`, `home.tscn`, `world_select.tscn`, `level_select.tscn`, `gameplay.tscn`, `level_complete.tscn`, `level_failed.tscn`, `no_path.tscn`, `pause.tscn`, `settings.tscn`, `hint_popup.tscn`, `confirm_sequence.tscn`.
2. **Use a single `UIManager` autoload** to handle scene push/pop with the standard transitions defined in §13 of GAME_DESIGN.md.
3. **Reference design tokens** from `scripts/ui/ui_theme.gd` — never hardcode hex values in scenes.
4. **Touch target sanity check:** every interactive element must be at least 144×144 px in the scene. Add invisible padding if the visual is smaller.
5. **Test on phone aspect ratios:** 9:16, 9:19.5, 9:21. The grid in Gameplay must fit comfortably in all three with the card hand and controls visible.
6. **All popups are modal `CanvasLayer` overlays**, not pushed scenes. They float above the current screen.
