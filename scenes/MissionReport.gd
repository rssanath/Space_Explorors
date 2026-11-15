extends Control

## MissionReport.gd - Mission Debrief, Performance Analysis & Final NASA Certification Controller
## Coordinates 3D NASA Mission Control environment, 16-stage timeline, science gallery,
## 10 player achievement medals, and final celebratory cinematic.

const GameManagerRef = preload("res://scripts/GameManager.gd")
const MissionScoringRef = preload("res://scripts/MissionScoring.gd")
const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")
const LaunchAudioRef = preload("res://scripts/LaunchAudio.gd")

var _gm_cache: Node = null
func _get_gm() -> Node:
	if _gm_cache: return _gm_cache
	if Engine.has_singleton("GameManager"):
		_gm_cache = Engine.get_singleton("GameManager")
	elif is_inside_tree() and get_tree().root.has_node("GameManager"):
		_gm_cache = get_tree().root.get_node("GameManager")
	return _gm_cache

# 3D Environment & SubViewport
@onready var subviewport: SubViewport = $MarginContainer/VBox/MainBody/ViewportContainer/SubViewport
@onready var mission_control_3d: Node3D = $MarginContainer/VBox/MainBody/ViewportContainer/SubViewport/MissionControl3D

# Top Navigation Tabs
@onready var btn_tab_overview: Button = $MarginContainer/VBox/Header/TabContainer/BtnTabOverview
@onready var btn_tab_timeline: Button = $MarginContainer/VBox/Header/TabContainer/BtnTabTimeline
@onready var btn_tab_performance: Button = $MarginContainer/VBox/Header/TabContainer/BtnTabPerformance
@onready var btn_tab_science: Button = $MarginContainer/VBox/Header/TabContainer/BtnTabScience
@onready var btn_tab_specs: Button = $MarginContainer/VBox/Header/TabContainer/BtnTabSpecs
@onready var btn_tab_achievements: Button = $MarginContainer/VBox/Header/TabContainer/BtnTabAchievements
@onready var btn_tab_cinematic: Button = $MarginContainer/VBox/Header/TabContainer/BtnTabCinematic
@onready var btn_cam_switch: Button = $MarginContainer/VBox/Header/BtnCamSwitch

# Radio Comms Box
@onready var radio_panel: PanelContainer = $MarginContainer/VBox/MainBody/OverlayHUD/RadioPanel
@onready var lbl_radio_speaker: Label = $MarginContainer/VBox/MainBody/OverlayHUD/RadioPanel/Margin/VBox/LblSpeaker
@onready var lbl_radio_message: Label = $MarginContainer/VBox/MainBody/OverlayHUD/RadioPanel/Margin/VBox/LblMessage

# Content Panels
@onready var panel_overview: PanelContainer = $MarginContainer/VBox/MainBody/OverlayHUD/PanelOverview
@onready var panel_timeline: PanelContainer = $MarginContainer/VBox/MainBody/OverlayHUD/PanelTimeline
@onready var panel_performance: PanelContainer = $MarginContainer/VBox/MainBody/OverlayHUD/PanelPerformance
@onready var panel_science: PanelContainer = $MarginContainer/VBox/MainBody/OverlayHUD/PanelScience
@onready var panel_specs: PanelContainer = $MarginContainer/VBox/MainBody/OverlayHUD/PanelSpecs
@onready var panel_achievements: PanelContainer = $MarginContainer/VBox/MainBody/OverlayHUD/PanelAchievements
@onready var panel_cinematic: PanelContainer = $MarginContainer/VBox/MainBody/OverlayHUD/PanelCinematic

# Overview Elements
@onready var badge_grade: Label = $MarginContainer/VBox/MainBody/OverlayHUD/PanelOverview/Margin/HBox/LeftCol/GradeBadge
@onready var lbl_award_title: Label = $MarginContainer/VBox/MainBody/OverlayHUD/PanelOverview/Margin/HBox/LeftCol/LblAwardTitle
@onready var lbl_final_score: Label = $MarginContainer/VBox/MainBody/OverlayHUD/PanelOverview/Margin/HBox/LeftCol/LblFinalScore
@onready var bar_tasks: ProgressBar = $MarginContainer/VBox/MainBody/OverlayHUD/PanelOverview/Margin/HBox/RightCol/BarTasks
@onready var bar_precision: ProgressBar = $MarginContainer/VBox/MainBody/OverlayHUD/PanelOverview/Margin/HBox/RightCol/BarPrecision
@onready var bar_science: ProgressBar = $MarginContainer/VBox/MainBody/OverlayHUD/PanelOverview/Margin/HBox/RightCol/BarScience
@onready var lbl_summary_text: Label = $MarginContainer/VBox/MainBody/OverlayHUD/PanelOverview/Margin/HBox/RightCol/LblSummaryText

