extends Control

## LaunchPreparation.gd - Stage D: Cinematic Launch Preparation, Environment & Player Throttle
## MARS DEEP • NASA Space Apps Challenge 2026 • Design. Launch. Explore.

const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")
const GameManagerRef = preload("res://scripts/GameManager.gd")
const LaunchAudioRef = preload("res://scripts/LaunchAudio.gd")

var _gm_cache: Node = null
func _get_gm() -> Node:
	if _gm_cache:
		return _gm_cache
	if Engine.has_singleton("GameManager"):
		_gm_cache = Engine.get_singleton("GameManager")
	elif is_inside_tree() and get_tree().root.has_node("GameManager"):
		_gm_cache = get_tree().root.get_node("GameManager")
	return _gm_cache

# Top Header Nodes
@onready var lbl_header_title: Label = $MarginContainer/VBoxContainer/Header/TitleVBox/Title
@onready var lbl_header_subtitle: Label = $MarginContainer/VBoxContainer/Header/TitleVBox/Subtitle
@onready var lbl_auth_badge: Label = $MarginContainer/VBoxContainer/Header/TopNav/AuthStatusBadge
@onready var btn_top_lab: Button = $MarginContainer/VBoxContainer/Header/TopNav/BtnBackLab
@onready var btn_top_designer: Button = $MarginContainer/VBoxContainer/Header/TopNav/BtnDesigner

# Left Panel: Rocket Catalogue
@onready var rocket_list_vbox: VBoxContainer = $MarginContainer/VBoxContainer/MainBody/LeftPanel/VBox/RocketScroll/RocketListVBox
@onready var lbl_selected_rocket_quick: Label = $MarginContainer/VBoxContainer/MainBody/LeftPanel/VBox/SelectedRocketSummary

# Center Panel: 3D Viewport, HUD & Camera Switcher
@onready var subviewport: SubViewport = $MarginContainer/VBoxContainer/MainBody/CenterPanel/ViewportContainer/SubViewport
@onready var rocket_3d: Node3D = $MarginContainer/VBoxContainer/MainBody/CenterPanel/ViewportContainer/SubViewport/RocketPreview3D
@onready var lbl_3d_stage_telemetry: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/StageOverlay/LblStageTelemetry

# Unobtrusive Top-Left Countdown HUD
@onready var countdown_panel: PanelContainer = $MarginContainer/VBoxContainer/MainBody/CenterPanel/CountdownOverlay
@onready var lbl_countdown_clock: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/CountdownOverlay/Margin/VBox/LblCountdownClock
@onready var lbl_countdown_status: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/CountdownOverlay/Margin/VBox/LblCountdownStatus

# Camera Selection HUD (5 Dedicated Views)
@onready var btn_cam_overview: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/CamSelectorBar/BtnCamOverview
@onready var btn_cam_nozzles: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/CamSelectorBar/BtnCamNozzles
@onready var btn_cam_under_rocket: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/CamSelectorBar/BtnCamUnderRocket
@onready var btn_cam_cockpit: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/CamSelectorBar/BtnCamCockpit
@onready var btn_cam_ascent: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/CamSelectorBar/BtnCamAscent

# Interactive Throttle HUD (Bottom-Right of Center Viewport)
@onready var throttle_hud: PanelContainer = $MarginContainer/VBoxContainer/MainBody/CenterPanel/ThrottleHUD
@onready var slider_throttle: VSlider = $MarginContainer/VBoxContainer/MainBody/CenterPanel/ThrottleHUD/Margin/VBox/HBoxThrottle/SliderThrottle
@onready var lbl_throttle_pct: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/ThrottleHUD/Margin/VBox/HBoxThrottle/VBoxLabels/LblThrottleVal
@onready var lbl_thrust_val: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/ThrottleHUD/Margin/VBox/HBoxThrottle/VBoxLabels/LblThrustVal
@onready var lbl_chamber_val: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/ThrottleHUD/Margin/VBox/HBoxThrottle/VBoxLabels/LblChamberVal
@onready var btn_throttle_up: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/ThrottleHUD/Margin/VBox/HBoxThrottle/VBoxButtons/BtnThrottleUp
@onready var btn_throttle_down: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/ThrottleHUD/Margin/VBox/HBoxThrottle/VBoxButtons/BtnThrottleDown
@onready var btn_clamp_release: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/ThrottleHUD/Margin/VBox/BtnClampRelease

# Right Panel: Compatibility, Trajectory & AI
@onready var lbl_spacecraft_mass: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/CompatCard/Margin/VBox/StatsGrid/LblCraftMassVal
@onready var lbl_rocket_capacity: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/CompatCard/Margin/VBox/StatsGrid/LblCapacityVal
@onready var lbl_mass_margin: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/CompatCard/Margin/VBox/StatsGrid/LblMarginVal
@onready var lbl_fairing_clearance: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/CompatCard/Margin/VBox/StatsGrid/LblFairingVal
@onready var badge_compat_status: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/CompatCard/Margin/VBox/BadgeCompatStatus
@onready var lbl_overweight_warning: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/CompatCard/Margin/VBox/LblOverweightWarning

