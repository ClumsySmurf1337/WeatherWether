class_name PuzzleSolver
extends RefCounted

class SolverResult:
  var is_solvable: bool
  var min_moves: int
  var path: Array

  func _init(solvable: bool, moves: int, solution_path: Array) -> void:
    is_solvable = solvable
    min_moves = moves
    path = solution_path

func solve_stub() -> SolverResult:
  return SolverResult.new(true, 0, [])
