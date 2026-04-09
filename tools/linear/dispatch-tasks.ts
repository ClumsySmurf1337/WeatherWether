import "dotenv/config";
import { LinearClient } from "@linear/sdk";
import { assigneeEnvVarForRole, inferRoleFromLabels } from "./role-map.js";

type LinearIssueNode = {
  id: string;
  identifier: string;
  title: string;
  priority: number;
  labels?: { nodes: Array<{ name: string }> };
  assignee?: { id: string } | null;
};

function getArgValue(flag: string, fallback: string): string {
  const full = process.argv.find((arg) => arg.startsWith(`${flag}=`));
  if (!full) {
    return fallback;
  }
  return full.slice(flag.length + 1);
}

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const todoStateId = process.env.LINEAR_STATE_TODO_ID;
  const inProgressStateId = process.env.LINEAR_STATE_IN_PROGRESS_ID;
  const apply = process.argv.includes("--apply");
  const limit = Number.parseInt(getArgValue("--limit", "8"), 10);

  if (!apiKey || !teamId || !todoStateId || !inProgressStateId) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_STATE_TODO_ID, or LINEAR_STATE_IN_PROGRESS_ID."
    );
  }

  const client = new LinearClient({ apiKey });
  const team = await client.team(teamId);
  const todoConnection = await team.issues({
    first: limit,
    filter: { state: { id: { eq: todoStateId } } }
  });

  const issues = (todoConnection.nodes ?? []) as LinearIssueNode[];
  if (issues.length === 0) {
    console.log("No Todo issues found.");
    return;
  }

  console.log(`Dispatch candidates: ${issues.length}`);
  for (const issue of issues) {
    const labelNames = (issue.labels?.nodes ?? []).map((label) => label.name);
    const role = inferRoleFromLabels(labelNames);
    const assigneeId = process.env[assigneeEnvVarForRole(role)];
    console.log(
      `- ${issue.identifier} ${issue.title} => ${role}${assigneeId ? " (assignee configured)" : ""}`
    );

    if (!apply) {
      continue;
    }

    const issueEntity = await client.issue(issue.id);
    const updateInput: { stateId: string; assigneeId?: string } = {
      stateId: inProgressStateId
    };
    if (assigneeId) {
      updateInput.assigneeId = assigneeId;
    }
    await issueEntity.update(updateInput);
    console.log(`  [updated] moved to In Progress`);
  }

  if (!apply) {
    console.log("Dry run complete. Re-run with --apply to write changes.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
