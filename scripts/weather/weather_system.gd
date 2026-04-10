## Resolves one queued weather card onto the grid (sequence model: GDD §4–5).
## Card identity is **`WeatherType.Card`** from `weather_type.gd` (GDD §5–6, `SPEC_DIFF.md` §2 — canonical enums).
## Still a stub vs GDD: `GridManager` uses a reduced terrain set; target is 14 terrains + pure `apply(grid copy) → grid`
## with full matrix, wind cross, fog 3×3, lightning flood-fill (`SPEC_DIFF.md` weather_system row).
class_name WeatherSystem
extends Node

## Uses global `WeatherType.Card` only — never shadow `WeatherType` with a local enum (breaks GDScript typing).

signal weather_applied(card: WeatherType.Card, target: Vector2i)

var grid: GridManager

func setup(grid_manager: GridManager) -> void:
  grid = grid_manager

func apply_weather(card: WeatherType.Card, target: Vector2i) -> bool:
  if grid == null:
    return false
  if not grid.is_in_bounds(target):
    return false

  var terrain: GridManager.Terrain = grid.get_terrain(target)
  match card:
    WeatherType.Card.RAIN:
      if terrain == GridManager.Terrain.DRY:
        grid.set_terrain(target, GridManager.Terrain.WET)
      elif terrain == GridManager.Terrain.EMPTY:
        grid.set_terrain(target, GridManager.Terrain.WATER)
    WeatherType.Card.SUN:
      if terrain == GridManager.Terrain.WET:
        grid.set_terrain(target, GridManager.Terrain.DRY)
      elif terrain == GridManager.Terrain.ICE:
        grid.set_terrain(target, GridManager.Terrain.WATER)
    WeatherType.Card.FROST:
      if terrain == GridManager.Terrain.WET or terrain == GridManager.Terrain.WATER:
        grid.set_terrain(target, GridManager.Terrain.ICE)
    WeatherType.Card.FOG:
      grid.set_terrain(target, GridManager.Terrain.FOG)
    WeatherType.Card.WIND, WeatherType.Card.LIGHTNING:
      pass

  weather_applied.emit(card, target)
  return true
