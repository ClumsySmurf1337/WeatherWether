## World metadata and level list container.
class_name WorldData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var mood: String = ""
@export var level_count: int = 22
@export var music_path: String = ""
@export var ambient_path: String = ""
@export var card_pool: Array[int] = []

var levels: Array[LevelData] = []
var path_layout: Array = []


func is_valid() -> bool:
	if id.is_empty():
		return false
	if name.is_empty():
		return false
	if level_count <= 0:
		return false
	return true
