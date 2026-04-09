import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";

loadLinearEnv();

function arg(name: string): string | undefined {
  const full = process.argv.find((item) => item.startsWith(`--${name}=`));
  if (!full) {
    return undefined;
  }
  return full.slice(name.length + 3);
}

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const inProgressStateId = process.env.LINEAR_STATE_IN_PROGRESS_ID;
  const inReviewStateId = process.env.LINEAR_STATE_IN_REVIEW_ID;
  const issueIdentifier = arg("issue");
  const apply = process.argv.includes("--apply");

  if (!apiKey || !teamId || !inProgressStateId || !inReviewStateId) {
    throw new Error(
      "Missing LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_STATE_IN_PROGRESS_ID, or LINEAR_STATE_IN_REVIEW_ID."
    );
  }
  if (!issueIdentifier) {
    throw new Error("Provide --issue=ABC-123.");
  }

  const client = new LinearClient({ apiKey });
  const team = await client.team(teamId);
  const issueConnection = await team.issues({
    first: 1,
    filter: {
      identifier: { eq: issueIdentifier },
      state: { id: { eq: inProgressStateId } }
    }
  });

  const issue = issueConnection.nodes[0];
  if (!issue) {
    throw new Error(
      `Could not find in-progress issue ${issueIdentifier} for team ${teamId}.`
    );
  }

  console.log(`Close-loop target: ${issue.identifier} ${issue.title}`);
  if (!apply) {
    console.log("Dry run complete. Re-run with --apply to move to In Review.");
    return;
  }

  const issueEntity = await client.issue(issue.id);
  await issueEntity.update({ stateId: inReviewStateId });
  console.log("Issue moved to In Review.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
