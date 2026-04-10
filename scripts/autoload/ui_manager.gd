extends Node

## Autoload: owns the UI canvas, screen stack (push/pop), and root replacement (Splash → Home).
## See `docs/UI_SCREENS.md` and `docs/CODE_REWRITE_PLAN.md` §UI files.

const SCENE_SPLASH: PackedScene = preload("res://scenes/ui/splash.tscn")
const SCENE_HOME: PackedScene = preload("res://scenes/ui/home.tscn")
const SCENE_WORLD_SELECT: PackedScene = preload("res://scenes/ui/world_select.tscn")
const SCENE_SETTINGS: PackedScene = preload("res://scenes/ui/settings.tscn")
const SCENE_GAMEPLAY_PLACEHOLDER: PackedScene = preload("res://scenes/ui/gameplay_placeholder.tscn")

const SAVE_DEFAULT_PATH: String = "user://save_default.json"

var _canvas: CanvasLayer
var _host: Control
var _stack: Array[Control] = []


func _ready() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 100
	add_child(_canvas)

	_host = Control.new()
	_host.name = &"UIScreenHost"
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_host.theme = UITheme.create_base_theme()
	_canvas.add_child(_host)

	replace_root(SCENE_SPLASH)


## Clears the stack and shows a single full-screen UI (e.g. Splash → Home, or Home → Gameplay stub).
func replace_root(scene: PackedScene) -> void:
	for child: Node in _host.get_children():
		_host.remove_child(child)
		child.queue_free()
	_stack.clear()
	var inst: Control = scene.instantiate() as Control
	_set_full_rect(inst)
	_host.add_child(inst)
	_stack.append(inst)


## Pushes a screen on top of the current stack (e.g. Home → World Select).
func push_screen(scene: PackedScene) -> void:
	var inst: Control = scene.instantiate() as Control
	_set_full_rect(inst)
	_host.add_child(inst)
	_stack.append(inst)


## Pops the top screen if more than one screen is on the stack.
func pop_screen() -> void:
	if _stack.size() <= 1:
		return
	var top: Control = _stack.pop_back()
	if top.get_parent() == _host:
		_host.remove_child(top)
	top.queue_free()


func go_to_home() -> void:
	replace_root(SCENE_HOME)


func go_to_gameplay_placeholder() -> void:
	replace_root(SCENE_GAMEPLAY_PLACEHOLDER)


static func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_DEFAULT_PATH)


func _set_full_rect(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