# Timeline Elements
@onready var timeline_vbox: VBoxContainer = $MarginContainer/VBox/MainBody/OverlayHUD/PanelTimeline/Margin/VBox/Scroll/TimelineList

# Performance Elements
@onready var perf_vbox: VBoxContainer = $MarginContainer/VBox/MainBody/OverlayHUD/PanelPerformance/Margin/VBox/Scroll/PerfList

# Science Elements
@onready var science_list_vbox: VBoxContainer = $MarginContainer/VBox/MainBody/OverlayHUD/PanelScience/Margin/HBox/LeftList/Scroll/ListVBox
@onready var lbl_sci_sample_name: Label = $MarginContainer/VBox/MainBody/OverlayHUD/PanelScience/Margin/HBox/RightDetail/Margin/VBox/LblSampleName
@onready var lbl_sci_instruments: Label = $MarginContainer/VBox/MainBody/OverlayHUD/PanelScience/Margin/HBox/RightDetail/Margin/VBox/LblInstruments
@onready var lbl_sci_observation: Label = $MarginContainer/VBox/MainBody/OverlayHUD/PanelScience/Margin/HBox/RightDetail/Margin/VBox/LblObservation
@onready var lbl_sci_explanation: Label = $MarginContainer/VBox/MainBody/OverlayHUD/PanelScience/Margin/HBox/RightDetail/Margin/VBox/LblExplanation
@onready var lbl_sci_real_nasa: Label = $MarginContainer/VBox/MainBody/OverlayHUD/PanelScience/Margin/HBox/RightDetail/Margin/VBox/LblRealNasa

# Specs Elements
@onready var lbl_specs_grid: Label = $MarginContainer/VBox/MainBody/OverlayHUD/PanelSpecs/Margin/VBox/Scroll/LblSpecsText

# Achievements Elements
@onready var ach_grid: GridContainer = $MarginContainer/VBox/MainBody/OverlayHUD/PanelAchievements/Margin/VBox/Scroll/AchGrid

# Cinematic Elements
@onready var btn_replay_mission: Button = $MarginContainer/VBox/MainBody/OverlayHUD/PanelCinematic/Margin/VBox/HBoxButtons/BtnReplay
@onready var btn_explore_again: Button = $MarginContainer/VBox/MainBody/OverlayHUD/PanelCinematic/Margin/VBox/HBoxButtons/BtnExploreAgain
@onready var btn_return_menu: Button = $MarginContainer/VBox/MainBody/OverlayHUD/PanelCinematic/Margin/VBox/HBoxButtons/BtnMenu

# State
var current_tab: int = 0
var current_cam_mode: int = 0
var cached_discoveries: Array[Dictionary] = []
var selected_discovery_idx: int = 0

func _ready() -> void:
	print("[MissionReport] Initializing NASA Mission Debrief and Final Certification...")
	_apply_styling()
	_connect_signals()
	_populate_all_data()
	_switch_tab(0) # Start on Overview Tab

func _apply_styling() -> void:
	var bg_panel_style = MarsDeepUIRef.create_panel_style(Color(0.03, 0.05, 0.09, 0.92), MarsDeepUIRef.COLOR_CYAN, 1, 4, 12)
	for p in [panel_overview, panel_timeline, panel_performance, panel_science, panel_specs, panel_achievements, panel_cinematic]:
		if p: p.add_theme_stylebox_override("panel", bg_panel_style)
		
	if radio_panel:
		radio_panel.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.04, 0.08, 0.12, 0.95), MarsDeepUIRef.COLOR_CYAN, 1, 4, 8))

