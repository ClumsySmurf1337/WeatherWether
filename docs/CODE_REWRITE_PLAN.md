# Code Rewrite Plan (v2)

> **Status:** File-by-file rewrite specification. The gameplay-programmer agent uses this as its build target. Pairs with `docs/GAME_DESIGN.md` (the design spine) and `docs/SPEC_DIFF.md` (what changed at a high level).
>
> **Reading order:** Start with §1 (dependency graph), then §2 (file specs in dependency order), then §3 (test strategy), then §4 (PR checklist).
>
> **For Linear tasks:** Each `[REWRITE]`, `[CORE]`, and `[MECH]` task in the v2 backlog corresponds to one or more file specs in §2. Cross-reference by file path.
>
> **Last updated:** 2026-04-10

---

## 1. Dependency graph

These files must be implemented in roughly this order. A → B means A blocks B.

```
weather_type.gd
  ├─→ weather_card.gd
  ├─→ weather_system.gd
  └─→ pathfinder.gd
        └─→ character_controller.gd

level_data.gd
  ├─→ level_loader.gd
  └─→ world_data.gd
        └─→ world_loader.gd

puzzle_state.gd
  └─→ puzzle_solver.gd ←── needs weather_system.gd, pathfinder.gd
        └─→ solver_result.gd

event_bus.gd      (autoload — no deps)
save_manager.gd   (autoload — no deps)
audio_manager.gd  (autoload — no deps)

grid_manager.gd  ←── needs weather_type.gd, weather_system.gd, event_bus.gd
  └─→ animation_director.gd
        └─→ ui/widgets/grid_view.gd

character_controller.gd  ←── needs pathfinder.gd, weather_type.gd
  └─→ ui/widgets/character_view.gd

game_manager.gd  ←── needs grid_manager.gd, character_controller.gd, level_loader.gd, save_manager.gd
  └─→ ui_manager.gd  (autoload)
        └─→ all ui/screens/*.gd
```

**Phase 1 (parallel-safe):** `weather_type.gd`, `weather_card.gd`, `weather_system.gd`, `pathfinder.gd`, `puzzle_state.gd`, `solver_result.gd`, `level_data.gd`, `event_bus.gd`, `save_manager.gd`, `audio_manager.gd` — these have no inter-deps and can be built by 4+ agents in parallel.

**Phase 2:** `puzzle_solver.gd`, `level_loader.gd`, `world_data.gd`, `world_loader.gd`, `character_controller.gd`, `grid_manager.gd` — depend on Phase 1.

**Phase 3:** `game_manager.gd`, `animation_director.gd`, `ui_manager.gd`, all `ui/widgets/*.gd`.

**Phase 4:** All `ui/screens/*.gd` and `ui/popups/*.gd`.

---

## 2. File-by-file specs

### `scripts/weather/weather_type.gd`

**Status:** REWRITE (existing file is 6-terrain enum, needs 14)
**Class:** `WeatherType extends RefCounted`
**Purpose:** Canonical enums and pure helper functions. No state, no signals.

**Public API:**

```gdscript
class_name WeatherType extends RefCounted

enum Card { RAIN, SUN, FROST, WIND, LIGHTNING, FOG }

enum Terrain {
    EMPTY, DRY_GRASS, WET_GRASS, SCORCHED, WATER, ICE, MUD, SNOW,
    FOG_COVERED, STEAM, PLANT, STONE, GOAL, START
}

static func card_name(card: Card) -> String
static func terrain_name(terrain: Terrain) -> String
static func is_walkable(terrain: Terrain) -> bool
static func is_conductive(terrain: Terrain) -> bool
static func is_death_tile(terrain: Terrain) -> bool
```

**Walkable set:** `EMPTY, DRY_GRASS, WET_GRASS, ICE, MUD, SNOW, PLANT, START, GOAL`
**Conductive set:** `WATER, WET_GRASS, MUD, ICE`
**Death tiles:** `WATER` (drown), `SCORCHED` (burn), `STEAM` (fall), `EMPTY` (fall)

**Tests (`test/test_weather_type.gd`):** 14 enum values present, each helper returns expected boolean for every terrain type.

---

### `scripts/weather/weather_card.gd`

**Status:** NEW
**Class:** `WeatherCard extends Resource`
**Purpose:** Inspector-editable card definition. One `.tres` per card type.

**Public API:**

