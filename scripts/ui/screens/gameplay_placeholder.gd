class_name GameplayPlaceholderScreen
extends Control

## Placeholder until `gameplay.gd` + board integration land. Back returns to Home.

@onready var _back_button: Button = %BackButton
@onready var _title: Label = $Margin/VBox/Title
@onready var _hint: Label = $Margin/VBox/Hint


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_secondary_button(_back_button)
	UITheme.configure_title_label(_title)
	UITheme.configure_muted_label(_hint)
	_back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	UIManager.go_to_home()
