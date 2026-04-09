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
  state?: { id: string; name: string };
};

function getArg(name: string): string | undefined {
  const arg = process.argv.find((item) => item.startsWith(`--${name}=`));
  if (!arg) {
    return undefined;
  }
  return arg.slice(name.length + 3);
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
  const role = (getArg("role") ?? "gameplay-programmer") as AgentRole;
  const apply = process.argv.includes("--apply");

  if (!apiKey || !teamId || !todoStateId || !backlogStateId || !inProgressStateId) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_STATE_TODO_ID, LINEAR_STATE_BACKLOG_ID, or LINEAR_STATE_IN_PROGRESS_ID."
    );
  }

  const client = new LinearClient({ apiKey });
  const plan = loadPmPhasePlan();

  const assigneeId =
    process.env[assigneeEnvVarForRole(role)] ??
    process.env.LINEAR_DEFAULT_ASSIGNEE_ID ??
    (await client.viewer)?.id;

  const todo = await fetchIssuesInState(client, teamId, todoStateId);
  const backlog = await fetchIssuesInState(client, teamId, backlogStateId);

  function pickFrom(nodes: IssueNode[]): IssueNode | undefined {
    const filtered = nodes.filter((issue) => {
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

  const todoPick = pickFrom(todo);
  const backlogPick = pickFrom(backlog);
  const selected = todoPick ?? backlogPick;
  if (!selected) {
    console.log(`No issue found for role=${role} in Todo/Backlog.`);
    return;
  }

  const selectedState = todoPick ? "Todo" : "Backlog";
  console.log(
    `Selected ${selected.identifier} ${selected.title} from ${selectedState} for role=${role}.`
  );
  if (!assigneeId) {
    console.log("No assignee id found (role/default/viewer). It will still move to In Progress unassigned.");
  }

  if (!apply) {
    console.log("Dry run complete. Re-run with --apply to move and claim this issue.");
    return;
  }

  const entity = await client.issue(selected.id);
  if (selectedState === "Backlog") {
    await withLinearRetry(
      () => entity.update({ stateId: todoStateId }),
      `issue.update.toTodo:${selected.identifier}`
    );
    console.log("  [updated] Backlog -> Todo");
  }
  await withLinearRetry(
    () => entity.update({ stateId: inProgressStateId, assigneeId }),
    `issue.update.toInProgress:${selected.identifier}`
  );
  console.log(`  [updated] moved to In Progress${assigneeId ? " and assigned" : ""}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

