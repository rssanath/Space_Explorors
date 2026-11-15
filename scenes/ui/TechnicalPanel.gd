class_name TechnicalPanel
extends PanelContainer

## TechnicalPanel.gd - Dark Charcoal Glass Aerospace Telemetry & Specs Display
## Features grid aesthetics, system telemetry readouts, and status badges.

const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")

@export var system_name: String = "TELEMETRY BUS" : set = set_system_name
@export var system_code: String = "[TLM.01]" : set = set_system_code
@export var status_text: String = "ONLINE" : set = set_status_text
@export var status_mode: int = 0 : set = set_status_mode

@onready var lbl_system: Label = $Margin/VBox/Header/SystemName
@onready var lbl_code: Label = $Margin/VBox/Header/SystemCode
@onready var status_indicator: Node = $Margin/VBox/Header/StatusIndicator
@onready var data_grid: GridContainer = $Margin/VBox/DataGrid

var _data_rows: Dictionary = {}

func _ready() -> void:
	_apply_styling()
	_update_header()

func set_system_name(val: String) -> void:
	system_name = val
	if is_node_ready() and lbl_system:
		lbl_system.text = system_name

func set_system_code(val: String) -> void:
	system_code = val
	if is_node_ready() and lbl_code:
		lbl_code.text = system_code

func set_status_text(val: String) -> void:
	status_text = val
	if is_node_ready() and status_indicator:
		status_indicator.value_text = status_text

func set_status_mode(m: int) -> void:
	status_mode = m
	if is_node_ready() and status_indicator:
		status_indicator.status_mode = status_mode

func _apply_styling() -> void:
	var sb := MarsDeepUIRef.create_glass_card("secondary", 6)
	add_theme_stylebox_override("panel", sb)

func _update_header() -> void:
	if lbl_system:
		lbl_system.text = system_name
	if lbl_code:
		lbl_code.text = system_code
	if status_indicator:
		status_indicator.status_text = "STATUS:"
		status_indicator.value_text = status_text
		status_indicator.status_mode = status_mode

func set_data_field(key: String, label: String, val_str: String, val_col: Color = Color(0.95, 0.96, 0.96, 1.0)) -> void:
	if not data_grid:
		return
	if _data_rows.has(key):
		var row: Dictionary = _data_rows[key]
		row["label"].text = label
		row["value"].text = val_str
		row["value"].add_theme_color_override("font_color", val_col)
	else:
		var lbl_k := Label.new()
		lbl_k.text = label
		lbl_k.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_SECONDARY)
		lbl_k.add_theme_font_size_override("font_size", 11)
		
		var lbl_v := Label.new()
		lbl_v.text = val_str
		lbl_v.add_theme_color_override("font_color", val_col)
		lbl_v.add_theme_font_size_override("font_size", 11)
		
		data_grid.add_child(lbl_k)
		data_grid.add_child(lbl_v)
		_data_rows[key] = {"label": lbl_k, "value": lbl_v}
