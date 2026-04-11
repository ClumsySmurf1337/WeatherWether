class_name PauseScreen
extends Control

## Screen 9 — Pause modal (`docs/UI_SCREENS.md`).
## Overlay during gameplay with resume, restart, settings, and quit options.

signal resume_requested
signal restart_requested
signal settings_requested
signal quit_to_world_map_requested

@onready var _dimmer: ColorRect = $Dimmer
@onready var _title_label: Label = %PauseTitle
@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_base_theme(self)
	var dim_color := UITheme.bg_deep
	dim_color.a = 0.85
	_dimmer.color = dim_color
	UITheme.configure_title_label(_title_label)
	UITheme.apply_primary_button(_resume_button)
	UITheme.apply_secondary_button(_restart_button)
	UITheme.apply_secondary_button(_settings_button)
	UITheme.apply_secondary_button(_quit_button)
	_resume_button.pressed.connect(_on_resume)
	_restart_button.pressed.connect(_on_restart)
	_settings_button.pressed.connect(_on_settings)
	_quit_button.pressed.connect(_on_quit)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and key.keycode == KEY_ESCAPE:
			_on_resume()
			get_viewport().set_input_as_handled()


func _on_resume() -> void:
	resume_requested.emit()


func _on_restart() -> void:
	restart_requested.emit()


func _on_settings() -> void:
	settings_requested.emit()


func _on_quit() -> void:
	quit_to_world_map_requested.emit()
