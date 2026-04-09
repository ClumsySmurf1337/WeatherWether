# Blueprint Gap Audit

Source audited:

- `docs/The Complete AI Multi-Agent Blueprint for Shipping Whether_ Parallel Agents, Orchestration, and Indie Game Development Toolkit.md`

## Audit Summary

### Previously Missing

1. Producer/PM role file and explicit PM loop.
2. Automated dispatch/pickup scripts for Linear task flow.
3. Godot docs MCP server in Cursor MCP config.
4. Complete cross-tool agent catalog beyond initial four role files.

### Fixes Applied

1. Added producer and expanded role definitions:
   - `.claude/agents/producer.md`
   - `.claude/agents/ui-developer.md`
   - `.claude/agents/release-ops.md`
2. Added Linear orchestration scripts:
   - `tools/linear/dispatch-tasks.ts`
   - `tools/linear/pickup-task.ts`
   - `tools/linear/producer-cycle.ts`
   - `tools/linear/role-map.ts`
   - `tools/linear/bootstrap-workspace.ts`, `seed-backlog.ts`, `promote-backlog.ts`, etc.
3. Added `godot-docs` MCP server to `.cursor/mcp.json`.
4. Added operator docs/commands:
   - `docs/AGENT_CATALOG.md`
   - `docs/LINEAR_SETUP.md`, `LINEAR_ENV_VARS.md`, `DAILY.md`
   - `.cursor/commands/linear-*.md`
5. Expanded outline-driven backlog templates:
   - `docs/backlog/outline-master.json`
   - included in `tools/linear/seed-backlog.ts`

---

## Autonomous build and connection audit (snapshot: 2026-04)

This section is the **single checklist** for “where we are”: agents, MCP, CI, tests, and UI reference flow.

### Cursor MCP (`.cursor/mcp.json`)

| Server | Purpose | Notes |
|--------|---------|--------|
| `linear` | Issue CRUD, PM tooling | `mcp-remote` → `https://mcp.linear.app/mcp` (needs Linear auth in Cursor). |
| `godot` | Editor/run project/debug/scene ops | [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) via `npx @coding-solo/godot-mcp`; `GODOT_PATH` set to `D:\Godot\...`. |
| `godot-docs` | API/class lookup | Remote MCP at `https://godot-docs-mcp.j2d.workers.dev/mcp`. |
| `github` | Repo/PR integration | `@modelcontextprotocol/server-github` with `GITHUB_TOKEN` from env. |

**Not configured in-repo:** Gemini image MCP, Playwright MCP (optional for future UI capture). UI references today are **prompt-led** (see below).

### Godot MCP: open-source vs “pro”

