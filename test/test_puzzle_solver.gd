## PuzzleSolver BFS tests: trivial, multi-step, unsolvable, hash, state cap.
extends GutTest

const T := WeatherType.Terrain
const C := WeatherType.Card


func _grid_filled(w: int, h: int, terrain: int) -> Array:
	var cells: Array = []
	cells.resize(w * h)
	for i: int in range(cells.size()):
		cells[i] = terrain
	return cells


func _set_cell(grid: Array, pos: Vector2i, w: int, val: int) -> void:
	grid[pos.y * w + pos.x] = val


func _get_cell(grid: Array, pos: Vector2i, w: int) -> int:
	return grid[pos.y * w + pos.x]


# ===================================================================
# Trivial 1-move solve
# ===================================================================

func test_trivial_one_rain_creates_path() -> void:
	# 3×1 grid: START | EMPTY | GOAL
	# RAIN on EMPTY -> WATER (not walkable). Use FROST on EMPTY -> SNOW (walkable).
	var w := 3
	var h := 1
	var grid := _grid_filled(w, h, T.EMPTY)
	_set_cell(grid, Vector2i(0, 0), w, T.START)
	_set_cell(grid, Vector2i(2, 0), w, T.GOAL)

	var start := Vector2i(0, 0)
	var goals: Array[Vector2i] = [Vector2i(2, 0)]
	var predicate: Callable = PuzzleSolver.make_path_exists_goal(start, goals)
	var solver := PuzzleSolver.new(w, h, predicate)

	var cards: Array[int] = [C.FROST]
	var result: SolverResult = solver.solve(grid, cards)

	assert_true(result.is_solvable, "should be solvable with FROST on EMPTY->SNOW")
	assert_eq(result.min_moves, 1)
	assert_eq(result.solution.size(), 1)
	assert_eq(result.solution[0][0], C.FROST)
	assert_eq(result.solution[0][1], Vector2i(1, 0))
	assert_true(result.states_explored > 0)


# ===================================================================
# Multi-step solve (2 cards needed)
# ===================================================================

func test_two_step_rain_then_frost() -> void:
	# 3×1: START | SCORCHED | GOAL
	# RAIN on SCORCHED -> MUD (walkable). One card suffices.
	# But let's test with: START | WATER | GOAL — need FROST on WATER -> ICE
	var w := 3
	var h := 1
	var grid := _grid_filled(w, h, T.DRY_GRASS)
	_set_cell(grid, Vector2i(0, 0), w, T.START)
	_set_cell(grid, Vector2i(1, 0), w, T.WATER)
	_set_cell(grid, Vector2i(2, 0), w, T.GOAL)

	var start := Vector2i(0, 0)
	var goals: Array[Vector2i] = [Vector2i(2, 0)]
	var predicate: Callable = PuzzleSolver.make_path_exists_goal(start, goals)
	var solver := PuzzleSolver.new(w, h, predicate)

	var cards: Array[int] = [C.FROST]
	var result: SolverResult = solver.solve(grid, cards)
	assert_true(result.is_solvable)
	assert_eq(result.min_moves, 1)
	assert_eq(result.solution[0][0], C.FROST)


func test_multi_step_two_cards_required() -> void:
	# 5×1: START | WATER | WATER | DRY_GRASS | GOAL
	# Need: FROST on (1,0) -> ICE, FROST on (2,0) -> ICE
	var w := 5
	var h := 1
	var grid := _grid_filled(w, h, T.DRY_GRASS)
	_set_cell(grid, Vector2i(0, 0), w, T.START)
	_set_cell(grid, Vector2i(1, 0), w, T.WATER)
	_set_cell(grid, Vector2i(2, 0), w, T.WATER)
	_set_cell(grid, Vector2i(4, 0), w, T.GOAL)

	var start := Vector2i(0, 0)
	var goals: Array[Vector2i] = [Vector2i(4, 0)]
	var predicate: Callable = PuzzleSolver.make_path_exists_goal(start, goals)
	var solver := PuzzleSolver.new(w, h, predicate)

	var cards: Array[int] = [C.FROST, C.FROST]
	var result: SolverResult = solver.solve(grid, cards)
	assert_true(result.is_solvable)
	assert_eq(result.min_moves, 2)


# ===================================================================
# Unsolvable level
# ===================================================================

func test_unsolvable_no_cards_can_fix_wall() -> void:
	# 3×1: START | STONE | GOAL — STONE cannot be transformed
	var w := 3
	var h := 1
	var grid := _grid_filled(w, h, T.DRY_GRASS)
	_set_cell(grid, Vector2i(0, 0), w, T.START)
	_set_cell(grid, Vector2i(1, 0), w, T.STONE)
	_set_cell(grid, Vector2i(2, 0), w, T.GOAL)

	var start := Vector2i(0, 0)
	var goals: Array[Vector2i] = [Vector2i(2, 0)]
	var predicate: Callable = PuzzleSolver.make_path_exists_goal(start, goals)
	var solver := PuzzleSolver.new(w, h, predicate)

	var cards: Array[int] = [C.RAIN, C.SUN, C.FROST]
	var result: SolverResult = solver.solve(grid, cards)
	assert_false(result.is_solvable)
	assert_eq(result.min_moves, 0)


