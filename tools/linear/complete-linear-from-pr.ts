import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";

loadLinearEnv();

function collectIssueTokens(text: string, teamKey: string): string[] {
  const k = teamKey.toUpperCase();
  const re = new RegExp(`\\b${k}-\\d+\\b`, "gi");
  const found = text.match(re) ?? [];
  return [...new Set(found.map((t) => t.toUpperCase()))];
}

function parseIssueNumber(token: string, teamKey: string): number | null {
  const k = teamKey.toUpperCase();
  const m = token.toUpperCase().match(new RegExp(`^${k}-(\\d+)$`));
  if (!m) {
    return null;
  }
  return Number.parseInt(m[1], 10);
}

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const doneStateId = process.env.LINEAR_STATE_DONE_ID;
  const teamKey = (process.env.LINEAR_TEAM_KEY ?? "WEA").trim();
  const title = process.env.PR_TITLE ?? "";
  const body = process.env.PR_BODY ?? "";

  if (!apiKey || !teamId || !doneStateId) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TEAM_ID, or LINEAR_STATE_DONE_ID (GitHub secrets and/or .env.linear.generated)."
    );
  }

  const text = `${title}\n${body}`;
  const tokens = collectIssueTokens(text, teamKey);
  if (tokens.length === 0) {
    console.log(`No ${teamKey.toUpperCase()}-### id in PR title/body; nothing to complete in Linear.`);
    return;
  }

  const client = new LinearClient({ apiKey });

  for (const token of tokens) {
    const num = parseIssueNumber(token, teamKey);
    if (num == null) {
      continue;
    }
    const conn = await client.issues({
      first: 2,
      filter: {
        team: { id: { eq: teamId } },
        number: { eq: num }
      }
    });
    const node = conn.nodes[0];
    if (!node) {
      console.warn(`Linear issue not found for ${token} on team ${teamId}.`);
      continue;
    }
    if (node.identifier.toUpperCase() !== token) {
      console.warn(`Skipping ${token}: found ${node.identifier} for number ${num}.`);
      continue;
    }
    const entity = await client.issue(node.id);
    const state = await entity.state;
    if (state?.id === doneStateId) {
      console.log(`${node.identifier} already in Done; skip.`);
      continue;
    }
    await entity.update({ stateId: doneStateId });
    console.log(`Moved ${node.identifier} to Done.`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
