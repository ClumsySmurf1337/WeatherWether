class_name HomeScreen
extends Control

## Screen 2 — Home (`docs/UI_SCREENS.md`). Wireframe layout until art assets land.

@onready var _continue_button: Button = %ContinueButton
@onready var _select_level_button: Button = %SelectLevelButton
@onready var _settings_button: Button = %SettingsButton
@onready var _progress_label: Label = %ProgressLabel
@onready var _hero_panel: PanelContainer = $Margin/VBox/HeroPanel
@onready var _wordmark: Label = $Margin/VBox/Wordmark


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_continue_label()
	_continue_button.pressed.connect(_on_continue_pressed)
	_select_level_button.pressed.connect(_on_select_level_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	UITheme.apply_primary_button(_continue_button)
	UITheme.apply_secondary_button(_select_level_button)
	UITheme.apply_secondary_button(_settings_button)
	UITheme.configure_body_label(_progress_label)
	UITheme.configure_title_label(_wordmark)
	call_deferred("_apply_hero_height")


func _apply_hero_height() -> void:
	var vp: Vector2 = get_viewport_rect().size
	_hero_panel.custom_minimum_size.y = maxf(400.0, vp.y * 0.38)


func _refresh_continue_label() -> void:
	if UIManager.has_save_file():
		_continue_button.text = "CONTINUE"
	else:
		_continue_button.text = "BEGIN"
	_progress_label.text = "0/132 levels"


func _on_continue_pressed() -> void:
	UIManager.go_to_gameplay_placeholder()


func _on_select_level_pressed() -> void:
	UIManager.push_screen(UIManager.SCENE_WORLD_SELECT)


func _on_settings_pressed() -> void:
	UIManager.push_screen(UIManager.SCENE_SETTINGS)