func _connect_signals() -> void:
	if btn_tab_overview: btn_tab_overview.pressed.connect(func(): _switch_tab(0))
	if btn_tab_timeline: btn_tab_timeline.pressed.connect(func(): _switch_tab(1))
	if btn_tab_performance: btn_tab_performance.pressed.connect(func(): _switch_tab(2))
	if btn_tab_science: btn_tab_science.pressed.connect(func(): _switch_tab(3))
	if btn_tab_specs: btn_tab_specs.pressed.connect(func(): _switch_tab(4))
	if btn_tab_achievements: btn_tab_achievements.pressed.connect(func(): _switch_tab(5))
	if btn_tab_cinematic: btn_tab_cinematic.pressed.connect(func(): _switch_tab(6))
	if btn_cam_switch: btn_cam_switch.pressed.connect(_cycle_camera)
	
	if btn_replay_mission: btn_replay_mission.pressed.connect(_on_replay_pressed)
	if btn_explore_again: btn_explore_again.pressed.connect(_on_explore_again_pressed)
	if btn_return_menu: btn_return_menu.pressed.connect(_on_return_menu_pressed)

func _switch_tab(idx: int) -> void:
	current_tab = idx
	var panels = [panel_overview, panel_timeline, panel_performance, panel_science, panel_specs, panel_achievements, panel_cinematic]
	var btns = [btn_tab_overview, btn_tab_timeline, btn_tab_performance, btn_tab_science, btn_tab_specs, btn_tab_achievements, btn_tab_cinematic]
	
	for i in range(panels.size()):
		if panels[i]: panels[i].visible = (i == current_tab)
		if btns[i]:
			if i == current_tab:
				btns[i].modulate = MarsDeepUIRef.COLOR_CYAN
			else:
				btns[i].modulate = Color(0.8, 0.85, 0.9, 1.0)
				
	match current_tab:
		0:
			_set_mission_control_cam(0) # OVERVIEW
			_broadcast_radio("NASA ADMINISTRATOR", "Welcome to Mission Control, Commander. Review your comprehensive flight performance and certification.")
		1:
			_set_mission_control_cam(1) # VIDEO WALL
			_broadcast_radio("FLIGHT DYNAMICS", "16-stage flight timeline logged from Cape Canaveral liftoff to Jezero Crater touchdown.")
		2:
			_set_mission_control_cam(2) # CONSOLE
			_broadcast_radio("CHIEF ENGINEER", "Performance metrics evaluated across physical calculation accuracy, propulsion margins, and landing velocity.")
		3:
			_set_mission_control_cam(1) # VIDEO WALL
			_broadcast_radio("CHIEF SCIENTIST", "Astrobiology discovery gallery: Sample caches cross-referenced against real-world NASA Mars mission telemetry.")
		4:
			_set_mission_control_cam(2) # CONSOLE
			_broadcast_radio("SYSTEMS INTEGRATOR", "Spacecraft technical telemetry and subsystem telemetry verified against design baseline.")
		5:
			_set_mission_control_cam(0) # OVERVIEW
			_broadcast_radio("NASA AWARDS BOARD", "Honorary achievement medals awarded based on verified mission flight milestones.")
		6:
			_set_mission_control_cam(3) # MARS CINEMATIC
			_broadcast_radio("CAPCOM (HOUSTON)", "MARS DEEP: DESIGN. LAUNCH. EXPLORE. Outstanding achievement, Commander. Mission Accomplished.")

func _cycle_camera() -> void:
	current_cam_mode = (current_cam_mode + 1) % 4
	_set_mission_control_cam(current_cam_mode)

func _set_mission_control_cam(cam_idx: int) -> void:
	if mission_control_3d:
		mission_control_3d.set_camera_view(cam_idx)

func _broadcast_radio(speaker: String, msg: String) -> void:
	if lbl_radio_speaker: lbl_radio_speaker.text = "• " + speaker
	if lbl_radio_message: lbl_radio_message.text = msg
	if mission_control_3d:
		mission_control_3d.play_radio_comm()

# =========================================================================
# DATA POPULATION
# =========================================================================

func _populate_all_data() -> void:
	var gm = _get_gm()
	_populate_overview(gm)
	_populate_timeline(gm)
	_populate_performance(gm)
	_populate_science_gallery(gm)
	_populate_specs(gm)
	_populate_achievements(gm)

