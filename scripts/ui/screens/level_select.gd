class_name LevelSelectScreen
extends Control

## Screen 4 — Level Select / in-world map (`docs/UI_SCREENS.md`).
## Vertical scroll of 22 level nodes on a winding path over the world biome bg.

signal level_selected(world: int, level: int)

@onready var _back_button: Button = %BackButton
@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _scroll: ScrollContainer = %NodeScroll
@onready var _path_container: Control = %PathContainer
@onready var _background: ColorRect = $Background
@onready var _header_bg: ColorRect = $Margin/VBox/HeaderBar/HeaderBg
@onready var _biome_bg: ColorRect = %BiomeBg
@onready var _biome_texture: TextureRect = %BiomeTexture

const NODE_RADIUS: float = 40.0
const NODE_DIAMETER: float = 80.0
const NODE_FONT_SIZE: int = 28
const STAR_FONT_SIZE: int = 16
const STAR_LABEL_HEIGHT: float = 24.0
const STAR_LABEL_MARGIN: float = 6.0
const PULSE_DURATION: float = 1.2
const PATH_WIDTH: float = 3.0
const SCROLL_HEIGHT: float = 3200.0
const BACKGROUND_TEXTURE_PATH: String = "res://assets/sprites/ui/world_bg_w%d.png"
const NODE_COMPLETE_TEXTURE_PATH: String = "res://assets/sprites/ui/node_complete.png"
const NODE_CURRENT_TEXTURE_PATH: String = "res://assets/sprites/ui/node_current.png"
const NODE_LOCKED_TEXTURE_PATH: String = "res://assets/sprites/ui/node_locked.png"
const PATH_DASH_TEXTURE_PATH: String = "res://assets/sprites/ui/path_dash.png"

var _world_id: int = 1
var _world_name: String = "DOWNPOUR"
var _highest_unlocked: int = 1
var _level_stars: Dictionary = {}
var _path_data: Array = []
var _node_controls: Array[Control] = []
var _tween: Tween = null
var _node_texture_complete: Texture2D = null
var _node_texture_current: Texture2D = null
var _node_texture_locked: Texture2D = null
var _path_dash_texture: Texture2D = null
var _drag_active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_base_theme(self)
	_background.color = UITheme.bg_deep
	var header_color := UITheme.bg_deep
	header_color.a = 0.85
	_header_bg.color = header_color
	_biome_bg.color = UITheme.bg_panel_alt
	_biome_texture.stretch_mode = TextureRect.STRETCH_SCALE
	_biome_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	UITheme.apply_secondary_button(_back_button)
	UITheme.configure_title_label(_title_label)
	UITheme.configure_body_label(_subtitle_label)
	_back_button.pressed.connect(_on_back_pressed)
	_scroll.gui_input.connect(_on_scroll_gui_input)
	_load_assets()
	configure(_world_id, _world_name, _highest_unlocked, _level_stars)


func configure(world: int, world_name: String, highest_unlocked: int, level_stars: Dictionary) -> void:
	_world_id = world
	_world_name = world_name
	_highest_unlocked = clampi(highest_unlocked, 1, 22)
	_level_stars = level_stars
	if not is_node_ready():
		return
	_title_label.text = "WORLD %d: %s" % [_world_id, _world_name.to_upper()]
	var completed: int = _highest_unlocked - 1 if _highest_unlocked <= 22 else 22
	var total_stars: int = 0
	for key: Variant in _level_stars:
		var val: Variant = _level_stars[key]
		if val is int:
			total_stars += val as int
	_subtitle_label.text = "%d/22 levels • %d stars" % [completed, total_stars]
	_load_biome_background()
	_load_path_data()
	_build_nodes()
	call_deferred("_scroll_to_current")


func _load_assets() -> void:
	_node_texture_complete = _load_texture(NODE_COMPLETE_TEXTURE_PATH)
	_node_texture_current = _load_texture(NODE_CURRENT_TEXTURE_PATH)
	_node_texture_locked = _load_texture(NODE_LOCKED_TEXTURE_PATH)
	_path_dash_texture = _load_texture(PATH_DASH_TEXTURE_PATH)


func _load_biome_background() -> void:
	var background_path: String = BACKGROUND_TEXTURE_PATH % _world_id
	var texture: Texture2D = _load_texture(background_path)
	_biome_texture.texture = texture
	_biome_texture.visible = texture != null
	_biome_bg.custom_minimum_size = Vector2(0, SCROLL_HEIGHT)


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var texture: Texture2D = load(path) as Texture2D
	return texture


func _load_path_data() -> void:
	_path_data = []
	var path_file: String = "res://levels/world%d/path.json" % _world_id
	if not FileAccess.file_exists(path_file):
		_generate_fallback_path()
		return
	var file: FileAccess = FileAccess.open(path_file, FileAccess.READ)
	if file == null:
		_generate_fallback_path()
		return
	var json: JSON = JSON.new()
	var text: String = file.get_as_text()
	file = null
	var err: Error = json.parse(text)
	if err != OK:
		_generate_fallback_path()
		return
	var parsed: Variant = json.data
	if parsed is Array:
		_path_data = parsed as Array
	else:
		_generate_fallback_path()


