import { readFileSync } from "node:fs";
import { resolve } from "node:path";

export type PhaseRow = {
  id: string;
  order: number;
  linearPriority: number;
  matchLabels: string[];
  matchTitlePrefixes: string[];
};

export type PmPhasePlanFile = {
  description?: string;
  defaultOrder: number;
  defaultLinearPriority: number;
  phases: PhaseRow[];
};

export function loadPmPhasePlan(cwd: string = process.cwd()): PmPhasePlanFile {
  const fullPath = resolve(cwd, "docs/backlog/pm-phase-plan.json");
  const raw = readFileSync(fullPath, "utf-8");
  return JSON.parse(raw) as PmPhasePlanFile;
}

/** Returns { order, linearPriority, phaseId } for an issue from labels + title. */
export function resolvePhaseForIssue(
  plan: PmPhasePlanFile,
  labelNames: string[],
  title: string
): { order: number; linearPriority: number; phaseId: string } {
  const t = title.trim().toLowerCase();
  const labels = labelNames.map((l) => l.trim().toLowerCase());

  let bestOrder = plan.defaultOrder;
  let bestPriority = plan.defaultLinearPriority;
  let bestId = "default";

  for (const phase of plan.phases) {
    let hit = false;
    for (const needle of phase.matchLabels) {
      if (labels.some((l) => l.includes(needle.toLowerCase()))) {
        hit = true;
        break;
      }
    }
    if (!hit) {
      for (const pref of phase.matchTitlePrefixes) {
        const p = pref.toLowerCase();
        if (t.startsWith(p) || t.includes(p)) {
          hit = true;
          break;
        }
      }
    }
    if (hit && phase.order < bestOrder) {
      bestOrder = phase.order;
      bestPriority = phase.linearPriority;
      bestId = phase.id;
    }
  }

  return { order: bestOrder, linearPriority: bestPriority, phaseId: bestId };
}
