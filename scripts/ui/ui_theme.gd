class_name UITheme
extends RefCounted

## Single source for UI colors, fonts, and layout metrics per `docs/UI_SCREENS.md` and `docs/GAME_DESIGN.md` v2.
## Scenes under `scenes/ui/` should reference this class only — avoid literal hex in UI scripts.

# --- Color tokens (table in UI_SCREENS.md) ---

static var bg_deep: Color = Color.from_string("#0a1428")
static var bg_panel: Color = Color.from_string("#142844")
static var bg_panel_alt: Color = Color.from_string("#1f3a5c")
static var border_frame: Color = Color.from_string("#3a5f8a")
static var text_title: Color = Color.from_string("#f5e89c")
static var text_body: Color = Color.from_string("#e8eef7")
static var text_muted: Color = Color.from_string("#8a9bb4")
static var accent_primary: Color = Color.from_string("#4a90e2")
static var accent_success: Color = Color.from_string("#5fc97e")
static var accent_warning: Color = Color.from_string("#e8a73a")
static var accent_danger: Color = Color.from_string("#e8584a")
static var card_rain: Color = Color.from_string("#3aa8e8")
static var card_sun: Color = Color.from_string("#f0b340")
static var card_frost: Color = Color.from_string("#7ad8e8")
static var card_wind: Color = Color.from_string("#5fc97e")
static var card_lightning: Color = Color.from_string("#a06fe8")
static var card_fog: Color = Color.from_string("#8a9bb4")

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