# Trajectory Selection (Routes)
@onready var btn_route_a: Button = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/TrajectoryCard/Margin/VBox/RouteA/BtnSelectRouteA
@onready var btn_route_b: Button = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/TrajectoryCard/Margin/VBox/RouteB/BtnSelectRouteB
@onready var badge_active_route: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/TrajectoryCard/Margin/VBox/BadgeActiveRoute

# Mission AI Assistant
@onready var btn_ai_explain: Button = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/AICard/Margin/VBox/AIButtons/BtnExplain
@onready var btn_ai_hint: Button = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/AICard/Margin/VBox/AIButtons/BtnHint
@onready var btn_ai_teach: Button = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/AICard/Margin/VBox/AIButtons/BtnTeach
@onready var ai_response_panel: PanelContainer = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/AICard/Margin/VBox/AIResponsePanel
@onready var lbl_ai_response: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/AICard/Margin/VBox/AIResponsePanel/Margin/TxtAI

# Advanced Mode Tasks (Level 03)
@onready var adv_tasks_container: VBoxContainer = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/AdvTasksCard/Margin/VBox/TasksVBox
@onready var adv_input_answer: LineEdit = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/AdvTasksCard/Margin/VBox/HBoxInput/AdvInputAnswer
@onready var adv_lbl_unit: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/AdvTasksCard/Margin/VBox/HBoxInput/AdvLblUnit
@onready var adv_btn_submit: Button = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/AdvTasksCard/Margin/VBox/HBoxInput/AdvBtnSubmit
@onready var adv_lbl_feedback: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/Scroll/VBox/AdvTasksCard/Margin/VBox/AdvLblFeedback

# Bottom Panel Checklist & Launch Authorization
@onready var checklist_grid: GridContainer = $MarginContainer/VBoxContainer/BottomPanel/Margin/HBox/ChecklistPanel/Margin/VBox/ChecklistGrid
@onready var lbl_launch_auth_status: Label = $MarginContainer/VBoxContainer/BottomPanel/Margin/HBox/AuthActionPanel/Margin/VBox/LblAuthStatus
@onready var lbl_launch_auth_sub: Label = $MarginContainer/VBoxContainer/BottomPanel/Margin/HBox/AuthActionPanel/Margin/VBox/LblAuthSubtitle
@onready var btn_initiate_countdown: Button = $MarginContainer/VBoxContainer/BottomPanel/Margin/HBox/AuthActionPanel/Margin/VBox/BtnInitiateCountdown
@onready var btn_nav_back: Button = $MarginContainer/VBoxContainer/BottomPanel/Margin/HBox/NavButtons/BtnBackToLab
@onready var btn_nav_sim: Button = $MarginContainer/VBoxContainer/BottomPanel/Margin/HBox/NavButtons/BtnToSimulation

# Audio Players (Procedural Sound Engine)
var audio_beep: AudioStreamPlayer
var audio_rumble: AudioStreamPlayer
var audio_whoosh: AudioStreamPlayer
var audio_clamp: AudioStreamPlayer

# State Variables
var selected_lv_id: String = "LV_ATLAS_V_541"
var selected_route_id: String = "ROUTE_B_HOHMANN"
var spacecraft_wet_mass: float = 1850.0
var spacecraft_diameter: float = 3.80

var is_overweight: bool = false
var is_launch_authorized: bool = false
var is_countdown_running: bool = false
var countdown_time: float = 10.0
var last_second_beeped: int = 11
var ignition_triggered: bool = false
var engines_at_idle: bool = false

# Player Throttle State (0.0 to 1.0)
var player_throttle: float = 0.0
var max_rocket_thrust_kn: float = 7500.0

# Checklist Items State
var checklist_states: Dictionary = {
	"VEHICLE_ASSIGNED": false,
	"MASS_MARGIN": false,
	"FAIRING_CLEARANCE": false,
	"TRAJECTORY_LOCKED": true,
	"C3_ENERGY_VALID": true,
	"DSN_SYNC": true,
	"SYNODIC_WINDOW": true,
	"RANGE_SAFETY": true
}

# Advanced Mode Tasks
var active_adv_task_id: String = "TASK_03_01"
var lvl03_tasks: Array = []

func _ready() -> void:
	print("[LaunchPreparation] Initializing Stage D Launch Integration System...")
	_setup_audio()
	_setup_theme()
	_load_spacecraft_data()
	_populate_launch_vehicles()
	_load_advanced_tasks()
	_connect_signals()
	_select_launch_vehicle(selected_lv_id)
	_select_route(selected_route_id)
	_update_checklist()
	_update_compatibility()
	_update_authorization_status()
	_update_throttle_ui()
	countdown_panel.visible = true
	lbl_countdown_clock.text = "T - 00:10.0"
	lbl_countdown_status.text = "READY FOR COUNTDOWN"

func _setup_audio() -> void:
	audio_beep = AudioStreamPlayer.new()
	audio_beep.name = "AudioBeep"
	add_child(audio_beep)
	
	audio_rumble = AudioStreamPlayer.new()
	audio_rumble.name = "AudioRumble"
	audio_rumble.stream = LaunchAudioRef.create_engine_rumble(2.5)
	audio_rumble.volume_db = -80.0
	add_child(audio_rumble)
	
	audio_whoosh = AudioStreamPlayer.new()
	audio_whoosh.name = "AudioWhoosh"
	audio_whoosh.stream = LaunchAudioRef.create_ignition_burst()
	add_child(audio_whoosh)
	
	audio_clamp = AudioStreamPlayer.new()
	audio_clamp.name = "AudioClamp"
	audio_clamp.stream = LaunchAudioRef.create_clamp_clank()
	add_child(audio_clamp)

