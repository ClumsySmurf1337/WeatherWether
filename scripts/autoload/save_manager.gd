## Autoload: persists player progress, settings, and stats to JSON (GDD §11).
## Atomic writes via .tmp + rename. Schema versioned for future migrations.
extends Node

const SAVE_PATH: String = "user://save_default.json"
const SCHEMA_VERSION: int = 1

var data: Dictionary = {}


func _ready() -> void:
	load_save()


func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		_init_default()
		return false

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_init_default()
		return false

	var text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err: int = json.parse(text)
	if err != OK:
		push_warning("SaveManager: corrupt save — reinitialising")
		_init_default()
		return false

	if not json.data is Dictionary:
		_init_default()
		return false

	data = json.data as Dictionary
	var version: int = data.get("version", 0) as int
	if version < SCHEMA_VERSION:
		_migrate(version)
	return true


func save() -> bool:
	data["updated_at"] = Time.get_datetime_string_from_system(true)

	var text: String = JSON.stringify(data, "  ")
	var tmp_path: String = SAVE_PATH + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s" % tmp_path)
		return false

	file.store_string(text)
	file.close()

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(SAVE_PATH)
		)
	var global_tmp: String = ProjectSettings.globalize_path(tmp_path)
	var global_save: String = ProjectSettings.globalize_path(SAVE_PATH)
	DirAccess.rename_absolute(global_tmp, global_save)
	return true


func reset_progress() -> void:
	_init_default()
	save()


func record_level_complete(level_id: String, stars: int, moves: int, time_ms: int) -> void:
	var levels: Dictionary = data.get("levels", {}) as Dictionary
	var existing: Dictionary = levels.get(level_id, {}) as Dictionary

	var prev_stars: int = existing.get("stars", 0) as int
	var prev_moves: int = existing.get("best_moves", 999999) as int
	var prev_time: int = existing.get("best_time_ms", 999999) as int

	existing["completed"] = true
	existing["stars"] = maxi(stars, prev_stars)
	existing["best_moves"] = mini(moves, prev_moves)
	existing["best_time_ms"] = mini(time_ms, prev_time)
	levels[level_id] = existing
	data["levels"] = levels

	var progress: Dictionary = data.get("progress", {}) as Dictionary
	var total_stars: int = 0
	for lid: String in levels:
		total_stars += (levels[lid] as Dictionary).get("stars", 0) as int
	progress["total_stars"] = total_stars
	data["progress"] = progress

	var stats: Dictionary = data.get("stats", {}) as Dictionary
	if stars == 3:
		stats["perfect_solves"] = (stats.get("perfect_solves", 0) as int) + 1
	data["stats"] = stats

	save()


func get_level_record(level_id: String) -> Dictionary:
	var levels: Dictionary = data.get("levels", {}) as Dictionary
	return levels.get(level_id, {}) as Dictionary


func get_setting(key: String, default_value: Variant = null) -> Variant:
	var settings: Dictionary = data.get("settings", {}) as Dictionary
	return settings.get(key, default_value)


func set_setting(key: String, value: Variant) -> void:
	var settings: Dictionary = data.get("settings", {}) as Dictionary
	settings[key] = value
	data["settings"] = settings
	save()
	EventBus.settings_changed.emit(key, value)


func _init_default() -> void:
	data = {
		"version": SCHEMA_VERSION,
		"profile_id": "default",
		"created_at": Time.get_datetime_string_from_system(true),
		"updated_at": Time.get_datetime_string_from_system(true),
		"settings": {
			"master_volume": 1.0,
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"color_blind_mode": "off",
			"reduce_motion": false,
			"language": "en",
		},
		"progress": {
			"current_world": 1,
			"current_level": 1,
			"highest_unlocked": "w1_l01",
			"total_stars": 0,
		},
		"levels": {},
		"stats": {
			"total_play_time_ms": 0,
			"hints_used": 0,
			"perfect_solves": 0,
		},
	}


func _migrate(from_version: int) -> void:
	if from_version < 1:
		data["version"] = SCHEMA_VERSION
