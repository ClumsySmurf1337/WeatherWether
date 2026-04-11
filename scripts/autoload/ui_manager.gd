extends Node

## Autoload: owns the UI canvas, screen stack (push/pop), modal overlay, and
## root replacement (Splash → Home). See `docs/UI_SCREENS.md` and
## `docs/CODE_REWRITE_PLAN.md` §UI files.

const SCENE_SPLASH: PackedScene = preload("res://scenes/ui/splash.tscn")
const SCENE_HOME: PackedScene = preload("res://scenes/ui/home.tscn")
const SCENE_WORLD_SELECT: PackedScene = preload("res://scenes/ui/world_select.tscn")
const SCENE_LEVEL_SELECT: PackedScene = preload("res://scenes/ui/level_select.tscn")
const SCENE_SETTINGS: PackedScene = preload("res://scenes/ui/settings.tscn")
const SCENE_GAMEPLAY: PackedScene = preload("res://scenes/ui/gameplay.tscn")
const SCENE_LEVEL_COMPLETE: PackedScene = preload("res://scenes/ui/level_complete.tscn")
const SCENE_LEVEL_FAILED: PackedScene = preload("res://scenes/ui/level_failed.tscn")
const SCENE_NO_PATH: PackedScene = preload("res://scenes/ui/no_path.tscn")
const SCENE_PAUSE: PackedScene = preload("res://scenes/ui/pause.tscn")

const SAVE_DEFAULT_PATH: String = "user://save_default.json"

var _canvas: CanvasLayer
var _host: Control
var _modal_layer: CanvasLayer
var _modal_host: Control
var _stack: Array[Control] = []
var _active_modal: Control = null


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

	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = 110
	add_child(_modal_layer)

	_modal_host = Control.new()
	_modal_host.name = &"UIModalHost"
	_modal_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_host.theme = UITheme.create_base_theme()
	_modal_layer.add_child(_modal_host)

	replace_root(SCENE_SPLASH)


## Clears the stack and shows a single full-screen UI (e.g. Splash → Home).
func replace_root(scene: PackedScene) -> void:
	dismiss_modal()
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


## Shows a modal overlay above everything (Level Failed, No Path, Pause).
## Returns the instantiated modal Control so the caller can connect signals.
func show_modal(scene: PackedScene) -> Control:
	dismiss_modal()
	var inst: Control = scene.instantiate() as Control
	_set_full_rect(inst)
	_modal_host.add_child(inst)
	_modal_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_active_modal = inst
	return inst


## Dismisses the current modal overlay if one is active.
func dismiss_modal() -> void:
	if _active_modal != null:
		if _active_modal.get_parent() == _modal_host:
			_modal_host.remove_child(_active_modal)
		_active_modal.queue_free()
		_active_modal = null
		_modal_host.mouse_filter = Control.MOUSE_FILTER_IGNORE


func has_active_modal() -> bool:
	return _active_modal != null


func go_to_home() -> void:
	replace_root(SCENE_HOME)


func go_to_gameplay() -> void:
	replace_root(SCENE_GAMEPLAY)


func go_to_gameplay_placeholder() -> void:
	go_to_gameplay()


func go_to_level_complete() -> void:
	replace_root(SCENE_LEVEL_COMPLETE)


func push_level_select(world: int, world_name: String, highest_unlocked: int, level_stars: Dictionary) -> void:
	var inst: Control = SCENE_LEVEL_SELECT.instantiate() as Control
	_set_full_rect(inst)
	var screen: LevelSelectScreen = inst as LevelSelectScreen
	if screen != null:
		screen.configure(world, world_name, highest_unlocked, level_stars)
		screen.level_selected.connect(_on_level_selected)
	_host.add_child(inst)
	_stack.append(inst)


func _on_level_selected(_world: int, _level: int) -> void:
	go_to_gameplay()


static func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_DEFAULT_PATH)


func _set_full_rect(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
