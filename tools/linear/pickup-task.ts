import { LinearClient } from "@linear/sdk";
import { AgentRole, assigneeEnvVarForRole, inferRoleFromLabels } from "./role-map.js";
import { loadLinearEnv } from "./load-env.js";
import { isOnboardingTitle } from "./linear-queries.js";

loadLinearEnv();

function getArg(name: string): string | undefined {
  const arg = process.argv.find((item) => item.startsWith(`--${name}=`));
  if (!arg) {
    return undefined;
  }
  return arg.slice(name.length + 3);
}

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const todoStateId = process.env.LINEAR_STATE_TODO_ID;
  const inProgressStateId = process.env.LINEAR_STATE_IN_PROGRESS_ID;
  const role = (getArg("role") ?? "gameplay-programmer") as AgentRole;
  const apply = process.argv.includes("--apply");

  if (!apiKey || !teamId || !todoStateId || !inProgressStateId) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_STATE_TODO_ID, or LINEAR_STATE_IN_PROGRESS_ID."
    );
  }

  const client = new LinearClient({ apiKey });
  const team = await client.team(teamId);
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
  const todoConnection = await team.issues({
    first: 30,
    filter: { state: { id: { eq: todoStateId } } }
  });

  const issue = (todoConnection.nodes ?? []).find((item) => {
    if (isOnboardingTitle(item.title)) {
      return false;
    }
    const labels = (item.labels?.nodes ?? []).map((node) => node.name);
    return inferRoleFromLabels(labels, item.title) === role;
  });

  if (!issue) {
    console.log(`No Todo issue available for role=${role}`);
    return;
  }

  const assigneeId =
    process.env[assigneeEnvVarForRole(role)] ??
    process.env.LINEAR_DEFAULT_ASSIGNEE_ID ??
    viewerId;
  console.log(`Selected ${issue.identifier} ${issue.title} for ${role}`);

  if (!apply) {
    console.log("Dry run complete. Re-run with --apply to claim issue.");
    return;
  }

  const issueEntity = await client.issue(issue.id);
  const updateInput: { stateId: string; assigneeId?: string } = {
    stateId: inProgressStateId
  };
  if (assigneeId) {
    updateInput.assigneeId = assigneeId;
  }
  await issueEntity.update(updateInput);
  console.log("Issue moved to In Progress.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
