Building “Whether”: a weather-powered puzzle game from zero to launch 

Your game should be a grid-based weather-sequencing puzzle called “Whether.” The core mechanic: players choose the order and placement of weather events — rain, sun, wind, frost, lightning, fog — to transform a tile grid and open a path from start to goal. Each weather element physically changes the boarpowd through state transitions (water freezes to ice bridges, sun evaporates water to steam platforms, wind pushes objects). The “whether/weather” wordplay lives in the core loop: every puzzle is a decision about *whether* to deploy each weather card and *when*. Build it in Godot 4.6 with GDScript, develop in Cursor with the godot-tools extension and a Godot MCP server, and target Steam first, then iOS and Android. Below is everything you need to make this real. 

The puzzle game landscape reveals a clear blueprint 

After analyzing 30+ successful puzzle games from the last decade, a striking pattern emerges: solo developers and two-person teams built nearly every critically acclaimed puzzle game on this list. Baba Is You (solo), Return of the Obra Dinn (solo), 

Game Developer Patrick’s Parabox (solo), Wikipedia Hexcells (solo), Monument Valley (8 people), Android Authority Mini Metro (2 people), Gorogoa (solo artist), A Good Snowman (2 people). The barrier to entry is design skill, not production scale. 

The commercially successful puzzle games share four traits. First, one original mechanic explored exhaustively — Monument Valley’s impossible geometry, Baba Is You’s rule pushing, Intel Gaming The Witness’s line-drawing — none add mechanics for variety, they deepen existing ones. Second, art that IS the mechanic — Monument Valley’s Escher geometry, Wikipedia Gorogoa’s layered illustrations, and Obra Dinn’s 1-bit rendering 

Wikipedia Game Developer aren’t decorative, they’re functional. Third, touch-native interactions succeed on mobile — swiping (Cut the Rope, Threes), drawing paths (Mini Metro, Where’s My Water), and drag-and-drop (World of Goo, Steam Unpacking) leverage what touchscreens do best. Fourth, game jam origins validate ideas cheaply — Baba Is You started at Nordic Game Jam, Steam Wikipedia Bonfire Peaks at Ludum Dare 43, 

Wikipedia Mini Metro at Ludum Dare 26, Wikipedia A Good Snowman as a PuzzleScript prototype. Wikipedia 

The commercial data is instructive. Monument Valley earned $14M+ on a $1.4M budget.  
PocketGamer Mini Metro sold 6 million copies PocketGamer from a 2-person team. The Room series hit 11.6 million downloads with the first game budgeted at just £160K. PocketGamer Unpacking sold over 1 million copies in its first year. GameRant 2 On the premium side, $5–$20 price points dominate Steam indie puzzles, while mobile splits between premium (rare but proven for high-quality games) and free-to-play with ads/IAP. The smartest approach for an indie today: premium on Steam ($8–$15), premium on iOS ($4–$6), and consider Apple Arcade or Netflix Games for mobile reach. 

Weather mechanics have been underexplored in puzzle games. Where’s My Water proved fluid physics are compelling on touch MobyGames (100M+ downloads). Pocket Gamer Fluidity/Hydroventure demonstrated water-ice-steam state changes as a full puzzle system. 

Wikipedia Rain on Your Parade showed weather abilities (rain, snow, wind, lightning) as puzzle tools. The Escapist Breath of the Wild’s weather system — where rain prevents climbing, lightning targets metal, and wind enables gliding — proved weather can transform gameplay rules, not just atmosphere. ScreenRant No existing puzzle game has made weather-sequencing its core mechanic. This is the gap. 

“Whether”: weather sequencing as puzzle mechanic 

The core concept 

Each puzzle presents a grid-based tile board with terrain (earth, water basins, stone, vegetation), objects (crates, mirrors, conductors, seeds), a start position, and a goal. The player receives a hand of weather cards — typically 3–5 per puzzle — and must decide the order and grid placement to deploy them. Each weather event physically transforms the board: 

