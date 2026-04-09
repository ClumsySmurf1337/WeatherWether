# Godot 4.x docs access for agents (no Docker, no remote MCP)

The third-party **`godot-docs` MCP** (`mcp-remote` → `godot-docs-mcp.j2d.workers.dev`) was unreliable. This project uses **official documentation URLs** instead.

## Canonical entry points

| Resource | URL |
|----------|-----|
| **Stable (recommended default)** | [docs.godotengine.org/en/stable](https://docs.godotengine.org/en/stable/) |
| **Pinned to 4.6 (matches `project.godot`)** | [docs.godotengine.org/en/4.6](https://docs.godotengine.org/en/4.6/) |
| **Class reference (stable)** | [Class reference](https://docs.godotengine.org/en/stable/classes/index.html) |
| **Class reference (4.6)** | [Class reference](https://docs.godotengine.org/en/4.6/classes/index.html) |

## Class page URL pattern

For a class named `PascalCase`, the path is usually:

`https://docs.godotengine.org/en/4.6/classes/class_<snake_case>.html` (or `/en/stable/...` if you prefer the rolling stable tree)

Examples:

- `Node2D` → `https://docs.godotengine.org/en/4.6/classes/class_node2d.html`
- `Control` → `https://docs.godotengine.org/en/4.6/classes/class_control.html`
- `TileMapLayer` → `https://docs.godotengine.org/en/4.6/classes/class_tilemaplayer.html`

If a lookup 404s, use the [4.6 class index](https://docs.godotengine.org/en/4.6/classes/index.html) search.

## Cursor IDE (index docs — no extra servers)

1. Open **Cursor Settings** → **Features** → **Chat** / **Indexing** (labels vary by version).
2. Add **documentation** / **@Docs** source with base URL: `https://docs.godotengine.org/en/4.6/` (or `/en/stable/`).

That lets the model cite Godot docs without running Docker or a separate MCP process.

## Agents without indexed docs

Use the **browser MCP** (if enabled), **WebFetch**, or paste the class URL into the prompt. Prefer **stable** URLs so links stay valid across minor releases.

## Offline (optional)

[Offline HTML builds](https://docs.godotengine.org/en/stable/) are linked from the docs homepage (“Offline documentation”); not required for CI or agents.

## Node.js (tooling + CI)

- **CI:** `.github/workflows/ci.yml` uses `actions/setup-node` with **`node-version: "22"`** and sets **`FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true`** so GitHub’s built-in actions match the [Node 20 deprecation timeline](https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/).
- **Local:** Install **Node 22+** (LTS) from [nodejs.org](https://nodejs.org/) or `nvm install 22` / `fnm install 22`, then `npm ci` in the repo root.
- **package.json** declares `"engines": { "node": ">=22" }` for consistency.

To move to **Node 24** later: change `node-version` in `ci.yml` to `"24"` and bump `engines` if you want strict alignment.
