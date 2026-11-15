class_name MarsDeepUI
extends RefCounted

## MarsDeepUI.gd - Global Aerospace Design System Helper & Theme Library
## MARS DEEP • NASA Space Apps Challenge 2026

# ==============================================================================
# GLOBAL COLOR PALETTE
# ==============================================================================
const COLOR_BG := Color("#080B0C")
const COLOR_PANEL := Color("#111719")
const COLOR_PANEL_SECONDARY := Color("#171F22")
const COLOR_PANEL_TRANSPARENT := Color(0.067, 0.090, 0.098, 0.92)

const COLOR_CYAN := Color("#00E5FF")
const COLOR_CYAN_DIM := Color(0.0, 0.898, 1.0, 0.35)
const COLOR_CYAN_GLOW := Color(0.0, 0.898, 1.0, 0.85)

const COLOR_ORANGE := Color("#FF7A00")
const COLOR_ORANGE_DIM := Color(1.0, 0.478, 0.0, 0.35)

const COLOR_GREEN := Color("#27D980")
const COLOR_YELLOW := Color("#FFC857")
const COLOR_RED := Color("#FF4545")

const COLOR_TEXT_PRIMARY := Color("#F2F5F5")
const COLOR_TEXT_SECONDARY := Color("#A1ADB1")
const COLOR_TEXT_MUTED := Color(0.45, 0.52, 0.55, 1.0)

const COLOR_BORDER_SUBTLE := Color(0.18, 0.25, 0.28, 0.65)
const COLOR_BORDER_CYAN := Color(0.0, 0.898, 1.0, 0.65)
const COLOR_BORDER_ORANGE := Color(1.0, 0.478, 0.0, 0.65)

# ==============================================================================
# STATUS ENUMS
# ==============================================================================
enum StatusMode {
	NOMINAL,
	WARNING,
	ALERT,
	ACTIVE,
	STANDBY,
	LOCKED
}

# ==============================================================================
# STYLEBOX FACTORIES
# ==============================================================================
static func create_panel_style(
	bg: Color = COLOR_PANEL,
	border: Color = COLOR_BORDER_SUBTLE,
	border_w: int = 1,
	corner_r: int = 6,
	pad: int = 12
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = border_w
	sb.border_width_top = border_w
	sb.border_width_right = border_w
	sb.border_width_bottom = border_w
	sb.corner_radius_top_left = corner_r
	sb.corner_radius_top_right = corner_r
	sb.corner_radius_bottom_right = corner_r
	sb.corner_radius_bottom_left = corner_r
	sb.content_margin_left = pad
	sb.content_margin_top = pad
	sb.content_margin_right = pad
	sb.content_margin_bottom = pad
	return sb

static func create_glass_card(accent: String = "subtle", corner_r: int = 6) -> StyleBoxFlat:
	var b_col := COLOR_BORDER_SUBTLE
	var bg_col := COLOR_PANEL_TRANSPARENT
	var border_w := 1
	
	match accent.to_lower():
		"cyan":
			b_col = COLOR_BORDER_CYAN
			border_w = 2
		"orange":
			b_col = COLOR_BORDER_ORANGE
			border_w = 2
		"green":
			b_col = Color(0.153, 0.851, 0.502, 0.75)
			border_w = 1
		"secondary":
			bg_col = Color(0.090, 0.122, 0.133, 0.95)
			b_col = COLOR_BORDER_SUBTLE
		_:
			b_col = COLOR_BORDER_SUBTLE
			
	return create_panel_style(bg_col, b_col, border_w, corner_r)

static func create_button_style(
	bg: Color = COLOR_PANEL_SECONDARY,
	border: Color = COLOR_BORDER_SUBTLE,
	border_w: int = 1,
	corner_r: int = 4
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = border_w
	sb.border_width_top = border_w
	sb.border_width_right = border_w
	sb.border_width_bottom = border_w
	sb.corner_radius_top_left = corner_r
	sb.corner_radius_top_right = corner_r
	sb.corner_radius_bottom_right = corner_r
	sb.corner_radius_bottom_left = corner_r
	sb.content_margin_left = 16
	sb.content_margin_top = 8
	sb.content_margin_right = 16
	sb.content_margin_bottom = 8
	return sb

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================
static func get_status_color(status: StatusMode) -> Color:
	match status:
		StatusMode.NOMINAL:
			return COLOR_GREEN
		StatusMode.WARNING:
			return COLOR_YELLOW
		StatusMode.ALERT:
			return COLOR_RED
		StatusMode.ACTIVE:
			return COLOR_CYAN
		StatusMode.STANDBY:
			return COLOR_TEXT_MUTED
		StatusMode.LOCKED:
			return Color(0.35, 0.38, 0.40, 1.0)
		_:
			return COLOR_TEXT_SECONDARY

static func get_status_text(status: StatusMode) -> String:
	match status:
		StatusMode.NOMINAL:
			return "NOMINAL"
		StatusMode.WARNING:
			return "WARNING"
		StatusMode.ALERT:
			return "CRITICAL"
		StatusMode.ACTIVE:
			return "ACTIVE"
		StatusMode.STANDBY:
			return "STANDBY"
		StatusMode.LOCKED:
			return "LOCKED"
		_:
			return "ONLINE"

static func format_telemetry(val: float, unit: String = "", decimals: int = 1) -> String:
	var fmt := "%.*f"
	var formatted := fmt % [decimals, val]
	if unit.is_empty():
		return formatted
	return "%s %s" % [formatted, unit]
