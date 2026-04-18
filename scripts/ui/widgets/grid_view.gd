class_name GridView
extends Control

## Renders GridManager terrain via TileMapLayer with an optional preview overlay.
## Visualization is UI-only; gameplay logic lives in GridManager + EventBus.

signal tile_tapped(pos: Vector2i)

@export var tile_size_px: int = UITheme.TILE_RENDER_PX
@export var preview_alpha: float = 0.55
@export var tile_set: TileSet = null
@export var terrain_source_id: int = 0
@export var terrain_atlas_coords: Array[Vector2i] = []
@export var use_debug_tileset: bool = true

const T := WeatherType.Terrain

var grid_manager: GridManager = null

var _tilemap: TileMapLayer
var _preview_layer: TileMapLayer
var _grid_size: Vector2i = Vector2i.ZERO
var _grid_origin: Vector2 = Vector2.ZERO
var _current_grid: Array = []
var _preview_grid: Array = []
var _preview_enabled: bool = true
var _tileset_source_id: int = 0
var _event_bus: Node = null


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tilemap = TileMapLayer.new()
	_preview_layer = TileMapLayer.new()
	_preview_layer.modulate = Color(1.0, 1.0, 1.0, preview_alpha)
	_preview_layer.z_index = 1
	add_child(_tilemap)
	add_child(_preview_layer)
	_ensure_tileset()
	_connect_event_bus()
	_refresh_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()


func set_grid_manager(manager: GridManager) -> void:
	if grid_manager == manager:
		return
	_disconnect_grid_manager()
	grid_manager = manager
	_connect_grid_manager()
	_refresh_all()


func set_grid_dimensions(width: int, height: int) -> void:
	_grid_size = Vector2i(max(width, 0), max(height, 0))
	_current_grid = []
	_current_grid.resize(_grid_size.x * _grid_size.y)
	for i in range(_current_grid.size()):
		_current_grid[i] = T.EMPTY as int
	_refresh_tilemap(_tilemap, _current_grid)
	_clear_preview()
	_update_layout()


func get_tile_at_screen(screen_pos: Vector2) -> Vector2i:
	return get_tile_at_local(to_local(screen_pos))


