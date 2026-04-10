import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";

loadLinearEnv();

function fmtDate(input: Date): string {
  return input.toISOString().slice(0, 10);
}

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;

  if (!apiKey || !teamId) {
    throw new Error("Missing LINEAR_API_KEY or LINEAR_TEAM_ID in environment.");
  }

  const client = new LinearClient({ apiKey });
  const team = await client.team(teamId);

  const [inProgress, backlog, done] = await Promise.all([
    team.issues({
      filter: { state: { name: { eq: "In Progress" } } },
      first: 10
    }),
    team.issues({
      filter: { state: { name: { eq: "Todo" } } },
      first: 10
    }),
    team.issues({
      filter: { state: { type: { eq: "completed" } } },
      first: 5
    })
  ]);

  const today = fmtDate(new Date());
  console.log(`# Weather Whether Daily Standup (${today})`);
  console.log("");
  console.log("## Done Recently");
  done.nodes.forEach((issue) => console.log(`- ${issue.identifier} ${issue.title}`));
  console.log("");
  console.log("## In Progress");
  inProgress.nodes.forEach((issue) =>
    console.log(`- ${issue.identifier} ${issue.title}`)
  );
  console.log("");
  console.log("## Next Up (Todo)");
  backlog.nodes.forEach((issue) =>
    console.log(`- ${issue.identifier} ${issue.title}`)
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
