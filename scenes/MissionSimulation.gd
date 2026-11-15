extends Control

## MissionSimulation.gd - Interplanetary Spaceflight Simulator Controller for MARS DEEP
## Integrates 3D cockpit & deep-space simulation, flight controls, mission events, and Level 04 progression.

const GameManagerRef = preload("res://scripts/GameManager.gd")
const LaunchAudioRef = preload("res://scripts/LaunchAudio.gd")
const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")

var _gm_cache: Node = null
func _get_gm() -> Node:
	if _gm_cache:
		return _gm_cache
	if Engine.has_singleton("GameManager"):
		_gm_cache = Engine.get_singleton("GameManager")
	elif is_inside_tree() and get_tree().root.has_node("GameManager"):
		_gm_cache = get_tree().root.get_node("GameManager")
	return _gm_cache

# Node References - Viewport & 3D Spaceflight
@onready var subviewport: SubViewport = $MarginContainer/VBoxContainer/MainBody/ViewportContainer/SubViewport
@onready var space_3d: Node3D = $MarginContainer/VBoxContainer/MainBody/ViewportContainer/SubViewport/SpaceFlight3D

# Header & Navigation
@onready var lbl_header_title: Label = $MarginContainer/VBoxContainer/Header/TitleVBox/Title
@onready var lbl_header_subtitle: Label = $MarginContainer/VBoxContainer/Header/TitleVBox/Subtitle
@onready var badge_phase: Label = $MarginContainer/VBoxContainer/Header/TopNav/PhaseBadge
@onready var badge_route: Label = $MarginContainer/VBoxContainer/Header/TopNav/RouteBadge
@onready var btn_nav_back: Button = $MarginContainer/VBoxContainer/Header/TopNav/BtnBackLaunch
@onready var btn_nav_next: Button = $MarginContainer/VBoxContainer/Header/TopNav/BtnToExploration

# Camera Switcher Bar
@onready var btn_cam_cockpit: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/CameraBar/BtnCamCockpit
@onready var btn_cam_exterior: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/CameraBar/BtnCamExterior
@onready var btn_cam_nav_map: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/CameraBar/BtnCamNavMap
@onready var btn_cam_mars: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/CameraBar/BtnCamMars

# Time Warp Bar
@onready var btn_warp_1x: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/WarpBar/BtnWarp1x
@onready var btn_warp_10x: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/WarpBar/BtnWarp10x
@onready var btn_warp_event: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/WarpBar/BtnWarpEvent

# Radio Communication HUD (Upper Left)
@onready var radio_panel: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RadioPanel
@onready var lbl_radio_speaker: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RadioPanel/Margin/VBox/LblSpeaker
@onready var lbl_radio_message: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RadioPanel/Margin/VBox/LblMessage

# Flight Telemetry HUD (Upper Right)
@onready var telemetry_panel: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/TelemetryPanel
@onready var lbl_speed_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/TelemetryPanel/Margin/VBox/Grid/LblSpeedVal
@onready var lbl_dist_earth_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/TelemetryPanel/Margin/VBox/Grid/LblDistEarthVal
@onready var lbl_dist_mars_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/TelemetryPanel/Margin/VBox/Grid/LblDistMarsVal
@onready var lbl_propellant_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/TelemetryPanel/Margin/VBox/Grid/LblPropellantVal
@onready var lbl_met_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/TelemetryPanel/Margin/VBox/Grid/LblMETVal
@onready var lbl_power_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/TelemetryPanel/Margin/VBox/Grid/LblPowerVal

# Interactive Flight Console HUD (Bottom Right)
@onready var console_panel: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/FlightConsolePanel
@onready var slider_throttle: VSlider = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/FlightConsolePanel/Margin/VBox/HBoxThrottle/SliderThrottle
@onready var lbl_throttle_pct: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/FlightConsolePanel/Margin/VBox/HBoxThrottle/VBoxLabels/LblThrottleVal
@onready var lbl_thrust_kn: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/FlightConsolePanel/Margin/VBox/HBoxThrottle/VBoxLabels/LblThrustVal
@onready var btn_throttle_up: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/FlightConsolePanel/Margin/VBox/HBoxThrottle/VBoxButtons/BtnThrottleUp
@onready var btn_throttle_down: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/FlightConsolePanel/Margin/VBox/HBoxThrottle/VBoxButtons/BtnThrottleDown
@onready var btn_arm_burn: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/FlightConsolePanel/Margin/VBox/BtnArmBurn
@onready var btn_execute_burn: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/FlightConsolePanel/Margin/VBox/BtnExecuteBurn

