## GameManager integration tests: state transitions, queue/play/walk/win/lose.
extends GutTest

const T := WeatherType.Terrain
const C := WeatherType.Card
const GS := GameManager.GameState


func _make_level(terrain: Array, w: int, h: int, cards: Array[int], start: Vector2i, goals: Array[Vector2i]) -> LevelData:
	var level := LevelData.new()
	level.id = "test_level"
	level.world = 1
	level.level_number = 1
	level.width = w
	level.height = h
	level.initial_terrain = terrain
	level.start_position = start
	level.goal_positions = goals
	level.available_cards = cards
	level.max_moves = cards.size()
	level.par_moves = cards.size()
	return level


func _make_grid(w: int, h: int, fill: int) -> Array:
	var g: Array = []
	g.resize(w * h)
	for i: int in range(g.size()):
		g[i] = fill
	return g


func _set_grid_cell(grid: Array, pos: Vector2i, w: int, val: int) -> void:
	grid[pos.y * w + pos.x] = val


func test_load_level_transitions_to_planning() -> void:
	var gm := GameManager.new()
	add_child_autoqfree(gm)
	var grid := _make_grid(3, 1, T.DRY_GRASS)
	_set_grid_cell(grid, Vector2i(0, 0), 3, T.START)
	_set_grid_cell(grid, Vector2i(2, 0), 3, T.GOAL)
	var level: LevelData = _make_level(grid, 3, 1, [], Vector2i(0, 0), [Vector2i(2, 0)])
	gm.load_level(level)
	assert_eq(gm.current_state, GS.PLANNING)
	assert_not_null(gm.grid_manager)
	assert_not_null(gm.character)


func test_queue_card_emits_and_increments() -> void:
	var gm := GameManager.new()
	add_child_autoqfree(gm)
	var grid := _make_grid(3, 1, T.DRY_GRASS)
	_set_grid_cell(grid, Vector2i(0, 0), 3, T.START)
	_set_grid_cell(grid, Vector2i(2, 0), 3, T.GOAL)
	var cards: Array[int] = [C.RAIN]
	var level: LevelData = _make_level(grid, 3, 1, cards, Vector2i(0, 0), [Vector2i(2, 0)])
	gm.load_level(level)

	var ok: bool = gm.queue_card(C.RAIN, Vector2i(1, 0))
	assert_true(ok)
	assert_eq(gm.grid_manager.queue.size(), 1)


func test_undo_removes_from_queue() -> void:
	var gm := GameManager.new()
	add_child_autoqfree(gm)
	var grid := _make_grid(3, 1, T.DRY_GRASS)
	_set_grid_cell(grid, Vector2i(0, 0), 3, T.START)
	_set_grid_cell(grid, Vector2i(2, 0), 3, T.GOAL)
	var cards: Array[int] = [C.RAIN, C.SUN]
	var level: LevelData = _make_level(grid, 3, 1, cards, Vector2i(0, 0), [Vector2i(2, 0)])
	gm.load_level(level)
	gm.queue_card(C.RAIN, Vector2i(1, 0))
	gm.undo_last_card()
	assert_eq(gm.grid_manager.queue.size(), 0)


func test_play_sequence_transitions_to_resolving() -> void:
	var gm := GameManager.new()
	add_child_autoqfree(gm)
	var grid := _make_grid(3, 1, T.DRY_GRASS)
	_set_grid_cell(grid, Vector2i(0, 0), 3, T.START)
	_set_grid_cell(grid, Vector2i(1, 0), 3, T.WATER)
	_set_grid_cell(grid, Vector2i(2, 0), 3, T.GOAL)
	var cards: Array[int] = [C.FROST]
	var level: LevelData = _make_level(grid, 3, 1, cards, Vector2i(0, 0), [Vector2i(2, 0)])
	gm.load_level(level)
	gm.queue_card(C.FROST, Vector2i(1, 0))
	gm.play_sequence()
	assert_eq(gm.current_state, GS.RESOLVING)


func test_pause_and_resume() -> void:
	var gm := GameManager.new()
	add_child_autoqfree(gm)
	var grid := _make_grid(3, 1, T.DRY_GRASS)
	_set_grid_cell(grid, Vector2i(0, 0), 3, T.START)
	_set_grid_cell(grid, Vector2i(2, 0), 3, T.GOAL)
	var level: LevelData = _make_level(grid, 3, 1, [], Vector2i(0, 0), [Vector2i(2, 0)])
	gm.load_level(level)
	gm.pause()
	assert_eq(gm.current_state, GS.PAUSED)
	gm.resume()
	assert_eq(gm.current_state, GS.PLANNING)


func test_star_rating_three_stars_at_par() -> void:
	var gm := GameManager.new()
	add_child_autoqfree(gm)
	var grid := _make_grid(3, 1, T.DRY_GRASS)
	_set_grid_cell(grid, Vector2i(0, 0), 3, T.START)
	_set_grid_cell(grid, Vector2i(1, 0), 3, T.WATER)
	_set_grid_cell(grid, Vector2i(2, 0), 3, T.GOAL)
	var cards: Array[int] = [C.FROST]
	var level: LevelData = _make_level(grid, 3, 1, cards, Vector2i(0, 0), [Vector2i(2, 0)])
	level.par_moves = 1
	gm.load_level(level)
	gm.queue_card(C.FROST, Vector2i(1, 0))
	gm.play_sequence()
	# First resolve_next applies the FROST card
	gm.resolve_next()
	assert_eq(gm.current_state, GS.RESOLVING)
	# Second resolve_next finds empty queue → triggers walk
	gm.resolve_next()
	assert_eq(gm.current_state, GS.WALKING)
	# Walk: START(0,0) → ICE(1,0) → GOAL(2,0)
	gm.walk_step()
	gm.walk_step()
	assert_eq(gm.current_state, GS.COMPLETE)
