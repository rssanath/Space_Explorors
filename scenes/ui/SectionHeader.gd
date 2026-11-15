class_name SectionHeader
extends HBoxContainer

## SectionHeader.gd - Technical Aerospace Section Banner
## Displays system index code, section title, and cyan decorative divider.

@export var title: String = "SECTION TITLE" : set = set_title
@export var code: String = "[SYS.01]" : set = set_code
@export var accent_color: Color = Color("#00E5FF") : set = set_accent_color

@onready var accent_bar: ColorRect = $AccentBar
@onready var lbl_code: Label = $Code
@onready var lbl_title: Label = $Title
@onready var divider: HSeparator = $Divider

func _ready() -> void:
	_update_header()

func set_title(val: String) -> void:
	title = val
	if is_node_ready() and lbl_title:
		lbl_title.text = title

func set_code(val: String) -> void:
	code = val
	if is_node_ready() and lbl_code:
		lbl_code.text = code
		lbl_code.visible = not code.is_empty()

func set_accent_color(col: Color) -> void:
	accent_color = col
	if is_node_ready() and accent_bar:
		accent_bar.color = accent_color

func _update_header() -> void:
	if lbl_title:
		lbl_title.text = title
	if lbl_code:
		lbl_code.text = code
		lbl_code.visible = not code.is_empty()
	if accent_bar:
		accent_bar.color = accent_color
