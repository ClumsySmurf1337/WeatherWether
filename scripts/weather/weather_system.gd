## Pure-function weather card resolution (GDD §5 interaction matrix).
## Every public method takes a grid copy and returns a NEW grid — no mutation.
## Handles all 37 active transitions across 6 cards × 14 terrains.
class_name WeatherSystem
extends RefCounted

const T := WeatherType.Terrain
const C := WeatherType.Card


static func apply(
	grid: Array,
	width: int,
	height: int,
	card_type: int,
	pos: Vector2i
) -> Array:
	var out: Array = grid.duplicate()
	match card_type:
		C.RAIN:
			_apply_rain(out, width, height, pos)
		C.SUN:
			_apply_sun(out, width, height, pos)
		C.FROST:
			_apply_frost(out, width, height, pos)
		C.WIND:
			_apply_wind(out, width, height, pos)
		C.LIGHTNING:
			_apply_lightning(out, width, height, pos)
		C.FOG:
			_apply_fog(out, width, height, pos)
	return out


static func is_valid_placement(
	grid: Array,
	width: int,
	height: int,
	card_type: int,
	pos: Vector2i
) -> bool:
	if not _in_bounds(pos, width, height):
		return false
	var terrain: int = grid[_idx(pos, width)]
	if terrain == T.STONE or terrain == T.START or terrain == T.GOAL:
		return false
	return true


# ---------------------------------------------------------------------------
# Single-tile effects
# ---------------------------------------------------------------------------

static func _apply_rain(grid: Array, width: int, height: int, pos: Vector2i) -> void:
	if not _in_bounds(pos, width, height):
		return
	var i: int = _idx(pos, width)
	var t: int = grid[i]
	match t:
		T.DRY_GRASS:
			grid[i] = T.WET_GRASS
		T.EMPTY:
			grid[i] = T.WATER
		T.SCORCHED:
			grid[i] = T.MUD
		T.FOG_COVERED:
			grid[i] = T.WET_GRASS
		T.PLANT:
			grid[i] = T.PLANT  # grow effect — stays PLANT
		T.SNOW:
			grid[i] = T.WET_GRASS


static func _apply_sun(grid: Array, width: int, height: int, pos: Vector2i) -> void:
	if not _in_bounds(pos, width, height):
		return
	var i: int = _idx(pos, width)
	var t: int = grid[i]
	match t:
		T.WATER:
			grid[i] = T.STEAM
		T.ICE:
			grid[i] = T.WATER
		T.WET_GRASS:
			grid[i] = T.DRY_GRASS
		T.DRY_GRASS:
			grid[i] = T.SCORCHED
		T.PLANT:
			grid[i] = T.DRY_GRASS
		T.FOG_COVERED:
			grid[i] = T.DRY_GRASS
		T.MUD:
			grid[i] = T.DRY_GRASS
		T.SNOW:
			grid[i] = T.WET_GRASS


static func _apply_frost(grid: Array, width: int, height: int, pos: Vector2i) -> void:
	if not _in_bounds(pos, width, height):
		return
	var i: int = _idx(pos, width)
	var t: int = grid[i]
	match t:
		T.WATER:
			grid[i] = T.ICE
		T.WET_GRASS:
			grid[i] = T.ICE
		T.MUD:
			grid[i] = T.ICE
		T.EMPTY:
			grid[i] = T.SNOW
		T.DRY_GRASS:
			grid[i] = T.SNOW
		T.PLANT:
			grid[i] = T.ICE


# ---------------------------------------------------------------------------
# Area effects
# ---------------------------------------------------------------------------

## Wind: 3-tile cross (target + 4 cardinal neighbors). Each tile checked independently.
static func _apply_wind(grid: Array, width: int, height: int, pos: Vector2i) -> void:
	var targets: Array[Vector2i] = [pos]
	for d: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		targets.append(pos + d)
	for cell: Vector2i in targets:
		if not _in_bounds(cell, width, height):
			continue
		var i: int = _idx(cell, width)
		var t: int = grid[i]
		match t:
			T.FOG_COVERED:
				grid[i] = T.DRY_GRASS
			T.STEAM:
				grid[i] = T.EMPTY


## Lightning: flood-fill through conductive tiles. ICE shatters to EMPTY (no chain).
static func _apply_lightning(grid: Array, width: int, height: int, pos: Vector2i) -> void:
	if not _in_bounds(pos, width, height):
		return
	var i: int = _idx(pos, width)
	var t: int = grid[i]

	# ICE shatters to EMPTY without chaining
	if t == T.ICE:
		grid[i] = T.EMPTY
		return

	# Non-conductive single-tile effects
	if not WeatherType.is_conductive(t as WeatherType.Terrain):
		match t:
			T.DRY_GRASS:
				grid[i] = T.SCORCHED
			T.PLANT:
				grid[i] = T.SCORCHED
		return

	# Conductive flood fill — all connected conductive tiles become SCORCHED
	var region: Array[Vector2i] = _flood_fill_conductive(grid, width, height, pos)
	for cell: Vector2i in region:
		var ci: int = _idx(cell, width)
		var ct: int = grid[ci]
		if ct == T.ICE:
			grid[ci] = T.EMPTY
		else:
			grid[ci] = T.SCORCHED


## Fog: 3×3 area centered on target. STONE/START/GOAL excluded.
static func _apply_fog(grid: Array, width: int, height: int, pos: Vector2i) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cell := Vector2i(pos.x + dx, pos.y + dy)
			if not _in_bounds(cell, width, height):
				continue
			var i: int = _idx(cell, width)
			var t: int = grid[i]
			if t == T.STONE or t == T.START or t == T.GOAL or t == T.STEAM:
				continue
			grid[i] = T.FOG_COVERED


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

static func _flood_fill_conductive(
	grid: Array,
	width: int,
	height: int,
	start: Vector2i
) -> Array[Vector2i]:
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	var result: Array[Vector2i] = []
	visited[start] = true

	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		result.append(cur)
		for d: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var nb: Vector2i = cur + d
			if visited.has(nb):
				continue
			if not _in_bounds(nb, width, height):
				continue
			var t: int = grid[_idx(nb, width)]
			if WeatherType.is_conductive(t as WeatherType.Terrain):
				visited[nb] = true
				queue.append(nb)

	return result


static func _in_bounds(pos: Vector2i, width: int, height: int) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height


static func _idx(pos: Vector2i, width: int) -> int:
	return pos.y * width + pos.x