Rain fills empty basins with water, extinguishes fire, makes slopes slippery, triggers plant growth on seeded tiles 

Sun evaporates water into steam (which rises and creates temporary floating platforms), melts ice, ignites dry vegetation, casts shadows from tall objects 

Frost freezes water into walkable ice bridges, makes surfaces brittle, slows spreading fire, preserves objects in place 

Wind pushes lightweight objects in a cardinal direction, disperses fog and steam, carries seeds to new tiles, fans flames to spread fire 

Lightning powers mechanical switches, splits large objects, chains through water (electrifying connected water tiles), shatters ice  
Fog obscures a region of the grid (hiding what’s there until another weather clears it), dampens sound-based mechanics, creates uncertainty 

The “whether” layer: You see your weather cards but not always what’s underneath fog tiles or behind objects. You must decide *whether* to commit each card and *where* to target it before seeing the full consequences unfold. Early puzzles are deterministic (perfect information), but later puzzles introduce fog-covered tiles that force genuine decisions under uncertainty — the “whether” in “whether weather.” 

Why this works 

One mechanic, infinite depth. The weather-sequencing system generates enormous combinatorial space from simple rules. Rain → Frost creates ice bridges. Sun → Rain creates steam then refills. Wind → Lightning creates devastating chain reactions through pushed objects. With 6 weather types and order-dependent interactions, the design space is vast while every individual element is intuitive. 

Touch-native input. The interaction is: (1) tap a weather card from your hand, (2) tap or swipe the grid to aim it. This is the simplest possible input — two taps per action. It works identically on touch screens and mouse. No timing, no reflexes, no pixel precision. 

Inherently beautiful. Weather effects are visually spectacular by nature. Rain particles, frost crystallization, lightning bolts, fog rolling in, sun breaking through clouds — these create atmospheric moments that screenshot beautifully and market themselves. A minimalist art style (clean tile art with expressive particle effects) is achievable solo with AI art assistance. 

Clear progression ladder. Introduce one weather element per world. World 1 is Rain-only (routing water). World 2 adds Sun (evaporation and steam). World 3 adds Frost (state changes). Each subsequent world layers in one more element until the final world uses all six. This mirrors the proven structure of Cut the Rope’s “boxes,” The Room’s chapters, and Baba Is You’s worlds. 

Level design framework 

World 1 — “Downpour” (Rain only, 15 levels): Route rainwater through terrain to fill a reservoir and float a boat to the exit. Teaches basins, water flow, and the basic card targeting mechanic. 

World 2 — “Heatwave” (Rain  Sun, 15 levels): Create water with rain, then evaporate it with sun to make steam platforms. Navigate a character across gaps using timed evaporation. Introduces the critical concept that order matters. 

World 3 — “Cold Snap” (Rain  Sun  Frost, 20 levels): Freeze water into ice bridges,  
melt ice with sun, refreeze. Build and destroy paths dynamically. This is where the puzzle depth opens up. 

World 4 — “Gale Force” (adds Wind, 20 levels): Push objects into position before applying other weather. Wind disperses steam (destroying platforms) and spreads seeds for rain-activated plant bridges. 

World 5 — “Thunderstorm” (adds Lightning, 20 levels): Power mechanisms, chain electricity through water, shatter ice to create new paths. Lightning  Water is dangerous (electrifies connected tiles); Lightning  Ice shatters it. Risk-reward decisions intensify. 

World 6 — “Whiteout” (adds Fog, full toolkit, 20 levels): Fog hides tiles, forcing genuine “whether” decisions. Do you burn a Sun card to clear fog, or save it for later evaporation? Information management becomes the meta-puzzle. 

Bonus World — “Climate Change” (20 levels): Remixed mechanics, paradox levels, community favorites. Post-launch content to sustain interest. 