| Option | Link | Fit for Whether |
|--------|------|------------------|
| **Coding-Solo/godot-mcp** | [github.com/Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) | **Already wired.** Editor launch, run/stop project, debug output, scene/node helpers — enough for agents to iterate and see errors. |
| **youichi-uda/godot-mcp-pro** | [github.com/youichi-uda/godot-mcp-pro](https://github.com/youichi-uda/godot-mcp-pro) | Paid add-on with a **large** tool surface (animation, 3D, particles, shaders, testing hooks, etc.). Consider if agents need richer **scene/animation** automation; not required for baseline 2D puzzle iteration. |

**Recommendation:** stay on Coding-Solo until you hit limits (e.g. bulk animation rigging); then evaluate godot-mcp-pro for a **level-builder / art** lane only.

### Parallel agents — what exists vs what is manual

| Layer | Status |
|-------|--------|
| **Role docs** | `.claude/agents/*.md` + `docs/AGENT_CATALOG.md`. |
| **Linear lanes** | `linear:pickup -- --role=...`, `linear:producer -- --apply`, phased seed/promote — **implemented.** |
| **Scope rules** | `docs/CURSOR_PARALLEL_AGENTS.md` (directory boundaries). |
| **Cursor Cloud** | Documented in `docs/CURSOR_CLOUD_AGENT_SETUP.md`; not self-hosted; parity checked via `daily.ps1` vs cloud. |
| **Windows orchestrator** | Scripts only: `daily-autonomous.ps1`, Task Scheduler — no Conductor-style GUI. |

**Gap:** No automated “merge queue for N agents”; Producer + human PR review still expected.

### Testing and validation

| Check | Where | Status |
|-------|-------|--------|
| **Level validation** | `tools/tasks/validate.ps1` → `scripts/validate_all_levels.gd` | **Runs locally** in autonomous lane. |
| **GUT unit tests** | `addons/gut/` ([bitwes/Gut](https://github.com/bitwes/Gut)) + `gut_cmdln.gd` | **Installed** (v9.6.0). `validate.ps1` runs `godot --headless --import` then GUT on `res://test`. |
| **CI** | `.github/workflows/ci.yml` | **Node + Godot 4.6.2 Linux:** `--import`, GUT (`res://test`), `validate_all_levels.gd`. |
| **Visual / screenshot QA** | Not automated | Optional future: capture + vision model (similar in spirit to [godogen](https://github.com/htdt/godogen)) or MCP-driven run + manual screenshot checklist. |

**Priority to “make it test for real”:** (1) Install GUT properly and commit `gut_cmdln.gd` path, (2) add CI job with Godot 4.6 headless + `validate.ps1` equivalent on Linux or Windows runner.

### UI/UX + Gemini (and related)

There is **no** in-repo Gemini API key wiring for agents. The intended workflow is:

1. **Specs in-repo:** `docs/ART_DIRECTION.md` (palette, readability, mobile-first).
2. **Reference generation:** `docs/ASSET_PROMPTS_GEMINI.md` — paste prompts into **Google AI Studio / Gemini** (or any image model) for mood boards, tile concepts, UI concepts.
3. **Implementation:** `ui-developer` / `art-pipeline` agents import **PNG references** into Godot (`assets/`, themes); use `tools/tasks/mobile-preview.ps1` for mobile-oriented preview.

**Console + mobile:** treat Steam deck / controller and phone as **touch-safe targets** and **readable at small scale** (already in workspace rules); validate in editor with stretch/aspect presets, not only desktop window.

### Doc map (autonomous path)

| Topic | Doc |
|-------|-----|
| Daily loop | `docs/DAILY.md` |
| PM + fallbacks | `docs/AUTONOMOUS_ORCHESTRATION.md` |
| Parallel agents | `docs/CURSOR_PARALLEL_AGENTS.md` |
| Cloud agents | `docs/CURSOR_CLOUD_AGENT_SETUP.md` |
| Linear | `docs/LINEAR_SETUP.md`, `LINEAR_ENV_VARS.md` |
| PR merge policy | `docs/GITHUB_AUTOMERGE.md` |
| Roles | `docs/AGENT_CATALOG.md` |
| Path policy | `docs/PATHS_AND_STORAGE_POLICY.md` |

---

## Remaining intentional deferments

- Automatic PR ↔ Linear comment linking is not fully auto-wired.
- Godot **export** / release binaries are not built in CI yet (`build.yml` still a scaffold).
- Full screenshot / vision QA loop is not implemented (documented as optional).
- Silent merge-all PRs remains off by design (`GITHUB_AUTOMERGE.md`).

## Recommended next expansion

1. **Export CI:** `export_presets.cfg` + workflow job to `godot --export-release` and upload artifacts (see autonomous build table above).
2. Optional **godot-mcp-pro** for heavy level/animation lanes if Coding-Solo tools are limiting.
3. PR-link auto-comment in close-loop (`linear:close`) when issue id is in branch/PR.
4. Per-role SLA / stalled-issue report in Linear tooling.

---

## Next steps toward autonomous build (ordered)

**Definition of “auto building” here:** every meaningful change is **validated in CI**, and **release tags** (or main) produce a **downloadable Windows build** without manual Godot clicks.

| Priority | Step | Why it matters | Current state |
|----------|------|----------------|---------------|
| **1** | **Godot in CI** — install Godot 4.6.x on the runner, run the same sequence as `validate.ps1` (`--import`, GUT, `validate_all_levels.gd`). | Agents and PRs get a **hard gate**; “autonomous” merges are not safe without this. | **Done** in `.github/workflows/ci.yml` (Ubuntu + Godot 4.6.2). |
| **2** | **Export presets in repo** — create `export_presets.cfg` (Windows/Steam first) via Editor → Export once, commit file. | Headless **`--export-release`** needs named presets; without them, `build.ps1` / Actions cannot emit binaries. | No `export_presets.cfg` in tree. |
| **3** | **Real `build.yml`** — on `workflow_dispatch` + `v*` tags: checkout, install Godot + export templates, `godot --headless --export-release "Windows Desktop" path.exe`, upload **artifact**. | Closes the loop from **green main** to **artifact**; agents can target “fix until CI + export green”. | `build.yml` is a placeholder message only. |
| **4** | **Branch protection** — require **Whether CI** (and future build job if split) on `main`; optional `automerge` label workflow. | Lets you trust **auto-merge** or bot merges after validation. | Documented in `GITHUB_AUTOMERGE.md`; not enforced in-repo. |
| **5** | **Windows Task Scheduler** — daily: `daily-autonomous.ps1` then optional `linear:producer -- --apply`. | **Ops** automation; does not replace CI but keeps Linear + local health fresh. | Scripts exist; scheduling is on your machine. |

**Next move after validation CI:** **priority 2 + 3** — commit `export_presets.cfg` and teach `build.yml` to export and upload artifacts.

Local and CI should stay on the **same Godot minor** (4.6.x) to avoid import drift.
