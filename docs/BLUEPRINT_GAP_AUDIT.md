# Blueprint Gap Audit

**Revalidated:** 2026-04-10 · **GitHub:** Whether CI **passing** on `main` / PRs (Node 22 + Godot 4.6.2 Linux: import, GUT, level validation).

Source blueprint:

- `docs/The Complete AI Multi-Agent Blueprint for Shipping Whether_ Parallel Agents, Orchestration, and Indie Game Development Toolkit.md`

Companion specs:

- `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md`
- `docs/OPEN_SOURCE_AND_PIPELINE.md`

---

## Where we are (executive snapshot)

| Area | Status |
|------|--------|
| **Linear PM** | Bootstrap, seed (dedupe + caps), promote, dispatch, pickup, producer cycle — **in repo**. |
| **Local validation** | `validate.ps1` — import + GUT + `validate_all_levels.gd`. |
| **GitHub Actions** | **`ci.yml` green** — mirrors core Godot checks; `npm ci` with Node **22**, `engines >=22`. |
| **GUT** | **Installed** (bitwes/Gut in `addons/gut/`). |
| **Godot MCP** | **Primary: `godot-full`** (tugcantopaloglu; `setup-godot-mcp-full.ps1`). **Optional:** `godot` (Coding-Solo `npx`) for lightweight use. |
| **Godot API docs** | **No docs MCP** — official [4.6 docs](https://docs.godotengine.org/en/4.6/) + `docs/GODOT_DOCS_ACCESS.md` + optional Cursor doc index. |
| **Export / release EXE in CI** | **Not done** — `build.yml` scaffold only; no `export_presets.cfg`. |
| **LDtk → runtime** | **`levels/whether.ldtk` exists**; **no** `level_loader.gd` / **no** godot-ldtk-importer addon yet. |
| **Docker** | **Not used** for CI or local docs (GitHub-hosted Ubuntu runners only). |

---

## What we are **not** doing (intentional)

| Item | Reason |
|------|--------|
| **Remote `godot-docs` MCP** (`mcp-remote` → workers.dev) | **Removed** — unreliable; replaced by official doc URLs + `GODOT_DOCS_ACCESS.md`. |
| **Docker-based CI or local doc server** | Unnecessary; Actions use vanilla Ubuntu + downloaded Godot binary. |
| **Self-hosted Cursor Cloud** | Not a product option; **local parallel** = `new-agent-worktree.ps1` + multiple Cursor windows (`docs/CURSOR_PARALLEL_AGENTS.md`). |
| **Merge every PR automatically** | Safety / game-asset risk; see `GITHUB_AUTOMERGE.md` (label + green CI when ready). |
| **Gemini / image MCP in-repo** | Keys and UX stay outside git; prompts in `ASSET_PROMPTS_GEMINI.md` / Stitch workflow. |
| **godot-mcp-pro (paid)** | Optional later; not purchased or wired by default. |

---

## Cursor MCP (`.cursor/mcp.json`) — current

| Server | Status | Notes |
|--------|--------|--------|
| `linear` | **Active** | `npx -y mcp-remote` → Linear; auth in Cursor. |
| `godot-full` | **Primary (intended)** | [tugcantopaloglu/godot-mcp](https://github.com/tugcantopaloglu/godot-mcp); run `tools/install/setup-godot-mcp-full.ps1` (output **gitignored**). Disable in MCP UI if `build/index.js` missing. |
| `godot` | **Optional / fallback** | [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) — quick `npx` without local build. |
| `github` | **Active** | `npx -y @modelcontextprotocol/server-github`; needs `GITHUB_TOKEN` in env. |
| ~~`godot-docs`~~ | **Removed** | Use `docs/GODOT_DOCS_ACCESS.md` and browser / indexed docs. |

---

## Godot MCP options (reference only)

| Option | Link | In this repo |
|--------|------|----------------|
| tugcantopaloglu fork | [github.com/tugcantopaloglu/godot-mcp](https://github.com/tugcantopaloglu/godot-mcp) | **`godot-full`** — **primary** (local build). |
| Coding-Solo | [github.com/Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) | **`godot`** — optional lightweight `npx`. |
| youichi-uda pro | [github.com/youichi-uda/godot-mcp-pro](https://github.com/youichi-uda/godot-mcp-pro) | **Not installed** — evaluate only if `godot-full` is insufficient. |

Details: `docs/AGENT_CATALOG.md`.

---

## Testing and CI (post–revalidation)

| Check | Local | GitHub Actions |
|-------|--------|----------------|
| `npm ci` / Linear tooling sanity | Yes | **Yes** (Node 22) |
| Godot `--import` | `validate.ps1` | **Yes** |
| GUT `res://test` | `validate.ps1` | **Yes** |
| `validate_all_levels.gd` | `validate.ps1` | **Yes** (placeholder still reports 0 failures if no level JSON yet) |

**Follow-ups (quality, not “CI red/green” yet):** GUT **orphan** warnings in tests; tighten `validate_all_levels.gd` once LDtk JSON + solver are wired.

---

## Parallel agents and orchestration

| Layer | Status |
|-------|--------|
| Role files + catalog | **Done** — `.claude/agents/*.md`, `docs/AGENT_CATALOG.md`. |
| Linear lanes | **Done** — pickup/dispatch/producer/promote/seed. |
| Scope / parallel doc | `docs/CURSOR_PARALLEL_AGENTS.md`. |
| **Local parallel worktrees** | **`tools/tasks/new-agent-worktree.ps1`** — creates `D:\Agents\WeatherWether\wt-*` (or `WHETHER_AGENT_ROOT`). |
| Cursor Cloud + API | Hosted by Cursor only; dashboard + API links in `CURSOR_PARALLEL_AGENTS.md`. |
| Merge queue / N-agent auto-merge | **Not automated** — human or label-gated PR flow. |

---

## UI/UX + Gemini

- **No** in-repo Gemini API keys.
- **Flows:** `ART_DIRECTION.md`, `ASSET_PROMPTS_GEMINI.md`, `STITCH_UX_WORKFLOW.md`, `mobile-preview.ps1`.

---

## Remaining gaps (prioritized)

1. **`export_presets.cfg`** + **`build.yml`** real export + artifact upload (Windows/Steam first).
2. **`scripts/level_loader.gd`** (or agreed name) + **godot-ldtk-importer** addon — see `OPEN_SOURCE_AND_PIPELINE.md`.
3. **Puzzle solver** hooked to real level data; **validate_all_levels** fails CI on bad levels.
4. **Branch protection** on `main` requiring **Whether CI** (+ optional automerge workflow).
5. **PR ↔ Linear** auto-comment / link (optional).
6. **Visual/screenshot QA** loop (optional; godogen-style).

---

## Recommended next expansion

1. Export preset + **`build.yml`** artifact job.
2. LDtk importer + level loader MVP.
3. PR-link automation in `linear:close` (optional).
4. Per-role SLA / stalled issues in Linear tooling (optional).

---

## Historical note (fixes already applied)

Earlier iterations added: producer agent, Linear scripts (dispatch, pickup, producer, bootstrap, seed, promote), GUT, Godot-in-CI, `godot-full` optional path, removal of flaky docs MCP, Node 22 + `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24`, canonical rules (`whether-development.mdc`, `godot-engine-docs.mdc`), `OPEN_SOURCE_AND_PIPELINE.md`, `GODOT_DOCS_ACCESS.md`, Stitch UX doc, Nodist/multi-Node notes in `SETUP_WIN11.md`.

---

## Doc map

| Topic | Doc |
|-------|-----|
| Godot API/docs | `docs/GODOT_DOCS_ACCESS.md` |
| Open-source + LDtk gaps | `docs/OPEN_SOURCE_AND_PIPELINE.md` |
| Daily loop | `docs/DAILY.md` |
| PM + fallbacks | `docs/AUTONOMOUS_ORCHESTRATION.md` |
| Parallel / Cloud agents | `docs/CURSOR_PARALLEL_AGENTS.md`, `CURSOR_CLOUD_AGENT_SETUP.md` |
| Linear | `LINEAR_SETUP.md`, `LINEAR_ENV_VARS.md` |
| PR merge | `GITHUB_AUTOMERGE.md` |
| Roles / MCP | `AGENT_CATALOG.md` |
| Win setup / Node | `SETUP_WIN11.md` |
| Paths | `PATHS_AND_STORAGE_POLICY.md` |
