export type AgentRole =
  | "producer"
  | "gameplay-programmer"
  | "ui-developer"
  | "level-designer"
  | "qa-agent"
  | "art-pipeline";

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