Total: 130 levels, comparable to premium puzzle games like Baba Is You (200 levels) Steam Wikipedia and Snakebird (53 levels). Wikipedia Brianhamrick Target 2–4 minutes per level for mobile session lengths, with later levels taking up to 10 minutes. 

Monetization strategy 

Steam: Premium at $9.99. This hits the sweet spot for indie puzzle games (Hexcells at $3, Patrick’s Parabox at $20, GG.deals Baba Is You at $15). Steambase Include a level editor for community content and longevity. 

iOS: Premium at $4.99. No IAP, no ads. Position alongside Monument Valley, Mini Metro, and The Room as a premium experience. Apply for Apple Design Award consideration — weather effects give you strong visual material. 

Android: Consider $2.99 premium or free with a single $3.99 unlock after World 1 (20 levels free, rest paid). Android users are more price-sensitive but will convert for quality. Adapty 

Alternative path: Apply to Netflix Games or Apple Arcade for guaranteed revenue regardless of download volume. Both platforms actively seek premium puzzle games. Daydreamsoft This eliminates the mobile monetization headache entirely. 

Runner-up concepts (briefly) 

Runner-up 1 — “Weather Words” (Baba Is You variant): Physical word blocks on a grid spell weather rules: “RAIN IS PUSH,” “SUN IS WIN,” “CLOUD IS YOU.” Players rearrange words to change how weather behaves. Extremely creative but extremely hard to design  
levels for — Baba Is You took years of iteration, and the designer is a proven genius. Too risky for a first game. 

Runner-up 2 — “Cloud Shepherd”: You play as wind, herding clouds across a landscape to create specific weather patterns over towns, farms, and forests. Each town needs different weather (rain for crops, sun for harvest, snow for ski season). Beautiful concept but the indirect control (pushing clouds rather than placing weather) makes touch input fiddly and puzzles harder to understand. 

Runner-up 3 — “Forecast” (Papers Please meets weather): You’re a weather forecaster reviewing atmospheric data (pressure maps, wind patterns, satellite imagery) and issuing forecasts that affect a town. Incorrect forecasts cause disasters; correct ones save lives. Fascinating theme but fundamentally a pattern-matching/deduction game rather than a spatial puzzle, which limits visual spectacle and touch interaction. 

“Whether” wins because it combines proven physics-puzzle touchscreen mechanics with a novel sequencing layer, has the clearest visual identity, is the most scopeable for a solo dev, and naturally supports the “whether/weather” wordplay. 

Godot 4.6 is the right engine, and it’s not close 

Use Godot 4.6 with GDScript. For this specific project — a 2D puzzle game built by a beginner game developer with deep mobile experience, developing in Cursor with AI assistance, targeting iOS/Android/Steam — Godot beats Unity on nearly every dimension that matters. 

Why Godot wins for you 

Godot’s 2D engine is purpose-built, not bolted on. Unity’s 2D is a projection layer on top of a 3D engine. Coding Quests Godot’s 2D has its own coordinate system, physics engine, particle system, and rendering pipeline. For a tile-based puzzle game, this means less configuration overhead, more intuitive behavior, and better performance on mobile. The TileMap system, GPUParticles2D for weather effects, and built-in 2D lighting for sun/shadow mechanics are exactly what “Whether” needs. 

AI writes better code for Godot than Unity. This is the decisive factor for an AI-assisted workflow. Godot scene files ( .tscn ) are 10-line human-readable text; Unity scenes are 60+ lines of GUID-heavy YAML that AI cannot parse. dev GDScript enforces one idiomatic way to accomplish each task; Unity C offers 4–5 competing patterns (MonoBehaviours, ScriptableObjects, ECS, dependency injection) that confuse AI models. dev Godot’s signal/scene-tree architecture is consistent and predictable — AI assistants can reason  
about your entire project. Multiple Godot MCP servers now let Claude and Cursor directly create scenes, add nodes, and capture debug output in your running editor. GitHub 3 

