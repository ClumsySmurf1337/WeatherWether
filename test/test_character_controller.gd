## CharacterController tests: walk path, all death causes, win, edge cases.
extends GutTest

const T := WeatherType.Terrain
const S := CharacterController.State


func _make_grid(w: int, h: int, fill: int) -> Array:
	var g: Array = []
	g.resize(w * h)
	for i: int in range(g.size()):
		g[i] = fill
	return g


func _set(grid: Array, pos: Vector2i, w: int, val: int) -> void:
	grid[pos.y * w + pos.x] = val


func test_initial_state_is_idle() -> void:
	var cc := CharacterController.new(Vector2i(0, 0))
	assert_eq(cc.current_state, S.IDLE)
	assert_eq(cc.position, Vector2i(0, 0))


func test_walk_happy_path_reaches_goal() -> void:
	var w := 3
	var h := 1
	var grid := _make_grid(w, h, T.DRY_GRASS)
	_set(grid, Vector2i(0, 0), w, T.START)
	_set(grid, Vector2i(2, 0), w, T.GOAL)

	var cc := CharacterController.new(Vector2i(0, 0))
	var path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var goals: Array[Vector2i] = [Vector2i(2, 0)]

	cc.begin_walk(path)
	assert_eq(cc.current_state, S.WALK)

	var continues: bool = cc.step(grid, w, h, goals)
	assert_true(continues)
	assert_eq(cc.position, Vector2i(1, 0))

	continues = cc.step(grid, w, h, goals)
	assert_false(continues)
	assert_eq(cc.current_state, S.CHEER)
	assert_eq(cc.position, Vector2i(2, 0))


func test_death_on_water_is_drown() -> void:
	var w := 3
	var h := 1
	var grid := _make_grid(w, h, T.DRY_GRASS)
	_set(grid, Vector2i(0, 0), w, T.START)
	_set(grid, Vector2i(1, 0), w, T.WATER)
	_set(grid, Vector2i(2, 0), w, T.GOAL)

	var cc := CharacterController.new(Vector2i(0, 0))
	var path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var goals: Array[Vector2i] = [Vector2i(2, 0)]

	cc.begin_walk(path)
	var continues: bool = cc.step(grid, w, h, goals)
	assert_false(continues)
	assert_eq(cc.current_state, S.DROWN)
	assert_true(cc.is_dead())
	assert_eq(cc.get_death_cause(), 0)


func test_death_on_scorched_is_burn() -> void:
	var w := 3
	var h := 1
	var grid := _make_grid(w, h, T.DRY_GRASS)
	_set(grid, Vector2i(0, 0), w, T.START)
	_set(grid, Vector2i(1, 0), w, T.SCORCHED)
	_set(grid, Vector2i(2, 0), w, T.GOAL)

	var cc := CharacterController.new(Vector2i(0, 0))
	var path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var goals: Array[Vector2i] = [Vector2i(2, 0)]

	cc.begin_walk(path)
	var continues: bool = cc.step(grid, w, h, goals)
	assert_false(continues)
	assert_eq(cc.current_state, S.BURN)
	assert_true(cc.is_dead())
	assert_eq(cc.get_death_cause(), 1)


func test_death_on_empty_is_fall() -> void:
	var w := 3
	var h := 1
	var grid := _make_grid(w, h, T.DRY_GRASS)
	_set(grid, Vector2i(0, 0), w, T.START)
	_set(grid, Vector2i(1, 0), w, T.EMPTY)
	_set(grid, Vector2i(2, 0), w, T.GOAL)

	var cc := CharacterController.new(Vector2i(0, 0))
	var path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var goals: Array[Vector2i] = [Vector2i(2, 0)]

	cc.begin_walk(path)
	var continues: bool = cc.step(grid, w, h, goals)
	assert_false(continues)
	assert_eq(cc.current_state, S.FALL)
	assert_eq(cc.get_death_cause(), 2)


func test_death_on_steam_is_fall() -> void:
	var w := 3
	var h := 1
	var grid := _make_grid(w, h, T.DRY_GRASS)
	_set(grid, Vector2i(0, 0), w, T.START)
	_set(grid, Vector2i(1, 0), w, T.STEAM)
	_set(grid, Vector2i(2, 0), w, T.GOAL)

	var cc := CharacterController.new(Vector2i(0, 0))
	var path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var goals: Array[Vector2i] = [Vector2i(2, 0)]

	cc.begin_walk(path)
	var continues: bool = cc.step(grid, w, h, goals)
	assert_false(continues)
	assert_eq(cc.current_state, S.FALL)


func test_begin_walk_single_tile_stays_idle() -> void:
	var cc := CharacterController.new(Vector2i(0, 0))
	var path: Array[Vector2i] = [Vector2i(0, 0)]
	cc.begin_walk(path)
	assert_eq(cc.current_state, S.IDLE)


func test_trigger_surprised_from_idle() -> void:
	var cc := CharacterController.new(Vector2i(0, 0))
	cc.trigger_surprised()
	assert_eq(cc.current_state, S.SURPRISED)
	cc.return_to_idle()
	assert_eq(cc.current_state, S.IDLE)


func test_step_when_not_walking_returns_false() -> void:
	var cc := CharacterController.new(Vector2i(0, 0))
	var grid: Array = [T.START]
	var goals: Array[Vector2i] = [Vector2i(0, 0)]
	assert_false(cc.step(grid, 1, 1, goals))


func test_facing_updates_during_walk() -> void:
	var w := 2
	var h := 2
	var grid := _make_grid(w, h, T.DRY_GRASS)
	_set(grid, Vector2i(0, 0), w, T.START)
	_set(grid, Vector2i(1, 1), w, T.GOAL)

	var cc := CharacterController.new(Vector2i(0, 0))
	var path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]
	var goals: Array[Vector2i] = [Vector2i(1, 1)]

	cc.begin_walk(path)
	cc.step(grid, w, h, goals)
	assert_eq(cc.facing, Vector2i(1, 0))
	cc.step(grid, w, h, goals)
	assert_eq(cc.facing, Vector2i(0, 1))