# Decision & Event Overlays
@onready var modal_departure: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDeparture
@onready var btn_confirm_departure: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDeparture/Margin/VBox/BtnConfirmDeparture

@onready var modal_maneuver: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalManeuver
@onready var lbl_maneuver_countdown: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalManeuver/Margin/VBox/LblManeuverCountdown
@onready var lbl_maneuver_status: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalManeuver/Margin/VBox/LblManeuverStatus
@onready var btn_retrograde_burn: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalManeuver/Margin/VBox/HBoxButtons/BtnRetrogradeBurn
@onready var btn_recover_maneuver: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalManeuver/Margin/VBox/HBoxButtons/BtnRecoverManeuver

@onready var modal_midcourse: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalMidcourse
@onready var btn_mcc_opt1: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalMidcourse/Margin/VBox/OptionsVBox/BtnOpt1
@onready var btn_mcc_opt2: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalMidcourse/Margin/VBox/OptionsVBox/BtnOpt2
@onready var btn_mcc_opt3: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalMidcourse/Margin/VBox/OptionsVBox/BtnOpt3
@onready var input_mcc_adv: LineEdit = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalMidcourse/Margin/VBox/AdvVBox/HBox/InputAdvAnswer
@onready var btn_submit_mcc_adv: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalMidcourse/Margin/VBox/AdvVBox/HBox/BtnSubmitAdv

@onready var modal_events: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalEvents
@onready var lbl_event_title: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalEvents/Margin/VBox/LblEventTitle
@onready var lbl_event_desc: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalEvents/Margin/VBox/LblEventDesc
@onready var btn_resolve_event: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalEvents/Margin/VBox/BtnResolveEvent

@onready var modal_mars_arrival: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalMarsArrival
@onready var lbl_attitude_guidance: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalMarsArrival/Margin/VBox/LblAttitudeGuidance
@onready var lbl_attitude_status: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalMarsArrival/Margin/VBox/LblAttitudeStatus
@onready var btn_align_attitude_helper: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalMarsArrival/Margin/VBox/BtnAlignAttitudeHelper
@onready var progress_bar_moi: ProgressBar = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalMarsArrival/Margin/VBox/ProgressBarMOI
@onready var btn_arm_moi: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalMarsArrival/Margin/VBox/HBoxMOIActions/BtnArmMOI
@onready var btn_execute_moi: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalMarsArrival/Margin/VBox/HBoxMOIActions/BtnExecuteMOI

@onready var banner_orbit_achieved: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/BannerOrbitAchieved
@onready var btn_continue_mars: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/BannerOrbitAchieved/Margin/VBox/BtnContinueMars

# Simulation Controller State
var is_propulsion_armed: bool = false
var is_moi_armed: bool = false
var is_moi_burning: bool = false
var is_maneuver_burning: bool = false
var current_warp_factor: float = 1.0
var active_event_type: String = ""
var level_04_completed: bool = false

func _ready() -> void:
	print("[MissionSimulation] Initializing Stage E Spaceflight Simulation Controller...")
	_apply_styling()
	_connect_signals()
	_initialize_mission_data()

func _apply_styling() -> void:
	# Header & badges
	if badge_phase:
		badge_phase.add_theme_stylebox_override("normal", MarsDeepUIRef.create_panel_style(Color(0.05, 0.1, 0.15, 0.85), MarsDeepUIRef.COLOR_CYAN, 1, 4, 8))
	if badge_route:
		badge_route.add_theme_stylebox_override("normal", MarsDeepUIRef.create_panel_style(Color(0.12, 0.08, 0.04, 0.85), MarsDeepUIRef.COLOR_ORANGE, 1, 4, 8))
		
	# Panels
	if radio_panel:
		radio_panel.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.04, 0.08, 0.12, 0.9), MarsDeepUIRef.COLOR_CYAN, 1))
	if telemetry_panel:
		telemetry_panel.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.04, 0.06, 0.1, 0.9), MarsDeepUIRef.COLOR_BORDER_SUBTLE, 1))
	if console_panel:
		console_panel.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.05, 0.07, 0.11, 0.9), MarsDeepUIRef.COLOR_ORANGE, 1))
		
	# Buttons
	if btn_execute_burn:
		btn_execute_burn.add_theme_stylebox_override("normal", MarsDeepUIRef.create_button_style(Color(0.85, 0.35, 0.05, 0.8), MarsDeepUIRef.COLOR_ORANGE, 2))
		btn_execute_burn.disabled = true

