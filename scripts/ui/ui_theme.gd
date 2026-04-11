class_name UITheme
extends RefCounted

## Single source for UI colors, fonts, and layout metrics per `docs/UI_SCREENS.md` and `docs/GAME_DESIGN.md` v2.
## Scenes under `scenes/ui/` should reference this class only — avoid literal hex in UI scripts.

# Godot 4.x: Color.from_string requires (hex_string, fallback_if_parse_fails).
const _COLOR_PARSE_FALLBACK: Color = Color.BLACK

# --- Color tokens (table in UI_SCREENS.md) ---

static var bg_deep: Color = Color.from_string("#0a1428", _COLOR_PARSE_FALLBACK)
static var bg_panel: Color = Color.from_string("#142844", _COLOR_PARSE_FALLBACK)
static var bg_panel_alt: Color = Color.from_string("#1f3a5c", _COLOR_PARSE_FALLBACK)
static var border_frame: Color = Color.from_string("#3a5f8a", _COLOR_PARSE_FALLBACK)
static var text_title: Color = Color.from_string("#f5e89c", _COLOR_PARSE_FALLBACK)
static var text_body: Color = Color.from_string("#e8eef7", _COLOR_PARSE_FALLBACK)
static var text_muted: Color = Color.from_string("#8a9bb4", _COLOR_PARSE_FALLBACK)
static var accent_primary: Color = Color.from_string("#4a90e2", _COLOR_PARSE_FALLBACK)
static var accent_success: Color = Color.from_string("#5fc97e", _COLOR_PARSE_FALLBACK)
static var accent_warning: Color = Color.from_string("#e8a73a", _COLOR_PARSE_FALLBACK)
static var accent_danger: Color = Color.from_string("#e8584a", _COLOR_PARSE_FALLBACK)
static var card_rain: Color = Color.from_string("#3aa8e8", _COLOR_PARSE_FALLBACK)
static var card_sun: Color = Color.from_string("#f0b340", _COLOR_PARSE_FALLBACK)
static var card_frost: Color = Color.from_string("#7ad8e8", _COLOR_PARSE_FALLBACK)
static var card_wind: Color = Color.from_string("#5fc97e", _COLOR_PARSE_FALLBACK)
static var card_lightning: Color = Color.from_string("#a06fe8", _COLOR_PARSE_FALLBACK)
static var card_fog: Color = Color.from_string("#8a9bb4", _COLOR_PARSE_FALLBACK)

# --- Font asset paths (`docs/ASSET_MANIFEST.md` §6) ---

const FONT_DISPLAY_PATH: String = "res://assets/fonts/whether_display.ttf"
const FONT_BODY_PATH: String = "res://assets/fonts/whether_body.ttf"
const FONT_NUMBERS_PATH: String = "res://assets/fonts/whether_numbers.ttf"

# --- Layout / sizing (UI_SCREENS.md layout fundamentals + grid tile scale) ---

const REFERENCE_WIDTH_PX: int = 1080
const REFERENCE_HEIGHT_PX: int = 1920
const SAFE_AREA_TOP_PX: int = 48
const SAFE_AREA_BOTTOM_PX: int = 64
const TOUCH_TARGET_MIN_PX: int = 144
const SIDE_MARGIN_PX: int = 48
const SECTION_GAP_PX: int = 32
const TILE_SOURCE_PX: int = 16
const TILE_RENDER_SCALE: int = 4
const TILE_RENDER_PX: int = TILE_SOURCE_PX * TILE_RENDER_SCALE


static func card_glow_color(weather_key: StringName) -> Color:
	match weather_key:
		&"rain":
			return card_rain
		&"sun":
			return card_sun
		&"frost":
			return card_frost
		&"wind":
			return card_wind
		&"lightning":
			return card_lightning
		&"fog":
			return card_fog
		_:
			return accent_primary


static func apply_display_font(label: Label) -> void:
	if ResourceLoader.exists(FONT_DISPLAY_PATH):
		var font: Font = load(FONT_DISPLAY_PATH) as Font
		label.add_theme_font_override(&"font", font)


static func apply_body_font(label: Label) -> void:
	if ResourceLoader.exists(FONT_BODY_PATH):
		var font: Font = load(FONT_BODY_PATH) as Font
		label.add_theme_font_override(&"font", font)


static func apply_numbers_font(label: Label) -> void:
	if ResourceLoader.exists(FONT_NUMBERS_PATH):
		var font: Font = load(FONT_NUMBERS_PATH) as Font
		label.add_theme_font_override(&"font", font)
		return
	if ResourceLoader.exists(FONT_DISPLAY_PATH):
		var fallback: Font = load(FONT_DISPLAY_PATH) as Font
		label.add_theme_font_override(&"font", fallback)


static func configure_title_label(label: Label) -> void:
	label.add_theme_color_override(&"font_color", text_title)
	apply_display_font(label)


static func configure_body_label(label: Label) -> void:
	label.add_theme_color_override(&"font_color", text_body)
	apply_body_font(label)


static func configure_muted_label(label: Label) -> void:
	label.add_theme_color_override(&"font_color", text_muted)
	apply_body_font(label)


