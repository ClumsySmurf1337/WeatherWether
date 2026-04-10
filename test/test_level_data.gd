## LevelData validation and LevelLoader round-trip tests.
extends GutTest

const T := WeatherType.Terrain


func _make_valid_level() -> LevelData:
	var level := LevelData.new()
	level.id = "w1_l01"
	level.world = 1
	level.level_number = 1
	level.display_name = "First Steps"
	level.hint_text = "Just walk forward."
	level.width = 3
	level.height = 1
	level.initial_terrain = [T.START, T.DRY_GRASS, T.GOAL]
	level.start_position = Vector2i(0, 0)
	level.goal_positions = [Vector2i(2, 0)]
	level.available_cards = []
	level.max_moves = 0
	level.par_moves = 0
	level.target_difficulty = 1
	return level


func test_valid_level_passes_validation() -> void:
	var level: LevelData = _make_valid_level()
	assert_true(level.is_valid())


func test_empty_id_is_invalid() -> void:
	var level: LevelData = _make_valid_level()
	level.id = ""
	assert_false(level.is_valid())


func test_wrong_terrain_size_is_invalid() -> void:
	var level: LevelData = _make_valid_level()
	level.initial_terrain = [T.START, T.DRY_GRASS]
	assert_false(level.is_valid())


func test_start_out_of_bounds_is_invalid() -> void:
	var level: LevelData = _make_valid_level()
	level.start_position = Vector2i(10, 10)
	assert_false(level.is_valid())


func test_start_on_unwalkable_is_invalid() -> void:
	var level: LevelData = _make_valid_level()
	level.initial_terrain[0] = T.WATER
	assert_false(level.is_valid())


func test_no_goals_is_invalid() -> void:
	var level: LevelData = _make_valid_level()
	level.goal_positions = []
	assert_false(level.is_valid())


func test_goal_out_of_bounds_is_invalid() -> void:
	var level: LevelData = _make_valid_level()
	level.goal_positions = [Vector2i(99, 99)]
	assert_false(level.is_valid())


func test_par_greater_than_max_is_invalid() -> void:
	var level: LevelData = _make_valid_level()
	level.max_moves = 3
	level.par_moves = 5
	assert_false(level.is_valid())


func test_json_round_trip() -> void:
	var level: LevelData = _make_valid_level()
	level.available_cards = [WeatherType.Card.RAIN, WeatherType.Card.FROST]
	level.max_moves = 2
	level.par_moves = 1

	var path: String = "user://test_level_roundtrip.json"
	var ok: bool = LevelLoader.save_to_json(level, path)
	assert_true(ok, "save should succeed")

	var loaded: LevelData = LevelLoader.load_from_json(path)
	assert_not_null(loaded, "load should return a LevelData")
	assert_eq(loaded.id, "w1_l01")
	assert_eq(loaded.width, 3)
	assert_eq(loaded.height, 1)
	assert_eq(loaded.initial_terrain.size(), 3)
	assert_eq(loaded.start_position, Vector2i(0, 0))
	assert_eq(loaded.goal_positions.size(), 1)
	assert_eq(loaded.goal_positions[0], Vector2i(2, 0))
	assert_eq(loaded.available_cards.size(), 2)
	assert_eq(loaded.max_moves, 2)
	assert_eq(loaded.par_moves, 1)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_load_missing_file_returns_null() -> void:
	var loaded: LevelData = LevelLoader.load_from_json("user://does_not_exist_12345.json")
	assert_null(loaded)
	assert_push_error("file not found")
