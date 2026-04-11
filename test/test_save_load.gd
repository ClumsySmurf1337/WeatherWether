## SaveManager tests: schema defaults, round-trip, level records, settings.
extends GutTest

const _SaveManagerScript := preload("res://scripts/autoload/save_manager.gd")
const TEST_PATH: String = "user://test_save_tmp.json"
const BAD_PATH: String = "user://missing_dir/test_save_tmp.json"


func _make_manager(path: String = TEST_PATH, init_defaults: bool = true) -> Node:
	var sm: Node = _SaveManagerScript.new() as Node
	sm.save_path = path
	if init_defaults:
		sm._init_default()
	return sm


func _cleanup() -> void:
	var global: String = ProjectSettings.globalize_path(TEST_PATH)
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(global)
	var tmp: String = TEST_PATH + ".tmp"
	if FileAccess.file_exists(tmp):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	if FileAccess.file_exists(BAD_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BAD_PATH))
	var bad_dir: String = ProjectSettings.globalize_path("user://missing_dir")
	if DirAccess.dir_exists_absolute(bad_dir):
		DirAccess.remove_absolute(bad_dir)


func before_each() -> void:
	_cleanup()


func after_each() -> void:
	_cleanup()


func test_default_schema_has_required_keys() -> void:
	var sm: Node = _make_manager()
	assert_eq(sm.data.get("version"), _SaveManagerScript.SCHEMA_VERSION)
	assert_true(sm.data.has("settings"))
	assert_true(sm.data.has("progress"))
	assert_true(sm.data.has("levels"))
	assert_true(sm.data.has("stats"))


func test_default_settings() -> void:
	var sm: Node = _make_manager()
	assert_eq(sm.get_setting("master_volume"), 1.0)
	assert_eq(sm.get_setting("music_volume"), 0.8)
	assert_eq(sm.get_setting("sfx_volume"), 1.0)
	assert_eq(sm.get_setting("color_blind_mode"), "off")
	assert_eq(sm.get_setting("reduce_motion"), false)


func test_set_and_get_setting() -> void:
	var sm: Node = _make_manager()
	sm.set_setting("master_volume", 0.5)
	assert_eq(sm.get_setting("master_volume"), 0.5)


func test_get_setting_returns_default_for_missing_key() -> void:
	var sm: Node = _make_manager()
	assert_eq(sm.get_setting("nonexistent_key", 42), 42)


func test_record_level_complete_creates_entry() -> void:
	var sm: Node = _make_manager()
	sm.record_level_complete("w1_l01", 3, 4, 8000)
	var rec: Dictionary = sm.get_level_record("w1_l01")
	assert_true(rec.get("completed", false) as bool)
	assert_eq(rec.get("stars"), 3)
	assert_eq(rec.get("best_moves"), 4)
	assert_eq(rec.get("best_time_ms"), 8000)


func test_record_level_complete_keeps_best_scores() -> void:
	var sm: Node = _make_manager()
	sm.record_level_complete("w1_l01", 2, 6, 10000)
	sm.record_level_complete("w1_l01", 3, 4, 8000)
	var rec: Dictionary = sm.get_level_record("w1_l01")
	assert_eq(rec.get("stars"), 3)
	assert_eq(rec.get("best_moves"), 4)
	assert_eq(rec.get("best_time_ms"), 8000)


func test_record_level_complete_does_not_downgrade_stars() -> void:
	var sm: Node = _make_manager()
	sm.record_level_complete("w1_l01", 3, 4, 8000)
	sm.record_level_complete("w1_l01", 1, 6, 12000)
	var rec: Dictionary = sm.get_level_record("w1_l01")
	assert_eq(rec.get("stars"), 3)
	assert_eq(rec.get("best_moves"), 4)


func test_total_stars_accumulated() -> void:
	var sm: Node = _make_manager()
	sm.record_level_complete("w1_l01", 3, 4, 8000)
	sm.record_level_complete("w1_l02", 2, 5, 9000)
	var progress: Dictionary = sm.data.get("progress", {}) as Dictionary
	assert_eq(progress.get("total_stars"), 5)


func test_perfect_solves_counter() -> void:
	var sm: Node = _make_manager()
	sm.record_level_complete("w1_l01", 3, 4, 8000)
	sm.record_level_complete("w1_l02", 2, 5, 9000)
	sm.record_level_complete("w1_l03", 3, 3, 7000)
	var stats: Dictionary = sm.data.get("stats", {}) as Dictionary
	assert_eq(stats.get("perfect_solves"), 2)


func test_reset_progress_clears_data() -> void:
	var sm: Node = _make_manager()
	sm.record_level_complete("w1_l01", 3, 4, 8000)
	sm.reset_progress()
	var levels: Dictionary = sm.data.get("levels", {}) as Dictionary
	assert_eq(levels.size(), 0)


func test_get_level_record_for_missing_level_returns_empty() -> void:
	var sm: Node = _make_manager()
	var rec: Dictionary = sm.get_level_record("nonexistent")
	assert_eq(rec.size(), 0)


func test_migrate_from_version_zero() -> void:
	var sm: Node = _make_manager()
	sm.data["version"] = 0
	sm._migrate(0)
	assert_eq(sm.data.get("version"), _SaveManagerScript.SCHEMA_VERSION)


func test_load_save_missing_file_initialises_defaults() -> void:
	var sm: Node = _make_manager(TEST_PATH, false)
	var loaded: bool = sm.load_save()
	assert_false(loaded)
	assert_eq(sm.data.get("version"), _SaveManagerScript.SCHEMA_VERSION)


func test_load_save_corrupt_file_reinitialises() -> void:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("not-json")
	file.close()
	var sm: Node = _make_manager(TEST_PATH, false)
	var loaded: bool = sm.load_save()
	assert_false(loaded)
	assert_eq(sm.data.get("version"), _SaveManagerScript.SCHEMA_VERSION)


func test_round_trip_save_and_load() -> void:
	var sm: Node = _make_manager()
	sm.record_level_complete("w1_l01", 3, 4, 8000)
	assert_true(sm.save())
	var sm2: Node = _make_manager(TEST_PATH, false)
	assert_true(sm2.load_save())
	var rec: Dictionary = sm2.get_level_record("w1_l01")
	assert_eq(int(rec.get("stars", 0)), 3)
	assert_eq(int(rec.get("best_moves", 0)), 4)
	assert_eq(int(rec.get("best_time_ms", 0)), 8000)


func test_atomic_write_failure_returns_false() -> void:
	var sm: Node = _make_manager(BAD_PATH)
	assert_false(sm.save())
	assert_push_error("cannot write")


func test_load_save_migrates_version_zero() -> void:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 0}))
	file.close()
	var sm: Node = _make_manager(TEST_PATH, false)
	var loaded: bool = sm.load_save()
	assert_true(loaded)
	assert_eq(sm.data.get("version"), _SaveManagerScript.SCHEMA_VERSION)