Cursor integration is first-class. Configure Godot to use Cursor as external editor in one settings change. UhiyamaLab The godot-tools VS Code extension provides full LSP support (code completion, go-to-definition, debugging with breakpoints). Oreate AI 

GitHub The Godot editor itself is 100MB and launches in 2–3 seconds itch.io — you’ll have it open alongside Cursor, not fighting it. Unity’s editor takes 30–60 seconds to launch, recompiles scripts on every change, and has no official Cursor support (community workarounds only). codingquests 

MIT license means zero risk. After Unity’s runtime fee debacle of 2023 — which they reversed after industry-wide backlash — many indie developers remain wary of building on a platform that could change terms. BairesDev codingquests Godot’s MIT license is permanent. No revenue share. No per-seat cost. No splash screen. No surprises. codingquests 

GDScript is the right language choice over C. Despite your programming background making C feel familiar, GDScript in Godot is the pragmatic pick. 84% of Godot developers use GDScript. Chickensoft It has the best documentation, the most tutorials, the strongest community support, and the most reliable export pipeline. C in Godot has experimental mobile exports, Godot Engine adds 30–60MB to binary size, and has a fraction of the learning resources. Strayspark GDScript’s Python-like syntax itch.io with optional type hints will feel natural to anyone who’s written Swift or Kotlin. Chickensoft You’ll be productive within days. 

Where Unity would have an edge (and why it doesn’t matter enough) 

Unity’s mobile monetization ecosystem is more mature — Unity Ads, IAP integration, and analytics are built-in. But for a premium puzzle game with no ads and no IAP (the recommended monetization strategy), this advantage evaporates. Unity’s Asset Store has more pre-built weather effect packages, Meshy but Godot has capable shader resources on godotshaders.com and open-source VFX libraries. codingquests Unity has more tutorials and community answers, but Godot’s community has grown explosively since 2023 Kevuru Games and AI assistance compensates for any documentation gaps. codingquests 

The one genuine risk: Godot’s mobile IAP plugins are poorly maintained. Godot Forum If you later decide to add in-app purchases on mobile, you’ll need to integrate third-party SDKs manually. For the recommended premium model, this is irrelevant. If you eventually want F2P mobile, consider porting the mobile version to Unity later — but build the core game in Godot first.  
Skip these alternatives 

Defold produces tiny binaries and has excellent mobile performance, but its Lua scripting has minimal AI training data and the community is small. Generalist Programmer GameMaker is beginner-friendly but its proprietary GML language has zero transferability and subscription pricing. revolgame-blogs Cocos Creator uses TypeScript but has stagnated outside Asia. revolgame-blogs Flutter Flame is natural for mobile devs but has no visual editor, no scene system, and no Steam export. LÖVE and PICO-8 are for prototyping and jams, not commercial releases. SpriteKit is Apple-only. None are competitive for your needs. 

Setting up Godot  Cursor for AI-powered development 

Initial setup (30 minutes) 

Install Godot 4.6.x from godotengine.org. Download the standard build (not the .NET/Mono build — you’re using GDScript). On macOS, drag to Applications. On Windows, extract anywhere. No installer needed. 

Configure Cursor as external editor. In the Godot editor: Editor → Editor Settings → Text Editor → External → Use External Editor (check). Set Exec Path to your Cursor executable ( /Applications/Cursor.app/Contents/MacOS/Cursor on macOS or C:Users usernameAppDataLocalProgramsCursorCursor.exe on Windows). UhiyamaLab Set Exec Flags to {project} -goto {file}:{line}:{col} . Medium Enable Auto Reload Scripts on External Change and Save on Focus Loss . GitHub 

Install the godot-tools extension in Cursor. Search for geequlim.godot-tools in the extensions panel. This provides GDScript LSP (code completion, go-to-definition, hover documentation, error checking), a full debugger (breakpoints, stepping, variable inspection), scene tree preview, DeepWiki and syntax highlighting for .gd , .tscn , .tres , and .gdshader files. Oreate AI GitHub 

