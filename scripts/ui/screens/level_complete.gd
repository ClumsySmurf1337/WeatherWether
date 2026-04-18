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
const STAR_REVEAL_SCALE_START: Vector2 = Vector2(0.6, 0.6)
const SPARKLE_AMOUNT: int = 14
const SPARKLE_LIFETIME_SEC: float = 0.6
const SPARKLE_VELOCITY_MIN: float = 40.0
const SPARKLE_VELOCITY_MAX: float = 90.0

var _sparkle_particles: Array[GPUParticles2D] = []
var _sparkle_texture: Texture2D = null


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
	UITheme.apply_success_button(_next_button)
	UITheme.apply_secondary_button(_replay_button)
	UITheme.apply_secondary_button(_world_map_button)
	_next_button.pressed.connect(_on_next_pressed)
	_replay_button.pressed.connect(_on_replay_pressed)
	_world_map_button.pressed.connect(_on_world_map_pressed)
	_star_timer.wait_time = STAR_REVEAL_DELAY_SEC
	_star_timer.one_shot = true
	_star_timer.timeout.connect(_reveal_next_star)
	_setup_star_sparkles()
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
	_reset_star_visual(_star_1)
	_reset_star_visual(_star_2)
	_reset_star_visual(_star_3)


func _reveal_next_star() -> void:
	_stars_revealed += 1
	var target: Label = _star_for_index(_stars_revealed)
	if target == null:
		return
	if _stars_revealed <= _stars_earned:
		target.text = STAR_FILLED
		target.add_theme_color_override(&"font_color", UITheme.text_title)
		_play_star_reveal(target)
		_emit_sparkle_for_index(_stars_revealed)
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


func _reset_star_visual(star: Label) -> void:
	star.scale = Vector2.ONE
	star.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _play_star_reveal(star: Label) -> void:
	star.pivot_offset = star.size * 0.5
	star.scale = STAR_REVEAL_SCALE_START
	star.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(star, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(star, "scale", Vector2.ONE, 0.18)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)


func _setup_star_sparkles() -> void:
	_sparkle_particles.clear()
	_sparkle_texture = _build_sparkle_texture()
	_attach_sparkle_to_star(_star_1)
	_attach_sparkle_to_star(_star_2)
	_attach_sparkle_to_star(_star_3)


func _attach_sparkle_to_star(star: Label) -> void:
	var particles := GPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = SPARKLE_AMOUNT
	particles.lifetime = SPARKLE_LIFETIME_SEC
	particles.explosiveness = 1.0
	particles.speed_scale = 1.0
	particles.texture = _sparkle_texture
	particles.process_material = _build_sparkle_material()
	star.add_child(particles)
	particles.position = star.size * 0.5
	star.resized.connect(_on_star_resized.bind(star, particles))
	_sparkle_particles.append(particles)


func _on_star_resized(star: Label, particles: GPUParticles2D) -> void:
	particles.position = star.size * 0.5


func _emit_sparkle_for_index(index: int) -> void:
	if index < 1 or index > _sparkle_particles.size():
		return
	var particles := _sparkle_particles[index - 1]
	if particles == null:
		return
	particles.restart()
	particles.emitting = true


func _build_sparkle_texture() -> Texture2D:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 1.0))
	return ImageTexture.create_from_image(image)


func _build_sparkle_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 160.0
	material.initial_velocity_min = SPARKLE_VELOCITY_MIN
	material.initial_velocity_max = SPARKLE_VELOCITY_MAX
	material.gravity = Vector3(0.0, 90.0, 0.0)
	material.scale_min = 0.5
	material.scale_max = 1.1
	material.angular_velocity_min = -6.0
	material.angular_velocity_max = 6.0
	material.color = UITheme.text_title
	return material


func _on_next_pressed() -> void:
	next_level_requested.emit()


func _on_replay_pressed() -> void:
	replay_requested.emit()


func _on_world_map_pressed() -> void:
	world_map_requested.emit()
