class_name SettingsScreen
extends Control

## Settings (`docs/UI_SCREENS.md`). Stub shell with back navigation.

@onready var _back_button: Button = %BackButton
@onready var _title: Label = $Margin/VBox/Header/Title
@onready var _placeholder: Label = $Margin/VBox/Placeholder
@onready var _background: ColorRect = $Background


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_base_theme(self)
	_background.color = UITheme.bg_deep
	UITheme.apply_secondary_button(_back_button)
	UITheme.configure_title_label(_title)
	UITheme.configure_muted_label(_placeholder)
	_back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	UIManager.pop_screen()
