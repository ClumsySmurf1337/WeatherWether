extends Node

## Autoload: owns the UI canvas, screen stack, and modal overlays.
## Implements push/pop transitions per GAME_DESIGN.md §13.

const SCENE_SPLASH: String = "res://scenes/ui/splash.tscn"
const SCENE_HOME: String = "res://scenes/ui/home.tscn"
const SCENE_WORLD_SELECT: String = "res://scenes/ui/world_select.tscn"
const SCENE_LEVEL_SELECT: String = "res://scenes/ui/level_select.tscn"
const SCENE_SETTINGS: String = "res://scenes/ui/settings.tscn"
const SCENE_GAMEPLAY: String = "res://scenes/ui/gameplay.tscn"
const SCENE_LEVEL_COMPLETE: String = "res://scenes/ui/level_complete.tscn"
const SCENE_LEVEL_FAILED: String = "res://scenes/ui/level_failed.tscn"
const SCENE_NO_PATH: String = "res://scenes/ui/no_path.tscn"
const SCENE_PAUSE: String = "res://scenes/ui/pause.tscn"
const SCENE_HINT_POPUP: String = "res://scenes/ui/hint_popup.tscn"

const SAVE_DEFAULT_PATH: String = "user://save_default.json"

const PUSH_DURATION_SEC: float = 0.28
const POP_DURATION_SEC: float = 0.20
const MODAL_DURATION_SEC: float = 0.22

var _canvas: CanvasLayer
var _host: Control
var _modal_layer: CanvasLayer
var _modal_host: Control
var _stack: Array[Control] = []
var _active_modal: Control = null
var _transitioning: bool = false
var _transition_tween: Tween = null
var _modal_tween: Tween = null
var _last_committed_queue: Array = []


func _ready() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 100
	add_child(_canvas)

	_host = Control.new()
	_host.name = &"UIScreenHost"
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_host.theme = UITheme.create_base_theme()
	_canvas.add_child(_host)

	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = 110
	add_child(_modal_layer)

	_modal_host = Control.new()
	_modal_host.name = &"UIModalHost"
	_modal_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_host.theme = UITheme.create_base_theme()
	_modal_layer.add_child(_modal_host)

	replace_screen(SCENE_SPLASH)


## Clears the stack and shows a single full-screen UI (e.g. Splash → Home).
func replace_screen(scene_path: String) -> void:
	_transitioning = false
	_clear_transition()
	dismiss_modal(true)
	# queue_free only — remove_child first briefly orphans nodes (GUT / orphan count noise).
	var to_clear: Array[Node] = _host.get_children()
	for child: Node in to_clear:
		child.queue_free()
	_stack.clear()
	var inst: Control = _instantiate_scene(scene_path)
	if inst == null:
		return
	_set_full_rect(inst)
	_host.add_child(inst)
	_stack.append(inst)
	_apply_offset(inst, Vector2.ZERO)


## Back-compat alias.
func replace_root(scene_path: String) -> void:
	replace_screen(scene_path)


## Pushes a screen on top of the current stack (e.g. Home → World Select).
func push_screen(scene_path: String) -> void:
	if _transitioning:
		return
	var inst: Control = _instantiate_scene(scene_path)
	if inst == null:
		return
	_push_instance(inst)


## Pops the top screen if more than one screen is on the stack.
func pop_screen() -> void:
	if _transitioning:
		return
	if _stack.size() <= 1:
		return
	var outgoing: Control = _stack.pop_back()
	var incoming: Control = _stack.back()
	if outgoing == null or incoming == null:
		return
	_transitioning = true
	_clear_transition()
	var width: float = _screen_size().x
	_apply_offset(incoming, Vector2(-width, 0.0))
	_apply_offset(outgoing, Vector2.ZERO)
	var duration: float = _scaled_duration(POP_DURATION_SEC)
	if duration <= 0.0:
		_apply_offset(incoming, Vector2.ZERO)
		_finalize_pop(outgoing)
		return
	_transition_tween = create_tween()
	_transition_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_transition_tween.tween_method(
		_apply_offset.bind(outgoing),
		Vector2.ZERO,
		Vector2(width, 0.0),
		duration
	)
	_transition_tween.parallel().tween_method(
		_apply_offset.bind(incoming),
		Vector2(-width, 0.0),
		Vector2.ZERO,
		duration
	)
	_transition_tween.finished.connect(_finalize_pop.bind(outgoing))


