## Top-level orchestrator for the level lifecycle (GDD §3).
## Owns the current level's GridManager, CharacterController, and state transitions.
## All transitions emit EventBus signals so UI can react without coupling.
class_name GameManager
extends Node

enum GameState { BOOT, MAIN_MENU, LOADING, PLANNING, RESOLVING, WALKING, COMPLETE, FAILED, PAUSED }

signal game_state_changed(new_state: GameState)

var current_state: GameState = GameState.BOOT

var current_level: LevelData = null
var grid_manager: GridManager = null
var character: CharacterController = null
var animation_director: AnimationDirector = null

var _pre_pause_state: GameState = GameState.PLANNING
var _moves_used: int = 0
var _sequence_running: bool = false

const LEVELS_PER_WORLD: int = 22
const LOG_PREFIX: String = "[GameManager]"
const SCENE_GAMEPLAY: String = "res://scenes/ui/gameplay.tscn"
const SCENE_LEVEL_COMPLETE: String = "res://scenes/ui/level_complete.tscn"
const SCENE_LEVEL_FAILED: String = "res://scenes/ui/level_failed.tscn"


func _ready() -> void:
	animation_director = get_node_or_null("AnimationDirector") as AnimationDirector
	if current_state == GameState.BOOT:
		set_state(GameState.MAIN_MENU)


func set_state(next_state: GameState) -> void:
	if current_state == next_state:
		return
	var previous: GameState = current_state
	current_state = next_state
	_log_state_transition(previous, next_state)
	game_state_changed.emit(current_state)


func load_level(level: LevelData) -> void:
	if level == null:
		push_error("%s load_level called with null" % LOG_PREFIX)
		return
	if not level.is_valid():
		push_error("%s invalid level: %s" % [LOG_PREFIX, level.id])
		return
	set_state(GameState.LOADING)
	current_level = level
	_moves_used = 0
	grid_manager = GridManager.new(level.width, level.height, level.max_moves)
	grid_manager.load_terrain(level.initial_terrain, level.width, level.height, level.max_moves)
	character = CharacterController.new(level.start_position)
	_render_gameplay_ui(level)
	EventBus.level_started.emit(level)
	start_planning()


func start_planning() -> void:
	if grid_manager != null:
		grid_manager.set_queue_locked(false)
	set_state(GameState.PLANNING)


func queue_card(card_type: int, pos: Vector2i) -> bool:
	if current_state != GameState.PLANNING:
		return false
	if not grid_manager.can_queue():
		return false
	var ok: bool = grid_manager.queue_card(card_type, pos)
	if ok:
		EventBus.card_queued.emit(card_type, pos)
	return ok


func undo_last_card() -> bool:
	if current_state != GameState.PLANNING:
		return false
	var idx: int = grid_manager.queue.size() - 1
	var ok: bool = grid_manager.unqueue_last()
	if ok:
		EventBus.card_unqueued.emit(idx)
	return ok


func unqueue_card_at(index: int) -> bool:
	if current_state != GameState.PLANNING:
		return false
	var ok: bool = grid_manager.unqueue_at(index)
	if ok:
		EventBus.card_unqueued.emit(index)
	return ok


func clear_queue() -> void:
	if current_state != GameState.PLANNING:
		return
	grid_manager.clear_queue()
	EventBus.queue_cleared.emit()


func play_sequence() -> void:
	if current_state != GameState.PLANNING:
		return
	if grid_manager.queue.is_empty():
		return
	_moves_used = grid_manager.queue.size()
	set_state(GameState.RESOLVING)
	grid_manager.set_queue_locked(true)
	EventBus.sequence_started.emit()
	if animation_director != null:
		_start_sequence_playback()


func resolve_next() -> Dictionary:
	if current_state != GameState.RESOLVING:
		return {}
	var result: Dictionary = grid_manager.resolve_next_card()
	if result.is_empty():
		_begin_walk_or_no_path()
		return {}
	EventBus.sequence_card_resolved.emit(result["card_type"], result["pos"])
	return result


func toggle_sequence_speed() -> void:
	if animation_director == null:
		return
	animation_director.toggle_fast_mode()


func _begin_walk_or_no_path() -> void:
	EventBus.sequence_finished.emit()
	if current_level == null:
		return
	var walk_path: Array[Vector2i] = _find_walk_path(
		current_level.start_position,
		current_level.goal_positions
	)
	if walk_path.is_empty():
		handle_no_path()
		return
	character.begin_walk(walk_path)
	set_state(GameState.WALKING)
	EventBus.walk_started.emit()


