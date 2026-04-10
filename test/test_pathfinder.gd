extends GutTest

func _grid_filled(width: int, height: int, terrain: WeatherType.Terrain) -> Array:
	var cells: Array = []
	cells.resize(width * height)
	var v: int = terrain as int
	for i in range(cells.size()):
		cells[i] = v
	return cells


func test_trivial_one_step_horizontal() -> void:
	var w := 3
	var h := 1
	var grid := _grid_filled(w, h, WeatherType.Terrain.DRY_GRASS)
	var path := Pathfinder.find_path(grid, w, h, Vector2i(0, 0), Vector2i(1, 0))
	assert_eq(path.size(), 2)
	assert_eq(path[0], Vector2i(0, 0))
	assert_eq(path[1], Vector2i(1, 0))


func test_blocked_path_returns_empty() -> void:
	var w := 3
	var h := 1
	var grid := _grid_filled(w, h, WeatherType.Terrain.DRY_GRASS)
	grid[1] = WeatherType.Terrain.WATER as int
	var path := Pathfinder.find_path(grid, w, h, Vector2i(0, 0), Vector2i(2, 0))
	assert_eq(path.size(), 0)


func test_finds_shortest_in_open_field() -> void:
	var w := 5
	var h := 5
	var grid := _grid_filled(w, h, WeatherType.Terrain.DRY_GRASS)
	var start := Vector2i(0, 0)
	var goal := Vector2i(4, 4)
	var path := Pathfinder.find_path(grid, w, h, start, goal)
	assert_true(path.size() > 0)
	assert_eq(path[0], start)
	assert_eq(path[path.size() - 1], goal)
	assert_eq(path.size(), 9)


func test_identical_cost_prefers_straighter_primary_axis() -> void:
	var w := 2
	var h := 2
	var grid := _grid_filled(w, h, WeatherType.Terrain.DRY_GRASS)
	var path := Pathfinder.find_path(grid, w, h, Vector2i(0, 0), Vector2i(1, 1))
	assert_eq(path.size(), 3)
	assert_eq(path[0], Vector2i(0, 0))
	assert_eq(path[1], Vector2i(1, 0))
	assert_eq(path[2], Vector2i(1, 1))


func test_straight_line_when_unique_shortest() -> void:
	var w := 5
	var h := 1
	var grid := _grid_filled(w, h, WeatherType.Terrain.DRY_GRASS)
	var path := Pathfinder.find_path(grid, w, h, Vector2i(0, 0), Vector2i(4, 0))
	assert_eq(path.size(), 5)
	for i in range(path.size()):
		assert_eq(path[i].y, 0)


func test_start_equals_goal_is_single_tile() -> void:
	var grid := _grid_filled(3, 3, WeatherType.Terrain.DRY_GRASS)
	var p := Vector2i(1, 1)
	var path := Pathfinder.find_path(grid, 3, 3, p, p)
	assert_eq(path.size(), 1)
	assert_eq(path[0], p)


func test_off_grid_goal_returns_empty() -> void:
	var grid := _grid_filled(2, 2, WeatherType.Terrain.DRY_GRASS)
	var path := Pathfinder.find_path(grid, 2, 2, Vector2i(0, 0), Vector2i(5, 0))
	assert_eq(path.size(), 0)


func test_non_walkable_goal_returns_empty() -> void:
	var grid := _grid_filled(2, 1, WeatherType.Terrain.DRY_GRASS)
	grid[1] = WeatherType.Terrain.STONE as int
	var path := Pathfinder.find_path(grid, 2, 1, Vector2i(0, 0), Vector2i(1, 0))
	assert_eq(path.size(), 0)
