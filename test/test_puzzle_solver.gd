extends GutTest

func test_solver_stub_reports_solvable() -> void:
  var solver := PuzzleSolver.new()
  var result := solver.solve_stub()
  assert_true(result.is_solvable)
  assert_eq(result.min_moves, 0)