func _generate_fallback_path() -> void:
	_path_data = []
	for i: int in range(1, 23):
		var t: float = float(i - 1) / 21.0
		var x: float = 0.5 + 0.25 * sin(t * TAU * 1.5)
		var y: float = 1.0 - t * 0.95 - 0.02
		_path_data.append({"level": i, "x": x, "y": y})


func _build_nodes() -> void:
	for child: Node in _path_container.get_children():
		_path_container.remove_child(child)
		child.queue_free()
	_node_controls.clear()
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_path_container.custom_minimum_size = Vector2(_scroll.size.x, SCROLL_HEIGHT)
	var container_width: float = maxf(_scroll.size.x, 600.0)

	var positions: Array[Vector2] = []
	for entry: Variant in _path_data:
		var d: Dictionary = entry as Dictionary
		var level: int = int(d.get("level", 0))
		var nx: float = float(d.get("x", 0.5))
		var ny: float = float(d.get("y", 0.5))
		var px: float = nx * container_width
		var py: float = ny * SCROLL_HEIGHT
		positions.append(Vector2(px, py))
		_create_level_node(level, px, py)

	_create_path_line(positions)
	_start_pulse_animation()


func _create_level_node(level: int, px: float, py: float) -> void:
	var container := Control.new()
	container.custom_minimum_size = Vector2(NODE_DIAMETER, NODE_DIAMETER + STAR_LABEL_MARGIN + STAR_LABEL_HEIGHT)
	container.size = container.custom_minimum_size
	container.position = Vector2(px - NODE_RADIUS, py - NODE_RADIUS)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var node: Button = Button.new()
	node.custom_minimum_size = Vector2(NODE_DIAMETER, NODE_DIAMETER)
	node.size = node.custom_minimum_size
	node.position = Vector2.ZERO
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	node.focus_mode = Control.FOCUS_NONE
	node.flat = true

	var icon := TextureRect.new()
	icon.anchor_right = 1.0
	icon.anchor_bottom = 1.0
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(icon)

	var label := Label.new()
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_numbers_font(label)
	label.add_theme_font_size_override(&"font_size", NODE_FONT_SIZE)
	node.add_child(label)

	var star_label := Label.new()
	star_label.position = Vector2(0.0, NODE_DIAMETER + STAR_LABEL_MARGIN)
	star_label.custom_minimum_size = Vector2(NODE_DIAMETER, STAR_LABEL_HEIGHT)
	star_label.size = star_label.custom_minimum_size
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_label.add_theme_color_override(&"font_color", UITheme.text_title)
	star_label.add_theme_font_size_override(&"font_size", STAR_FONT_SIZE)
	UITheme.apply_body_font(star_label)

	var state: int = _get_node_state(level)
	_apply_node_style(node, icon, label, star_label, state, level)

	node.pressed.connect(_on_level_node_pressed.bind(level))
	container.add_child(node)
	container.add_child(star_label)
	_path_container.add_child(container)
	_node_controls.append(node)


func _get_node_state(level: int) -> int:
	if level < _highest_unlocked:
		return 0  # completed
	elif level == _highest_unlocked:
		return 1  # current
	else:
		return 2  # locked


func _apply_node_style(node: Button, icon: TextureRect, label: Label, star_label: Label, state: int, level: int) -> void:
	var texture: Texture2D = null
	match state:
		0:
			texture = _node_texture_complete
		1:
			texture = _node_texture_current
		2:
			texture = _node_texture_locked

	if texture != null:
		node.flat = true
		icon.texture = texture
		icon.visible = true
	else:
		node.flat = false
		icon.visible = false

	match state:
		0:  # completed
			label.text = str(level)
			label.visible = true
			label.add_theme_color_override(&"font_color", UITheme.bg_deep)
			star_label.text = _star_text_for_level(level)
			star_label.visible = true
			node.tooltip_text = _star_text_for_level(level)
		1:  # current
			label.text = str(level)
			label.visible = true
			label.add_theme_color_override(&"font_color", UITheme.bg_deep)
			star_label.visible = false
			node.tooltip_text = ""
		2:  # locked
			label.text = "🔒"
			label.visible = true
			label.add_theme_color_override(&"font_color", UITheme.text_muted)
			star_label.visible = false
			node.tooltip_text = "Beat level %d to unlock" % (level - 1)

	if texture != null:
		node.text = ""
		if state == 2:
			label.visible = false
			label.text = ""
		return

	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_left = int(NODE_RADIUS)
	stylebox.corner_radius_top_right = int(NODE_RADIUS)
	stylebox.corner_radius_bottom_left = int(NODE_RADIUS)
	stylebox.corner_radius_bottom_right = int(NODE_RADIUS)

	match state:
		0:  # completed
			stylebox.bg_color = UITheme.accent_success
			stylebox.border_color = UITheme.border_frame
			stylebox.border_width_left = 3
			stylebox.border_width_top = 3
			stylebox.border_width_right = 3
			stylebox.border_width_bottom = 3
			node.add_theme_color_override(&"font_color", UITheme.bg_deep)
			node.add_theme_color_override(&"font_hover_color", UITheme.bg_deep)
			node.add_theme_color_override(&"font_pressed_color", UITheme.bg_deep)
			node.text = ""
		1:  # current
			stylebox.bg_color = UITheme.accent_primary
			stylebox.border_color = UITheme.text_title
			stylebox.border_width_left = 4
			stylebox.border_width_top = 4
			stylebox.border_width_right = 4
			stylebox.border_width_bottom = 4
			node.add_theme_color_override(&"font_color", UITheme.bg_deep)
			node.add_theme_color_override(&"font_hover_color", UITheme.bg_deep)
			node.add_theme_color_override(&"font_pressed_color", UITheme.bg_deep)
			node.text = ""
		2:  # locked
			stylebox.bg_color = UITheme.bg_panel
			stylebox.border_color = UITheme.border_frame
			stylebox.border_width_left = 2
			stylebox.border_width_top = 2
			stylebox.border_width_right = 2
			stylebox.border_width_bottom = 2
			node.add_theme_color_override(&"font_color", UITheme.text_muted)
			node.add_theme_color_override(&"font_hover_color", UITheme.text_muted)
			node.add_theme_color_override(&"font_pressed_color", UITheme.text_muted)
			node.text = ""

	node.add_theme_font_size_override(&"font_size", NODE_FONT_SIZE)
	node.add_theme_stylebox_override(&"normal", stylebox)
	var hover_box: StyleBoxFlat = stylebox.duplicate() as StyleBoxFlat
	hover_box.bg_color = stylebox.bg_color.lightened(0.08)
	node.add_theme_stylebox_override(&"hover", hover_box)
	var pressed_box: StyleBoxFlat = stylebox.duplicate() as StyleBoxFlat
	pressed_box.bg_color = stylebox.bg_color.darkened(0.06)
	node.add_theme_stylebox_override(&"pressed", pressed_box)


