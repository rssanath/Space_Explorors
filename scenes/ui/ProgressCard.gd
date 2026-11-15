class_name ProgressCard
extends PanelContainer

## ProgressCard.gd - Aerospace Progress & Mission Milestone Card
## Displays metric name, completion percentage, styled progress bar, and status label.

const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")

@export var title: String = "MISSION PROGRESS" : set = set_title
@export var current_value: float = 0.0 : set = set_current_value
@export var max_value: float = 100.0 : set = set_max_value
@export var unit: String = "%" : set = set_unit
@export var detail_text: String = "Awaiting Subsystem Certification" : set = set_detail_text
@export var bar_color: Color = Color("#00E5FF") : set = set_bar_color

@onready var lbl_title: Label = $Margin/VBox/HeaderHBox/Title
@onready var lbl_value: Label = $Margin/VBox/HeaderHBox/Value
@onready var progress_bar: ProgressBar = $Margin/VBox/ProgressBar
@onready var lbl_detail: Label = $Margin/VBox/Detail

func _ready() -> void:
	_apply_styling()
	_update_display()

func set_title(val: String) -> void:
	title = val
	if is_node_ready() and lbl_title:
		lbl_title.text = title

func set_current_value(val: float) -> void:
	current_value = val
	if is_node_ready():
		_update_display()

func set_max_value(val: float) -> void:
	max_value = max(0.001, val)
	if is_node_ready():
		_update_display()

func set_unit(val: String) -> void:
	unit = val
	if is_node_ready():
		_update_display()

func set_detail_text(val: String) -> void:
	detail_text = val
	if is_node_ready() and lbl_detail:
		lbl_detail.text = detail_text

func set_bar_color(col: Color) -> void:
	bar_color = col
	if is_node_ready():
		_apply_bar_style()

func set_progress(curr: float, mx: float, detail: String = "") -> void:
	current_value = curr
	max_value = max(0.001, mx)
	if not detail.is_empty():
		detail_text = detail
	_update_display()

func _apply_styling() -> void:
	var sb := MarsDeepUIRef.create_glass_card("subtle", 4)
	add_theme_stylebox_override("panel", sb)
	_apply_bar_style()

func _apply_bar_style() -> void:
	if not progress_bar:
		return
	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = bar_color
	fill_sb.set_corner_radius_all(2)
	progress_bar.add_theme_stylebox_override("fill", fill_sb)

func _update_display() -> void:
	if lbl_title:
		lbl_title.text = title
	if progress_bar:
		progress_bar.max_value = max_value
		progress_bar.value = current_value
	if lbl_value:
		var pct: float = (current_value / max_value) * 100.0 if max_value > 0 else 0.0
		if unit == "%":
			lbl_value.text = "%.0f%%" % pct
		else:
			lbl_value.text = "%.1f / %.1f %s" % [current_value, max_value, unit]
	if lbl_detail:
		lbl_detail.text = detail_text
