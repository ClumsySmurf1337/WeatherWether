import { mkdir, unlink, writeFile } from "node:fs/promises";
import { dirname } from "node:path";

import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";
import { isOnboardingTitle } from "./linear-queries.js";
import { withLinearRetry } from "./retry-linear.js";
import { AgentRole, assigneeEnvVarForRole, inferRoleFromLabels } from "./role-map.js";

loadLinearEnv();

type IssueNode = {
  id: string;
  identifier: string;
  title: string;
  priority: number;
  labels?: { nodes: Array<{ name: string }> };
  assignee?: { id: string } | null;
};

function getArg(name: string): string | undefined {
  const arg = process.argv.find((item) => item.startsWith(`--${name}=`));
  if (!arg) {
    return undefined;
  }
  return arg.slice(name.length + 3);
}

async function syncWorktreeMarker(path: string | undefined, identifier: string | null, apply: boolean): Promise<void> {
  if (!path?.trim() || !apply) {
    return;
  }
  const target = path.trim();
  if (identifier) {
    await mkdir(dirname(target), { recursive: true });
    await writeFile(target, `${identifier}\n`, "utf8");
    console.log(`  [marker] wrote ${identifier} -> ${target}`);
    return;
  }
  try {
    await unlink(target);
    console.log(`  [marker] cleared ${target}`);
  } catch {
    // absent file is fine
  }
}

function sortByPriorityThenId(a: IssueNode, b: IssueNode): number {
  if (a.priority !== b.priority) {
    return a.priority - b.priority;
  }
  return a.identifier.localeCompare(b.identifier);
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
  const inProgressStateId = process.env.LINEAR_STATE_IN_PROGRESS_ID;
  const role = (getArg("role") ?? "gameplay-programmer") as AgentRole;
  const apply = process.argv.includes("--apply");
  const worktreeMarker = getArg("worktree-marker");

  if (!apiKey || !teamId || !todoStateId || !inProgressStateId) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_STATE_TODO_ID, or LINEAR_STATE_IN_PROGRESS_ID."
    );
  }

  const client = new LinearClient({ apiKey });
  const fallbackViewerEnabled =
    (process.env.LINEAR_FALLBACK_ASSIGNEE_TO_VIEWER ?? "true").toLowerCase() !== "false";
  let viewerId: string | undefined;
  if (fallbackViewerEnabled) {
    try {
      const viewer = await client.viewer;
      viewerId = viewer?.id;
    } catch {
      viewerId = undefined;
    }
  }

  const preferredAssigneeId =
    process.env[assigneeEnvVarForRole(role)] ??
    process.env.LINEAR_DEFAULT_ASSIGNEE_ID ??
    viewerId;

  const [inProgress, todo] = await Promise.all([
    fetchIssuesInState(client, teamId, inProgressStateId),
    fetchIssuesInState(client, teamId, todoStateId)
  ]);

  const roleMatch = (issue: IssueNode): boolean => {
    if (isOnboardingTitle(issue.title)) {
      return false;
    }
    const labels = (issue.labels?.nodes ?? []).map((node) => node.name);
    return inferRoleFromLabels(labels, issue.title) === role;
  };

  const inProgressRole = inProgress.filter(roleMatch).sort(sortByPriorityThenId);
  const resumeCandidate =
    inProgressRole.find((i) => preferredAssigneeId && i.assignee?.id === preferredAssigneeId) ??
    inProgressRole.find((i) => !i.assignee?.id) ??
    inProgressRole[0];

  if (resumeCandidate) {
    console.log(`Resume ${resumeCandidate.identifier} ${resumeCandidate.title} for role=${role}`);
    if (!apply) {
      console.log("Dry run complete. Re-run with --apply to keep ownership and continue.");
      return;
    }
    if (!resumeCandidate.assignee?.id && preferredAssigneeId) {
      const entity = await client.issue(resumeCandidate.id);
      await withLinearRetry(
        () =>
          entity.update({
            assigneeId: preferredAssigneeId
          }),
        `issue.update.resumeAssign:${resumeCandidate.identifier}`
      );
      console.log("  [updated] set assignee for resumed issue");
    }
    await syncWorktreeMarker(worktreeMarker, resumeCandidate.identifier, apply);
    console.log("  [resume] continue this In Progress issue.");
    return;
  }

  const todoCandidate = todo.filter(roleMatch).sort(sortByPriorityThenId)[0];
  if (!todoCandidate) {
    console.log(`No In Progress or Todo issue available for role=${role}`);
    await syncWorktreeMarker(worktreeMarker, null, apply);
    return;
  }

  console.log(`Claim ${todoCandidate.identifier} ${todoCandidate.title} for role=${role}`);
  if (!apply) {
    console.log("Dry run complete. Re-run with --apply to claim issue.");
    return;
  }

  const issueEntity = await client.issue(todoCandidate.id);
  const updateInput: { stateId: string; assigneeId?: string } = {
    stateId: inProgressStateId
  };
  if (preferredAssigneeId) {
    updateInput.assigneeId = preferredAssigneeId;
  }
  await withLinearRetry(
    () => issueEntity.update(updateInput),
    `issue.update.claim:${todoCandidate.identifier}`
  );
  await syncWorktreeMarker(worktreeMarker, todoCandidate.identifier, apply);
  console.log("  [updated] moved Todo -> In Progress");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

