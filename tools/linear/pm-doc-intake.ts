/**
 * PM doc intake: draft Linear-ready issues from GAME_DESIGN, UI_SCREENS, ASSET_MANIFEST, SPEC_DIFF.
 * Dry-run by default; `--apply` creates missing issues in Backlog (deduped by title).
 */
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";

import { LinearClient } from "@linear/sdk";

import { PM_DOC_ISSUE_CANDIDATES, type PmDocIssueCandidate } from "./pm-doc-issue-candidates.js";
import { loadLinearEnv } from "./load-env.js";
import {
  buildTeamLabelNameToId,
  buildTeamProjectNameToId,
  countTeamActiveIssues,
  fetchAllTeamIssueTitles,
  resolveLabelIds
} from "./linear-queries.js";

const EXCERPT_MAX = 7000;
const REPORT_REL = "assignments/generated/pm-doc-intake-dry-run.md";

function getArg(name: string): string | undefined {
  const arg = process.argv.find((item) => item.startsWith(`--${name}=`));
  if (!arg) {
    return undefined;
  }
  return arg.slice(name.length + 3);
}

function parseIntArg(name: string, fallback: number): number {
  const raw = getArg(name);
  if (raw == null || raw === "") {
    return fallback;
  }
  const n = Number.parseInt(raw, 10);
  return Number.isFinite(n) ? n : fallback;
}

function parseIntEnv(name: string, fallback: number): number {
  const raw = process.env[name];
  if (raw == null || raw === "") {
    return fallback;
  }
  const n = Number.parseInt(raw, 10);
  return Number.isFinite(n) ? n : fallback;
}

/** Extract first `##` section whose heading matches prefix (after `## `). */
export function extractSectionByHeading(content: string, sectionHeadingPrefix: string): string | null {
  const lines = content.split(/\r?\n/);
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    if (!line.startsWith("## ")) {
      continue;
    }
    const rest = line.slice(3).trim();
    if (rest === sectionHeadingPrefix || rest.startsWith(sectionHeadingPrefix)) {
      const chunk: string[] = [line];
      for (let j = i + 1; j < lines.length; j += 1) {
        if (lines[j].startsWith("## ") && lines[j].length > 3) {
          break;
        }
        chunk.push(lines[j]);
      }
      return chunk.join("\n").trim();
    }
  }
  return null;
}

function truncateExcerpt(text: string): string {
  if (text.length <= EXCERPT_MAX) {
    return text;
  }
  return `${text.slice(0, EXCERPT_MAX)}\n\n_(Excerpt truncated for size limit.)_`;
}

function acceptanceToMarkdown(items: string[]): string {
  return items.map((item) => `- [ ] ${item}`).join("\n");
}

function buildDescription(candidate: PmDocIssueCandidate, excerpt: string): string {
  const body = truncateExcerpt(excerpt);
  return [
    "## PM intake (repo docs)",
    "",
    "Drafted by `npm run linear:pm-doc-intake` from **authoritative specs**. **Producer / PM**: dedupe against existing backlog, split if too large, edit acceptance, then promote.",
    "",
    `**Candidate id:** \`${candidate.id}\``,
    "",
    `## Source excerpt (\`${candidate.docPath}\`)`,
    "",
    body,
    "",
    "## Deliverables",
    "",
    candidate.deliverables,
    "",
    "## Acceptance criteria",
    "",
    acceptanceToMarkdown(candidate.acceptance),
    ""
  ].join("\n");
}

