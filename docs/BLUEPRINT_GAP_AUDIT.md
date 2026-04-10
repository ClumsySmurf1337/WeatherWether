# Blueprint Gap Audit

**Revalidated:** 2026-04-09 · **GitHub:** Weather Whether CI on **`ci.yml`** — `npm ci`, Godot **4.6.2** Linux headless (`/usr/local/bin/godot`), import, GUT, level validation (PR + `main`). **No** GitHub auto-merge or Linear Done in Actions (local **`qa:pr`** only).

Source blueprint:

- `docs/The Complete AI Multi-Agent Blueprint for Shipping Whether_ Parallel Agents, Orchestration, and Indie Game Development Toolkit.md`

Companion specs:

- **`docs/GAME_DESIGN.md` v2** (authoritative GDD)
- `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md` (legacy toolkit / study links)
- `docs/OPEN_SOURCE_AND_PIPELINE.md`

---

## Where we are (executive snapshot)

| Area | Status |
|------|--------|
| **Linear PM** | Bootstrap, seed (dedupe + caps), promote, dispatch (**WIP + role filter**), pickup, producer, standup, status, close-loop, **complete-from-pr** (local), **`linear:label-backfill`** (missing labels + unlabeled issue backfill), **`linear:pm-organize`** + **`linear:pm-assignments`** (phase plan + DeedWise-style handoffs) — **in repo**. |
| **Local validation** | `validate.ps1` — **`GODOT_PATH` / PATH / `D:\Godot` fallback**; import + GUT + `validate_all_levels.gd`. |
| **GitHub Actions** | **`ci.yml`** — mirrors core Godot checks; Node **22**, `engines >=22`. |
| **GUT** | **Installed** (bitwes/Gut in `addons/gut/`). |
| **Godot MCP** | **Primary: `godot-full`** (tugcantopaloglu; `setup-godot-mcp-full.ps1`). **Optional:** `godot` (Coding-Solo `npx`). |
| **Godot API docs** | **No docs MCP** — official [4.6 docs](https://docs.godotengine.org/en/4.6/) + `docs/GODOT_DOCS_ACCESS.md` + optional Cursor doc index. |
| **Parallel agents** | **`new-agent-worktree.ps1`**, **`sync-agent-worktrees.ps1`**, **`cursor-autonomous-session.ps1`**, **`run-cursor-chat.ps1`** (`cursor-agent`, fallback `cursor agent`), **`cursor-cli.ps1`**. |
| **QA / merge** | **`qa-pr-handoff-local.ps1`** (`npm run qa:pr`), **`qa-merge-conflicts.ps1`** (`npm run qa:repair-merge`) — **local**; merge + **Linear Done** via **`.env.local`**. |
| **Export / release EXE in CI** | **Not done** — `build.yml` scaffold only; no `export_presets.cfg`. |
| **LDtk → runtime** | **`levels/whether.ldtk` exists**; **no** `level_loader.gd` / **no** godot-ldtk-importer addon yet. |
| **Docker** | **Not used** for CI or local docs (GitHub-hosted Ubuntu runners only). |

---

## What we are **not** doing (intentional)

| Item | Reason |
|------|--------|
| **Remote `godot-docs` MCP** (`mcp-remote` → workers.dev) | **Removed** — unreliable; replaced by official doc URLs + `GODOT_DOCS_ACCESS.md`. |
| **Docker-based CI or local doc server** | Unnecessary; Actions use vanilla Ubuntu + downloaded Godot binary. |
| **Self-hosted Cursor Cloud** | Not a product option; **local parallel** = worktrees + Cursor CLI / IDE (`docs/CURSOR_PARALLEL_AGENTS.md`, `docs/CURSOR_CLI_AND_WORKTREES.md`). |
| **GitHub Actions auto-merge + Linear Done** | **By design** — merge and issue completion are **local** (`docs/GITHUB_AUTOMERGE.md`) so **`LINEAR_API_KEY`** stays off GitHub for that path. |
| **Gemini / image MCP in-repo** | Keys and UX stay outside git; prompts in `ASSET_PROMPTS_GEMINI.md` / Stitch workflow. |
| **godot-mcp-pro (paid)** | Optional later; not purchased or wired by default. |

---

## Cursor MCP (`.cursor/mcp.json`) — current

| Server | Status | Notes |
|--------|--------|-------|
| `linear` | **Active** | `npx -y mcp-remote` → Linear; auth in Cursor. |
| `godot-full` | **Primary (intended)** | [tugcantopaloglu/godot-mcp](https://github.com/tugcantopaloglu/godot-mcp); run `tools/install/setup-godot-mcp-full.ps1` (output **gitignored**). Disable in MCP UI if `build/index.js` missing. |
| `godot` | **Optional / fallback** | [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) — quick `npx` without local build. |
| `github` | **Active** | `npx -y @modelcontextprotocol/server-github`; needs `GITHUB_TOKEN` in env. |
| ~~`godot-docs`~~ | **Removed** | Use `docs/GODOT_DOCS_ACCESS.md` and browser / indexed docs. |

---

## npm / PowerShell entry points (inventory)

| Script | Purpose |
|--------|---------|
| `npm run daily:full` | Prerequisites, `npm ci`, Linear producer preview/apply, `validate.ps1` |
| `npm run cursor:session` / `cursor:session:apply` | Producer + validate + lanes; **`-SpawnAgentCli`** → `cursor-agent` per worktree (fallback `cursor agent`) |
| `npm run linear:*` | status, standup, promote, dispatch, pickup, producer, seed, bootstrap, close, complete-from-pr, **pm-organize**, **pm-assignments** |
| `npm run qa:pr` | Local merge handoff + Linear Done (`gh` + `.env.local`) |
| `npm run qa:repair-merge` | `git merge origin/main` + **`cursor-agent`** / **`cursor agent`** conflict repair prompt |
| `npm run cursor:resume:editor` / `cursor:go:editor` | PM/worktree prep + **integrated** lane terminals (Tasks); **`prepare-editor-lane-worktrees.ps1`** |
| `npm run lane:ship` / `qa:lane-prs` / `lane:next-cycle` | **`lane-ship.ps1`** (commit/push/PR from worktree), **`qa-lane-pr-batch.ps1`** (merge + Linear Done + sync), **`lane-worktrees-reset-for-next-cycle.ps1`** |
| `npm run worktrees:sync` | `git fetch` + merge `origin/main` into each `wt-*` |
| `pwsh ./tools/tasks/new-agent-worktree.ps1` | Add lane under `WHETHER_AGENT_ROOT` |

Env: **`LINEAR_MAX_IN_PROGRESS`**, **`LINEAR_DISPATCH_ROLES`**, **`CURSOR_CLI_BIN`** — see `docs/LINEAR_ENV_VARS.md`.

---

## Godot MCP options (reference only)

| Option | Link | In this repo |
|--------|------|----------------|
| tugcantopaloglu fork | [github.com/tugcantopaloglu/godot-mcp](https://github.com/tugcantopaloglu/godot-mcp) | **`godot-full`** — **primary** (local build). |
| Coding-Solo | [github.com/Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) | **`godot`** — optional lightweight `npx`. |
| youichi-uda pro | [github.com/youichi-uda/godot-mcp-pro](https://github.com/youichi-uda/godot-mcp-pro) | **Not installed** — evaluate only if `godot-full` is insufficient. |

Details: `docs/AGENT_CATALOG.md`.

---

## Testing and CI

| Check | Local | GitHub Actions |
|-------|--------|----------------|
| `npm ci` / Linear tooling sanity | Yes | **Yes** (Node 22) |
| Godot `--import` | `validate.ps1` | **Yes** |
| GUT `res://test` | `validate.ps1` | **Yes** |
| `validate_all_levels.gd` | `validate.ps1` | **Yes** |

**Follow-ups (quality):** GUT **orphan** warnings in tests; tighten `validate_all_levels.gd` once LDtk JSON + solver are wired.

---

## Parallel agents and orchestration

| Layer | Status |
|-------|--------|
| Role files + catalog | **Done** — `.claude/agents/*.md`, `docs/AGENT_CATALOG.md`. |
| Linear lanes | **Done** — pickup/dispatch (**WIP + role filter**)/producer/promote/seed. |
| Scope / parallel doc | `docs/CURSOR_PARALLEL_AGENTS.md`, **`docs/CURSOR_CLI_AND_WORKTREES.md`**. |
| **Local parallel worktrees** | **`tools/tasks/new-agent-worktree.ps1`** — `D:\Agents\WeatherWether\wt-*` (or `WHETHER_AGENT_ROOT`). |
| Cursor Cloud + API | Hosted by Cursor only; dashboard + API links in `CURSOR_PARALLEL_AGENTS.md`. |
| **PR merge + Linear Done** | **Local** — `npm run qa:pr` (not Actions). |

---

## UI/UX + Gemini

- **No** in-repo Gemini API keys.
- **Flows:** `ART_DIRECTION.md`, `ASSET_PROMPTS_GEMINI.md`, `STITCH_UX_WORKFLOW.md`, `mobile-preview.ps1`.

---

## Remaining gaps (prioritized)

1. **`export_presets.cfg`** + **`build.yml`** real export + artifact upload (Windows/Steam first).
2. **`scripts/level_loader.gd`** (or agreed name) + **godot-ldtk-importer** addon — see `OPEN_SOURCE_AND_PIPELINE.md`.
3. **Puzzle solver** hooked to real level data; **validate_all_levels** fails CI on bad levels.
4. **Branch protection** on `main` requiring **Weather Whether CI** + local **`qa:pr`** discipline.
5. **PR ↔ Linear** auto-comment / link (optional).
6. **Visual/screenshot QA** loop (optional).

---

## Recommended next expansion

1. Export preset + **`build.yml`** artifact job.
2. LDtk importer + level loader MVP.
3. Optional: GitHub Action **comment-only** linking PR ↔ Linear (no secrets for Done).
4. Per-role SLA / stalled issues in Linear tooling (optional).

---

## Historical note (fixes already applied)

Earlier iterations added: producer agent, Linear scripts (dispatch with WIP, pickup, producer, bootstrap, seed, promote, complete-from-pr), GUT, Godot-in-CI, `godot-full` optional path, removal of flaky docs MCP, Node 22 + `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24`, canonical rules, `OPEN_SOURCE_AND_PIPELINE.md`, `GODOT_DOCS_ACCESS.md`, **`cursor` CLI orchestration**, **`qa:pr` / `qa:repair-merge`**, `new-agent-worktree` **git show-ref** fix.

---

## Doc map

| Topic | Doc |
|-------|-----|
| Godot API/docs | `docs/GODOT_DOCS_ACCESS.md` |
| Open-source + LDtk gaps | `docs/OPEN_SOURCE_AND_PIPELINE.md` |
| Daily loop | `docs/DAILY.md` |
| PM + fallbacks | `docs/AUTONOMOUS_ORCHESTRATION.md` |
| Parallel / Cloud / CLI | `docs/CURSOR_PARALLEL_AGENTS.md`, `docs/CURSOR_CLI_AND_WORKTREES.md`, `CURSOR_CLOUD_AGENT_SETUP.md` |
| Linear | `LINEAR_SETUP.md`, `LINEAR_ENV_VARS.md`, **`PM_AGENT_LINEAR.md`** |
| PR merge (local) | `GITHUB_AUTOMERGE.md` |
| Roles / MCP | `AGENT_CATALOG.md`, `TOOL_AGENT_MATRIX.md` |
| Win setup / Node | `SETUP_WIN11.md` |
| Paths | `PATHS_AND_STORAGE_POLICY.md` |
| This audit | `BLUEPRINT_GAP_AUDIT.md` |
