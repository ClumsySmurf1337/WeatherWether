## Autoload: central audio playback for music, SFX, and ambient layers.
extends Node

const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_AMBIENT: String = "Ambient"

const MUSIC_CROSSFADE_SECONDS: float = 1.0
const SFX_POOL_SIZE: int = 8

var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer
var _inactive_music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []

var _current_music_path: String = ""
var _current_ambient_path: String = ""


func _ready() -> void:
	_ensure_buses()
	_setup_players()
	_apply_saved_volumes()
	EventBus.settings_changed.connect(_on_setting_changed)


func play_music(track_path: String) -> void:
	if track_path.is_empty():
		_stop_music()
		return
	if track_path == _current_music_path and _active_music_player.playing:
		return

	var stream: AudioStream = _load_stream(track_path)
	if stream == null:
		return

	_inactive_music_player.stream = stream
	_inactive_music_player.volume_db = -80.0
	_inactive_music_player.play()

	if _active_music_player.playing:
		_crossfade_music(_active_music_player, _inactive_music_player, MUSIC_CROSSFADE_SECONDS)
	else:
		_inactive_music_player.volume_db = 0.0

	_current_music_path = track_path
	var previous_active: AudioStreamPlayer = _active_music_player
	_active_music_player = _inactive_music_player
	_inactive_music_player = previous_active


func play_ambient(layer_path: String) -> void:
	if layer_path.is_empty():
		_stop_ambient()
		return
	if layer_path == _current_ambient_path and _ambient_player.playing:
		return

	var stream: AudioStream = _load_stream(layer_path)
	if stream == null:
		return

	_ambient_player.stream = stream
	_ambient_player.play()
	_current_ambient_path = layer_path


func play_sfx(sound_path: String) -> void:
	var stream: AudioStream = _load_stream(sound_path)
	if stream == null:
		return

	var player: AudioStreamPlayer = _get_available_sfx_player()
	player.stream = stream
	player.volume_db = 0.0
	player.play()


func _ensure_buses() -> void:
	_ensure_bus(BUS_MUSIC, BUS_MASTER)
	_ensure_bus(BUS_SFX, BUS_MASTER)
	_ensure_bus(BUS_AMBIENT, BUS_MASTER)


func _ensure_bus(name: String, send: String) -> void:
	var idx: int = AudioServer.get_bus_index(name)
	if idx == -1:
		idx = AudioServer.get_bus_count()
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, name)
	AudioServer.set_bus_send(idx, send)


func _setup_players() -> void:
	_music_player_a = AudioStreamPlayer.new()
	_music_player_b = AudioStreamPlayer.new()
	_music_player_a.bus = BUS_MUSIC
	_music_player_b.bus = BUS_MUSIC
	add_child(_music_player_a)
	add_child(_music_player_b)
	_active_music_player = _music_player_a
	_inactive_music_player = _music_player_b

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = BUS_AMBIENT
	add_child(_ambient_player)

	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_players.append(player)


func _apply_saved_volumes() -> void:
	var save: Node = get_node_or_null("/root/SaveManager")
	if save == null or not save.has_method("get_setting"):
		return
	_set_bus_volume(BUS_MASTER, save.call("get_setting", "master_volume", 1.0))
	_set_bus_volume(BUS_MUSIC, save.call("get_setting", "music_volume", 0.8))
	_set_bus_volume(BUS_SFX, save.call("get_setting", "sfx_volume", 1.0))
	var ambient_volume: Variant = save.call(
		"get_setting",
		"ambient_volume",
		save.call("get_setting", "music_volume", 0.8)
	)
	_set_bus_volume(BUS_AMBIENT, ambient_volume)


func _on_setting_changed(key: String, value: Variant) -> void:
	match key:
		"master_volume":
			_set_bus_volume(BUS_MASTER, value)
		"music_volume":
			_set_bus_volume(BUS_MUSIC, value)
			_set_bus_volume(BUS_AMBIENT, value)
		"sfx_volume":
			_set_bus_volume(BUS_SFX, value)
		"ambient_volume":
			_set_bus_volume(BUS_AMBIENT, value)


func _set_bus_volume(bus_name: String, linear_value: Variant) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var volume: float = clampf(float(linear_value), 0.0, 1.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(volume))


func _load_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		push_error("AudioManager: missing audio stream %s" % path)
		return null
	var resource: Resource = load(path)
	if resource == null or not (resource is AudioStream):
		push_error("AudioManager: invalid audio stream %s" % path)
		return null
	return resource as AudioStream


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	var extra := AudioStreamPlayer.new()
	extra.bus = BUS_SFX
	add_child(extra)
	_sfx_players.append(extra)
	return extra


func _crossfade_music(from_player: AudioStreamPlayer, to_player: AudioStreamPlayer, duration: float) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(from_player, "volume_db", -80.0, duration)
	tween.tween_property(to_player, "volume_db", 0.0, duration)
	tween.finished.connect(func() -> void:
		from_player.stop()
	)


func _stop_music() -> void:
	_active_music_player.stop()
	_inactive_music_player.stop()
	_current_music_path = ""


func _stop_ambient() -> void:
	_ambient_player.stop()
	_current_ambient_path = ""
