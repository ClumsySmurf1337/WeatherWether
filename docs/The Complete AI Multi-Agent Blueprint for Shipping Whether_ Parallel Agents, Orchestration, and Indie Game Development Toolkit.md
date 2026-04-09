The complete AI multi-agent blueprint for shipping “Whether” 

Build fresh. Don’t fork godogen. That’s the bottom line after deep analysis of the entire AI game dev toolkit landscape as of April 2026\. Godogen is a brilliant autonomous game generator tightly coupled to Claude Code and C\# — but you need an interactive, multi-agent development system built around Cursor, GDScript, and parallel workflows. The toolkit described below — “whether-kit” — gives you a purpose-built development system with Claude Code worktrees for parallel agents, Conductor for orchestration, Linear MCP for automated project management, a BFS puzzle solver for level validation, and a complete CI/CD pipeline. A solo developer following this blueprint can realistically run 3–4 AI agents simultaneously on different game systems, with a producer agent tracking all 250+ tasks across code, art, audio, level design, QA, and marketing. Everything here is executable on Monday morning. 

**Core design contract (Whether).** The PM and every agent must align implementation, tasks, and reviews with the product spine in `docs/Building Whether_ A Weather-Powered Puzzle Game from Zero to Launch.md`: a **grid** puzzle with **terrain and objects**, a **hand of weather cards** where players choose **order and grid placement**, and **six weathers**—Rain, Sun, Frost, Wind, Lightning, Fog—each **physically transforming** the board through teachable state rules (water/ice/steam, push, fog reveal, chains through water, etc.). Early levels favor **perfect information**; later levels use **fog** and hidden tiles so players commit under uncertainty—the “whether” in “whether weather.” Do not add orthogonal mechanics without an explicit GDD change and producer sign-off.

1\. Godogen is impressive but wrong for this project 

Godogen (github.com/htdt/godogen, \~2,400 stars) is a set of Claude Code skills that generates complete, playable Godot games from natural language descriptions. skillsllm Created by htdt (Alex Ermakov), it operates through two skills: an orchestrator ( /godogen ) that decomposes game descriptions into tasks, and a task executor ( /godot-task ) that implements each piece in a forked context window. GitHub Its most innovative feature is a visual QA loop — it runs the game headlessly, captures screenshots, and feeds them to Gemini Flash for automated visual bug detection. SkillsLLM 

The architecture is genuinely clever. Each task executes in Claude Code’s context: fork mode, preventing state accumulation across tasks. It includes a hand-written Godot quirks database ( quirks.md ), lazy-loaded API documentation for 850+ Godot classes, and budget-aware asset generation using Gemini, xAI Grok, and Tripo3D. Ihor Chyshkala After four major rewrites, Ihor Chyshkala the project has shifted from GDScript to C\# / .NET 9, 

chyshkala with the rationale documented in gdscript-vs-csharp.md : GitHub LLMs produce significantly fewer hallucinations and runtime errors with C\# due to its vastly larger training corpus and stronger type system. 

Why forking godogen doesn’t work  
The fork path fails for five specific reasons: 

1\. Claude Code lock-in. Godogen’s skill system ( SKILL.md \+ context: fork ) has no equivalent in Cursor. Cursor uses .cursor/rules/\*.mdc files and a fundamentally different agent architecture. Augment Code cursor Porting would mean rewriting every skill from scratch — at which point you’ve built fresh anyway. 

2\. C\# vs GDScript mismatch. Godogen has fully migrated to C\#. GitHub Your project specifies GDScript. Every code generation template, scene builder, and script reference would need conversion. 

3\. Autonomous vs interactive workflow. Godogen is designed for “describe a game, walk away, come back to a playable prototype.” GitHub You need an interactive system where you direct multiple agents on specific tasks throughout the day. 

4\. Single-agent pipeline. Godogen runs one long Claude Code session. GitHub You need 3–5 parallel agents working on different systems simultaneously. 

5\. No Cursor/multi-tool integration. Godogen has no awareness of MCP servers, Linear, GitHub Actions, or the broader toolchain needed for shipping a real game. 

What to extract from godogen 

The domain knowledge is gold. Cherry-pick these specific files and adapt them into your Cursor rules and skill files: 

**quirks.md** — Engine behaviors you can’t learn from docs alone (owner propagation, signal timing, physics gotchas) 

**scene-generation.md** — Patterns for building node trees and serializing to .tscn **gdscript.md** — Hand-written language reference tuned for LLM consumption **visual-qa.md** — The concept of screenshot→AI analysis feedback loops 

**asset-gen.md** — Prompt templates for AI image generation with game-asset-specific formatting GitHub 

2\. The whether-kit: a fresh toolkit built for parallel agents Repository structure 

whether-kit/ 

├── .cursor/  
│ ├── rules/ 

│ │ ├── godot-gdscript.mdc \# Always-on GDScript coding standards │ │ ├── weather-game.mdc \# Whether-specific patterns and architecture │ │ ├── whether-development.mdc \# GDD/core concept alignment, pipelines, agent doc duty │ │ ├── godot-engine-docs.mdc \# Official Godot doc URLs (no remote docs MCP) │ │ └── puzzle-design.mdc \# Puzzle mechanic rules and constraints │ ├── skills/ 

│ │ ├── weather-puzzle-design/ 

│ │ │ ├── SKILL.md \# Puzzle mechanic design assistant │ │ │ └── references/ 

│ │ │ ├── game-design-doc.md 

│ │ │ └── weather-rules.md 

│ │ ├── godot-scene-builder/ 

│ │ │ ├── SKILL.md \# Scene tree construction patterns │ │ │ └── references/ 

│ │ │ ├── quirks.md \# Extracted from godogen │ │ │ └── scene-patterns.md 

│ │ ├── level-builder/ 

│ │ │ ├── SKILL.md \# LDtk JSON generation \+ validation │ │ │ └── references/ 

│ │ │ └── ldtk-format.md 

│ │ ├── build-and-deploy/ 

│ │ │ └── SKILL.md \# CI/CD, platform configs, release │ │ └── audio-pipeline/ 

│ │ └── SKILL.md \# SFX/music generation workflow │ ├── commands/ 

│ │ ├── run-game.md 

│ │ ├── run-tests.md 

│ │ ├── validate-levels.md 

│ │ └── build-all.md 

│ └── mcp.json \# MCP server configurations ├── .claude/ 

│ ├── CLAUDE.md \# Claude Code project instructions │ ├── agents/ 

│ │ ├── gameplay-programmer.md \# Custom subagent definition │ │ ├── level-designer.md 

│ │ ├── qa-agent.md 

│ │ └── art-pipeline.md 

│ └── settings.json 

├── .github/ 

│ └── workflows/ 

│ ├── ci.yml \# Test \+ validate on every push │ └── release.yml \# Multi-platform build \+ deploy ├── docs/ 

│ ├── GDD.md \# Game Design Document 

│ ├── architecture.md \# Technical architecture │ ├── weather-rules.md \# Complete weather interaction matrix │ └── difficulty-curve.md \# Target difficulty per level ├── scripts/  
│ ├── validate\_all\_levels.gd \# Headless level solver 

│ ├── puzzle\_solver.gd \# BFS solver engine 

│ ├── generate\_levels.py \# AI-assisted level generation 

│ └── orchestrate.sh \# Agent spawning helper 

├── test/ 

│ ├── test\_weather\_cards.gd \# GUT unit tests 

│ ├── test\_grid\_system.gd 

│ ├── test\_puzzle\_solver.gd 

│ └── test\_save\_load.gd 

├── levels/ \# LDtk JSON level data 

