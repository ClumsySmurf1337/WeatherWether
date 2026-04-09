class_name GridManager
extends Node2D

enum Terrain {
  EMPTY,
  DRY,
  WET,
  WATER,
  ICE,
  FOG
}

var width: int = 5
var height: int = 5
var cells: Array[int] = []

func _ready() -> void:
  reset_grid(width, height)

func reset_grid(new_width: int, new_height: int) -> void:
  width = new_width
  height = new_height
  cells.clear()
  cells.resize(width * height)
  for i in range(cells.size()):
    cells[i] = Terrain.EMPTY

func is_in_bounds(pos: Vector2i) -> bool:
  return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func index_of(pos: Vector2i) -> int:
  return pos.y * width + pos.x

func set_terrain(pos: Vector2i, terrain: Terrain) -> bool:
  if not is_in_bounds(pos):
    return false
  cells[index_of(pos)] = int(terrain)
  return true

func get_terrain(pos: Vector2i) -> Terrain:
  if not is_in_bounds(pos):
    return Terrain.EMPTY
  return cells[index_of(pos)] as Terrain
