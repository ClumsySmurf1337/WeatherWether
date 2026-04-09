import { LinearClient } from "@linear/sdk";
import { mkdirSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

import { loadLinearEnv } from "./load-env.js";
import { isOnboardingTitle } from "./linear-queries.js";
import { withLinearRetry } from "./retry-linear.js";

loadLinearEnv();

type IssueNode = {
  id: string;
  identifier: string;
  title: string;
  state?: { id: string; name: string } | null;
};

type Parsed = {
  kind: string;
  token: string;
  world?: number;
  batch?: number;
};

type Edge = {
  prerequisiteId: string;
  dependentId: string;
  reason: string;
};

function parseIssue(title: string): Parsed | null {
  const m = title.trim().match(/^\[([A-Z-]+)\]\s+(.+)$/i);
  if (!m) {
    return null;
  }
  const kind = m[1].toUpperCase();
  const token = m[2].trim().toLowerCase();
  const wb = token.match(/\bw(\d+)-b(\d+)\b/i);
  if (wb) {
    return {
      kind,
      token,
      world: Number.parseInt(wb[1], 10),
      batch: Number.parseInt(wb[2], 10)
    };
  }
  return { kind, token };
}

async function fetchIssuesInState(
  client: LinearClient,
  teamId: string,
  stateId: string
): Promise<IssueNode[]> {
  const out: IssueNode[] = [];
  let after: string | undefined;
  do {
    const conn = await client.issues({
      first: 100,
      after,
      filter: {
        team: { id: { eq: teamId } },
        state: { id: { eq: stateId } }
      }
    });
    for (const node of conn.nodes) {
      out.push(node as IssueNode);
    }
    after = conn.pageInfo.hasNextPage ? conn.pageInfo.endCursor : undefined;
  } while (after);
  return out;
}

function canIgnoreRelationError(error: unknown): boolean {
  const msg = String((error as { message?: string })?.message ?? "").toLowerCase();
  return (
    msg.includes("already exists") ||
    msg.includes("must be unique") ||
    msg.includes("cannot relate an issue to itself")
  );
}

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const backlogStateId = process.env.LINEAR_STATE_BACKLOG_ID;
  const todoStateId = process.env.LINEAR_STATE_TODO_ID;
  const inProgressStateId = process.env.LINEAR_STATE_IN_PROGRESS_ID;
  const apply = process.argv.includes("--apply");

  if (!apiKey || !teamId || !backlogStateId || !todoStateId || !inProgressStateId) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_STATE_BACKLOG_ID, LINEAR_STATE_TODO_ID, or LINEAR_STATE_IN_PROGRESS_ID."
    );
  }

  const client = new LinearClient({ apiKey });
  const [backlog, todo, inProgress] = await Promise.all([
    fetchIssuesInState(client, teamId, backlogStateId),
    fetchIssuesInState(client, teamId, todoStateId),
    fetchIssuesInState(client, teamId, inProgressStateId)
  ]);

  const all = [...backlog, ...todo, ...inProgress].filter((i) => !isOnboardingTitle(i.title));
  const byIdentifier = new Map(all.map((i) => [i.identifier, i]));
  const byKindToken = new Map<string, IssueNode>();

  for (const issue of all) {
    const parsed = parseIssue(issue.title);
    if (!parsed) {
      continue;
    }
    const key = `${parsed.kind}:${parsed.token}`;
    if (!byKindToken.has(key)) {
      byKindToken.set(key, issue);
    }
  }

  const edges: Edge[] = [];

  function addEdge(prereq: IssueNode | undefined, dependent: IssueNode | undefined, reason: string): void {
    if (!prereq || !dependent) {
      return;
    }
    if (prereq.identifier === dependent.identifier) {
      return;
    }
    edges.push({
      prerequisiteId: prereq.identifier,
      dependentId: dependent.identifier,
      reason
    });
  }

  // Global foundations.
  const coreGrid = all.find((i) =>
    i.title.toLowerCase().includes("grid manager foundation")
  );
  const mechSequencing = all.find((i) =>
    i.title.toLowerCase().includes("weather card sequencing rules")
  );
  const solverBaseline = all.find((i) =>
    i.title.toLowerCase().includes("solver integration baseline")
  );

  for (const issue of all) {
    const p = parseIssue(issue.title);
    if (!p) {
      continue;
    }
    if (p.kind === "MECH") {
      addEdge(coreGrid, issue, "mechanics after core grid");
    }
    if (p.kind.startsWith("LEVEL")) {
      addEdge(mechSequencing, issue, "levels after weather sequencing mechanics");
      addEdge(solverBaseline, issue, "levels after solver baseline");
    }
    if (p.kind === "UI" || p.kind === "UX") {
      addEdge(coreGrid, issue, "UI after core foundation");
    }
  }

  // Per-batch chains and design->implement->playtest/validate.
  for (const issue of all) {
    const parsed = parseIssue(issue.title);
    if (!parsed) {
      continue;
    }
    const kind = parsed.kind;
    const token = parsed.token;

    if (kind === "LEVEL-IMPLEMENT") {
      addEdge(
        byKindToken.get(`LEVEL-DESIGN:${token}`),
        issue,
        "implement after design"
      );
    }
    if (kind === "LEVEL-PLAYTEST" || kind === "LEVEL-VALIDATE") {
      addEdge(
        byKindToken.get(`LEVEL-IMPLEMENT:${token}`),
        issue,
        `${kind.toLowerCase()} after implement`
      );
    }

    if (
      parsed.world &&
      parsed.batch &&
      parsed.batch > 1 &&
      (kind === "LEVEL-DESIGN" ||
        kind === "LEVEL-IMPLEMENT" ||
        kind === "LEVEL-PLAYTEST" ||
        kind === "LEVEL-VALIDATE")
    ) {
      const prevToken = token.replace(/-b\d+\b/i, `-b${parsed.batch - 1}`);
      addEdge(
        byKindToken.get(`${kind}:${prevToken}`),
        issue,
        `${kind.toLowerCase()} batch ${parsed.batch - 1} before batch ${parsed.batch}`
      );
    }
  }

  // Dedupe relation edges.
  const dedup = new Map<string, Edge>();
  for (const edge of edges) {
    dedup.set(`${edge.prerequisiteId}->${edge.dependentId}`, edge);
  }
  const finalEdges = [...dedup.values()].filter(
    (e) => byIdentifier.has(e.prerequisiteId) && byIdentifier.has(e.dependentId)
  );

  console.log(`Dependency edge candidates: ${finalEdges.length}`);
  for (const edge of finalEdges.slice(0, 40)) {
    console.log(`- ${edge.prerequisiteId} blocks ${edge.dependentId} (${edge.reason})`);
  }
  if (finalEdges.length > 40) {
    console.log(`... ${finalEdges.length - 40} more`);
  }

  const outDir = resolve(process.cwd(), "assignments/generated");
  mkdirSync(outDir, { recursive: true });
  const mdPath = resolve(outDir, "dependency-relations-plan.md");
  const mdLines = [
    "# Linear dependency relations plan",
    "",
    `Generated edges: ${finalEdges.length}`,
    "",
    "| Prerequisite | Dependent | Reason |",
    "|---|---|---|",
    ...finalEdges.map((e) => `| ${e.prerequisiteId} | ${e.dependentId} | ${e.reason} |`)
  ];
  writeFileSync(mdPath, mdLines.join("\n") + "\n", "utf-8");
  console.log(`Wrote ${mdPath}`);

  if (!apply) {
    console.log("Dry run complete. Re-run with --apply to write relation edges in Linear.");
    return;
  }

  let created = 0;
  let skipped = 0;
  for (const edge of finalEdges) {
    try {
      await withLinearRetry(
        () =>
          client.createIssueRelation({
            // prerequisite blocks dependent
            type: "blocks",
            issueId: edge.prerequisiteId,
            relatedIssueId: edge.dependentId
          }),
        `createIssueRelation:${edge.prerequisiteId}->${edge.dependentId}`
      );
      created += 1;
    } catch (error) {
      if (canIgnoreRelationError(error)) {
        skipped += 1;
        continue;
      }
      throw error;
    }
  }
  console.log(`Applied relations: created=${created}, skipped(existing/self)=${skipped}.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

