import { LinearClient } from "@linear/sdk";
import { assigneeEnvVarForRole, inferRoleFromLabels, parseDispatchRoleFilter } from "./role-map.js";
import { loadLinearEnv } from "./load-env.js";
import { countIssuesInState, isOnboardingTitle } from "./linear-queries.js";
import { withLinearRetry } from "./retry-linear.js";

loadLinearEnv();

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

function parseIntEnv(name: string, fallback: number): number {
  const raw = process.env[name];
  if (raw == null || raw === "") {
    return fallback;
  }
  const n = Number.parseInt(raw, 10);
  return Number.isFinite(n) ? n : fallback;
}

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const todoStateId = process.env.LINEAR_STATE_TODO_ID;
  const inProgressStateId = process.env.LINEAR_STATE_IN_PROGRESS_ID;
  const apply = process.argv.includes("--apply");
  const perRunMax = Number.parseInt(getArgValue("--limit", "8"), 10);
  const maxInProgress = parseIntEnv("LINEAR_MAX_IN_PROGRESS", 3);
  const todoFetchFirst = Number.parseInt(getArgValue("--todo-fetch", "80"), 10);

  if (!apiKey || !teamId || !todoStateId || !inProgressStateId) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_STATE_TODO_ID, or LINEAR_STATE_IN_PROGRESS_ID."
    );
  }

  const client = new LinearClient({ apiKey });
  const team = await client.team(teamId);
  const allowedRoles = parseDispatchRoleFilter();
  const fallbackViewerEnabled =
    (process.env.LINEAR_FALLBACK_ASSIGNEE_TO_VIEWER ?? "true").toLowerCase() !== "false";
  let cachedViewerId: string | undefined;
  async function resolveViewerId(): Promise<string | undefined> {
    if (!fallbackViewerEnabled) {
      return undefined;
    }
    if (cachedViewerId) {
      return cachedViewerId;
    }
    try {
      const viewer = await client.viewer;
      cachedViewerId = viewer?.id;
      return cachedViewerId;
    } catch {
      return undefined;
    }
  }

  const inProgressCount = await countIssuesInState(client, teamId, inProgressStateId);
  let wipSlots = Math.max(0, maxInProgress - inProgressCount);
  console.log(
    `In Progress ${inProgressCount} / max ${maxInProgress} (LINEAR_MAX_IN_PROGRESS); dispatch slots this cycle: ${wipSlots}`
  );
  console.log(`Dispatch role filter: ${[...allowedRoles].join(", ")} (LINEAR_DISPATCH_ROLES)`);

  const todoConnection = await team.issues({
    first: Math.min(250, Math.max(20, todoFetchFirst)),
    filter: { state: { id: { eq: todoStateId } } }
  });

  const issues = (todoConnection.nodes ?? []) as LinearIssueNode[];
  if (issues.length === 0) {
    console.log("No Todo issues found.");
    return;
  }

  console.log(`Todo scan: ${issues.length} issue(s) (fetch first ${todoFetchFirst})`);
  let dispatched = 0;

  for (const issue of issues) {
    if (wipSlots <= 0 || dispatched >= perRunMax) {
      break;
    }
    if (isOnboardingTitle(issue.title)) {
      console.log(`- skip onboarding: ${issue.identifier} ${issue.title}`);
      continue;
    }
    const labelNames = (issue.labels?.nodes ?? []).map((label) => label.name);
    const role = inferRoleFromLabels(labelNames, issue.title);
    if (!allowedRoles.has(role)) {
      console.log(`- skip role (not in dispatch filter): ${issue.identifier} => ${role}`);
      continue;
    }
    const assigneeEnv = assigneeEnvVarForRole(role);
    const assigneeSource = process.env[assigneeEnv]
      ? assigneeEnv
      : process.env.LINEAR_DEFAULT_ASSIGNEE_ID
        ? "LINEAR_DEFAULT_ASSIGNEE_ID"
        : fallbackViewerEnabled
          ? "viewer"
          : "";
    const assigneeId =
      process.env[assigneeEnv] ??
      process.env.LINEAR_DEFAULT_ASSIGNEE_ID ??
      (await resolveViewerId());
    console.log(
      `- ${issue.identifier} ${issue.title} => ${role}${assigneeId ? ` (${assigneeSource})` : " (no assignee id)"}`
    );

    if (!apply) {
      dispatched += 1;
      wipSlots -= 1;
      continue;
    }

    const issueEntity = await client.issue(issue.id);
    const updateInput: { stateId: string; assigneeId?: string } = {
      stateId: inProgressStateId
    };
    if (assigneeId) {
      updateInput.assigneeId = assigneeId;
    }
    await withLinearRetry(
      () => issueEntity.update(updateInput),
      `issue.update.dispatch:${issue.identifier}`
    );
    console.log(`  [updated] moved to In Progress`);
    dispatched += 1;
    wipSlots -= 1;
  }

  if (!apply) {
    console.log("Dry run complete. Re-run with --apply to write changes.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