│ ├── world1/ ... world6/ 

│ └── whether.ldtk \# Master LDtk project 

├── project.godot 

├── .gutconfig.json 

└── linear-backlog-generator.js \# Script to populate Linear 

Core **.cursor/rules/godot-gdscript.mdc** 

\--- 

description: Godot 4.6 GDScript rules for "Whether" puzzle game 

globs: \["\*.gd", "\*.tscn", "\*.tres"\] 

alwaysApply: true 

\--- 

\# Godot 4.6 GDScript — "Whether" Development Rules 

\#\# Strict Typing Everywhere 

\- ALL variables: \`var score: int \= 0\`, \`var grid: Array\[Array\[int\]\] \= \[\]\` \- ALL params and returns: \`func place\_card(pos: Vector2i, card: WeatherCard) \-\> bool:\` \- Use \`class\_name\` at top of every script 

\#\# Architecture 

\- Grid system: custom \`GridManager\` extending Node2D, stores terrain as flat Array\[int\] \- Weather cards: Resource-based (\`WeatherCard extends Resource\`) with enum types \- State machine: \`GameManager\` autoload singleton with explicit state enum \- Signals for all cross-system communication — never call methods directly between systems \- Input: Godot Input Map with both touch and mouse actions 

\#\# Weather Types (canonical enum) 

\`\`\`gdscript 

enum WeatherType { RAIN, SUN, FROST, WIND, LIGHTNING, FOG } 

enum Terrain { EMPTY, DRY\_GRASS, WET\_GRASS, ICE, SCORCHED, WATER, FOG\_COVERED, SNOW, MUD }

File Organization   
scenes/{system}/ — Scene files grouped by system 

scripts/{system}/ — Scripts grouped by system 

resources/ — Custom Resources (cards, level data, config) 

assets/sprites/ , assets/audio/ , assets/fonts/ 

test/ — All GUT test files prefixed test\_ 

Critical Patterns 

Use @onready var node: Type \= %UniqueNode — never raw $Path syntax 

Use @export for inspector configuration 

Prefer composition (child nodes) over deep inheritance 

Signals use past tense: card\_placed , terrain\_changed , level\_completed 

Keep methods under 30 lines, extract helpers aggressively 

Do NOT 

Never use GDScript 1.0 / Godot 3.x APIs 

Never use yield() — use await 

Never call get\_node() in \_process() — cache with @onready 

Never create circular script dependencies 

Never use untyped Arrays or Dictionaries in core systems 

\#\#\# Claude Code project config: \`.claude/CLAUDE.md\` 

\`\`\`markdown 

\# Whether — AI Agent Instructions 

\#\# Project 

Grid-based weather puzzle game. Godot 4.6 \+ GDScript. \~130 levels, 6 worlds. Weather cards (rain/sun/frost/wind/lightning/fog) placed on tile grids to transform terrain. 

\#\# Architecture 

\- GridManager: core grid logic, terrain state, card placement 

\- WeatherSystem: card effects, terrain transformations, chain reactions   
\- PuzzleSolver: BFS solver for level validation (scripts/puzzle\_solver.gd) \- LevelLoader: reads LDtk JSON, constructs playable scenes 

\- GameManager: autoload singleton, state machine, save/load 

\#\# Conventions 

\- Strict GDScript typing everywhere 

\- GUT 9.x for testing (run: godot \--headless \-s addons/gut/gut\_cmdln.gd \-gexit) \- Levels stored as LDtk JSON in levels/worldN/ 

\- Branch naming: feat/WHT-{number}-{description} or fix/WHT-{number}-{description} \- Commits: conventional commits linking Linear issues 

\#\# Worktree Rules 

When working in a worktree, ONLY modify files within your assigned system scope. Do not touch files outside your designated directories without explicit permission. 

\#\# Testing 

Run before committing: godot \--headless \-s addons/gut/gut\_cmdln.gd \-gexit Run level validation: godot \--headless \-s scripts/validate\_all\_levels.gd \--quit

MCP server configuration: **.cursor/mcp.json** (copy from the repo; excerpt below reflects the **Whether** Windows layout as of 2026-04)

{ 

 "mcpServers": { 

 "linear": { 

 "command": "npx", 

 "args": \["-y", "mcp-remote", "https://mcp.linear.app/mcp"\]  }, 

 "godot-full": { 

 "command": "node", 

 "args": \["tools/godot-mcp-full/build/index.js"\], 

 "env": { 

 "GODOT\_PATH": "D:/Godot/Godot\_v4.6.2-stable\_win64.exe" 

 } 

 }, 

 "godot": { 

 "command": "npx", 

 "args": \["-y", "@coding-solo/godot-mcp"\], 

 "env": { 

 "GODOT\_PATH": "D:/Godot/Godot\_v4.6.2-stable\_win64.exe" 

 } 

 }, 

 "github": { 

 "command": "npx", 

 "args": \["-y", "@modelcontextprotocol/server-github"\], 

 "env": { 

 "GITHUB\_PERSONAL\_ACCESS\_TOKEN": "${GITHUB\_TOKEN}" 

 } 

 } 

 }   
} 

**Whether repo MCP notes:** \- **Primary Godot MCP:** `godot-full` — [tugcantopaloglu/godot-mcp](https://github.com/tugcantopaloglu/godot-mcp) (149 tools, runtime/UI/export). Run `pwsh ./tools/install/setup-godot-mcp-full.ps1`; `tools/godot-mcp-full/` is gitignored. \- **Optional:** `godot` — [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) for lightweight `npx` without a local build. \- **Not used:** remote `godot-docs` MCP (flaky). Use [Godot 4.6 docs](https://docs.godotengine.org/en/4.6/) and `docs/GODOT_DOCS_ACCESS.md`. \- **Paid:** [godot-mcp-pro](https://github.com/youichi-uda/godot-mcp-pro) — not wired by default. \- **Parallel agents:** **Cursor Cloud is not self-hosted**—cloud agents run on Cursor’s infrastructure. For **local** parallelism (default for Godot-tight work), use **multiple Cursor windows on git worktrees:** `pwsh ./tools/tasks/new-agent-worktree.ps1 -BranchName agent/your-lane` with scopes in `docs/CURSOR_PARALLEL_AGENTS.md` and `.claude/CLAUDE.md`.

3\. Multi-agent orchestration: the realistic 3-agent workflow 

The tool landscape in April 2026 

Cursor 3.0 (released April 2, 2026\) Build Fast with AI now supports up to 8 parallel agents in separate git worktrees, Cursor cursor background cloud agents running on Ubuntu VMs for 25–52+ hours, Augment Code and a Mission Control grid view for monitoring. 

Tech Jacks Solutions It supports Claude 4.5 Opus, GPT-5.4, Gemini 3 Pro, Cursor and its own Composer model. Cursor 35% of Cursor’s internal merged PRs are created by its background agents. Morph You can install the GitHub Copilot extension alongside Cursor’s native models — disable one’s inline completions to avoid conflicts. DEV Community 

Claude Code has first-class git worktree support ( claude \--worktree feature-name \-- tmux ), Threads up to 7 parallel subagents per session, Claude Lab custom subagents defined as markdown in .claude/agents/ , Claude Fast Claude and Agent Teams with inter-agent messaging through JSON inboxes on disk. lilting channel It scores 80.8% on SWE-bench Verified. Morph DEV Community 

OpenAI Codex CLI ships with GPT-5.4, built-in sandboxing, MCP support, and can run as an MCP server consumed by other agents. Openai Included with ChatGPT Plus ($20/mo). LeadDev Openai 

Recommended orchestration stack

| Layer  | Tool  | Cost |
| ----- | :---- | :---- |
| Primary IDE  | Cursor Pro  | $20/mo |
| Primary  agent  | Claude Code (Claude Pro/Max)  | $20–100/mo |
| Orchestrator  | Conductor (macOS) or Claude Squad (cross-platform) | Free |
| Secondary  agent  | OpenAI Codex CLI | Included with ChatGPT Plus $20/mo |
| Linear PM  | Official Linear MCP  | Free (Linear free tier) |
| Total  |  | $60–140/mo |

|  |  |  |
| :---- | :---- | :---- |

Conductor (conductor.build) is a Y Combinator-backed macOS app Grokipedia that provides a visual dashboard for running multiple Claude Code/Codex agents in parallel, each in isolated git worktrees. AddyOsmani.com One-click agent spawning, real-time progress, diff-first review, and Linear integration. Free to use with your existing API keys. 

Y Combinator If you’re on Linux, Claude Squad ( brew install claude-squad , run as cs ) provides equivalent functionality as a terminal TUI managing multiple tmux sessions. GitHub 

Git worktree isolation is the foundation 

Each agent gets its own worktree — a separate filesystem checkout with its own branch sharing the same git history. Dan Does Code O'Reilly No file conflicts are possible because agents literally work on different copies: 

\# Morning: spawn worktrees for today's tasks 

claude \--worktree grid-system \--tmux 

claude \--worktree weather-effects \--tmux  

claude \--worktree ui-level-select \--tmux 

\# Monitor all worktrees 

git worktree list 

\# Review completed work 

cd .claude/worktrees/grid-system 

git diff main \--stat 

git log \--oneline main..HEAD 

\# Merge when satisfied 

git checkout main && git merge worktree-grid-system && git push git worktree remove .claude/worktrees/grid-system 

The practical ceiling is 3–5 parallel worktrees before context-switching overhead between terminals becomes counterproductive, according to multiple developer reports. MindStudio Cursor’s 8-agent limit is theoretical. 

Preventing the “who’s editing what” problem 

The key insight: scope each agent to non-overlapping directory trees. For “Whether”: Agent A (Grid/Core): scripts/grid/ , scripts/weather/ , scenes/grid/ Agent B (UI): scripts/ui/ , scenes/ui/ , assets/ui/ 

Agent C (Levels): levels/ , scripts/level\_loader.gd , scenes/levels/  
Agent D (QA): test/ , scripts/validate\_all\_levels.gd 

Define these boundaries in each worktree’s CLAUDE.md . Agents communicate through stable interfaces (signals, exported Resources), not shared files. 

A realistic daily workflow 

Morning planning (15 minutes): Open Conductor. Review Linear backlog. Identify 3 parallelizable tasks with non-overlapping file scopes. Write one-paragraph task specs for each. 

Task dispatch (10 minutes): 

\# In Conductor or terminal: 

claude \--worktree feat-rain-frost-chain \--tmux 

\# Paste: "Implement rain→frost terrain chain reaction in WeatherSystem. \# When frost card is placed adjacent to wet tiles, convert to ice. \# Add 3 GUT tests. Only touch scripts/weather/ and test/test\_weather\_cards.gd." 

claude \--worktree feat-level-select-ui \--tmux  

\# Paste: "Build world select → level select UI flow. 

\# 6 world buttons, each opens level grid. Lock/unlock based on save data. \# Only touch scripts/ui/, scenes/ui/, and assets/ui/." 

claude \--worktree feat-level-batch-w1 \--tmux 

\# Paste: "Generate LDtk JSON for World 1 levels 6-10. 

\# Difficulty: easy-medium. Grid: 4x4. Cards: rain \+ sun only. \# Run solver to verify solvability. Only touch levels/world1/." 

Monitoring (check every 30–60 minutes): Glance at Conductor dashboard or cs TUI. Agents show progress, file changes, and terminal output in real time. Intervene only if an agent gets stuck. 

Afternoon review and merge (30–60 minutes): Review each completed worktree’s diff. Run tests. Merge to main. Deploy next batch of tasks or start integration testing. 

Evening: fire overnight cloud agents via Cursor background agents for documentation, test generation, or level batch creation. 

4\. Linear as the production brain 

Setup in 5 minutes  
The official Linear MCP server (launched May 2025\) is the only option worth considering. Linear Linear The community jerhadf/linear-mcp-server (344 stars) is officially deprecated. github The official server provides 21+ tools including list\_issues , create\_issue , update\_issue , search\_issues , and add\_comment , all hosted by Linear with no local server needed. linear 

\# For Claude Code: 

claude mcp add \--transport http linear-server https://mcp.linear.app/mcp \# For Cursor: add to .cursor/mcp.json (shown above) 

Linear structure for “Whether” 

States workflow: Triage → Backlog → Todo → In Progress → In Review → Done 

Labels by workstream: Core-Engine, Puzzle-Design, Level-Design, Art-Visual, Audio Music, UI-UX, QA-Testing, Marketing, Store-Page, Legal-Business, Release-Ops, Analytics, Accessibility, Localization 

Project hierarchy:

| Project  | Issues  | Priority |
| :---- | :---- | :---- |
| Core Engine & Framework  | \~25 (grid, weather, state, save/load) | ![][image1] Critical  path |
| Puzzle Mechanics  | \~15 (solver, scoring, hints, undo) | ![][image2] Critical  path |
| World 1: Morning Mist (Levels 1– 22\) | \~10 batches of 2–3 | ![][image3] High |
| World 2: Afternoon Sun (Levels 23–44) | \~10 batches | ![][image4] High |
| World 3: Evening Storm (Levels 45–66) | \~10 batches | ![][image5] Medium |
| World 4: Night Rain (Levels 67– 88\) | \~10 batches | ![][image6] Medium |
| World 5: Dawn Frost (Levels 89– 110\) | \~10 batches | ![][image7] Low (for  now) |
| World 6: Full Spectrum (Levels |  |  |

| 111–130)  | \~8 batches | ![][image8] Low |
| :---- | :---- | :---- |
| UI/UX  | \~20 (menus, HUD, transitions) | ![][image9] High |
| Art & Visual  | \~30 (style guide, tiles, VFX, key art) | ![][image10] Medium |
| Audio & Music  | \~15 (6 themes, SFX library) | ![][image11] Medium |
| Marketing & Launch  | \~20 (Steam page, trailer, press kit) | ![][image12] Low  initially |
| Release Ops  | \~15 (CI/CD, platform compliance, analytics) | ![][image13] Medium |

Total: \~250–350 issues. Use 1-week cycles. Core engine in weeks 1–4, first playable by week 8, content production weeks 9–20, polish and marketing weeks 21–28. 

Agent-driven ticket flow 

The workflow is straightforward with Linear MCP: 

1\. Producer agent reads the backlog, identifies today’s highest-priority Todo issues 

2\. Coding agent picks up a ticket: reads issue details and acceptance criteria via list\_issues 

3\. Agent creates a feature branch: feat/WHT-042-rain-frost-chain 

4\. Agent updates status via MCP: update\_issue(id, status="In Progress") 

5\. Agent implements, writes tests, commits with conventional commits linking the issue 

6\. Agent creates PR, adds comment with link: add\_comment(issueId, body="PR \#47 ready") 

7\. Agent moves to In Review: update\_issue(id, status="In Review") 

8\. You review the PR, merge, and GitHub-Linear integration auto-closes the issue Eesel AI 

Auto-generating the backlog 

Use Claude Code with Linear MCP connected. Point it at your GDD: 

Read docs/GDD.md and generate the complete Linear backlog for "Whether." Create Projects for: Core Engine, Puzzle Mechanics, Level Design (one sub-project per world), UI/UX, Art, Audio, Marketing, Release Ops, QA. 

Each issue needs: \[TYPE\] title, acceptance criteria as checkboxes, appropriate label, priori  
Levels: one parent issue per 5-level batch with sub-issues for design, implement, playtest, Use Linear MCP tools to create all issues directly. Start with Core Engine. 

For bulk import, the Linear JavaScript SDK works: 

const { LinearClient } \= require('@linear/sdk'); 

const client \= new LinearClient({ apiKey: process.env.LINEAR\_API\_KEY }); 

// Create 130 level issues in batches 

for (let world \= 1; world \<= 6; world++) { 

 const levelsInWorld \= world \=== 6 ? 20 : 22; 

 for (let batch \= 0; batch \< Math.ceil(levelsInWorld / 5); batch++) { 

 const start \= batch \* 5 \+ 1; 

 const end \= Math.min(start \+ 4, levelsInWorld); 

 await client.createIssue({ 

 teamId: TEAM\_ID, 

 projectId: LEVEL\_PROJECT\_ID, 

 title: \`\[LEVEL\] World ${world} \- Levels ${start}-${end}\`, 

 description: \`\#\# Acceptance Criteria\\n- \[ \] All puzzles solvable\\n- \[ \] Difficulty mat priority: world \<= 3 ? 2 : 3, 

 labelIds: \[LEVEL\_DESIGN\_LABEL\] 

 }); 

 } 

}

The Producer Agent 

This is the most valuable agent in the system. It acts as a game producer — tracking every workstream, flagging risks, guarding scope, and ensuring nothing falls through the cracks. Here is its complete system prompt: 

\# PRODUCER AGENT — "Whether" Game Development 

\#\# Identity 

You are the Producer Agent for "Whether," a grid-based weather puzzle game  (\~130 levels, 6 worlds, Godot 4.6 GDScript). You serve as project manager  for a solo indie developer. You are meticulous, proactive, and scope-conscious. 

\#\# Core Responsibilities 

1\. BACKLOG: Maintain and prioritize Linear backlog. Every issue needs clear   acceptance criteria, labels, priority, and complexity estimate. 

2\. SPRINT PLANNING: Select \~30 hours of work per weekly cycle based on   priority, dependencies, and capacity. 

3\. PROGRESS: Monitor daily. Flag stalled issues (\>3 days without update). 4\. SCOPE GUARD: Evaluate new features against: (a) Does it make puzzles    
 more satisfying? (b) Does it fit the weather theme? (c) Achievable   within budget? If no to any → Icebox. 

5\. RISK DETECTION: Content bottleneck (130 levels is massive), technical   debt, missing assets, marketing gaps, legal oversights. 

6\. QUALITY: Every level playtested. Difficulty curve tracked across all levels. 7\. COORDINATION: Keep art, audio, code, levels, UI, marketing synchronized. 8\. LAUNCH READINESS: Track store pages, trailer, press kit, EULA, privacy   policy, accessibility, analytics, crash reporting. 

\#\# Decision Framework 

![][image14] Ship-blockers: Crashes, data loss, broken core mechanics 

![][image15] Critical path: Features required for next milestone 

 Content pipeline: Levels and assets (long lead time — start early)  Polish: Visual/audio improvements, UX tweaks 

 Nice-to-have: Stretch goals → Icebox 

\#\# Failure Modes to Watch 

\- Scope creep (monitor issue count growth rate) 

\- Content grind burnout (track levels/week, suggest batching) \- Marketing neglect (start at 60% content completion) 

\- Audio last (start at 40% content completion) 

\- Save/load untested (ship-blocker category, test from day 1\) \- No external playtesting (schedule 3+ sessions at milestones) \- Analytics absent (integrate early to measure player behavior) 

\#\# Tools Available 

Linear MCP, GitHub MCP, project docs (GDD.md, architecture.md) 

5\. QA, level building, and the puzzle solver pipeline 

Automated testing with GUT 9.x 

GUT (github.com/bitwes/Gut, 2,400 stars, MIT license) is the standard unit testing framework for GDScript. It runs via editor GUI, command line, or CI, with JUnit XML export for GitHub Actions integration. The alternative GdUnit4 (github.com/godot-gdunit labs/gdUnit4) offers a fluent assertion syntax and built-in editor test inspector — either works, but GUT has deeper community adoption. 

Example tests for “Whether” core mechanics: 

\# test/test\_weather\_cards.gd 

extends GutTest  
var \_grid: PuzzleGrid 

func before\_each(): 

 \_grid \= PuzzleGrid.new(5, 5\) 

func after\_each(): 

 \_grid.free() 

func test\_rain\_transforms\_dry\_to\_wet(): 

 \_grid.set\_terrain(2, 3, Terrain.DRY\_GRASS) 

 var card := WeatherCard.new(WeatherCard.Type.RAIN) 

 \_grid.place\_card(card, Vector2i(2, 3)) 

 assert\_eq(\_grid.get\_terrain(2, 3), Terrain.WET\_GRASS) 

 card.free() 

func test\_frost\_on\_wet\_creates\_ice(): 

 \_grid.set\_terrain(1, 1, Terrain.WET\_GRASS) 

 var card := WeatherCard.new(WeatherCard.Type.FROST) 

 \_grid.place\_card(card, Vector2i(1, 1)) 

 assert\_eq(\_grid.get\_terrain(1, 1), Terrain.ICE) 

 card.free() 

func test\_level\_is\_solvable(): 

 var level := LevelLoader.load("res://levels/world1/level\_03.tres")  var solver := PuzzleSolver.new(level) 

 var result := solver.solve() 

 assert\_true(result.is\_solvable, "Level 1-03 must be solvable")  assert\_gt(result.min\_moves, 0\) 

 solver.free() 

The BFS puzzle solver — the most critical automation 

“Whether” is a combinatorial placement problem: given N weather cards and a grid with initial terrain, find a card-placement sequence that transforms the grid to a goal state. BFS (Breadth-First Search) with state hashing is the right algorithm — it guarantees finding the minimum-move solution and the state space for typical puzzle grids (5×5 to 8×8 with 3–6 cards) is manageable (thousands to low millions of states). 

\# scripts/puzzle\_solver.gd 

class\_name PuzzleSolver 

var level: LevelData 

var solutions\_found: int \= 0 

func solve() \-\> SolverResult:  
 var initial := PuzzleState.new(level.initial\_terrain, level.available\_cards, \[\])  var queue: Array\[PuzzleState\] \= \[initial\] 

 var visited: Dictionary \= {initial.hash\_key(): true} 


 while queue.size() \> 0: 

 var current := queue.pop\_front() 

 if \_matches\_goal(current.terrain): 

 solutions\_found \+= 1 

 return SolverResult.new(true, current.moves, current.moves.size())  if current.remaining\_cards.is\_empty(): 

 continue 

 for i in current.remaining\_cards.size(): 

 var card := current.remaining\_cards\[i\] 

 for pos in \_get\_valid\_positions(current.terrain, card):  var new\_terrain := \_apply\_card(current.terrain.duplicate(), card, pos)  var new\_cards := current.remaining\_cards.duplicate()  new\_cards.remove\_at(i) 

 var new\_state := PuzzleState.new(new\_terrain, new\_cards,  current.moves \+ \[\[card.type, pos\]\]) 

 if not visited.has(new\_state.hash\_key()): 

 visited\[new\_state.hash\_key()\] \= true 

 queue.push\_back(new\_state) 

 return SolverResult.new(false, \[\], 0\)

Run validation across all 130 levels in CI: 

\# scripts/validate\_all\_levels.gd 

extends SceneTree 

func \_init(): 

 var passed: int \= 0 

 var failed: int \= 0 

 for world in range(1, 7): 

 var dir := DirAccess.open("res://levels/world%d" % world) 

 dir.list\_dir\_begin() 

 var file := dir.get\_next() 

 while file \!= "": 

 if file.ends\_with(".json"): 

 var level := LevelLoader.load\_from\_json( 

 "res://levels/world%d/%s" % \[world, file\]) 

 var result := PuzzleSolver.new(level).solve() 

 if result.is\_solvable: 

 passed \+= 1 

 else: 

 printerr("FAIL: world%d/%s unsolvable\!" % \[world, file\])  failed \+= 1   
 file \= dir.get\_next() 

 print("Validation: %d passed, %d failed" % \[passed, failed\])  quit(1 if failed \> 0 else 0\) 

Difficulty metrics computed per level: minimum solution length, solution tree width (fewer valid moves \= harder), number of distinct solutions (unique solution \= hardest), required mechanic combos (multi-card chains), and dead-end density (wrong placements leading to unsolvable states). 

LDtk for level design 

LDtk (ldtk.io, created by the director of Dead Cells, MIT license) is ideal for “Whether.” Its IntGrid layers map directly to terrain types ( DRY\_GRASS=1, WET\_GRASS=2, ICE=3 ), its entity system handles card spawn points and goal states, and its enum support maps to weather types. Levels are stored as pure JSON that AI agents can generate and modify programmatically. 

The godot-ldtk-importer (github.com/heygleeson/godot-ldtk-importer) imports .ldtk files directly as Godot scenes with auto-reload on save. Use LDtk for visual level design and iteration, while also maintaining the JSON as the solver’s input format. 

AI agents generate level candidates by producing IntGrid arrays and card sets matching difficulty targets, then the solver validates solvability automatically. This pipeline — AI proposes, solver validates, human polishes — can produce 5–10 validated levels per hour compared to pure manual design. 

CI/CD pipeline 

godot-ci (github.com/abarichello/godot-ci, 1,100 stars) provides Docker images with Godot pre-installed for GitHub Actions. The pipeline: 

\# .github/workflows/ci.yml 

name: Whether CI 

on: 

 push: 

 branches: \[main, develop\] 

 pull\_request: 

 branches: \[main\] 

jobs: 

 test: 

 runs-on: ubuntu-latest 

 container: 

 image: barichello/godot-ci:4.6 

 steps:  
 \- uses: actions/checkout@v4 

 \- name: Import assets 

 run: godot \--headless \--import \--quit || true 

 timeout-minutes: 3 

 \- name: Run GUT tests 

 run: | 

 godot \--headless \-s addons/gut/gut\_cmdln.gd \\ 

 \-gdir=res://test \-gexit \\ 

 \-gjunit\_xml\_file=results/gut\_results.xml 

 timeout-minutes: 10 

 \- name: Validate all levels 

 run: godot \--headless \-s scripts/validate\_all\_levels.gd \--quit  timeout-minutes: 15 

 export: 

 needs: test 

 runs-on: ubuntu-latest 

 container: 

 image: barichello/godot-ci:4.6 

 strategy: 

 matrix: 

 platform: \[windows, linux, android\] 

 steps: 

 \- uses: actions/checkout@v4 

 \- name: Build 

 run: | 

 mkdir \-p build/${{ matrix.platform }} 

 godot \--headless \--export-release \\ 

 "${{ matrix.platform }}" build/${{ matrix.platform }}/Whether  \- uses: actions/upload-artifact@v4 

 with: 

 name: whether-${{ matrix.platform }} 

 path: build/${{ matrix.platform }} 

Steam deployment uses game-ci/steam-deploy@v3 triggered on version tags. Android signing via base64-encoded keystore in GitHub Secrets. iOS requires a macOS runner plus Fastlane. 

Art and audio: the fastest pipelines 

Art: Use Midjourney ($10/mo) or Stable Diffusion (free, local) for concept art and reference images, then create actual pixel art tiles in Aseprite ($20 one-time, github.com/aseprite/aseprite, 30k+ stars). AI pixel art still needs heavy manual cleanup for production use — treat AI output as reference, not final assets. Lock a strict 32-color palette and fixed canvas sizes (16×16 tiles, 32×32 icons) for style consistency.  
Audio: ElevenLabs Creator ($22/mo) covers both SFX and music with clear commercial licensing and full API access. Generate weather sounds with prompts like “gentle rain pattering on window, loopable” and “distant rolling thunder, dramatic.” Use jsfxr (sfxr.me, free) for retro UI interaction sounds. Import as .ogg for music, .wav for SFX. Create three Godot AudioBus channels: Master → Music, SFX, Ambient. 

Total first-month tooling cost: \~$336 (mostly one-time fees for Aseprite, Steam Direct, Apple Developer, Google Play). 

6\. Week 1 setup: everything to do on Monday morning Day 1: Foundation (4 hours) 

\# 1\. Create the repo 

mkdir whether-game && cd whether-game 

git init && git branch \-M main 

\# 2\. Install Godot 4.6 

\# macOS: brew install \--cask godot 

\# Verify: godot \--version 

\# 3\. Create Godot project 

godot \--path . \--headless \--quit \# generates project.godot 

\# Open in Godot editor, configure: 2D, mobile preset,  

\# Project Settings → Display → Window → 1080x1920 portrait 

\# 4\. Set up Cursor 

\# Install Cursor from cursor.com ($20/mo Pro) 

\# Open project in Cursor 

\# Install GitHub Copilot extension (disable inline completions,  \# keep for chat/review only) 

\# 5\. Create toolkit structure 

mkdir \-p .cursor/{rules,skills,commands} 

mkdir \-p .claude/agents 

mkdir \-p docs scripts test levels/{world1,world2,world3,world4,world5,world6} mkdir \-p scenes/{grid,ui,weather,levels} scripts/{grid,weather,ui,core} mkdir \-p assets/{sprites,audio/{sfx,music},fonts} 

mkdir \-p .github/workflows 

\# 6\. Copy in all config files from whether-kit  

\# (rules, skills, CLAUDE.md, mcp.json, CI workflows — all defined above)  
\# 7\. Install GUT 

\# In Godot: AssetLib → search "GUT" → download → install to addons/gut/ \# Create .gutconfig.json: 

echo '{"dirs": \["res://test/"\], "prefix": "test\_", "suffix": ".gd"}' \> .gutconfig.json 

\# 8\. Install LDtk 

\# Download from ldtk.io, create whether.ldtk project in levels/ 

\# 9\. Set up Linear 

\# Create workspace at linear.app (free tier) 

\# Create team "Whether Dev" 

\# Configure states: Triage → Backlog → Todo → In Progress → In Review → Done \# Add labels (all workstream labels listed in section 4\) 

\# 10\. Connect MCP servers 

claude mcp add \--transport http linear-server https://mcp.linear.app/mcp \# Cursor: add mcp.json config (shown above) 

\# 11\. Install orchestration 

\# macOS: Download Conductor from conductor.build 

\# Or: brew install claude-squad 

\# 12\. Generate the backlog 

claude \# Start Claude Code 

\# Prompt: "Read docs/GDD.md, generate complete Linear backlog using  \# Linear MCP. Create all projects, issues, and sub-issues."

Day 2: First parallel agent run (6 hours) 

\# Spawn 3 agents on non-overlapping systems: 

\# Agent 1: Core grid system 

claude \--worktree grid-system \--tmux 

\# "Implement GridManager (scripts/grid/grid\_manager.gd): 

\# \- Variable-size grid stored as flat Array\[int\] 

\# \- Terrain enum, get/set terrain, neighbor lookup 

\# \- Card placement validation 

\# \- Write 10 GUT tests in test/test\_grid\_system.gd" 

\# Agent 2: Weather card system  

claude \--worktree weather-cards \--tmux 

\# "Implement WeatherCard Resource and WeatherSystem  

\# (scripts/weather/): 

\# \- WeatherCard resource with type enum and effect rules 

\# \- Weather interaction matrix (rain→wet, frost+wet→ice, etc.) 

\# \- Write tests in test/test\_weather\_cards.gd"   
\# Agent 3: Puzzle solver 

claude \--worktree solver \--tmux 

\# "Implement BFS puzzle solver (scripts/puzzle\_solver.gd): 

\# \- State representation with terrain \+ remaining cards 

\# \- BFS with visited state hashing 

\# \- SolverResult with is\_solvable, min\_moves, solution path 

\# \- Write tests with hand-crafted 3x3 test levels" 

Days 3–5: Build outward 

Day 3: Level loader (reads LDtk JSON), basic scene rendering, first 5 tutorial levels hand-designed in LDtk 

Day 4: Input system (touch \+ mouse), card placement UI, undo/redo, level complete detection 

Day 5: World 1 levels 6–22 (AI-generated \+ solver-validated), main menu, world select Agent role assignments

| Agent Role  | Scope  | Tools  | Trigger |
| ----- | ----- | :---- | ----- |
| Gameplay  Programmer | scripts/grid/ ,  scripts/weather/ ,  scripts/core/ | Claude Code  worktree | Linear tickets  labeled Core  Engine |
| UI  Developer | scripts/ui/ , scenes/ui/ ,  assets/ui/ | Claude Code  worktree | Linear tickets  labeled UI-UX |
| Level  Designer | levels/ ,  scripts/level\_loader.gd | Claude Code  \+ LDtk JSON  gen | Linear tickets  labeled Level  Design |
| QA Agent | test/ ,  scripts/validate\_all\_levels.gd | Claude Code  worktree \+  GUT | After each  merge to main |
| Producer  | Linear backlog, docs/ | Claude Code  \+ Linear MCP | Daily standup,  weekly planning |
| Art Pipeline  | assets/sprites/ | Midjourney \+  Aseprite  (manual) | Parallel to code  development |

Daily workflow summary 

8:00 AM — Producer standup (5 min): Ask the producer agent via Claude Code: “Generate today’s standup. What shipped yesterday, what’s next, any blockers?” It reads Linear via MCP and reports. 

8:05 AM — Task selection (10 min): Pick 3 parallelizable tickets from Todo. Verify non overlapping file scopes. Write one-paragraph specs. 

8:15 AM — Agent dispatch (5 min): Spawn 3 worktree agents with specs. Open Conductor/Claude Squad to monitor. 

8:20 AM–12:00 PM — Work in parallel: You work on one task directly in Cursor while 2 agents run autonomously. Check in every 30–60 minutes. 

12:00 PM — Midday merge (30 min): Review completed agent work. Run tests. Merge to main. Dispatch afternoon agents. 

1:00 PM–5:00 PM — Second agent batch \+ integration: New parallel tasks \+ integration testing across merged systems. 

5:00 PM — End-of-day review (15 min): Merge remaining work. Update Linear. Ask producer: “What’s our velocity this week? Any risks?” 

5:15 PM — Fire overnight agents (5 min): Start Cursor background agents for documentation, test generation, or level batch creation. 

Metrics to track 

Sprint velocity: story points completed per weekly cycle (target: increasing for first 4 cycles, then stable) 

Levels validated: N/130 passing solver (the single most important progress metric) Test coverage: GUT tests passing / total (target: 90%+ for core systems) 

Agent merge rate: PRs merged without revision vs. needing human fixes (target: \>70% clean merges) 

Difficulty curve compliance: all levels within ±1 difficulty band of target curve Build health: CI green on main at all times 

What’s uncertain and what to watch 

GDScript vs C\# is a real tradeoff. Godogen’s shift to C\# reflects genuine LLM performance differences — Claude and GPT produce fewer hallucinations with C\#. However, for a solo dev who’s already committed to GDScript, the switching cost (learning .NET  
Godot, C\# Godot API differences, potential plugin compatibility issues) likely outweighs the LLM accuracy gains. Mitigate by using strict typing everywhere and comprehensive .cursorrules that encode GDScript-specific patterns. Monitor agent error rates in the first week; if GDScript hallucinations exceed 30% of generated code, consider switching. 

Cursor’s background agents are brand new (February–April 2026). They work but are still maturing. **Whether repo default:** **local** parallelism — multiple Cursor windows on **git worktrees** (`pwsh ./tools/tasks/new-agent-worktree.ps1`); Cursor Cloud is **not** self-hosted. If cloud agents are throttled, rely on local worktrees and/or Claude Code with worktrees — same scope rules in `.claude/CLAUDE.md`. 

130 levels is genuinely massive for a solo dev. The producer agent’s most important job is tracking levels/week velocity and flagging burnout risk early. Consider reducing to 80–100 levels if the pace isn’t sustainable — a polished 80-level game ships better than an exhausted 130-level game. 

The tools and workflows described here represent the best available stack for shipping a multi-platform indie puzzle game with AI assistance in 2026\. The key advantage isn’t any single tool — it’s the system: parallel agents with non-overlapping scopes, automated level validation ensuring you never ship an unsolvable puzzle, a producer agent that never forgets a workstream, and a CI pipeline that catches regressions before they compound. Execute this blueprint and you’ll have a playable first world within two weeks.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAYAAAA7bUf6AAABTklEQVR4Xq2Tv0vDQBTHr1TtDW1jk0uaqYto0VVEqqiTIHTR1cX/wwpKdVE3oYrSVVJwdPAXUqST3Zykblm6OAgVh5rC877Bk4CIacmDD3e89/286Y6xQA1L1jifqWhaFTRyuVYzn3/DqXqYI/erZHMIlFOp/ZdC4fNjq0TAO6lQ7+zUP1UPc+SUE90SeYntptMHoL2yTN2dEnW3N/9GzpGT+UMAn61yPvc8NemBzsY6vYcAOeXAZ442et6enSbwujQfGuXAj2ZJ3TRdd3yMfCb64NupW5bLHkyz07JtGhT47EYI9ymbpUGBz6q67jxaFoFmHygHfjRLionEwp0QPdAwTQqLcuDj3cb2kskjcCsE3cvAfyCnHPj+07fj8RFQls1Lw/CuZAhcB1A9zJFTzs8HjGSJKnymIueLx5mMA2q67l4YRgen6mHuf7pAfQEtpu7JmyZ5NAAAAABJRU5ErkJggg==>

[image2]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAYAAAA7bUf6AAABTklEQVR4Xq2Tv0vDQBTHr1TtDW1jk0uaqYto0VVEqqiTIHTR1cX/wwpKdVE3oYrSVVJwdPAXUqST3Zykblm6OAgVh5rC877Bk4CIacmDD3e89/286Y6xQA1L1jifqWhaFTRyuVYzn3/DqXqYI/erZHMIlFOp/ZdC4fNjq0TAO6lQ7+zUP1UPc+SUE90SeYntptMHoL2yTN2dEnW3N/9GzpGT+UMAn61yPvc8NemBzsY6vYcAOeXAZ442et6enSbwujQfGuXAj2ZJ3TRdd3yMfCb64NupW5bLHkyz07JtGhT47EYI9ymbpUGBz6q67jxaFoFmHygHfjRLionEwp0QPdAwTQqLcuDj3cb2kskjcCsE3cvAfyCnHPj+07fj8RFQls1Lw/CuZAhcB1A9zJFTzs8HjGSJKnymIueLx5mMA2q67l4YRgen6mHuf7pAfQEtpu7JmyZ5NAAAAABJRU5ErkJggg==>

[image3]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAYAAAA7bUf6AAABRklEQVR4Xq2TQSgEcRTGv0GzF5SUkxIXB3LlYPes5OioTYomq0U5DBcnF0WmOKrlMDmuuLqZKCVrHdgcRokkaS7SjJ79pv2vPTG2efXr1Xvf7zVTM0BNJZqgGcNIXZiaTR4329znnU6PXc24Z67WC6unHTo5NDTrLdfvfzoLQoLCunwVN8KuZtwzp5z4jiQaoeVnYBHvYFB8JyP+6S+U98wphz6mh5B82e4IyMfxiERFOfThZGG/73YJ8fZ7I6Mc+vEcKa3Afd1qlhCrJToVhz5KJrynNUi93JV9FBfhPqxC6oU+TtKw701IyPI/qDj04zmSHkCyOI+A3C5BoqIc+tAboO2NwSLXc5Cb7N8wpxz64aff3Qqd5EZhXRrwr2YhpJD5Qc24Z0451R8wliOq+GgTfUgdjcMmZ5Nwz6fgsasZ99VXqNQ3vXBJvwIG5t0AAAAASUVORK5CYII=>

[image4]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAYAAAA7bUf6AAABRklEQVR4Xq2TQSgEcRTGv0GzF5SUkxIXB3LlYPes5OioTYomq0U5DBcnF0WmOKrlMDmuuLqZKCVrHdgcRokkaS7SjJ79pv2vPTG2efXr1Xvf7zVTM0BNJZqgGcNIXZiaTR4329znnU6PXc24Z67WC6unHTo5NDTrLdfvfzoLQoLCunwVN8KuZtwzp5z4jiQaoeVnYBHvYFB8JyP+6S+U98wphz6mh5B82e4IyMfxiERFOfThZGG/73YJ8fZ7I6Mc+vEcKa3Afd1qlhCrJToVhz5KJrynNUi93JV9FBfhPqxC6oU+TtKw701IyPI/qDj04zmSHkCyOI+A3C5BoqIc+tAboO2NwSLXc5Cb7N8wpxz64aff3Qqd5EZhXRrwr2YhpJD5Qc24Z0451R8wliOq+GgTfUgdjcMmZ5Nwz6fgsasZ99VXqNQ3vXBJvwIG5t0AAAAASUVORK5CYII=>

[image5]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAYAAAA7bUf6AAABRUlEQVR4Xq2TwSsEYRjGnyl2T8qJ4uAkyt1t9+AgNwd/hEJRjvIHqEXNydFtcpQoF0pNS4lkN9E6zGGlkN1x2Jjxvb5n8m57kWmbt3599b7P7+37agboqHwPnPkpFC9Ljkfqe/3B8/5QyFN7nDPX6SU1OogcOVhz3IY/EUX1ZSHmfUNMo5Sc2uOcOXWyW8KrHa7DJa3KpJiXJZHXxT/hnDl1kqctTKPwUR6IiXmaEUkBc+rQR3UHXlwbESLBWGrUoZ/NkrcjJzC1PiHymB516KN5glDuId1CH81jBHJnG11CHw+78EwFQqSaHnXoZ7NkZRaFrwvERG5tICXq0Ee+F46/CZd8X9nAzf8w529Zx0I/+fTHh5Ej5W240Tkic22vapEOtMc5c+q0f8BMlmjxaqtzKAYePNI6RfB5hpCn9jhvP+G3fgB2CqFiOpHw6gAAAABJRU5ErkJggg==>

[image6]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAYAAAA7bUf6AAABRUlEQVR4Xq2TwSsEYRjGnyl2T8qJ4uAkyt1t9+AgNwd/hEJRjvIHqEXNydFtcpQoF0pNS4lkN9E6zGGlkN1x2Jjxvb5n8m57kWmbt3599b7P7+37agboqHwPnPkpFC9Ljkfqe/3B8/5QyFN7nDPX6SU1OogcOVhz3IY/EUX1ZSHmfUNMo5Sc2uOcOXWyW8KrHa7DJa3KpJiXJZHXxT/hnDl1kqctTKPwUR6IiXmaEUkBc+rQR3UHXlwbESLBWGrUoZ/NkrcjJzC1PiHymB516KN5glDuId1CH81jBHJnG11CHw+78EwFQqSaHnXoZ7NkZRaFrwvERG5tICXq0Ee+F46/CZd8X9nAzf8w529Zx0I/+fTHh5Ej5W240Tkic22vapEOtMc5c+q0f8BMlmjxaqtzKAYePNI6RfB5hpCn9jhvP+G3fgB2CqFiOpHw6gAAAABJRU5ErkJggg==>

[image7]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAYAAAA7bUf6AAABSklEQVR4XmNgQAZMrAws6v6mnN6T5oCweMaBmwoFx9+DaJgYSB6kDhMwsbKAMJtDfadB/dVfZRs//AfhiYe//5969AeYhomB5EHqYHqoaAgTKyOLfUMXCFt33f9ftunD/1I8GCRv3X3/P1B9NwiD9DMwqPlZSRZe+A3CgbNf/A+Y/ZIgBqmD6QHpZ2DwXbJUuebufxDWaX5INIbpAemnjiGMobsf8mff+g/GOSRgqB6QfgaGoD2fGGIu/ycbg/QzeG15yBBy5j/ZGKSfwWbmcgafI//B2Pco8RimB6SfOoZIe9kyOG/7A8Zu+/4TjWF6QPoZGFkYGfQbJ4Gx/db/DA47CGOQOpgekH4w4JRgA2Od+kkMlut+M1ht+g/G1psRGCYGkgepg+mBA6oYAgMgp4l72DHoTVoOxsZLHjKYLPsEpmFiIHm4FyAAALOBDiDgAWnMAAAAAElFTkSuQmCC>

[image8]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAYAAAA7bUf6AAABSklEQVR4XmNgQAZMrAws6v6mnN6T5oCweMaBmwoFx9+DaJgYSB6kDhMwsbKAMJtDfadB/dVfZRs//AfhiYe//5969AeYhomB5EHqYHqoaAgTKyOLfUMXCFt33f9ftunD/1I8GCRv3X3/P1B9NwiD9DMwqPlZSRZe+A3CgbNf/A+Y/ZIgBqmD6QHpZ2DwXbJUuebufxDWaX5INIbpAemnjiGMobsf8mff+g/GOSRgqB6QfgaGoD2fGGIu/ycbg/QzeG15yBBy5j/ZGKSfwWbmcgafI//B2Pco8RimB6SfOoZIe9kyOG/7A8Zu+/4TjWF6QPoZGFkYGfQbJ4Gx/db/DA47CGOQOpgekH4w4JRgA2Od+kkMlut+M1ht+g/G1psRGCYGkgepg+mBA6oYAgMgp4l72DHoTVoOxsZLHjKYLPsEpmFiIHm4FyAAALOBDiDgAWnMAAAAAElFTkSuQmCC>

[image9]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAYAAAA7bUf6AAABRklEQVR4Xq2TQSgEcRTGv0GzF5SUkxIXB3LlYPes5OioTYomq0U5DBcnF0WmOKrlMDmuuLqZKCVrHdgcRokkaS7SjJ79pv2vPTG2efXr1Xvf7zVTM0BNJZqgGcNIXZiaTR4329znnU6PXc24Z67WC6unHTo5NDTrLdfvfzoLQoLCunwVN8KuZtwzp5z4jiQaoeVnYBHvYFB8JyP+6S+U98wphz6mh5B82e4IyMfxiERFOfThZGG/73YJ8fZ7I6Mc+vEcKa3Afd1qlhCrJToVhz5KJrynNUi93JV9FBfhPqxC6oU+TtKw701IyPI/qDj04zmSHkCyOI+A3C5BoqIc+tAboO2NwSLXc5Cb7N8wpxz64aff3Qqd5EZhXRrwr2YhpJD5Qc24Z0451R8wliOq+GgTfUgdjcMmZ5Nwz6fgsasZ99VXqNQ3vXBJvwIG5t0AAAAASUVORK5CYII=>

[image10]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAYAAAA7bUf6AAABRUlEQVR4Xq2TwSsEYRjGnyl2T8qJ4uAkyt1t9+AgNwd/hEJRjvIHqEXNydFtcpQoF0pNS4lkN9E6zGGlkN1x2Jjxvb5n8m57kWmbt3599b7P7+37agboqHwPnPkpFC9Ljkfqe/3B8/5QyFN7nDPX6SU1OogcOVhz3IY/EUX1ZSHmfUNMo5Sc2uOcOXWyW8KrHa7DJa3KpJiXJZHXxT/hnDl1kqctTKPwUR6IiXmaEUkBc+rQR3UHXlwbESLBWGrUoZ/NkrcjJzC1PiHymB516KN5glDuId1CH81jBHJnG11CHw+78EwFQqSaHnXoZ7NkZRaFrwvERG5tICXq0Ee+F46/CZd8X9nAzf8w529Zx0I/+fTHh5Ej5W240Tkic22vapEOtMc5c+q0f8BMlmjxaqtzKAYePNI6RfB5hpCn9jhvP+G3fgB2CqFiOpHw6gAAAABJRU5ErkJggg==>

[image11]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAYAAAA7bUf6AAABRUlEQVR4Xq2TwSsEYRjGnyl2T8qJ4uAkyt1t9+AgNwd/hEJRjvIHqEXNydFtcpQoF0pNS4lkN9E6zGGlkN1x2Jjxvb5n8m57kWmbt3599b7P7+37agboqHwPnPkpFC9Ljkfqe/3B8/5QyFN7nDPX6SU1OogcOVhz3IY/EUX1ZSHmfUNMo5Sc2uOcOXWyW8KrHa7DJa3KpJiXJZHXxT/hnDl1kqctTKPwUR6IiXmaEUkBc+rQR3UHXlwbESLBWGrUoZ/NkrcjJzC1PiHymB516KN5glDuId1CH81jBHJnG11CHw+78EwFQqSaHnXoZ7NkZRaFrwvERG5tICXq0Ee+F46/CZd8X9nAzf8w529Zx0I/+fTHh5Ej5W240Tkic22vapEOtMc5c+q0f8BMlmjxaqtzKAYePNI6RfB5hpCn9jhvP+G3fgB2CqFiOpHw6gAAAABJRU5ErkJggg==>

[image12]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAYAAAA7bUf6AAABSklEQVR4XmNgQAZMrAws6v6mnN6T5oCweMaBmwoFx9+DaJgYSB6kDhMwsbKAMJtDfadB/dVfZRs//AfhiYe//5969AeYhomB5EHqYHqoaAgTKyOLfUMXCFt33f9ftunD/1I8GCRv3X3/P1B9NwiD9DMwqPlZSRZe+A3CgbNf/A+Y/ZIgBqmD6QHpZ2DwXbJUuebufxDWaX5INIbpAemnjiGMobsf8mff+g/GOSRgqB6QfgaGoD2fGGIu/ycbg/QzeG15yBBy5j/ZGKSfwWbmcgafI//B2Pco8RimB6SfOoZIe9kyOG/7A8Zu+/4TjWF6QPoZGFkYGfQbJ4Gx/db/DA47CGOQOpgekH4w4JRgA2Od+kkMlut+M1ht+g/G1psRGCYGkgepg+mBA6oYAgMgp4l72DHoTVoOxsZLHjKYLPsEpmFiIHm4FyAAALOBDiDgAWnMAAAAAElFTkSuQmCC>

[image13]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAYAAAA7bUf6AAABRUlEQVR4Xq2TwSsEYRjGnyl2T8qJ4uAkyt1t9+AgNwd/hEJRjvIHqEXNydFtcpQoF0pNS4lkN9E6zGGlkN1x2Jjxvb5n8m57kWmbt3599b7P7+37agboqHwPnPkpFC9Ljkfqe/3B8/5QyFN7nDPX6SU1OogcOVhz3IY/EUX1ZSHmfUNMo5Sc2uOcOXWyW8KrHa7DJa3KpJiXJZHXxT/hnDl1kqctTKPwUR6IiXmaEUkBc+rQR3UHXlwbESLBWGrUoZ/NkrcjJzC1PiHymB516KN5glDuId1CH81jBHJnG11CHw+78EwFQqSaHnXoZ7NkZRaFrwvERG5tICXq0Ee+F46/CZd8X9nAzf8w529Zx0I/+fTHh5Ej5W240Tkic22vapEOtMc5c+q0f8BMlmjxaqtzKAYePNI6RfB5hpCn9jhvP+G3fgB2CqFiOpHw6gAAAABJRU5ErkJggg==>

[image14]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABJ0lEQVR4Xq2TsUrDUBSGby8UNHcpzc29NdhXqIgKgi/h4iYiVERRcLGDzyBu4iKuLnEpDgpSlRbN0m6ubqLoEDqKCMf7B45kqYTGA99w8n//gUAiRGZqUk7seF7zMgw7oN9ovAPekcHJdtIJpZwCFzV7/7G2Sl9HhynfJ8cpvCOLnMP+/xywUk5G1nTBcGOdPg9ajv0RtAiOc3sAXbGn1PbL0iKB4cpyLthHV9wE+vF1bobA28JsLthHt/iBnjHJc32axgFdcad18mQtjQO6oq113DeGwCAn7Ld9Py5+YEup3W4QEHjICfvoClMqeWeVSgw6WtOtC/4CDvvopl/jfLlcB6fu4ZUTrkeADA77v/9C4QM8Rkq16d7rvFqNQeT7CeAdGZxs5wfoHLqSSFDCfwAAAABJRU5ErkJggg==>

[image15]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABJklEQVR4XmNgQALyQgzcPYEMOQ+7eY+D8MuZSu9AGMYHyYHUIOsBAy8dBlkQPl/HefzrtqD/v881gvGfS51gDOOD5M7XcR2HqaeOAfICDFznqtmPg/D3HYH/fx1OxYtBamDqQXoZOrwZct4vUP0Pwt/W2xGFYeo7fBhyGG5VMx5/P1vqPwh/mCtDFIapB+ml3IA7tQzvXnWz/icH3wXqZbhRzvDuSRPDf3IwSC/DxRyG4/drGP6Tg0F6KTeg3p4h50YJ0DlAfKuMOAxT3wDUyyDDy8C1K5bhOAhfLWD4f40ABqnZDVQLwiC94NToLssgC8I7oxiOX8xm+H8pBzsGyYHUwNTD8wLFBsCADA8Dd40VQ87ReIbjIHwymeEdCMP4IDmQGmQ9AAOeDIg5NDvGAAAAAElFTkSuQmCC>