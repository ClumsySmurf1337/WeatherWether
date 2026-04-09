extends GutTest

var grid: GridManager

func before_each() -> void:
  grid = GridManager.new()
  grid.reset_grid(3, 3)

func test_set_and_get_terrain() -> void:
  var pos := Vector2i(1, 1)
  var ok := grid.set_terrain(pos, GridManager.Terrain.WET)
  assert_true(ok)
  assert_eq(grid.get_terrain(pos), GridManager.Terrain.WET)

func test_out_of_bounds_rejected() -> void:
  var ok := grid.set_terrain(Vector2i(99, 99), GridManager.Terrain.WATER)
  assert_false(ok)
