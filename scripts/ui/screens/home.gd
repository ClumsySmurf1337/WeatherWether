class_name HomeScreen
extends Control

## Screen 2 — Home (`docs/UI_SCREENS.md`). Wireframe layout until art assets land.

const TOTAL_LEVELS: int = 132
const HERO_TEXTURE_PATH: String = "res://assets/sprites/ui/home_hero.png"
const WORDMARK_TEXTURE_PATH: String = "res://assets/sprites/ui/wordmark_small.png"

@onready var _continue_button: Button = %ContinueButton
@onready var _select_level_button: Button = %SelectLevelButton
@onready var _settings_button: Button = %SettingsButton
@onready var _progress_label: Label = %ProgressLabel
@onready var _progress_star_label: Label = %StarLabel
@onready var _background: ColorRect = $Background
@onready var _hero_panel: PanelContainer = $Margin/VBox/HeroPanel
@onready var _progress_strip: PanelContainer = $Margin/VBox/ProgressStrip
@onready var _hero_texture: TextureRect = $Margin/VBox/HeroPanel/HeroContent/HeroTexture
@onready var _hero_fallback: Label = $Margin/VBox/HeroPanel/HeroContent/HeroFallback
@onready var _wordmark_texture: TextureRect = $Margin/VBox/Wordmark/WordmarkTexture
@onready var _wordmark_fallback: Label = $Margin/VBox/Wordmark/WordmarkFallback


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_base_theme(self)
	_background.color = UITheme.bg_deep
	_apply_panel_style(_hero_panel, UITheme.bg_panel_alt)
	_apply_panel_style(_progress_strip, UITheme.bg_panel)
	_setup_hero_art()
	_setup_wordmark()
	_refresh_progress()
	_refresh_continue_label()
	_continue_button.pressed.connect(_on_continue_pressed)
	_select_level_button.pressed.connect(_on_select_level_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	UITheme.apply_primary_button(_continue_button)
	UITheme.apply_secondary_button(_select_level_button)
	UITheme.apply_secondary_button(_settings_button)
	UITheme.configure_muted_label(_hero_fallback)
	UITheme.configure_body_label(_progress_label)
	UITheme.configure_title_label(_progress_star_label)
	UITheme.configure_title_label(_wordmark_fallback)
	call_deferred("_apply_hero_height")


func _apply_hero_height() -> void:
	var vp: Vector2 = get_viewport_rect().size
	_hero_panel.custom_minimum_size.y = maxf(400.0, vp.y * 0.38)


func _refresh_progress() -> void:
	var save_data: Dictionary = _get_save_data()
	var completed: int = _count_completed_levels(save_data)
	var total_stars: int = _get_total_stars(save_data)
	_progress_label.text = "%d/%d levels" % [completed, TOTAL_LEVELS]
	_progress_star_label.text = "★ %d" % total_stars


func _refresh_continue_label() -> void:
	var completed: int = _count_completed_levels(_get_save_data())
	if not UIManager.has_save_file():
		_continue_button.text = "BEGIN"
	elif completed >= TOTAL_LEVELS:
		_continue_button.text = "FREEPLAY"
	else:
		_continue_button.text = "CONTINUE"


func _on_continue_pressed() -> void:
	UIManager.go_to_gameplay()


func _on_select_level_pressed() -> void:
	UIManager.push_screen(UIManager.SCENE_WORLD_SELECT)


func _on_settings_pressed() -> void:
	UIManager.push_screen(UIManager.SCENE_SETTINGS)


func _setup_hero_art() -> void:
	var texture: Texture2D = _try_load_texture(HERO_TEXTURE_PATH)
	if texture == null:
		_hero_texture.visible = false
		_hero_fallback.visible = true
		return
	_hero_texture.texture = texture
	_hero_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_hero_texture.visible = true
	_hero_fallback.visible = false


func _setup_wordmark() -> void:
	var texture: Texture2D = _try_load_texture(WORDMARK_TEXTURE_PATH)
	if texture == null:
		_wordmark_texture.visible = false
		_wordmark_fallback.visible = true
		return
	_wordmark_texture.texture = texture
	_wordmark_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_wordmark_texture.custom_minimum_size = texture.get_size()
	_wordmark_texture.visible = true
	_wordmark_fallback.visible = false


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


func _get_save_data() -> Dictionary:
	var save: Node = get_node_or_null("/root/SaveManager")
	if save != null:
		var data_value: Variant = save.get("data")
		if data_value is Dictionary:
			return data_value
	return {}


func _count_completed_levels(save_data: Dictionary) -> int:
	var levels: Dictionary = save_data.get("levels", {}) as Dictionary
	var count: int = 0
	for level_id: String in levels:
		var record: Dictionary = levels[level_id] as Dictionary
		if record.get("completed", false):
			count += 1
	return count


func _get_total_stars(save_data: Dictionary) -> int:
	var progress: Dictionary = save_data.get("progress", {}) as Dictionary
	return progress.get("total_stars", 0) as int


func _try_load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