func _connect_signals() -> void:
	if space_3d:
		space_3d.telemetry_changed.connect(_on_3d_telemetry_changed)
		space_3d.phase_advanced.connect(_on_3d_phase_advanced)
		space_3d.burn_started.connect(_on_3d_burn_started)
		space_3d.burn_completed.connect(_on_3d_burn_completed)
		
	# Camera buttons
	if btn_cam_cockpit: btn_cam_cockpit.pressed.connect(func(): space_3d.set_camera_view(0))
	if btn_cam_exterior: btn_cam_exterior.pressed.connect(func(): space_3d.set_camera_view(1))
	if btn_cam_nav_map: btn_cam_nav_map.pressed.connect(func(): space_3d.set_camera_view(2))
	if btn_cam_mars: btn_cam_mars.pressed.connect(func(): space_3d.set_camera_view(3))
	
	# Time Warp buttons
	if btn_warp_1x: btn_warp_1x.pressed.connect(func(): _set_time_warp(1.0))
	if btn_warp_10x: btn_warp_10x.pressed.connect(func(): _set_time_warp(10.0))
	if btn_warp_event: btn_warp_event.pressed.connect(_on_warp_to_next_event_pressed)
	
	# Throttle & Console
	if slider_throttle:
		slider_throttle.value_changed.connect(_on_throttle_slider_changed)
	if btn_throttle_up:
		btn_throttle_up.pressed.connect(func(): _step_throttle(0.05))
	if btn_throttle_down:
		btn_throttle_down.pressed.connect(func(): _step_throttle(-0.05))
	if btn_arm_burn:
		btn_arm_burn.pressed.connect(_toggle_arm_burn)
	if btn_execute_burn:
		btn_execute_burn.pressed.connect(_on_execute_burn_pressed)
		
	# Modals & Decisions
	if btn_confirm_departure:
		btn_confirm_departure.pressed.connect(_on_confirm_departure_pressed)
	if btn_retrograde_burn:
		btn_retrograde_burn.pressed.connect(_on_retrograde_burn_pressed)
	if btn_recover_maneuver:
		btn_recover_maneuver.pressed.connect(_on_recover_maneuver_pressed)
	if btn_align_attitude_helper:
		btn_align_attitude_helper.pressed.connect(_on_align_attitude_helper_pressed)
	if btn_arm_moi:
		btn_arm_moi.pressed.connect(_toggle_arm_moi)
	if btn_execute_moi:
		btn_execute_moi.pressed.connect(_on_execute_moi_pressed)
	if btn_continue_mars:
		btn_continue_mars.pressed.connect(_on_continue_to_mars_exploration_pressed)
	if btn_mcc_opt1:
		btn_mcc_opt1.pressed.connect(func(): _on_mcc_choice_selected(15.0, 12.1))
	if btn_mcc_opt2:
		btn_mcc_opt2.pressed.connect(func(): _on_mcc_choice_selected(10.0, 8.1))
	if btn_mcc_opt3:
		btn_mcc_opt3.pressed.connect(func(): _on_mcc_choice_selected(25.0, 20.1))
	if btn_submit_mcc_adv:
		btn_submit_mcc_adv.pressed.connect(_on_submit_mcc_adv_pressed)
	if btn_resolve_event:
		btn_resolve_event.pressed.connect(_on_resolve_event_pressed)
		
	# Navigation
	if btn_nav_back:
		btn_nav_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LaunchPreparation.tscn"))
	if btn_nav_next:
		btn_nav_next.pressed.connect(_on_continue_to_mars_exploration_pressed)

