import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";
import { isOnboardingTitle } from "./linear-queries.js";
import { loadPmPhasePlan, resolvePhaseForIssue } from "./pm-phase-types.js";
import { withLinearRetry } from "./retry-linear.js";
import {
  assigneeEnvVarForRole,
  inferRoleFromLabels
} from "./role-map.js";

loadLinearEnv();

type IssueNode = {
  id: string;
  identifier: string;
  title: string;
  priority: number;
  labels?: { nodes: Array<{ name: string }> };
  assignee?: { id: string } | null;
};

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

function parseBoolEnv(name: string, defaultVal: boolean): boolean {
  const v = process.env[name]?.trim().toLowerCase();
  if (v === "0" || v === "false" || v === "no") {
    return false;
  }
  if (v === "1" || v === "true" || v === "yes") {
    return true;
  }
  return defaultVal;
}

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const todoStateId = process.env.LINEAR_STATE_TODO_ID;
  const backlogStateId = process.env.LINEAR_STATE_BACKLOG_ID;
  const apply = process.argv.includes("--apply");
  const assignOnly = process.argv.includes("--assign-only");
  const priorityOnly = process.argv.includes("--priority-only");
  const skipBacklog = process.argv.includes("--todo-only");

  if (!apiKey || !teamId || !todoStateId) {
    throw new Error("Missing LINEAR_API_KEY, LINEAR_TEAM_ID, or LINEAR_STATE_TODO_ID.");
  }

  const autoAssign = parseBoolEnv("LINEAR_PM_AUTO_ASSIGN", true);
  const fallbackViewerEnabled = parseBoolEnv("LINEAR_FALLBACK_ASSIGNEE_TO_VIEWER", true);
  const plan = loadPmPhasePlan();

  const client = new LinearClient({ apiKey });
  let viewerId: string | undefined;
  if (fallbackViewerEnabled) {
    try {
      const viewer = await client.viewer;
      viewerId = viewer?.id;
    } catch {
      viewerId = undefined;
    }
  }
  const buckets: IssueNode[] = [];
  buckets.push(...(await fetchIssuesInState(client, teamId, todoStateId)));
  if (!skipBacklog && backlogStateId) {
    buckets.push(...(await fetchIssuesInState(client, teamId, backlogStateId)));
  }

  const unique = new Map<string, IssueNode>();
  for (const issue of buckets) {
    unique.set(issue.id, issue);
  }
  const issues = [...unique.values()];

  console.log(`PM organize: ${issues.length} issue(s) in Todo${skipBacklog ? "" : " + Backlog"}.`);
  console.log(`Plan: ${plan.phases.length} phases (docs/backlog/pm-phase-plan.json).`);
  console.log(`Auto-assign (no assignee): ${autoAssign} (LINEAR_PM_AUTO_ASSIGN).`);
  console.log(`Mode: ${apply ? "APPLY" : "dry-run"}${assignOnly ? " (assign-only)" : ""}${priorityOnly ? " (priority-only)" : ""}\n`);

  let priorityUpdates = 0;
  let assignUpdates = 0;

  const sortedForLog = [...issues].sort((a, b) => {
    const la = (a.labels?.nodes ?? []).map((x) => x.name);
    const lb = (b.labels?.nodes ?? []).map((x) => x.name);
    const pa = resolvePhaseForIssue(plan, la, a.title);
    const pb = resolvePhaseForIssue(plan, lb, b.title);
    if (pa.order !== pb.order) {
      return pa.order - pb.order;
    }
    return a.priority - b.priority;
  });

  for (const issue of sortedForLog) {
    if (isOnboardingTitle(issue.title)) {
      console.log(`- skip onboarding: ${issue.identifier} ${issue.title}`);
      continue;
    }

    const labelNames = (issue.labels?.nodes ?? []).map((l) => l.name);
    const role = inferRoleFromLabels(labelNames, issue.title);
    const phase = resolvePhaseForIssue(plan, labelNames, issue.title);
    const assigneeEnv = assigneeEnvVarForRole(role);
    const assigneeSource = process.env[assigneeEnv]
      ? assigneeEnv
      : process.env.LINEAR_DEFAULT_ASSIGNEE_ID
        ? "LINEAR_DEFAULT_ASSIGNEE_ID"
        : viewerId
          ? "viewer"
          : "";
    const targetAssignee =
      process.env[assigneeEnv] ??
      process.env.LINEAR_DEFAULT_ASSIGNEE_ID ??
      viewerId;

    const parts = [
      `${issue.identifier}`,
      `phase=${phase.phaseId}(#${phase.order})`,
      `prio→${phase.linearPriority}`,
      `role=${role}`
    ];
    if (targetAssignee) {
      parts.push(`assignee=${assigneeSource}`);
    } else {
      parts.push("assignee=(none configured)");
    }
    console.log(`- ${issue.title.slice(0, 72)}${issue.title.length > 72 ? "…" : ""}`);
    console.log(`    ${parts.join(" · ")}`);

    if (!apply) {
      continue;
    }

    const entity = await client.issue(issue.id);
    const patch: { priority?: number; assigneeId?: string } = {};

    const doPriority = !assignOnly || priorityOnly;
    const doAssign = assignOnly || !priorityOnly;

    if (doPriority && issue.priority !== phase.linearPriority) {
      patch.priority = phase.linearPriority;
    }
    if (doAssign && autoAssign && targetAssignee && !issue.assignee?.id) {
      patch.assigneeId = targetAssignee;
    }

    if (Object.keys(patch).length > 0) {
      await withLinearRetry(
        () => entity.update(patch),
        `issue.update.organize:${issue.identifier}`
      );
      if (patch.priority !== undefined) {
        priorityUpdates += 1;
      }
      if (patch.assigneeId !== undefined) {
        assignUpdates += 1;
      }
    }
  }

  if (apply) {
    console.log(`\nUpdated priorities: ${priorityUpdates}, assignees: ${assignUpdates}.`);
  } else {
    console.log(`\nDry run. Re-run with --apply to write Linear.`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
