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

var _pre_pause_state: GameState = GameState.PLANNING
var _moves_used: int = 0


func set_state(next_state: GameState) -> void:
	if current_state == next_state:
		return
	current_state = next_state
	game_state_changed.emit(current_state)


func load_level(level: LevelData) -> void:
	set_state(GameState.LOADING)
	current_level = level
	_moves_used = 0
	grid_manager = GridManager.new(level.width, level.height, level.max_moves)
	grid_manager.load_terrain(level.initial_terrain, level.width, level.height, level.max_moves)
	character = CharacterController.new(level.start_position)
	EventBus.level_started.emit(level.id)
	start_planning()


func start_planning() -> void:
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
	EventBus.sequence_started.emit()


func resolve_next() -> Dictionary:
	if current_state != GameState.RESOLVING:
		return {}
	var result: Dictionary = grid_manager.resolve_next_card()
	if result.is_empty():
		_begin_walk_or_no_path()
		return {}
	EventBus.sequence_card_resolved.emit(result["card_type"], result["pos"])
	return result


func _begin_walk_or_no_path() -> void:
	EventBus.sequence_finished.emit()
	if current_level == null:
		return
	var walk_path: Array[Vector2i] = Pathfinder.find_path(
		grid_manager.terrain, grid_manager.width, grid_manager.height,
		current_level.start_position, current_level.goal_positions[0]
	)
	if walk_path.is_empty():
		handle_no_path()
		return
	character.begin_walk(walk_path)
	set_state(GameState.WALKING)
	EventBus.walk_started.emit()


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


func handle_loss(cause: int) -> void:
	set_state(GameState.FAILED)
	EventBus.character_died.emit(cause)
	if current_level != null:
		EventBus.level_failed.emit(current_level.id, cause)


func handle_no_path() -> void:
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