func _initialize_mission_data() -> void:
	var gm = _get_gm()
	if gm:
		var route: Dictionary = gm.get_selected_mission_route()
		var r_name: String = route.get("name", "Hohmann Transfer")
		var r_days: int = route.get("duration_days", 260)
		badge_route.text = "TRAJECTORY: %s (%dd)" % [r_name.to_upper(), r_days]
		
		# Initial mission control radio transmission
		_broadcast_radio("FLIGHT DIRECTOR (HOUSTON)", "Earth orbital insertion confirmed. Spacecraft systems nominal. Prepare for Trans-Mars Injection (TMI).")
		
		# Show initial departure dialog
		modal_departure.visible = true

func _unhandled_input(event: InputEvent) -> void:
	# Flight controls keyboard shortcuts
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_W, KEY_UP:
				_step_throttle(0.05)
			KEY_S, KEY_DOWN:
				_step_throttle(-0.05)
			KEY_A, KEY_LEFT:
				if space_3d: space_3d.apply_yaw_input(1.0)
			KEY_D, KEY_RIGHT:
				if space_3d: space_3d.apply_yaw_input(-1.0)
			KEY_Q:
				if space_3d: space_3d.apply_roll_input(1.0)
			KEY_E:
				if space_3d: space_3d.apply_roll_input(-1.0)
			KEY_C:
				if space_3d: space_3d.cycle_camera_view()
			KEY_SPACE:
				if is_propulsion_armed:
					_on_execute_burn_pressed()
			KEY_1:
				if space_3d: space_3d.set_camera_view(0)
			KEY_2:
				if space_3d: space_3d.set_camera_view(1)
			KEY_3:
				if space_3d: space_3d.set_camera_view(2)
			KEY_4:
				if space_3d: space_3d.set_camera_view(3)
				
	# Mouse look in Cockpit & Exterior
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if space_3d:
			space_3d.handle_cockpit_look(mm.relative)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if space_3d: space_3d.is_mouse_dragging = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			if space_3d: space_3d.handle_zoom(-0.5)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			if space_3d: space_3d.handle_zoom(0.5)

# =========================================================================
# TELEMETRY & FLIGHT FEEDBACK
# =========================================================================

