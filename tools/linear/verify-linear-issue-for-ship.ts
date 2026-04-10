import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";

loadLinearEnv();

function resolveIssueToken(): string {
  const positional = process.argv[2]?.trim();
  if (positional && /^[A-Za-z]+-\d+$/.test(positional)) {
    return positional.toUpperCase();
  }
  const fromEnv = process.env.LINEAR_SHIP_ISSUE_ID?.trim();
  if (fromEnv && /^[A-Za-z]+-\d+$/.test(fromEnv)) {
    return fromEnv.toUpperCase();
  }
  throw new Error(
    "Missing issue id: pass WEA-123 as first arg or set LINEAR_SHIP_ISSUE_ID."
  );
}

function parseIssueNumber(token: string, teamKey: string): number {
  const k = teamKey.toUpperCase();
  const m = token.toUpperCase().match(new RegExp(`^${k}-(\\d+)$`));
  if (!m) {
    throw new Error(`Issue ${token} must match LINEAR_TEAM_KEY (${k}-###).`);
  }
  return Number.parseInt(m[1], 10);
}

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const doneStateId = process.env.LINEAR_STATE_DONE_ID;
  const teamKey = (process.env.LINEAR_TEAM_KEY ?? "WEA").trim().toUpperCase();
  const token = resolveIssueToken();

  if (!apiKey || !teamId) {
    throw new Error(
      "Missing LINEAR_API_KEY or LINEAR_TEAM_ID (.env / .env.linear.generated / .env.local)."
    );
  }

  const num = parseIssueNumber(token, teamKey);
  const client = new LinearClient({ apiKey });

  const conn = await client.issues({
    first: 2,
    filter: {
      team: { id: { eq: teamId } },
      number: { eq: num }
    }
  });
  const node = conn.nodes[0];
  if (!node) {
    throw new Error(
      `Linear issue not found for ${token} on configured team — fix id or LINEAR_TEAM_ID.`
    );
  }
  if (node.identifier.toUpperCase() !== token) {
    throw new Error(
      `Expected ${token} but Linear returned ${node.identifier} for number ${num}.`
    );
  }

  const entity = await client.issue(node.id);
  const state = await entity.state;
  if (!state) {
    throw new Error(`${node.identifier} has no workflow state.`);
  }

  if (doneStateId && state.id === doneStateId) {
    throw new Error(
      `${node.identifier} is already Done — update .weather-lane-issue.txt / resume-pickup before opening another PR.`
    );
  }

  const wtype = (state as unknown as { type?: string }).type;
  if (wtype === "completed" || wtype === "canceled") {
    throw new Error(
      `${node.identifier} is ${wtype} in Linear — cannot ship against this issue.`
    );
  }

  console.log(`OK: ${node.identifier} — ${node.title} (state: ${state.name})`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
