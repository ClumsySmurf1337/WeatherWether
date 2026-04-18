class_name WorldSelectScreen
extends Control

## Screen 3 — World Select (`docs/UI_SCREENS.md`).
## 2×3 grid of world cards with lock state driven by save progress.

const WORLD_NAMES_FALLBACK: Array[String] = [
	"DOWNPOUR", "HEATWAVE", "COLD SNAP", "GALE FORCE", "THUNDERSTORM", "WHITEOUT",
]
const DEFAULT_LEVELS_PER_WORLD: int = 22
const WORLD_CARD_TEXTURE_TEMPLATE: String = "res://assets/sprites/ui/world_card_w%d.png"
const LOCK_ICON_PATH: String = "res://assets/sprites/ui/icon_lock.png"
const DENIED_SFX_PATH: String = "res://assets/audio/sfx/sfx_denied.wav"

@onready var _back_button: Button = %BackButton
@onready var _title: Label = $Margin/VBox/Header/Title
@onready var _world_grid: GridContainer = %WorldGrid
@onready var _background: ColorRect = $Background

var _highest_unlocked_world: int = 1
var _world_stats: Array = []
var _world_cards: Array[Control] = []
var _save_data: Dictionary = {}
var _worlds: Array = []
var _world_level_counts: Array[int] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_base_theme(self)
	_background.color = UITheme.bg_deep
	UITheme.apply_secondary_button(_back_button)
	UITheme.configure_title_label(_title)
	_back_button.pressed.connect(_on_back_pressed)
	_load_worlds()
	_refresh_world_state()
	_build_world_cards()


func _build_world_cards() -> void:
	for child: Node in _world_grid.get_children():
		_world_grid.remove_child(child)
		child.queue_free()
	_world_cards.clear()

	for i: int in range(_worlds.size()):
		var world_num: int = i + 1
		var is_unlocked: bool = world_num <= _highest_unlocked_world
		var world_name: String = _world_name_for(world_num)
		var card: Control = _create_world_card(world_num, world_name, is_unlocked)
		_world_grid.add_child(card)
		_world_cards.append(card)


func _create_world_card(world_num: int, world_name: String, is_unlocked: bool) -> Control:
	var card := Button.new()
	card.text = ""
	card.custom_minimum_size = Vector2(0, 320)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_NONE

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_color = UITheme.border_frame
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0

	if is_unlocked:
		style.bg_color = UITheme.bg_panel_alt
	else:
		style.bg_color = UITheme.bg_panel
	card.add_theme_color_override(&"font_color", UITheme.text_body)
	card.add_theme_color_override(&"font_hover_color", UITheme.text_title)
	card.add_theme_color_override(&"font_pressed_color", UITheme.text_title)
	card.add_theme_stylebox_override(&"normal", style)
	var hover_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover_style.bg_color = style.bg_color.lightened(0.06)
	card.add_theme_stylebox_override(&"hover", hover_style)
	var pressed_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = style.bg_color.darkened(0.04)
	card.add_theme_stylebox_override(&"pressed", pressed_style)

	if not is_unlocked:
		card.modulate = Color(1.0, 1.0, 1.0, 0.7)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 16)
	margin.add_theme_constant_override(&"margin_right", 16)
	margin.add_theme_constant_override(&"margin_top", 16)
	margin.add_theme_constant_override(&"margin_bottom", 16)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override(&"separation", 8)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)

	var art_container := Control.new()
	art_container.custom_minimum_size = Vector2(0, 180)
	art_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(art_container)

	var art_texture := TextureRect.new()
	art_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_container.add_child(art_texture)

	var art_fallback := Label.new()
	art_fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_fallback.text = "[ painterly biome art ]"
	art_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_container.add_child(art_fallback)
	UITheme.configure_muted_label(art_fallback)
	art_fallback.add_theme_font_size_override(&"font_size", 20)

	var art_path: String = WORLD_CARD_TEXTURE_TEMPLATE % world_num
	var art_tex: Texture2D = _try_load_texture(art_path)
	if is_unlocked and art_tex != null:
		art_texture.texture = art_tex
		art_texture.visible = true
		art_fallback.visible = false
	elif is_unlocked:
		art_texture.visible = false
		art_fallback.visible = true
	else:
		art_texture.visible = false
		art_fallback.visible = false

	var title_label := Label.new()
	title_label.text = "%d. %s" % [world_num, world_name]
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override(&"font_size", 24)
	UITheme.configure_title_label(title_label)
	content.add_child(title_label)

	var progress_label := Label.new()
	progress_label.text = _world_progress_text(world_num)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override(&"font_size", 20)
	UITheme.configure_body_label(progress_label)
	content.add_child(progress_label)

	var lock_container := CenterContainer.new()
	lock_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	lock_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_container.add_child(lock_container)

	var lock_texture := TextureRect.new()
	lock_texture.custom_minimum_size = Vector2(64, 64)
	lock_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_container.add_child(lock_texture)

	var lock_fallback := Label.new()
	lock_fallback.text = "🔒"
	lock_fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lock_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_container.add_child(lock_fallback)
	UITheme.configure_title_label(lock_fallback)
	lock_fallback.add_theme_font_size_override(&"font_size", 28)

	var lock_tex: Texture2D = _try_load_texture(LOCK_ICON_PATH)
	if lock_tex != null:
		lock_texture.texture = lock_tex
		lock_texture.visible = true
		lock_fallback.visible = false
	else:
		lock_texture.visible = false
		lock_fallback.visible = true
	lock_container.visible = not is_unlocked
	progress_label.visible = is_unlocked

	card.pressed.connect(_on_world_card_pressed.bind(world_num, is_unlocked))
	return card


