export type AgentRole =
  | "producer"
  | "gameplay-programmer"
  | "ui-developer"
  | "level-designer"
  | "qa-agent"
  | "art-pipeline";

/** Roles `linear:dispatch` may move Todo → In Progress (excludes producer/QA by default). */
export const DEFAULT_DISPATCH_ROLES: readonly AgentRole[] = [
  "gameplay-programmer",
  "ui-developer",
  "level-designer",
  "art-pipeline"
] as const;

const ALL_ROLES: readonly AgentRole[] = [
  "producer",
  "gameplay-programmer",
  "ui-developer",
  "level-designer",
  "qa-agent",
  "art-pipeline"
] as const;

/** Comma-separated override: `LINEAR_DISPATCH_ROLES=gameplay-programmer,ui-developer` */
export function parseDispatchRoleFilter(): Set<AgentRole> {
  const raw = process.env.LINEAR_DISPATCH_ROLES?.trim();
  if (!raw) {
    return new Set(DEFAULT_DISPATCH_ROLES);
  }
  const set = new Set<AgentRole>();
  for (const part of raw.split(",")) {
    const p = part.trim() as AgentRole;
    if ((ALL_ROLES as readonly string[]).includes(p)) {
      set.add(p);
    } else {
      console.warn(`Unknown role in LINEAR_DISPATCH_ROLES (ignored): ${part.trim()}`);
    }
  }
  if (set.size === 0) {
    return new Set(DEFAULT_DISPATCH_ROLES);
  }
  return set;
}

export function inferRoleFromLabels(labels: string[], title?: string): AgentRole {
  const t = (title ?? "").trim().toLowerCase();
  if (t.startsWith("[level-design]")) {
    return "level-designer";
  }
  if (t.startsWith("[level-implement]")) {
    return "gameplay-programmer";
  }
  if (t.startsWith("[level-playtest]") || t.startsWith("[level-validate]")) {
    return "qa-agent";
  }
  if (t.startsWith("[core]") || t.startsWith("[mech]")) {
    return "gameplay-programmer";
  }
  if (t.startsWith("[ui]")) {
    return "ui-developer";
  }
  if (t.startsWith("[qa]")) {
    return "qa-agent";
  }
  if (t.startsWith("[art-audio]") || t.startsWith("[art]")) {
    return "art-pipeline";
  }
  if (t.startsWith("[release]")) {
    return "producer";
  }

  const normalized = labels.map((label) => label.toLowerCase());

  if (normalized.some((label) => label.includes("core-engine"))) {
    return "gameplay-programmer";
  }
  if (normalized.some((label) => label.includes("ui-ux"))) {
    return "ui-developer";
  }
  if (normalized.some((label) => label.includes("level-design"))) {
    return "level-designer";
  }
  if (normalized.some((label) => label.includes("qa-testing"))) {
    return "qa-agent";
  }
  if (
    normalized.some(
      (label) =>
        label.includes("art-visual") || label.includes("audio music") || label.includes("audio-music")
    )
  ) {
    return "art-pipeline";
  }
  if (
    t.includes("ui") ||
    t.includes("hud") ||
    t.includes("menu") ||
    t.includes("layout") ||
    t.includes("ux")
  ) {
    return "ui-developer";
  }
  if (
    t.includes("level") ||
    t.includes("ldtk") ||
    t.includes("world") ||
    t.includes("puzzle layout")
  ) {
    return "level-designer";
  }
  if (
    t.includes("qa") ||
    t.includes("test") ||
    t.includes("validate") ||
    t.includes("regression")
  ) {
    return "qa-agent";
  }
  if (
    t.includes("art") ||
    t.includes("sprite") ||
    t.includes("vfx") ||
    t.includes("sfx") ||
    t.includes("audio") ||
    t.includes("music")
  ) {
    return "art-pipeline";
  }
  if (
    t.includes("grid") ||
    t.includes("weather") ||
    t.includes("card") ||
    t.includes("system") ||
    t.includes("solver") ||
    t.includes("save") ||
    t.includes("input")
  ) {
    return "gameplay-programmer";
  }
  return "producer";
}

export function assigneeEnvVarForRole(role: AgentRole): string {
  switch (role) {
    case "producer":
      return "LINEAR_ASSIGNEE_PRODUCER_ID";
    case "gameplay-programmer":
      return "LINEAR_ASSIGNEE_GAMEPLAY_ID";
    case "ui-developer":
      return "LINEAR_ASSIGNEE_UI_ID";
    case "level-designer":
      return "LINEAR_ASSIGNEE_LEVEL_ID";
    case "qa-agent":
      return "LINEAR_ASSIGNEE_QA_ID";
    case "art-pipeline":
      return "LINEAR_ASSIGNEE_ART_ID";
  }
}
