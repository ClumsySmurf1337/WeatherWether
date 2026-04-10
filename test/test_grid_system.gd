## GridManager v2 test coverage: terrain, queue, undo, preview, reset.
extends GutTest

const T := WeatherType.Terrain
const C := WeatherType.Card


func _make_manager(w: int = 3, h: int = 3, max_moves: int = 3) -> GridManager:
	var gm := GridManager.new(w, h, max_moves)
	return gm


func test_initial_terrain_is_empty() -> void:
	var gm := _make_manager()
	assert_eq(gm.get_terrain_at(Vector2i(0, 0)), T.EMPTY as int)


func test_set_and_get_terrain() -> void:
	var gm := _make_manager()
	var ok := gm.set_terrain_at(Vector2i(1, 1), T.WET_GRASS)
	assert_true(ok)
	assert_eq(gm.get_terrain_at(Vector2i(1, 1)), T.WET_GRASS as int)


func test_out_of_bounds_get_returns_empty() -> void:
	var gm := _make_manager()
	assert_eq(gm.get_terrain_at(Vector2i(99, 99)), T.EMPTY as int)


func test_out_of_bounds_set_returns_false() -> void:
	var gm := _make_manager()
	assert_false(gm.set_terrain_at(Vector2i(-1, 0), T.WATER))


func test_queue_card_succeeds() -> void:
	var gm := _make_manager()
	assert_true(gm.queue_card(C.RAIN, Vector2i(0, 0)))
	assert_eq(gm.get_queue().size(), 1)


func test_queue_respects_max_size() -> void:
	var gm := _make_manager(3, 3, 2)
	gm.queue_card(C.RAIN, Vector2i(0, 0))
	gm.queue_card(C.SUN, Vector2i(1, 0))
	assert_false(gm.can_queue())
	assert_false(gm.queue_card(C.FROST, Vector2i(2, 0)))


func test_unqueue_last_removes_last_card() -> void:
	var gm := _make_manager()
	gm.queue_card(C.RAIN, Vector2i(0, 0))
	gm.queue_card(C.SUN, Vector2i(1, 0))
	assert_true(gm.unqueue_last())
	assert_eq(gm.get_queue().size(), 1)


func test_unqueue_on_empty_returns_false() -> void:
	var gm := _make_manager()
	assert_false(gm.unqueue_last())


func test_clear_queue_empties_it() -> void:
	var gm := _make_manager()
	gm.queue_card(C.RAIN, Vector2i(0, 0))
	gm.queue_card(C.SUN, Vector2i(1, 0))
	gm.clear_queue()
	assert_eq(gm.get_queue().size(), 0)
	assert_true(gm.can_queue())


func test_resolve_next_card_applies_weather() -> void:
	var gm := _make_manager()
	gm.set_terrain_at(Vector2i(0, 0), T.DRY_GRASS)
	gm.queue_card(C.RAIN, Vector2i(0, 0))
	var result := gm.resolve_next_card()
	assert_eq(result["card_type"], C.RAIN as int)
	assert_eq(gm.get_terrain_at(Vector2i(0, 0)), T.WET_GRASS as int)


func test_resolve_on_empty_queue_returns_empty_dict() -> void:
	var gm := _make_manager()
	var result := gm.resolve_next_card()
	assert_eq(result.size(), 0)


func test_reset_to_initial_restores_terrain_and_clears_queue() -> void:
	var gm := _make_manager()
	gm.set_terrain_at(Vector2i(0, 0), T.DRY_GRASS)
	gm.terrain = gm.terrain.duplicate()
	gm.initial_terrain = gm.terrain.duplicate()
	gm.queue_card(C.SUN, Vector2i(0, 0))
	gm.resolve_next_card()
	assert_eq(gm.get_terrain_at(Vector2i(0, 0)), T.SCORCHED as int)
	gm.reset_to_initial()
	assert_eq(gm.get_terrain_at(Vector2i(0, 0)), T.DRY_GRASS as int)
	assert_eq(gm.get_queue().size(), 0)


func test_get_preview_grid_shows_future_state() -> void:
	var gm := _make_manager()
	gm.set_terrain_at(Vector2i(0, 0), T.DRY_GRASS)
	gm.initial_terrain = gm.terrain.duplicate()
	gm.queue_card(C.RAIN, Vector2i(0, 0))
	var preview := gm.get_preview_grid()
	assert_eq(preview[0], T.WET_GRASS as int)
	# Actual terrain unchanged until resolve
	assert_eq(gm.get_terrain_at(Vector2i(0, 0)), T.DRY_GRASS as int)


func test_load_terrain_initialises_correctly() -> void:
	var source: Array = [T.START, T.DRY_GRASS, T.WATER, T.GOAL]
	var gm := GridManager.new()
	gm.load_terrain(source, 2, 2, 4)
	assert_eq(gm.width, 2)
	assert_eq(gm.height, 2)
	assert_eq(gm.get_terrain_at(Vector2i(0, 0)), T.START as int)
	assert_eq(gm.get_terrain_at(Vector2i(1, 1)), T.GOAL as int)
	assert_eq(gm.max_queue_size, 4)


func test_queue_rejects_out_of_bounds_position() -> void:
	var gm := _make_manager()
	assert_false(gm.queue_card(C.RAIN, Vector2i(99, 99)))