func _on_3d_telemetry_changed(data: Dictionary) -> void:
	if lbl_speed_val:
		lbl_speed_val.text = "%.2f km/s" % data.get("velocity_kms", 0.0)
	if lbl_dist_earth_val:
		var d_earth: float = data.get("distance_earth_km", 0.0)
		lbl_dist_earth_val.text = "%.0f km" % d_earth if d_earth < 1000000.0 else "%.2f M km" % (d_earth / 1000000.0)
	if lbl_dist_mars_val:
		var d_mars: float = data.get("distance_mars_km", 0.0)
		lbl_dist_mars_val.text = "%.0f km" % d_mars if d_mars < 1000000.0 else "%.2f M km" % (d_mars / 1000000.0)
	if lbl_propellant_val:
		lbl_propellant_val.text = "%.1f kg (%.0f%%)" % [data.get("propellant_kg", 0.0), data.get("propellant_pct", 100.0)]
	if lbl_met_val:
		lbl_met_val.text = "DAY %03d / %03d" % [int(data.get("mission_day", 0.0)), int(data.get("total_days", 260.0))]
	if lbl_power_val:
		lbl_power_val.text = "+%.0f W (Net)" % data.get("net_power_w", 275.0)
		
	# Throttle HUD
	var throt_pct: int = data.get("throttle_pct", 0)
	if lbl_throttle_pct:
		lbl_throttle_pct.text = "%d%%" % throt_pct
	if lbl_thrust_kn:
		var thrust_kn: float = data.get("thrust_kn", 0.0)
		lbl_thrust_kn.text = "%.1f kN" % thrust_kn
	if slider_throttle and not slider_throttle.has_focus():
		slider_throttle.value = float(throt_pct)
		
	# Maneuver Window UI Updates (Stage I Part 1)
	if modal_maneuver and modal_maneuver.visible:
		var cd: float = data.get("maneuver_countdown_s", 0.0)
		var v_cur: float = data.get("velocity_kms", 11.24)
		var v_tgt: float = data.get("target_cutoff_velocity_kms", 9.85)
		var missed: bool = data.get("maneuver_missed", false)
		
		if lbl_maneuver_countdown:
			lbl_maneuver_countdown.text = "WINDOW T-MINUS: %.1fs • CURRENT: %.2f km/s • TARGET: %.2f km/s" % [cd, v_cur, v_tgt]
			
		if missed:
			if lbl_maneuver_status:
				lbl_maneuver_status.text = "MANEUVER WINDOW OVERRUN! Trajectory divergence. Execute recovery burn."
				lbl_maneuver_status.modulate = MarsDeepUIRef.COLOR_RED
			if btn_recover_maneuver:
				btn_recover_maneuver.visible = true
				btn_recover_maneuver.disabled = false
		elif is_maneuver_burning:
			if lbl_maneuver_status:
				lbl_maneuver_status.text = "RETROGRADE BURN ACTIVE: Velocity decreasing opposite to flight direction..."
				lbl_maneuver_status.modulate = MarsDeepUIRef.COLOR_CYAN
			# Complete burn when cutoff velocity is achieved
			if v_cur <= (v_tgt + 0.05):
				_complete_maneuver_burn()
				
	# Mars Approach Attitude Guidance Updates (Stage I Part 2)
	if modal_mars_arrival and modal_mars_arrival.visible:
		var err_rad: float = data.get("attitude_alignment_error", 1.0)
		var is_aligned: bool = data.get("is_attitude_aligned", false)
		var cur_p: float = data.get("current_pitch_deg", 0.0)
		var cur_y: float = data.get("current_yaw_deg", 0.0)
		var tgt_p: float = data.get("target_moi_pitch_deg", -18.0)
		var tgt_y: float = data.get("target_moi_yaw_deg", 25.0)
		
		if lbl_attitude_guidance:
			lbl_attitude_guidance.text = "TARGET: Pitch %+.1f°, Yaw %+.1f° | CURRENT: Pitch %+.1f°, Yaw %+.1f°" % [tgt_p, tgt_y, cur_p, cur_y]
		if lbl_attitude_status:
			if is_aligned:
				lbl_attitude_status.text = "ATTITUDE ALIGNED [LOCKED] • READY FOR RETROGRADE INSERTION BURN"
				lbl_attitude_status.modulate = MarsDeepUIRef.COLOR_GREEN
			else:
				var err_deg := rad_to_deg(err_rad)
				lbl_attitude_status.text = "ATTITUDE MISALIGNED (Error: %.1f°) • Steer with A/D (Yaw), W/S (Pitch)" % err_deg
				lbl_attitude_status.modulate = MarsDeepUIRef.COLOR_ORANGE
		if btn_arm_moi and not is_moi_armed:
			btn_arm_moi.disabled = false

func _on_3d_phase_advanced(phase: int) -> void:
	if badge_phase and space_3d:
		badge_phase.text = "PHASE: " + space_3d.get_phase_name()

func _on_3d_burn_started(burn_name: String) -> void:
	_broadcast_radio("FLIGHT DYNAMICS", "Main engine burn initiated: %s. Telemetry active." % burn_name)

func _on_3d_burn_completed(burn_name: String) -> void:
	_broadcast_radio("CAPCOM", "Burn cutoff verified: %s complete. Trajectory locked." % burn_name)

# =========================================================================
# RADIO BROADCASTS
# =========================================================================

func _broadcast_radio(speaker: String, message: String) -> void:
	if lbl_radio_speaker:
		lbl_radio_speaker.text = speaker
	if lbl_radio_message:
		lbl_radio_message.text = message
	if space_3d and space_3d.audio_comms:
		space_3d.audio_comms.play()

# =========================================================================
# TIME WARP & THROTTLE CONTROLS
# =========================================================================

func _set_time_warp(scale_factor: float) -> void:
	current_warp_factor = scale_factor
	if space_3d:
		space_3d.time_warp_scale = scale_factor
	print("[MissionSimulation] Time Warp Factor set to %.1fx." % scale_factor)

func _step_throttle(delta_pct: float) -> void:
	if space_3d:
		space_3d.step_throttle(delta_pct)

