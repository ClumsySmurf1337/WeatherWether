class_name NoPathScreen
extends Control

## Screen 8 — No Path Forward modal (`docs/UI_SCREENS.md`).
## Soft-lose overlay: no death animation, amber border, recovery options.

signal undo_last_requested
signal restart_requested

@onready var _dimmer: ColorRect = $Dimmer
@onready var _title_label: Label = %NoPathTitle
@onready var _body_label: Label = %BodyLabel
@onready var _undo_button: Button = %UndoButton
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_base_theme(self)
	var dim_color := UITheme.bg_deep
	dim_color.a = 0.7
	_dimmer.color = dim_color
	UITheme.configure_title_label(_title_label)
	_title_label.add_theme_color_override(&"font_color", UITheme.accent_warning)
	UITheme.configure_body_label(_body_label)
	UITheme.apply_secondary_button(_undo_button)
	UITheme.apply_secondary_button(_restart_button)
	_undo_button.pressed.connect(_on_undo)
	_restart_button.pressed.connect(_on_restart)


func _on_undo() -> void:
	undo_last_requested.emit()


func _on_restart() -> void:
	restart_requested.emit()
