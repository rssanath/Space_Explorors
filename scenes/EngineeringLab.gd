extends Control

## EngineeringLab.gd - Beginner-Friendly & Advanced Engineering Laboratory
## MARS DEEP • NASA Space Apps Challenge 2026 • Design. Launch. Explore.

const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")
const GameManagerRef = preload("res://scripts/GameManager.gd")

var _gm_cache: Node = null
func _get_gm() -> Node:
	if _gm_cache:
		return _gm_cache
	if Engine.has_singleton("GameManager"):
		_gm_cache = Engine.get_singleton("GameManager")
	elif is_inside_tree() and get_tree().root.has_node("GameManager"):
		_gm_cache = get_tree().root.get_node("GameManager")
	return _gm_cache

# Top Navigation
@onready var btn_designer: Button = $MarginContainer/VBoxContainer/Header/TopNav/BtnDesigner
@onready var btn_briefing: Button = $MarginContainer/VBoxContainer/Header/TopNav/BtnBriefing
@onready var btn_launch_prep: Button = $MarginContainer/VBoxContainer/Header/TopNav/BtnLaunchPrep

# Mode Switcher
@onready var btn_mode_beginner: Button = $MarginContainer/VBoxContainer/Header/ModeHBox/BtnBeginner
@onready var btn_mode_advanced: Button = $MarginContainer/VBoxContainer/Header/ModeHBox/BtnAdvanced

# Header Status Badges
@onready var lbl_header_title: Label = $MarginContainer/VBoxContainer/Header/TitleVBox/Title
@onready var lbl_header_subtitle: Label = $MarginContainer/VBoxContainer/Header/TitleVBox/Subtitle
@onready var lbl_cert_status: Label = $MarginContainer/VBoxContainer/Header/CertBadge

# Left Panel Navigation
@onready var module_buttons_vbox: VBoxContainer = $MarginContainer/VBoxContainer/MainBody/LeftPanel/VBox/ModuleScroll/ModuleButtonsVBox
@onready var tasks_list_vbox: VBoxContainer = $MarginContainer/VBoxContainer/MainBody/LeftPanel/VBox/TaskScroll/TasksListVBox
@onready var left_panel_title: Label = $MarginContainer/VBoxContainer/MainBody/LeftPanel/VBox/PanelHeader

# Center Panel Workspace
@onready var lbl_task_title: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/HeaderCard/Margin/VBox/LblTaskTitle
@onready var lbl_task_module: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/HeaderCard/Margin/VBox/LblTaskModule
@onready var txt_problem_statement: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/ProblemCard/Margin/VBox/TxtProblem
@onready var given_data_vbox: VBoxContainer = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/GivenDataCard/Margin/VBox/DataListVBox
@onready var lbl_formula_eq: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/FormulaCard/Margin/VBox/LblFormulaEq
@onready var lbl_formula_vars: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/FormulaCard/Margin/VBox/LblFormulaVars

# Input & Submission
@onready var input_answer: LineEdit = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/WorkspaceCard/Margin/VBox/HBoxInput/InputAnswer
@onready var lbl_unit: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/WorkspaceCard/Margin/VBox/HBoxInput/LblUnit
@onready var btn_submit_calc: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/WorkspaceCard/Margin/VBox/HBoxInput/BtnSubmitCalc

# Validation Feedback
@onready var feedback_card: PanelContainer = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/FeedbackCard
@onready var lbl_feedback_status: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/FeedbackCard/Margin/VBox/LblFeedbackStatus
@onready var txt_feedback_explanation: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/FeedbackCard/Margin/VBox/TxtFeedbackExplanation

# Mission AI Assistant
@onready var btn_ai_explain: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/AICard/Margin/VBox/AIButtons/BtnExplain
@onready var btn_ai_hint: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/AICard/Margin/VBox/AIButtons/BtnHint
@onready var btn_ai_teach: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/AICard/Margin/VBox/AIButtons/BtnTeach
@onready var ai_response_panel: PanelContainer = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/AICard/Margin/VBox/AIResponsePanel
@onready var txt_ai_response: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/Scroll/VBox/AICard/Margin/VBox/AIResponsePanel/Margin/TxtAI

# Right Panel Calculator & Telemetry
@onready var btn_toggle_calc: Button = $MarginContainer/VBoxContainer/MainBody/RightPanel/VBox/CalculatorCard/Margin/VBox/HeaderHBox/BtnToggleCalc
@onready var calc_display: LineEdit = $MarginContainer/VBoxContainer/MainBody/RightPanel/VBox/CalculatorCard/Margin/VBox/CalcDisplay
@onready var calc_keypad_grid: GridContainer = $MarginContainer/VBoxContainer/MainBody/RightPanel/VBox/CalculatorCard/Margin/VBox/KeypadGrid
@onready var btn_calc_copy: Button = $MarginContainer/VBoxContainer/MainBody/RightPanel/VBox/CalculatorCard/Margin/VBox/BtnCopyCalc
@onready var lbl_hardware_ref: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/VBox/HardwareCard/Margin/VBox/LblHardwareRef
@onready var lbl_progress_count: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/VBox/ProgressCard/Margin/VBox/LblProgressCount
@onready var bar_overall_progress: ProgressBar = $MarginContainer/VBoxContainer/MainBody/RightPanel/VBox/ProgressCard/Margin/VBox/BarProgress
@onready var lbl_level_unlock_status: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/VBox/ProgressCard/Margin/VBox/LblLevelStatus

