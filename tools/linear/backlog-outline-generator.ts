export type BacklogIssue = {
  title: string;
  priority: number;
  labels: string[];
  acceptance: string[];
};

type WorldSpec = {
  number: number;
  name: string;
  levels: number;
  mechanics: string;
};

function makeIssue(
  title: string,
  priority: number,
  labels: string[],
  acceptance: string[]
): BacklogIssue {
  return { title, priority, labels, acceptance };
}

function buildWorldBatchIssues(world: WorldSpec, batchSize: number): BacklogIssue[] {
  const issues: BacklogIssue[] = [];
  const batches = Math.ceil(world.levels / batchSize);

  for (let i = 0; i < batches; i += 1) {
    const start = i * batchSize + 1;
    const end = Math.min((i + 1) * batchSize, world.levels);
    const batchTag = `W${world.number}-B${i + 1}`;
    const span = `levels ${start}-${end}`;

    issues.push(
      makeIssue(
        `[LEVEL-DESIGN] ${batchTag} ${world.name} ${span}`,
        2,
        ["Level-Design", "Puzzle-Design"],
        [
          `${world.mechanics} puzzle concepts drafted`,
          "Candidate levels exported to JSON/LDtk",
          "No repeated dominant puzzle archetype"
        ]
      )
    );

    issues.push(
      makeIssue(
        `[LEVEL-IMPLEMENT] ${batchTag} ${world.name} ${span}`,
        2,
        ["Core-Engine", "Level-Design"],
        [
          "Level data integrated into playable flow",
          "Card loadout and goals wired correctly",
          "No runtime errors during level load"
        ]
      )
    );

    issues.push(
      makeIssue(
        `[LEVEL-PLAYTEST] ${batchTag} ${world.name} ${span}`,
        2,
        ["QA-Testing", "Level-Design"],
        [
          "Playtest session notes captured",
          "Difficulty progression sanity-checked",
          "At least 1 actionable iteration note per level"
        ]
      )
    );

    issues.push(
      makeIssue(
        `[LEVEL-VALIDATE] ${batchTag} ${world.name} ${span}`,
        1,
        ["QA-Testing", "Level-Design"],
        [
          "All levels in batch pass solver validation",
          "No unsolvable/softlock paths remain",
          "Validation output archived in QA notes"
        ]
      )
    );
  }

  return issues;
}

