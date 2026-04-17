class_name AnimationDirector
extends Node

signal weather_effect_finished(card_type: int)
signal sequence_complete
signal walk_started
signal walk_finished
signal death_finished(cause: int)
signal cheer_finished

@export var inter_card_pause_ms: int = 100
@export var walk_start_delay_ms: int = 250

var speed_multiplier: float = 1.0
var reduce_motion: bool = false
var _sequence_queue: Array = []
var _sequence_active: bool = false


func _ready() -> void:
	var save: Node = get_node_or_null("/root/SaveManager")
	if save != null and save.has_method("get_setting"):
		reduce_motion = bool(save.call("get_setting", "reduce_motion", false))
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("settings_changed"):
		bus.connect("settings_changed", _on_settings_changed)
	if not weather_effect_finished.is_connected(_on_internal_weather_finished):
		weather_effect_finished.connect(_on_internal_weather_finished)


## Plays queued card animations in order (visuals only). Does not mutate the grid.
func play_sequence(queue: Array, _grid_manager: GridManager) -> void:
	if _sequence_active:
		return
	_sequence_queue = queue.duplicate()
	_sequence_active = true
	_play_next_sequence_entry()


## Plays a single card resolution effect at the target.
func play_card_resolution(card_type: int, _target: Vector2i) -> void:
	var duration_ms: int = _card_duration_ms(card_type)
	if reduce_motion:
		duration_ms = min(duration_ms, 120)
	_schedule_ms(duration_ms, weather_effect_finished.emit.bind(card_type))


## Plays the character walk timing (visuals only).
func play_character_walk(path: Array[Vector2i]) -> void:
	walk_started.emit()
	if reduce_motion or path.size() <= 1:
		walk_finished.emit()
		return
	var step_ms: int = 250
	var total_ms: int = step_ms * (path.size() - 1)
	_schedule_ms(total_ms, walk_finished.emit)


## Plays the character death animation timing (visuals only).
func play_character_death(cause: int) -> void:
	var duration_ms: int = _death_duration_ms(cause)
	if reduce_motion:
		duration_ms = min(duration_ms, 120)
	_schedule_ms(duration_ms, death_finished.emit.bind(cause))


## Plays the win celebration timing (visuals only).
func play_character_win() -> void:
	var duration_ms: int = 1000
	if reduce_motion:
		duration_ms = min(duration_ms, 120)
	_schedule_ms(duration_ms, cheer_finished.emit)


func set_speed_multiplier(multiplier: float) -> void:
	speed_multiplier = max(0.1, multiplier)


func toggle_fast_mode() -> void:
	if speed_multiplier < 1.5:
		speed_multiplier = 2.0
	else:
		speed_multiplier = 1.0


func get_scaled_delay_seconds(ms: int, skip_on_reduce_motion: bool = true) -> float:
	if ms <= 0:
		return 0.0
	if skip_on_reduce_motion and reduce_motion:
		return 0.0
	return float(ms) / 1000.0 / max(0.1, speed_multiplier)


func _card_duration_ms(card_type: int) -> int:
	match card_type:
		WeatherType.Card.RAIN:
			return 500
		WeatherType.Card.SUN:
			return 600
		WeatherType.Card.FROST:
			return 700
		WeatherType.Card.WIND:
			return 600
		WeatherType.Card.LIGHTNING:
			return 700
		WeatherType.Card.FOG:
			return 900
		_:
			return 500


func _death_duration_ms(cause: int) -> int:
	match cause:
		0: # DROWN
			return 1000
		1: # BURN
			return 1200
		2: # FALL
			return 900
		3: # ELECTROCUTE
			return 800
		4: # FREEZE
			return 1000
		_:
			return 900


func _schedule_ms(ms: int, callback: Callable) -> void:
	var delay: float = get_scaled_delay_seconds(ms, false)
	if delay <= 0.0:
		callback.call()
		return
	var timer: SceneTreeTimer = get_tree().create_timer(delay)
	timer.timeout.connect(callback)


func _play_next_sequence_entry() -> void:
	if not _sequence_active:
		return
	if _sequence_queue.is_empty():
		_sequence_active = false
		sequence_complete.emit()
		return
	var entry: Array = _sequence_queue.pop_front()
	if entry.size() < 2:
		_play_next_sequence_entry()
		return
	var card_type: int = entry[0]
	var pos: Vector2i = entry[1]
	play_card_resolution(card_type, pos)


func _on_internal_weather_finished(_card_type: int) -> void:
	if not _sequence_active:
		return
	var delay: float = get_scaled_delay_seconds(inter_card_pause_ms, true)
	if delay <= 0.0:
		_play_next_sequence_entry()
		return
	var timer: SceneTreeTimer = get_tree().create_timer(delay)
	timer.timeout.connect(_play_next_sequence_entry)


func _on_settings_changed(key: String, value: Variant) -> void:
	if key == "reduce_motion":
		reduce_motion = bool(value)