# Footer
@onready var btn_bottom_designer: Button = $MarginContainer/VBoxContainer/Footer/BtnBottomDesigner
@onready var btn_prev_task: Button = $MarginContainer/VBoxContainer/Footer/BtnPrevTask
@onready var btn_next_task: Button = $MarginContainer/VBoxContainer/Footer/BtnNextTask
@onready var lbl_current_task_index: Label = $MarginContainer/VBoxContainer/Footer/LblCurrentTaskIndex
@onready var btn_bottom_continue: Button = $MarginContainer/VBoxContainer/Footer/BtnBottomContinue

# Mode and State Management
var is_advanced_mode: bool = false
var current_beginner_index: int = 0
var current_advanced_index: int = 0
var current_module_id: int = 1
var all_advanced_tasks: Array[Dictionary] = []

# ==============================================================================
# FOUR MANDATORY BEGINNER-FRIENDLY CALCULATION CHALLENGES
# ==============================================================================
const BEGINNER_CHALLENGES: Array[Dictionary] = [
	{
		"id": "CHALLENGE_01_WEIGHT",
		"linked_task_id": "TASK_02_01",
		"linked_level_id": "LVL_02",
		"concept": "ADDITION (+)",
		"title": "1. SPACECRAFT WEIGHT BUDGET",
		"icon": "⚖️",
		"problem": "Calculate the total weight of your spacecraft by adding together the weights of all individual components.",
		"given_values": [
			"Structure Bus Chassis: 320.0 kg",
			"Flight Computer & Avionics: 85.0 kg",
			"Electrical Power Subsystem: 145.0 kg",
			"Thermal Control & Radiators: 60.0 kg",
			"Deep Space Communications: 40.0 kg",
			"Scientific Instrument Payload: 150.0 kg"
		],
		"formula_plain": "Total Weight = Structure + Avionics + Power + Thermal + Comms + Payload",
		"formula_math": "Total Weight = 320 + 85 + 145 + 60 + 40 + 150",
		"unit": "kg",
		"target_value": 800.0,
		"tolerance": 0.02,
		"explanation_after": "Great job! By summing all 6 component weights (320 + 85 + 145 + 60 + 40 + 150 = 800 kg), you calculated the exact dry weight required for launch vehicle sizing.",
		"ai_explain": "Think of building a spacecraft like packing an expedition backpack. Every tool, computer, and structure adds weight. To know how heavy the rocket payload is, you simply add all component weights together.",
		"ai_hint": "Add the 6 component weights listed above: 320 + 85 + 145 + 60 + 40 + 150. You can type this directly into the calculator on the right!",
		"ai_teach": "Formula: Total = Item 1 + Item 2 + ... + Item N.\nWorked Example: If a small exploration rover has a Body (50 kg), Wheels (30 kg), and a Camera (10 kg), its Total Weight is 50 + 30 + 10 = 90 kg."
	},
	{
		"id": "CHALLENGE_02_POWER",
		"linked_task_id": "TASK_02_02",
		"linked_level_id": "LVL_02",
		"concept": "SUBTRACTION (-)",
		"title": "2. ELECTRICITY BALANCE",
		"icon": "⚡",
		"problem": "Calculate the remaining surplus electricity available after all spacecraft electronics, computers, and science instruments have drawn their power.",
		"given_values": [
			"Generated Solar Electricity: 420.0 W (from UltraFlex Solar Wings in daylight)",
			"Total Consumed Electricity: 175.4 W (continuous power draw by all instruments and avionics)"
		],
		"formula_plain": "Remaining Electricity = Generated Electricity - Consumed Electricity",
		"formula_math": "Remaining Electricity = 420.0 - 175.4",
		"unit": "W",
		"target_value": 244.6,
		"tolerance": 0.03,
		"explanation_after": "Excellent power calculation! With 420.0 W generated and 175.4 W consumed, you have +244.6 W of surplus clean electricity to recharge onboard lithium-ion batteries.",
		"ai_explain": "Solar wings produce electricity from sunlight, while instruments and computers consume electricity to run. If electricity consumption exceeds generation, the spacecraft suffers a net electrical deficit: onboard lithium-ion batteries rapidly discharge to sustain vital flight avionics, and non-essential science instruments are shut down into safe mode to prevent total mission blackout.",
		"ai_hint": "Take the total electricity generated (420.0 W) and subtract the electricity consumed (175.4 W). The formula is: 420.0 - 175.4.",
		"ai_teach": "Formula: Remaining = Generated - Consumed.\nWorked Example: If a home solar panel makes 500 Watts of power and your refrigerator uses 150 Watts, the remaining electricity is 500 - 150 = 350 Watts."
	},
	{
		"id": "CHALLENGE_03_BUDGET",
		"linked_task_id": "TASK_03_04",
		"linked_level_id": "LVL_03",
		"concept": "ADDITION & SUBTRACTION (+ & -)",
		"title": "3. MISSION BUDGET RESERVE",
		"icon": "💰",
		"problem": "Calculate your total mission expenditure (Spacecraft Subsystems + Instruments + Launch Vehicle), then subtract it from the $450.0M NASA budget cap to determine your remaining reserve contingency funds.",
		"given_values": [
			"Maximum NASA Exploration Budget: $450.0M",
			"Spacecraft Bus & Subsystems Cost: $103.0M",
			"Scientific Instruments Payload Cost: $48.0M",
			"Launch Vehicle Procurement Cost: $20.0M",
			"(Total Mission Spending: $103.0M + $48.0M + $20.0M = $171.0M)"
		],
		"formula_plain": "Remaining Budget = Total Budget - Total Spending",
		"formula_math": "Remaining Budget = 450.0 - 171.0",
		"unit": "Million $",
		"target_value": 279.0,
		"tolerance": 0.02,
		"explanation_after": "Outstanding financial management! Spending $171.0M out of your $450.0M grant leaves $279.0M in contingency reserves for launch operations and mission navigation.",
		"ai_explain": "Every space mission has a strict financial budget. You first add up the cost of all parts to find your total spending, then subtract that total from your grant to ensure you haven't run out of money.",
		"ai_hint": "Subtract the total spending ($171.0M) from the maximum budget ($450.0M): 450.0 - 171.0.",
		"ai_teach": "Formula: Remaining = Budget - (Cost 1 + Cost 2 + ...)\nWorked Example: If you have a $100 allowance and buy a backpack for $40 and a water bottle for $25 (total spent: $65), your remaining allowance is 100 - 65 = $35."
	},
	{
		"id": "CHALLENGE_04_DATA",
		"linked_task_id": "TASK_01_03",
		"linked_level_id": "LVL_01",
		"concept": "DIVISION (÷)",
		"title": "4. DATA TRANSMISSION TIME",
		"icon": "📡",
		"problem": "Calculate how many seconds it will take to transmit a high-resolution 360° Martian panorama back to the NASA Deep Space Network.",
		"given_values": [
			"Total Image File Size: 240.0 Megabytes (MB)",
			"High-Gain Antenna Downlink Speed: 2.0 Megabytes per second (MB/s)",
			"(Illustrative mission downlink values based on High-Gain X-band antenna)"
		],
		"formula_plain": "Transmission Time = Total Data / Transmission Speed",
		"formula_math": "Transmission Time = 240.0 / 2.0",
		"unit": "seconds",
		"target_value": 120.0,
		"tolerance": 0.03,
		"explanation_after": "Spot-on telemetry transmission calculation! Dividing 240 MB by 2 MB/s yields exactly 120 seconds (2.0 minutes) of continuous radio downlink time.",
		"ai_explain": "Science data travels across interplanetary space through radio signals. By dividing the total file size by how many megabytes the dish sends each second, you find how long the transmitter must stay active.",
		"ai_hint": "Divide the total data (240 Megabytes) by the downlink speed (2 Megabytes/sec): 240.0 / 2.0.",
		"ai_teach": "Formula: Time = Total Data / Transmission Speed.\nWorked Example: If you are downloading an 80 Megabyte app on your phone at 10 Megabytes per second, the download time is 80 / 10 = 8 seconds."
	}
]

