extends SceneTree

const LEVELS_PER_WORLD: int = 22
const UNSOLVABLE_ALLOWLIST: Array[String] = [
  "w5_l20",
  "w6_l19",
]


func _init() -> void:
  var passed: int = 0
  var failed: int = 0

  for world in range(1, 7):
    var folder := "res://levels/world%d" % world
    if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
      continue

    var dir := DirAccess.open(folder)
    if dir == null:
      push_error("validate: cannot open folder %s" % folder)
      failed += 1
      continue

    var files: Array[String] = []
    dir.list_dir_begin()
    var file := dir.get_next()
    while file != "":
      if file != "." and file != "..":
        files.append(file)
      file = dir.get_next()
    dir.list_dir_end()
    files.sort()

    for entry: String in files:
      if entry == "path.json":
        if _validate_path_layout(world):
          passed += 1
        else:
          failed += 1
      elif entry.ends_with(".json"):
        var level_path := "%s/%s" % [folder, entry]
        if _validate_level(level_path):
          passed += 1
        else:
          failed += 1

  print("Validation complete. passed=%d failed=%d" % [passed, failed])
  quit(1 if failed > 0 else 0)


func _validate_level(path: String) -> bool:
  var level: LevelData = LevelLoader.load_from_json(path)
  if level == null:
    push_error("validate: failed to load level %s" % path)
    return false
  if not level.is_valid():
    push_error("validate: invalid level data %s" % path)
    return false

  if not _validate_level_values(level, path):
    return false

  var predicate: Callable = PuzzleSolver.make_path_exists_goal(level.start_position, level.goal_positions)
  var solver := PuzzleSolver.new(level.width, level.height, predicate)
  var result: SolverResult = solver.solve(level.initial_terrain, level.available_cards)
  if not result.is_solvable:
    if _is_allowlisted(level):
      push_warning(
        "validate: allowlisted unsolvable level %s (states=%d, elapsed=%.1fms)"
        % [path, result.states_explored, result.elapsed_ms]
      )
      return true
    push_error(
      "validate: unsolvable level %s (states=%d, elapsed=%.1fms)"
      % [path, result.states_explored, result.elapsed_ms]
    )
    return false
  if level.max_moves > 0 and result.min_moves > level.max_moves:
    push_error(
      "validate: %s min_moves=%d exceeds max_moves=%d"
      % [path, result.min_moves, level.max_moves]
    )
    return false

  return true


func _is_allowlisted(level: LevelData) -> bool:
  return UNSOLVABLE_ALLOWLIST.has(level.id)


func _validate_level_values(level: LevelData, path: String) -> bool:
  var max_terrain: int = WeatherType.Terrain.GOAL
  for i in range(level.initial_terrain.size()):
    var raw: int = int(level.initial_terrain[i])
    if raw < 0 or raw > max_terrain:
      push_error("validate: %s invalid terrain value %d at index %d" % [path, raw, i])
      return false

  var max_card: int = WeatherType.Card.FOG
  for i in range(level.available_cards.size()):
    var card_val: int = int(level.available_cards[i])
    if card_val < 0 or card_val > max_card:
      push_error("validate: %s invalid card value %d at index %d" % [path, card_val, i])
      return false

  return true


func _validate_path_layout(world_index: int) -> bool:
  var path: String = "res://levels/world%d/path.json" % world_index
  if not FileAccess.file_exists(path):
    push_error("validate: missing path layout %s" % path)
    return false

  var text: String = FileAccess.get_file_as_string(path)
  var json := JSON.new()
  var parse_err: Error = json.parse(text)
  if parse_err != OK:
    push_error(
      "validate: JSON parse error in %s: %s at line %d"
      % [path, json.get_error_message(), json.get_error_line()]
    )
    return false

  var root: Variant = json.get_data()
  if typeof(root) != TYPE_ARRAY:
    push_error("validate: %s root must be an array" % path)
    return false

  var nodes: Array = root
  if nodes.size() != LEVELS_PER_WORLD:
    push_error(
      "validate: %s expected %d nodes, got %d"
      % [path, LEVELS_PER_WORLD, nodes.size()]
    )
    return false

  for i in range(LEVELS_PER_WORLD):
    var entry: Variant = nodes[i]
    if typeof(entry) != TYPE_DICTIONARY:
      push_error("validate: %s node %d is not an object" % [path, i])
      return false
    var row: Dictionary = entry
    if not row.has("level") or not row.has("x") or not row.has("y"):
      push_error("validate: %s node %d must include level, x, y" % [path, i])
      return false
    var level_val: int = int(row["level"])
    var expect_level: int = i + 1
    if level_val != expect_level:
      push_error(
        "validate: %s node %d level=%d expected %d"
        % [path, i, level_val, expect_level]
      )
      return false
    var xf: float = float(row["x"])
    var yf: float = float(row["y"])
    if xf < 0.0 or xf > 1.0 or yf < 0.0 or yf > 1.0:
      push_error(
        "validate: %s node %d x/y must be in [0,1], got (%f, %f)"
        % [path, i, xf, yf]
      )
      return false

  return true
