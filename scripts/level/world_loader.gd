## Loads world metadata, level lists, and path layouts.
class_name WorldLoader
extends RefCounted

const LEVELS_PER_WORLD: int = 22


static func load_world(world_id: String) -> WorldData:
	var index: int = _resolve_world_index(world_id)
	if index <= 0:
		push_error("WorldLoader: unknown world id %s" % world_id)
		return null

	var defs: Array = _world_defs()
	if index > defs.size():
		push_error("WorldLoader: missing world definition for %s" % world_id)
		return null

	var def: Dictionary = defs[index - 1] as Dictionary
	var world := WorldData.new()
	world.id = def.get("id", "") as String
	world.name = def.get("name", "") as String
	world.mood = def.get("mood", "") as String
	world.level_count = def.get("level_count", LEVELS_PER_WORLD) as int
	world.music_path = def.get("music_path", "") as String
	world.ambient_path = def.get("ambient_path", "") as String

	var pool: Array = def.get("card_pool", []) as Array
	world.card_pool = []
	for card: Variant in pool:
		world.card_pool.append(int(card))
	world.levels = _load_levels_for_world(index)
	world.path_layout = load_path_layout(world.id)
	return world


static func load_all_worlds() -> Array[WorldData]:
	var worlds: Array[WorldData] = []
	for i: int in range(1, 7):
		var world: WorldData = load_world("world%d" % i)
		if world != null:
			worlds.append(world)
	return worlds


static func load_path_layout(world_id: String) -> Array:
	var index: int = _resolve_world_index(world_id)
	if index <= 0:
		push_error("WorldLoader: unknown world id %s" % world_id)
		return []

	var path: String = "res://levels/world%d/path.json" % index
	if not FileAccess.file_exists(path):
		push_error("WorldLoader: path layout missing: %s" % path)
		return []

	var text: String = FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var err: int = json.parse(text)
	if err != OK:
		push_error("WorldLoader: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return []

	if not json.data is Array:
		push_error("WorldLoader: path layout root is not an Array in %s" % path)
		return []

	var nodes: Array = json.data as Array
	for i: int in range(nodes.size()):
		var entry: Variant = nodes[i]
		if not entry is Dictionary:
			push_error("WorldLoader: node %d is not a Dictionary in %s" % [i, path])
			return []
		var row: Dictionary = entry as Dictionary
		if not row.has("level") or not row.has("x") or not row.has("y"):
			push_error("WorldLoader: node %d missing level/x/y in %s" % [i, path])
			return []
		var xf: float = float(row["x"])
		var yf: float = float(row["y"])
		if xf < 0.0 or xf > 1.0 or yf < 0.0 or yf > 1.0:
			push_error("WorldLoader: node %d has out-of-range coords in %s" % [i, path])
			return []
	return nodes


static func _load_levels_for_world(world_index: int) -> Array[LevelData]:
	var levels: Array[LevelData] = []
	var folder: String = "res://levels/world%d" % world_index
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
		push_error("WorldLoader: missing folder %s" % folder)
		return levels

	var dir := DirAccess.open(folder)
	if dir == null:
		push_error("WorldLoader: cannot open folder %s" % folder)
		return levels

	dir.list_dir_begin()
	var file: String = dir.get_next()
	while file != "":
		if file == "." or file == "..":
			file = dir.get_next()
			continue
		if file == "path.json":
			file = dir.get_next()
			continue
		if file.ends_with(".json"):
			var path: String = "%s/%s" % [folder, file]
			var level: LevelData = LevelLoader.load_from_json(path)
			if level != null:
				levels.append(level)
		file = dir.get_next()

	levels.sort_custom(func(a, b):
		return a.level_number < b.level_number
	)
	return levels


static func _resolve_world_index(world_id: String) -> int:
	var trimmed: String = world_id.strip_edges().to_lower()
	if trimmed.begins_with("world"):
		trimmed = trimmed.substr(5, trimmed.length() - 5)
	elif trimmed.begins_with("w"):
		trimmed = trimmed.substr(1, trimmed.length() - 1)
	if trimmed.is_empty():
		return 0
	var idx: int = int(trimmed)
	if idx < 1 or idx > 6:
		return 0
	return idx


static func _world_defs() -> Array:
	return [
		{
			"id": "world1",
			"name": "Downpour",
			"mood": "Gentle, contemplative",
			"level_count": LEVELS_PER_WORLD,
			"music_path": "res://assets/audio/music/music_w1_downpour.ogg",
			"ambient_path": "res://assets/audio/ambient/ambient_rain.ogg",
			"card_pool": [WeatherType.Card.RAIN],
		},
		{
			"id": "world2",
			"name": "Heatwave",
			"mood": "Warm, slow",
			"level_count": LEVELS_PER_WORLD,
			"music_path": "res://assets/audio/music/music_w2_heatwave.ogg",
			"ambient_path": "res://assets/audio/ambient/ambient_cicadas.ogg",
			"card_pool": [WeatherType.Card.RAIN, WeatherType.Card.SUN],
		},
		{
			"id": "world3",
			"name": "Cold Snap",
			"mood": "Crystalline, sparse",
			"level_count": LEVELS_PER_WORLD,
			"music_path": "res://assets/audio/music/music_w3_coldsnap.ogg",
			"ambient_path": "res://assets/audio/ambient/ambient_wind_cold.ogg",
			"card_pool": [WeatherType.Card.RAIN, WeatherType.Card.SUN, WeatherType.Card.FROST],
		},
		{
			"id": "world4",
			"name": "Gale Force",
			"mood": "Airy, motion",
			"level_count": LEVELS_PER_WORLD,
			"music_path": "res://assets/audio/music/music_w4_galeforce.ogg",
			"ambient_path": "res://assets/audio/ambient/ambient_wind_strong.ogg",
			"card_pool": [
				WeatherType.Card.RAIN,
				WeatherType.Card.SUN,
				WeatherType.Card.FROST,
				WeatherType.Card.WIND,
			],
		},
		{
			"id": "world5",
			"name": "Thunderstorm",
			"mood": "Tense, low strings",
			"level_count": LEVELS_PER_WORLD,
			"music_path": "res://assets/audio/music/music_w5_thunderstorm.ogg",
			"ambient_path": "res://assets/audio/ambient/ambient_thunder_distant.ogg",
			"card_pool": [
				WeatherType.Card.RAIN,
				WeatherType.Card.SUN,
				WeatherType.Card.FROST,
				WeatherType.Card.WIND,
				WeatherType.Card.LIGHTNING,
			],
		},
		{
			"id": "world6",
			"name": "Whiteout",
			"mood": "Mysterious, choral",
			"level_count": LEVELS_PER_WORLD,
			"music_path": "res://assets/audio/music/music_w6_whiteout.ogg",
			"ambient_path": "res://assets/audio/ambient/ambient_silence_low.ogg",
			"card_pool": [
				WeatherType.Card.RAIN,
				WeatherType.Card.SUN,
				WeatherType.Card.FROST,
				WeatherType.Card.WIND,
				WeatherType.Card.LIGHTNING,
				WeatherType.Card.FOG,
			],
		},
	]
