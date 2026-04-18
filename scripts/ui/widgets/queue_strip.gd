class_name QueueStrip
extends PanelContainer

signal remove_requested(index: int)
signal reorder_requested(from_index: int, to_index: int)

@export var max_slots: int = 6
@export var empty_hint_text: String = "tap a card, tap a tile"
@export var slot_size: Vector2 = Vector2(UITheme.TOUCH_TARGET_MIN_PX, UITheme.TOUCH_TARGET_MIN_PX)

@onready var _slot_container: HBoxContainer = %QueueSlots
@onready var _hint_label: Label = %QueueHint

var _entries: Array = []
var _slots: Array = []


class QueueSlot:
	extends PanelContainer

	signal remove_requested(index: int)
	signal reorder_requested(from_index: int, to_index: int)

	var index: int = -1
	var fill_color: Color = UITheme.bg_panel_alt
	var _label: Label = null
	var _dragging: bool = false

	func setup(slot_index: int, size: Vector2) -> void:
		index = slot_index
		custom_minimum_size = size
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_NONE
		if _label == null:
			_label = Label.new()
			_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			add_child(_label)

	func set_number(number: int) -> void:
		if _label != null:
			_label.text = str(number)

	func set_label_style() -> void:
		if _label != null:
			UITheme.configure_numbers_label(_label)

	func _get_drag_data(_at_position: Vector2) -> Variant:
		_dragging = true
		var preview := PanelContainer.new()
		var preview_style := StyleBoxFlat.new()
		preview_style.bg_color = fill_color
		preview_style.border_color = UITheme.border_frame
		preview_style.border_width_left = 2
		preview_style.border_width_top = 2
		preview_style.border_width_right = 2
		preview_style.border_width_bottom = 2
		preview_style.corner_radius_top_left = 6
		preview_style.corner_radius_top_right = 6
		preview_style.corner_radius_bottom_right = 6
		preview_style.corner_radius_bottom_left = 6
		preview.add_theme_stylebox_override(&"panel", preview_style)
		preview.custom_minimum_size = custom_minimum_size
		var preview_label := Label.new()
		preview_label.text = _label.text if _label != null else ""
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UITheme.configure_numbers_label(preview_label)
		preview.add_child(preview_label)
		set_drag_preview(preview)
		return {"from_index": index}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return typeof(data) == TYPE_DICTIONARY and data.has("from_index")

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if typeof(data) != TYPE_DICTIONARY or not data.has("from_index"):
			_dragging = false
			return
		reorder_requested.emit(int(data["from_index"]), index)
		_dragging = false

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mouse_event: InputEventMouseButton = event as InputEventMouseButton
			if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
				if not _dragging:
					remove_requested.emit(index)
				_dragging = false
		elif event is InputEventScreenTouch:
			var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
			if not touch_event.pressed:
				if not _dragging:
					remove_requested.emit(index)
				_dragging = false

	func _notification(what: int) -> void:
		if what == NOTIFICATION_DRAG_END:
			_dragging = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _hint_label != null:
		_hint_label.text = empty_hint_text
		UITheme.configure_muted_label(_hint_label)
	_build_slots()
	_refresh()


func set_queue(entries: Array) -> void:
	_entries.clear()
	for entry: Variant in entries:
		_entries.append(_normalize_entry(entry))
	_refresh()


func set_queue_count(count: int) -> void:
	_entries.clear()
	for _i in range(count):
		_entries.append({"card_type": -1, "pos": Vector2i.ZERO})
	_refresh()


func get_queue_size() -> int:
	return _entries.size()


func clear_queue() -> void:
	_entries.clear()
	_refresh()


func _build_slots() -> void:
	if _slot_container == null:
		_slot_container = HBoxContainer.new()
		_slot_container.name = &"QueueSlots"
		_slot_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_slot_container.alignment = BoxContainer.ALIGNMENT_CENTER
		_slot_container.add_theme_constant_override(&"separation", 12)
		_slot_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_slot_container)
	_slot_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in _slot_container.get_children():
		child.queue_free()
	_slots.clear()
	if max_slots < 1:
		max_slots = 1
	for i in range(max_slots):
		var slot := QueueSlot.new()
		slot.setup(i, slot_size)
		slot.set_label_style()
		slot.remove_requested.connect(_on_slot_remove_requested)
		slot.reorder_requested.connect(_on_slot_reorder_requested)
		_slot_container.add_child(slot)
		_slots.append(slot)


func _refresh() -> void:
	if _hint_label != null:
		_hint_label.visible = _entries.is_empty()
	if _slot_container != null:
		_slot_container.visible = not _entries.is_empty()
	if _entries.size() > _slots.size():
		max_slots = _entries.size()
		_build_slots()
	for i in range(_slots.size()):
		var slot: QueueSlot = _slots[i] as QueueSlot
		if slot == null:
			continue
		if i < _entries.size():
			var entry: Dictionary = _entries[i]
			slot.visible = true
			slot.fill_color = _color_for_card(int(entry.get("card_type", -1)))
			_apply_slot_style(slot, slot.fill_color)
			slot.set_number(i + 1)
		else:
			slot.visible = false


func _apply_slot_style(slot: PanelContainer, fill: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = UITheme.border_frame
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	slot.add_theme_stylebox_override(&"panel", style)


func _normalize_entry(entry: Variant) -> Dictionary:
	if entry is Dictionary:
		return {
			"card_type": int(entry.get("card_type", entry.get("card", -1))),
			"pos": entry.get("pos", Vector2i.ZERO),
		}
	if entry is Array and (entry as Array).size() >= 2:
		var entry_array: Array = entry as Array
		return {"card_type": int(entry_array[0]), "pos": entry_array[1]}
	if entry is int:
		return {"card_type": int(entry), "pos": Vector2i.ZERO}
	return {"card_type": -1, "pos": Vector2i.ZERO}


func _color_for_card(card_type: int) -> Color:
	match card_type:
		WeatherType.Card.RAIN:
			return UITheme.card_rain
		WeatherType.Card.SUN:
			return UITheme.card_sun
		WeatherType.Card.FROST:
			return UITheme.card_frost
		WeatherType.Card.WIND:
			return UITheme.card_wind
		WeatherType.Card.LIGHTNING:
			return UITheme.card_lightning
		WeatherType.Card.FOG:
			return UITheme.card_fog
		_:
			return UITheme.bg_panel_alt


func _on_slot_remove_requested(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	_entries.remove_at(index)
	_refresh()
	remove_requested.emit(index)


func _on_slot_reorder_requested(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return
	if from_index < 0 or from_index >= _entries.size():
		return
	if to_index < 0 or to_index >= _entries.size():
		return
	var entry: Dictionary = _entries[from_index]
	_entries.remove_at(from_index)
	var target_index: int = to_index
	if from_index < to_index:
		target_index -= 1
	_entries.insert(target_index, entry)
	_refresh()
	reorder_requested.emit(from_index, target_index)
