class_name CardView
extends Button

signal long_pressed(card_key: StringName)

@export var card_key: StringName = &""
@export var card_label: String = ""
@export var description: String = ""
@export var base_color: Color = UITheme.card_rain
@export var lift_pixels: float = 8.0
@export var long_press_ms: int = 500

var _selected: bool = false
var _base_position: Vector2 = Vector2.ZERO
var _suppress_rect_change: bool = false
var _long_press_timer: Timer
var _tooltip_panel: PanelContainer
var _tooltip_label: Label

var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat
var _style_pressed: StyleBoxFlat
var _style_disabled: StyleBoxFlat
var _style_glow: StyleBoxFlat
var _style_glow_pressed: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	_build_styles()
	_apply_default_style()
	if card_label != "":
		text = card_label
	_ensure_tooltip()
	_cache_base_position()
	item_rect_changed.connect(_on_item_rect_changed)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_exited.connect(_on_mouse_exited)


func configure(key: StringName, label_text: String, color: Color, tooltip_text: String = "") -> void:
	card_key = key
	card_label = label_text
	base_color = color
	description = tooltip_text
	text = label_text
	_build_styles()
	_apply_default_style()
	_ensure_tooltip()
	_set_selected(false)


func set_selected(is_selected: bool) -> void:
	_set_selected(is_selected)


func toggle_selected() -> void:
	_set_selected(not _selected)


func is_selected() -> bool:
	return _selected


func set_exhausted(exhausted: bool) -> void:
	disabled = exhausted
	if exhausted:
		modulate.a = 0.3
		_set_selected(false)
	else:
		modulate.a = 1.0
	_apply_default_style()


func _set_selected(is_selected: bool) -> void:
	if _selected == is_selected:
		return
	_selected = is_selected
	if _selected:
		_apply_glow_style()
	else:
		_apply_default_style()
	_update_lift()


func _build_styles() -> void:
	_style_normal = _create_style(base_color)
	_style_hover = _create_style(base_color.lightened(0.05))
	_style_pressed = _create_style(base_color.darkened(0.05))
	_style_disabled = _create_style(base_color.darkened(0.18))
	var glow_color: Color = UITheme.card_glow_color(card_key).lightened(0.15)
	_style_glow = _create_style(base_color, glow_color, 4)
	_style_glow_pressed = _create_style(base_color.darkened(0.05), glow_color.darkened(0.05), 4)
	add_theme_color_override(&"font_color", UITheme.bg_deep)
	add_theme_color_override(&"font_hover_color", UITheme.bg_deep)
	add_theme_color_override(&"font_pressed_color", UITheme.bg_deep)
	add_theme_color_override(&"font_disabled_color", UITheme.text_muted)


func _create_style(fill: Color, border: Color = UITheme.border_frame, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _apply_default_style() -> void:
	add_theme_stylebox_override(&"normal", _style_normal)
	add_theme_stylebox_override(&"hover", _style_hover)
	add_theme_stylebox_override(&"pressed", _style_pressed)
	add_theme_stylebox_override(&"disabled", _style_disabled)


func _apply_glow_style() -> void:
	add_theme_stylebox_override(&"normal", _style_glow)
	add_theme_stylebox_override(&"hover", _style_glow)
	add_theme_stylebox_override(&"pressed", _style_glow_pressed)
	add_theme_stylebox_override(&"disabled", _style_disabled)


func _cache_base_position() -> void:
	_base_position = position
	_update_lift()


func _update_lift() -> void:
	var offset := Vector2(0.0, (-lift_pixels) if _selected else 0.0)
	_suppress_rect_change = true
	position = _base_position + offset
	_suppress_rect_change = false


func _on_item_rect_changed() -> void:
	if _suppress_rect_change:
		return
	_base_position = position
	_update_lift()


func _on_button_down() -> void:
	if disabled:
		return
	_start_long_press_timer()


func _on_button_up() -> void:
	_stop_long_press_timer()
	_hide_tooltip()


func _on_mouse_exited() -> void:
	_stop_long_press_timer()
	_hide_tooltip()


func _start_long_press_timer() -> void:
	if _long_press_timer == null:
		_long_press_timer = Timer.new()
		_long_press_timer.one_shot = true
		_long_press_timer.timeout.connect(_on_long_press_timeout)
		add_child(_long_press_timer)
	_long_press_timer.wait_time = float(long_press_ms) / 1000.0
	_long_press_timer.start()


func _stop_long_press_timer() -> void:
	if _long_press_timer == null:
		return
	_long_press_timer.stop()


func _on_long_press_timeout() -> void:
	_show_tooltip()
	long_pressed.emit(card_key)


func _ensure_tooltip() -> void:
	if description == "":
		_hide_tooltip()
		return
	if _tooltip_panel == null:
		_tooltip_panel = PanelContainer.new()
		_tooltip_panel.visible = false
		_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = UITheme.bg_panel
		style.border_color = UITheme.border_frame
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		style.content_margin_left = 12.0
		style.content_margin_right = 12.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		_tooltip_panel.add_theme_stylebox_override(&"panel", style)
		_tooltip_label = Label.new()
		_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_tooltip_label.custom_minimum_size = Vector2(220, 0)
		UITheme.configure_body_label(_tooltip_label)
		_tooltip_panel.add_child(_tooltip_label)
		add_child(_tooltip_panel)
	_tooltip_label.text = description


func _show_tooltip() -> void:
	if _tooltip_panel == null:
		return
	_tooltip_panel.visible = true
	call_deferred("_position_tooltip")


func _position_tooltip() -> void:
	if _tooltip_panel == null:
		return
	var tooltip_size: Vector2 = _tooltip_panel.get_combined_minimum_size()
	_tooltip_panel.size = tooltip_size
	var card_size: Vector2 = size
	_tooltip_panel.position = Vector2((card_size.x - tooltip_size.x) * 0.5, -tooltip_size.y - 8.0)


func _hide_tooltip() -> void:
	if _tooltip_panel != null:
		_tooltip_panel.visible = false
