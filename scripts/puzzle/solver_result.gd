## Result type returned by PuzzleSolver.solve().
## Holds solvability, optimal solution, and diagnostic metrics.
class_name SolverResult
extends RefCounted

var is_solvable: bool
var min_moves: int
var solution: Array  # Array of [card_type: int, pos: Vector2i] pairs
var states_explored: int
var elapsed_ms: float
var unique_solution: bool


func _init(
	p_solvable: bool,
	p_solution: Array = [],
	p_min_moves: int = 0,
	p_states_explored: int = 0,
	p_elapsed_ms: float = 0.0,
	p_unique_solution: bool = false
) -> void:
	is_solvable = p_solvable
	solution = p_solution
	min_moves = p_min_moves
	states_explored = p_states_explored
	elapsed_ms = p_elapsed_ms
	unique_solution = p_unique_solution


## Rough difficulty 1–10 based on min_moves + branching (states_explored).
func difficulty_score() -> int:
	if not is_solvable:
		return 0
	var move_factor: float = clampf(float(min_moves) / 8.0, 0.0, 1.0)
	var branch_factor: float = clampf(log(maxf(float(states_explored), 1.0)) / log(200000.0), 0.0, 1.0)
	var raw: float = (move_factor * 0.6 + branch_factor * 0.4) * 10.0
	if unique_solution:
		raw += 1.0
	return clampi(int(roundf(raw)), 1, 10)