func _on_world_card_pressed(world_num: int, is_unlocked: bool) -> void:
	if not is_unlocked:
		_shake_world_card(world_num)
		_play_denied_sound()
		return
	var world_name: String = _world_name_for(world_num)
	var highest_level: int = _highest_unlocked_level_for_world(world_num)
	var level_stars: Dictionary = _level_stars_for_world(world_num)
	var level_count: int = _level_count_for_world(world_num)
	UIManager.push_level_select(world_num, world_name, highest_level, level_stars, level_count)


func _on_back_pressed() -> void:
	UIManager.pop_screen()


func _load_worlds() -> void:
	_worlds = WorldLoader.load_all_worlds()
	if _worlds.is_empty():
		_worlds = []
		for i: int in range(WORLD_NAMES_FALLBACK.size()):
			var fallback := WorldData.new()
			fallback.id = "world%d" % (i + 1)
			fallback.name = WORLD_NAMES_FALLBACK[i]
			fallback.level_count = DEFAULT_LEVELS_PER_WORLD
			_worlds.append(fallback)
	_world_level_counts.clear()
	for world: Variant in _worlds:
		var data: WorldData = world as WorldData
		var count: int = DEFAULT_LEVELS_PER_WORLD
		if data != null:
			count = data.level_count
			if data.levels.size() > count:
				count = data.levels.size()
		_world_level_counts.append(count)


func _world_for(world_num: int) -> WorldData:
	var idx: int = world_num - 1
	if idx < 0 or idx >= _worlds.size():
		return null
	return _worlds[idx] as WorldData


func _world_name_for(world_num: int) -> String:
	var world: WorldData = _world_for(world_num)
	if world != null and not world.name.is_empty():
		return world.name.to_upper()
	if world_num - 1 < WORLD_NAMES_FALLBACK.size():
		return WORLD_NAMES_FALLBACK[world_num - 1]
	return "WORLD %d" % world_num


func _level_count_for_world(world_num: int) -> int:
	var idx: int = world_num - 1
	if idx < 0 or idx >= _world_level_counts.size():
		return DEFAULT_LEVELS_PER_WORLD
	return _world_level_counts[idx]


func _refresh_world_state() -> void:
	_save_data = _get_save_data()
	_world_stats = _compute_world_stats(_save_data)
	_highest_unlocked_world = _extract_highest_unlocked_world(_save_data)


func _extract_highest_unlocked_world(save_data: Dictionary) -> int:
	var progress: Dictionary = save_data.get("progress", {}) as Dictionary
	var current_world: int = progress.get("current_world", 1) as int
	var unlocked: int = 1
	for i: int in range(_world_stats.size()):
		var stats: Dictionary = _world_stats[i] as Dictionary
		var level_count: int = _level_count_for_world(i + 1)
		if stats.get("completed", 0) as int >= level_count:
			unlocked = i + 2
		else:
			break
	var world_count: int = maxi(_worlds.size(), 1)
	return clampi(maxi(unlocked, current_world), 1, world_count)


func _compute_world_stats(save_data: Dictionary) -> Array:
	var stats: Array = []
	var levels: Dictionary = save_data.get("levels", {}) as Dictionary
	for i: int in range(_worlds.size()):
		var world_num: int = i + 1
		var world: WorldData = _world_for(world_num)
		var completed: int = 0
		var stars: int = 0
		if world != null and not world.levels.is_empty():
			for level_data: LevelData in world.levels:
				var record: Dictionary = levels.get(level_data.id, {}) as Dictionary
				if record.get("completed", false):
					completed += 1
				stars += record.get("stars", 0) as int
		else:
			for level_id: String in levels:
				if not level_id.begins_with("w%d_" % world_num):
					continue
				var record_value: Variant = levels[level_id]
				if not record_value is Dictionary:
					continue
				var record: Dictionary = record_value as Dictionary
				if record.get("completed", false):
					completed += 1
				stars += record.get("stars", 0) as int
		stats.append({"completed": completed, "stars": stars})
	return stats


