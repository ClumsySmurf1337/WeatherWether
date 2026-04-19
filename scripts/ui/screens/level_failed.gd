class_name LevelFailedScreen
extends Control

## Screen 7 — Level Failed modal (`docs/UI_SCREENS.md`).
## Shown as an overlay when the character dies on a death tile.

signal try_again_requested
signal undo_last_requested
signal hint_requested

enum DeathCause { DROWN, BURN, FALL, ELECTROCUTE, FREEZE }

@onready var _dimmer: ColorRect = $Dimmer
@onready var _modal_panel: PanelContainer = $ModalCenter/ModalPanel
@onready var _title_label: Label = %FailTitle
@onready var _reason_label: Label = %ReasonLabel
@onready var _icon_label: Label = %DeathIcon
@onready var _try_again_button: Button = %TryAgainButton
@onready var _undo_button: Button = %UndoButton
@onready var _hint_button: Button = %HintButton

var _death_cause: DeathCause = DeathCause.DROWN


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_base_theme(self)
	var dim_color := UITheme.bg_deep
	dim_color.a = 0.7
	_dimmer.color = dim_color
	_apply_modal_panel_style(_modal_panel)
	UITheme.configure_title_label(_title_label)
	_title_label.add_theme_color_override(&"font_color", UITheme.accent_danger)
	UITheme.configure_body_label(_reason_label)
	UITheme.apply_primary_button(_try_again_button)
	UITheme.apply_secondary_button(_undo_button)
	UITheme.apply_secondary_button(_hint_button)
	_try_again_button.pressed.connect(_on_try_again)
	_undo_button.pressed.connect(_on_undo_last)
	_hint_button.pressed.connect(_on_hint)
	_apply_death_copy()


func configure(cause: DeathCause) -> void:
	_death_cause = cause
	if is_node_ready():
		_apply_death_copy()


func _apply_death_copy() -> void:
	match _death_cause:
		DeathCause.DROWN:
			_title_label.text = "OH NO."
			_reason_label.text = "Sky drowned in the river."
			_icon_label.text = "💧"
		DeathCause.BURN:
			_title_label.text = "OH NO."
			_reason_label.text = "The ground was too hot."
			_icon_label.text = "🔥"
		DeathCause.FALL:
			_title_label.text = "OH NO."
			_reason_label.text = "Sky fell into the gap."
			_icon_label.text = "🕳"
		DeathCause.ELECTROCUTE:
			_title_label.text = "OH NO."
			_reason_label.text = "Sky was electrocuted."
			_icon_label.text = "⚡"
		DeathCause.FREEZE:
			_title_label.text = "OH NO."
			_reason_label.text = "Sky froze solid."
			_icon_label.text = "❄"


func _apply_modal_panel_style(panel: PanelContainer) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = UITheme.bg_panel
	style.border_color = UITheme.accent_danger
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	panel.add_theme_stylebox_override(&"panel", style)


func _on_try_again() -> void:
	try_again_requested.emit()
	UIManager.dismiss_modal()
	UIManager.request_restart_level()


func _on_undo_last() -> void:
	undo_last_requested.emit()
	UIManager.dismiss_modal()
	UIManager.restore_planning_without_last()


func _on_hint() -> void:
	hint_requested.emit()
	UIManager.show_hint_popup()
