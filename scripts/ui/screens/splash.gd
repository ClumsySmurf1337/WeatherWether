class_name SplashScreen
extends Control

## Screen 1 — Splash (`docs/UI_SCREENS.md`). Auto-advances after 1.5s or on tap.

const ADVANCE_SEC: float = 1.5

var _advanced: bool = false
@onready var _timer: Timer = $AdvanceTimer
@onready var _title1: Label = $Center/VBox/Title1
@onready var _title2: Label = $Center/VBox/Title2
@onready var _tagline: Label = $Center/VBox/Tagline
@onready var _tap_hint: Label = $Center/VBox/TapHint


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.configure_title_label(_title1)
	UITheme.configure_title_label(_title2)
	UITheme.configure_muted_label(_tagline)
	UITheme.configure_muted_label(_tap_hint)
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


func _on_advance_timer() -> void:
	_advance()


func _advance() -> void:
	if _advanced:
		return
	_advanced = true
	_timer.stop()
	UIManager.go_to_home()