## Shows a modal overlay above everything (Level Failed, No Path, Pause).
## Returns the instantiated modal Control so the caller can connect signals.
func show_modal(scene_path: String) -> Control:
	dismiss_modal(true)
	var inst: Control = _instantiate_scene(scene_path)
	if inst == null:
		return null
	_set_full_rect(inst)
	_modal_host.add_child(inst)
	_modal_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_active_modal = inst
	_clear_modal_tween()
	var height: float = _screen_size().y
	_apply_offset(inst, Vector2(0.0, height))
	var duration: float = _scaled_duration(MODAL_DURATION_SEC)
	if duration <= 0.0:
		_apply_offset(inst, Vector2.ZERO)
		return inst
	_modal_tween = create_tween()
	_modal_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_modal_tween.tween_method(
		_apply_offset.bind(inst),
		Vector2(0.0, height),
		Vector2.ZERO,
		duration
	)
	return inst


## Dismisses the current modal overlay if one is active.
func dismiss_modal(immediate: bool = false) -> void:
	if _active_modal == null:
		return
	var modal: Control = _active_modal
	_active_modal = null
	_modal_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clear_modal_tween()
	if immediate:
		_remove_modal(modal)
		return
	var height: float = _screen_size().y
	var duration: float = _scaled_duration(MODAL_DURATION_SEC)
	if duration <= 0.0:
		_remove_modal(modal)
		return
	_modal_tween = create_tween()
	_modal_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_modal_tween.tween_method(
		_apply_offset.bind(modal),
		Vector2.ZERO,
		Vector2(0.0, height),
		duration
	)
	_modal_tween.finished.connect(_remove_modal.bind(modal))


func has_active_modal() -> bool:
	return _active_modal != null


func go_to_home() -> void:
	replace_screen(SCENE_HOME)


func go_to_gameplay() -> void:
	replace_screen(SCENE_GAMEPLAY)


func go_to_gameplay_placeholder() -> void:
	go_to_gameplay()


func go_to_level_complete() -> void:
	replace_screen(SCENE_LEVEL_COMPLETE)


func set_last_committed_queue(queue_entries: Array) -> void:
	_last_committed_queue = _normalize_queue(queue_entries)


func clear_last_committed_queue() -> void:
	_last_committed_queue.clear()


func restore_planning_without_last() -> void:
	var queue_entries: Array = _last_committed_queue.duplicate()
	if not queue_entries.is_empty():
		queue_entries.remove_at(queue_entries.size() - 1)
	restore_planning_from_queue(queue_entries)


func restore_planning_from_queue(queue_entries: Array) -> void:
	var game_manager: GameManager = _get_game_manager()
	if game_manager == null:
		return
	var grid_manager: GridManager = game_manager.grid_manager
	if grid_manager == null:
		return
	grid_manager.reset_to_initial()
	game_manager.start_planning()
	var event_bus: Node = get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal("queue_cleared"):
		event_bus.queue_cleared.emit()
	var normalized: Array = _normalize_queue(queue_entries)
	for entry: Array in normalized:
		if entry.size() < 2:
			continue
		game_manager.queue_card(int(entry[0]), entry[1])
	set_last_committed_queue(normalized)
	_refresh_gameplay_screen(grid_manager)


func request_restart_level() -> void:
	var game_manager: GameManager = _get_game_manager()
	if game_manager == null:
		return
	game_manager.restart_level()
	clear_last_committed_queue()


func show_hint_popup() -> void:
	var modal: Control = show_modal(SCENE_HINT_POPUP)
	if modal == null:
		return
	var hint_popup: Control = modal
	var hint: Dictionary = _compute_hint()
	if hint.has("card_type") and hint.has("pos"):
		if hint_popup.has_method("configure"):
			hint_popup.call("configure", int(hint["card_type"]), hint["pos"] as Vector2i)
	else:
		if hint_popup.has_method("configure_fallback"):
			hint_popup.call("configure_fallback", _get_level_hint_text())


func push_level_select(world: int, world_name: String, highest_unlocked: int, level_stars: Dictionary) -> void:
	if _transitioning:
		return
	var inst: Control = _instantiate_scene(SCENE_LEVEL_SELECT)
	if inst == null:
		return
	var screen: LevelSelectScreen = inst as LevelSelectScreen
	if screen != null:
		screen.configure(world, world_name, highest_unlocked, level_stars)
		screen.level_selected.connect(_on_level_selected)
	_push_instance(inst)


func _on_level_selected(_world: int, _level: int) -> void:
	go_to_gameplay()


static func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_DEFAULT_PATH)


func _push_instance(inst: Control) -> void:
	_set_full_rect(inst)
	_host.add_child(inst)
	var outgoing: Control = _stack.back() if _stack.size() > 0 else null
	_stack.append(inst)
	if outgoing == null:
		_apply_offset(inst, Vector2.ZERO)
		return
	_transitioning = true
	_clear_transition()
	var width: float = _screen_size().x
	_apply_offset(inst, Vector2(width, 0.0))
	_apply_offset(outgoing, Vector2.ZERO)
	var duration: float = _scaled_duration(PUSH_DURATION_SEC)
	if duration <= 0.0:
		_apply_offset(outgoing, Vector2(-width, 0.0))
		_apply_offset(inst, Vector2.ZERO)
		_transitioning = false
		return
	_transition_tween = create_tween()
	_transition_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_method(
		_apply_offset.bind(outgoing),
		Vector2.ZERO,
		Vector2(-width, 0.0),
		duration
	)
	_transition_tween.parallel().tween_method(
		_apply_offset.bind(inst),
		Vector2(width, 0.0),
		Vector2.ZERO,
		duration
	)
	_transition_tween.finished.connect(_on_transition_finished)