func _populate_overview(gm: Node) -> void:
	var perf = MissionScoringRef.get_performance_breakdown(gm)
	var overall: Dictionary = perf.get("overall", {})
	var grade: String = overall.get("grade", "A")
	var score: int = overall.get("score", 9200)
	var award: String = overall.get("award_title", "NASA Mission Medal")
	
	if badge_grade:
		badge_grade.text = grade
		match grade:
			"S": badge_grade.modulate = Color(1.0, 0.84, 0.0, 1.0) # Gold
			"A": badge_grade.modulate = MarsDeepUIRef.COLOR_CYAN
			"B": badge_grade.modulate = MarsDeepUIRef.COLOR_GREEN
			"C": badge_grade.modulate = MarsDeepUIRef.COLOR_YELLOW
			"D": badge_grade.modulate = MarsDeepUIRef.COLOR_ORANGE
			_: badge_grade.modulate = MarsDeepUIRef.COLOR_RED
			
	if lbl_award_title: lbl_award_title.text = award
	if lbl_final_score: lbl_final_score.text = "%d / 10,000 PTS" % score
	
	var task_pts: int = overall.get("task_points", 5000)
	var prec_pts: int = overall.get("precision_bonus", 2500)
	var sci_pts: int = overall.get("science_points", 2500)
	
	if bar_tasks: bar_tasks.value = (float(task_pts) / 5000.0) * 100.0
	if bar_precision: bar_precision.value = (float(prec_pts) / 2500.0) * 100.0
	if bar_science: bar_science.value = (float(sci_pts) / 2500.0) * 100.0
	
	var p = gm.progress if gm else null
	var comp_count: int = p.get_completed_tasks_count() if p else 23
	var total_count: int = p.get_total_tasks_count() if p else 23
	var route_name: String = gm.get_selected_mission_route().get("name", "Hohmann Transfer") if gm else "Hohmann"
	var lv_name: String = gm.get_selected_launch_vehicle().get("name", "Atlas V 541") if gm else "Atlas V 541"
	
	if lbl_summary_text:
		lbl_summary_text.text = "FLIGHT DEBRIEF EXECUTIVE SUMMARY:\n" + \
			"• Campaign Completion: %d of %d Mandatory Aerospace Engineering Tasks Certified (100%%).\n" % [comp_count, total_count] + \
			"• Launch Vehicle: %s from Cape Canaveral Pad 39A.\n" % lv_name + \
			"• Interplanetary Trajectory: %s with Monopropellant TCM-1 Burn.\n" % route_name + \
			"• Touchdown Velocity: 1.15 m/s (Soft Touchdown Nominal at Jezero Crater).\n" + \
			"• Planetary Science: 5 Astrobiological Discoveries Cached (100%% Yield)."

func _populate_timeline(gm: Node) -> void:
	if not timeline_vbox: return
	for child in timeline_vbox.get_children():
		child.queue_free()
		
	var timeline_stages = MissionScoringRef.get_mission_timeline(gm)
	for item in timeline_stages:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.04, 0.07, 0.11, 0.8), MarsDeepUIRef.COLOR_BORDER_SUBTLE, 1, 3, 8))
		
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 12)
		m.add_theme_constant_override("margin_top", 8)
		m.add_theme_constant_override("margin_right", 12)
		m.add_theme_constant_override("margin_bottom", 8)
		card.add_child(m)
		
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)
		m.add_child(hbox)
		
		var badge := Label.new()
		badge.text = "[STAGE %02d]\n%s" % [item.get("id", 1), item.get("phase", "STAGE")]
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.custom_minimum_size = Vector2(85, 0)
		badge.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_CYAN)
		badge.add_theme_font_size_override("font_size", 11)
		hbox.add_child(badge)
		
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(vbox)
		
		var title_lbl := Label.new()
		title_lbl.text = item.get("title", "")
		title_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_PRIMARY)
		title_lbl.add_theme_font_size_override("font_size", 13)
		vbox.add_child(title_lbl)
		
		var desc_lbl := Label.new()
		desc_lbl.text = item.get("description", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_SECONDARY)
		desc_lbl.add_theme_font_size_override("font_size", 10)
		vbox.add_child(desc_lbl)
		
		var right_vbox := VBoxContainer.new()
		right_vbox.custom_minimum_size = Vector2(180, 0)
		right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(right_vbox)
		
		var stat_lbl := Label.new()
		stat_lbl.text = item.get("status_text", "NOMINAL")
		var is_comp: bool = item.get("completed", false)
		stat_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_GREEN if is_comp else MarsDeepUIRef.COLOR_YELLOW)
		stat_lbl.add_theme_font_size_override("font_size", 11)
		stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right_vbox.add_child(stat_lbl)
		
		var met_lbl := Label.new()
		met_lbl.text = item.get("metrics", "")
		met_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_SECONDARY)
		met_lbl.add_theme_font_size_override("font_size", 9)
		met_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right_vbox.add_child(met_lbl)
		
		timeline_vbox.add_child(card)

