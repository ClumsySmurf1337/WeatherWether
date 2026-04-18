/**
 * Curated PM intake: each row maps to authoritative docs so the producer / PM agent
 * can file well-scoped Linear issues with real context (not LLM-generated).
 */
export type PmDocIssueCandidate = {
  /** Stable id for dedupe notes / logs */
  id: string;
  title: string;
  labels: string[];
  priority: number;
  /** Repo-relative path */
  docPath: string;
  /** Matches the `## ...` line body after `## ` (prefix match). */
  sectionHeadingPrefix: string;
  /** Markdown: what builders should deliver (PM-owned). */
  deliverables: string;
  acceptance: string[];
};

export const PM_DOC_ISSUE_CANDIDATES: PmDocIssueCandidate[] = [
  {
    id: "gdd-core-loop",
    title: "[CORE] Implement GDD v2 sequence model (queue, preview, PLAY SEQUENCE, resolve)",
    labels: ["Core-Engine", "Puzzle-Design"],
    priority: 1,
    docPath: "docs/GAME_DESIGN.md",
    sectionHeadingPrefix: "3. Core gameplay loop",
    deliverables:
      "Ship the full planning → commit → resolve → walk spine from **GAME_DESIGN.md §3**: card lift, tile targeting with ghost order, queue strip, reorder/undo, PLAY SEQUENCE, per-card resolve cadence, then walk phase handoff.",
    acceptance: [
      "Behavior matches §3 state machine (planning vs commit vs resolve vs walk)",
      "Tile preview reflects post-queue board state per GDD",
      "GUT coverage for queue + resolve order (existing tests stay green)",
      "`pwsh tools/tasks/validate.ps1` passes for the Godot project path in use"
    ]
  },
  {
    id: "gdd-character-walk",
    title: "[CORE] Character walk + death/soft-lose flows per GDD §4",
    labels: ["Core-Engine", "Puzzle-Design"],
    priority: 1,
    docPath: "docs/GAME_DESIGN.md",
    sectionHeadingPrefix: "4. The character",
    deliverables:
      "Pathfinding after resolve, walk animations per direction, death states (drown/burn/electrocute/freeze/fall), cheer on goal, and OUT OF MOVES / soft-lose when no path — all per **GAME_DESIGN.md §4** and UI spec popups.",
    acceptance: [
      "A* uses walkable terrain rules from GDD + `docs/weather_type` alignment",
      "Each death state triggers correct animation + transition to Level Failed flow",
      "No path → soft-lose path (see UI spec Screen 8) without silent stall"
    ]
  },
  {
    id: "ui-display-profile-desktop-mobile",
    title: "[UI] DisplayProfile: desktop 9:16 window + stretch keep + mobile sim presets (close when shipped)",
    labels: ["UI-UX"],
    priority: 2,
    docPath: "docs/DISPLAY_PROFILE.md",
    sectionHeadingPrefix: "Display profile",
    deliverables:
      "**Shipped on main:** `scripts/autoload/display_profile.gd` (before `UIManager`), `project.godot` stretch `keep`, handheld portrait, env `WHETHER_DISPLAY_PRESET` for 360/540/720/1080 windows on desktop. If this issue is still open, verify against `docs/DISPLAY_PROFILE.md` and close as Done.",
    acceptance: [
      "Desktop/editor opens a centered portrait window that fits the monitor (not 1:1 1080×1920 px by default unless preset)",
      "Android/iOS exports are not forced to a tiny window — DisplayProfile skips mobile OS features",
      "`pwsh tools/tasks/validate.ps1` passes"
    ]
  },
  {
    id: "ui-gameplay-screen",
    title: "[UI] Gameplay screen: HUD, queue strip, hand, PLAY — match UI_SCREENS Screen 5",
    labels: ["UI-UX"],
    priority: 2,
    docPath: "docs/UI_SCREENS.md",
    sectionHeadingPrefix: "Screen 5 — Gameplay (the main screen)",
    deliverables:
      "Implement **Screen 5** layout and behaviors: safe area, move counter, hint banner, grid, hand, queue strip, PLAY SEQUENCE, pause — per **UI_SCREENS.md** and `assets/mocks/level_mockup.svg` proportions where applicable.",
    acceptance: [
      "Touch targets ≥ spec minimum; layout matches wireframe regions",
      "Sprites/fonts referenced in Screen 5 exist or tracked in ASSET_MANIFEST gaps",
      "Screen hooks into GameManager / UI manager patterns already in repo"
    ]
  },
  {
    id: "ui-home-world-level-select",
    title: "[UI] Home, World Select, Level Select flow — Screens 2–4",
    labels: ["UI-UX"],
    priority: 2,
    docPath: "docs/UI_SCREENS.md",
    sectionHeadingPrefix: "Screen 2 — Home",
    deliverables:
      "Three-button home, world map, in-world level path — composite **Screens 2–4** (read §2–4 in UI_SCREENS). Align with unlock model (Linear / GDD: Cut the Rope style).",
    acceptance: [
      "Navigation flow: Splash → Home → World Select → Level Select → Gameplay",
      "Locked/unlocked presentation matches spec copy and visual tokens",
      "World/level data driven (e.g. world JSON) — no hard-coded-only prototype"
    ]
  },
  {
    id: "assets-tiles-cards",
    title: "[art-audio] Pixel tiles + weather card sprite set per ASSET_MANIFEST §1–2",
    labels: ["Art-Visual"],
    priority: 2,
    docPath: "docs/ASSET_MANIFEST.md",
    sectionHeadingPrefix: "1. Tile sprites",
    deliverables:
      "Produce or verify **all §1 tile** and **§2 card** PNGs at paths in **ASSET_MANIFEST.md** (16×16 tiles, 32×48 cards, icon variants). Follow palette + naming conventions in manifest preamble.",
    acceptance: [
      "Every row in §1 and §2 tables has a file at the listed path or an explicit follow-up sub-issue",
      "Import settings: nearest filter, no mipmaps per manifest",
      "Gameplay scenes reference atlas/frames consistent with strip/frame notes"
    ]
  },
  {
    id: "assets-character-ui-audio",
    title: "[art-audio] Character sprite states + core UI/audio assets per ASSET_MANIFEST",
    labels: ["Art-Visual", "Audio-Music"],
    priority: 3,
    docPath: "docs/ASSET_MANIFEST.md",
    sectionHeadingPrefix: "3. Character (Sky) sprites",
    deliverables:
      "Sky character states from GDD §4 + remaining HUD/audio listed in **ASSET_MANIFEST** (sections 3+ as applicable). Coordinate with gameplay for state names and frame counts.",
    acceptance: [
      "All GDD-listed character states have art or documented deferral",
      "UI chrome assets for primary screens exist or are stubbed with manifest tracking",
      "SFX/Music entries either shipped or explicitly scoped out with producer sign-off"
    ]
  },
  {
    id: "spec-diff-rework-parity",
    title: "[CORE] SPEC_DIFF §1–2 parity — instant-resolve debt vs v2",
    labels: ["Core-Engine", "Puzzle-Design"],
    priority: 1,
    docPath: "docs/SPEC_DIFF.md",
    sectionHeadingPrefix: "1. What changed from the original design",
    deliverables:
      "Use **SPEC_DIFF.md** §1 major changes + §2 file table to drive remaining rewrites. PM: break into sub-issues if this umbrella is too large; link PRs back to acceptance rows.",
    acceptance: [
      "Each major row in SPEC_DIFF §1 has either merged code or an open child issue",
      "`docs/CODE_REWRITE_PLAN.md` targets stay in sync with shipped code",
      "No user-facing feature reverts to instant-resolve behavior"
    ]
  },
  {
    id: "gdd-pillars-ux",
    title: "[UI] GDD pillars UX — undo, restart, hint, no dead ends (§2 + §5)",
    labels: ["UI-UX", "Core-Engine"],
    priority: 2,
    docPath: "docs/GAME_DESIGN.md",
    sectionHeadingPrefix: "2. Design pillars",
    deliverables:
      "Implement player safeguards from **§2** (undo, restart, hint, no traps) and cross-check with puzzle flow in later GDD sections. Ensures mobile-first parity.",
    acceptance: [
      "Player can always undo queued cards and restart level from pause/fail",
      "Hint entry points match UI spec; free tier per GDD/SPEC_DIFF",
      "No soft-lock board states without recovery path"
    ]
  },
  {
    id: "blueprint-remaining-gaps",
    title: "[CORE] Close prioritized implementation gaps (BLUEPRINT_GAP_AUDIT — export, LDtk, validation, CI hygiene)",
    labels: ["Core-Engine"],
    priority: 2,
    docPath: "docs/BLUEPRINT_GAP_AUDIT.md",
    sectionHeadingPrefix: "Remaining gaps (prioritized)",
    deliverables:
      "Work through **BLUEPRINT_GAP_AUDIT.md** § *Remaining gaps*: Windows/Steam export + CI, LDtk/level loader, solver-backed validation, branch protection / PR hygiene, optional PR↔Linear and visual QA. Split into child issues per bullet when scope is large.",
    acceptance: [
      "Each numbered gap has a merged fix, an open owned issue, or an explicit deferral with producer sign-off",
      "`pwsh tools/tasks/validate.ps1` stays green; CI expectations unchanged unless intentionally updated"
    ]
  }
];