```gdscript
class_name WeatherCard extends Resource

@export var type: WeatherType.Card = WeatherType.Card.RAIN
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export var cost: int = 1
@export var radius: int = 0
@export var is_directional: bool = false

func get_icon_path() -> String
```

Create `resources/cards/card_rain.tres` through `resources/cards/card_fog.tres`.

---

### `scripts/weather/weather_system.gd`

**Status:** REWRITE (existing only handles RAIN/SUN/FROST/FOG, no chains, mutates grid)
**Class:** `WeatherSystem extends RefCounted` (NOT Node)
**Purpose:** Pure-function interaction matrix. Must be deterministic and side-effect-free.

**Public API:**

```gdscript
class_name WeatherSystem extends RefCounted

# Pure function. Takes a grid copy + width/height + card_type + position.
# Returns a NEW grid (does not mutate input).
static func apply(
    grid: Array,
    width: int,
    height: int,
    card_type: int,
    pos: Vector2i
) -> Array

static func is_valid_placement(
    grid: Array,
    width: int,
    height: int,
    card_type: int,
    pos: Vector2i
) -> bool
```

**Implementation requirements:**
1. Match every active row in `GAME_DESIGN.md §5` matrix exactly (37 active transitions)
2. Handle WIND as a 3-tile cross (target + 4 cardinal neighbors)
3. Handle FOG as a 3×3 area, excluding STONE/START/GOAL inside the area
4. Handle LIGHTNING as a flood fill across conductive tiles (chain to scorched)
5. LIGHTNING on ICE shatters single tile to EMPTY (no chain)
6. Be deterministic: same inputs = same output, every call

**Internal helpers (private, prefixed `_`):**

```gdscript
static func _apply_rain(grid: Array, width: int, height: int, pos: Vector2i) -> void
static func _apply_sun(grid: Array, width: int, height: int, pos: Vector2i) -> void
static func _apply_frost(grid: Array, width: int, height: int, pos: Vector2i) -> void
static func _apply_wind(grid: Array, width: int, height: int, pos: Vector2i) -> void
static func _apply_lightning(grid: Array, width: int, height: int, pos: Vector2i) -> void
static func _apply_fog(grid: Array, width: int, height: int, pos: Vector2i) -> void
static func _flood_fill_conductive(grid: Array, width: int, height: int, start: Vector2i) -> Array
```

**Tests (`test/test_weather_cards.gd`):** Minimum 40 test cases. All 37 active transitions plus at least one multi-tile case per area-effect card.

---

### `scripts/character/pathfinder.gd`

**Status:** NEW
**Class:** `Pathfinder extends RefCounted`
**Purpose:** Pure A* over a grid + walkable predicate.

**Public API:**

```gdscript
class_name Pathfinder extends RefCounted

# Returns Array[Vector2i] of tile positions from start to goal (inclusive),
# or empty array if no path. Cardinal moves only. Tie-break prefers straight lines.
static func find_path(
    grid: Array,
    width: int,
    height: int,
    start: Vector2i,
    goal: Vector2i
) -> Array
```

**Implementation requirements:**
1. Cardinal movement only (no diagonals)
2. Walkable predicate uses `WeatherType.is_walkable()`
3. Manhattan distance heuristic
4. Tie-breaking: prefer paths that match the direction of the previous step (straight lines look better than zigzags)
5. Goal tile must be walkable

**Tests (`test/test_pathfinder.gd`):** trivial 1-step path, blocked path returns empty, multi-route picks shortest, identical-cost picks straight, start==goal, off-grid goal.

---

### `scripts/puzzle/puzzle_state.gd`

**Status:** NEW
**Class:** `PuzzleState extends RefCounted`
**Purpose:** Immutable BFS state for the solver.

**Public API:**

```gdscript
class_name PuzzleState extends RefCounted

var terrain: Array
var remaining_cards: Array[int]
var moves: Array

func _init(p_terrain: Array, p_remaining_cards: Array[int], p_moves: Array)

# Stable hash for BFS deduplication.
# Two states with identical terrain AND identical remaining cards collide.
func hash_key() -> String
```

**Tests:** different states produce different hashes, identical states produce identical hashes, sorted-card-set hash collisions don't depend on cards order.

---

### `scripts/puzzle/solver_result.gd`

**Status:** NEW
**Class:** `SolverResult extends RefCounted`

**Public API:**