Install a Godot MCP server for AI-editor integration. The most popular option is Coding Solo/godot-mcp (2,500 GitHub stars). Create .cursor/mcp.json in your project: 

{ 

 "mcpServers": { 

 "godot": { 

 "command": "npx", 

 "args": "@coding-solo/godot-mcp", 

 "env": { "GODOTPATH": "/path/to/godot" } 

 }  
 } 

} 

This lets Cursor’s AI agent launch the editor, run the project, create scenes, add nodes, and capture debug output directly. GitHub 2 

Add a .cursorrules file to your project root. The community template at BlueBirdBack/godot-cursorrules on GitHub provides Godot 4.4+ coding standards: strict typing conventions, lifecycle implementation patterns, GitHub signal/export best practices, and performance guidelines. This dramatically improves AI code generation quality. 

Essential extensions and tools 

godot-tools ( geequlim.godot-tools ) — Core LSP, debugger, scene preview 

GDScript Formatter & Linter ( EddieDover.gdscript-formatter-linter ) — Code formatting via gdtoolkit; install with pip3 install gdtoolkit GDQuest 

GitLens — Git integration for version control 

GUT (Godot Unit Testing) — Install from Godot’s AssetLib; Medium write tests in GDScript, GitHub run from editor or CLI Saltares 

godogen (1,066 GitHub stars) — Claude Code skills that can generate entire Godot project scaffolding from text descriptions; useful for rapid prototyping 

The development workflow in practice 

Your daily loop: Godot editor open on one monitor, Cursor on the other. Edit scenes, tilemaps, and particle effects in the Godot editor (it’s lightweight — think of it as a visual scene builder, not an IDE). Write all GDScript code in Cursor with AI assistance. The godot tools extension keeps them synced via LSP on port 6005 DeepWiki Hit F5 in Godot to playtest, or configure a launch.json in Cursor for debugger-attached launches. The MCP server means you can ask Cursor’s AI to “add a RainParticle node to the WeatherEffects scene” and it will do so directly in the Godot editor. GitHub GitHub 

Project structure 

whether/ 

├── project.godot 

├── .cursorrules 

├── CLAUDE.md 

├── addons/  GUT, GodotSteam, touch input, etc. 

├── assets/  
│ ├── sprites/  Tile art, weather icons, UI elements │ ├── shaders/  Rain, snow, fog, lightning shaders 

│ ├── audio/  Ambient weather SFX, music 

│ └── fonts/ 

├── scenes/ 

│ ├── levels/  Individual puzzle scenes 

│ ├── weather/  Weather effect scenes (rain, sun, etc.) │ ├── ui/  Menus, HUD, card hand 

│ └── gameobjects/  Tiles, crates, conductors, etc. 

├── scripts/ 

│ ├── autoloads/  GameManager, AudioManager, SaveManager │ ├── weather/  Weather logic (state changes, interactions) │ ├── grid/  Grid management, tile state machine 

│ └── ui/ 

├── resources/  Custom Resource definitions (.tres) 

├── levels/  Level data (JSON or .tres) 

└── test/  GUT test files 

Version control essentials 

Your .gitignore needs exactly two critical entries: .godot/ (imported resource cache, 100+ MB, always regenerated) and .import/ (Godot 3 equivalent). Track everything else: .tscn scene files, .gd scripts, .tres resources, project.godot , and all assets. These are all human-readable text files that diff cleanly in Git. dev 

Open-source foundations to build on 

Grid-based puzzle frameworks (study these first) 

The zurkon/sokoban repository implements a clean data-driven Sokoban in Godot 4 with JSON-based level loading and grid-based movement — the exact architecture “Whether” needs. Study its grid.gd for tile state management. The dobsondev/godot-sokoban repo adds level templates via Godot’s inherited scenes system, showing how to structure 100+ levels without duplicating scene files. GitHub Neither is a drop-in template, but together they provide the grid-movement and level-management patterns you’ll build on. 