func _finalize_pop(outgoing: Control) -> void:
	if outgoing != null:
		_remove_screen(outgoing)
	_transitioning = false
	_clear_transition()


func _on_transition_finished() -> void:
	_transitioning = false
	_clear_transition()


func _remove_screen(screen: Control) -> void:
	if screen == null:
		return
	screen.queue_free()


func _remove_modal(modal: Control) -> void:
	if modal == null:
		return
	modal.queue_free()


func _instantiate_scene(scene_path: String) -> Control:
	if scene_path.is_empty():
		return null
	if not ResourceLoader.exists(scene_path):
		push_error("UIManager: missing scene %s" % scene_path)
		return null
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_error("UIManager: failed to load scene %s" % scene_path)
		return null
	return packed.instantiate() as Control


func _set_full_rect(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _apply_offset(control: Control, offset: Vector2) -> void:
	if control == null:
		return
	control.offset_left = offset.x
	control.offset_right = offset.x
	control.offset_top = offset.y
	control.offset_bottom = offset.y


func _screen_size() -> Vector2:
	var size: Vector2 = _host.size
	if size == Vector2.ZERO:
		var viewport: Viewport = get_viewport()
		if viewport != null:
			size = viewport.get_visible_rect().size
	return size


func _scaled_duration(base: float) -> float:
	return base * 0.5 if _is_reduce_motion() else base


func _is_reduce_motion() -> bool:
	var save: Node = get_node_or_null("/root/SaveManager")
	if save != null and save.has_method("get_setting"):
		return bool(save.call("get_setting", "reduce_motion", false))
	return false


func _clear_transition() -> void:
	if _transition_tween != null:
		_transition_tween.kill()
		_transition_tween = null


func _clear_modal_tween() -> void:
	if _modal_tween != null:
		_modal_tween.kill()
		_modal_tween = null


func _normalize_queue(queue_entries: Array) -> Array:
	var normalized: Array = []
	for entry: Variant in queue_entries:
		if entry is Array and (entry as Array).size() >= 2:
			var entry_array: Array = entry as Array
			normalized.append([int(entry_array[0]), entry_array[1]])
		elif entry is Dictionary:
			var entry_dict: Dictionary = entry as Dictionary
			var card_type: int = int(entry_dict.get("card_type", entry_dict.get("card", -1)))
			var pos: Vector2i = entry_dict.get("pos", Vector2i.ZERO)
			normalized.append([card_type, pos])
	return normalized


func _compute_hint() -> Dictionary:
	var game_manager: GameManager = _get_game_manager()
	if game_manager == null:
		return {}
	var level: LevelData = game_manager.current_level
	var grid_manager: GridManager = game_manager.grid_manager
	if level == null or grid_manager == null:
		return {}
	var preview: Array = grid_manager.get_preview_grid()
	var remaining: Array[int] = level.available_cards.duplicate()
	for entry: Variant in grid_manager.queue:
		if entry is Array and (entry as Array).size() >= 2:
			var card_type: int = int((entry as Array)[0])
			var idx: int = remaining.find(card_type)
			if idx >= 0:
				remaining.remove_at(idx)
	var solver := PuzzleSolver.new(
		grid_manager.width,
		grid_manager.height,
		PuzzleSolver.make_path_exists_goal(level.start_position, level.goal_positions)
	)
	var result: SolverResult = solver.solve(preview, remaining)
	if result.is_solvable and result.solution.size() > 0:
		var move: Array = result.solution[0]
		if move.size() >= 2:
			return {"card_type": int(move[0]), "pos": move[1]}
	return {}


func _get_level_hint_text() -> String:
	var game_manager: GameManager = _get_game_manager()
	if game_manager != null and game_manager.current_level != null:
		return game_manager.current_level.hint_text
	return "No hint available yet."


func _get_game_manager() -> GameManager:
	return get_node_or_null("/root/GameManager") as GameManager


func _refresh_gameplay_screen(grid_manager: GridManager) -> void:
	if _stack.is_empty():
		return
	var screen: Control = _stack.back()
	if screen == null:
		return
	if screen.has_method("set_grid_manager"):
		screen.call("set_grid_manager", grid_manager)
	if screen.has_method("set_queue"):
		screen.call("set_queue", grid_manager.get_queue())
	if screen.has_method("set_sequence_playing"):
		screen.call("set_sequence_playing", false)