func _populate_performance(gm: Node) -> void:
	if not perf_vbox: return
	for child in perf_vbox.get_children():
		child.queue_free()
		
	var perf = MissionScoringRef.get_performance_breakdown(gm)
	var categories: Array = perf.get("categories", [])
	
	for cat in categories:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.04, 0.07, 0.11, 0.8), MarsDeepUIRef.COLOR_BORDER_SUBTLE, 1, 3, 10))
		
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 16)
		m.add_theme_constant_override("margin_top", 10)
		m.add_theme_constant_override("margin_right", 16)
		m.add_theme_constant_override("margin_bottom", 10)
		card.add_child(m)
		
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		m.add_child(vbox)
		
		var top_hbox := HBoxContainer.new()
		vbox.add_child(top_hbox)
		
		var name_lbl := Label.new()
		name_lbl.text = cat.get("name", "")
		name_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
		name_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_CYAN)
		name_lbl.add_theme_font_size_override("font_size", 14)
		top_hbox.add_child(name_lbl)
		
		var score_lbl := Label.new()
		score_lbl.text = "%d / %d PTS (%s)" % [cat.get("score", 0), cat.get("max_score", 1000), cat.get("grade", "")]
		score_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_GREEN)
		score_lbl.add_theme_font_size_override("font_size", 13)
		top_hbox.add_child(score_lbl)
		
		var pbar := ProgressBar.new()
		pbar.custom_minimum_size = Vector2(0, 8)
		pbar.show_percentage = false
		var ratio: float = float(cat.get("score", 0)) / float(max(1, cat.get("max_score", 1000))) * 100.0
		pbar.value = ratio
		vbox.add_child(pbar)
		
		var desc_lbl := Label.new()
		desc_lbl.text = cat.get("description", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_SECONDARY)
		desc_lbl.add_theme_font_size_override("font_size", 11)
		vbox.add_child(desc_lbl)
		
		perf_vbox.add_child(card)

func _populate_science_gallery(gm: Node) -> void:
	cached_discoveries = MissionScoringRef.get_science_gallery_data(gm)
	if not science_list_vbox: return
	for child in science_list_vbox.get_children():
		child.queue_free()
		
	for i in range(cached_discoveries.size()):
		var disc := cached_discoveries[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 48)
		btn.text = "%s\n%s" % [disc.get("name", ""), disc.get("location", "")]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 11)
		var idx := i
		btn.pressed.connect(func(): _select_science_discovery(idx))
		science_list_vbox.add_child(btn)
		
	_select_science_discovery(0)

func _select_science_discovery(idx: int) -> void:
	if idx < 0 or idx >= cached_discoveries.size(): return
	selected_discovery_idx = idx
	var disc := cached_discoveries[idx]
	
	if lbl_sci_sample_name: lbl_sci_sample_name.text = disc.get("name", "")
	if lbl_sci_instruments: lbl_sci_instruments.text = "INSTRUMENTS: " + disc.get("instrument", "") + " • LOCATION: " + disc.get("location", "")
	if lbl_sci_observation: lbl_sci_observation.text = "IN-GAME OBSERVATION:\n" + disc.get("observation", "")
	if lbl_sci_explanation: lbl_sci_explanation.text = "SCIENTIFIC EXPLANATION:\n" + disc.get("scientific_explanation", "")
	if lbl_sci_real_nasa: lbl_sci_real_nasa.text = "REAL-WORLD NASA EXPLORATION CROSS-REFERENCE:\n" + disc.get("real_world_nasa_discovery", "")

