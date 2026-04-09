import "dotenv/config";
import { LinearClient } from "@linear/sdk";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { BacklogIssue, generateOutlineBacklog } from "./backlog-outline-generator.js";

function loadIssues(relativePath: string): BacklogIssue[] {
  const fullPath = resolve(process.cwd(), relativePath);
  const raw = readFileSync(fullPath, "utf-8");
  return JSON.parse(raw) as BacklogIssue[];
}

function acceptanceToMarkdown(items: string[]): string {
  return items.map((item) => `- [ ] ${item}`).join("\n");
}

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const dryRun = process.argv.includes("--dry-run");

  if (!dryRun && (!apiKey || !teamId)) {
    throw new Error("Missing LINEAR_API_KEY or LINEAR_TEAM_ID in environment.");
  }
  const client = dryRun ? null : new LinearClient({ apiKey: apiKey as string });

  const files = [
    "docs/backlog/core-engine.json",
    "docs/backlog/puzzle-mechanics.json",
    "docs/backlog/world-batches.json",
    "docs/backlog/ux-and-animation.json",
    "docs/backlog/outline-master.json"
  ];

  const fileIssues = files.flatMap(loadIssues);
  const generatedIssues = generateOutlineBacklog();
  const dedupedMap = new Map<string, BacklogIssue>();
  for (const issue of [...fileIssues, ...generatedIssues]) {
    dedupedMap.set(issue.title, issue);
  }
  const issues = [...dedupedMap.values()];
  console.log(
    `Loaded ${issues.length} backlog templates (${fileIssues.length} file + ${generatedIssues.length} generated).`
  );

  for (const issue of issues) {
    const description =
      "## Acceptance Criteria\n" + acceptanceToMarkdown(issue.acceptance);

    if (dryRun) {
      console.log(`[dry-run] ${issue.title}`);
      continue;
    }

    await client!.createIssue({
      teamId: teamId as string,
      title: issue.title,
      description,
      priority: issue.priority
    });
    console.log(`[created] ${issue.title}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