func _on_throttle_slider_changed(val: float) -> void:
	if space_3d:
		space_3d.set_throttle(val / 100.0)

func _toggle_arm_burn() -> void:
	is_propulsion_armed = not is_propulsion_armed
	if is_propulsion_armed:
		btn_arm_burn.text = "DISARM PROPULSION"
		btn_arm_burn.modulate = MarsDeepUIRef.COLOR_RED
		btn_execute_burn.disabled = false
		btn_execute_burn.modulate = MarsDeepUIRef.COLOR_GREEN
	else:
		btn_arm_burn.text = "ARM PROPULSION"
		btn_arm_burn.modulate = Color.WHITE
		btn_execute_burn.disabled = true
		btn_execute_burn.modulate = Color.WHITE

func _on_execute_burn_pressed() -> void:
	if not is_propulsion_armed:
		return
	_step_throttle(1.0) # Full thrust
	print("[MissionSimulation] Player executed armed manual burn.")

# =========================================================================
# MISSION WORKFLOW & DECISION EVENTS
# =========================================================================

func _on_confirm_departure_pressed() -> void:
	modal_departure.visible = false
	if space_3d:
		space_3d.set_flight_phase(1) # EARTH_DEPARTURE (TMI)
	_broadcast_radio("CAPCOM", "Earth departure confirmed. Trans-Mars Injection burn active. Godspeed Mars Deep!")
	
	# Prompt player with upcoming maneuver braking window after departure acceleration
	var tw := create_tween()
	tw.tween_interval(1.8)
	tw.tween_callback(func():
		_trigger_maneuver_window()
	)

func _trigger_maneuver_window() -> void:
	if space_3d:
		space_3d.trigger_maneuver_window(12.0)
		if space_3d.audio_alarm:
			space_3d.audio_alarm.play()
	if modal_maneuver:
		modal_maneuver.visible = true
	if btn_recover_maneuver:
		btn_recover_maneuver.visible = false
	_broadcast_radio("FLIGHT DYNAMICS", "APPROACHING MANEUVER WINDOW! Prepare to reduce forward thrust and initiate retrograde burn.")

func _on_retrograde_burn_pressed() -> void:
	if not space_3d:
		return
	# Check forward throttle
	if space_3d.throttle > 0.05:
		if lbl_maneuver_status:
			lbl_maneuver_status.text = "ERROR: Reduce forward throttle lever to 0% before initiating retrograde burn!"
			lbl_maneuver_status.modulate = MarsDeepUIRef.COLOR_RED
		return
		
	is_maneuver_burning = true
	space_3d.set_retrograde_burn(true, 1.0)
	if lbl_maneuver_status:
		lbl_maneuver_status.text = "RETROGRADE BURN ACTIVE: Decelerating opposite to flight direction to 9.85 km/s..."
		lbl_maneuver_status.modulate = MarsDeepUIRef.COLOR_CYAN

func _on_recover_maneuver_pressed() -> void:
	if space_3d:
		space_3d.recover_maneuver_burn()
	_complete_maneuver_burn()
	_broadcast_radio("CAPCOM", "Emergency trajectory recovery burn complete. Re-entering planned Hohmann cruise.")

func _complete_maneuver_burn() -> void:
	is_maneuver_burning = false
	if space_3d:
		space_3d.set_retrograde_burn(false)
		space_3d.set_flight_phase(2) # INTERPLANETARY_CRUISE
	if modal_maneuver:
		modal_maneuver.visible = false
	_broadcast_radio("FLIGHT DIRECTOR", "Retrograde maneuver cutoff confirmed! Spacecraft has entered deep space Hohmann cruise.")
	
	# Complete Level 04 Task 1 in GameManager
	var gm = _get_gm()
	if gm and gm.has_method("submit_task_calculation"):
		gm.submit_task_calculation("LVL_04", "TASK_04_01", 258.8)