func _setup_theme() -> void:
	countdown_panel.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(
		Color(0.04, 0.06, 0.08, 0.85),
		MarsDeepUIRef.COLOR_CYAN,
		1, 6, 10
	))
	throttle_hud.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(
		Color(0.04, 0.06, 0.08, 0.85),
		MarsDeepUIRef.COLOR_ORANGE,
		1, 6, 10
	))

func _load_spacecraft_data() -> void:
	var gm = _get_gm()
	if gm:
		if not gm.selected_launch_vehicle_id.is_empty():
			selected_lv_id = gm.selected_launch_vehicle_id
		if not gm.selected_mission_route.is_empty():
			selected_route_id = gm.selected_mission_route
			
		var telemetry: Dictionary = gm.get_design_telemetry()
		var design_mass: float = telemetry.get("mass", {}).get("total_mass_kg", 0.0)
		if design_mass > 300.0:
			spacecraft_wet_mass = design_mass + 1050.0
		else:
			spacecraft_wet_mass = 1850.0

func _connect_signals() -> void:
	btn_top_lab.pressed.connect(_on_back_to_lab_pressed)
	btn_top_designer.pressed.connect(_on_designer_pressed)
	btn_nav_back.pressed.connect(_on_back_to_lab_pressed)
	btn_nav_sim.pressed.connect(_on_to_simulation_pressed)
	
	# Camera Views
	btn_cam_overview.pressed.connect(func(): if rocket_3d: rocket_3d.set_camera_view(0))
	btn_cam_nozzles.pressed.connect(func(): if rocket_3d: rocket_3d.set_camera_view(1))
	btn_cam_under_rocket.pressed.connect(func(): if rocket_3d: rocket_3d.set_camera_view(2))
	btn_cam_cockpit.pressed.connect(func(): if rocket_3d: rocket_3d.set_camera_view(3))
	btn_cam_ascent.pressed.connect(func(): if rocket_3d: rocket_3d.set_camera_view(4))
	
	# Throttle Controls
	slider_throttle.value_changed.connect(_on_throttle_slider_changed)
	btn_throttle_up.pressed.connect(func(): set_player_throttle(player_throttle + 0.05))
	btn_throttle_down.pressed.connect(func(): set_player_throttle(player_throttle - 0.05))
	btn_clamp_release.pressed.connect(_on_clamp_release_pressed)
	
	btn_route_a.pressed.connect(func(): _select_route("ROUTE_A_FAST"))
	btn_route_b.pressed.connect(func(): _select_route("ROUTE_B_HOHMANN"))
	
	btn_ai_explain.pressed.connect(_on_ai_explain_pressed)
	btn_ai_hint.pressed.connect(_on_ai_hint_pressed)
	btn_ai_teach.pressed.connect(_on_ai_teach_pressed)
	
	adv_btn_submit.pressed.connect(_on_adv_submit_pressed)
	adv_input_answer.text_submitted.connect(func(_t): _on_adv_submit_pressed())
	
	btn_initiate_countdown.pressed.connect(_on_initiate_countdown_pressed)
	
	if rocket_3d:
		rocket_3d.launch_animation_finished.connect(_on_liftoff_animation_complete)
		rocket_3d.meco_achieved.connect(_on_meco_achieved)

func _unhandled_input(event: InputEvent) -> void:
	# Real-time player keyboard controls for throttle & clamps
	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		if k.keycode == KEY_W or k.keycode == KEY_UP:
			set_player_throttle(player_throttle + 0.05)
		elif k.keycode == KEY_S or k.keycode == KEY_DOWN:
			set_player_throttle(player_throttle - 0.05)
		elif k.keycode == KEY_E or k.keycode == KEY_SPACE:
			if engines_at_idle and player_throttle >= 0.90:
				_on_clamp_release_pressed()

func set_player_throttle(val: float) -> void:
	player_throttle = clampf(val, 0.0, 1.0)
	slider_throttle.value = player_throttle * 100.0
	_update_throttle_ui()
	if rocket_3d:
		rocket_3d.set_throttle(player_throttle)
		
	# Adjust rumble audio volume based on throttle
	if audio_rumble and audio_rumble.playing:
		audio_rumble.volume_db = lerpf(-24.0, 4.0, player_throttle)

func _on_throttle_slider_changed(val: float) -> void:
	player_throttle = val / 100.0
	_update_throttle_ui()
	if rocket_3d:
		rocket_3d.set_throttle(player_throttle)
	if audio_rumble and audio_rumble.playing:
		audio_rumble.volume_db = lerpf(-24.0, 4.0, player_throttle)

