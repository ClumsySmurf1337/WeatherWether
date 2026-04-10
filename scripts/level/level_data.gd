## Level resource matching GDD §7. Holds the full puzzle definition for one level.
class_name LevelData
extends Resource

@export var id: String = ""
@export var world: int = 1
@export var level_number: int = 1
@export var display_name: String = ""
@export var hint_text: String = ""

@export var width: int = 5
@export var height: int = 5

@export var initial_terrain: Array = []
@export var start_position: Vector2i = Vector2i.ZERO
@export var goal_positions: Array[Vector2i] = []

@export var available_cards: Array[int] = []
@export var max_moves: int = 0

@export var par_moves: int = 0
@export var target_difficulty: int = 1

@export var min_solution_length: int = 0
@export var unique_solution: bool = false


func is_valid() -> bool:
	if id.is_empty():
		return false
	if width <= 0 or height <= 0:
		return false
	if initial_terrain.size() != width * height:
		return false
	if not _pos_in_bounds(start_position):
		return false
	var start_terrain: int = initial_terrain[start_position.y * width + start_position.x]
	if not WeatherType.is_walkable(start_terrain as WeatherType.Terrain):
		return false
	if goal_positions.is_empty():
		return false
	for gp: Vector2i in goal_positions:
		if not _pos_in_bounds(gp):
			return false
	if max_moves < 0:
		return false
	if par_moves < 0 or par_moves > max_moves:
		return false
	return true


func _pos_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height