func _star_text_for_level(level: int) -> String:
	var key: String = "w%d_l%02d" % [_world_id, level]
	var stars: int = int(_level_stars.get(key, 0))
	match stars:
		3:
			return "★★★"
		2:
			return "★★☆"
		1:
			return "★☆☆"
		_:
			return "☆☆☆"


func _create_path_line(positions: Array[Vector2]) -> void:
	if positions.size() < 2:
		return
	var line := Line2D.new()
	line.width = PATH_WIDTH
	line.default_color = UITheme.border_frame
	line.antialiased = true
	if _path_dash_texture != null:
		line.texture = _path_dash_texture
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
	for pos: Vector2 in positions:
		line.add_point(pos)
	_path_container.add_child(line)
	_path_container.move_child(line, 0)


func _start_pulse_animation() -> void:
	var current_idx: int = _highest_unlocked - 1
	if current_idx < 0 or current_idx >= _node_controls.size():
		return
	var current_node: Control = _node_controls[current_idx]
	_tween = create_tween().set_loops()
	_tween.tween_property(current_node, "modulate:a", 0.6, PULSE_DURATION * 0.5)
	_tween.tween_property(current_node, "modulate:a", 1.0, PULSE_DURATION * 0.5)


func _scroll_to_current() -> void:
	if _path_data.is_empty():
		return
	var current_idx: int = _highest_unlocked - 1
	if current_idx < 0 or current_idx >= _path_data.size():
		return
	var entry: Dictionary = _path_data[current_idx] as Dictionary
	var ny: float = float(entry.get("y", 0.5))
	var target_y: float = ny * SCROLL_HEIGHT - _scroll.size.y * 0.5
	_scroll.scroll_vertical = int(clampf(target_y, 0.0, maxf(SCROLL_HEIGHT - _scroll.size.y, 0.0)))


func _on_level_node_pressed(level: int) -> void:
	if level > _highest_unlocked:
		_shake_locked_node(level)
		return
	level_selected.emit(_world_id, level)


func _on_scroll_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_drag_active = touch.pressed
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_scroll.scroll_vertical = int(clampf(_scroll.scroll_vertical - drag.relative.y, 0.0, maxf(SCROLL_HEIGHT - _scroll.size.y, 0.0)))
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			_drag_active = mouse_button.pressed
	elif event is InputEventMouseMotion and _drag_active:
		var motion := event as InputEventMouseMotion
		_scroll.scroll_vertical = int(clampf(_scroll.scroll_vertical - motion.relative.y, 0.0, maxf(SCROLL_HEIGHT - _scroll.size.y, 0.0)))


func _shake_locked_node(level: int) -> void:
	var idx: int = level - 1
	if idx < 0 or idx >= _node_controls.size():
		return
	var node: Control = _node_controls[idx]
	var original_x: float = node.position.x
	var shake_tween: Tween = create_tween()
	shake_tween.tween_property(node, "position:x", original_x + 8.0, 0.05)
	shake_tween.tween_property(node, "position:x", original_x - 8.0, 0.05)
	shake_tween.tween_property(node, "position:x", original_x + 4.0, 0.05)
	shake_tween.tween_property(node, "position:x", original_x, 0.05)


func _on_back_pressed() -> void:
	UIManager.pop_screen()
