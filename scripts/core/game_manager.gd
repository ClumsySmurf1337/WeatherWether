class_name GameManager
extends Node

enum GameState {
  BOOT,
  MAIN_MENU,
  PLAYING,
  PAUSED,
  LEVEL_COMPLETE
}

signal game_state_changed(new_state: GameState)

var current_state: GameState = GameState.BOOT

func set_state(next_state: GameState) -> void:
  if current_state == next_state:
    return
  current_state = next_state
  game_state_changed.emit(current_state)
