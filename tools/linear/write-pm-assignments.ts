import { mkdirSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";
import { isOnboardingTitle } from "./linear-queries.js";
import { loadPmPhasePlan, resolvePhaseForIssue } from "./pm-phase-types.js";
import { type AgentRole, assigneeEnvVarForRole, inferRoleFromLabels } from "./role-map.js";

loadLinearEnv();

type IssueNode = {
  id: string;
  identifier: string;
  title: string;
  priority: number;
  description?: string | null;
  url?: string;
  labels?: { nodes: Array<{ name: string }> };
  assignee?: { id: string; name?: string } | null;
  state?: { name: string } | null;
};

type TaggedIssue = { issue: IssueNode; bucket: string };

const ROLES_FOR_FILES: AgentRole[] = [
  "gameplay-programmer",
  "ui-developer",
  "level-designer",
  "qa-agent",
  "art-pipeline",
  "producer"
];

function roleToFilename(role: AgentRole): string {
  return role.replace(/-/g, "_");
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

function bucketRank(bucket: string): number {
  if (bucket === "In Progress") {
    return 0;
  }
  if (bucket === "Todo") {
    return 1;
  }
  if (bucket === "Backlog") {
    return 2;
  }
  return 3;
}

function buildHandoffMarkdown(
  tagged: TaggedIssue,
  role: AgentRole,
  phaseId: string,
  phaseOrder: number
): string {
  const issue = tagged.issue;
  const desc = (issue.description ?? "").trim();
  const url = issue.url ?? `(open ${issue.identifier} in Linear)`;
  const assignee = issue.assignee?.name ?? "(unassigned)";
  const st = issue.state?.name ?? tagged.bucket;

  return `## ${issue.identifier} — ${issue.title}

- **Linear:** ${url}
- **Queue:** ${tagged.bucket} · **State:** ${st} · **Assignee:** ${assignee}
- **Role:** ${role} · **PM phase:** ${phaseId} (order ${phaseOrder})
- **Linear priority:** ${issue.priority}

### Description / acceptance

${desc || "_(no description — add acceptance criteria in Linear)_"}

### When done

- Commit with \`${issue.identifier}\` in message; PR title/body includes team key + number.
- Run \`pwsh ./tools/tasks/validate.ps1\` when touching gameplay/tests/levels.

---

`;
}

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const todoStateId = process.env.LINEAR_STATE_TODO_ID;
  const inProgressStateId = process.env.LINEAR_STATE_IN_PROGRESS_ID;
  const backlogStateId = process.env.LINEAR_STATE_BACKLOG_ID;
  const teamKey = (process.env.LINEAR_TEAM_KEY ?? "WEA").trim();

  if (!apiKey || !teamId || !todoStateId || !inProgressStateId) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_STATE_TODO_ID, or LINEAR_STATE_IN_PROGRESS_ID."
    );
  }

  const client = new LinearClient({ apiKey });
  const plan = loadPmPhasePlan();
  const todo = await fetchIssuesInState(client, teamId, todoStateId);
  const doing = await fetchIssuesInState(client, teamId, inProgressStateId);
  const backlog = backlogStateId
    ? await fetchIssuesInState(client, teamId, backlogStateId)
    : [];

  const tagged: TaggedIssue[] = [];
  for (const issue of doing) {
    tagged.push({ issue, bucket: "In Progress" });
  }
  for (const issue of todo) {
    tagged.push({ issue, bucket: "Todo" });
  }
  for (const issue of backlog) {
    tagged.push({ issue, bucket: "Backlog" });
  }

  const byRole = new Map<AgentRole, TaggedIssue[]>();
  for (const r of ROLES_FOR_FILES) {
    byRole.set(r, []);
  }

  for (const item of tagged) {
    if (isOnboardingTitle(item.issue.title)) {
      continue;
    }
    const labels = (item.issue.labels?.nodes ?? []).map((l) => l.name);
    const role = inferRoleFromLabels(labels, item.issue.title);
    const list = byRole.get(role);
    if (list) {
      list.push(item);
    }
  }

  const outDir = resolve(process.cwd(), "assignments/generated");
  mkdirSync(outDir, { recursive: true });

  for (const role of ROLES_FOR_FILES) {
    const list = byRole.get(role) ?? [];
    list.sort((a, b) => {
      const la = (a.issue.labels?.nodes ?? []).map((x) => x.name);
      const lb = (b.issue.labels?.nodes ?? []).map((x) => x.name);
      const pa = resolvePhaseForIssue(plan, la, a.issue.title);
      const pb = resolvePhaseForIssue(plan, lb, b.issue.title);
      if (pa.order !== pb.order) {
        return pa.order - pb.order;
      }
      if (a.issue.priority !== b.issue.priority) {
        return a.issue.priority - b.issue.priority;
      }
      return bucketRank(a.bucket) - bucketRank(b.bucket);
    });

    const fn = resolve(outDir, `${roleToFilename(role)}.md`);
    const envHint = assigneeEnvVarForRole(role);
    let body = `# PM assignment file — ${role}\n\n`;
    body += `Generated by \`npm run linear:pm-assignments\`. Team **${teamKey}**. `;
    body += `Ordered by **pm-phase-plan** (foundation → content). `;
    body += `Set **${envHint}** (or LINEAR_DEFAULT_ASSIGNEE_ID) for auto-assign: \`npm run linear:pm-organize -- --apply\`.\n\n`;
    body += `---\n\n`;

    if (list.length === 0) {
      body += `_No issues in Backlog/Todo/In Progress for this role (after onboarding filter)._\n`;
    } else {
      for (const item of list) {
        const labels = (item.issue.labels?.nodes ?? []).map((l) => l.name);
        const ph = resolvePhaseForIssue(plan, labels, item.issue.title);
        body += buildHandoffMarkdown(item, role, ph.phaseId, ph.order);
      }
    }

    writeFileSync(fn, body, "utf-8");
    console.log(`Wrote ${fn} (${list.length} issue(s))`);
  }

  console.log(`\nDeedWise-style handoff: open assignments/generated/<role>.md per agent.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
