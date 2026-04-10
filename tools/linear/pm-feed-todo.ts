import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";
import { isOnboardingTitle } from "./linear-queries.js";
import { loadPmPhasePlan, resolvePhaseForIssue } from "./pm-phase-types.js";
import { withLinearRetry } from "./retry-linear.js";

loadLinearEnv();

type IssueNode = {
  id: string;
  identifier: string;
  title: string;
  priority: number;
  labels?: { nodes: Array<{ name: string }> };
};

function parseIntEnv(name: string, fallback: number): number {
  const raw = process.env[name];
  if (!raw) {
    return fallback;
  }
  const n = Number.parseInt(raw, 10);
  return Number.isFinite(n) ? n : fallback;
}

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
  const apply = process.argv.includes("--apply");
  const targetTodo =
    Number.parseInt(getArg("target") ?? "", 10) ||
    parseIntEnv("LINEAR_PM_TODO_TARGET", 8);

  if (!apiKey || !teamId || !todoStateId || !backlogStateId) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_STATE_TODO_ID, or LINEAR_STATE_BACKLOG_ID."
    );
  }

  const client = new LinearClient({ apiKey });
  const plan = loadPmPhasePlan();
  const [todo, backlog] = await Promise.all([
    fetchIssuesInState(client, teamId, todoStateId),
    fetchIssuesInState(client, teamId, backlogStateId)
  ]);

  const todoActive = todo.filter((i) => !isOnboardingTitle(i.title));
  const currentTodo = todoActive.length;
  let need = Math.max(0, targetTodo - currentTodo);

  console.log(
    `PM feed Todo: current Todo=${currentTodo}, target=${targetTodo}, to-move=${need}.`
  );
  if (need <= 0) {
    console.log("Todo already meets/exceeds target; nothing to move.");
    return;
  }

  const candidates = backlog
    .filter((i) => !isOnboardingTitle(i.title))
    .sort((a, b) => {
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

  if (candidates.length === 0) {
    console.log("No Backlog candidates to move.");
    return;
  }

  let moved = 0;
  for (const issue of candidates) {
    if (need <= 0) {
      break;
    }
    const labels = (issue.labels?.nodes ?? []).map((x) => x.name);
    const phase = resolvePhaseForIssue(plan, labels, issue.title);
    console.log(
      `- ${issue.identifier} ${issue.title} (phase=${phase.phaseId}#${phase.order}, prio=${issue.priority})`
    );
    if (apply) {
      const entity = await client.issue(issue.id);
      await withLinearRetry(
        () => entity.update({ stateId: todoStateId }),
        `issue.update.toTodo:${issue.identifier}`
      );
      moved += 1;
    }
    need -= 1;
  }

  if (!apply) {
    console.log("Dry run complete. Re-run with --apply to move selected Backlog -> Todo.");
  } else {
    console.log(`Moved ${moved} issue(s) Backlog -> Todo.`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

