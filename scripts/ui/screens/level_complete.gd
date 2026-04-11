class_name LevelCompleteScreen
extends Control

## Screen 6 — Level Complete (`docs/UI_SCREENS.md`).
## Shows star rating, stats, and next-level navigation after a win.

signal next_level_requested
signal replay_requested
signal world_map_requested

@onready var _title_label: Label = %TitleLabel
@onready var _tagline_label: Label = %TaglineLabel
@onready var _star_1: Label = %Star1
@onready var _star_2: Label = %Star2
@onready var _star_3: Label = %Star3
@onready var _hero_label: Label = $Margin/VBox/HeroPlaceholder/HeroLabel
@onready var _moves_label: Label = $Margin/VBox/StatPanel/StatRow/MovesCol/MovesLabel
@onready var _moves_value: Label = %MovesValue
@onready var _best_label: Label = $Margin/VBox/StatPanel/StatRow/BestCol/BestLabel
@onready var _best_value: Label = %BestValue
@onready var _par_label: Label = $Margin/VBox/StatPanel/StatRow/ParCol/ParLabel
@onready var _par_value: Label = %ParValue
@onready var _next_button: Button = %NextButton
@onready var _replay_button: Button = %ReplayButton
@onready var _world_map_button: Button = %WorldMapButton
@onready var _star_timer: Timer = $StarRevealTimer
@onready var _background: ColorRect = $Background

var _stars_earned: int = 0
var _stars_revealed: int = 0
var _moves_used: int = 0
var _best_moves: int = 0
var _par_moves: int = 0
var _is_last_in_world: bool = false

const STAR_REVEAL_DELAY_SEC: float = 0.2
const STAR_FILLED: String = "★"
const STAR_EMPTY: String = "☆"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_base_theme(self)
	_background.color = UITheme.bg_deep
	UITheme.configure_muted_label(_hero_label)
	UITheme.configure_title_label(_title_label)
	UITheme.configure_body_label(_tagline_label)
	UITheme.configure_muted_label(_moves_label)
	UITheme.configure_numbers_label(_moves_value)
	UITheme.configure_muted_label(_best_label)
	UITheme.configure_numbers_label(_best_value)
	UITheme.configure_muted_label(_par_label)
	UITheme.configure_numbers_label(_par_value)
	_par_value.add_theme_color_override(&"font_color", UITheme.accent_success)
	UITheme.apply_primary_button(_next_button)
	UITheme.apply_secondary_button(_replay_button)
	UITheme.apply_secondary_button(_world_map_button)
	_next_button.pressed.connect(_on_next_pressed)
	_replay_button.pressed.connect(_on_replay_pressed)
	_world_map_button.pressed.connect(_on_world_map_pressed)
	_star_timer.wait_time = STAR_REVEAL_DELAY_SEC
	_star_timer.one_shot = true
	_star_timer.timeout.connect(_reveal_next_star)
	_reset_stars()
	_apply_result()


func configure(stars: int, moves_used: int, best_moves: int, par_moves: int, is_last_in_world: bool) -> void:
	_stars_earned = clampi(stars, 0, 3)
	_moves_used = moves_used
	_best_moves = best_moves
	_par_moves = par_moves
	_is_last_in_world = is_last_in_world
	if is_node_ready():
		_apply_result()


func _apply_result() -> void:
	_moves_value.text = str(_moves_used)
	_best_value.text = str(_best_moves)
	_par_value.text = str(_par_moves)
	if _is_last_in_world:
		_next_button.text = "NEXT WORLD ▶"
	else:
		_next_button.text = "NEXT LEVEL ▶"
	_update_title_for_stars(_stars_earned)
	_stars_revealed = 0
	_reset_stars()
	_star_timer.start()


func _update_title_for_stars(stars: int) -> void:
	match stars:
		3:
			_title_label.text = "BRILLIANT."
			_tagline_label.text = "You found the perfect path."
		2:
			_title_label.text = "NICE."
			_tagline_label.text = "Not bad at all."
		_:
			_title_label.text = "DONE."
			_tagline_label.text = "You made it through."


func _reset_stars() -> void:
	_star_1.text = STAR_EMPTY
	_star_2.text = STAR_EMPTY
	_star_3.text = STAR_EMPTY
	_star_1.add_theme_color_override(&"font_color", UITheme.text_muted)
	_star_2.add_theme_color_override(&"font_color", UITheme.text_muted)
	_star_3.add_theme_color_override(&"font_color", UITheme.text_muted)


func _reveal_next_star() -> void:
	_stars_revealed += 1
	var target: Label = _star_for_index(_stars_revealed)
	if target == null:
		return
	if _stars_revealed <= _stars_earned:
		target.text = STAR_FILLED
		target.add_theme_color_override(&"font_color", UITheme.text_title)
	if _stars_revealed < 3:
		_star_timer.start()


func _star_for_index(index: int) -> Label:
	match index:
		1:
			return _star_1
		2:
			return _star_2
		3:
			return _star_3
		_:
			return null


func _on_next_pressed() -> void:
	next_level_requested.emit()


func _on_replay_pressed() -> void:
	replay_requested.emit()


func _on_world_map_pressed() -> void:
	world_map_requested.emit()
