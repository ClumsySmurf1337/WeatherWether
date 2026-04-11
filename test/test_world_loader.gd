## WorldLoader metadata and path layout tests.
extends GutTest

const LEVELS_PER_WORLD: int = 22


func test_load_all_worlds_returns_valid_layouts() -> void:
	var worlds: Array[WorldData] = WorldLoader.load_all_worlds()
	assert_eq(worlds.size(), 6)
	for world: WorldData in worlds:
		assert_true(world.is_valid())
		assert_eq(world.path_layout.size(), LEVELS_PER_WORLD)
		for i: int in range(world.path_layout.size()):
			var row: Dictionary = world.path_layout[i] as Dictionary
			assert_true(row.has("level"))
			assert_true(row.has("x"))
			assert_true(row.has("y"))
			assert_eq(int(row["level"]), i + 1)
			var xf: float = float(row["x"])
			var yf: float = float(row["y"])
			assert_true(xf >= 0.0 and xf <= 1.0)
			assert_true(yf >= 0.0 and yf <= 1.0)
