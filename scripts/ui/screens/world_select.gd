class_name WorldSelectScreen
extends Control

## Screen 3 — World Select (`docs/UI_SCREENS.md`).
## 2×3 grid of world cards with lock state driven by save progress.

const WORLD_NAMES: Array[String] = [
	"DOWNPOUR", "HEATWAVE", "COLD SNAP", "GALE FORCE", "THUNDERSTORM", "WHITEOUT",
]

@onready var _back_button: Button = %BackButton
@onready var _title: Label = $Margin/VBox/Header/Title
@onready var _world_grid: GridContainer = %WorldGrid

var _highest_unlocked_world: int = 1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_secondary_button(_back_button)
	UITheme.configure_title_label(_title)
	_back_button.pressed.connect(_on_back_pressed)
	_build_world_cards()


func _build_world_cards() -> void:
	for child: Node in _world_grid.get_children():
		_world_grid.remove_child(child)
		child.queue_free()

	for i: int in range(6):
		var world_num: int = i + 1
		var is_unlocked: bool = world_num <= _highest_unlocked_world
		_world_grid.add_child(_create_world_card(world_num, is_unlocked))


func _create_world_card(world_num: int, is_unlocked: bool) -> Control:
	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 300)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_color = UITheme.border_frame
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0

	if is_unlocked:
		style.bg_color = UITheme.bg_panel_alt
		card.add_theme_color_override(&"font_color", UITheme.text_body)
		card.add_theme_color_override(&"font_hover_color", UITheme.text_title)
		card.add_theme_color_override(&"font_pressed_color", UITheme.text_title)
		card.text = "%d. %s" % [world_num, WORLD_NAMES[world_num - 1]]
	else:
		style.bg_color = UITheme.bg_panel
		card.add_theme_color_override(&"font_color", UITheme.text_muted)
		card.add_theme_color_override(&"font_hover_color", UITheme.text_muted)
		card.add_theme_color_override(&"font_pressed_color", UITheme.text_muted)
		card.text = "🔒 %d. %s" % [world_num, WORLD_NAMES[world_num - 1]]

	card.add_theme_font_size_override(&"font_size", 24)
	card.add_theme_stylebox_override(&"normal", style)
	var hover_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover_style.bg_color = style.bg_color.lightened(0.06)
	card.add_theme_stylebox_override(&"hover", hover_style)
	var pressed_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = style.bg_color.darkened(0.04)
	card.add_theme_stylebox_override(&"pressed", pressed_style)

	card.pressed.connect(_on_world_card_pressed.bind(world_num, is_unlocked))
	return card


func _on_world_card_pressed(world_num: int, is_unlocked: bool) -> void:
	if not is_unlocked:
		return
	UIManager.push_level_select(world_num, WORLD_NAMES[world_num - 1], 1, {})


func _on_back_pressed() -> void:
	UIManager.pop_screen()
