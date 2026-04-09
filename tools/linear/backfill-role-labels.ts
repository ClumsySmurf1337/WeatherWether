import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";
import { isOnboardingTitle } from "./linear-queries.js";
import { inferRoleFromLabels, type AgentRole } from "./role-map.js";

loadLinearEnv();

type IssueNode = {
  id: string;
  identifier: string;
  title: string;
  labels?: { nodes: Array<{ id?: string; name: string }> };
};

const ROLE_LABEL: Record<AgentRole, string> = {
  producer: "Release-Ops",
  "gameplay-programmer": "Core-Engine",
  "ui-developer": "UI-UX",
  "level-designer": "Level-Design",
  "qa-agent": "QA-Testing",
  "art-pipeline": "Art-Visual"
};

function parseCsvEnv(name: string): string[] {
  const raw = process.env[name]?.trim();
  if (!raw) {
    return [];
  }
  return raw
    .split(",")
    .map((x) => x.trim())
    .filter((x) => x.length > 0);
}

function normalize(value: string): string {
  return value.trim().toLowerCase();
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
  const apply = process.argv.includes("--apply");

  if (!apiKey || !teamId || !todoStateId) {
    throw new Error("Missing LINEAR_API_KEY, LINEAR_TEAM_ID, or LINEAR_STATE_TODO_ID.");
  }

  const extraStates = parseCsvEnv("LINEAR_PM_LABEL_BACKFILL_STATE_IDS");
  const stateIds = [todoStateId, backlogStateId, inProgressStateId, ...extraStates].filter(
    (x): x is string => typeof x === "string" && x.length > 0
  );

  const client = new LinearClient({ apiKey });
  const team = await client.team(teamId);
  const labelsConnection = await team.labels({ first: 250 });
  const labelsByName = new Map(
    labelsConnection.nodes.map((label) => [normalize(label.name), label])
  );

  // Ensure role labels exist.
  for (const labelName of Object.values(ROLE_LABEL)) {
    if (labelsByName.has(normalize(labelName))) {
      continue;
    }
    console.log(`[missing-label] ${labelName}`);
    if (apply) {
      await client.createIssueLabel({ teamId, name: labelName });
      console.log(`  [created-label] ${labelName}`);
    }
  }

  // Refresh labels if we created any.
  const refreshedLabels = apply ? await team.labels({ first: 250 }) : labelsConnection;
  const refreshedByName = new Map(
    refreshedLabels.nodes.map((label) => [normalize(label.name), label.id])
  );

  const allIssues: IssueNode[] = [];
  for (const stateId of stateIds) {
    const nodes = await fetchIssuesInState(client, teamId, stateId);
    allIssues.push(...nodes);
  }

  const dedup = new Map<string, IssueNode>();
  for (const issue of allIssues) {
    dedup.set(issue.id, issue);
  }
  const issues = [...dedup.values()];

  let updates = 0;
  console.log(`Label backfill scan: ${issues.length} issue(s) across ${stateIds.length} state bucket(s).`);
  for (const issue of issues) {
    if (isOnboardingTitle(issue.title)) {
      continue;
    }
    const labelNames = (issue.labels?.nodes ?? []).map((l) => l.name);
    const role = inferRoleFromLabels(labelNames, issue.title);
    const targetLabelName = ROLE_LABEL[role];
    const targetLabelId = refreshedByName.get(normalize(targetLabelName));
    const hasAnyLabel = (issue.labels?.nodes?.length ?? 0) > 0;

    console.log(
      `- ${issue.identifier} ${issue.title} => ${role} / ${targetLabelName}${hasAnyLabel ? " (already labeled)" : ""}`
    );

    // Keep this conservative: only backfill issues that currently have zero labels.
    if (hasAnyLabel || !targetLabelId) {
      continue;
    }
    if (!apply) {
      continue;
    }
    const entity = await client.issue(issue.id);
    await entity.update({ labelIds: [targetLabelId] });
    updates += 1;
  }

  if (apply) {
    console.log(`Applied role label backfill to ${updates} unlabeled issue(s).`);
  } else {
    console.log("Dry run complete. Re-run with --apply to create labels and backfill unlabeled issues.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

