## Grid state + queue + undo for the sequence model (GDD §3–4).
## Pure logic — no TileMapLayer, no rendering. Visualization is in ui/widgets/grid_view.gd.
class_name GridManager
extends RefCounted

const T := WeatherType.Terrain

var width: int
var height: int
var terrain: Array
var initial_terrain: Array

var queue: Array  # Array of [card_type: int, pos: Vector2i]
var max_queue_size: int


func _init(level_width: int = 5, level_height: int = 5, max_moves: int = 6) -> void:
	width = level_width
	height = level_height
	max_queue_size = max_moves
	terrain = []
	terrain.resize(width * height)
	for i in range(terrain.size()):
		terrain[i] = T.EMPTY as int
	initial_terrain = terrain.duplicate()
	queue = []


## Initialise from a LevelData-style flat terrain array.
func load_terrain(source: Array, w: int, h: int, max_moves: int) -> void:
	width = w
	height = h
	max_queue_size = max_moves
	terrain = source.duplicate()
	initial_terrain = source.duplicate()
	queue = []


# -----------------------------------------------------------------------
# Planning phase
# -----------------------------------------------------------------------

func queue_card(card_type: int, pos: Vector2i) -> bool:
	if not can_queue():
		return false
	if not is_in_bounds(pos):
		return false
	queue.append([card_type, pos])
	return true


func unqueue_last() -> bool:
	if queue.is_empty():
		return false
	queue.pop_back()
	return true


func clear_queue() -> void:
	queue.clear()


func get_queue() -> Array:
	return queue.duplicate()


func can_queue() -> bool:
	return queue.size() < max_queue_size


# -----------------------------------------------------------------------
# Sequence resolution (called one card at a time by animation director)
# -----------------------------------------------------------------------

## Resolve the next queued card against the live terrain.
## Returns a Dictionary { "card_type": int, "pos": Vector2i } or empty if queue is spent.
func resolve_next_card() -> Dictionary:
	if queue.is_empty():
		return {}
	var entry: Array = queue.pop_front()
	var card_type: int = entry[0]
	var pos: Vector2i = entry[1]
	terrain = WeatherSystem.apply(terrain, width, height, card_type, pos)
	return { "card_type": card_type, "pos": pos }


func reset_to_initial() -> void:
	terrain = initial_terrain.duplicate()
	queue.clear()


# -----------------------------------------------------------------------
# Read-only access
# -----------------------------------------------------------------------

func get_terrain_at(pos: Vector2i) -> int:
	if not is_in_bounds(pos):
		return T.EMPTY as int
	return terrain[pos.y * width + pos.x]


## Return the grid state after applying all currently queued cards (preview).
func get_preview_grid() -> Array:
	var preview: Array = terrain.duplicate()
	for entry: Array in queue:
		var card_type: int = entry[0]
		var pos: Vector2i = entry[1]
		preview = WeatherSystem.apply(preview, width, height, card_type, pos)
	return preview


func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height


func set_terrain_at(pos: Vector2i, t: int) -> bool:
	if not is_in_bounds(pos):
		return false
	terrain[pos.y * width + pos.x] = t
	return true