func _on_warp_to_next_event_pressed() -> void:
	if not space_3d:
		return
		
	match space_3d.current_phase:
		0, 1: # Pre-Departure
			_on_confirm_departure_pressed()
		2: # In Cruise
			if space_3d.mission_day < 40.0:
				_trigger_midcourse_correction()
			elif space_3d.mission_day < 120.0:
				_trigger_mission_event("SOLAR_DRIFT")
			else:
				_trigger_mars_arrival()
		3: # Post-MCC -> Trigger Space Mission Event
			_trigger_mission_event("SOLAR_DRIFT")
		4: # Mars Approach -> Open MOI dialog
			_trigger_mars_arrival()
		5, 6:
			pass

func _trigger_midcourse_correction() -> void:
	if space_3d:
		space_3d.set_flight_phase(3) # MIDCOURSE_CORRECTION
	modal_midcourse.visible = true
	_broadcast_radio("FLIGHT DYNAMICS", "Navigation deviation detected at Day 35. Mid-course correction (TCM-1) required.")
	if space_3d and space_3d.audio_alarm:
		space_3d.audio_alarm.play()

func _on_mcc_choice_selected(dv: float, fuel: float) -> void:
	modal_midcourse.visible = false
	if space_3d:
		space_3d.execute_midcourse_burn(dv, fuel)
	_broadcast_radio("CAPCOM", "Executing TCM-1 burn: %.1f m/s (%.1f kg hydrazine). Trajectory realigned." % [dv, fuel])
	
	# Submit Task 04_02
	var gm = _get_gm()
	if gm and gm.has_method("submit_task_calculation"):
		gm.submit_task_calculation("LVL_04", "TASK_04_02", 12.1)

func _on_submit_mcc_adv_pressed() -> void:
	if not input_mcc_adv:
		return
	var val_str := input_mcc_adv.text.strip_edges()
	var gm = _get_gm()
	if gm and gm.has_method("submit_task_calculation"):
		var res: Dictionary = gm.submit_task_calculation("LVL_04", "TASK_04_02", val_str)
		if res.get("is_valid", false):
			_on_mcc_choice_selected(15.0, 12.1)
		else:
			_broadcast_radio("FLIGHT DYNAMICS", "Calculation rejected: " + res.get("message", "Check formula."))

func _trigger_mission_event(evt_type: String) -> void:
	active_event_type = evt_type
	modal_events.visible = true
	
	match evt_type:
		"SOLAR_DRIFT":
			lbl_event_title.text = "EVENT: SOLAR ARRAY TRACKING DRIFT"
			lbl_event_desc.text = "Solar array sun-tracking servo has drifted off the Sun vector. Power generation reduced to 180W. Realign panels to restore full charging."
			btn_resolve_event.text = "REALIGN SOLAR PANELS TO SUN"
		"DSN_LOSS":
			lbl_event_title.text = "EVENT: DEEP SPACE NETWORK PATH LOSS"
			lbl_event_desc.text = "Distance to Earth exceeded 150M km. Carrier signal attenuation detected. Optimize high-gain parabolic dish alignment (TASK_04_03: 276.9 dB)."
			btn_resolve_event.text = "OPTIMIZE HIGH-GAIN ANTENNA DISH"
		"RADIATION_STORM":
			lbl_event_title.text = "EVENT: SOLAR PARTICLE STORM WARNING"
			lbl_event_desc.text = "Coronal mass ejection detected along trajectory. Total expected cruise dose: 468 mSv (TASK_04_04). Orient aft heat shield towards Sun."
			btn_resolve_event.text = "ORIENT AFT STORM SHIELD TO SUN"

func _on_resolve_event_pressed() -> void:
	modal_events.visible = false
	var gm = _get_gm()
	
	match active_event_type:
		"SOLAR_DRIFT":
			if space_3d: space_3d.resolve_solar_tracking()
			_broadcast_radio("CAPCOM", "Solar arrays realigned to solar vector. Full 460W charging restored.")
			# Chain to next event or approach
			var tw := create_tween()
			tw.tween_interval(2.0)
			tw.tween_callback(func(): _trigger_mission_event("DSN_LOSS"))
		"DSN_LOSS":
			if gm and gm.has_method("submit_task_calculation"):
				gm.submit_task_calculation("LVL_04", "TASK_04_03", 276.9)
			_broadcast_radio("CAPCOM", "High-gain dish signal locked. DSN X-Band link nominal (276.9 dB path loss compensated).")
			var tw := create_tween()
			tw.tween_interval(2.0)
			tw.tween_callback(func(): _trigger_mission_event("RADIATION_STORM"))
		"RADIATION_STORM":
			if space_3d: space_3d.resolve_radiation_shielding()
			if gm and gm.has_method("submit_task_calculation"):
				gm.submit_task_calculation("LVL_04", "TASK_04_04", 468.0)
			_broadcast_radio("FLIGHT SURGEON", "Aft radiation shield locked towards Sun. Avionics and crew shielded. Radiation load safe.")
			var tw := create_tween()
			tw.tween_interval(2.5)
			tw.tween_callback(_trigger_mars_arrival)

