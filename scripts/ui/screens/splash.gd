class_name SplashScreen
extends Control

## Screen 1 — Splash (`docs/UI_SCREENS.md`). Auto-advances after 1.5s or on tap.

const ADVANCE_SEC: float = 1.5
const TAP_HINT_DELAY_SEC: float = 0.8
const CLOUD_SCROLL_SPEED_PX: float = 12.0
const CLOUD_ALPHA: float = 0.1
const CLOUD_Y_OFFSET_PX: float = 64.0
const WORDMARK_TEXTURE_PATH: String = "res://assets/sprites/ui/wordmark.png"
const CLOUDS_TEXTURE_PATH: String = "res://assets/sprites/ui/splash_clouds.png"

var _advanced: bool = false
var _cloud_scroll: float = 0.0
var _cloud_width: float = 0.0
var _clouds_enabled: bool = false

@onready var _clouds: Control = $Clouds
@onready var _cloud_a: TextureRect = $Clouds/CloudA
@onready var _cloud_b: TextureRect = $Clouds/CloudB
@onready var _wordmark: TextureRect = $Center/VBox/Wordmark
@onready var _wordmark_fallback: Label = $Center/VBox/WordmarkFallback
@onready var _background: ColorRect = $Background
@onready var _timer: Timer = $AdvanceTimer
@onready var _tagline: Label = $Center/VBox/Tagline
@onready var _tap_hint: Label = $TapHint


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_base_theme(self)
	_background.color = UITheme.bg_deep
	UITheme.configure_title_label(_wordmark_fallback)
	UITheme.configure_muted_label(_tagline)
	UITheme.configure_muted_label(_tap_hint)
	_tap_hint.modulate.a = 0.0
	_setup_wordmark()
	_setup_clouds()
	_fade_in_tap_hint()
	_kickoff_save_load()
	_timer.wait_time = ADVANCE_SEC
	_timer.one_shot = true
	_timer.timeout.connect(_on_advance_timer)
	_timer.start()


func _gui_input(event: InputEvent) -> void:
	if _advanced:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed:
			_advance()
			accept_event()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_advance()
			accept_event()


func _input(event: InputEvent) -> void:
	if _advanced:
		return
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and (key.keycode == KEY_SPACE or key.keycode == KEY_ENTER):
			_advance()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _clouds_enabled or _cloud_width <= 0.0:
		return
	_cloud_scroll += delta * CLOUD_SCROLL_SPEED_PX
	if _cloud_scroll >= _cloud_width:
		_cloud_scroll -= _cloud_width
	var y: float = UITheme.SAFE_AREA_TOP_PX + CLOUD_Y_OFFSET_PX
	_cloud_a.position = Vector2(-_cloud_scroll, y)
	_cloud_b.position = Vector2(_cloud_a.position.x + _cloud_width, y)


func _on_advance_timer() -> void:
	_advance()


func _advance() -> void:
	if _advanced:
		return
	_advanced = true
	_timer.stop()
	UIManager.go_to_home()


func _setup_wordmark() -> void:
	var texture: Texture2D = _try_load_texture(WORDMARK_TEXTURE_PATH)
	if texture == null:
		_wordmark.visible = false
		_wordmark_fallback.visible = true
		return
	_wordmark.texture = texture
	_wordmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_wordmark.custom_minimum_size = texture.get_size()
	_wordmark.visible = true
	_wordmark_fallback.visible = false


func _setup_clouds() -> void:
	var texture: Texture2D = _try_load_texture(CLOUDS_TEXTURE_PATH)
	if texture == null:
		_clouds.visible = false
		set_process(false)
		return
	_clouds.visible = true
	_cloud_a.texture = texture
	_cloud_b.texture = texture
	_cloud_a.modulate.a = CLOUD_ALPHA
	_cloud_b.modulate.a = CLOUD_ALPHA
	_cloud_width = texture.get_size().x
	_cloud_a.size = texture.get_size()
	_cloud_b.size = texture.get_size()
	_cloud_scroll = 0.0
	_clouds_enabled = _cloud_width > 0.0
	set_process(_clouds_enabled)


func _fade_in_tap_hint() -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(TAP_HINT_DELAY_SEC)
	tween.tween_property(_tap_hint, "modulate:a", 1.0, 0.35)


func _kickoff_save_load() -> void:
	var save: Node = get_node_or_null("/root/SaveManager")
	if save != null and save.has_method("load_save"):
		save.call_deferred("load_save")


func _try_load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