# 7 Advanced Modules Definition (Retaining all 23 Tasks)
const ADVANCED_MODULES: Array[Dictionary] = [
	{
		"id": 1,
		"name": "MODULE 1: MASS BUDGET",
		"short_name": "Mass Budget",
		"icon": "⚖️",
		"task_ids": ["TASK_01_05", "TASK_02_01", "TASK_03_03", "TASK_03_04"]
	},
	{
		"id": 2,
		"name": "MODULE 2: ELECTRICAL POWER",
		"short_name": "Electrical Power",
		"icon": "⚡",
		"task_ids": ["TASK_01_04", "TASK_02_02"]
	},
	{
		"id": 3,
		"name": "MODULE 3: BATTERY SIZING",
		"short_name": "Battery Sizing",
		"icon": "🔋",
		"task_ids": ["TASK_02_03", "TASK_05_04"]
	},
	{
		"id": 4,
		"name": "MODULE 4: PROPULSION & DELTA-V",
		"short_name": "Propulsion & Δv",
		"icon": "🚀",
		"task_ids": ["TASK_02_04", "TASK_04_02", "TASK_05_03"]
	},
	{
		"id": 5,
		"name": "MODULE 5: ORBITAL MECHANICS",
		"short_name": "Orbital Mechanics",
		"icon": "🪐",
		"task_ids": ["TASK_01_02", "TASK_03_01", "TASK_03_02", "TASK_04_01"]
	},
	{
		"id": 6,
		"name": "MODULE 6: DATA & COMMUNICATIONS",
		"short_name": "Data & Comms",
		"icon": "📡",
		"task_ids": ["TASK_01_01", "TASK_01_03", "TASK_04_03", "TASK_05_05"]
	},
	{
		"id": 7,
		"name": "MODULE 7: THERMAL & MISSION LIFETIME",
		"short_name": "Thermal & Lifetime",
		"icon": "🛡️",
		"task_ids": ["TASK_02_05", "TASK_04_04", "TASK_05_01", "TASK_05_02"]
	}
]

func _ready() -> void:
	print("[EngineeringLab] Initializing Beginner-Friendly & Advanced Engineering Systems...")
	_collect_all_advanced_tasks()
	_setup_top_nav()
	_setup_footer_nav()
	_setup_calculator()
	_setup_ai_assistant()
	_setup_events()
	
	_set_mode(false) # Default to Beginner Mode
	_update_progress_readouts()
	_update_hardware_reference()

func _collect_all_advanced_tasks() -> void:
	all_advanced_tasks.clear()
	var gm = _get_gm()
	if not gm or not gm.campaign_data.has("levels"):
		return
	var levels: Array = gm.campaign_data["levels"]
	for lvl in levels:
		var tasks: Array = lvl.get("tasks", [])
		for t in tasks:
			var t_copy: Dictionary = t.duplicate(true)
			t_copy["level_id"] = lvl.get("id", "")
			t_copy["level_title"] = lvl.get("title", "")
			all_advanced_tasks.append(t_copy)