```gdscript
class_name SolverResult extends RefCounted

var is_solvable: bool
var min_moves: int
var solution: Array  # Array of [card_type, Vector2i] pairs
var states_explored: int
var elapsed_ms: float

func _init(p_solvable: bool, p_solution: Array = [], p_min_moves: int = 0,
           p_states_explored: int = 0, p_elapsed_ms: float = 0.0)

# Rough difficulty 1-10 based on min_moves + states_explored.
func difficulty_score() -> int
```

---

### `scripts/puzzle/puzzle_solver.gd`

**Status:** REWRITE (existing is a stub)
**Class:** `PuzzleSolver extends RefCounted`
**Purpose:** BFS solver. Used by tests, level validation CI, level gen tooling.

**Public API:**

```gdscript
class_name PuzzleSolver extends RefCounted

const MAX_STATES: int = 200000

var _width: int
var _height: int
var _goal_predicate: Callable  # func(terrain: Array, w: int, h: int) -> bool

func _init(width: int, height: int, goal_predicate: Callable)

func solve(initial_terrain: Array, available_cards: Array[int]) -> SolverResult

# Default goal predicate: A* path exists from start to any goal.
static func make_path_exists_goal(start: Vector2i, goals: Array[Vector2i]) -> Callable
```

**Implementation:**
1. BFS from initial state, expanding by trying every (card, position) combination
2. Hash dedup via `PuzzleState.hash_key()`
3. Stop at first goal hit (BFS guarantees min moves)
4. Hard cap at `MAX_STATES` to prevent runaway
5. Track `states_explored` and `elapsed_ms`

**Tests:** trivial 1-move solve, multi-step solve, unsolvable level, hash collision sanity, state cap behavior, performance budget (5×5 grid + 6 cards under 2 seconds).

---

### `scripts/level/level_data.gd`

**Status:** NEW
**Class:** `LevelData extends Resource`

```gdscript
class_name LevelData extends Resource

@export var id: String = ""
@export var world: int = 1
@export var level_number: int = 1
@export var display_name: String = ""
@export var hint_text: String = ""
@export var width: int = 5
@export var height: int = 5
@export var initial_terrain: Array = []
@export var start_position: Vector2i = Vector2i.ZERO
@export var goal_positions: Array[Vector2i] = []
@export var available_cards: Array[int] = []
@export var max_moves: int = 0
@export var par_moves: int = 0
@export var target_difficulty: int = 1
@export var min_solution_length: int = 0
@export var unique_solution: bool = false

func is_valid() -> bool  # validates start_position is walkable, etc.
```

---

### `scripts/level/level_loader.gd`

**Status:** NEW
**Class:** `LevelLoader extends RefCounted`

```gdscript
class_name LevelLoader extends RefCounted

static func load_from_json(path: String) -> LevelData
static func save_to_json(level: LevelData, path: String) -> bool
```

JSON schema documented in `docs/GAME_DESIGN.md §7`.

---

### `scripts/level/world_data.gd` and `world_loader.gd`

**Status:** NEW

`WorldData extends Resource`:

```gdscript
class_name WorldData extends Resource

@export var id: String           # "world1"
@export var name: String         # "Downpour"
@export var mood: String         # "gentle melancholy"
@export var level_count: int = 22
@export var music_path: String = ""
@export var ambient_path: String = ""
@export var card_pool: Array[int] = []  # which cards are available
```

`WorldLoader extends RefCounted`:

```gdscript
class_name WorldLoader extends RefCounted

static func load_world(world_id: String) -> WorldData
static func load_all_worlds() -> Array[WorldData]
static func load_path_layout(world_id: String) -> Array  # from levels/worldN/path.json
```

---

### `scripts/autoload/event_bus.gd`

**Status:** NEW (autoload)
**Class:** `EventBus extends Node`
**Purpose:** Global signal bus. Decouples systems.

```gdscript
extends Node

signal level_started(level: LevelData)
signal level_completed(level_id: String, stars: int, moves_used: int)
signal level_failed(level_id: String, cause: int)
signal card_queued(card_type: int, pos: Vector2i)
signal card_unqueued(index: int)
signal sequence_started
signal sequence_finished
signal walk_started
signal character_died(cause: int)
signal no_path_forward
signal settings_changed(key: String, value: Variant)
```

Register in `project.godot`:

```
[autoload]
EventBus="*res://scripts/autoload/event_bus.gd"
```

---

### `scripts/autoload/save_manager.gd`

**Status:** NEW (autoload)
**Class:** `SaveManager extends Node`

