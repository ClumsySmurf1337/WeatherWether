class_name WeatherSystem
extends Node

enum WeatherType {
  RAIN,
  SUN,
  FROST,
  WIND,
  LIGHTNING,
  FOG
}

signal weather_applied(weather: WeatherType, target: Vector2i)

var grid: GridManager

func setup(grid_manager: GridManager) -> void:
  grid = grid_manager

func apply_weather(weather: WeatherType, target: Vector2i) -> bool:
  if grid == null:
    return false
  if not grid.is_in_bounds(target):
    return false

  var terrain: GridManager.Terrain = grid.get_terrain(target)
  match weather:
    WeatherType.RAIN:
      if terrain == GridManager.Terrain.DRY:
        grid.set_terrain(target, GridManager.Terrain.WET)
      elif terrain == GridManager.Terrain.EMPTY:
        grid.set_terrain(target, GridManager.Terrain.WATER)
    WeatherType.SUN:
      if terrain == GridManager.Terrain.WET:
        grid.set_terrain(target, GridManager.Terrain.DRY)
      elif terrain == GridManager.Terrain.ICE:
        grid.set_terrain(target, GridManager.Terrain.WATER)
    WeatherType.FROST:
      if terrain == GridManager.Terrain.WET or terrain == GridManager.Terrain.WATER:
        grid.set_terrain(target, GridManager.Terrain.ICE)
    WeatherType.FOG:
      grid.set_terrain(target, GridManager.Terrain.FOG)
    WeatherType.WIND, WeatherType.LIGHTNING:
      pass

  weather_applied.emit(weather, target)
  return true