func _setup_events() -> void:
	if btn_mode_beginner:
		btn_mode_beginner.pressed.connect(func(): _set_mode(false))
	if btn_mode_advanced:
		btn_mode_advanced.pressed.connect(func(): _set_mode(true))
	if btn_submit_calc:
		btn_submit_calc.pressed.connect(_on_submit_calculation_pressed)
	if input_answer:
		input_answer.text_submitted.connect(func(_t): _on_submit_calculation_pressed())
	if btn_calc_copy:
		btn_calc_copy.pressed.connect(_on_copy_calc_pressed)
		
	var gm = _get_gm()
	if gm:
		gm.campaign_progress_updated.connect(_on_campaign_progress_updated)
		gm.spacecraft_config_changed.connect(_update_hardware_reference)

func _setup_top_nav() -> void:
	if btn_designer:
		btn_designer.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MissionDesign.tscn"))
	if btn_briefing:
		btn_briefing.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MissionBriefing.tscn"))
	if btn_launch_prep:
		btn_launch_prep.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LaunchPreparation.tscn"))

func _setup_footer_nav() -> void:
	if btn_prev_task:
		btn_prev_task.pressed.connect(_on_prev_pressed)
	if btn_next_task:
		btn_next_task.pressed.connect(_on_next_pressed)
	if btn_bottom_designer:
		btn_bottom_designer.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MissionDesign.tscn"))
	if btn_bottom_continue:
		btn_bottom_continue.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LaunchPreparation.tscn"))

func _on_mode_toggled(mode_idx: int) -> void:
	_set_mode(mode_idx == 1)

func _set_mode(advanced: bool) -> void:
	is_advanced_mode = advanced
	
	if btn_mode_beginner:
		btn_mode_beginner.modulate = Color(0.3, 1.0, 0.5, 1.0) if not is_advanced_mode else Color(0.7, 0.75, 0.8, 1.0)
	if btn_mode_advanced:
		btn_mode_advanced.modulate = Color(0, 0.9, 1.0, 1.0) if is_advanced_mode else Color(0.7, 0.75, 0.8, 1.0)
		
	if module_buttons_vbox:
		module_buttons_vbox.visible = is_advanced_mode
	if left_panel_title:
		left_panel_title.text = "ADVANCED MODULES" if is_advanced_mode else "FOUR ESSENTIAL CHALLENGES"
		
	if is_advanced_mode:
		_setup_advanced_module_buttons()
		_on_advanced_module_selected(current_module_id)
	else:
		_populate_beginner_challenges_list()
		_select_beginner_challenge(current_beginner_index)
		
	if ai_response_panel:
		ai_response_panel.visible = false

# ==============================================================================
# BEGINNER MODE DISPLAY & WORKFLOW
# ==============================================================================
func _populate_beginner_challenges_list() -> void:
	if not tasks_list_vbox:
		return
	for child in tasks_list_vbox.get_children():
		child.queue_free()
		
	var gm = _get_gm()
	for i in range(BEGINNER_CHALLENGES.size()):
		var ch: Dictionary = BEGINNER_CHALLENGES[i]
		var ch_id: String = ch.get("id", "")
		var l_tid: String = ch.get("linked_task_id", "")
		var is_done: bool = false
		if gm:
			is_done = gm.is_task_completed(l_tid) or gm.is_task_completed(ch_id)
		
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 36)
		btn.text = "%s %s" % ["✓" if is_done else "○", ch.get("title", "")]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 11)
		
		if is_done:
			btn.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_GREEN)
		else:
			btn.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_PRIMARY)
			
		btn.pressed.connect(_select_beginner_challenge.bind(i))
		tasks_list_vbox.add_child(btn)

func _select_beginner_challenge(idx: int) -> void:
	if idx < 0 or idx >= BEGINNER_CHALLENGES.size():
		return
	current_beginner_index = idx
	_display_beginner_challenge(current_beginner_index)

func _display_beginner_challenge(idx: int) -> void:
	var ch: Dictionary = BEGINNER_CHALLENGES[idx]
	var ch_id: String = ch.get("id", "")
	var l_tid: String = ch.get("linked_task_id", "")
	var gm = _get_gm()
	var is_completed: bool = false
	if gm:
		is_completed = gm.is_task_completed(l_tid) or gm.is_task_completed(ch_id)
	
	if lbl_task_title:
		lbl_task_title.text = "%s  [ %s ]" % [ch.get("title", ""), ch.get("concept", "")]
	if lbl_task_module:
		lbl_task_module.text = "BEGINNER CHALLENGE %d OF 4 • TEACHING CORE PRINCIPLES" % [idx + 1]
	if txt_problem_statement:
		txt_problem_statement.text = ch.get("problem", "")
	if lbl_unit:
		lbl_unit.text = ch.get("unit", "")
	if lbl_current_task_index:
		lbl_current_task_index.text = "CHALLENGE %d / 4" % [idx + 1]
		
	# Given Values List
	if given_data_vbox:
		for child in given_data_vbox.get_children():
			child.queue_free()
		var g_vals: Array = ch.get("given_values", [])
		for val_str in g_vals:
			var lbl := Label.new()
			lbl.text = "• " + str(val_str)
			lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_PRIMARY)
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			given_data_vbox.add_child(lbl)
			
	# Formula Card
	if lbl_formula_eq:
		lbl_formula_eq.text = "FORMULA:  %s" % ch.get("formula_plain", "")
	if lbl_formula_vars:
		lbl_formula_vars.text = "CALCULATION:  %s" % ch.get("formula_math", "")
		
	# Input Workspace
	if input_answer:
		if is_completed:
			var prev_val = ""
			if gm and gm.progress:
				prev_val = gm.progress.completed_task_ids.get(l_tid, {}).get("player_value", "")
			if str(prev_val).is_empty():
				prev_val = str(ch.get("target_value", ""))
			input_answer.text = str(prev_val)
		else:
			input_answer.text = ""
			
	# Feedback Card
	if feedback_card:
		if is_completed:
			feedback_card.visible = true
			lbl_feedback_status.text = "CHALLENGE COMPLETED & CERTIFIED ✓"
			lbl_feedback_status.modulate = MarsDeepUIRef.COLOR_GREEN
			txt_feedback_explanation.text = ch.get("explanation_after", "")
		else:
			feedback_card.visible = false