```gdscript
extends Node

const SAVE_PATH: String = "user://save_default.json"
const SCHEMA_VERSION: int = 1

var data: Dictionary = {}

func _ready() -> void
func load_save() -> bool
func save() -> bool  # atomic write via .tmp + rename
func reset_progress() -> void

func record_level_complete(level_id: String, stars: int, moves: int, time_ms: int) -> void
func get_level_record(level_id: String) -> Dictionary
func get_setting(key: String, default: Variant = null) -> Variant
func set_setting(key: String, value: Variant) -> void

# Schema migrations (stubbed for v1)
func _migrate(from_version: int) -> void
```

Schema in `GAME_DESIGN.md §11`.

**Tests:** round-trip, atomic write failure, missing file, corrupt file, version migration stub.

---

### `scripts/autoload/audio_manager.gd`

**Status:** NEW (autoload)
**Class:** `AudioManager extends Node`

```gdscript
extends Node

func play_music(track_path: String, fade_in_ms: int = 500) -> void
func stop_music(fade_out_ms: int = 500) -> void
func play_sfx(sound_path: String, volume_db: float = 0.0) -> void
func play_ambient(layer_path: String) -> void
func stop_ambient() -> void

func set_master_volume(volume: float) -> void  # 0-1
func set_music_volume(volume: float) -> void
func set_sfx_volume(volume: float) -> void

# Bound to SaveManager settings on _ready
```

Three buses configured in `project.godot`: Master → Music, SFX, Ambient.

---

### `scripts/grid/grid_manager.gd`

**Status:** REWRITE (existing has 6-terrain enum, no queue, no undo)
**Class:** `GridManager extends RefCounted` (NOT Node — pure logic, rendering is separate)
**Purpose:** State of the puzzle board + queue + undo/redo.

**Public API:**

```gdscript
class_name GridManager extends RefCounted

var width: int
var height: int
var terrain: Array  # flat width*height array of Terrain ints
var initial_terrain: Array  # for reset

var queue: Array  # Array of [card_type, Vector2i] pairs (planning phase)
var max_queue_size: int

# Setup
func _init(level: LevelData)

# Planning phase
func queue_card(card_type: int, pos: Vector2i) -> bool
func unqueue_last() -> bool
func clear_queue() -> void
func get_queue() -> Array
func can_queue() -> bool  # false if queue.size == max_queue_size

# Sequence playback (called by animation_director)
func resolve_next_card() -> Dictionary  # returns {card_type, pos, new_terrain}
func reset_to_initial() -> void

# Read-only access
func get_terrain_at(pos: Vector2i) -> int
func get_preview_grid() -> Array  # current terrain + all queued cards applied
func is_in_bounds(pos: Vector2i) -> bool

# Undo (across sequences)
func undo_last_sequence() -> bool
```

**Critical:** GridManager has NO TileMapLayer or rendering deps. Visualization lives in `ui/widgets/grid_view.gd` which subscribes to `EventBus`.

**Signals:** none (use EventBus).

**Tests:** queue/unqueue, max queue enforcement, preview grid correctness, reset, undo across sequences.

---

### `scripts/character/character_controller.gd`

**Status:** NEW
**Class:** `CharacterController extends RefCounted`

```gdscript
class_name CharacterController extends RefCounted

enum State { IDLE, SURPRISED, WALK, CHEER, DROWN, BURN, ELECTROCUTE, FREEZE, FALL }

var current_state: State = State.IDLE
var position: Vector2i
var facing: Vector2i = Vector2i.DOWN
var path: Array = []
var path_index: int = 0

func _init(start_pos: Vector2i)

# Called by GameManager after sequence resolution
func begin_walk(computed_path: Array) -> void

# Step the walk (called per tile, ~250ms each)
# Returns true if walk continues, false if reached goal or died
func step(grid: Array, width: int, height: int, goals: Array[Vector2i]) -> bool

func get_death_cause() -> int  # cause enum for death type

# Triggered externally
func trigger_death(cause: int) -> void
func trigger_win() -> void
```

The controller delegates animation playback to `character_view.gd` via EventBus signals. It doesn't know about sprites.

**Tests:** walk along happy path, death on water, death on scorched, death on empty, win on goal, no-path scenario.

---

### `scripts/animation/animation_director.gd`

**Status:** REWRITE (existing is a placeholder timer)
**Class:** `AnimationDirector extends Node`
**Purpose:** Orchestrates sequence playback and walk visuals.