func _start_sequence_playback() -> void:
	if _sequence_running or animation_director == null:
		return
	_sequence_running = true
	if not animation_director.weather_effect_finished.is_connected(_on_sequence_card_effect_finished):
		animation_director.weather_effect_finished.connect(_on_sequence_card_effect_finished)
	_play_next_sequence_card()


func _play_next_sequence_card() -> void:
	if animation_director == null or grid_manager == null:
		_sequence_running = false
		return
	if current_state != GameState.RESOLVING:
		_sequence_running = false
		return
	if grid_manager.queue.is_empty():
		_finish_sequence_playback()
		return
	var entry: Array = grid_manager.queue[0]
	if entry.size() < 2:
		grid_manager.resolve_next_card()
		_play_next_sequence_card()
		return
	var card_type: int = entry[0]
	var pos: Vector2i = entry[1]
	animation_director.play_card_resolution(card_type, pos)


func _on_sequence_card_effect_finished(_card_type: int) -> void:
	if not _sequence_running or current_state != GameState.RESOLVING or grid_manager == null:
		return
	var result: Dictionary = grid_manager.resolve_next_card()
	if result.is_empty():
		_finish_sequence_playback()
		return
	EventBus.sequence_card_resolved.emit(result["card_type"], result["pos"])
	if grid_manager.queue.is_empty():
		_finish_sequence_playback()
		return
	var delay: float = animation_director.get_scaled_delay_seconds(
		animation_director.inter_card_pause_ms,
		true
	)
	if delay <= 0.0:
		_play_next_sequence_card()
		return
	var timer: SceneTreeTimer = get_tree().create_timer(delay)
	timer.timeout.connect(_play_next_sequence_card)


func _finish_sequence_playback() -> void:
	if animation_director == null:
		_sequence_running = false
		_begin_walk_or_no_path()
		return
	var delay: float = animation_director.get_scaled_delay_seconds(
		animation_director.walk_start_delay_ms,
		false
	)
	if delay <= 0.0:
		_sequence_running = false
		_begin_walk_or_no_path()
		return
	var timer: SceneTreeTimer = get_tree().create_timer(delay)
	timer.timeout.connect(_on_sequence_walk_delay_finished)


func _on_sequence_walk_delay_finished() -> void:
	if not _sequence_running:
		return
	_sequence_running = false
	_begin_walk_or_no_path()


func walk_step() -> bool:
	if current_state != GameState.WALKING or character == null or current_level == null:
		return false
	var continues: bool = character.step(
		grid_manager.terrain, grid_manager.width, grid_manager.height,
		current_level.goal_positions
	)
	EventBus.walk_step.emit(character.position)
	if not continues:
		if character.is_dead():
			handle_loss(character.get_death_cause())
		elif character.current_state == CharacterController.State.CHEER:
			handle_win()
	return continues


func handle_win() -> void:
	set_state(GameState.COMPLETE)
	if current_level == null:
		return
	var stars: int = _compute_stars(_moves_used)
	EventBus.level_completed.emit(current_level.id, stars, _moves_used)
	EventBus.character_won.emit()
	_show_level_complete(stars)


func handle_loss(cause: int) -> void:
	set_state(GameState.FAILED)
	EventBus.character_died.emit(cause)
	if current_level != null:
		EventBus.level_failed.emit(current_level.id, cause)
	_show_level_failed_modal(cause)


func handle_no_path() -> void:
	if grid_manager != null:
		grid_manager.set_queue_locked(false)
	set_state(GameState.PLANNING)
	EventBus.no_path_forward.emit()


func pause() -> void:
	if current_state == GameState.PAUSED:
		return
	_pre_pause_state = current_state
	set_state(GameState.PAUSED)


func resume() -> void:
	if current_state != GameState.PAUSED:
		return
	set_state(_pre_pause_state)


func restart_level() -> void:
	if current_level != null:
		load_level(current_level)


func quit_to_world_map() -> void:
	current_level = null
	grid_manager = null
	character = null
	set_state(GameState.MAIN_MENU)


func _compute_stars(moves_used: int) -> int:
	if current_level == null:
		return 1
	if moves_used <= current_level.par_moves:
		return 3
	if moves_used <= current_level.max_moves - 1:
		return 2
	return 1


