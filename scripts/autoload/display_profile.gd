extends Node
## Autoload: sizes the game window on **desktop** to a comfortable 9:16 portrait frame (design 1080×1920)
## without stretching content. **Android / iOS / Web** skip this — OS handles fullscreen / browser chrome.
## Simulated phone sizes: set env `WHETHER_DISPLAY_PRESET` (see `docs/DISPLAY_PROFILE.md`).

const DESIGN_WIDTH: int = 1080
const DESIGN_HEIGHT: int = 1920
const ASPECT_X: float = 9.0
const ASPECT_Y: float = 16.0

const MIN_WINDOW: Vector2i = Vector2i(360, 640)

enum Preset {
	AUTO_DESKTOP,
	SIM_360,
	SIM_540,
	SIM_720,
	NATIVE_DESIGN,
}


func _enter_tree() -> void:
	_apply_startup()


func _apply_startup() -> void:
	if OS.has_feature("android") or OS.has_feature("ios"):
		return
	if OS.has_feature("web"):
		return
	if DisplayServer.get_name() == &"headless":
		return

	var window: Window = get_window()
	if window == null:
		return

	var screen_size: Vector2i = DisplayServer.screen_get_size()
	if screen_size.x < 32 or screen_size.y < 32:
		return

	var env_value: String = String(OS.get_environment("WHETHER_DISPLAY_PRESET")).strip_edges()
	if env_value != "":
		if _apply_preset_from_string(env_value, window):
			return
		push_warning("DisplayProfile: unknown WHETHER_DISPLAY_PRESET=%s — using auto desktop fit" % env_value)

	_apply_auto_desktop_fit(window)


func _apply_preset_from_string(raw: String, window: Window) -> bool:
	var v: String = raw.to_lower()
	match v:
		"auto":
			_apply_auto_desktop_fit(window)
			return true
		"360", "sim_360":
			_apply_preset_size(window, Vector2i(360, 640))
			return true
		"540", "sim_540":
			_apply_preset_size(window, Vector2i(540, 960))
			return true
		"720", "sim_720":
			_apply_preset_size(window, Vector2i(720, 1280))
			return true
		"1080", "native", "sim_1080", "native_design":
			_apply_preset_size(window, Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT))
			return true
		_:
			return false


func apply_preset(preset: Preset) -> void:
	var window: Window = get_window()
	if window == null:
		return
	match preset:
		Preset.AUTO_DESKTOP:
			_apply_auto_desktop_fit(window)
		Preset.SIM_360:
			_apply_preset_size(window, Vector2i(360, 640))
		Preset.SIM_540:
			_apply_preset_size(window, Vector2i(540, 960))
		Preset.SIM_720:
			_apply_preset_size(window, Vector2i(720, 1280))
		Preset.NATIVE_DESIGN:
			_apply_preset_size(window, Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT))


func _apply_preset_size(window: Window, size: Vector2i) -> void:
	var w: int = clampi(size.x, MIN_WINDOW.x, DESIGN_WIDTH)
	var h: int = clampi(size.y, MIN_WINDOW.y, DESIGN_HEIGHT)
	window.min_size = MIN_WINDOW
	window.size = Vector2i(w, h)
	window.move_to_center()


func _apply_auto_desktop_fit(window: Window) -> void:
	var usable: Rect2i = DisplayServer.screen_get_usable_rect()
	var max_w: float = float(usable.size.x)
	var max_h: float = float(usable.size.y)
	if max_w < 32.0 or max_h < 32.0:
		var screen_size: Vector2i = DisplayServer.screen_get_size()
		max_w = float(screen_size.x)
		max_h = float(screen_size.y)
	if max_w < 32.0 or max_h < 32.0:
		return

	# Fit ~92% of usable height, 9:16, cap at design resolution, stay inside width.
	var target_h: float = min(float(DESIGN_HEIGHT), max_h * 0.92)
	var target_w: float = target_h * ASPECT_X / ASPECT_Y
	if target_w > max_w * 0.95:
		target_w = max_w * 0.95
		target_h = target_w * ASPECT_Y / ASPECT_X

	var iw: int = clampi(int(round(target_w)), MIN_WINDOW.x, DESIGN_WIDTH)
	var ih: int = clampi(int(round(target_h)), MIN_WINDOW.y, DESIGN_HEIGHT)
	window.min_size = MIN_WINDOW
	window.size = Vector2i(iw, ih)
	window.move_to_center()