func _trigger_mars_arrival() -> void:
	if space_3d:
		space_3d.set_flight_phase(4) # MARS_APPROACH
	if modal_mars_arrival:
		modal_mars_arrival.visible = true
	is_moi_armed = false
	is_moi_burning = false
	if btn_arm_moi:
		btn_arm_moi.text = "ARM PROPULSION"
		btn_arm_moi.modulate = Color.WHITE
	if btn_execute_moi:
		btn_execute_moi.disabled = true
	_broadcast_radio("FLIGHT DIRECTOR", "MARS ORBIT INSERTION WINDOW APPROACHING! Prepare spacecraft orientation for Mars orbital capture.")

func _on_align_attitude_helper_pressed() -> void:
	if space_3d:
		space_3d.craft_rotation = space_3d.target_moi_attitude
		space_3d.update_attitude_guidance()
	_broadcast_radio("GUIDANCE", "Attitude thrusters fired. Spacecraft aligned with retrograde capture vector.")

func _toggle_arm_moi() -> void:
	if not space_3d or not space_3d.is_attitude_aligned:
		_broadcast_radio("GUIDANCE", "WARNING: Align spacecraft attitude to retrograde target vector before arming propulsion!")
		return
	is_moi_armed = not is_moi_armed
	if btn_arm_moi:
		btn_arm_moi.text = "DISARM PROPULSION" if is_moi_armed else "ARM PROPULSION"
		btn_arm_moi.modulate = MarsDeepUIRef.COLOR_RED if is_moi_armed else Color.WHITE
	if btn_execute_moi:
		btn_execute_moi.disabled = not is_moi_armed
		btn_execute_moi.modulate = MarsDeepUIRef.COLOR_ORANGE if is_moi_armed else Color.WHITE

func _on_execute_moi_pressed() -> void:
	is_moi_burning = true
	is_moi_armed = true
	if space_3d:
		space_3d.set_flight_phase(5) # MARS_ORBIT_INSERTION (MOI)
		space_3d.set_retrograde_burn(true, 1.0)
	_broadcast_radio("CAPCOM", "Mars Orbit Insertion retrograde burn engaged! 100% throttle. Braking into Mars gravity well.")
	
	if progress_bar_moi:
		var tw_p := create_tween()
		tw_p.tween_property(progress_bar_moi, "value", 100.0, 3.5)
		
	# After 3.5 seconds of MOI braking burn, achieve stable Mars orbit!
	var tw := create_tween()
	tw.tween_interval(3.5)
	tw.tween_callback(func():
		is_moi_burning = false
		if space_3d:
			space_3d.set_retrograde_burn(false)
			space_3d.set_flight_phase(6) # MARS_ORBIT_ACHIEVED
		if modal_mars_arrival:
			modal_mars_arrival.visible = false
		if banner_orbit_achieved:
			banner_orbit_achieved.visible = true
		btn_nav_next.disabled = false
		level_04_completed = true
		_broadcast_radio("FLIGHT DIRECTOR", "HOUSTON CONFIRMS MARS ORBIT INSERTION! MARS ORBIT ACHIEVED! LEVEL 04 COMPLETE!")
		
		# Certify all tasks for Level 04 and unlock Level 05 in GameManager
		var gm = _get_gm()
		if gm and gm.progress:
			gm.progress.certify_level("LVL_04")
	)

func _on_continue_to_mars_exploration_pressed() -> void:
	print("[MissionSimulation] Progressing to Level 05: MarsExploration.tscn...")
	get_tree().change_scene_to_file("res://scenes/MarsExploration.tscn")
