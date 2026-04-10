import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";
import { isOnboardingTitle } from "./linear-queries.js";
import { loadPmPhasePlan, resolvePhaseForIssue } from "./pm-phase-types.js";
import {
  type AgentRole,
  assigneeEnvVarForRole,
  inferRoleFromLabels
} from "./role-map.js";
import { withLinearRetry } from "./retry-linear.js";

loadLinearEnv();

type IssueNode = {
  id: string;
  identifier: string;
  title: string;
  priority: number;
  labels?: { nodes: Array<{ name: string }> };
};

const DEFAULT_ROLES: AgentRole[] = [
  "gameplay-programmer",
  "ui-developer",
  "level-designer"
];

function getArg(name: string): string | undefined {
  const arg = process.argv.find((item) => item.startsWith(`--${name}=`));
  if (!arg) {
    return undefined;
  }
  return arg.slice(name.length + 3);
}

function parseRolesArg(): AgentRole[] {
  const raw = getArg("roles");
  if (!raw) {
    return DEFAULT_ROLES;
  }
  const parsed = raw
    .split(",")
    .map((r) => r.trim() as AgentRole)
    .filter(Boolean);
  return parsed.length ? parsed : DEFAULT_ROLES;
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

function pickForRole(
  nodes: IssueNode[],
  role: AgentRole,
  usedIds: Set<string>
): IssueNode | undefined {
  const plan = loadPmPhasePlan();
  const filtered = nodes.filter((issue) => {
    if (usedIds.has(issue.id)) {
      return false;
    }
    if (isOnboardingTitle(issue.title)) {
      return false;
    }
    const labels = (issue.labels?.nodes ?? []).map((l) => l.name);
    return inferRoleFromLabels(labels, issue.title) === role;
  });
  filtered.sort((a, b) => {
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
  return filtered[0];
}

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const todoStateId = process.env.LINEAR_STATE_TODO_ID;
  const backlogStateId = process.env.LINEAR_STATE_BACKLOG_ID;
  const inProgressStateId = process.env.LINEAR_STATE_IN_PROGRESS_ID;
  const apply = process.argv.includes("--apply");
  const roles = parseRolesArg();

  if (!apiKey || !teamId || !todoStateId || !backlogStateId || !inProgressStateId) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_STATE_TODO_ID, LINEAR_STATE_BACKLOG_ID, or LINEAR_STATE_IN_PROGRESS_ID."
    );
  }

  const client = new LinearClient({ apiKey });
  const viewerId = (await client.viewer)?.id;
  const [todo, backlog] = await Promise.all([
    fetchIssuesInState(client, teamId, todoStateId),
    fetchIssuesInState(client, teamId, backlogStateId)
  ]);

  const usedIds = new Set<string>();
  console.log(`Kickoff lanes for roles: ${roles.join(", ")}.`);
  for (const role of roles) {
    const assigneeId =
      process.env[assigneeEnvVarForRole(role)] ??
      process.env.LINEAR_DEFAULT_ASSIGNEE_ID ??
      viewerId;
    const fromTodo = pickForRole(todo, role, usedIds);
    const fromBacklog = fromTodo ? undefined : pickForRole(backlog, role, usedIds);
    const selected = fromTodo ?? fromBacklog;
    if (!selected) {
      console.log(`- ${role}: no Todo/Backlog issue available`);
      continue;
    }

    usedIds.add(selected.id);
    const source = fromTodo ? "Todo" : "Backlog";
    console.log(`- ${role}: ${selected.identifier} ${selected.title} (from ${source})`);
    if (!apply) {
      continue;
    }

    const entity = await client.issue(selected.id);
    if (!fromTodo) {
      await withLinearRetry(
        () => entity.update({ stateId: todoStateId }),
        `issue.update.toTodo:${selected.identifier}`
      );
      console.log("    [updated] Backlog -> Todo");
    }
    await withLinearRetry(
      () =>
        entity.update({
          stateId: inProgressStateId,
          assigneeId
        }),
      `issue.update.toInProgress:${selected.identifier}`
    );
    console.log(`    [updated] -> In Progress${assigneeId ? " (assigned)" : ""}`);
  }

  if (!apply) {
    console.log("Dry run complete. Re-run with --apply to kick off lanes.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

