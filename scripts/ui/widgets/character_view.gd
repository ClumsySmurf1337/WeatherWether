class_name CharacterView
extends Control

@export var grid_view_path: NodePath
@export var tile_size_px: int = UITheme.TILE_RENDER_PX
@export var walk_step_ms: int = 250
@export var reduce_motion_step_ms: int = 80
@export var idle_bob_pixels: float = 6.0

const State := CharacterController.State

var _grid_view: GridView = null
var _sprite_root: Control = null
var _glyph_container: Control = null
var _glyph: Label = null

var _game_manager: GameManager = null
var _character: CharacterController = null
var _grid_size: Vector2i = Vector2i.ZERO
var _current_pos: Vector2i = Vector2i.ZERO
var _current_state: int = -1
var _current_facing: Vector2i = Vector2i.ZERO
var _last_death_cause: int = -1

var _event_bus: Node = null
var _move_tween: Tween = null
var _bob_tween: Tween = null
var _death_hold: bool = false
var _is_moving: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid_view = get_node_or_null(grid_view_path) as GridView
	_sync_tile_size()
	_build_visuals()
	_connect_event_bus()
	_sync_from_game_manager()
	_apply_state_from_character(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_reposition_current(false)


func _process(_delta: float) -> void:
	_sync_character_state(false)


func set_grid_manager(manager: GridManager) -> void:
	if manager == null:
		return
	_grid_size = Vector2i(manager.width, manager.height)
	_reposition_current(false)


func _build_visuals() -> void:
	if _sprite_root == null:
		_sprite_root = Control.new()
		_sprite_root.name = &"SpriteRoot"
		_sprite_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_sprite_root)
	if _glyph_container == null:
		_glyph_container = Control.new()
		_glyph_container.name = &"GlyphContainer"
		_glyph_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sprite_root.add_child(_glyph_container)
	if _glyph == null:
		_glyph = Label.new()
		_glyph.name = &"Glyph"
		_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_glyph.add_theme_font_size_override(&"font_size", 28)
		UITheme.configure_title_label(_glyph)
		_glyph_container.add_child(_glyph)
	_set_sprite_size()
	_set_glyph("O", UITheme.text_title)


func _set_sprite_size() -> void:
	if _sprite_root == null or _glyph_container == null or _glyph == null:
		return
	var size_px := Vector2(float(tile_size_px), float(tile_size_px))
	_sprite_root.size = size_px
	_sprite_root.pivot_offset = size_px * 0.5
	_glyph_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glyph_container.offset_left = 0.0
	_glyph_container.offset_top = 0.0
	_glyph_container.offset_right = 0.0
	_glyph_container.offset_bottom = 0.0
	_glyph_container.size = size_px
	_glyph_container.pivot_offset = size_px * 0.5
	_glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glyph.offset_left = 0.0
	_glyph.offset_top = 0.0
	_glyph.offset_right = 0.0
	_glyph.offset_bottom = 0.0


func _connect_event_bus() -> void:
	_event_bus = get_node_or_null("/root/EventBus")
	if _event_bus == null:
		return
	if not _event_bus.level_started.is_connected(_on_level_started):
		_event_bus.level_started.connect(_on_level_started)
	if not _event_bus.walk_started.is_connected(_on_walk_started):
		_event_bus.walk_started.connect(_on_walk_started)
	if not _event_bus.walk_step.is_connected(_on_walk_step):
		_event_bus.walk_step.connect(_on_walk_step)
	if not _event_bus.character_died.is_connected(_on_character_died):
		_event_bus.character_died.connect(_on_character_died)
	if not _event_bus.character_won.is_connected(_on_character_won):
		_event_bus.character_won.connect(_on_character_won)
	if not _event_bus.queue_cleared.is_connected(_on_queue_cleared):
		_event_bus.queue_cleared.connect(_on_queue_cleared)


func _sync_from_game_manager() -> void:
	_game_manager = get_node_or_null("/root/GameManager") as GameManager
	if _game_manager == null:
		return
	_character = _game_manager.character
	if _game_manager.grid_manager != null:
		_grid_size = Vector2i(_game_manager.grid_manager.width, _game_manager.grid_manager.height)
	elif _game_manager.current_level != null:
		_grid_size = Vector2i(_game_manager.current_level.width, _game_manager.current_level.height)
	if _character != null:
		_current_pos = _character.position
		_reposition_current(false)


