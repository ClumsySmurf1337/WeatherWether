extends GutTest

var grid: GridManager
var weather: WeatherSystem

func before_each() -> void:
  grid = GridManager.new()
  grid.reset_grid(3, 3)
  weather = WeatherSystem.new()
  weather.setup(grid)

func test_rain_turns_dry_to_wet() -> void:
  var pos := Vector2i(0, 0)
  grid.set_terrain(pos, GridManager.Terrain.DRY)
  weather.apply_weather(WeatherSystem.WeatherType.RAIN, pos)
  assert_eq(grid.get_terrain(pos), GridManager.Terrain.WET)

func test_frost_turns_water_to_ice() -> void:
  var pos := Vector2i(1, 1)
  grid.set_terrain(pos, GridManager.Terrain.WATER)
  weather.apply_weather(WeatherSystem.WeatherType.FROST, pos)
  assert_eq(grid.get_terrain(pos), GridManager.Terrain.ICE)