func _update_throttle_ui() -> void:
	var pct := int(player_throttle * 100.0)
	lbl_throttle_pct.text = "%d%%" % pct
	var thrust := max_rocket_thrust_kn * player_throttle
	lbl_thrust_val.text = "%.0f kN" % thrust
	var chamber_psi := 3200.0 * player_throttle
	lbl_chamber_val.text = "%.0f PSI" % chamber_psi
	
	if engines_at_idle and not rocket_3d.are_clamps_released:
		if player_throttle >= 0.90:
			btn_clamp_release.disabled = false
			btn_clamp_release.text = "RELEASE CLAMPS (E) ▶"
			btn_clamp_release.modulate = MarsDeepUIRef.COLOR_GREEN
			lbl_countdown_status.text = "FULL THRUST NOMINAL! RELEASE CLAMPS FOR LIFTOFF!"
			lbl_countdown_status.modulate = MarsDeepUIRef.COLOR_GREEN
		else:
			btn_clamp_release.disabled = true
			btn_clamp_release.text = "THROTTLE TO 100%..."
			btn_clamp_release.modulate = MarsDeepUIRef.COLOR_YELLOW
			lbl_countdown_status.text = "ENGINES IGNITED! ADVANCE THROTTLE (W) TO 100%!"
			lbl_countdown_status.modulate = MarsDeepUIRef.COLOR_YELLOW

func _process(delta: float) -> void:
	_update_engine_audio(delta)
	if is_countdown_running:
		countdown_time -= delta
		if countdown_time > 0.0:
			lbl_countdown_clock.text = "T - %02d:%04.1f" % [int(countdown_time) / 60, fmod(countdown_time, 60.0)]
			
			# Audio countdown beeps
			var sec_int := int(ceil(countdown_time))
			if sec_int < last_second_beeped and sec_int >= 1:
				last_second_beeped = sec_int
				_play_beep(880.0 if sec_int > 3 else 1175.0)
				
			# At T-1.5s: Ignition sequence begins
			if countdown_time <= 1.5 and not ignition_triggered:
				ignition_triggered = true
				lbl_countdown_status.text = "MAIN ENGINE IGNITION • ALL SYSTEMS GO"
				lbl_countdown_status.modulate = MarsDeepUIRef.COLOR_ORANGE
				if rocket_3d:
					rocket_3d.ignite_engines(0.65)
					# Cinematic switch to Under-Rocket camera!
					rocket_3d.set_camera_view(2) # CAM_UNDER_ROCKET
				if audio_whoosh:
					audio_whoosh.play()
				if audio_rumble:
					audio_rumble.volume_db = -12.0
					audio_rumble.play()
				set_player_throttle(0.65)
		else:
			lbl_countdown_clock.text = "T + 00:00.0"
			is_countdown_running = false
			if not ignition_triggered:
				ignition_triggered = true
				if rocket_3d:
					rocket_3d.ignite_engines(0.65)
				set_player_throttle(0.65)
			engines_at_idle = true
			lbl_countdown_status.text = "ENGINES RUNNING! ADVANCE THROTTLE TO 100%!"
			lbl_countdown_status.modulate = MarsDeepUIRef.COLOR_YELLOW
			_update_throttle_ui()

func _play_beep(freq: float) -> void:
	if audio_beep:
		audio_beep.stream = LaunchAudioRef.create_beep(freq, 0.12)
		audio_beep.play()

func _update_engine_audio(delta: float) -> void:
	if not audio_rumble:
		return
	var is_active_burn: bool = (engines_at_idle or is_countdown_running or ignition_triggered or (rocket_3d and rocket_3d.are_engines_ignited)) and not (rocket_3d and rocket_3d.meco_triggered)
	
	if is_active_burn and player_throttle > 0.001:
		if not audio_rumble.playing:
			audio_rumble.volume_db = -40.0
			audio_rumble.play()
		
		# Piecewise smooth response to throttle:
		# 0%: -80dB (silent)
		# 65%: -12dB (deep idle rumble)
		# 90%: -3dB (powerful roar)
		# 100%: +2dB (maximum roar)
		var target_db: float
		if player_throttle <= 0.65:
			target_db = lerpf(-40.0, -12.0, player_throttle / 0.65)
		elif player_throttle <= 0.90:
			target_db = lerpf(-12.0, -3.0, (player_throttle - 0.65) / 0.25)
		else:
			target_db = lerpf(-3.0, 2.0, (player_throttle - 0.90) / 0.10)
			
		var target_pitch := lerpf(0.85, 1.30, player_throttle)
		
		audio_rumble.volume_db = move_toward(audio_rumble.volume_db, target_db, delta * 40.0)
		audio_rumble.pitch_scale = move_toward(audio_rumble.pitch_scale, target_pitch, delta * 3.0)
	else:
		if audio_rumble.playing:
			audio_rumble.volume_db = move_toward(audio_rumble.volume_db, -80.0, delta * 45.0)
			if audio_rumble.volume_db <= -70.0:
				audio_rumble.stop()

func _on_clamp_release_pressed() -> void:
	if not engines_at_idle or player_throttle < 0.90:
		return
	if rocket_3d and not rocket_3d.are_clamps_released:
		rocket_3d.release_clamps()
		if audio_clamp:
			audio_clamp.play()
		lbl_countdown_status.text = "CLAMPS RELEASED • LIFTOFF! MARS BOUND!"
		lbl_countdown_status.modulate = MarsDeepUIRef.COLOR_GREEN
		btn_clamp_release.disabled = true
		btn_clamp_release.text = "ASCENT IN PROGRESS"
		# Switch to tracking liftoff camera
		rocket_3d.set_camera_view(4) # TRACKING_LIFTOFF

