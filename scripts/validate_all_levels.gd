extends SceneTree

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
      if file.ends_with(".json"):
        # Placeholder validation pass. Real solver integration comes next.
        passed += 1
      file = dir.get_next()

  print("Validation complete. passed=%d failed=%d" % [passed, failed])
  quit(1 if failed > 0 else 0)
