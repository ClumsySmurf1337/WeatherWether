class_name WorldSelectScreen
extends Control

## Screen 3 — World Select (`docs/UI_SCREENS.md`). Stub: header + back until biome cards ship.

@onready var _back_button: Button = %BackButton
@onready var _title: Label = $Margin/VBox/Header/Title


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_secondary_button(_back_button)
	UITheme.configure_title_label(_title)
	_back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	UIManager.pop_screen()
