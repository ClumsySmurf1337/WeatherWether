## Immutable BFS state for the puzzle solver.
## Two states collide iff they share identical terrain AND identical sorted remaining cards.
class_name PuzzleState
extends RefCounted

var terrain: Array
var remaining_cards: Array[int]
var moves: Array  # Array of [card_type: int, pos: Vector2i] pairs applied so far


func _init(p_terrain: Array, p_remaining_cards: Array[int], p_moves: Array) -> void:
	terrain = p_terrain
	remaining_cards = p_remaining_cards
	moves = p_moves


func hash_key() -> String:
	var terrain_parts: PackedStringArray = PackedStringArray()
	for t: int in terrain:
		terrain_parts.append(str(t))
	var sorted_cards: Array[int] = remaining_cards.duplicate()
	sorted_cards.sort()
	var card_parts: PackedStringArray = PackedStringArray()
	for c: int in sorted_cards:
		card_parts.append(str(c))
	return "%s|%s" % [",".join(terrain_parts), ",".join(card_parts)]