func _on_meco_achieved() -> void:
	lbl_countdown_status.text = "STAGE 1 MECO ACHIEVED • ORBITAL INJECTION"
	lbl_countdown_status.modulate = MarsDeepUIRef.COLOR_CYAN
	_play_beep(1760.0)

# ==============================================================================
# ACTIVITY 1: CHOOSE YOUR ROCKET (LAUNCH VEHICLE SELECTION)
# ==============================================================================
func _populate_launch_vehicles() -> void:
	for child in rocket_list_vbox.get_children():
		rocket_list_vbox.remove_child(child)
		child.queue_free()
		
	var gm = _get_gm()
	var lvs: Array = gm.get_all_launch_vehicles() if gm else []
	if lvs.is_empty():
		return
		
	for lv in lvs:
		var lv_id: String = lv.get("id", "")
		var card := PanelContainer.new()
		card.name = "RocketCard_" + lv_id
		card.custom_minimum_size = Vector2(0, 110)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var is_selected := (lv_id == selected_lv_id)
		var style := MarsDeepUIRef.create_glass_card("cyan" if is_selected else "subtle")
		card.add_theme_stylebox_override("panel", style)
		
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(margin)
		
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		margin.add_child(vbox)
		
		# Title & Reliability Row
		var top_row := HBoxContainer.new()
		var lbl_name := Label.new()
		lbl_name.text = lv.get("name", "")
		lbl_name.add_theme_font_size_override("font_size", 14)
		lbl_name.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_PRIMARY)
		lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_child(lbl_name)
		
		var rel_rate: float = lv.get("reliability_rate", 0.98) * 100.0
		var lbl_rel := Label.new()
		lbl_rel.text = "%.0f%% REL" % rel_rate
		lbl_rel.add_theme_font_size_override("font_size", 12)
		lbl_rel.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_GREEN)
		top_row.add_child(lbl_rel)
		vbox.add_child(top_row)
		
		# Specs Grid Row
		var specs_grid := GridContainer.new()
		specs_grid.columns = 3
		specs_grid.add_theme_constant_override("h_separation", 16)
		specs_grid.add_theme_constant_override("v_separation", 2)
		
		var cap_kg: float = lv.get("payload_tmi_capacity_kg", 0.0)
		var cost_m: float = lv.get("cost_m", 0.0)
		var fairing_d: float = lv.get("fairing_diameter_m", 0.0)
		
		_add_spec_item(specs_grid, "TMI Capacity", "%d kg" % int(cap_kg), MarsDeepUIRef.COLOR_CYAN)
		_add_spec_item(specs_grid, "Fairing Ø", "%.1f m" % fairing_d, MarsDeepUIRef.COLOR_TEXT_SECONDARY)
		_add_spec_item(specs_grid, "Cost", "$%.1fM" % cost_m, MarsDeepUIRef.COLOR_ORANGE)
		vbox.add_child(specs_grid)
		
		# Historical missions tag
		var missions: Array = lv.get("historical_missions", [])
		if not missions.is_empty():
			var lbl_hist := Label.new()
			lbl_hist.text = "Flight Proven: %s" % ", ".join(missions)
			lbl_hist.add_theme_font_size_override("font_size", 11)
			lbl_hist.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_MUTED)
			vbox.add_child(lbl_hist)
			
		# Expandable details container
		var details_box := VBoxContainer.new()
		details_box.name = "DetailsBox"
		details_box.visible = false
		
		var sep := HSeparator.new()
		details_box.add_child(sep)
		
		var lbl_c3 := Label.new()
		lbl_c3.text = "• Characteristic Injection Energy (C3): %.1f km²/s²\n• Upper Stage: High-Isp Hydrolox Centaur / Restartable Core\n• Direct Trans-Mars Injection Certified" % lv.get("c3_capability_km2_s2", 22.0)
		lbl_c3.add_theme_font_size_override("font_size", 11)
		lbl_c3.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_CYAN)
		details_box.add_child(lbl_c3)
		vbox.add_child(details_box)
		
		# Action buttons row (Select & More Details)
		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 8)
		
		var btn_select := Button.new()
		btn_select.text = "✓ SELECTED" if is_selected else "SELECT ROCKET"
		btn_select.custom_minimum_size = Vector2(140, 28)
		btn_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if is_selected:
			btn_select.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_CYAN)
		btn_select.pressed.connect(func(): _select_launch_vehicle(lv_id))
		btn_row.add_child(btn_select)
		
		var btn_details := Button.new()
		btn_details.text = "MORE DETAILS"
		btn_details.custom_minimum_size = Vector2(110, 28)
		btn_details.pressed.connect(func():
			details_box.visible = not details_box.visible
			btn_details.text = "HIDE DETAILS" if details_box.visible else "MORE DETAILS"
		)
		btn_row.add_child(btn_details)
		
		vbox.add_child(btn_row)
		rocket_list_vbox.add_child(card)