func get_tile_at_local(local_pos: Vector2) -> Vector2i:
	if _grid_size.x <= 0 or _grid_size.y <= 0:
		return Vector2i(-1, -1)
	var relative: Vector2 = local_pos - _grid_origin
	if relative.x < 0.0 or relative.y < 0.0:
		return Vector2i(-1, -1)
	var x: int = int(relative.x / float(tile_size_px))
	var y: int = int(relative.y / float(tile_size_px))
	var pos := Vector2i(x, y)
	if grid_manager != null:
		return pos if grid_manager.is_in_bounds(pos) else Vector2i(-1, -1)
	return pos if (pos.x >= 0 and pos.x < _grid_size.x and pos.y >= 0 and pos.y < _grid_size.y) else Vector2i(-1, -1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			_emit_tile_tap(mouse_event.position)
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if not touch_event.pressed:
			_emit_tile_tap(touch_event.position)


func _emit_tile_tap(screen_pos: Vector2) -> void:
	var pos: Vector2i = get_tile_at_screen(screen_pos)
	if pos.x < 0 or pos.y < 0:
		return
	tile_tapped.emit(pos)


func _connect_event_bus() -> void:
	_event_bus = get_node_or_null("/root/EventBus")
	if _event_bus == null:
		return
	if not _event_bus.level_started.is_connected(_on_level_started):
		_event_bus.level_started.connect(_on_level_started)
	if not _event_bus.card_queued.is_connected(_on_queue_changed):
		_event_bus.card_queued.connect(_on_queue_changed)
	if not _event_bus.card_unqueued.is_connected(_on_queue_changed):
		_event_bus.card_unqueued.connect(_on_queue_changed)
	if not _event_bus.queue_cleared.is_connected(_on_queue_cleared):
		_event_bus.queue_cleared.connect(_on_queue_cleared)
	if not _event_bus.sequence_started.is_connected(_on_sequence_started):
		_event_bus.sequence_started.connect(_on_sequence_started)
	if not _event_bus.sequence_card_resolved.is_connected(_on_sequence_card_resolved):
		_event_bus.sequence_card_resolved.connect(_on_sequence_card_resolved)
	if not _event_bus.sequence_finished.is_connected(_on_sequence_finished):
		_event_bus.sequence_finished.connect(_on_sequence_finished)
	if not _event_bus.no_path_forward.is_connected(_on_no_path_forward):
		_event_bus.no_path_forward.connect(_on_no_path_forward)


func _connect_grid_manager() -> void:
	if grid_manager == null:
		return
	if grid_manager.has_signal("grid_changed") and not grid_manager.grid_changed.is_connected(_on_grid_changed):
		grid_manager.grid_changed.connect(_on_grid_changed)


func _disconnect_grid_manager() -> void:
	if grid_manager == null:
		return
	if grid_manager.has_signal("grid_changed") and grid_manager.grid_changed.is_connected(_on_grid_changed):
		grid_manager.grid_changed.disconnect(_on_grid_changed)


func _on_level_started(level: LevelData) -> void:
	_sync_grid_manager_from_tree()
	if grid_manager == null and level != null:
		_grid_size = Vector2i(level.width, level.height)
		_current_grid = level.initial_terrain.duplicate()
		_refresh_tilemap(_tilemap, _current_grid)
		_clear_preview()
	_update_layout()


func _on_queue_changed(_card_type: int = 0, _pos: Vector2i = Vector2i.ZERO) -> void:
	_refresh_preview()


func _on_queue_cleared() -> void:
	_refresh_preview()


func _on_sequence_started() -> void:
	_preview_enabled = false
	_clear_preview()


func _on_sequence_card_resolved(_card_type: int, pos: Vector2i) -> void:
	if grid_manager == null:
		return
	_refresh_cell(pos)


func _on_sequence_finished() -> void:
	_preview_enabled = true
	_refresh_all()


func _on_no_path_forward() -> void:
	_preview_enabled = true
	_refresh_preview()


func _on_grid_changed(changed: Variant = null) -> void:
	if changed is Array:
		for entry: Variant in changed:
			if entry is Vector2i:
				_refresh_cell(entry)
	elif changed is Vector2i:
		_refresh_cell(changed)
	else:
		_refresh_all()
	_refresh_preview()


func _refresh_all() -> void:
	if grid_manager != null:
		_grid_size = Vector2i(grid_manager.width, grid_manager.height)
		_current_grid = grid_manager.terrain.duplicate()
		_refresh_tilemap(_tilemap, _current_grid)
		_refresh_preview()
	elif _grid_size.x > 0 and _grid_size.y > 0:
		_refresh_tilemap(_tilemap, _current_grid)
		_clear_preview()
	_update_layout()


func _refresh_cell(pos: Vector2i) -> void:
	if grid_manager == null:
		return
	var terrain: int = grid_manager.get_terrain_at(pos)
	_set_cell(_tilemap, pos, terrain)
	var idx: int = pos.y * _grid_size.x + pos.x
	if idx >= 0 and idx < _current_grid.size():
		_current_grid[idx] = terrain
	if _preview_enabled:
		_refresh_preview_cell(pos, terrain)


func _refresh_preview() -> void:
	if not _preview_enabled:
		_clear_preview()
		return
	if grid_manager == null:
		_clear_preview()
		return
	_preview_grid = grid_manager.get_preview_grid()
	for y in range(_grid_size.y):
		for x in range(_grid_size.x):
			var idx: int = y * _grid_size.x + x
			var preview_terrain: int = int(_preview_grid[idx]) if idx < _preview_grid.size() else T.EMPTY
			var base_terrain: int = int(_current_grid[idx]) if idx < _current_grid.size() else preview_terrain
			var pos := Vector2i(x, y)
			if preview_terrain != base_terrain:
				_set_cell(_preview_layer, pos, preview_terrain)
			else:
				_preview_layer.erase_cell(pos)


func _refresh_preview_cell(pos: Vector2i, base_terrain: int) -> void:
	if not _preview_enabled or grid_manager == null:
		return
	var idx: int = pos.y * _grid_size.x + pos.x
	if idx < 0:
		return
	var preview: Array = grid_manager.get_preview_grid()
	if idx >= preview.size():
		return
	var preview_terrain: int = int(preview[idx])
	if preview_terrain != base_terrain:
		_set_cell(_preview_layer, pos, preview_terrain)
	else:
		_preview_layer.erase_cell(pos)


func _clear_preview() -> void:
	_preview_grid.clear()
	_preview_layer.clear()


func _refresh_tilemap(layer: TileMapLayer, grid: Array) -> void:
	if layer == null:
		return
	layer.clear()
	if _grid_size.x <= 0 or _grid_size.y <= 0:
		return
	for y in range(_grid_size.y):
		for x in range(_grid_size.x):
			var idx: int = y * _grid_size.x + x
			var terrain: int = int(grid[idx]) if idx < grid.size() else T.EMPTY
			_set_cell(layer, Vector2i(x, y), terrain)


func _set_cell(layer: TileMapLayer, pos: Vector2i, terrain: int) -> void:
	if tile_set == null:
		return
	var coords: Vector2i = _atlas_coords_for(terrain)
	layer.set_cell(pos, _tileset_source_id, coords, 0)


func _atlas_coords_for(terrain: int) -> Vector2i:
	if terrain < 0:
		terrain = 0
	if terrain < terrain_atlas_coords.size():
		return terrain_atlas_coords[terrain]
	return Vector2i(terrain, 0)


func _update_layout() -> void:
	if _grid_size.x <= 0 or _grid_size.y <= 0:
		return
	var grid_pixel_size := Vector2(float(_grid_size.x) * tile_size_px, float(_grid_size.y) * tile_size_px)
	_grid_origin = (size - grid_pixel_size) * 0.5
	if _grid_origin.x < 0.0:
		_grid_origin.x = 0.0
	if _grid_origin.y < 0.0:
		_grid_origin.y = 0.0
	_tilemap.position = _grid_origin
	_preview_layer.position = _grid_origin
	_apply_tileset_scale()


func _ensure_tileset() -> void:
	if tile_set == null and use_debug_tileset:
		tile_set = _build_debug_tileset()
		_tileset_source_id = terrain_source_id
	else:
		_tileset_source_id = terrain_source_id
	if tile_set != null:
		_tilemap.tile_set = tile_set
		_preview_layer.tile_set = tile_set
	_apply_tileset_scale()


func _apply_tileset_scale() -> void:
	if tile_set == null:
		return
	var region_size: Vector2i = _get_region_size()
	if region_size.x <= 0 or region_size.y <= 0:
		region_size = Vector2i(1, 1)
	var scale := Vector2(float(tile_size_px) / float(region_size.x), float(tile_size_px) / float(region_size.y))
	_tilemap.scale = scale
	_preview_layer.scale = scale


func _get_region_size() -> Vector2i:
	if tile_set == null:
		return Vector2i.ZERO
	var source: TileSetSource = tile_set.get_source(_tileset_source_id)
	if source is TileSetAtlasSource:
		return (source as TileSetAtlasSource).texture_region_size
	return Vector2i.ZERO


func _build_debug_tileset() -> TileSet:
	var colors: Array[Color] = _debug_terrain_colors()
	var image := Image.create(colors.size(), 1, false, Image.FORMAT_RGBA8)
	for i in range(colors.size()):
		image.set_pixel(i, 0, colors[i])
	var texture := ImageTexture.create_from_image(image)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(1, 1)
	var tileset := TileSet.new()
	var source_id: int = tileset.add_source(atlas)
	for i in range(colors.size()):
		atlas.create_tile(Vector2i(i, 0))
	terrain_source_id = source_id
	return tileset


func _debug_terrain_colors() -> Array[Color]:
	return [
		UITheme.bg_deep,                     # EMPTY
		UITheme.card_wind,                   # DRY_GRASS
		UITheme.card_rain,                   # WET_GRASS
		UITheme.card_rain.darkened(0.15),    # WATER
		UITheme.card_frost,                  # ICE
		UITheme.accent_warning.darkened(0.1),# MUD
		UITheme.text_title,                  # SNOW
		UITheme.accent_danger,               # SCORCHED
		UITheme.text_muted.lightened(0.15),  # STEAM
		UITheme.card_wind.lightened(0.2),    # PLANT
		UITheme.border_frame.darkened(0.2),  # STONE
		UITheme.text_muted,                  # FOG_COVERED
		UITheme.accent_success,              # START
		UITheme.accent_danger.lightened(0.1) # GOAL
	]


func _sync_grid_manager_from_tree() -> void:
	if grid_manager != null:
		return
	var root := get_tree().get_root()
	if root == null:
		return
	var gm: Node = root.get_node_or_null("/root/GameManager")
	if gm == null:
		gm = root.find_child("GameManager", true, false)
	if gm == null:
		return
	var candidate: Variant = gm.get("grid_manager")
	if candidate is GridManager:
		set_grid_manager(candidate)
