class_name AerospaceStatusIndicator
extends HBoxContainer

## StatusIndicator.gd - Aerospace Status LED & Telemetry Badge
## Visualizes status levels (NOMINAL, WARNING, ALERT, ACTIVE, STANDBY) with LED glows.

const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")

@export var status_text: String = "STATUS" : set = set_status_text
@export var value_text: String = "NOMINAL" : set = set_value_text
@export var status_mode: int = 0 : set = set_status_mode
@export var show_dot: bool = true : set = set_show_dot

@onready var dot_rect: ColorRect = $DotContainer/Dot
@onready var lbl_status: Label = $TextContainer/LblStatus
@onready var lbl_value: Label = $TextContainer/LblValue

func _ready() -> void:
	_update_visuals()

func set_status_text(val: String) -> void:
	status_text = val
	if is_node_ready() and lbl_status:
		lbl_status.text = status_text

func set_value_text(val: String) -> void:
	value_text = val
	if is_node_ready() and lbl_value:
		lbl_value.text = value_text

func set_status_mode(m: int) -> void:
	status_mode = m
	if is_node_ready():
		_update_visuals()

func set_show_dot(s: bool) -> void:
	show_dot = s
	if is_node_ready() and $DotContainer:
		$DotContainer.visible = show_dot

func set_status(text: String, value: String, mode: int = 0) -> void:
	status_text = text
	value_text = value
	status_mode = mode
	_update_visuals()

func _update_visuals() -> void:
	var col := MarsDeepUIRef.get_status_color(status_mode)
	if dot_rect:
		dot_rect.color = col
	if lbl_value:
		lbl_value.text = value_text
		lbl_value.add_theme_color_override("font_color", col)
	if lbl_status:
		lbl_status.text = status_text