func _add_spec_item(parent: Node, label: String, val: String, val_color: Color) -> void:
	var hbox := HBoxContainer.new()
	var l := Label.new()
	l.text = label + ": "
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_MUTED)
	hbox.add_child(l)
	
	var v := Label.new()
	v.text = val
	v.add_theme_font_size_override("font_size", 11)
	v.add_theme_color_override("font_color", val_color)
	hbox.add_child(v)
	parent.add_child(hbox)

func _select_launch_vehicle(lv_id: String) -> void:
	selected_lv_id = lv_id
	var gm = _get_gm()
	if gm:
		gm.select_launch_vehicle(lv_id)
		
	if rocket_3d:
		rocket_3d.update_rocket_model(lv_id)
		
	var lv = gm.get_launch_vehicle_by_id(lv_id) if gm else {}
	if lv:
		var name_str: String = lv.get("name", "")
		lbl_selected_rocket_quick.text = "ACTIVE VEHICLE: %s ($%.1fM)" % [name_str, lv.get("cost_m", 0.0)]
		lbl_3d_stage_telemetry.text = "VEHICLE ENVELOPE: %s\nFAIRING DIAMETER: %.1f m  •  C3 CAPABILITY: %.1f km²/s²" % [
			name_str, lv.get("fairing_diameter_m", 5.4), lv.get("c3_capability_km2_s2", 22.0)
		]
		max_rocket_thrust_kn = 7500.0 if lv_id == "LV_ATLAS_V_541" else (22800.0 if lv_id == "LV_FALCON_HEAVY" else 39000.0)
		
	_populate_launch_vehicles()
	_update_compatibility()
	_update_checklist()
	_update_authorization_status()

# ==============================================================================
# ACTIVITY 2: SPACECRAFT COMPATIBILITY CHECK
# ==============================================================================
func _update_compatibility() -> void:
	var gm = _get_gm()
	var lv = gm.get_launch_vehicle_by_id(selected_lv_id) if gm else {}
	var capacity_kg: float = lv.get("payload_tmi_capacity_kg", 2400.0)
	var fairing_dia: float = lv.get("fairing_diameter_m", 5.4)
	
	lbl_spacecraft_mass.text = "%.1f kg" % spacecraft_wet_mass
	lbl_rocket_capacity.text = "%.1f kg" % capacity_kg
	
	var clearance := fairing_dia - spacecraft_diameter
	lbl_fairing_clearance.text = "%.2f m" % clearance
	if clearance >= 1.0:
		lbl_fairing_clearance.modulate = MarsDeepUIRef.COLOR_GREEN
		checklist_states["FAIRING_CLEARANCE"] = true
	else:
		lbl_fairing_clearance.modulate = MarsDeepUIRef.COLOR_RED
		checklist_states["FAIRING_CLEARANCE"] = false
		
	var margin_pct := ((capacity_kg - spacecraft_wet_mass) / capacity_kg) * 100.0
	lbl_mass_margin.text = "%+.1f%%" % margin_pct
	
	if margin_pct < 0.0:
		is_overweight = true
		checklist_states["MASS_MARGIN"] = false
		badge_compat_status.text = "STATUS: OVERWEIGHT (LAUNCH BLOCKED)"
		badge_compat_status.modulate = MarsDeepUIRef.COLOR_RED
		lbl_mass_margin.modulate = MarsDeepUIRef.COLOR_RED
		lbl_overweight_warning.visible = true
		lbl_overweight_warning.text = "⚠ PAYLOAD EXCEEDS ROCKET TMI CAPACITY by %.1f kg!\nSelect a heavier launch vehicle (e.g. Falcon Heavy or SLS) or reduce spacecraft mass." % abs(capacity_kg - spacecraft_wet_mass)
	elif margin_pct < 15.0:
		is_overweight = false
		checklist_states["MASS_MARGIN"] = true
		badge_compat_status.text = "STATUS: CAUTION (TIGHT MASS RESERVE)"
		badge_compat_status.modulate = MarsDeepUIRef.COLOR_YELLOW
		lbl_mass_margin.modulate = MarsDeepUIRef.COLOR_YELLOW
		lbl_overweight_warning.visible = false
	else:
		is_overweight = false
		checklist_states["MASS_MARGIN"] = true
		badge_compat_status.text = "STATUS: COMPATIBLE (NOMINAL NASA RESERVE)"
		badge_compat_status.modulate = MarsDeepUIRef.COLOR_GREEN
		lbl_mass_margin.modulate = MarsDeepUIRef.COLOR_GREEN
		lbl_overweight_warning.visible = false

# ==============================================================================
# ACTIVITY 3: CHOOSE YOUR JOURNEY TO MARS (TRAJECTORY SELECTION)
# ==============================================================================
func _select_route(route_id: String) -> void:
	selected_route_id = route_id
	var gm = _get_gm()
	if gm:
		gm.select_mission_route(route_id)
		
	var is_route_a := (route_id == "ROUTE_A_FAST")
	btn_route_a.text = "✓ SELECTED (FAST TRANSIT)" if is_route_a else "SELECT ROUTE A"
	btn_route_b.text = "✓ SELECTED (HOHMANN)" if not is_route_a else "SELECT ROUTE B"
	
	if is_route_a:
		badge_active_route.text = "ACTIVE TRAJECTORY: ROUTE A (FAST TRANSIT • 180 DAYS)"
		badge_active_route.modulate = MarsDeepUIRef.COLOR_ORANGE
	else:
		badge_active_route.text = "ACTIVE TRAJECTORY: ROUTE B (HOHMANN TRANSFER • 260 DAYS)"
		badge_active_route.modulate = MarsDeepUIRef.COLOR_CYAN
		
	checklist_states["TRAJECTORY_LOCKED"] = true
	_update_checklist()
	_update_authorization_status()

