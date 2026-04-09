class_name AnimationDirector
extends Node

signal card_play_animation_finished()

@export var card_tween_seconds: float = 0.18
@export var board_feedback_seconds: float = 0.22

func play_card_and_board_feedback() -> void:
  await get_tree().create_timer(card_tween_seconds + board_feedback_seconds).timeout
  card_play_animation_finished.emit()
