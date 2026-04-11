## Autoload: persists player progress, settings, and stats to JSON (GDD §11).
## Atomic writes via .tmp + rename. Schema versioned for future migrations.
extends Node

const SAVE_PATH: String = "user://save_default.json"
const SCHEMA_VERSION: int = 1
const TMP_SUFFIX: String = ".tmp"

var save_path: String = SAVE_PATH
var data: Dictionary = {}
var _level_start_ms: int = -1


func _ready() -> void:
	load_save()
	_connect_event_bus()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			save()


func load_save() -> bool:
	if not FileAccess.file_exists(save_path):
		_init_default()
		return false

	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
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
	_ensure_schema_defaults()
	return true


func save() -> bool:
	if data.is_empty():
		_init_default()
	data["updated_at"] = Time.get_datetime_string_from_system(true)

	var text: String = JSON.stringify(data, "  ")
	var tmp_path: String = _tmp_path()
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s" % tmp_path)
		return false

	file.store_string(text)
	file.close()

	var global_tmp: String = ProjectSettings.globalize_path(tmp_path)
	var global_save: String = ProjectSettings.globalize_path(save_path)
	if FileAccess.file_exists(save_path):
		var remove_err: int = DirAccess.remove_absolute(global_save)
		if remove_err != OK:
			push_error("SaveManager: cannot replace %s" % save_path)
			return false
	var rename_err: int = DirAccess.rename_absolute(global_tmp, global_save)
	if rename_err != OK:
		push_error("SaveManager: cannot finalize save to %s" % save_path)
		return false
	return true


func reset_progress() -> void:
	_init_default()
	save()


func record_level_complete(level_id: String, stars: int, moves: int, time_ms: int) -> void:
	var levels: Dictionary = data.get("levels", {}) as Dictionary
	var existing: Dictionary = levels.get(level_id, {}) as Dictionary

	var prev_stars: int = existing.get("stars", 0) as int
	var prev_moves: int = existing.get("best_moves", 999999) as int
	var prev_time: int = existing.get("best_time_ms", -1) as int

	existing["completed"] = true
	existing["stars"] = maxi(stars, prev_stars)
	existing["best_moves"] = mini(moves, prev_moves)
	if time_ms >= 0:
		existing["best_time_ms"] = time_ms if prev_time < 0 else mini(time_ms, prev_time)
	elif not existing.has("best_time_ms"):
		existing["best_time_ms"] = -1
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
	if time_ms >= 0:
		stats["total_play_time_ms"] = (stats.get("total_play_time_ms", 0) as int) + time_ms
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
	data = _default_schema()


func _migrate(from_version: int) -> void:
	if from_version < 1:
		data["version"] = SCHEMA_VERSION
	_ensure_schema_defaults()


func _default_schema() -> Dictionary:
	var now: String = Time.get_datetime_string_from_system(true)
	return {
		"version": SCHEMA_VERSION,
		"profile_id": "default",
		"created_at": now,
		"updated_at": now,
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


func _ensure_schema_defaults() -> void:
	var defaults: Dictionary = _default_schema()
	for key: String in defaults.keys():
		if not data.has(key) or typeof(data[key]) != typeof(defaults[key]):
			data[key] = defaults[key]

	var settings: Dictionary = data.get("settings", {}) as Dictionary
	var default_settings: Dictionary = defaults["settings"] as Dictionary
	for key: String in default_settings.keys():
		if not settings.has(key):
			settings[key] = default_settings[key]
	data["settings"] = settings

	var progress: Dictionary = data.get("progress", {}) as Dictionary
	var default_progress: Dictionary = defaults["progress"] as Dictionary
	for key: String in default_progress.keys():
		if not progress.has(key):
			progress[key] = default_progress[key]
	data["progress"] = progress

	var stats: Dictionary = data.get("stats", {}) as Dictionary
	var default_stats: Dictionary = defaults["stats"] as Dictionary
	for key: String in default_stats.keys():
		if not stats.has(key):
			stats[key] = default_stats[key]
	data["stats"] = stats

	if not (data.get("levels") is Dictionary):
		data["levels"] = {}


func _tmp_path() -> String:
	return save_path + TMP_SUFFIX


func _connect_event_bus() -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus == null:
		return
	if bus.has_signal("level_started"):
		bus.connect("level_started", _on_level_started)
	if bus.has_signal("level_completed"):
		bus.connect("level_completed", _on_level_completed)


func _on_level_started(_level: Variant) -> void:
	_level_start_ms = Time.get_ticks_msec()


func _on_level_completed(level_id: String, stars: int, moves_used: int) -> void:
	var elapsed: int = -1
	if _level_start_ms >= 0:
		elapsed = maxi(0, Time.get_ticks_msec() - _level_start_ms)
	record_level_complete(level_id, stars, moves_used, elapsed)
