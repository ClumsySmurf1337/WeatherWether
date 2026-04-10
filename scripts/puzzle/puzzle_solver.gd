## BFS puzzle solver (GDD §10 / CODE_REWRITE_PLAN §2).
## Explores (card, position) combinations from an initial board state.
## Goal predicate: A* path exists from START to any GOAL on walkable tiles.
## State dedup via PuzzleState.hash_key(). Hard cap at MAX_STATES.
class_name PuzzleSolver
extends RefCounted

const MAX_STATES: int = 200000

var _width: int
var _height: int
var _goal_predicate: Callable


func _init(width: int, height: int, goal_predicate: Callable) -> void:
	_width = width
	_height = height
	_goal_predicate = goal_predicate


## BFS from initial state, expanding by trying every (remaining_card, in-bounds position).
## Returns the first (shortest-move) solution found or an unsolvable result if none.
func solve(initial_terrain: Array, available_cards: Array[int]) -> SolverResult:
	var start_time: int = Time.get_ticks_msec()
	var states_explored: int = 0

	var initial_moves: Array = []
	var initial_remaining: Array[int] = available_cards.duplicate()
	var start_state := PuzzleState.new(initial_terrain.duplicate(), initial_remaining, initial_moves)

	if _goal_predicate.call(start_state.terrain, _width, _height):
		var elapsed: float = float(Time.get_ticks_msec() - start_time)
		return SolverResult.new(true, [], 0, 1, elapsed)

	var visited: Dictionary = {}
	var queue: Array[PuzzleState] = []
	visited[start_state.hash_key()] = true
	queue.append(start_state)

	while not queue.is_empty():
		if states_explored >= MAX_STATES:
			break

		var current: PuzzleState = queue.pop_front()
		states_explored += 1

		var unique_cards: Dictionary = {}
		for i: int in range(current.remaining_cards.size()):
			var card_type: int = current.remaining_cards[i]
			if unique_cards.has(card_type):
				continue
			unique_cards[card_type] = true

			for y: int in range(_height):
				for x: int in range(_width):
					var pos := Vector2i(x, y)
					if not WeatherSystem.is_valid_placement(current.terrain, _width, _height, card_type, pos):
						continue

					var new_terrain: Array = WeatherSystem.apply(
						current.terrain, _width, _height, card_type, pos
					)

					var new_remaining: Array[int] = _remove_first(current.remaining_cards, card_type)
					var new_moves: Array = current.moves.duplicate()
					new_moves.append([card_type, pos])

					var next_state := PuzzleState.new(new_terrain, new_remaining, new_moves)
					var key: String = next_state.hash_key()
					if visited.has(key):
						continue
					visited[key] = true

					if _goal_predicate.call(new_terrain, _width, _height):
						var elapsed: float = float(Time.get_ticks_msec() - start_time)
						return SolverResult.new(
							true,
							next_state.moves,
							next_state.moves.size(),
							states_explored,
							elapsed
						)

					if not new_remaining.is_empty():
						queue.append(next_state)

	var elapsed: float = float(Time.get_ticks_msec() - start_time)
	return SolverResult.new(false, [], 0, states_explored, elapsed)


## Default goal predicate: A* path exists from start to any goal tile.
static func make_path_exists_goal(start: Vector2i, goals: Array[Vector2i]) -> Callable:
	return func(terrain: Array, w: int, h: int) -> bool:
		for goal: Vector2i in goals:
			var path: Array[Vector2i] = Pathfinder.find_path(terrain, w, h, start, goal)
			if not path.is_empty():
				return true
		return false


static func _remove_first(cards: Array[int], card_type: int) -> Array[int]:
	var result: Array[int] = cards.duplicate()
	var idx: int = result.find(card_type)
	if idx >= 0:
		result.remove_at(idx)
	return result