func _populate_specs(gm: Node) -> void:
	if not lbl_specs_grid: return
	var summary := MissionScoringRef.get_spacecraft_performance_summary(gm)
	
	var text := "=========================================================================\n"
	text += "MARS DEEP SPACECRAFT SPECIFICATIONS & PERFORMANCE AUDIT REPORT\n"
	text += "=========================================================================\n\n"
	text += "MISSION ARCHETYPE:               %s\n" % summary.get("archetype", "")
	text += "LAUNCH VEHICLE:                  %s (Capacity to C3: %.1f kg)\n" % [summary.get("launch_vehicle_name", ""), summary.get("launch_capacity_kg", 0.0)]
	text += "DRY SPACECRAFT MASS:             %.1f kg\n" % summary.get("dry_mass_kg", 0.0)
	text += "PROPELLANT TANKAGE:              %.1f kg (Hydrazine Monopropellant / Bipropellant)\n" % summary.get("propellant_mass_kg", 0.0)
	text += "TOTAL WET INJECTION MASS:        %.1f kg\n\n" % summary.get("wet_mass_kg", 0.0)
	text += "ELECTRICAL POWER GENERATION:     %.1f W (UltraFlex Solar Arrays / MMRTG)\n" % summary.get("power_generated_w", 0.0)
	text += "TOTAL POWER CONSUMPTION:         %.1f W (Bus + Telecom + Active Science)\n" % summary.get("power_consumed_w", 0.0)
	text += "POWER SAFETY MARGIN:             +%.1f W (Nominal Excess)\n\n" % summary.get("power_margin_w", 0.0)
	text += "TOTAL SPACECRAFT COST:           $%.1f Million\n" % summary.get("total_cost_m", 0.0)
	text += "INSTALLED NASA INSTRUMENTS:      %d Payloads Deployed\n" % summary.get("installed_instruments_count", 0)
	text += "SELECTED TRANSIT ROUTE:          %s (%d Days Duration)\n" % [summary.get("trajectory_name", ""), summary.get("transit_duration_days", 0)]
	text += "REQUIRED DELTA-V BUDGET:         %.2f km/s\n" % summary.get("delta_v_demand_km_s", 0.0)
	text += "MARS LANDING TOUCHDOWN:          %s\n" % summary.get("landing_result", "")
	text += "FINAL AUDIT STATUS:              %s\n" % summary.get("mission_status", "")
	text += "=========================================================================\n"
	
	lbl_specs_grid.text = text

func _populate_achievements(gm: Node) -> void:
	if not ach_grid: return
	for child in ach_grid.get_children():
		child.queue_free()
		
	var ach_list := MissionScoringRef.get_player_achievements(gm)
	for a in ach_list:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(230, 95)
		var is_unlocked: bool = a.get("unlocked", false)
		var border_col := MarsDeepUIRef.COLOR_GREEN if is_unlocked else Color(0.2, 0.25, 0.3, 0.5)
		card.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.04, 0.07, 0.11, 0.85), border_col, 1, 4, 8))
		
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 10)
		m.add_theme_constant_override("margin_top", 8)
		m.add_theme_constant_override("margin_right", 10)
		m.add_theme_constant_override("margin_bottom", 8)
		card.add_child(m)
		
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		m.add_child(hbox)
		
		var icon_lbl := Label.new()
		icon_lbl.text = a.get("icon", "🏅")
		icon_lbl.add_theme_font_size_override("font_size", 24)
		icon_lbl.custom_minimum_size = Vector2(32, 0)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(icon_lbl)
		
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(vbox)
		
		var title_lbl := Label.new()
		title_lbl.text = a.get("title", "")
		title_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_PRIMARY if is_unlocked else Color(0.5, 0.55, 0.6))
		title_lbl.add_theme_font_size_override("font_size", 11)
		vbox.add_child(title_lbl)
		
		var sub_lbl := Label.new()
		sub_lbl.text = "[%s] %s" % [a.get("rarity", "Bronze"), a.get("subtitle", "")]
		sub_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_ORANGE if is_unlocked else Color(0.4, 0.45, 0.5))
		sub_lbl.add_theme_font_size_override("font_size", 9)
		vbox.add_child(sub_lbl)
		
		var desc_lbl := Label.new()
		desc_lbl.text = a.get("description", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_SECONDARY if is_unlocked else Color(0.4, 0.45, 0.5))
		desc_lbl.add_theme_font_size_override("font_size", 8)
		vbox.add_child(desc_lbl)
		
		ach_grid.add_child(card)

# =========================================================================
# REPLAY & SCENE TRANSITIONS
# =========================================================================

func _on_replay_pressed() -> void:
	print("[MissionReport] Player requested Mission Replay. Resetting campaign state...")
	var gm = _get_gm()
	if gm and gm.has_method("reset_for_replay"):
		gm.reset_for_replay(true) # Keep unlocked levels accessible
	get_tree().change_scene_to_file("res://scenes/MissionDesign.tscn")

func _on_explore_again_pressed() -> void:
	print("[MissionReport] Navigating back to Mars surface exploration...")
	get_tree().change_scene_to_file("res://scenes/MarsExploration.tscn")

func _on_return_menu_pressed() -> void:
	print("[MissionReport] Returning to main menu...")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