```gdscript
class_name AnimationDirector extends Node

signal weather_effect_finished(card_type: int)
signal sequence_complete
signal walk_started
signal walk_finished

var speed_multiplier: float = 1.0  # 1.0 normal, 2.0 fast

func play_card_resolution(card_type: int, target: Vector2i) -> void
func play_weather_effect(card_type: int, target: Vector2i) -> void
func play_character_walk(path: Array[Vector2i]) -> void
func play_character_death(cause: int) -> void
func play_character_win() -> void
func set_speed_multiplier(multiplier: float) -> void
```

All methods are await-able. Timings come from `docs/ANIMATION_DIRECTION_2D.md`.

---

### `scripts/core/game_manager.gd`

**Status:** REWRITE (existing only has state enum)
**Class:** `GameManager extends Node`
**Purpose:** Top-level orchestrator. Owns the current level cycle.

```gdscript
class_name GameManager extends Node

enum State { BOOT, MAIN_MENU, LOADING, PLANNING, RESOLVING, WALKING, COMPLETE, FAILED, PAUSED }

var current_state: State = State.BOOT
var current_level: LevelData
var grid_manager: GridManager
var character: CharacterController
var animation_director: AnimationDirector

func load_level(level_id: String) -> void
func start_planning() -> void
func play_sequence() -> void  # transitions PLANNING → RESOLVING → WALKING
func handle_win() -> void
func handle_loss(cause: int) -> void
func handle_no_path() -> void
func quit_to_world_map() -> void
func pause() -> void
func resume() -> void
```

All transitions emit `EventBus` signals. UI listens for them.

---

### UI files

See `docs/UI_SCREENS.md` for the 12 screens. Each screen has a `.tscn` and a `.gd` script. The widgets `card_view`, `queue_strip`, `grid_view`, `character_view` are pulled into multiple screens. Specs for each are in `UI_SCREENS.md`.

UI implementation order:

1. `ui_manager.gd` (autoload, scene push/pop)
2. `ui_theme.gd` (color tokens)
3. Splash → Home → World Select → Level Select → Gameplay → Level Complete → Level Failed
4. Modals: Pause, Settings, Hint, Confirm Sequence, No Path Forward
5. Widgets: card_view, queue_strip, grid_view, character_view (refactor as scenes use them)

---

## 3. Test strategy

| Test file | What it covers | Min cases |
|---|---|---|
| `test/test_weather_type.gd` | Enum values, helper booleans | 14 |
| `test/test_weather_cards.gd` | All 37 transitions + multi-tile cases | 40+ |
| `test/test_grid_system.gd` | Queue, undo, preview grid, reset | 12+ |
| `test/test_pathfinder.gd` | Trivial, blocked, multi-route, edges | 8+ |
| `test/test_puzzle_solver.gd` | Trivial, multi-step, unsolvable, cap, hash | 10+ |
| `test/test_save_load.gd` | Schema, atomic write, migration, missing | 8+ |
| `test/test_character_controller.gd` | Walk path, all death causes, win | 7+ |
| `test/test_sequence_integration.gd` | Full level cycle headless | 5+ |

Run via `npm run validate` (which calls `tools/tasks/validate.ps1`).

---

## 4. PR checklist for any rewrite task

Before opening a PR for any of these files, the gameplay-programmer agent verifies:

- [ ] File matches the public API in §2 exactly (no extra public methods, no missing ones)
- [ ] Strict typing on every variable, parameter, and return
- [ ] No `yield` (use `await`)
- [ ] No `get_node()` in `_process()` (use `@onready`)
- [ ] No untyped `Array` or `Dictionary` in core systems
- [ ] No circular script dependencies
- [ ] Tests added/updated and passing locally (`npm run validate`)
- [ ] PR title includes the Linear ID (`WEA-NNN`)
- [ ] PR description references the file spec section in `CODE_REWRITE_PLAN.md`
- [ ] No references to old design (instant-resolve, 6-terrain enum, abstract win condition)
- [ ] Signals routed through `EventBus`, not direct method calls
- [ ] Pure logic separated from rendering (e.g. GridManager has no TileMapLayer)

---

## 5. What this doc supersedes

- The `[CORE]` track in the old `backlog-outline-generator.ts` (deleted in Pass 2 cleanup)
- Any references to "Turn sequencing and action history" or "Steam platform placeholder" in older docs
- Generic "implement grid system" or "implement weather system" tasks without specs

If you find an older doc that contradicts a file spec here, the spec wins. Update the older doc in the same PR.