export function generateOutlineBacklog(): BacklogIssue[] {
  const issues: BacklogIssue[] = [];

  const coreTrack = [
    "GridManager typed data model",
    "WeatherSystem interaction matrix v1",
    "Turn sequencing and action history",
    "Undo/redo support baseline",
    "Save/load baseline",
    "Level loader integration",
    "Input abstraction for touch/mouse",
    "Card hand controller",
    "Signal contract cleanup",
    "Error reporting hooks",
    "State machine for scene flow",
    "Performance profiling hooks",
    "Tile state serialization",
    "Fog-of-war reveal pipeline",
    "Lightning chain path resolver",
    "Wind push rules baseline",
    "Frost-melt transition rules",
    "Steam platform placeholder flow",
    "Objective and fail-state evaluator",
    "Debug overlay for puzzle state",
    "Mobile-safe interaction zones",
    "Desktop adaptation pass",
    "Autoload wiring cleanup",
    "Data-driven weather tuning",
    "Content flags for experimentation"
  ];
  for (const item of coreTrack) {
    issues.push(
      makeIssue(`[CORE] ${item}`, 1, ["Core-Engine"], [
        "Implementation merged behind deterministic logic",
        "Tests updated for new behavior",
        "No regressions in basic play loop"
      ])
    );
  }

  const uiTrack = [
    "Main menu flow",
    "World select grid",
    "Level select with lock states",
    "HUD card tray mobile ergonomics",
    "Pause/settings panel",
    "Accessibility contrast mode",
    "Dynamic text sizing option",
    "Touch feedback animations",
    "Desktop UI adaptation",
    "Onboarding screens",
    "Hint panel baseline",
    "Result screen and stats",
    "Failure retry UX",
    "Audio controls in settings",
    "Localization-ready string map",
    "Screen transition system",
    "In-game objective panel",
    "Input method indicator"
  ];
  for (const item of uiTrack) {
    issues.push(
      makeIssue(`[UI] ${item}`, 2, ["UI-UX"], [
        "Mobile-first UX behavior validated",
        "Desktop behavior remains coherent",
        "No interaction dead ends"
      ])
    );
  }

  const qaTrack = [
    "GUT suite expansion pass 1",
    "GUT suite expansion pass 2",
    "Regression matrix by weather type",
    "Save/load corruption checks",
    "Level solver benchmark dataset",
    "CI validation gate hardening",
    "Crash repro template",
    "Smoke test checklist automation",
    "Touch input edge-case tests",
    "Performance baseline checks",
    "Telemetry event sanity checks",
    "Release candidate QA script",
    "World progression verification",
    "Accessibility validation pass",
    "Cross-resolution visual QA"
  ];
  for (const item of qaTrack) {
    issues.push(
      makeIssue(`[QA] ${item}`, 2, ["QA-Testing"], [
        "Procedure documented",
        "Findings captured with severity labels",
        "Follow-up tasks linked where needed"
      ])
    );
  }

  const artAudioTrack = [
    "Weather icon family style lock",
    "Tile palette lock",
    "Card frame style variants",
    "Rain VFX pass",
    "Sun VFX pass",
    "Frost VFX pass",
    "Wind VFX pass",
    "Lightning VFX pass",
    "Fog VFX pass",
    "UI transition animation pass",
    "Ambient weather loop set",
    "Interaction SFX set",
    "Menu music exploration",
    "World music motif sketches",
    "Audio bus mix baseline",
    "Low-FX fallback visual mode",
    "Asset naming and folder policy",
    "Visual consistency QA pass"
  ];
  for (const item of artAudioTrack) {
    const labels = item.toLowerCase().includes("audio") || item.toLowerCase().includes("music")
      ? ["Audio Music"]
      : ["Art-Visual"];
    issues.push(
      makeIssue(`[ART-AUDIO] ${item}`, 3, labels, [
        "Reference or implementation delivered",
        "Integrated without readability regressions",
        "Performance impact reviewed"
      ])
    );
  }

  const releaseTrack = [
    "Steam page asset pack prep",
    "Steam build verification checklist",
    "Windows installer/package verification",
    "Release notes template",
    "Crash-reporting baseline",
    "Launch-day rollback checklist",
    "Post-launch hotfix protocol",
    "Android compatibility smoke pass",
    "Android packaging checklist",
    "Mobile telemetry baseline",
    "Privacy policy draft",
    "EULA/license checklist",
    "Press kit baseline",
    "Trailer shotlist draft",
    "Community feedback intake workflow",
    "Store page A/B copy test plan",
    "Localization launch scope decision",
    "Deferred iOS remote-mac activation checklist"
  ];
  for (const item of releaseTrack) {
    issues.push(
      makeIssue(`[RELEASE] ${item}`, 3, ["Release-Ops"], [
        "Documented and reviewed",
        "Dependencies identified",
        "Owner assigned"
      ])
    );
  }

  const worlds: WorldSpec[] = [
    { number: 1, name: "Downpour", levels: 15, mechanics: "Rain-only routing" },
    { number: 2, name: "Heatwave", levels: 15, mechanics: "Rain + Sun ordering" },
    { number: 3, name: "ColdSnap", levels: 20, mechanics: "Rain + Sun + Frost chains" },
    { number: 4, name: "GaleForce", levels: 20, mechanics: "Wind with prior systems" },
    { number: 5, name: "Thunderstorm", levels: 20, mechanics: "Lightning risk/reward" },
    { number: 6, name: "Whiteout", levels: 20, mechanics: "Fog + full toolkit uncertainty" }
  ];

  for (const world of worlds) {
    issues.push(...buildWorldBatchIssues(world, 5));
  }

  return issues;
}
