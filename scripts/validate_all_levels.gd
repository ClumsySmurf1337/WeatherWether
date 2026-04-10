extends SceneTree

const LEVELS_PER_WORLD: int = 22


func _init() -> void:
  var passed: int = 0
  var failed: int = 0

  for world in range(1, 7):
    var folder := "res://levels/world%d" % world
    if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
      continue

    var dir := DirAccess.open(folder)
    if dir == null:
      continue

    dir.list_dir_begin()
    var file := dir.get_next()
    while file != "":
      if file == "." or file == "..":
        file = dir.get_next()
        continue
      if file == "path.json":
        if _validate_path_layout(world):
          passed += 1
        else:
          failed += 1
      elif file.ends_with(".json"):
        # Placeholder validation pass. Real solver integration comes next.
        passed += 1
      file = dir.get_next()

  print("Validation complete. passed=%d failed=%d" % [passed, failed])
  quit(1 if failed > 0 else 0)


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