func _highest_unlocked_level_for_world(world_num: int) -> int:
	var level_count: int = _level_count_for_world(world_num)
	var levels: Dictionary = _save_data.get("levels", {}) as Dictionary
	var highest_completed: int = 0
	var world: WorldData = _world_for(world_num)
	if world != null and not world.levels.is_empty():
		for level_data: LevelData in world.levels:
			var record: Dictionary = levels.get(level_data.id, {}) as Dictionary
			if record.get("completed", false):
				highest_completed = maxi(highest_completed, level_data.level_number)
	else:
		for level_id: String in levels:
			if not level_id.begins_with("w%d_" % world_num):
				continue
			var record_value: Variant = levels[level_id]
			if not record_value is Dictionary:
				continue
			var record: Dictionary = record_value as Dictionary
			if record.get("completed", false):
				var parsed: Dictionary = _parse_highest_unlocked(level_id)
				highest_completed = maxi(highest_completed, parsed.get("level", 1) as int)
	var highest_unlocked: int = highest_completed + 1
	return clampi(highest_unlocked, 1, level_count)


func _level_stars_for_world(world_num: int) -> Dictionary:
	var stars: Dictionary = {}
	var levels: Dictionary = _save_data.get("levels", {}) as Dictionary
	var world: WorldData = _world_for(world_num)
	if world != null and not world.levels.is_empty():
		for level_data: LevelData in world.levels:
			var record: Dictionary = levels.get(level_data.id, {}) as Dictionary
			stars[level_data.id] = record.get("stars", 0)
	else:
		for level_id: String in levels:
			if not level_id.begins_with("w%d_" % world_num):
				continue
			var record_value: Variant = levels[level_id]
			if not record_value is Dictionary:
				continue
			var record: Dictionary = record_value as Dictionary
			stars[level_id] = record.get("stars", 0)
	return stars


func _world_progress_text(world_num: int) -> String:
	if world_num - 1 < 0 or world_num - 1 >= _world_stats.size():
		return "··· 0/%d" % _level_count_for_world(world_num)
	var stats: Dictionary = _world_stats[world_num - 1] as Dictionary
	var completed: int = stats.get("completed", 0) as int
	var stars: int = stats.get("stars", 0) as int
	var rating: int = 0
	if completed > 0:
		rating = int(floor(float(stars) / float(completed)))
	var star_text: String = _stars_text(rating)
	return "%s %d/%d" % [star_text, completed, _level_count_for_world(world_num)]


func _parse_highest_unlocked(value: String) -> Dictionary:
	var world_num: int = 1
	var level_num: int = 1
	if value.begins_with("w"):
		var parts: PackedStringArray = value.split("_")
		if parts.size() >= 1:
			world_num = int(parts[0].trim_prefix("w"))
		if parts.size() >= 2:
			level_num = int(parts[1].trim_prefix("l"))
	return {"world": world_num, "level": level_num}


func _stars_text(rating: int) -> String:
	match clampi(rating, 0, 3):
		3:
			return "★★★"
		2:
			return "★★·"
		1:
			return "★··"
		_:
			return "···"


func _shake_world_card(world_num: int) -> void:
	var idx: int = world_num - 1
	if idx < 0 or idx >= _world_cards.size():
		return
	var card: Control = _world_cards[idx]
	var original_x: float = card.position.x
	var shake_tween: Tween = create_tween()
	shake_tween.tween_property(card, "position:x", original_x + 8.0, 0.05)
	shake_tween.tween_property(card, "position:x", original_x - 8.0, 0.05)
	shake_tween.tween_property(card, "position:x", original_x + 4.0, 0.05)
	shake_tween.tween_property(card, "position:x", original_x, 0.05)


func _play_denied_sound() -> void:
	if not ResourceLoader.exists(DENIED_SFX_PATH):
		return
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio == null or not audio.has_method("play_sfx"):
		return
	audio.call("play_sfx", DENIED_SFX_PATH)


func _get_save_data() -> Dictionary:
	var save: Node = get_node_or_null("/root/SaveManager")
	if save != null:
		var data_value: Variant = save.get("data")
		if data_value is Dictionary:
			return data_value
	return {}


func _try_load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
