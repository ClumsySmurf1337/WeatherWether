import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";
import { isOnboardingTitle } from "./linear-queries.js";
import { loadPmPhasePlan, resolvePhaseForIssue } from "./pm-phase-types.js";
import { type AgentRole, inferRoleFromLabels } from "./role-map.js";

loadLinearEnv();

type IssueNode = {
  id: string;
  identifier: string;
  title: string;
  priority: number;
  labels?: { nodes: Array<{ name: string }> };
  state?: { id: string; name: string };
};

type ScopeConfig = Record<string, string[]>;

function parseIssueKey(title: string): { kind: string; token: string } | null {
  const t = title.trim();
  const m = t.match(/^\[([A-Z-]+)\]\s+(.+)$/i);
  if (!m) {
    return null;
  }
  return { kind: m[1].toUpperCase(), token: m[2].toLowerCase() };
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

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const todoStateId = process.env.LINEAR_STATE_TODO_ID;
  const backlogStateId = process.env.LINEAR_STATE_BACKLOG_ID;
  const inProgressStateId = process.env.LINEAR_STATE_IN_PROGRESS_ID;
  const teamKey = process.env.LINEAR_TEAM_KEY ?? "WEA";

  if (!apiKey || !teamId || !todoStateId || !backlogStateId || !inProgressStateId) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_STATE_TODO_ID, LINEAR_STATE_BACKLOG_ID, or LINEAR_STATE_IN_PROGRESS_ID."
    );
  }

  const client = new LinearClient({ apiKey });
  const plan = loadPmPhasePlan();
  const scopePath = resolve(process.cwd(), "docs/backlog/role-file-scope.json");
  const scopes = JSON.parse(readFileSync(scopePath, "utf-8")) as ScopeConfig;

  const [backlog, todo, inProgress] = await Promise.all([
    fetchIssuesInState(client, teamId, backlogStateId),
    fetchIssuesInState(client, teamId, todoStateId),
    fetchIssuesInState(client, teamId, inProgressStateId)
  ]);

  const all = [...inProgress, ...todo, ...backlog].filter((i) => !isOnboardingTitle(i.title));
  const byId = new Map(all.map((i) => [i.identifier, i]));

  const ordered = [...all].sort((a, b) => {
    const la = (a.labels?.nodes ?? []).map((x) => x.name);
    const lb = (b.labels?.nodes ?? []).map((x) => x.name);
    const pa = resolvePhaseForIssue(plan, la, a.title);
    const pb = resolvePhaseForIssue(plan, lb, b.title);
    if (pa.order !== pb.order) {
      return pa.order - pb.order;
    }
    if (a.priority !== b.priority) {
      return a.priority - b.priority;
    }
    return a.identifier.localeCompare(b.identifier);
  });

  const firstByKindToken = new Map<string, string>();
  for (const issue of ordered) {
    const key = parseIssueKey(issue.title);
    if (!key) {
      continue;
    }
    const composite = `${key.kind}:${key.token}`;
    if (!firstByKindToken.has(composite)) {
      firstByKindToken.set(composite, issue.identifier);
    }
  }

  const lines: string[] = [];
  lines.push(`# Dependency + file-scope plan (${teamKey})`);
  lines.push("");
  lines.push("Generated from Linear Backlog/Todo/In Progress using phase ordering heuristics.");
  lines.push("");
  lines.push("## Role file scopes");
  lines.push("");
  for (const [role, paths] of Object.entries(scopes)) {
    lines.push(`- **${role}**: ${paths.join(", ")}`);
  }
  lines.push("");
  lines.push("## Ordered task queue");
  lines.push("");
  lines.push("| Issue | Role | Phase | State | Suggested depends on | Primary file scope |");
  lines.push("|---|---|---:|---|---|---|");

  for (const issue of ordered) {
    const labels = (issue.labels?.nodes ?? []).map((l) => l.name);
    const role = inferRoleFromLabels(labels, issue.title) as AgentRole;
    const ph = resolvePhaseForIssue(plan, labels, issue.title);
    const parsed = parseIssueKey(issue.title);
    let dep = "";
    if (parsed) {
      // Task-chain heuristics for level lanes.
      if (parsed.kind === "LEVEL-IMPLEMENT") {
        dep = firstByKindToken.get(`LEVEL-DESIGN:${parsed.token}`) ?? "";
      } else if (parsed.kind === "LEVEL-PLAYTEST" || parsed.kind === "LEVEL-VALIDATE") {
        dep = firstByKindToken.get(`LEVEL-IMPLEMENT:${parsed.token}`) ?? "";
      }
    }
    if (!dep && ph.order > 0) {
      dep = `phase<${ph.order} complete`;
    }
    const scope = (scopes[role] ?? []).slice(0, 3).join(", ");
    const state = issue.state?.name ?? "";
    lines.push(
      `| ${issue.identifier} | ${role} | ${ph.order} | ${state} | ${dep || "-"} | ${scope || "-"} |`
    );
  }

  lines.push("");
  lines.push("## Notes");
  lines.push("");
  lines.push("- This is a planning artifact; it does not write Linear relation edges yet.");
  lines.push("- Use it to avoid overlap and choose next lane claims before `linear:resume-pickup --apply`.");

  const outDir = resolve(process.cwd(), "assignments/generated");
  mkdirSync(outDir, { recursive: true });
  const outPath = resolve(outDir, "dependency-scope-plan.md");
  writeFileSync(outPath, lines.join("\n") + "\n", "utf-8");
  console.log(`Wrote ${outPath} for ${ordered.length} issue(s).`);
  console.log(`Use this plan to keep roles in non-overlapping paths and honor phase dependencies.`);

  // Keep tsc happy with byId currently unused in markdown path; helpful for future relation writer.
  if (byId.size < 0) {
    console.log("noop");
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