func _sync_tile_size() -> void:
	if _grid_view != null:
		tile_size_px = _grid_view.tile_size_px


func _apply_state_from_character(force: bool) -> void:
	if _character == null:
		_sync_from_game_manager()
	if _character == null:
		return
	var next_state: int = _character.current_state
	var next_facing: Vector2i = _character.facing
	if force or next_state != _current_state or next_facing != _current_facing:
		_current_state = next_state
		_current_facing = next_facing
		_apply_state(next_state)


func _sync_character_state(force: bool) -> void:
	if _death_hold:
		return
	if _character == null:
		_sync_from_game_manager()
	if _character == null:
		return
	_apply_state_from_character(force)
	if _character.position != _current_pos:
		_current_pos = _character.position
		var animate: bool = _character.current_state == State.WALK
		_reposition_current(animate)


func _apply_state(state: int) -> void:
	if _sprite_root == null or _glyph_container == null or _glyph == null:
		return
	_stop_bob()
	_glyph_container.scale = Vector2.ONE
	_sprite_root.scale = Vector2.ONE
	_sprite_root.modulate = Color.WHITE
	match state:
		State.IDLE:
			_set_glyph("O", UITheme.text_title)
			_start_bob()
		State.SURPRISED:
			_set_glyph("!", UITheme.accent_warning)
			_pulse_once()
		State.WALK:
			_set_glyph(_arrow_for_facing(_current_facing), UITheme.text_title)
		State.CHEER:
			_set_glyph("*", UITheme.accent_success)
			_play_cheer()
		State.DROWN, State.BURN, State.ELECTROCUTE, State.FREEZE, State.FALL:
			_set_glyph("X", UITheme.accent_danger)
			_play_death()
		_:
			_set_glyph("O", UITheme.text_title)


func _set_glyph(text: String, color: Color) -> void:
	if _glyph == null:
		return
	_glyph.text = text
	_glyph.add_theme_color_override(&"font_color", color)


func _start_bob() -> void:
	if _glyph_container == null:
		return
	_glyph_container.position = Vector2.ZERO
	if _bob_tween != null:
		_bob_tween.kill()
	_bob_tween = create_tween()
	_bob_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_loops()
	_bob_tween.tween_property(_glyph_container, "position", Vector2(0.0, -idle_bob_pixels), 0.5)
	_bob_tween.tween_property(_glyph_container, "position", Vector2(0.0, idle_bob_pixels), 0.5)


func _stop_bob() -> void:
	if _bob_tween != null:
		_bob_tween.kill()
		_bob_tween = null
	if _glyph_container != null:
		_glyph_container.position = Vector2.ZERO


func _pulse_once() -> void:
	if _glyph_container == null:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_glyph_container, "scale", Vector2(1.15, 1.15), 0.12)
	tween.tween_property(_glyph_container, "scale", Vector2.ONE, 0.12)


func _play_cheer() -> void:
	if _glyph_container == null:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_glyph_container, "scale", Vector2(1.25, 1.25), 0.18)
	tween.tween_property(_glyph_container, "scale", Vector2.ONE, 0.18)


func _play_death() -> void:
	_death_hold = true
	if _move_tween != null:
		_move_tween.kill()
		_move_tween = null
	_is_moving = false
	var duration: float = _death_duration_sec(_last_death_cause)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite_root, "scale", Vector2(0.7, 0.7), duration)


func _reposition_current(animate: bool) -> void:
	if _sprite_root == null:
		return
	if _grid_size.x <= 0 or _grid_size.y <= 0:
		return
	var target: Vector2 = _tile_top_left(_current_pos)
	if not animate or _is_reduce_motion():
		if _move_tween != null:
			_move_tween.kill()
			_move_tween = null
		_is_moving = false
		_sprite_root.position = target
		return
	var duration: float = _walk_duration_sec()
	if duration <= 0.0:
		_sprite_root.position = target
		return
	if _move_tween != null:
		_move_tween.kill()
	_move_tween = create_tween()
	_move_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_property(_sprite_root, "position", target, duration)
	_move_tween.finished.connect(_on_move_finished)
	_is_moving = true


