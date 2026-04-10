## Sky's state machine: idle, walk, death, and win states (GDD §4).
## Pure logic — no sprites or rendering. UI binds via EventBus signals.
class_name CharacterController
extends RefCounted

enum State { IDLE, SURPRISED, WALK, CHEER, DROWN, BURN, ELECTROCUTE, FREEZE, FALL }

var current_state: State = State.IDLE
var position: Vector2i
var facing: Vector2i = Vector2i(0, 1)
var path: Array[Vector2i] = []
var path_index: int = 0


func _init(start_pos: Vector2i) -> void:
	position = start_pos


func begin_walk(computed_path: Array[Vector2i]) -> void:
	path = computed_path
	path_index = 0
	if path.size() > 1:
		current_state = State.WALK
		path_index = 1
	elif path.size() == 1:
		current_state = State.IDLE


## Advance one tile along the path. Returns true if walk continues,
## false if the character reached the goal, died, or ran out of path.
func step(grid: Array, width: int, height: int, goals: Array[Vector2i]) -> bool:
	if current_state != State.WALK:
		return false
	if path_index >= path.size():
		current_state = State.IDLE
		return false

	var next_pos: Vector2i = path[path_index]
	facing = next_pos - position
	position = next_pos
	path_index += 1

	var terrain: int = _get_terrain(grid, width, height, position)
	var death: State = _check_death(terrain)
	if death != State.IDLE:
		current_state = death
		return false

	if goals.has(position):
		trigger_win()
		return false

	if path_index >= path.size():
		current_state = State.IDLE
		return false

	return true


func get_death_cause() -> int:
	match current_state:
		State.DROWN:
			return 0
		State.BURN:
			return 1
		State.FALL:
			return 2
		State.ELECTROCUTE:
			return 3
		State.FREEZE:
			return 4
		_:
			return -1


func is_dead() -> bool:
	match current_state:
		State.DROWN, State.BURN, State.ELECTROCUTE, State.FREEZE, State.FALL:
			return true
		_:
			return false


func trigger_death(cause: State) -> void:
	match cause:
		State.DROWN, State.BURN, State.ELECTROCUTE, State.FREEZE, State.FALL:
			current_state = cause


func trigger_win() -> void:
	current_state = State.CHEER


func trigger_surprised() -> void:
	if current_state == State.IDLE:
		current_state = State.SURPRISED


func return_to_idle() -> void:
	if current_state == State.SURPRISED:
		current_state = State.IDLE


func _check_death(terrain: int) -> State:
	match terrain:
		WeatherType.Terrain.WATER:
			return State.DROWN
		WeatherType.Terrain.SCORCHED:
			return State.BURN
		WeatherType.Terrain.EMPTY, WeatherType.Terrain.STEAM:
			return State.FALL
		_:
			return State.IDLE


func _get_terrain(grid: Array, width: int, height: int, pos: Vector2i) -> int:
	if pos.x < 0 or pos.x >= width or pos.y < 0 or pos.y >= height:
		return WeatherType.Terrain.EMPTY
	return grid[pos.y * width + pos.x]
