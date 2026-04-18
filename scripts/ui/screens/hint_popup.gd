class_name HintPopup
extends Control

## Screen 11 — Hint popup (`docs/UI_SCREENS.md`).
## Lightweight modal that shows the next suggested move or a fallback hint.

signal dismissed

@onready var _dimmer: ColorRect = $Dimmer
@onready var _title_label: Label = %HintTitle
@onready var _body_label: Label = %BodyLabel
@onready var _card_label: Label = %CardLabel
@onready var _arrow_label: Label = %ArrowLabel
@onready var _tile_label: Label = %TileLabel
@onready var _confirm_button: Button = %ConfirmButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_base_theme(self)
	var dim_color := UITheme.bg_deep
	dim_color.a = 0.7
	_dimmer.color = dim_color
	UITheme.configure_title_label(_title_label)
	_title_label.add_theme_color_override(&"font_color", UITheme.accent_warning)
	UITheme.configure_body_label(_body_label)
	UITheme.configure_title_label(_card_label)
	UITheme.configure_muted_label(_arrow_label)
	UITheme.configure_body_label(_tile_label)
	UITheme.apply_primary_button(_confirm_button)
	_confirm_button.pressed.connect(_on_confirm)


func configure(card_type: int, pos: Vector2i, hint_text: String = "") -> void:
	if hint_text.is_empty():
		_body_label.text = "Try this next:"
	else:
		_body_label.text = hint_text
	_card_label.visible = true
	_arrow_label.visible = true
	_tile_label.visible = true
	_card_label.text = WeatherType.card_name(card_type).to_upper()
	_arrow_label.text = "→"
	_tile_label.text = "tile (%d, %d)" % [pos.x + 1, pos.y + 1]


func configure_fallback(message: String) -> void:
	_body_label.text = message if not message.is_empty() else "No hint available yet."
	_card_label.visible = false
	_arrow_label.visible = false
	_tile_label.visible = false


func _on_confirm() -> void:
	dismissed.emit()
	UIManager.dismiss_modal()
