extends Control

## MissionBriefing.gd - Mission Briefing and Interactive Level 01 Engineering Tasks

@onready var lbl_level_title: Label = $MarginContainer/VBoxContainer/HeaderBar/TitleVBox/LblLevelTitle
@onready var lbl_level_subtitle: Label = $MarginContainer/VBoxContainer/HeaderBar/TitleVBox/LblLevelSubtitle
@onready var lbl_progress_badge: Label = $MarginContainer/VBoxContainer/HeaderBar/ProgressBadge
@onready var txt_description: Label = $MarginContainer/VBoxContainer/BriefingPanel/MarginContainer/VBoxContainer/TxtDescription

@onready var btn_back: Button = $MarginContainer/VBoxContainer/FooterBar/BtnBack
@onready var btn_proceed: Button = $MarginContainer/VBoxContainer/FooterBar/BtnProceed

# Task 1 Widgets
@onready var opt_task_1: OptionButton = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task1Panel/Margin/VBox/HBox/OptArchitecture
@onready var btn_submit_1: Button = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task1Panel/Margin/VBox/HBox/BtnSubmit1
@onready var lbl_status_1: Label = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task1Panel/Margin/VBox/LblStatus1

# Task 2 Widgets
@onready var input_task_2: LineEdit = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task2Panel/Margin/VBox/HBox/InputTask2
@onready var btn_submit_2: Button = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task2Panel/Margin/VBox/HBox/BtnSubmit2
@onready var lbl_status_2: Label = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task2Panel/Margin/VBox/LblStatus2

# Task 3 Widgets
@onready var input_task_3: LineEdit = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task3Panel/Margin/VBox/HBox/InputTask3
@onready var btn_submit_3: Button = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task3Panel/Margin/VBox/HBox/BtnSubmit3
@onready var lbl_status_3: Label = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task3Panel/Margin/VBox/LblStatus3

# Task 4 Widgets
@onready var input_task_4: LineEdit = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task4Panel/Margin/VBox/HBox/InputTask4
@onready var btn_submit_4: Button = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task4Panel/Margin/VBox/HBox/BtnSubmit4
@onready var lbl_status_4: Label = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task4Panel/Margin/VBox/LblStatus4

# Task 5 Widgets
@onready var input_task_5: LineEdit = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task5Panel/Margin/VBox/HBox/InputTask5
@onready var btn_submit_5: Button = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task5Panel/Margin/VBox/HBox/BtnSubmit5
@onready var lbl_status_5: Label = $MarginContainer/VBoxContainer/TasksScroll/TasksVBox/Task5Panel/Margin/VBox/LblStatus5

var current_level: Dictionary = {}

func _ready() -> void:
	print("[MissionBriefing] Initializing Mission Briefing Station...")
	current_level = GameManager.get_current_level()
	_populate_level_info()
	_setup_options()
	_connect_signals()
	_update_ui_states()

func _populate_level_info() -> void:
	if current_level.is_empty():
		return
	lbl_level_title.text = current_level.get("title", "LEVEL 01: Mission Architect")
	lbl_level_subtitle.text = current_level.get("subtitle", "Mission Profile & Trajectory Foundations")
	txt_description.text = current_level.get("description", "")

func _setup_options() -> void:
	opt_task_1.clear()
	opt_task_1.add_item("Surface Rover")
	opt_task_1.add_item("Stationary Lander")
	opt_task_1.add_item("Orbital Reconnaissance")
	opt_task_1.add_item("Sample Return Lander")

func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_proceed.pressed.connect(_on_proceed_pressed)
	
	btn_submit_1.pressed.connect(_on_submit_task_1)
	btn_submit_2.pressed.connect(_on_submit_task_2)
	btn_submit_3.pressed.connect(_on_submit_task_3)
	btn_submit_4.pressed.connect(_on_submit_task_4)
	btn_submit_5.pressed.connect(_on_submit_task_5)

func _on_back_pressed() -> void:
	GameManager.return_to_main_menu()

func _on_proceed_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MissionDesign.tscn")

func _on_submit_task_1() -> void:
	var selected_text: String = opt_task_1.get_item_text(opt_task_1.selected)
	var res := GameManager.submit_task_calculation("LVL_01", "TASK_01_01", selected_text)
	_display_feedback(lbl_status_1, res)
	_update_ui_states()

func _on_submit_task_2() -> void:
	var val_text: String = input_task_2.text.strip_edges()
	var res := GameManager.submit_task_calculation("LVL_01", "TASK_01_02", val_text)
	_display_feedback(lbl_status_2, res)
	_update_ui_states()

func _on_submit_task_3() -> void:
	var val_text: String = input_task_3.text.strip_edges()
	var res := GameManager.submit_task_calculation("LVL_01", "TASK_01_03", val_text)
	_display_feedback(lbl_status_3, res)
	_update_ui_states()

func _on_submit_task_4() -> void:
	var val_text: String = input_task_4.text.strip_edges()
	var res := GameManager.submit_task_calculation("LVL_01", "TASK_01_04", val_text)
	_display_feedback(lbl_status_4, res)
	_update_ui_states()

func _on_submit_task_5() -> void:
	var val_text: String = input_task_5.text.strip_edges()
	var res := GameManager.submit_task_calculation("LVL_01", "TASK_01_05", val_text)
	_display_feedback(lbl_status_5, res)
	_update_ui_states()

func _display_feedback(label: Label, res: Dictionary) -> void:
	var is_valid: bool = res.get("is_valid", false)
	var msg: String = res.get("message", "")
	label.text = msg
	if is_valid:
		label.modulate = Color(0.2, 1.0, 0.4, 1.0) # Green success
	else:
		label.modulate = Color(1.0, 0.35, 0.3, 1.0) # Red error

func _update_ui_states() -> void:
	var t1_done: bool = GameManager.is_task_completed("TASK_01_01")
	var t2_done: bool = GameManager.is_task_completed("TASK_01_02")
	var t3_done: bool = GameManager.is_task_completed("TASK_01_03")
	var t4_done: bool = GameManager.is_task_completed("TASK_01_04")
	var t5_done: bool = GameManager.is_task_completed("TASK_01_05")
	
	var completed_count: int = (1 if t1_done else 0) + (1 if t2_done else 0) + (1 if t3_done else 0) + (1 if t4_done else 0) + (1 if t5_done else 0)
	lbl_progress_badge.text = "MANDATORY TASKS: %d / 5 COMPLETED" % completed_count
	
	if completed_count == 5:
		lbl_progress_badge.modulate = Color(0.2, 1.0, 0.4, 1.0)
		btn_proceed.disabled = false
	else:
		lbl_progress_badge.modulate = Color(0, 0.9, 1.0, 1.0)
		btn_proceed.disabled = false # Accessible for exploration in Stage 1