# ==============================================================================
# ADVANCED MODE DISPLAY & WORKFLOW
# ==============================================================================
func _setup_advanced_module_buttons() -> void:
	if not module_buttons_vbox:
		return
	for child in module_buttons_vbox.get_children():
		child.queue_free()
		
	for mod in ADVANCED_MODULES:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 32)
		btn.text = "%s %s" % [mod["icon"], mod["short_name"]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_advanced_module_selected.bind(int(mod["id"])))
		module_buttons_vbox.add_child(btn)

func _on_advanced_module_selected(mod_id: int) -> void:
	current_module_id = mod_id
	if not tasks_list_vbox:
		return
	for child in tasks_list_vbox.get_children():
		child.queue_free()
		
	var gm = _get_gm()
	var mod: Dictionary = {}
	for m in ADVANCED_MODULES:
		if m["id"] == mod_id:
			mod = m
			break
			
	var tids: Array = mod.get("task_ids", [])
	for tid in tids:
		var task: Dictionary = _find_advanced_task_by_id(tid)
		if task.is_empty():
			continue
		var is_done: bool = false
		if gm:
			is_done = gm.is_task_completed(tid)
		var t_idx: int = all_advanced_tasks.find(task)
		
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 30)
		btn.text = "%s %s" % ["✓" if is_done else "○", task.get("name", tid)]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_GREEN if is_done else MarsDeepUIRef.COLOR_TEXT_PRIMARY)
		btn.pressed.connect(_select_advanced_task_by_index.bind(t_idx))
		tasks_list_vbox.add_child(btn)
		
	if not tids.is_empty():
		var first_t: Dictionary = _find_advanced_task_by_id(tids[0])
		var first_idx: int = all_advanced_tasks.find(first_t)
		if first_idx >= 0:
			_select_advanced_task_by_index(first_idx)

func _find_advanced_task_by_id(tid: String) -> Dictionary:
	for t in all_advanced_tasks:
		if t.get("id", "") == tid:
			return t
	return {}

func _select_advanced_task_by_index(idx: int) -> void:
	if idx < 0 or idx >= all_advanced_tasks.size():
		return
	current_advanced_index = idx
	_display_advanced_task(idx)

func _display_advanced_task(idx: int) -> void:
	var gm = _get_gm()
	var task: Dictionary = all_advanced_tasks[idx]
	var tid: String = task.get("id", "")
	var tname: String = task.get("name", "")
	var desc: String = task.get("description", "")
	var unit: String = task.get("unit", "")
	var formula_hint: String = task.get("formula_hint", "")
	var is_completed: bool = false
	if gm:
		is_completed = gm.is_task_completed(tid)
	
	if lbl_task_title:
		lbl_task_title.text = "[ %s ]  %s" % [tid, tname]
	if lbl_task_module:
		lbl_task_module.text = "LEVEL: %s • ADVANCED AEROSPACE MODULE" % task.get("level_title", "General")
	if txt_problem_statement:
		txt_problem_statement.text = desc
	if lbl_unit:
		lbl_unit.text = unit
	if lbl_current_task_index:
		lbl_current_task_index.text = "TASK %d / %d" % [idx + 1, all_advanced_tasks.size()]
		
	if given_data_vbox:
		for child in given_data_vbox.get_children():
			child.queue_free()
		_populate_advanced_given_data(task)
		
	if lbl_formula_eq:
		lbl_formula_eq.text = "EQUATION:  %s" % formula_hint
	if lbl_formula_vars:
		lbl_formula_vars.text = _get_advanced_variable_definitions(tid)
		
	if input_answer:
		if is_completed:
			var prev_val = ""
			if gm and gm.progress:
				prev_val = gm.progress.completed_task_ids.get(tid, {}).get("player_value", "")
			input_answer.text = str(prev_val)
		else:
			input_answer.text = ""
			
	if feedback_card:
		if is_completed:
			feedback_card.visible = true
			lbl_feedback_status.text = "STATUS: VALIDATED & SUBMITTED ✓"
			lbl_feedback_status.modulate = MarsDeepUIRef.COLOR_GREEN
			txt_feedback_explanation.text = "This engineering calculation has been validated by the flight computer and officially certified."
		else:
			feedback_card.visible = false