function inferProjectId(title: string, projectMap: Map<string, string>): string | undefined {
  const t = title.toLowerCase();
  const pick = (key: string): string | undefined => projectMap.get(key);

  if (t.startsWith("[ui]")) {
    return pick("ui/ux");
  }
  if (t.startsWith("[art-audio]") || t.startsWith("[art]")) {
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
  return pick("core engine & framework") ?? pick("puzzle mechanics");
}

function loadDoc(repoRoot: string, relativePath: string): string {
  const full = resolve(repoRoot, relativePath);
  return readFileSync(full, "utf-8");
}

async function runApply(
  repoRoot: string,
  candidates: Array<{ candidate: PmDocIssueCandidate; description: string; excerptOk: boolean }>,
  maxCreates: number
): Promise<void> {
  loadLinearEnv();
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  const backlogStateId = process.env.LINEAR_STATE_BACKLOG_ID;
  if (!apiKey || !teamId) {
    throw new Error("Missing LINEAR_API_KEY or LINEAR_TEAM_ID for --apply.");
  }
  if (!backlogStateId) {
    throw new Error("Missing LINEAR_STATE_BACKLOG_ID for --apply (issues must land in Backlog).");
  }

  const client = new LinearClient({ apiKey });
  const team = await client.team(teamId);
  const existingTitles = await fetchAllTeamIssueTitles(client, team);
  const activeCount = await countTeamActiveIssues(client, teamId);
  const labelMap = await buildTeamLabelNameToId(team);
  const projectMap = await buildTeamProjectNameToId(team);
  const cap = parseIntEnv("LINEAR_ACTIVE_ISSUE_CAP", 230);
  let slots = Math.max(0, cap - activeCount);

  let created = 0;
  for (const { candidate, description } of candidates) {
    if (created >= maxCreates || slots <= 0) {
      break;
    }
    const key = candidate.title.trim().toLowerCase();
    if (existingTitles.has(key)) {
      console.log(`[skip exists] ${candidate.title}`);
      continue;
    }
    const labelIds = resolveLabelIds(candidate.labels, labelMap);
    const projectId = inferProjectId(candidate.title, projectMap);
    await client.createIssue({
      teamId,
      title: candidate.title,
      description,
      priority: candidate.priority,
      labelIds: labelIds.length ? labelIds : undefined,
      projectId,
      stateId: backlogStateId
    });
    existingTitles.add(key);
    console.log(`[created] ${candidate.title}`);
    created += 1;
    slots -= 1;
  }

  console.log(`\nApply complete: ${created} created (max ${maxCreates}, active cap headroom was considered).`);
}

async function main(): Promise<void> {
  const apply = process.argv.includes("--apply");
  const repoRoot = process.cwd();
  const maxCreates = parseIntArg("max", 12);

  const docCache = new Map<string, string>();
  const getDoc = (path: string): string => {
    if (!docCache.has(path)) {
      docCache.set(path, loadDoc(repoRoot, path));
    }
    return docCache.get(path) as string;
  };

  const resolved: Array<{
    candidate: PmDocIssueCandidate;
    description: string;
    excerptOk: boolean;
  }> = [];

  for (const candidate of PM_DOC_ISSUE_CANDIDATES) {
    const md = getDoc(candidate.docPath);
    const rawExcerpt = extractSectionByHeading(md, candidate.sectionHeadingPrefix);
    const excerptOk = rawExcerpt != null && rawExcerpt.length > 0;
    const excerpt =
      rawExcerpt ??
      `_Could not find section starting with \`## ${candidate.sectionHeadingPrefix}\` in \`${candidate.docPath}\`. Update **sectionHeadingPrefix** in \`pm-doc-issue-candidates.ts\` or fix the doc._`;
    const description = buildDescription(candidate, excerpt);
    resolved.push({ candidate, description, excerptOk });
  }

  const lines: string[] = [
    "# PM doc intake — dry run",
    "",
    `Generated: ${new Date().toISOString()}`,
    "",
    "> Reads **GAME_DESIGN.md**, **UI_SCREENS.md**, **ASSET_MANIFEST.md**, **SPEC_DIFF.md** and emits **detailed** issue bodies for the producer / PM agent.",
    "",
    "---",
    ""
  ];

  console.log("=== PM doc intake ===\n");
  if (apply) {
    console.log("Mode: --apply (Linear API)\n");
  } else {
    console.log("Mode: dry-run (no Linear writes). Pass --apply to create issues in Backlog.\n");
  }

  for (const { candidate, description, excerptOk } of resolved) {
    const status = excerptOk ? "ok" : "MISSING SECTION";
    console.log(`• [${status}] ${candidate.title}`);
    console.log(`  id=${candidate.id}  labels=${candidate.labels.join(", ")}  priority=${candidate.priority}`);
    lines.push(`## ${candidate.title}`, "");
    lines.push(`- **id:** \`${candidate.id}\``);
    lines.push(`- **labels:** ${candidate.labels.join(", ")}`);
    lines.push(`- **priority:** ${candidate.priority}`);
    lines.push(`- **section:** \`${candidate.docPath}\` → \`${candidate.sectionHeadingPrefix}\``);
    lines.push(`- **excerpt resolved:** ${excerptOk ? "yes" : "NO — fix heading"}`);
    lines.push("", description, "", "---", "");
  }

  const reportPath = resolve(repoRoot, REPORT_REL);
  mkdirSync(dirname(reportPath), { recursive: true });
  const reportBody = lines.join("\n");
  writeFileSync(reportPath, reportBody, "utf-8");
  const reportLines = reportBody.split(/\r?\n/).length;
  console.log(`\nWrote ${REPORT_REL} (${reportLines} lines).`);

  if (apply) {
    await runApply(repoRoot, resolved, maxCreates);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
