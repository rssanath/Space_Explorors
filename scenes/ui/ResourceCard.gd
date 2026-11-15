class_name ResourceCard
extends PanelContainer

## ResourceCard.gd - Aerospace Resource Readout & Telemetry Gauge Card
## Displays metric name, primary numeric value, unit, limit bar, and safety margin.

const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")

@export var metric_name: String = "TOTAL MASS" : set = set_metric_name
@export var metric_code: String = "[M_WET]" : set = set_metric_code
@export var current_val: float = 0.0 : set = set_current_val
@export var max_val: float = 1000.0 : set = set_max_val
@export var unit: String = "kg" : set = set_unit
@export var is_cost: bool = false : set = set_is_cost

@onready var lbl_name: Label = $Margin/VBox/Header/MetricName
@onready var lbl_code: Label = $Margin/VBox/Header/MetricCode
@onready var lbl_value: Label = $Margin/VBox/ReadoutHBox/Value
@onready var lbl_unit: Label = $Margin/VBox/ReadoutHBox/Unit
@onready var gauge_bar: ProgressBar = $Margin/VBox/GaugeBar
@onready var lbl_margin: Label = $Margin/VBox/Footer/MarginText
@onready var lbl_status: Label = $Margin/VBox/Footer/StatusTag

func _ready() -> void:
	_apply_styling()
	_update_card()

func set_metric_name(val: String) -> void:
	metric_name = val
	if is_node_ready() and lbl_name:
		lbl_name.text = metric_name

func set_metric_code(val: String) -> void:
	metric_code = val
	if is_node_ready() and lbl_code:
		lbl_code.text = metric_code

func set_current_val(val: float) -> void:
	current_val = val
	if is_node_ready():
		_update_card()

func set_max_val(val: float) -> void:
	max_val = max(0.001, val)
	if is_node_ready():
		_update_card()

func set_unit(val: String) -> void:
	unit = val
	if is_node_ready() and lbl_unit:
		lbl_unit.text = unit

func set_is_cost(c: bool) -> void:
	is_cost = c
	if is_node_ready():
		_update_card()

func update_resource(cur: float, mx: float, margin_str: String = "") -> void:
	current_val = cur
	max_val = max(0.001, mx)
	if not margin_str.is_empty() and lbl_margin:
		lbl_margin.text = margin_str
	_update_card()

func _apply_styling() -> void:
	var sb := MarsDeepUIRef.create_glass_card("subtle", 4)
	add_theme_stylebox_override("panel", sb)

func _update_card() -> void:
	if lbl_name:
		lbl_name.text = metric_name
	if lbl_code:
		lbl_code.text = metric_code
	if lbl_unit:
		lbl_unit.text = unit
		
	if lbl_value:
		if is_cost:
			lbl_value.text = "$%.1fM" % current_val
			if lbl_unit:
				lbl_unit.text = ""
		else:
			lbl_value.text = "%.1f" % current_val
			
	var ratio: float = current_val / max_val if max_val > 0 else 0.0
	if gauge_bar:
		gauge_bar.max_value = max_val
		gauge_bar.value = current_val
		
		# Gauge color based on load
		var bar_col := MarsDeepUIRef.COLOR_CYAN
		var stat_col := MarsDeepUIRef.COLOR_GREEN
		var stat_text := "NOMINAL"
		
		if ratio > 1.0:
			bar_col = MarsDeepUIRef.COLOR_RED
			stat_col = MarsDeepUIRef.COLOR_RED
			stat_text = "EXCEEDED"
		elif ratio > 0.85:
			bar_col = MarsDeepUIRef.COLOR_YELLOW
			stat_col = MarsDeepUIRef.COLOR_YELLOW
			stat_text = "MARGIN LOW"
			
		var fill_sb := StyleBoxFlat.new()
		fill_sb.bg_color = bar_col
		fill_sb.set_corner_radius_all(2)
		gauge_bar.add_theme_stylebox_override("fill", fill_sb)
		
		if lbl_status:
			lbl_status.text = stat_text
			lbl_status.add_theme_color_override("font_color", stat_col)
			
	if lbl_margin and lbl_margin.text.is_empty():
		var margin_rem: float = max_val - current_val
		if is_cost:
			lbl_margin.text = "Rem: $%.1fM" % margin_rem
		else:
			lbl_margin.text = "Rem: %.1f %s" % [margin_rem, unit]