func _populate_advanced_given_data(task: Dictionary) -> void:
	var tid: String = task.get("id", "")
	var lines: Array[String] = []
	match tid:
		"TASK_01_01": lines = ["Primary Candidate Profiles: Surface Rover, Stationary Lander, Orbital Reconnaissance", "Destination: Jezero Crater, Mars"]
		"TASK_01_02": lines = ["Mars Perihelion (r_peri): 1.381 AU", "Mars Aphelion (r_aph): 1.666 AU"]
		"TASK_01_03": lines = ["Opposition Distance (d): 225,000,000 km", "Speed of Light (c): 299,792.458 km/s"]
		"TASK_01_04": lines = ["Solar Constant S0 (1 AU): 1361.0 W/m²", "Mars Mean Distance: 1.524 AU"]
		"TASK_01_05": lines = ["Standard Target Payload Fraction: 18.0%"]
		"TASK_02_01": lines = ["Structure: 320 kg | Avionics: 85 kg | Power: 145 kg", "Thermal: 60 kg | Comms: 40 kg | Payload: 150 kg"]
		"TASK_02_02": lines = ["Daytime Load: 350 W | Cell Efficiency: 28% | Dust Derating: 0.80", "Solar Flux S: 586 W/m²"]
		"TASK_02_03": lines = ["Night Heater Draw: 90 W | Night Duration: 12.3 hours", "Depth-of-Discharge (DoD): 70% (0.70)"]
		"TASK_02_04": lines = ["Required Delta-V: 1600 m/s | Isp: 320 s | g0: 9.80665 m/s²", "Dry Mass: 800 kg"]
		"TASK_02_05": lines = ["Heat Load: 400 W | Radiator Temp: 285 K | Emissivity: 0.90", "Stefan-Boltzmann sigma: 5.67e-8"]
		"TASK_03_01": lines = ["Injection Energy C3: 16.5 km²/s² | Formula: v_inf = sqrt(C3)"]
		"TASK_03_02": lines = ["Earth Period T1: 365.25 days | Mars Period T2: 686.98 days"]
		"TASK_03_03": lines = ["Fairing Inner Diameter: 5.00 m | Spacecraft Diameter: 3.80 m"]
		"TASK_03_04": lines = ["Launcher TMI Capacity: 2200 kg | Spacecraft Wet Mass: 1850 kg"]
		"TASK_04_01": lines = ["Hohmann Semi-Major Axis a: 1.262 AU | Earth: 1.0 AU | Mars: 1.524 AU"]
		"TASK_04_02": lines = ["Trajectory Trim Delta-V: 15 m/s | Isp: 220 s | Stage Mass: 1750 kg"]
		"TASK_04_03": lines = ["Frequency: 8.4 GHz | Distance: 200,000,000 km | c: 299,792,458 m/s"]
		"TASK_04_04": lines = ["Cruise Duration: 260 days | Daily Dose: 1.8 mSv/day"]
		"TASK_05_01": lines = ["Entry Velocity: 5800 m/s | Entry Mass: 1025 kg"]
		"TASK_05_02": lines = ["Payload Mass: 850 kg | Mars Gravity: 3.72 m/s² | Density: 0.015 kg/m³", "Parachute Diameter: 21.5 m | Cd: 0.55"]
		"TASK_05_03": lines = ["Terminal Velocity: 60 m/s | Touchdown Velocity: 0.75 m/s | Deceleration: 9.5 m/s²"]
		"TASK_05_04": lines = ["Traverse: 120 m | Speed: 0.04 m/s | Motor Power: 180 W"]
		"TASK_05_05": lines = ["Instruments: 4 | Core Samples: 15 | Telemetry Link Efficiency: 1.5"]
		_: lines = ["Official NASA JPL Mars mission flight specifications."]
		
	for l in lines:
		var lbl := Label.new()
		lbl.text = "• " + l
		lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_PRIMARY)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		given_data_vbox.add_child(lbl)

func _get_advanced_variable_definitions(tid: String) -> String:
	match tid:
		"TASK_01_02": return "a: Semi-major axis | r_peri: Perihelion | r_aph: Aphelion"
		"TASK_01_03": return "t: Light delay (s) | d: Distance (km) | c: Speed of light (299,792 km/s)"
		"TASK_01_04": return "S_mars: Mars solar flux (W/m²) | S0: 1361 W/m² | r_AU: Distance in AU"
		"TASK_02_01": return "M_dry: Total dry mass (kg) | sum(M_subsystems): Structure + Avionics + Power + Thermal + Comms + Payload"
		"TASK_02_02": return "Area: Array area (m²) | P_load: Load (W) | S: Flux | efficiency: Cell yield | derating: Dust"
		"TASK_02_03": return "Capacity: Battery (Wh) | P_night: Power (W) | t_night: Duration (h) | DoD_max: 0.70"
		"TASK_02_04": return "M_prop: Propellant (kg) | M_dry: Dry mass | Δv: 1600 m/s | Isp: 320 s | g0: 9.80665"
		"TASK_02_05": return "A_rad: Area (m²) | Q: Heat (W) | ε: 0.90 | σ: 5.67e-8 | T: 285 K"
		"TASK_03_01": return "v_inf: Excess speed (km/s) | C3: Injection energy (km²/s²)"
		"TASK_03_02": return "S: Synodic period (days) | T1: Earth period | T2: Mars period"
		"TASK_04_01": return "T_transfer: Duration (days) | a: Semi-major axis (1.262 AU)"
		"TASK_04_02": return "M_prop: Trim fuel | Δv: 15 m/s | Isp: 220 s | M_total: 1750 kg"
		"TASK_05_02": return "v_t: Terminal velocity | m: Mass | g: Mars gravity | ρ: Density | A: Area | Cd: 0.55"
		_: return "Variables defined per NASA JPL technical specifications."