# ==============================================================================
# ACTIVITY 4: PRE-LAUNCH CHECKLIST (8 ITEMS)
# ==============================================================================
func _update_checklist() -> void:
	checklist_states["VEHICLE_ASSIGNED"] = not selected_lv_id.is_empty()
	
	for child in checklist_grid.get_children():
		checklist_grid.remove_child(child)
		child.queue_free()
		
	var items: Array[Dictionary] = [
		{"id": "VEHICLE_ASSIGNED", "title": "1. Launch Vehicle Assigned", "desc": "Selected booster verified"},
		{"id": "MASS_MARGIN", "title": "2. Mass Margin Reserve > 0%", "desc": "TMI injection payload positive"},
		{"id": "FAIRING_CLEARANCE", "title": "3. Fairing Clearance Verified", "desc": "Dynamic clearance > 1.0 m"},
		{"id": "TRAJECTORY_LOCKED", "title": "4. Trajectory Solution Locked", "desc": "Direct or Hohmann departure"},
		{"id": "C3_ENERGY_VALID", "title": "5. Hyperbolic Energy C3 Valid", "desc": "C3 >= 16.5 km²/s² confirmed"},
		{"id": "DSN_SYNC", "title": "6. Deep Space Network Synced", "desc": "Goldstone, Madrid, Canberra ready"},
		{"id": "SYNODIC_WINDOW", "title": "7. Synodic Window Aligned", "desc": "780-day orbital alignment"},
		{"id": "RANGE_SAFETY", "title": "8. Range Safety Clearance", "desc": "Cape Canaveral Space Force Range"}
	]
	
	for item in items:
		var check_id: String = item["id"]
		var is_checked: bool = checklist_states.get(check_id, false)
		
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		
		var btn_check := Button.new()
		btn_check.text = "✓" if is_checked else "✕"
		btn_check.custom_minimum_size = Vector2(24, 24)
		if is_checked:
			btn_check.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_GREEN)
		else:
			btn_check.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_RED)
			
		btn_check.pressed.connect(func():
			if check_id in ["DSN_SYNC", "SYNODIC_WINDOW", "RANGE_SAFETY", "C3_ENERGY_VALID"]:
				checklist_states[check_id] = not checklist_states[check_id]
				_update_checklist()
				_update_authorization_status()
		)
		hbox.add_child(btn_check)
		
		var lbl := Label.new()
		lbl.text = item["title"]
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_PRIMARY if is_checked else MarsDeepUIRef.COLOR_TEXT_MUTED)
		hbox.add_child(lbl)
		
		checklist_grid.add_child(hbox)

# ==============================================================================
# ACTIVITY 5: LAUNCH AUTHORIZATION & COUNTDOWN
# ==============================================================================
func _update_authorization_status() -> void:
	var all_checked := true
	for k in checklist_states:
		if not checklist_states[k]:
			all_checked = false
			break
			
	if not is_overweight and all_checked:
		is_launch_authorized = true
		lbl_launch_auth_status.text = "LAUNCH AUTHORIZATION: APPROVED"
		lbl_launch_auth_status.modulate = MarsDeepUIRef.COLOR_GREEN
		lbl_launch_auth_sub.text = "All 8 pre-launch criteria nominal. Cape Canaveral Range Safety reports GREEN."
		lbl_auth_badge.text = "AUTHORIZATION: APPROVED ✓"
		lbl_auth_badge.modulate = MarsDeepUIRef.COLOR_GREEN
		btn_initiate_countdown.disabled = false
		btn_initiate_countdown.text = "INITIATE COUNTDOWN ▶"
	else:
		is_launch_authorized = false
		lbl_launch_auth_status.text = "LAUNCH AUTHORIZATION: BLOCKED"
		lbl_launch_auth_status.modulate = MarsDeepUIRef.COLOR_RED
		if is_overweight:
			lbl_launch_auth_sub.text = "HOLD: Spacecraft payload mass exceeds launch vehicle TMI injection capacity!"
		else:
			lbl_launch_auth_sub.text = "HOLD: One or more pre-launch checklist criteria unresolved."
		lbl_auth_badge.text = "AUTHORIZATION: BLOCKED ✕"
		lbl_auth_badge.modulate = MarsDeepUIRef.COLOR_RED
		btn_initiate_countdown.disabled = true
		btn_initiate_countdown.text = "COUNTDOWN BLOCKED"

func _on_initiate_countdown_pressed() -> void:
	if not is_launch_authorized or is_countdown_running:
		return
		
	is_countdown_running = true
	countdown_time = 10.0
	last_second_beeped = 11
	ignition_triggered = false
	engines_at_idle = false
	countdown_panel.visible = true
	btn_initiate_countdown.disabled = true
	btn_initiate_countdown.text = "COUNTDOWN IN PROGRESS..."
	lbl_countdown_status.text = "TERMINAL COUNTDOWN INITIATED • T-10s"

