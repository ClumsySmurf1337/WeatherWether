## Global signal bus — decouples gameplay systems from UI and each other.
## Registered as autoload in project.godot.
##
## Signals:
## - level_started(level_id: String)
## - level_completed(level_id: String, stars: int, moves_used: int)
## - level_failed(level_id: String, cause: int)
## - card_queued(card_type: int, pos: Vector2i)
## - card_unqueued(index: int)
## - queue_cleared
## - sequence_started
## - sequence_card_resolved(card_type: int, pos: Vector2i)
## - sequence_finished
## - walk_started
## - walk_step(pos: Vector2i)
## - character_died(cause: int)
## - character_won
## - no_path_forward
## - settings_changed(key: String, value: Variant)
extends Node

signal level_started(level_id: String)
signal level_completed(level_id: String, stars: int, moves_used: int)
signal level_failed(level_id: String, cause: int)

signal card_queued(card_type: int, pos: Vector2i)
signal card_unqueued(index: int)
signal queue_cleared

signal sequence_started
signal sequence_card_resolved(card_type: int, pos: Vector2i)
signal sequence_finished

signal walk_started
signal walk_step(pos: Vector2i)
signal character_died(cause: int)
signal character_won

signal no_path_forward

signal settings_changed(key: String, value: Variant)
