class_name GameplayScreen
extends Control

## Screen 5 — Gameplay (`docs/UI_SCREENS.md`).
## Layout and interaction shell until gameplay wiring lands.

signal back_requested
signal pause_requested
signal hint_requested
signal undo_requested
signal play_sequence_requested
signal cancel_requested
signal speed_toggle_requested
signal card_selected(card_key: StringName)
signal tile_selected(pos: Vector2i)
signal queue_item_removed(index: int)
signal queue_item_reordered(from_index: int, to_index: int)

@onready var _back_button: Button = %BackButton
@onready var _pause_button: Button = %PauseButton
@onready var _hint_button: Button = %HintButton
@onready var _level_title: Label = %LevelTitle
@onready var _level_insight: Label = %LevelInsight
@onready var _moves_label: Label = %MovesLabel
@onready var _moves_value: Label = %MovesValue
@onready var _hint_icon: Label = %HintIcon
@onready var _hint_arrow: Label = %HintArrow
@onready var _hint_text: Label = %HintText
@onready var _hint_banner: PanelContainer = %HintBanner
@onready var _queue_strip: QueueStrip = %QueueStrip
@onready var _grid_panel: PanelContainer = %GridPanel
@onready var _grid_view: GridView = %GridView
@onready var _undo_button: Button = %UndoButton
@onready var _play_button: Button = %PlayButton
@onready var _cancel_button: Button = %CancelButton
@onready var _speed_container: Control = %SpeedContainer
@onready var _speed_button: Button = %SpeedButton
@onready var _hand_row: HBoxContainer = %HandRow
@onready var _background: ColorRect = $Background

