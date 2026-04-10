## Loads and saves LevelData as JSON files.
class_name LevelLoader
extends RefCounted


static func load_from_json(path: String) -> LevelData:
	if not FileAccess.file_exists(path):
		push_error("LevelLoader: file not found: %s" % path)
		return null

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("LevelLoader: cannot open: %s" % path)
		return null

	var text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err: int = json.parse(text)
	if err != OK:
		push_error("LevelLoader: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return null

	var data: Variant = json.data
	if not data is Dictionary:
		push_error("LevelLoader: root is not a Dictionary in %s" % path)
		return null

	return _dict_to_level(data as Dictionary)


static func save_to_json(level: LevelData, path: String) -> bool:
	var dict: Dictionary = _level_to_dict(level)
	var text: String = JSON.stringify(dict, "  ")

	var tmp_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("LevelLoader: cannot write: %s" % tmp_path)
		return false

	file.store_string(text)
	file.close()

	var global_path: String = ProjectSettings.globalize_path(path)
	var global_tmp: String = ProjectSettings.globalize_path(tmp_path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(global_path)
	DirAccess.rename_absolute(global_tmp, global_path)
	return true


static func _dict_to_level(d: Dictionary) -> LevelData:
	var level := LevelData.new()
	level.id = d.get("id", "") as String
	level.world = d.get("world", 1) as int
	level.level_number = d.get("level_number", 1) as int
	level.display_name = d.get("display_name", "") as String
	level.hint_text = d.get("hint_text", "") as String
	level.width = d.get("width", 5) as int
	level.height = d.get("height", 5) as int

	var raw_terrain: Array = d.get("initial_terrain", []) as Array
	level.initial_terrain = []
	for t: Variant in raw_terrain:
		level.initial_terrain.append(int(t))

	var sp: Variant = d.get("start_position", [0, 0])
	if sp is Array:
		var spa: Array = sp as Array
		level.start_position = Vector2i(int(spa[0]), int(spa[1]))

	var gp_raw: Variant = d.get("goal_positions", [])
	level.goal_positions = []
	if gp_raw is Array:
		for g: Variant in gp_raw as Array:
			if g is Array:
				var ga: Array = g as Array
				level.goal_positions.append(Vector2i(int(ga[0]), int(ga[1])))

	var raw_cards: Array = d.get("available_cards", []) as Array
	level.available_cards = []
	for c: Variant in raw_cards:
		level.available_cards.append(int(c))

	level.max_moves = d.get("max_moves", 0) as int
	level.par_moves = d.get("par_moves", 0) as int
	level.target_difficulty = d.get("target_difficulty", 1) as int
	level.min_solution_length = d.get("min_solution_length", 0) as int
	level.unique_solution = d.get("unique_solution", false) as bool

	return level


static func _level_to_dict(level: LevelData) -> Dictionary:
	var goals: Array = []
	for gp: Vector2i in level.goal_positions:
		goals.append([gp.x, gp.y])

	return {
		"id": level.id,
		"world": level.world,
		"level_number": level.level_number,
		"display_name": level.display_name,
		"hint_text": level.hint_text,
		"width": level.width,
		"height": level.height,
		"initial_terrain": level.initial_terrain,
		"start_position": [level.start_position.x, level.start_position.y],
		"goal_positions": goals,
		"available_cards": level.available_cards,
		"max_moves": level.max_moves,
		"par_moves": level.par_moves,
		"target_difficulty": level.target_difficulty,
		"min_solution_length": level.min_solution_length,
		"unique_solution": level.unique_solution,
	}
