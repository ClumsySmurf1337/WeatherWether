import { LinearClient } from "@linear/sdk";

import { loadLinearEnv } from "./load-env.js";

loadLinearEnv();

/**
 * Wipe tool: marks all non-terminal issues in the Linear team as Cancelled.
 *
 * Usage:
 *   npm run linear:wipe -- --dry-run            # preview only, no changes
 *   npm run linear:wipe -- --confirm            # actually cancel them
 *
 * Safety:
 *   - Refuses to run without --confirm or --dry-run flag
 *   - Skips issues already in Done or Cancelled state
 *   - Skips archived issues
 *   - Logs every action
 *
 * After running --confirm, follow with:
 *   npm run linear:seed
 *   npm run linear:pm-prepare
 *   npm run linear:apply-deps -- --apply
 *   npm run linear:pm-feed-todo -- --apply --target=8
 */

type WipeFlags = {
  dryRun: boolean;
  confirm: boolean;
};

function parseFlags(): WipeFlags {
  const argv = process.argv.slice(2);
  return {
    dryRun: argv.includes("--dry-run"),
    confirm: argv.includes("--confirm"),
  };
}

async function main(): Promise<void> {
  const flags = parseFlags();

  if (!flags.dryRun && !flags.confirm) {
    console.error(
      "[wipe-team] Refusing to run without --dry-run or --confirm.\n" +
        "  Preview: npm run linear:wipe -- --dry-run\n" +
        "  Apply:   npm run linear:wipe -- --confirm"
    );
    process.exit(1);
  }

  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const cancelStateId = process.env.LINEAR_STATE_CANCELED_ID;

  if (!apiKey || !teamId) {
    throw new Error(
      "Missing LINEAR_API_KEY or LINEAR_TEAM_ID. Run linear:bootstrap first."
    );
  }

  const client = new LinearClient({ apiKey });
  const team = await client.team(teamId);
  console.log(`[wipe-team] Target team: ${team.name} (${teamId})`);
  console.log(`[wipe-team] Mode: ${flags.dryRun ? "DRY RUN" : "APPLY"}`);

  // Resolve a Cancelled state ID. Prefer env var, fall back to lookup.
  let canceledStateId = cancelStateId ?? "";
  if (!canceledStateId) {
    const states = await team.states();
    const canceled = states.nodes.find(
      (s) => s.type === "canceled" && s.name.toLowerCase() === "canceled"
    );
    if (!canceled) {
      throw new Error(
        "No 'Canceled' workflow state found in this team. Set LINEAR_STATE_CANCELED_ID in .env.linear.generated."
      );
    }
    canceledStateId = canceled.id;
  }
  console.log(`[wipe-team] Cancel state ID: ${canceledStateId}`);

  // Page through all team issues
  let cursor: string | undefined = undefined;
  let scanned = 0;
  let cancelled = 0;
  let skipped = 0;
  let failed = 0;

  while (true) {
    const page = await team.issues({ first: 100, after: cursor });
    for (const issue of page.nodes) {
      scanned++;
      const state = await issue.state;
      const stateName = state?.name ?? "(unknown)";
      const stateType = state?.type ?? "(unknown)";

      if (issue.archivedAt) {
        skipped++;
        continue;
      }
      if (stateType === "completed" || stateType === "canceled") {
        skipped++;
        continue;
      }

      console.log(
        `[wipe-team] ${flags.dryRun ? "[dry]" : "[apply]"} ${issue.identifier} ` +
          `(${stateName}) ${issue.title.slice(0, 60)}`
      );

      if (!flags.dryRun) {
        try {
          await client.updateIssue(issue.id, { stateId: canceledStateId });
          cancelled++;
        } catch (err) {
          failed++;
          console.error(
            `[wipe-team] FAILED to cancel ${issue.identifier}: ${
              (err as Error).message
            }`
          );
        }
      } else {
        cancelled++;
      }
    }

    if (!page.pageInfo.hasNextPage) break;
    cursor = page.pageInfo.endCursor ?? undefined;
  }

  console.log("[wipe-team] Done.");
  console.log(`[wipe-team] Scanned:    ${scanned}`);
  console.log(`[wipe-team] Cancelled:  ${cancelled}${flags.dryRun ? " (dry run)" : ""}`);
  console.log(`[wipe-team] Skipped:    ${skipped} (already done/cancelled/archived)`);
  if (failed > 0) {
    console.log(`[wipe-team] Failed:     ${failed}`);
  }

  if (flags.dryRun) {
    console.log("\n[wipe-team] This was a dry run. Re-run with --confirm to apply.");
  } else {
    console.log("\n[wipe-team] Next steps:");
    console.log("  npm run linear:seed");
    console.log("  npm run linear:pm-prepare");
    console.log("  npm run linear:apply-deps -- --apply");
    console.log("  npm run linear:pm-feed-todo -- --apply --target=8");
  }
}

main().catch((error) => {
  console.error("[wipe-team] Fatal:", error);
  process.exit(1);
});