static func configure_numbers_label(label: Label) -> void:
	label.add_theme_color_override(&"font_color", text_title)
	apply_numbers_font(label)


## Baseline Theme for Control nodes (optional root `theme` on UI screens).
static func apply_primary_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = accent_primary
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6
	normal.corner_radius_bottom_left = 6
	normal.content_margin_left = 24.0
	normal.content_margin_right = 24.0
	normal.content_margin_top = 16.0
	normal.content_margin_bottom = 16.0
	button.add_theme_stylebox_override(&"normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = accent_primary.lightened(0.06)
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_right = 6
	hover.corner_radius_bottom_left = 6
	hover.content_margin_left = 24.0
	hover.content_margin_right = 24.0
	hover.content_margin_top = 16.0
	hover.content_margin_bottom = 16.0
	button.add_theme_stylebox_override(&"hover", hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = accent_primary.darkened(0.08)
	pressed.corner_radius_top_left = 6
	pressed.corner_radius_top_right = 6
	pressed.corner_radius_bottom_right = 6
	pressed.corner_radius_bottom_left = 6
	pressed.content_margin_left = 24.0
	pressed.content_margin_right = 24.0
	pressed.content_margin_top = 16.0
	pressed.content_margin_bottom = 16.0
	button.add_theme_stylebox_override(&"pressed", pressed)
	button.add_theme_color_override(&"font_color", bg_deep)
	button.add_theme_color_override(&"font_hover_color", bg_deep)
	button.add_theme_color_override(&"font_pressed_color", bg_deep)


static func apply_success_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = accent_success
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6
	normal.corner_radius_bottom_left = 6
	normal.content_margin_left = 24.0
	normal.content_margin_right = 24.0
	normal.content_margin_top = 16.0
	normal.content_margin_bottom = 16.0
	button.add_theme_stylebox_override(&"normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = accent_success.lightened(0.06)
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_right = 6
	hover.corner_radius_bottom_left = 6
	hover.content_margin_left = 24.0
	hover.content_margin_right = 24.0
	hover.content_margin_top = 16.0
	hover.content_margin_bottom = 16.0
	button.add_theme_stylebox_override(&"hover", hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = accent_success.darkened(0.08)
	pressed.corner_radius_top_left = 6
	pressed.corner_radius_top_right = 6
	pressed.corner_radius_bottom_right = 6
	pressed.corner_radius_bottom_left = 6
	pressed.content_margin_left = 24.0
	pressed.content_margin_right = 24.0
	pressed.content_margin_top = 16.0
	pressed.content_margin_bottom = 16.0
	button.add_theme_stylebox_override(&"pressed", pressed)
	button.add_theme_color_override(&"font_color", bg_deep)
	button.add_theme_color_override(&"font_hover_color", bg_deep)
	button.add_theme_color_override(&"font_pressed_color", bg_deep)


static func apply_secondary_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_panel
	normal.border_color = border_frame
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6
	normal.corner_radius_bottom_left = 6
	normal.content_margin_left = 24.0
	normal.content_margin_right = 24.0
	normal.content_margin_top = 16.0
	normal.content_margin_bottom = 16.0
	button.add_theme_stylebox_override(&"normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = bg_panel.lightened(0.04)
	hover.border_color = border_frame
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_right = 6
	hover.corner_radius_bottom_left = 6
	hover.content_margin_left = 24.0
	hover.content_margin_right = 24.0
	hover.content_margin_top = 16.0
	hover.content_margin_bottom = 16.0
	button.add_theme_stylebox_override(&"hover", hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = bg_panel.darkened(0.06)
	pressed.border_color = border_frame
	pressed.border_width_left = 2
	pressed.border_width_top = 2
	pressed.border_width_right = 2
	pressed.border_width_bottom = 2
	pressed.corner_radius_top_left = 6
	pressed.corner_radius_top_right = 6
	pressed.corner_radius_bottom_right = 6
	pressed.corner_radius_bottom_left = 6
	pressed.content_margin_left = 24.0
	pressed.content_margin_right = 24.0
	pressed.content_margin_top = 16.0
	pressed.content_margin_bottom = 16.0
	button.add_theme_stylebox_override(&"pressed", pressed)
	button.add_theme_color_override(&"font_color", text_body)
	button.add_theme_color_override(&"font_hover_color", text_title)
	button.add_theme_color_override(&"font_pressed_color", text_title)


static func create_base_theme() -> Theme:
	var theme := Theme.new()
	theme.set_color(&"font_color", &"Label", text_body)
	theme.set_color(&"font_hover_color", &"Label", text_body)
	theme.set_color(&"font_pressed_color", &"Label", text_body)
	theme.set_color(&"font_color", &"Button", text_body)
	theme.set_color(&"font_hover_color", &"Button", text_title)
	theme.set_color(&"font_pressed_color", &"Button", text_title)
	theme.set_color(&"font_disabled_color", &"Button", text_muted)
	if ResourceLoader.exists(FONT_BODY_PATH):
		var body: Font = load(FONT_BODY_PATH) as Font
		theme.set_font(&"font", &"Label", body)
		theme.set_font(&"font", &"Button", body)
	return theme
