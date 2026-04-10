import { LinearClient } from "@linear/sdk";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import { BacklogIssue, generateOutlineBacklog } from "./backlog-outline-generator.js";
import { loadLinearEnv } from "./load-env.js";
import {
  buildTeamLabelNameToId,
  buildTeamProjectNameToId,
  countTeamActiveIssues,
  fetchAllTeamIssueTitles,
  resolveLabelIds
} from "./linear-queries.js";

loadLinearEnv();

function loadIssues(relativePath: string): BacklogIssue[] {
  const fullPath = resolve(process.cwd(), relativePath);
  const raw = readFileSync(fullPath, "utf-8");
  return JSON.parse(raw) as BacklogIssue[];
}

function acceptanceToMarkdown(items: string[]): string {
  return items.map((item) => `- [ ] ${item}`).join("\n");
}

function parseIntEnv(name: string, fallback: number): number {
  const raw = process.env[name];
  if (raw == null || raw === "") {
    return fallback;
  }
  const n = Number.parseInt(raw, 10);
  return Number.isFinite(n) ? n : fallback;
}

function inferProjectId(
  title: string,
  projectMap: Map<string, string>
): string | undefined {
  const t = title.toLowerCase();
  const pick = (key: string): string | undefined => projectMap.get(key);

  if (t.includes("world 1") || t.includes("w1-") || t.includes("downpour")) {
    return pick("world 1: downpour");
  }
  if (t.includes("world 2") || t.includes("w2-") || t.includes("heatwave")) {
    return pick("world 2: heatwave");
  }
  if (t.includes("world 3") || t.includes("w3-") || t.includes("coldsnap")) {
    return pick("world 3: cold snap");
  }
  if (t.includes("world 4") || t.includes("w4-") || t.includes("galeforce")) {
    return pick("world 4: gale force");
  }
  if (t.includes("world 5") || t.includes("w5-") || t.includes("thunderstorm")) {
    return pick("world 5: thunderstorm");
  }
  if (t.includes("world 6") || t.includes("w6-") || t.includes("whiteout")) {
    return pick("world 6: whiteout");
  }
  if (t.startsWith("[ui]")) {
    return pick("ui/ux");
  }
  if (t.startsWith("[qa]")) {
    return pick("qa & validation");
  }
  if (t.startsWith("[release]")) {
    return pick("release ops");
  }
  if (t.startsWith("[art-audio]")) {
    if (t.includes("music") || t.includes("audio") || t.includes("sfx")) {
      return pick("audio & music");
    }
    return pick("art & visual");
  }
  if (t.startsWith("[core]") || t.startsWith("[mech]")) {
    return pick("core engine & framework") ?? pick("puzzle mechanics");
  }
  if (t.startsWith("[level")) {
    return pick("puzzle mechanics");
  }
  return undefined;
}

async function main(): Promise<void> {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const backlogStateId = process.env.LINEAR_STATE_BACKLOG_ID;
  const dryRun = process.argv.includes("--dry-run");

  if (!dryRun && (!apiKey || !teamId)) {
    throw new Error("Missing LINEAR_API_KEY or LINEAR_TEAM_ID. Use .env.local or run bootstrap.");
  }

  const client = dryRun ? null : new LinearClient({ apiKey: apiKey as string });
  const files = [
    "docs/backlog/system-rework.json"
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

  if (dryRun) {
    for (const issue of issues) {
      console.log(`[dry-run] ${issue.title}`);
    }
    return;
  }

  const cap = parseIntEnv("LINEAR_ACTIVE_ISSUE_CAP", 230);
  const batchMax = parseIntEnv("LINEAR_SEED_BATCH_MAX", 40);
  const team = await client!.team(teamId as string);
  const existingTitles = await fetchAllTeamIssueTitles(client!, team);
  const activeCount = await countTeamActiveIssues(client!, teamId as string);
  const labelMap = await buildTeamLabelNameToId(team);
  const projectMap = await buildTeamProjectNameToId(team);

  let slots = Math.max(0, cap - activeCount);
  const toCreate = issues.filter((issue) => !existingTitles.has(issue.title.trim().toLowerCase()));

  console.log(`Active non-terminal issues (approx cap check): ${activeCount} / cap ${cap}`);
  console.log(`New titles not in Linear: ${toCreate.length}`);
  console.log(`Create budget this run: min(${batchMax}, ${slots})`);

  let created = 0;
  const initialState =
    backlogStateId && backlogStateId.length > 0 ? backlogStateId : process.env.LINEAR_STATE_TODO_ID;
  if (!initialState) {
    throw new Error("Set LINEAR_STATE_BACKLOG_ID or LINEAR_STATE_TODO_ID in .env.linear.generated");
  }
  if (!backlogStateId) {
    console.warn(
      "[warn] LINEAR_STATE_BACKLOG_ID missing — creating issues in Todo. Prefer Backlog for phased intake."
    );
  }

  for (const issue of toCreate) {
    if (created >= batchMax || slots <= 0) {
      break;
    }
    const description =
      "## Acceptance Criteria\n" + acceptanceToMarkdown(issue.acceptance);
    const labelIds = resolveLabelIds(issue.labels, labelMap);
    const projectId = inferProjectId(issue.title, projectMap);

    await client!.createIssue({
      teamId: teamId as string,
      title: issue.title,
      description,
      priority: issue.priority,
      labelIds: labelIds.length ? labelIds : undefined,
      projectId,
      stateId: initialState
    });
    console.log(`[created] ${issue.title}`);
    created += 1;
    slots -= 1;
  }

  if (toCreate.length > created) {
    console.log(
      `[phase] Stopped after ${created} creates. Re-run \`npm run linear:seed\` after closing issues or raising cap. ${toCreate.length - created} remaining in local template set.`
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
