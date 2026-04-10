## Pure A* pathfinding on a flat terrain grid (GDD §4 — cardinal moves, walkable predicate).
## Grid cells are `int` values matching `WeatherType.Terrain`; walkability uses `WeatherType.is_walkable()`.
class_name Pathfinder
extends RefCounted

const _SENTINEL_PARENT := Vector2i(2147483647, 2147483647)

static func _index(pos: Vector2i, width: int) -> int:
	return pos.y * width + pos.x


static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func _dirs_straight_first(current: Vector2i, parent: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var dirs: Array[Vector2i] = []
	var cardinals: Array[Vector2i] = [
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 0),
	]
	if parent == _SENTINEL_PARENT:
		var to_goal := goal - current
		var dx := to_goal.x
		var dy := to_goal.y
		var first: Vector2i
		if absi(dx) > absi(dy):
			first = Vector2i(signi(dx), 0)
		elif absi(dy) > absi(dx):
			first = Vector2i(0, signi(dy))
		else:
			if dx != 0:
				first = Vector2i(signi(dx), 0)
			elif dy != 0:
				first = Vector2i(0, signi(dy))
			else:
				first = Vector2i.ZERO
		if first != Vector2i.ZERO:
			dirs.append(first)
			for d: Vector2i in cardinals:
				if d != first:
					dirs.append(d)
		return dirs
	var step := current - parent
	dirs.append(step)
	for d: Vector2i in cardinals:
		if d != step:
			dirs.append(d)
	return dirs


## Returns tile positions from start to goal inclusive, or empty if unreachable.
## Grid is a flat Array of terrain ints, row-major: y * width + x.
static func find_path(
	grid: Array,
	width: int,
	height: int,
	start: Vector2i,
	goal: Vector2i
) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if width <= 0 or height <= 0:
		return out
	if not _in_bounds(start, width, height) or not _in_bounds(goal, width, height):
		return out
	var start_terrain: int = grid[_index(start, width)]
	var goal_terrain: int = grid[_index(goal, width)]
	if not WeatherType.is_walkable(start_terrain as WeatherType.Terrain):
		return out
	if not WeatherType.is_walkable(goal_terrain as WeatherType.Terrain):
		return out
	if start == goal:
		out.append(start)
		return out

	var g_score: Dictionary = {}
	var came_from: Dictionary = {}
	var open_list: Array[Vector2i] = []

	g_score[start] = 0
	open_list.append(start)

	while not open_list.is_empty():
		var current: Vector2i = _pop_best_open(open_list, g_score, goal)
		if current == goal:
			return _reconstruct_path(came_from, start, goal)

		var parent: Vector2i = _SENTINEL_PARENT
		if current != start:
			parent = came_from[current] as Vector2i

		for delta: Vector2i in _dirs_straight_first(current, parent, goal):
			var neighbor: Vector2i = current + delta
			if not _in_bounds(neighbor, width, height):
				continue
			var t: int = grid[_index(neighbor, width)]
			if not WeatherType.is_walkable(t as WeatherType.Terrain):
				continue
			var tentative_g: int = (g_score[current] as int) + 1
			if not g_score.has(neighbor) or tentative_g < (g_score[neighbor] as int):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				if not open_list.has(neighbor):
					open_list.append(neighbor)

	return out


static func _in_bounds(pos: Vector2i, width: int, height: int) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height


static func _pop_best_open(
	open_list: Array[Vector2i],
	g_score: Dictionary,
	goal: Vector2i
) -> Vector2i:
	var best_i: int = 0
	var best_pos: Vector2i = open_list[0]
	var best_g: int = g_score[best_pos] as int
	var best_f: int = best_g + _manhattan(best_pos, goal)
	for i in range(1, open_list.size()):
		var pos: Vector2i = open_list[i]
		var g: int = g_score[pos] as int
		var f: int = g + _manhattan(pos, goal)
		if _is_better_candidate(f, g, pos, best_f, best_g, best_pos):
			best_f = f
			best_g = g
			best_i = i
			best_pos = pos
	open_list.remove_at(best_i)
	return best_pos


static func _is_better_candidate(
	f: int,
	g: int,
	pos: Vector2i,
	best_f: int,
	best_g: int,
	best_pos: Vector2i
) -> bool:
	if f < best_f:
		return true
	if f > best_f:
		return false
	if g > best_g:
		return true
	if g < best_g:
		return false
	if pos.y < best_pos.y:
		return true
	if pos.y > best_pos.y:
		return false
	return pos.x < best_pos.x


static func _reconstruct_path(came_from: Dictionary, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var rev: Array[Vector2i] = []
	var cur: Vector2i = goal
	while cur != start:
		rev.append(cur)
		cur = came_from[cur] as Vector2i
	rev.append(start)
	var out: Array[Vector2i] = []
	for i in range(rev.size() - 1, -1, -1):
		out.append(rev[i])
	return out
