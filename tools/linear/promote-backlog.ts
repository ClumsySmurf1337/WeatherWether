import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";
import { countTeamActiveIssues } from "./linear-queries.js";

loadLinearEnv();

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
  const backlogStateId = process.env.LINEAR_STATE_BACKLOG_ID;
  const todoStateId = process.env.LINEAR_STATE_TODO_ID;
  const apply = process.argv.includes("--apply");

  if (!apiKey || !teamId || !backlogStateId || !todoStateId) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_STATE_BACKLOG_ID, or LINEAR_STATE_TODO_ID."
    );
  }

  const cap = parseIntEnv("LINEAR_ACTIVE_ISSUE_CAP", 230);
  const promoteMax = parseIntEnv("LINEAR_PROMOTE_BATCH_MAX", 25);

  const client = new LinearClient({ apiKey });
  const team = await client.team(teamId);
  const active = await countTeamActiveIssues(client, teamId);
  let slots = Math.max(0, cap - active);
  console.log(`Active issues ~${active} / cap ${cap}; promotion slots: ${slots}`);

  if (slots <= 0) {
    console.log("No slots to promote; reduce active issues or raise LINEAR_ACTIVE_ISSUE_CAP.");
    return;
  }

  const take = Math.min(slots, promoteMax);
  const conn = await team.issues({
    first: take,
    filter: { state: { id: { eq: backlogStateId } } }
  });

  const nodes = conn.nodes;
  if (nodes.length === 0) {
    console.log("No issues in Backlog to promote.");
    return;
  }

  console.log(`Promote candidates: ${nodes.length}`);
  for (const issue of nodes) {
    console.log(`- ${issue.identifier} ${issue.title}`);
    if (!apply) {
      continue;
    }
    const entity = await client.issue(issue.id);
    await entity.update({ stateId: todoStateId });
  }

  if (!apply) {
    console.log("Dry run. Re-run with --apply to move Backlog → Todo.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