var _sequence_playing: bool = false
var _card_views: Dictionary = {}
var _selected_card_key: StringName = &""
var _event_bus: Node = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_base_theme(self)
	_background.color = UITheme.bg_deep
	_apply_panel_style(_hint_banner, UITheme.bg_panel)
	_apply_panel_style(_queue_strip, UITheme.bg_deep)
	_apply_panel_style(_grid_panel, UITheme.bg_panel)
	UITheme.apply_secondary_button(_back_button)
	UITheme.apply_secondary_button(_pause_button)
	UITheme.apply_secondary_button(_hint_button)
	_hint_button.add_theme_color_override(&"font_color", UITheme.accent_warning)
	UITheme.configure_title_label(_level_title)
	UITheme.configure_muted_label(_level_insight)
	UITheme.configure_muted_label(_moves_label)
	UITheme.configure_numbers_label(_moves_value)
	UITheme.configure_body_label(_hint_text)
	UITheme.configure_muted_label(_hint_icon)
	UITheme.configure_muted_label(_hint_arrow)
	UITheme.apply_secondary_button(_undo_button)
	UITheme.apply_success_button(_play_button)
	UITheme.apply_secondary_button(_cancel_button)
	UITheme.apply_secondary_button(_speed_button)
	_back_button.pressed.connect(_on_back_pressed)
	_pause_button.pressed.connect(_on_pause_pressed)
	_hint_button.pressed.connect(_on_hint_pressed)
	_undo_button.pressed.connect(_on_undo_pressed)
	_play_button.pressed.connect(_on_play_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_speed_button.pressed.connect(_on_speed_pressed)
	_queue_strip.remove_requested.connect(_on_queue_item_removed)
	_queue_strip.reorder_requested.connect(_on_queue_item_reordered)
	if _grid_view != null:
		_grid_view.tile_tapped.connect(_on_grid_tile_tapped)
	_bind_card_buttons()
	_connect_event_bus()
	_sync_from_game_manager()
	_update_sequence_state(false)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and key.keycode == KEY_ESCAPE:
			_on_pause_pressed()
			get_viewport().set_input_as_handled()


func configure(level_title: String, insight: String, moves: int, hint_text: String) -> void:
	_level_title.text = level_title
	_level_insight.text = insight
	_moves_value.text = str(moves)
	_hint_text.text = hint_text


func set_sequence_playing(is_playing: bool) -> void:
	_update_sequence_state(is_playing)


func set_queue_count(count: int) -> void:
	_set_queue_count(count)

func set_queue(entries: Array) -> void:
	_queue_strip.set_queue(entries)
	_set_queue_count(_queue_strip.get_queue_size())


func set_grid_manager(manager: GridManager) -> void:
	if _grid_view != null:
		_grid_view.set_grid_manager(manager)


func _set_queue_count(count: int) -> void:
	_queue_strip.set_queue_count(count)
	_play_button.disabled = count == 0
	_undo_button.disabled = count == 0
	_cancel_button.disabled = count == 0


func _update_sequence_state(is_playing: bool) -> void:
	_sequence_playing = is_playing
	_queue_strip.visible = true
	_speed_container.visible = is_playing
	_undo_button.visible = not is_playing
	_play_button.visible = not is_playing
	_cancel_button.visible = not is_playing


func _bind_card_buttons() -> void:
	var card_defs := [
		{"node": "RainCard", "label": "RAIN", "key": &"rain", "color": UITheme.card_rain, "description": "Rain wets tiles and clears fog."},
		{"node": "SunCard", "label": "SUN", "key": &"sun", "color": UITheme.card_sun, "description": "Sun dries wet tiles and evaporates water."},
		{"node": "FrostCard", "label": "FROST", "key": &"frost", "color": UITheme.card_frost, "description": "Frost freezes wet tiles into ice."},
		{"node": "WindCard", "label": "WIND", "key": &"wind", "color": UITheme.card_wind, "description": "Wind clears fog and steam in a cross."},
		{"node": "LightningCard", "label": "LIGHT", "key": &"lightning", "color": UITheme.card_lightning, "description": "Lightning chains through conductive tiles."},
		{"node": "FogCard", "label": "FOG", "key": &"fog", "color": UITheme.card_fog, "description": "Fog blankets a 3×3 area."},
	]
	for entry: Dictionary in card_defs:
		var card_view: CardView = _hand_row.get_node_or_null(entry["node"]) as CardView
		if card_view == null:
			continue
		card_view.configure(entry["key"], entry["label"], entry["color"], entry["description"])
		card_view.pressed.connect(_on_card_pressed.bind(entry["key"]))
		_card_views[entry["key"]] = card_view


func _apply_panel_style(panel: PanelContainer, fill: Color) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = UITheme.border_frame
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	panel.add_theme_stylebox_override(&"panel", style)


func _on_back_pressed() -> void:
	back_requested.emit()
	var game_manager: GameManager = _get_game_manager()
	if game_manager != null:
		game_manager.pause()
	_open_pause()


func _on_pause_pressed() -> void:
	pause_requested.emit()
	var game_manager: GameManager = _get_game_manager()
	if game_manager != null:
		game_manager.pause()
	_open_pause()


func _on_hint_pressed() -> void:
	hint_requested.emit()
	UIManager.show_hint_popup()


func _on_undo_pressed() -> void:
	undo_requested.emit()
	var game_manager: GameManager = _get_game_manager()
	if game_manager != null:
		game_manager.undo_last_card()


func _on_play_pressed() -> void:
	play_sequence_requested.emit()
	var game_manager: GameManager = _get_game_manager()
	if game_manager == null:
		return
	if game_manager.grid_manager != null:
		UIManager.set_last_committed_queue(game_manager.grid_manager.get_queue())
	game_manager.play_sequence()


func _on_cancel_pressed() -> void:
	cancel_requested.emit()
	var game_manager: GameManager = _get_game_manager()
	if game_manager != null:
		game_manager.clear_queue()


func _on_speed_pressed() -> void:
	speed_toggle_requested.emit()
	var game_manager: GameManager = _get_game_manager()
	if game_manager != null:
		game_manager.toggle_sequence_speed()


func _on_card_pressed(card_key: StringName) -> void:
	_set_selected_card(card_key)
	card_selected.emit(card_key)
	var card: CardView = _card_views.get(card_key, null) as CardView
	if card != null and card.is_selected():
		_selected_card_key = card_key
	else:
		_selected_card_key = &""


func _on_grid_tile_tapped(pos: Vector2i) -> void:
	tile_selected.emit(pos)
	if _selected_card_key == &"":
		return
	var card_type: int = _card_type_for_key(_selected_card_key)
	if card_type < 0:
		return
	var game_manager: GameManager = _get_game_manager()
	if game_manager == null:
		return
	if game_manager.queue_card(card_type, pos):
		_sync_queue_from_manager()

func _on_queue_item_removed(index: int) -> void:
	queue_item_removed.emit(index)
	var game_manager: GameManager = _get_game_manager()
	if game_manager == null:
		return
	if game_manager.unqueue_card_at(index):
		_sync_queue_from_manager()


func _on_queue_item_reordered(from_index: int, to_index: int) -> void:
	queue_item_reordered.emit(from_index, to_index)
	var game_manager: GameManager = _get_game_manager()
	if game_manager == null or game_manager.grid_manager == null:
		return
	var queue: Array = game_manager.grid_manager.queue
	if from_index < 0 or from_index >= queue.size():
		return
	if to_index < 0 or to_index >= queue.size():
		return
	var entry: Variant = queue[from_index]
	queue.remove_at(from_index)
	queue.insert(to_index, entry)
	_sync_queue_from_manager()
	if _grid_view != null:
		_grid_view.set_grid_manager(game_manager.grid_manager)


func set_card_exhausted(card_key: StringName, exhausted: bool) -> void:
	var card: CardView = _card_views.get(card_key, null) as CardView
	if card == null:
		return
	card.set_exhausted(exhausted)


func _set_selected_card(card_key: StringName) -> void:
	for key: Variant in _card_views.keys():
		var card: CardView = _card_views[key] as CardView
		if card == null:
			continue
		if key == card_key:
			if not card.disabled:
				card.toggle_selected()
		else:
			card.set_selected(false)


func _open_pause() -> void:
	if UIManager.has_active_modal():
		return
	var modal: Control = UIManager.show_modal(UIManager.SCENE_PAUSE)
	if modal == null:
		return
	var pause_screen: PauseScreen = modal as PauseScreen
	if pause_screen == null:
		return
	pause_screen.resume_requested.connect(_on_pause_resume)
	pause_screen.restart_requested.connect(_on_pause_restart)
	pause_screen.settings_requested.connect(_on_pause_settings)
	pause_screen.quit_to_world_map_requested.connect(_on_pause_quit)


func _on_pause_resume() -> void:
	UIManager.dismiss_modal()
	var game_manager: GameManager = _get_game_manager()
	if game_manager != null:
		game_manager.resume()


func _on_pause_restart() -> void:
	UIManager.dismiss_modal()
	UIManager.request_restart_level()


func _on_pause_settings() -> void:
	UIManager.dismiss_modal()
	UIManager.push_screen(UIManager.SCENE_SETTINGS)


func _on_pause_quit() -> void:
	UIManager.dismiss_modal()
	var game_manager: GameManager = _get_game_manager()
	if game_manager != null:
		game_manager.quit_to_world_map()
	UIManager.clear_last_committed_queue()
	UIManager.pop_screen()


func _connect_event_bus() -> void:
	_event_bus = get_node_or_null("/root/EventBus")
	if _event_bus == null:
		return
	if not _event_bus.level_started.is_connected(_on_level_started):
		_event_bus.level_started.connect(_on_level_started)
	if not _event_bus.card_queued.is_connected(_on_queue_event):
		_event_bus.card_queued.connect(_on_queue_event)
	if not _event_bus.card_unqueued.is_connected(_on_queue_event):
		_event_bus.card_unqueued.connect(_on_queue_event)
	if not _event_bus.queue_cleared.is_connected(_on_queue_cleared):
		_event_bus.queue_cleared.connect(_on_queue_cleared)
	if not _event_bus.sequence_started.is_connected(_on_sequence_started):
		_event_bus.sequence_started.connect(_on_sequence_started)
	if not _event_bus.no_path_forward.is_connected(_on_no_path_forward):
		_event_bus.no_path_forward.connect(_on_no_path_forward)
	if not _event_bus.level_failed.is_connected(_on_level_failed):
		_event_bus.level_failed.connect(_on_level_failed)
	if not _event_bus.level_completed.is_connected(_on_level_completed):
		_event_bus.level_completed.connect(_on_level_completed)


func _on_level_started(_level: LevelData) -> void:
	_update_sequence_state(false)
	_sync_from_game_manager()


func _on_queue_event(_card_type: int = 0, _pos: Vector2i = Vector2i.ZERO) -> void:
	_sync_queue_from_manager()


func _on_queue_cleared() -> void:
	_sync_queue_from_manager()


func _on_sequence_started() -> void:
	_update_sequence_state(true)


func _on_no_path_forward() -> void:
	_update_sequence_state(false)
	if not UIManager.has_active_modal():
		UIManager.show_modal(UIManager.SCENE_NO_PATH)


func _on_level_failed(_level_id: String, _cause: int) -> void:
	_update_sequence_state(false)


func _on_level_completed(_level_id: String, _stars: int, _moves_used: int) -> void:
	_update_sequence_state(false)


func _sync_from_game_manager() -> void:
	var game_manager: GameManager = _get_game_manager()
	if game_manager == null:
		return
	if game_manager.grid_manager != null:
		set_grid_manager(game_manager.grid_manager)
		set_queue(game_manager.grid_manager.get_queue())


func _sync_queue_from_manager() -> void:
	var game_manager: GameManager = _get_game_manager()
	if game_manager == null or game_manager.grid_manager == null:
		_set_queue_count(0)
		return
	set_queue(game_manager.grid_manager.get_queue())


func _card_type_for_key(key: StringName) -> int:
	match key:
		&"rain":
			return WeatherType.Card.RAIN
		&"sun":
			return WeatherType.Card.SUN
		&"frost":
			return WeatherType.Card.FROST
		&"wind":
			return WeatherType.Card.WIND
		&"lightning":
			return WeatherType.Card.LIGHTNING
		&"fog":
			return WeatherType.Card.FOG
		_:
			return -1


func _get_game_manager() -> GameManager:
	return get_node_or_null("/root/GameManager") as GameManager