func _render_gameplay_ui(level: LevelData) -> void:
	# GUT: GameManager is parented under `res://test/*` scripts — avoid swapping global UIManager
	# (full gameplay scene + autoload graph); unit tests only assert grid/character/state.
	if _is_running_under_gut_or_test_harness():
		return
	var ui_manager: Node = _get_ui_manager()
	if ui_manager == null:
		return
	if ui_manager.has_method("go_to_gameplay"):
		ui_manager.call("go_to_gameplay")
	elif ui_manager.has_method("replace_screen"):
		ui_manager.call("replace_screen", SCENE_GAMEPLAY)
	_configure_gameplay_screen(level)


func _configure_gameplay_screen(level: LevelData) -> void:
	var screen: Control = _get_active_ui_screen()
	if screen == null:
		return
	if not screen.has_method("configure"):
		return
	var title: String = level.display_name
	if title.is_empty():
		title = "LEVEL %d" % level.level_number
	screen.call("configure", title, level.hint_text, level.max_moves, level.hint_text)


func _show_level_complete(stars: int) -> void:
	var ui_manager: Node = _get_ui_manager()
	if ui_manager == null:
		return
	if ui_manager.has_method("go_to_level_complete"):
		ui_manager.call("go_to_level_complete")
	elif ui_manager.has_method("replace_screen"):
		ui_manager.call("replace_screen", SCENE_LEVEL_COMPLETE)
	var screen: Control = _get_active_ui_screen()
	var level_complete: LevelCompleteScreen = screen as LevelCompleteScreen
	if level_complete == null or current_level == null:
		return
	var best_moves: int = _moves_used
	var save_manager: Node = _get_save_manager()
	if save_manager != null and save_manager.has_method("get_level_record"):
		var record: Dictionary = save_manager.call("get_level_record", current_level.id)
		if record.has("best_moves"):
			best_moves = int(record.get("best_moves"))
	var is_last_in_world: bool = current_level.level_number >= LEVELS_PER_WORLD
	level_complete.configure(stars, _moves_used, best_moves, current_level.par_moves, is_last_in_world)


func _show_level_failed_modal(cause: int) -> void:
	var ui_manager: Node = _get_ui_manager()
	if ui_manager == null:
		return
	if not ui_manager.has_method("show_modal"):
		return
	var modal: Control = ui_manager.call("show_modal", SCENE_LEVEL_FAILED)
	if modal == null:
		return
	var level_failed: LevelFailedScreen = modal as LevelFailedScreen
	if level_failed != null:
		level_failed.configure(cause)


func _find_walk_path(start: Vector2i, goals: Array[Vector2i]) -> Array[Vector2i]:
	if grid_manager == null or goals.is_empty():
		return []
	var best_path: Array[Vector2i] = []
	var best_len: int = 0
	for goal: Vector2i in goals:
		var path: Array[Vector2i] = Pathfinder.find_path(
			grid_manager.terrain, grid_manager.width, grid_manager.height,
			start, goal
		)
		if path.is_empty():
			continue
		if best_path.is_empty() or path.size() < best_len:
			best_path = path
			best_len = path.size()
	return best_path


func _get_active_ui_screen() -> Control:
	var ui_manager: Node = _get_ui_manager()
	if ui_manager == null:
		return null
	var host: Node = ui_manager.get_node_or_null("UIScreenHost")
	if host == null or host.get_child_count() == 0:
		return null
	return host.get_child(host.get_child_count() - 1) as Control


func _is_running_under_gut_or_test_harness() -> bool:
	var p: Node = get_parent()
	while p != null:
		var s: Script = p.get_script() as Script
		if s != null:
			var path: String = s.resource_path
			if path.begins_with("res://test/") or path.begins_with("res://addons/gut/"):
				return true
		p = p.get_parent()
	return false


func _get_ui_manager() -> Node:
	return get_node_or_null("/root/UIManager")


func _get_save_manager() -> Node:
	return get_node_or_null("/root/SaveManager")


func _log_state_transition(from_state: GameState, to_state: GameState) -> void:
	print("%s state %s -> %s" % [LOG_PREFIX, _state_name(from_state), _state_name(to_state)])


func _state_name(state: GameState) -> String:
	match state:
		GameState.BOOT:
			return "BOOT"
		GameState.MAIN_MENU:
			return "MAIN_MENU"
		GameState.LOADING:
			return "LOADING"
		GameState.PLANNING:
			return "PLANNING"
		GameState.RESOLVING:
			return "RESOLVING"
		GameState.WALKING:
			return "WALKING"
		GameState.COMPLETE:
			return "COMPLETE"
		GameState.FAILED:
			return "FAILED"
		GameState.PAUSED:
			return "PAUSED"
		_:
			return "UNKNOWN"