# ==============================================================================
# SUBMISSION & VALIDATION
# ==============================================================================
func _on_submit_calculation_pressed() -> void:
	var player_text: String = input_answer.text.strip_edges()
	if player_text.is_empty():
		_display_feedback(false, "Submission rejected: Please enter your calculated numerical value.")
		return
		
	if not is_advanced_mode:
		_submit_beginner_challenge(current_beginner_index, player_text)
	else:
		_submit_advanced_task(current_advanced_index, player_text)

func _submit_beginner_challenge(idx: int, player_text: String) -> void:
	var ch: Dictionary = BEGINNER_CHALLENGES[idx]
	var target: float = float(ch.get("target_value", 0.0))
	var tol: float = float(ch.get("tolerance", 0.05))
	
	if not player_text.is_valid_float():
		_display_feedback(false, "Please enter a valid numerical calculation.")
		return
		
	var p_val: float = player_text.to_float()
	var error_margin: float = abs(p_val - target) / max(0.001, abs(target))
	
	if error_margin <= tol:
		# Accept! Link to campaign task if applicable
		var l_tid: String = ch.get("linked_task_id", "")
		var l_lid: String = ch.get("linked_level_id", "LVL_02")
		var gm = _get_gm()
		if not l_tid.is_empty() and gm:
			gm.submit_task_calculation(l_lid, l_tid, player_text)
			
		_display_feedback(true, ch.get("explanation_after", "Challenge successfully validated!"))
		_populate_beginner_challenges_list()
	else:
		var err_pct: float = error_margin * 100.0
		_display_feedback(false, "Calculation incorrect (Error: %.1f%%). Check your arithmetic or ask the Mission AI Assistant for a hint!" % err_pct)

func _submit_advanced_task(idx: int, player_text: String) -> void:
	var task: Dictionary = all_advanced_tasks[idx]
	var tid: String = task.get("id", "")
	var lid: String = task.get("level_id", "LVL_01")
	
	var gm = _get_gm()
	var res: Dictionary = {}
	if gm:
		res = gm.submit_task_calculation(lid, tid, player_text)
	var is_valid: bool = res.get("is_valid", false)
	var msg: String = res.get("message", "")
	
	_display_feedback(is_valid, msg)
	_on_advanced_module_selected(current_module_id)

func _display_feedback(is_ok: bool, msg: String) -> void:
	if feedback_card:
		feedback_card.visible = true
		if is_ok:
			lbl_feedback_status.text = "CALCULATION VALIDATED ✓"
			lbl_feedback_status.modulate = MarsDeepUIRef.COLOR_GREEN
			txt_feedback_explanation.text = msg
		else:
			lbl_feedback_status.text = "CALCULATION INCORRECT ✕"
			lbl_feedback_status.modulate = MarsDeepUIRef.COLOR_RED
			txt_feedback_explanation.text = msg
	_update_progress_readouts()

# ==============================================================================
# MISSION AI ASSISTANT (GDScript Local Logic)
# ==============================================================================
func _setup_ai_assistant() -> void:
	if btn_ai_explain:
		btn_ai_explain.pressed.connect(_on_ai_explain_pressed)
	if btn_ai_hint:
		btn_ai_hint.pressed.connect(_on_ai_hint_pressed)
	if btn_ai_teach:
		btn_ai_teach.pressed.connect(_on_ai_teach_pressed)
	if ai_response_panel:
		ai_response_panel.visible = false

func _on_ai_explain_pressed() -> void:
	if not is_advanced_mode:
		var ch: Dictionary = BEGINNER_CHALLENGES[current_beginner_index]
		_show_ai_message("💡 EXPLANATION", ch.get("ai_explain", "Add or subtract the given values as requested."))
	else:
		var task: Dictionary = all_advanced_tasks[current_advanced_index]
		_show_ai_message("💡 EXPLANATION", "This task assesses official NASA physical formulas: %s" % task.get("description", ""))

func _on_ai_hint_pressed() -> void:
	if not is_advanced_mode:
		var ch: Dictionary = BEGINNER_CHALLENGES[current_beginner_index]
		_show_ai_message("🔍 STRATEGY HINT", ch.get("ai_hint", "Check the formula in plain language above!"))
	else:
		var task: Dictionary = all_advanced_tasks[current_advanced_index]
		_show_ai_message("🔍 STRATEGY HINT", "Use the formula hint: %s. Substitute given values and solve." % task.get("formula_hint", ""))

func _on_ai_teach_pressed() -> void:
	if not is_advanced_mode:
		var ch: Dictionary = BEGINNER_CHALLENGES[current_beginner_index]
		_show_ai_message("📚 WORKED EXAMPLE", ch.get("ai_teach", "Formula and example."))
	else:
		_show_ai_message("📚 WORKED EXAMPLE", "Example: When computing Delta-V = Isp * g0 * ln(m0/mf), with Isp=300 and ratio=2.0, Delta-V = 300 * 9.80665 * ln(2.0) = 2039 m/s.")

func _show_ai_message(header: String, body: String) -> void:
	if ai_response_panel and txt_ai_response:
		ai_response_panel.visible = true
		txt_ai_response.text = "%s:\n%s" % [header, body]

# ==============================================================================
# BUILT-IN ARITHMETIC CALCULATOR
# ==============================================================================
var is_calc_open: bool = true

func _setup_calculator() -> void:
	if btn_toggle_calc:
		btn_toggle_calc.pressed.connect(_on_toggle_calc_pressed)
		
	if not calc_keypad_grid:
		return
	for child in calc_keypad_grid.get_children():
		child.queue_free()
		
	var btns: Array[String] = [
		"C", "(", ")", "/",
		"7", "8", "9", "*",
		"4", "5", "6", "-",
		"1", "2", "3", "+",
		"0", ".", "DEL", "="
	]
	
	for b in btns:
		var btn := Button.new()
		btn.text = b
		btn.custom_minimum_size = Vector2(36, 28)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_calc_button_pressed.bind(b))
		calc_keypad_grid.add_child(btn)