func _on_move_finished() -> void:
	_is_moving = false


func _tile_top_left(pos: Vector2i) -> Vector2:
	return _grid_origin() + Vector2(float(pos.x) * tile_size_px, float(pos.y) * tile_size_px)


func _grid_origin() -> Vector2:
	var view_size: Vector2 = size
	var view_offset: Vector2 = Vector2.ZERO
	if _grid_view != null:
		view_size = _grid_view.size
		view_offset = _grid_view.position
	var grid_pixel_size := Vector2(float(_grid_size.x) * tile_size_px, float(_grid_size.y) * tile_size_px)
	var origin: Vector2 = (view_size - grid_pixel_size) * 0.5
	if origin.x < 0.0:
		origin.x = 0.0
	if origin.y < 0.0:
		origin.y = 0.0
	return view_offset + origin


func _arrow_for_facing(facing: Vector2i) -> String:
	if facing == Vector2i(1, 0):
		return ">"
	if facing == Vector2i(-1, 0):
		return "<"
	if facing == Vector2i(0, -1):
		return "^"
	if facing == Vector2i(0, 1):
		return "v"
	return "o"


func _walk_duration_sec() -> float:
	var step_ms: int = walk_step_ms
	var director: AnimationDirector = _get_animation_director()
	if director != null:
		if director.reduce_motion:
			step_ms = min(step_ms, reduce_motion_step_ms)
		else:
			step_ms = int(float(step_ms) / max(0.1, director.speed_multiplier))
	return float(step_ms) / 1000.0


func _death_duration_sec(cause: int) -> float:
	var duration_ms: int = 900
	match cause:
		0:
			duration_ms = 1000
		1:
			duration_ms = 1200
		2:
			duration_ms = 900
		3:
			duration_ms = 800
		4:
			duration_ms = 1000
	return float(duration_ms) / 1000.0


func _is_reduce_motion() -> bool:
	var director: AnimationDirector = _get_animation_director()
	if director != null:
		return director.reduce_motion
	var save: Node = get_node_or_null("/root/SaveManager")
	if save != null and save.has_method("get_setting"):
		return bool(save.call("get_setting", "reduce_motion", false))
	return false


func _get_animation_director() -> AnimationDirector:
	if _game_manager != null and _game_manager.animation_director != null:
		return _game_manager.animation_director
	var gm: GameManager = get_node_or_null("/root/GameManager") as GameManager
	if gm != null:
		return gm.animation_director
	return null


func _on_level_started(level: LevelData) -> void:
	_death_hold = false
	_last_death_cause = -1
	_current_state = -1
	_current_facing = Vector2i.ZERO
	if level != null:
		_grid_size = Vector2i(level.width, level.height)
		_current_pos = level.start_position
		_reposition_current(false)
	_sync_from_game_manager()
	_apply_state_from_character(true)


func _on_walk_started() -> void:
	_death_hold = false
	_apply_state_from_character(true)


func _on_walk_step(pos: Vector2i) -> void:
	var previous: Vector2i = _current_pos
	_current_pos = pos
	var delta: Vector2i = pos - previous
	if delta != Vector2i.ZERO:
		_current_facing = delta
		if _current_state == State.WALK:
			_set_glyph(_arrow_for_facing(_current_facing), UITheme.text_title)
	_reposition_current(true)


func _on_character_died(cause: int) -> void:
	_last_death_cause = cause
	_death_hold = true
	match cause:
		0:
			_current_state = State.DROWN
		1:
			_current_state = State.BURN
		2:
			_current_state = State.FALL
		3:
			_current_state = State.ELECTROCUTE
		4:
			_current_state = State.FREEZE
		_:
			_current_state = State.FALL
	_apply_state(_current_state)


func _on_character_won() -> void:
	_death_hold = false
	_current_state = State.CHEER
	_apply_state(State.CHEER)


func _on_queue_cleared() -> void:
	if not _death_hold:
		return
	_death_hold = false
	_sync_from_game_manager()
	_apply_state_from_character(true)