func _on_liftoff_animation_complete() -> void:
	print("[LaunchPreparation] Liftoff sequence completed! Navigating to Mission Simulation...")
	get_tree().change_scene_to_file("res://scenes/MissionSimulation.tscn")

# ==============================================================================
# MISSION AI ASSISTANT
# ==============================================================================
func _on_ai_explain_pressed() -> void:
	ai_response_panel.visible = true
	lbl_ai_response.text = "MISSION AI // EXPLANATION:\n" + \
		"To reach Mars, a rocket must accelerate a spacecraft beyond Earth's gravity well using Trans-Mars Injection (TMI).\n\n" + \
		"• Capacity vs Weight: If your spacecraft is heavier than the rocket's TMI capacity, the upper stage cannot reach escape velocity.\n" + \
		"• Route Comparison: Route A (Fast Transit) reaches Mars in 180 days, reducing radiation dose, but consumes 40% more fuel. Route B (Hohmann) is the fuel-saving minimum energy transfer orbit taking 260 days."

func _on_ai_hint_pressed() -> void:
	ai_response_panel.visible = true
	lbl_ai_response.text = "MISSION AI // HINT:\n" + \
		"• If your spacecraft mass is close to 1850 kg, the Atlas V 541 (2400 kg capacity) provides a healthy 22.9% mass reserve margin.\n" + \
		"• Falcon Heavy gives the lowest launch cost per kilogram ($120M for 4500 kg capacity).\n" + \
		"• Make sure Fairing Clearance is at least 1.0 meter so dynamic acoustic vibrations during ascent do not damage the solar arrays."

func _on_ai_teach_pressed() -> void:
	ai_response_panel.visible = true
	lbl_ai_response.text = "MISSION AI // WORKED EXAMPLE (MASS RESERVE MARGIN):\n" + \
		"Formula: Margin % = ((Rocket Capacity - Spacecraft Mass) / Rocket Capacity) * 100\n\n" + \
		"Example:\n" + \
		"• Rocket TMI Capacity = 2400 kg\n" + \
		"• Spacecraft Wet Mass = 1850 kg\n" + \
		"1. Difference = 2400 - 1850 = 550 kg reserve\n" + \
		"2. Margin % = (550 / 2400) * 100 = 22.92%\n\n" + \
		"NASA guidelines recommend keeping at least a +15% mass margin to account for trajectory correction maneuvers!"

# ==============================================================================
# ADVANCED MODE: LEVEL 03 CALCULATION TASKS
# ==============================================================================
func _load_advanced_tasks() -> void:
	var gm = _get_gm()
	if not gm or not gm.progress:
		return
	lvl03_tasks = gm.progress.get_tasks_for_level("LVL_03")
	_populate_adv_task_buttons()
	if not lvl03_tasks.is_empty():
		_select_adv_task(lvl03_tasks[0].get("id", "TASK_03_01"))

func _populate_adv_task_buttons() -> void:
	for child in adv_tasks_container.get_children():
		adv_tasks_container.remove_child(child)
		child.queue_free()
		
	var gm = _get_gm()
	for task in lvl03_tasks:
		var t_id: String = task.get("id", "")
		var is_done: bool = gm.is_task_completed(t_id) if gm else false
		var is_active := (t_id == active_adv_task_id)
		
		var btn := Button.new()
		btn.text = "%s %s" % ["✓" if is_done else "•", task.get("name", t_id)]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if is_done:
			btn.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_GREEN)
		elif is_active:
			btn.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_CYAN)
		btn.pressed.connect(func(): _select_adv_task(t_id))
		adv_tasks_container.add_child(btn)

func _select_adv_task(task_id: String) -> void:
	active_adv_task_id = task_id
	var gm = _get_gm()
	var task: Dictionary = gm.progress.get_task(task_id) if (gm and gm.progress) else {}
	if task:
		adv_lbl_unit.text = task.get("unit", "")
		adv_lbl_feedback.text = "TASK DESCRIPTION: %s\nHint: %s" % [task.get("description", ""), task.get("formula_hint", "")]
		adv_lbl_feedback.modulate = MarsDeepUIRef.COLOR_TEXT_SECONDARY
	_populate_adv_task_buttons()

func _on_adv_submit_pressed() -> void:
	var input_val := adv_input_answer.text.strip_edges()
	var gm = _get_gm()
	if not gm:
		return
		
	var result: Dictionary = gm.submit_task_calculation("LVL_03", active_adv_task_id, input_val)
	var is_valid: bool = result.get("is_valid", false)
	var msg: String = result.get("message", "")
	
	if is_valid:
		adv_lbl_feedback.text = "✓ %s" % msg
		adv_lbl_feedback.modulate = MarsDeepUIRef.COLOR_GREEN
	else:
		adv_lbl_feedback.text = "✕ %s" % msg
		adv_lbl_feedback.modulate = MarsDeepUIRef.COLOR_RED
		
	_populate_adv_task_buttons()

# ==============================================================================
# NAVIGATION
# ==============================================================================
func _on_back_to_lab_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/EngineeringLab.tscn")

func _on_designer_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MissionDesign.tscn")

func _on_to_simulation_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MissionSimulation.tscn")