Level design pipeline 

Use LDtk (Level Designer Toolkit) as your external level editor, imported via heygleeson/godot-ldtk-importer (240 stars, MIT license, actively maintained through 2025). LDtk is free, designed for 2D tile-based games, and has a visual editor far superior to Godot’s built-in TileMap for designing 130+ puzzle levels. Tres Sims Define tile types  
(earth, basin, stone, vegetation), place objects, and set weather card assignments per level in LDtk’s entity system. The importer converts everything to Godot TileMapLayers and scene nodes automatically. GitHub 

Weather and particle effects 

Start with gregrylivingston/Godot4—Weather-System-2D for shader-based rain, cloud, and raindrop-on-screen effects built natively for Godot 4 Layer in effects from haowg/GODOT-VFX-LIBRARY which provides rain, snow, steam, water splash, and environmental VFX with a simple API ( EnvVFX.createrain(self, 600 ). GitHub For individual shader effects — frost crystallization, fog rollout, lightning flash — browse godotshaders.com/shader-tag/rain/ which hosts dozens of community-contributed Godot 4 shaders. GitHub The pirachute/godot-weather-2D repo (80 stars) has the best designed weather node architecture (wind parameters, scene darkening, particle configuration) but targets Godot 3 and needs porting; use it as a design reference. GitHub GitHub 

Touch input 

Federico-Ciuffardi/GodotTouchInputManager (570 stars, MIT, Godot 4 support) provides tap, long press, swipe, pinch, and multi-touch gesture recognition that integrates with Godot’s InputEvent system. GitHub For “Whether,” you’ll primarily need tap detection (select weather card, target grid tile) and swipe (scroll through card hand, navigate between levels), both of which this library handles. 

AI and productivity tools 

Coding-Solo/godot-mcp (2,500 stars) is the MCP server. GitHub Maaack’s Godot Game-Template (1,000+ stars) provides a complete main menu → options → pause → credits flow that saves you weeks of UI work. SaveMadeEasy by AdamKormos handles 

encrypted save files with a simple key-value API. GitHub LimboAI (2,400 stars) provides state machines Ecosyste.ms if your weather interaction system needs complex state management (likely useful for tile states: dry → wet → frozen → electrified). GitHub GitHub 

Code study recommendations 

Study luiz734/match3game (Godot 4.1.2) for grid-based puzzle logic — its match3core.gd and grid.gd show how to manage a 2D grid of interactive tiles with state changes, which is architecturally similar to what “Whether” needs. GitHub Study blikoor/godot-match-3 (80 stars, Godot 3 for its well-organized codebase and GDScript style guide. GitHub For physics-based weather inspiration, study the water simulation  
approach in any open-source Where’s My Water clone. 

From prototype to launch in 9–12 months 

Phase 1 — Prototype (Weeks 1–6) 

Goal: Prove the core mechanic is fun in 5 levels. 

Weeks 1–2: Set up Godot  Cursor  MCP. Complete 2–3 GDScript tutorials. Build a basic grid system with placeholder tiles (colored rectangles). Implement tap-to-select, tap-to place input. 

Weeks 3–4: Implement Rain (fills basins) and Sun (evaporates water to steam). Build 3 levels testing the rain→water→sun→steam→platform chain. Use GPUParticles2D for basic rain/steam effects. No art — pure colored rectangles and particles. 

Weeks 5–6: Add Frost (freezes water to ice). Build 2 more levels testing rain→frost→ice bridge sequences. Implement the weather card hand UI (simple horizontal list). Playtest with 5–10 people. The question to answer: *Is choosing weather order inherently satisfying?* 

If the answer is no, pivot to a runner-up concept before investing further. If yes, proceed. 

Phase 2 — Vertical slice (Weeks 7–14) 

Goal: One polished world (15 levels) that represents final quality. 

Weeks 7–9: Commission or AI-generate the tile art style. Aim for clean, flat vector-style tiles with expressive weather particle effects — think Mini Metro’s minimalism meets Alto’s Odyssey atmospheric beauty. Implement polished weather shaders (rain with screen droplets, frost crystallization animation, sun rays, fog rollout). Add ambient audio per weather type. 

Weeks 10–12: Design and build all 15 levels of World 1 (“Downpour”). Implement level select, progression tracking, and the save system. Add undo functionality (critical for puzzle games — every successful puzzle game has undo). NeoGAF 

Weeks 13–14: Polish the vertical slice. Add juice: screen shake on lightning, particle bursts on weather card play, satisfying completion animation. This is your demo for Steam Next Fest and your pitch to publishers like Annapurna Interactive or Draknek & Friends (both appear repeatedly in successful indie puzzle launches). 

Phase 3 — MVP / Full content (Weeks 15–30) 

Goal: All 6 worlds, 130 levels, ready for launch.  
Build remaining weather mechanics one world at a time. Each world takes 2–3 weeks (implement mechanic  design 15–20 levels  playtest). The later worlds are harder to design because combinatorial complexity increases — budget extra time for Worlds 5 and 6 

Weeks 27–30: Main menu, settings, credits, Steam achievements, cloud saves. Implement the level editor if scope allows (extends post-launch longevity enormously — see Baba Is You and Hexcells Infinite). Final QA pass across all levels. 

Phase 4 — Launch (Weeks 31–36) 

Steam first (Weeks 31–33): Submit to Steam. Run a Steam Next Fest demo (World 1 only). Build a wishlist over 2–4 weeks. Launch at $9.99. Target Overwhelmingly Positive reviews by ensuring every puzzle is solvable through logic (no guessing — the Hexcells principle). Buried Treasure 

iOS/Android (Weeks 34–36): Port to mobile. Adjust UI for touch (larger tap targets, card hand repositioned for thumb reach). Test across devices. INAIRSPACE Submit to App Store ($4.99 premium) and Google Play ($2.99 or freemium). Apply to Apple Arcade and Netflix Games simultaneously — both provide guaranteed revenue and solve the mobile discoverability problem. 

Realistic timeline adjustments 

The 36-week schedule assumes 15–20 hours/week of focused development. With AI assistance (Cursor  MCP generating boilerplate, writing shaders, building UI), you’ll move 2–3x faster than a traditional solo dev on infrastructure tasks — but level design is irreducibly human and will consume the most time. If working full-time, compress to 6–8 months. If evenings-and-weekends only, extend to 12–14 months. 

The critical risk is not technical — it’s level design fatigue. Designing 130 distinct, satisfying, solvable-without-guessing puzzles is the hardest part of making a puzzle game. Baba Is You took years largely because level design is slow. Wikipedia Mitigate this by building a level editor early, playtesting constantly, and cutting levels that don’t spark joy rather than padding content. 

What separates a good puzzle game from a great one 

The research points to a single meta-lesson: great puzzle games are built around moments of insight, not moments of skill. The player’s reward is the “aha” — suddenly understanding that rain before frost creates a bridge, that sun clears fog but destroys the steam platform you needed. “Whether” is designed to maximize these moments by making weather order the central puzzle. Every level should have at least one moment where the  
player thinks “wait… what if I use sun *first*?” and everything clicks. 

The weather theme gives you a second advantage most puzzle games lack: emotional atmosphere. Rain is melancholy. Sun is hopeful. Fog is mysterious. Lightning is dramatic. If you lean into this — ambient sound design, dynamic lighting, weather effects that feel alive — “Whether” won’t just be a clever puzzle game. It will be a place people want to spend time. That’s what elevated Monument Valley, Alto’s Odyssey, and Cocoon Metacritic from good to beloved. The puzzles are the skeleton. The weather is the soul.