func _on_toggle_calc_pressed() -> void:
	is_calc_open = not is_calc_open
	if calc_display:
		calc_display.visible = is_calc_open
	if calc_keypad_grid:
		calc_keypad_grid.visible = is_calc_open
	if btn_calc_copy:
		btn_calc_copy.visible = is_calc_open
	if btn_toggle_calc:
		btn_toggle_calc.text = "HIDE" if is_calc_open else "SHOW"

func _on_calc_button_pressed(btn_text: String) -> void:
	if not calc_display:
		return
	match btn_text:
		"C":
			calc_display.text = ""
		"DEL":
			var cur := calc_display.text
			if cur.length() > 0:
				calc_display.text = cur.substr(0, cur.length() - 1)
		"=":
			_evaluate_calc()
		_:
			calc_display.text += btn_text

func _evaluate_calc() -> void:
	var raw := calc_display.text.strip_edges()
	if raw.is_empty():
		return
	var expr := Expression.new()
	var err := expr.parse(raw)
	if err != OK:
		calc_display.text = "Syntax Error"
		return
	var res = expr.execute()
	if expr.has_execute_failed():
		calc_display.text = "Math Error"
	else:
		if typeof(res) in [TYPE_FLOAT, TYPE_INT]:
			calc_display.text = "%.2f" % float(res)
		else:
			calc_display.text = str(res)

func _on_copy_calc_pressed() -> void:
	if calc_display and input_answer:
		var txt := calc_display.text.strip_edges()
		if not txt.is_empty() and txt.is_valid_float():
			input_answer.text = txt

# ==============================================================================
# FOOTER NAVIGATION & STATUS READOUTS
# ==============================================================================
func _on_prev_pressed() -> void:
	if not is_advanced_mode:
		if current_beginner_index > 0:
			_select_beginner_challenge(current_beginner_index - 1)
	else:
		if current_advanced_index > 0:
			_select_advanced_task_by_index(current_advanced_index - 1)

func _on_next_pressed() -> void:
	if not is_advanced_mode:
		if current_beginner_index < BEGINNER_CHALLENGES.size() - 1:
			_select_beginner_challenge(current_beginner_index + 1)
	else:
		if current_advanced_index < all_advanced_tasks.size() - 1:
			_select_advanced_task_by_index(current_advanced_index + 1)

func _on_campaign_progress_updated() -> void:
	_update_progress_readouts()
	if not is_advanced_mode:
		_populate_beginner_challenges_list()
	else:
		_on_advanced_module_selected(current_module_id)

func _update_progress_readouts() -> void:
	var gm = _get_gm()
	if not gm or not gm.progress:
		return
	var total: int = gm.progress.get_total_tasks_count()
	var completed: int = gm.progress.get_completed_tasks_count()
	
	if lbl_progress_count:
		lbl_progress_count.text = "TASKS CERTIFIED: %d / %d" % [completed, total]
	if bar_overall_progress:
		bar_overall_progress.max_value = total
		bar_overall_progress.value = completed
		
	var lvl1_done: bool = gm.progress.are_all_level_tasks_completed("LVL_01")
	var lvl2_done: bool = gm.progress.are_all_level_tasks_completed("LVL_02")
	
	if lbl_level_unlock_status:
		if lvl2_done:
			lbl_level_unlock_status.text = "LEVEL 02 CERTIFIED • LEVEL 03 UNLOCKED"
			lbl_level_unlock_status.modulate = MarsDeepUIRef.COLOR_GREEN
		elif lvl1_done:
			lbl_level_unlock_status.text = "LEVEL 01 CERTIFIED • LEVEL 02 IN PROGRESS"
			lbl_level_unlock_status.modulate = MarsDeepUIRef.COLOR_CYAN
		else:
			lbl_level_unlock_status.text = "LEVEL 01 IN PROGRESS"
			lbl_level_unlock_status.modulate = MarsDeepUIRef.COLOR_ORANGE
			
	if lbl_cert_status:
		if lvl2_done:
			lbl_cert_status.text = "CERTIFIED FOR LAUNCH ✓"
			lbl_cert_status.modulate = MarsDeepUIRef.COLOR_GREEN
		else:
			lbl_cert_status.text = "CERTIFICATION IN PROGRESS"
			lbl_cert_status.modulate = MarsDeepUIRef.COLOR_ORANGE

func _update_hardware_reference() -> void:
	if not lbl_hardware_ref:
		return
	var gm = _get_gm()
	if not gm:
		return
	var bus: String = "Composite Honeycomb (210 kg)" if gm.has_component("BUS_LIGHT") else ("Heavy Platform (380 kg)" if gm.has_component("BUS_HEAVY") else "Light Bus (210 kg)")
	var pwr: String = "UltraFlex Solar (420 W)" if gm.has_component("PWR_SOLAR_ULTRAFLEX") else ("MMRTG Nuclear (110 W)" if gm.has_component("PWR_MMRTG") else "Solar Wings (420 W)")
	var inst_cnt: int = max(2, gm.selected_instruments.size())
	lbl_hardware_ref.text = "Active Spacecraft Specs:\n• Structure: %s\n• Power System: %s\n• Science Tools: %d Mounted\n• Baseline Mass: 800.0 kg" % [bus, pwr, inst_cnt]