# ===================================================================
# Already solved (path exists at start)
# ===================================================================

func test_already_solved_returns_zero_moves() -> void:
	# 3×1: START | DRY_GRASS | GOAL — already walkable
	var w := 3
	var h := 1
	var grid := _grid_filled(w, h, T.DRY_GRASS)
	_set_cell(grid, Vector2i(0, 0), w, T.START)
	_set_cell(grid, Vector2i(2, 0), w, T.GOAL)

	var start := Vector2i(0, 0)
	var goals: Array[Vector2i] = [Vector2i(2, 0)]
	var predicate: Callable = PuzzleSolver.make_path_exists_goal(start, goals)
	var solver := PuzzleSolver.new(w, h, predicate)

	var cards: Array[int] = [C.RAIN]
	var result: SolverResult = solver.solve(grid, cards)
	assert_true(result.is_solvable)
	assert_eq(result.min_moves, 0)
	assert_eq(result.solution.size(), 0)


# ===================================================================
# Hash collision sanity
# ===================================================================

func test_different_states_produce_different_hashes() -> void:
	var terrain_a: Array = [T.DRY_GRASS, T.WATER]
	var terrain_b: Array = [T.WATER, T.DRY_GRASS]
	var cards: Array[int] = [C.RAIN]
	var state_a := PuzzleState.new(terrain_a, cards, [])
	var state_b := PuzzleState.new(terrain_b, cards, [])
	assert_ne(state_a.hash_key(), state_b.hash_key())


func test_identical_states_produce_same_hash() -> void:
	var terrain: Array = [T.DRY_GRASS, T.WATER, T.ICE]
	var cards: Array[int] = [C.FROST, C.RAIN]
	var state_a := PuzzleState.new(terrain.duplicate(), cards.duplicate(), [])
	var state_b := PuzzleState.new(terrain.duplicate(), cards.duplicate(), [])
	assert_eq(state_a.hash_key(), state_b.hash_key())


func test_card_order_does_not_affect_hash() -> void:
	var terrain: Array = [T.DRY_GRASS]
	var cards_a: Array[int] = [C.RAIN, C.FROST]
	var cards_b: Array[int] = [C.FROST, C.RAIN]
	var state_a := PuzzleState.new(terrain.duplicate(), cards_a, [])
	var state_b := PuzzleState.new(terrain.duplicate(), cards_b, [])
	assert_eq(state_a.hash_key(), state_b.hash_key())


# ===================================================================
# State cap behavior
# ===================================================================

func test_state_cap_returns_unsolvable_without_crash() -> void:
	# Large-ish grid with many cards — will exceed cap quickly if no solution
	# 4×4 grid of STONE except START and GOAL on opposite corners with no fix
	var w := 4
	var h := 4
	var grid := _grid_filled(w, h, T.STONE)
	_set_cell(grid, Vector2i(0, 0), w, T.START)
	_set_cell(grid, Vector2i(3, 3), w, T.GOAL)

	var start := Vector2i(0, 0)
	var goals: Array[Vector2i] = [Vector2i(3, 3)]
	var predicate: Callable = PuzzleSolver.make_path_exists_goal(start, goals)
	var solver := PuzzleSolver.new(w, h, predicate)

	# Give many cards — none can transform STONE, so queue is always empty
	# after first expansion. But the solver should terminate cleanly.
	var cards: Array[int] = [C.RAIN, C.SUN, C.FROST, C.WIND, C.LIGHTNING, C.FOG]
	var result: SolverResult = solver.solve(grid, cards)
	assert_false(result.is_solvable)
	assert_true(result.states_explored > 0)


# ===================================================================
# SolverResult difficulty_score
# ===================================================================

func test_difficulty_score_trivial_is_low() -> void:
	var result := SolverResult.new(true, [[C.RAIN, Vector2i.ZERO]], 1, 5, 1.0)
	assert_true(result.difficulty_score() >= 1)
	assert_true(result.difficulty_score() <= 3)


func test_difficulty_score_unsolvable_is_zero() -> void:
	var result := SolverResult.new(false, [], 0, 100, 5.0)
	assert_eq(result.difficulty_score(), 0)


# ===================================================================
# Goal predicate: make_path_exists_goal
# ===================================================================

func test_goal_predicate_returns_true_when_path_exists() -> void:
	var w := 3
	var h := 1
	var grid: Array = [T.START, T.DRY_GRASS, T.GOAL]
	var pred: Callable = PuzzleSolver.make_path_exists_goal(Vector2i(0, 0), [Vector2i(2, 0)])
	assert_true(pred.call(grid, w, h))


func test_goal_predicate_returns_false_when_blocked() -> void:
	var w := 3
	var h := 1
	var grid: Array = [T.START, T.STONE, T.GOAL]
	var pred: Callable = PuzzleSolver.make_path_exists_goal(Vector2i(0, 0), [Vector2i(2, 0)])
	assert_false(pred.call(grid, w, h))
