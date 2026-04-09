import type { LinearClient } from "@linear/sdk";
import type { Team } from "@linear/sdk";

const PAGE = 250;

function normalizeTitle(title: string): string {
  return title.trim().toLowerCase();
}

export async function fetchAllTeamIssueTitles(client: LinearClient, team: Team): Promise<Set<string>> {
  const titles = new Set<string>();
  let after: string | undefined;
  do {
    const conn = await team.issues({ first: PAGE, after });
    for (const node of conn.nodes) {
      titles.add(normalizeTitle(node.title));
    }
    after = conn.pageInfo.hasNextPage ? conn.pageInfo.endCursor : undefined;
  } while (after);
  return titles;
}

export async function countTeamActiveIssues(client: LinearClient, teamId: string): Promise<number> {
  let total = 0;
  let after: string | undefined;
  const filter = {
    team: { id: { eq: teamId } },
    state: { type: { nin: ["completed", "canceled"] } }
  };
  do {
    const conn = await client.issues({ first: PAGE, after, filter });
    total += conn.nodes.length;
    after = conn.pageInfo.hasNextPage ? conn.pageInfo.endCursor : undefined;
  } while (after);
  return total;
}

export async function buildTeamLabelNameToId(team: Team): Promise<Map<string, string>> {
  const map = new Map<string, string>();
  let after: string | undefined;
  do {
    const conn = await team.labels({ first: PAGE, after });
    for (const label of conn.nodes) {
      map.set(label.name.trim().toLowerCase(), label.id);
    }
    after = conn.pageInfo.hasNextPage ? conn.pageInfo.endCursor : undefined;
  } while (after);
  return map;
}

export async function buildTeamProjectNameToId(team: Team): Promise<Map<string, string>> {
  const map = new Map<string, string>();
  let after: string | undefined;
  do {
    const conn = await team.projects({ first: PAGE, after });
    for (const project of conn.nodes) {
      map.set(project.name.trim().toLowerCase(), project.id);
    }
    after = conn.pageInfo.hasNextPage ? conn.pageInfo.endCursor : undefined;
  } while (after);
  return map;
}

export function resolveLabelIds(labelNames: string[], labelMap: Map<string, string>): string[] {
  const ids: string[] = [];
  for (const name of labelNames) {
    const id = labelMap.get(name.trim().toLowerCase());
    if (id) {
      ids.push(id);
    }
  }
  return ids;
}

export function isOnboardingTitle(title: string): boolean {
  const t = title.trim().toLowerCase();
  return (
    t.includes("get familiar with linear") ||
    t.includes("set up your teams") ||
    t.includes("connect your tools") ||
    t.includes("import your data")
  );
}
