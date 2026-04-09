import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";
import { countTeamActiveIssues, fetchAllTeamIssueTitles } from "./linear-queries.js";

loadLinearEnv();

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  if (!apiKey || !teamId) {
    throw new Error("Missing LINEAR_API_KEY or LINEAR_TEAM_ID");
  }
  const cap = Number.parseInt(process.env.LINEAR_ACTIVE_ISSUE_CAP ?? "230", 10);
  const client = new LinearClient({ apiKey });
  const team = await client.team(teamId);
  const [titles, active] = await Promise.all([
    fetchAllTeamIssueTitles(client, team),
    countTeamActiveIssues(client, teamId)
  ]);
  console.log(
    JSON.stringify(
      {
        teamKey: team.key,
        teamName: team.name,
        uniqueTitlesIndexed: titles.size,
        approxActiveNonTerminal: active,
        activeCap: cap,
        headroom: Math.max(0, cap - active)
      },
      null,
      2
    )
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
