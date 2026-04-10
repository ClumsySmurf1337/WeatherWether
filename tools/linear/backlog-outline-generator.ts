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
        `[LEVEL] ${batchTag} ${world.name} ${span}`,
        2,
        ["Level-Design", "Puzzle-Design"],
        [
          `${world.mechanics} puzzle concepts drafted`,
          "Candidate level JSONs in levels/worldN/ implementing the batch",
          "All levels in batch pass solver validation (npm run validate)",
          "At least one playtest pass with notes",
          "No repeated dominant puzzle archetype within the batch"
        ]
      )
    );
  }

  return issues;
}

export function generateOutlineBacklog(): BacklogIssue[] {
  const issues: BacklogIssue[] = [];

  const worlds: WorldSpec[] = [
    { number: 1, name: "Downpour", levels: 22, mechanics: "Rain-only routing" },
    { number: 2, name: "Heatwave", levels: 22, mechanics: "Rain + Sun ordering" },
    { number: 3, name: "ColdSnap", levels: 22, mechanics: "Rain + Sun + Frost chains" },
    { number: 4, name: "GaleForce", levels: 22, mechanics: "Wind with prior systems" },
    { number: 5, name: "Thunderstorm", levels: 22, mechanics: "Lightning risk/reward" },
    { number: 6, name: "Whiteout", levels: 22, mechanics: "Fog + full toolkit uncertainty" }
  ];

  for (const world of worlds) {
    issues.push(...buildWorldBatchIssues(world, 5));
  }

  return issues;
}
