extends Control

## MarsExploration.gd - Mars Landing, EDL Descent & Planetary Exploration Controller
## Integrates 3D descent physics, playable 6-wheel rover driving, 5 science objectives, and Level 05 certification.

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

# Node References - Viewport & 3D Simulation
@onready var subviewport: SubViewport = $MarginContainer/VBoxContainer/MainBody/ViewportContainer/SubViewport
@onready var mars_3d: Node3D = $MarginContainer/VBoxContainer/MainBody/ViewportContainer/SubViewport/MarsPlanetary3D

# Header & Navigation
@onready var badge_phase: Label = $MarginContainer/VBoxContainer/Header/TopNav/PhaseBadge
@onready var badge_site: Label = $MarginContainer/VBoxContainer/Header/TopNav/SiteBadge
@onready var btn_nav_back: Button = $MarginContainer/VBoxContainer/Header/TopNav/BtnBackTransit
@onready var btn_nav_report: Button = $MarginContainer/VBoxContainer/Header/TopNav/BtnToReport

# Radio Communications Box
@onready var radio_panel: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RadioPanel
@onready var lbl_radio_speaker: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RadioPanel/Margin/VBox/LblSpeaker
@onready var lbl_radio_message: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RadioPanel/Margin/VBox/LblMessage

# Telemetry Panels
@onready var descent_telemetry_panel: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/DescentTelemetryPanel
@onready var lbl_alt_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/DescentTelemetryPanel/Margin/VBox/Grid/LblAltVal
@onready var lbl_vspeed_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/DescentTelemetryPanel/Margin/VBox/Grid/LblVSpeedVal
@onready var lbl_hspeed_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/DescentTelemetryPanel/Margin/VBox/Grid/LblHSpeedVal
@onready var lbl_fuel_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/DescentTelemetryPanel/Margin/VBox/Grid/LblFuelVal
@onready var lbl_chute_status: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/DescentTelemetryPanel/Margin/VBox/Grid/LblChuteVal

@onready var rover_telemetry_panel: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverTelemetryPanel
@onready var lbl_rover_speed_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverTelemetryPanel/Margin/VBox/Grid/LblSpeedVal
@onready var lbl_rover_battery_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverTelemetryPanel/Margin/VBox/Grid/LblBatteryVal
@onready var lbl_rover_dist_lander: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverTelemetryPanel/Margin/VBox/Grid/LblDistLanderVal
@onready var lbl_target_range_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverTelemetryPanel/Margin/VBox/Grid/LblTargetRangeVal
@onready var lbl_samples_count_val: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverTelemetryPanel/Margin/VBox/Grid/LblSamplesVal

# Flight Controls HUD (Bottom-Right during Descent)
@onready var descent_console: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/DescentConsolePanel
@onready var slider_thrust: VSlider = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/DescentConsolePanel/Margin/VBox/HBox/SliderThrust
@onready var lbl_thrust_pct: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/DescentConsolePanel/Margin/VBox/HBox/VBox/LblThrustPct
@onready var btn_thrust_up: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/DescentConsolePanel/Margin/VBox/HBox/VBoxButtons/BtnThrustUp
@onready var btn_thrust_down: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/DescentConsolePanel/Margin/VBox/HBox/VBoxButtons/BtnThrustDown
@onready var btn_drift_left: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/DescentConsolePanel/Margin/VBox/HBoxDrift/BtnDriftLeft
@onready var btn_drift_right: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/DescentConsolePanel/Margin/VBox/HBoxDrift/BtnDriftRight

# Rover Controls HUD (Bottom-Right on Surface)
@onready var rover_console: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverConsolePanel
@onready var btn_drive_fwd: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverConsolePanel/Margin/VBox/GridDrive/BtnFwd
@onready var btn_drive_back: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverConsolePanel/Margin/VBox/GridDrive/BtnBack
@onready var btn_drive_left: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverConsolePanel/Margin/VBox/GridDrive/BtnLeft
@onready var btn_drive_right: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverConsolePanel/Margin/VBox/GridDrive/BtnRight
@onready var btn_interact_sample: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverConsolePanel/Margin/VBox/BtnInteract
@onready var btn_take_photo: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverConsolePanel/Margin/VBox/HBoxPhoto/BtnTakePhoto
@onready var btn_photo_gallery: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverConsolePanel/Margin/VBox/HBoxPhoto/BtnPhotoGallery
@onready var btn_science_lab: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverConsolePanel/Margin/VBox/HBoxScience/BtnScienceLab
@onready var btn_transmit_link: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/RoverConsolePanel/Margin/VBox/HBoxScience/BtnTransmitLink

# Camera Switcher Bar
@onready var camera_bar: HBoxContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/CameraBar
@onready var btn_cam_1: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/CameraBar/BtnCam1
@onready var btn_cam_2: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/CameraBar/BtnCam2
@onready var btn_cam_orbit_360: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/CameraBar/BtnCamOrbit360
@onready var btn_cam_3: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/CameraBar/BtnCam3
@onready var btn_reset_cam: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/CameraBar/BtnResetCam

# Modals & Dialogs
@onready var modal_site_select: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSiteSelect
@onready var btn_site_jezero: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSiteSelect/Margin/VBox/SitesGrid/BtnJezero
@onready var btn_site_gale: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSiteSelect/Margin/VBox/SitesGrid/BtnGale
@onready var btn_site_elysium: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSiteSelect/Margin/VBox/SitesGrid/BtnElysium

@onready var modal_checklist: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalChecklist
@onready var btn_start_edl: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalChecklist/Margin/VBox/BtnStartEDL

@onready var modal_touchdown: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalTouchdown
@onready var lbl_touchdown_outcome: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalTouchdown/Margin/VBox/LblOutcome
@onready var lbl_touchdown_stats: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalTouchdown/Margin/VBox/LblStats
@onready var btn_touchdown_proceed: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalTouchdown/Margin/VBox/BtnProceed
@onready var btn_touchdown_retry: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalTouchdown/Margin/VBox/BtnRetry

@onready var modal_deploy_rover: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDeployRover
@onready var btn_confirm_deploy_rover: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDeployRover/Margin/VBox/BtnConfirmDeploy

@onready var modal_discovery: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDiscovery
@onready var lbl_disc_title: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDiscovery/Margin/VBox/LblDiscTitle
@onready var lbl_disc_inst: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDiscovery/Margin/VBox/LblDiscInst
@onready var lbl_disc_obs: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDiscovery/Margin/VBox/LblDiscObs
@onready var btn_close_discovery: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDiscovery/Margin/VBox/BtnCloseDisc

@onready var banner_mission_complete: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/BannerMissionComplete
@onready var btn_to_report_final: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/BannerMissionComplete/Margin/VBox/BtnFinalReport
@onready var btn_enter_sandbox: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/BannerMissionComplete/Margin/VBox/BtnEnterSandbox

# Stage I Sequential Science & Transmissions
@onready var modal_sequential_science: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSequentialScience
@onready var btn_run_exp1: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSequentialScience/Margin/VBox/Scroll/CardVBox/Exp1Card/HBoxExp1/BtnRunExp1
@onready var lbl_exp1_status: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSequentialScience/Margin/VBox/Scroll/CardVBox/Exp1Card/HBoxExp1/LblExp1Status
@onready var btn_depth_4m: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSequentialScience/Margin/VBox/Scroll/CardVBox/Exp2Card/HBoxDepth/BtnDepth4m
@onready var btn_depth_8m: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSequentialScience/Margin/VBox/Scroll/CardVBox/Exp2Card/HBoxDepth/BtnDepth8m
@onready var btn_depth_12m: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSequentialScience/Margin/VBox/Scroll/CardVBox/Exp2Card/HBoxDepth/BtnDepth12m
@onready var btn_run_exp2: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSequentialScience/Margin/VBox/Scroll/CardVBox/Exp2Card/HBoxExp2/BtnRunExp2
@onready var lbl_exp2_status: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSequentialScience/Margin/VBox/Scroll/CardVBox/Exp2Card/HBoxExp2/LblExp2Status
@onready var btn_run_exp3: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSequentialScience/Margin/VBox/Scroll/CardVBox/Exp3Card/HBoxExp3/BtnRunExp3
@onready var lbl_exp3_status: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSequentialScience/Margin/VBox/Scroll/CardVBox/Exp3Card/HBoxExp3/LblExp3Status
@onready var btn_run_exp4: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSequentialScience/Margin/VBox/Scroll/CardVBox/Exp4Card/HBoxExp4/BtnRunExp4
@onready var lbl_exp4_status: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSequentialScience/Margin/VBox/Scroll/CardVBox/Exp4Card/HBoxExp4/LblExp4Status
@onready var btn_close_science: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalSequentialScience/Margin/VBox/BtnCloseScienceModal

@onready var modal_photo_gallery: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalPhotoGallery
@onready var lbl_gallery_count: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalPhotoGallery/Margin/VBox/LblGalleryCount
@onready var photo_list_vbox: VBoxContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalPhotoGallery/Margin/VBox/Scroll/PhotoListVBox
@onready var btn_close_gallery: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalPhotoGallery/Margin/VBox/BtnCloseGallery

@onready var modal_data_transmission: PanelContainer = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDataTransmission
@onready var progress_bar_dsn: ProgressBar = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDataTransmission/Margin/VBox/ProgressBarDSN
@onready var lbl_earth_status: Label = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDataTransmission/Margin/VBox/LblEarthStatus
@onready var btn_transmit_confirm: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDataTransmission/Margin/VBox/BtnTransmitConfirm
@onready var btn_close_transmission: Button = $MarginContainer/VBoxContainer/MainBody/OverlayHUD/ModalDataTransmission/Margin/VBox/BtnCloseTransmission

# State Machine & Progression
var current_stage_step: int = 0
# 0: Orbit Site Select, 1: Descent Checklist, 2: Powered Descent, 3: Touchdown Outcome, 4: Rover Egress, 5: Surface Science, 6: Mission Complete
var key_drive_throttle: float = 0.0
var key_drive_steering: float = 0.0
var selected_rimfax_depth: float = 8.2

func _ready() -> void:
	print("[MarsExploration] Initializing Mars Landing & Planetary Exploration UI...")
	_apply_styling()
	_connect_signals()
	_initialize_orbit_state()

func _apply_styling() -> void:
	if badge_phase:
		badge_phase.add_theme_stylebox_override("normal", MarsDeepUIRef.create_panel_style(Color(0.05, 0.1, 0.15, 0.85), MarsDeepUIRef.COLOR_CYAN, 1, 4, 8))
	if badge_site:
		badge_site.add_theme_stylebox_override("normal", MarsDeepUIRef.create_panel_style(Color(0.12, 0.08, 0.04, 0.85), MarsDeepUIRef.COLOR_ORANGE, 1, 4, 8))
	if radio_panel:
		radio_panel.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.04, 0.08, 0.12, 0.9), MarsDeepUIRef.COLOR_CYAN, 1))
	if descent_telemetry_panel:
		descent_telemetry_panel.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.04, 0.06, 0.1, 0.9), MarsDeepUIRef.COLOR_BORDER_SUBTLE, 1))
	if rover_telemetry_panel:
		rover_telemetry_panel.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.04, 0.06, 0.1, 0.9), MarsDeepUIRef.COLOR_BORDER_SUBTLE, 1))
	if descent_console:
		descent_console.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.05, 0.07, 0.11, 0.9), MarsDeepUIRef.COLOR_ORANGE, 1))
	if rover_console:
		rover_console.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.05, 0.07, 0.11, 0.9), MarsDeepUIRef.COLOR_CYAN, 1))

func _connect_signals() -> void:
	if mars_3d:
		mars_3d.descent_telemetry_updated.connect(_on_descent_telemetry_updated)
		mars_3d.touchdown_occurred.connect(_on_touchdown_occurred)
		mars_3d.rover_telemetry_updated.connect(_on_rover_telemetry_updated)
		mars_3d.sample_collected.connect(_on_sample_collected)
		mars_3d.objective_completed.connect(_on_objective_completed)
		
	# Landing Site buttons
	if btn_site_jezero: btn_site_jezero.pressed.connect(func(): _select_site("Jezero Crater"))
	if btn_site_gale: btn_site_gale.pressed.connect(func(): _select_site("Gale Crater"))
	if btn_site_elysium: btn_site_elysium.pressed.connect(func(): _select_site("Elysium Planitia"))
	
	# Descent Checklist & Action
	if btn_start_edl: btn_start_edl.pressed.connect(_on_start_edl_pressed)
	
	# Descent Controls
	if slider_thrust: slider_thrust.value_changed.connect(func(v): mars_3d.descent_thrust_pct = v / 100.0)
	if btn_thrust_up: btn_thrust_up.pressed.connect(func(): mars_3d.adjust_descent_thrust(0.05))
	if btn_thrust_down: btn_thrust_down.pressed.connect(func(): mars_3d.adjust_descent_thrust(-0.05))
	if btn_drift_left: btn_drift_left.pressed.connect(func(): mars_3d.adjust_horizontal_drift(-1.5))
	if btn_drift_right: btn_drift_right.pressed.connect(func(): mars_3d.adjust_horizontal_drift(1.5))
	
	# Touchdown outcomes
	if btn_touchdown_proceed: btn_touchdown_proceed.pressed.connect(_on_touchdown_proceed_pressed)
	if btn_touchdown_retry: btn_touchdown_retry.pressed.connect(_on_touchdown_retry_pressed)
	
	# Rover Deployment & Drive
	if btn_confirm_deploy_rover: btn_confirm_deploy_rover.pressed.connect(_on_confirm_deploy_rover_pressed)
	if btn_interact_sample: btn_interact_sample.pressed.connect(_on_interact_sample_pressed)
	if btn_close_discovery: btn_close_discovery.pressed.connect(func(): modal_discovery.visible = false)
	
	# Stage I Photography, Science & DSN Links
	if btn_take_photo: btn_take_photo.pressed.connect(_on_take_photo_pressed)
	if btn_photo_gallery: btn_photo_gallery.pressed.connect(_on_photo_gallery_pressed)
	if btn_close_gallery: btn_close_gallery.pressed.connect(func(): modal_photo_gallery.visible = false)
	if btn_science_lab: btn_science_lab.pressed.connect(_on_science_lab_pressed)
	if btn_close_science: btn_close_science.pressed.connect(func(): modal_sequential_science.visible = false)
	if btn_transmit_link: btn_transmit_link.pressed.connect(func(): modal_data_transmission.visible = true)
	if btn_transmit_confirm: btn_transmit_confirm.pressed.connect(_on_transmit_confirm_pressed)
	if btn_close_transmission: btn_close_transmission.pressed.connect(func(): modal_data_transmission.visible = false)
	if btn_enter_sandbox: btn_enter_sandbox.pressed.connect(_on_enter_sandbox_pressed)
	
	# Four Sequential Experiments
	if btn_run_exp1: btn_run_exp1.pressed.connect(_on_run_exp1_pressed)
	if btn_depth_4m: btn_depth_4m.pressed.connect(func(): selected_rimfax_depth = 4.5; _update_depth_buttons())
	if btn_depth_8m: btn_depth_8m.pressed.connect(func(): selected_rimfax_depth = 8.2; _update_depth_buttons())
	if btn_depth_12m: btn_depth_12m.pressed.connect(func(): selected_rimfax_depth = 12.0; _update_depth_buttons())
	if btn_run_exp2: btn_run_exp2.pressed.connect(_on_run_exp2_pressed)
	if btn_run_exp3: btn_run_exp3.pressed.connect(_on_run_exp3_pressed)
	if btn_run_exp4: btn_run_exp4.pressed.connect(_on_run_exp4_pressed)
	
	# Navigation & Report
	if btn_nav_back: btn_nav_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MissionSimulation.tscn"))
	if btn_nav_report: btn_nav_report.pressed.connect(_on_go_to_report_pressed)
	if btn_to_report_final: btn_to_report_final.pressed.connect(_on_go_to_report_pressed)
	
	# Camera buttons
	if btn_cam_1: btn_cam_1.pressed.connect(func(): _set_cam_slot(1))
	if btn_cam_2: btn_cam_2.pressed.connect(func(): _set_cam_slot(2))
	if btn_cam_3: btn_cam_3.pressed.connect(func(): _set_cam_slot(3))
	if btn_cam_orbit_360: btn_cam_orbit_360.pressed.connect(_on_cam_orbit_360_pressed)
	if btn_reset_cam: btn_reset_cam.pressed.connect(func(): if mars_3d: mars_3d.reset_orbit_camera())

func _initialize_orbit_state() -> void:
	current_stage_step = 0
	badge_phase.text = "PHASE 1: ORBIT & LANDING SITE SELECTION"
	badge_site.text = "SITE: JEZERO CRATER (TARGET ACQUIRED)"
	modal_site_select.visible = true
	modal_checklist.visible = false
	descent_telemetry_panel.visible = false
	rover_telemetry_panel.visible = false
	descent_console.visible = false
	rover_console.visible = false
	modal_touchdown.visible = false
	modal_deploy_rover.visible = false
	modal_discovery.visible = false
	banner_mission_complete.visible = false
	if modal_sequential_science: modal_sequential_science.visible = false
	if modal_photo_gallery: modal_photo_gallery.visible = false
	if modal_data_transmission: modal_data_transmission.visible = false
	_update_camera_buttons_for_mode(0)
	
	_broadcast_radio("FLIGHT DIRECTOR (HOUSTON)", "Mars orbit nominal. Spacecraft in 350 km observation trajectory. Select primary planetary landing site.")

# =========================================================================
# INPUT SHORTCUTS & ROVER DRIVING
# =========================================================================

func _process(delta: float) -> void:
	if current_stage_step == 5 and mars_3d: # Surface driving
		# Poll keyboard drive inputs
		var fwd := 0.0
		var steer := 0.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): fwd += 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): fwd -= 0.6
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): steer -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): steer += 1.0
		if Input.is_key_pressed(KEY_SPACE): fwd = 0.0 # Handbrake
		
		# Combine button/key input
		fwd += key_drive_throttle
		steer += key_drive_steering
		mars_3d.set_rover_drive_input(fwd, steer)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E:
				if current_stage_step == 5:
					_on_interact_sample_pressed()
			KEY_P:
				if current_stage_step >= 4:
					_on_take_photo_pressed()
			KEY_C:
				_cycle_current_cameras()
			KEY_W, KEY_UP:
				if current_stage_step == 2: mars_3d.adjust_descent_thrust(0.05)
				elif current_stage_step <= 1 and mars_3d.camera_mode == 6: mars_3d.adjust_orbit_angles(0.0, 0.06)
			KEY_S, KEY_DOWN:
				if current_stage_step == 2: mars_3d.adjust_descent_thrust(-0.05)
				elif current_stage_step <= 1 and mars_3d.camera_mode == 6: mars_3d.adjust_orbit_angles(0.0, -0.06)
			KEY_A, KEY_LEFT:
				if current_stage_step == 2: mars_3d.adjust_horizontal_drift(-1.5)
				elif current_stage_step <= 1 and mars_3d.camera_mode == 6: mars_3d.adjust_orbit_angles(0.08, 0.0)
			KEY_D, KEY_RIGHT:
				if current_stage_step == 2: mars_3d.adjust_horizontal_drift(1.5)
				elif current_stage_step <= 1 and mars_3d.camera_mode == 6: mars_3d.adjust_orbit_angles(-0.08, 0.0)
				
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if mars_3d:
			if mars_3d.camera_mode == 6 and mars_3d.is_mouse_looking:
				mars_3d.handle_orbit_mouse_look(mm.relative)
			else:
				mars_3d.handle_mouse_look(mm.relative)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mars_3d: mars_3d.is_mouse_looking = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			if mars_3d and mars_3d.camera_mode == 6: mars_3d.handle_orbit_zoom(-2.5)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if mars_3d and mars_3d.camera_mode == 6: mars_3d.handle_orbit_zoom(2.5)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mars_3d: mars_3d.is_mouse_looking = mb.pressed

# =========================================================================
# RADIO BROADCASTS
# =========================================================================

func _broadcast_radio(speaker: String, message: String) -> void:
	if lbl_radio_speaker: lbl_radio_speaker.text = "• " + speaker
	if lbl_radio_message: lbl_radio_message.text = message
	if mars_3d and mars_3d.audio_chatter:
		mars_3d.audio_chatter.play()

# =========================================================================
# STAGE 1: LANDING SITE SELECTION
# =========================================================================

func _select_site(site_name: String) -> void:
	if mars_3d: mars_3d.select_landing_site(site_name)
	badge_site.text = "SITE: " + site_name.to_upper()
	modal_site_select.visible = false
	modal_checklist.visible = true
	current_stage_step = 1
	badge_phase.text = "PHASE 2: DESCENT PREPARATION & EDL ENTRY"
	_broadcast_radio("CAPCOM", "Target landing coordinates locked for %s. Verify Entry, Descent & Landing systems checklist." % site_name)

# =========================================================================
# STAGE 2: DESCENT PREPARATION & ENTRY (EDL)
# =========================================================================

func _on_start_edl_pressed() -> void:
	modal_checklist.visible = false
	current_stage_step = 2
	badge_phase.text = "PHASE 3: PLAYER-CONTROLLED POWERED DESCENT"
	descent_telemetry_panel.visible = true
	descent_console.visible = true
	
	if mars_3d: mars_3d.start_descent_sequence()
	_update_camera_buttons_for_mode(1)
	_broadcast_radio("FLIGHT DYNAMICS", "De-orbit burn complete. Atmospheric entry confirmed at 5.8 km/s! Seven Minutes of Terror underway!")
	
	# Submit Task 05_01 in GameManager
	var gm = _get_gm()
	if gm and gm.has_method("submit_task_calculation"):
		gm.submit_task_calculation("LVL_05", "TASK_05_01", 17.24)

func _on_descent_telemetry_updated(data: Dictionary) -> void:
	if lbl_alt_val: lbl_alt_val.text = "%.0f m" % data.get("altitude_m", 0.0)
	if lbl_vspeed_val:
		var vs: float = data.get("vertical_speed_ms", 0.0)
		lbl_vspeed_val.text = "%.1f m/s" % vs
		lbl_vspeed_val.modulate = MarsDeepUIRef.COLOR_GREEN if vs < 3.2 else (MarsDeepUIRef.COLOR_YELLOW if vs < 5.0 else MarsDeepUIRef.COLOR_RED)
	if lbl_hspeed_val: lbl_hspeed_val.text = "%.1f m/s" % data.get("horizontal_speed_ms", 0.0)
	if lbl_fuel_val: lbl_fuel_val.text = "%.1f kg" % data.get("fuel_kg", 0.0)
	if lbl_chute_status:
		lbl_chute_status.text = "DEPLOYED" if data.get("chute_deployed", false) else ("GEAR LOCKED" if data.get("landing_gear", false) else "STOWED")
		
	# Update thrust slider
	var th_pct: int = data.get("thrust_pct", 0)
	if lbl_thrust_pct: lbl_thrust_pct.text = "%d%%" % th_pct
	if slider_thrust and not slider_thrust.has_focus():
		slider_thrust.value = float(th_pct)

# =========================================================================
# STAGE 3: TOUCHDOWN & ASSESSMENT
# =========================================================================

func _on_touchdown_occurred(outcome: int, vspeed: float) -> void:
	current_stage_step = 3
	badge_phase.text = "PHASE 4: TOUCHDOWN & ROVER DEPLOYMENT"
	descent_console.visible = false
	modal_touchdown.visible = true
	
	if lbl_touchdown_outcome:
		lbl_touchdown_outcome.text = mars_3d.get_landing_outcome_name()
		lbl_touchdown_outcome.modulate = MarsDeepUIRef.COLOR_GREEN if outcome in [1, 2] else (MarsDeepUIRef.COLOR_YELLOW if outcome == 3 else MarsDeepUIRef.COLOR_RED)
		
	if lbl_touchdown_stats:
		lbl_touchdown_stats.text = "Touchdown Vertical Speed: %.2f m/s • Residual Fuel: %.1f kg • Landing Site: %s" % [
			vspeed, mars_3d.descent_fuel_kg, mars_3d.selected_landing_site
		]
		
	if outcome == 4: # FAILED
		btn_touchdown_proceed.visible = false
		btn_touchdown_retry.visible = true
		_broadcast_radio("CAPCOM", "Touchdown speed exceeded structural limit! Abort landing. Retry descent sequence.")
	else:
		btn_touchdown_proceed.visible = true
		btn_touchdown_retry.visible = false
		_broadcast_radio("FLIGHT DIRECTOR", "TOUCHDOWN CONFIRMED! MARS DEEP IS ON THE SURFACE OF MARS!")
		# Validate Tasks 05_02 and 05_03
		var gm = _get_gm()
		if gm and gm.has_method("submit_task_calculation"):
			gm.submit_task_calculation("LVL_05", "TASK_05_02", 61.3)
			gm.submit_task_calculation("LVL_05", "TASK_05_03", 6.24)

func _on_touchdown_proceed_pressed() -> void:
	modal_touchdown.visible = false
	modal_deploy_rover.visible = true
	current_stage_step = 4
	if mars_3d: mars_3d.start_surface_mode()
	_update_camera_buttons_for_mode(2)
	_broadcast_radio("SURFACE OPERATIONS", "Post-landing stabilization verified. Lander ramp and rover egress ready.")

func _on_touchdown_retry_pressed() -> void:
	modal_touchdown.visible = false
	if mars_3d: mars_3d.start_descent_sequence()
	current_stage_step = 2

# =========================================================================
# STAGE 4: ROVER DEPLOYMENT
# =========================================================================

func _on_confirm_deploy_rover_pressed() -> void:
	modal_deploy_rover.visible = false
	current_stage_step = 5
	badge_phase.text = "PHASE 5: SURFACE EXPLORATION & SCIENCE HARVEST"
	descent_telemetry_panel.visible = false
	rover_telemetry_panel.visible = true
	rover_console.visible = true
	
	if mars_3d: mars_3d.deploy_rover_sequence()
	_broadcast_radio("ROVER CONTROL", "Rover wheels on Martian regolith! Drive systems and science instruments operational.")
	
	# Submit Task 05_04 in GameManager
	var gm = _get_gm()
	if gm and gm.has_method("submit_task_calculation"):
		gm.submit_task_calculation("LVL_05", "TASK_05_04", 150.0)

func _on_rover_telemetry_updated(data: Dictionary) -> void:
	if lbl_rover_speed_val: lbl_rover_speed_val.text = "%.1f km/h" % data.get("speed_kmh", 0.0)
	if lbl_rover_battery_val: lbl_rover_battery_val.text = "%.0f Wh (%.0f%%)" % [data.get("battery_wh", 0.0), data.get("battery_pct", 100.0)]
	if lbl_rover_dist_lander: lbl_rover_dist_lander.text = "%.1f m" % data.get("distance_to_lander_m", 0.0)
	if lbl_target_range_val:
		var t_name: String = data.get("nearest_target", "")
		var t_dist: float = data.get("nearest_dist_m", 999.0)
		lbl_target_range_val.text = "%s (%.1fm)" % [t_name, t_dist]
		lbl_target_range_val.modulate = MarsDeepUIRef.COLOR_GREEN if t_dist <= 12.0 else MarsDeepUIRef.COLOR_TEXT_SECONDARY
	if lbl_samples_count_val:
		lbl_samples_count_val.text = "%d / 5 OBJECTIVES" % data.get("samples_count", 0)

# =========================================================================
# STAGE 5: SCIENCE HARVEST & SAMPLES
# =========================================================================

func _on_interact_sample_pressed() -> void:
	if not mars_3d:
		return
	var res: Dictionary = mars_3d.interact_with_nearest_target()
	if not res.get("success", false):
		_broadcast_radio("ROVER CONTROL", res.get("message", "Interaction failed."))
	else:
		var s_data: Dictionary = res.get("data", {})
		_show_discovery_card(s_data)

func _show_discovery_card(sample: Dictionary) -> void:
	modal_discovery.visible = true
	if lbl_disc_title: lbl_disc_title.text = sample.get("name", "Science Sample")
	if lbl_disc_inst: lbl_disc_inst.text = "INSTRUMENTS: " + sample.get("instrument", "")
	if lbl_disc_obs: lbl_disc_obs.text = "%s\n\nSignificance: %s" % [sample.get("observation", ""), sample.get("significance", "")]
	_broadcast_radio("CHIEF SCIENTIST", "Discovery logged: %s. Sample cached." % sample.get("name", ""))

func _on_sample_collected(sample: Dictionary) -> void:
	_check_all_science_completed()

func _on_objective_completed(obj_id: String, _data: Dictionary) -> void:
	_check_all_science_completed()

func _check_all_science_completed() -> void:
	if mars_3d and mars_3d.are_all_science_objectives_met() and current_stage_step == 5:
		current_stage_step = 6
		badge_phase.text = "PHASE 6: MARS EXPLORATION COMPLETE"
		banner_mission_complete.visible = true
		btn_nav_report.disabled = false
		if mars_3d: mars_3d.set_camera_view(5) # SURFACE_CINEMATIC
		_broadcast_radio("NASA ADMINISTRATOR", "CONGRATULATIONS COMMANDER! ALL PRIMARY MISSION OBJECTIVES COMPLETED ON MARS! MISSION CERTIFIED!")
		
		# Submit Task 05_05 and certify Level 05 in GameManager
		var gm = _get_gm()
		if gm and gm.progress:
			if gm.has_method("submit_task_calculation"):
				gm.submit_task_calculation("LVL_05", "TASK_05_05", 90.0)
			gm.progress.certify_level("LVL_05")

func _on_go_to_report_pressed() -> void:
	print("[MarsExploration] Navigating to final mission report: MissionReport.tscn...")
	get_tree().change_scene_to_file("res://scenes/MissionReport.tscn")

# =========================================================================
# CAMERA MANAGEMENT
# =========================================================================

func _update_camera_buttons_for_mode(mode: int) -> void:
	match mode:
		0: # Orbit
			btn_cam_1.text = "[1] ORBIT VIEW"
			btn_cam_1.visible = true
			btn_cam_2.visible = false
			btn_cam_3.visible = false
			if btn_cam_orbit_360: btn_cam_orbit_360.visible = true
			if btn_reset_cam: btn_reset_cam.visible = (mars_3d != null and mars_3d.camera_mode == 6)
		1: # Descent
			btn_cam_1.text = "[1] COCKPIT"
			btn_cam_2.text = "[2] EXTERIOR"
			btn_cam_1.visible = true
			btn_cam_2.visible = true
			btn_cam_3.visible = false
			if btn_cam_orbit_360: btn_cam_orbit_360.visible = false
			if btn_reset_cam: btn_reset_cam.visible = false
		2: # Surface
			btn_cam_1.text = "[1] ROVER CHASE"
			btn_cam_2.text = "[2] MASTCAM"
			btn_cam_3.text = "[3] CINEMATIC"
			btn_cam_1.visible = true
			btn_cam_2.visible = true
			btn_cam_3.visible = true
			if btn_cam_orbit_360: btn_cam_orbit_360.visible = false
			if btn_reset_cam: btn_reset_cam.visible = false

func _on_cam_orbit_360_pressed() -> void:
	if not mars_3d:
		return
	mars_3d.set_camera_view(6) # ORBIT_INSPECT_360
	if btn_reset_cam: btn_reset_cam.visible = true
	_broadcast_radio("FLIGHT DYNAMICS", "360° Mars Inspection camera engaged. Click and drag mouse to rotate, mouse wheel to zoom, or use A/D and W/S keys.")

func _set_cam_slot(slot: int) -> void:
	if not mars_3d:
		return
	if current_stage_step <= 1:
		mars_3d.set_camera_view(0)
		if btn_reset_cam: btn_reset_cam.visible = false
	elif current_stage_step in [2, 3]:
		mars_3d.set_camera_view(1 if slot == 1 else 2)
	else:
		if slot == 1: mars_3d.set_camera_view(3)
		elif slot == 2: mars_3d.set_camera_view(4)
		elif slot == 3: mars_3d.set_camera_view(5)

func _cycle_current_cameras() -> void:
	if not mars_3d:
		return
	var cur := int(mars_3d.camera_mode)
	if current_stage_step <= 1:
		mars_3d.set_camera_view(6 if cur == 0 else 0)
		if btn_reset_cam: btn_reset_cam.visible = (mars_3d.camera_mode == 6)
	elif current_stage_step in [2, 3]:
		mars_3d.set_camera_view(2 if cur == 1 else 1)
	elif current_stage_step >= 4:
		var next_cam := 3 if cur == 5 else cur + 1
		if next_cam < 3 or next_cam > 5: next_cam = 3
		mars_3d.set_camera_view(next_cam)

# =========================================================================
# STAGE I: PHOTOGRAPHY & PHOTO GALLERY (PART 8)
# =========================================================================

func _on_take_photo_pressed() -> void:
	if not mars_3d:
		return
	var p: Dictionary = mars_3d.capture_viewport_photo()
	if btn_photo_gallery:
		btn_photo_gallery.text = "GALLERY (%d)" % mars_3d.captured_photos.size()
	_broadcast_radio("MASTCAM-Z", "High-resolution photo captured: %s at %s. Stored in rover memory." % [
		p.get("id", "PHOTO"), p.get("coordinates", "0,0")
	])

func _on_photo_gallery_pressed() -> void:
	if not mars_3d:
		return
	modal_photo_gallery.visible = true
	var count: int = mars_3d.captured_photos.size()
	if lbl_gallery_count:
		lbl_gallery_count.text = "Stored Viewport Captures: %d photos" % count
		
	if photo_list_vbox:
		for child in photo_list_vbox.get_children():
			child.queue_free()
			
		if count == 0:
			var empty_lbl := Label.new()
			empty_lbl.text = "No photographs captured yet. Press [P] or click '📷 MASTCAM' to take photos of the Martian surface."
			empty_lbl.modulate = Color(0.7, 0.7, 0.7)
			photo_list_vbox.add_child(empty_lbl)
		else:
			for p in mars_3d.captured_photos:
				var card := PanelContainer.new()
				card.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.04, 0.07, 0.11, 0.9), MarsDeepUIRef.COLOR_BORDER_SUBTLE, 1, 4, 6))
				var cv := VBoxContainer.new()
				card.add_child(cv)
				
				var title_lbl := Label.new()
				title_lbl.text = "• %s [Sol %d] - %s" % [p.get("id", ""), p.get("sol", 34), p.get("timestamp", "")]
				title_lbl.modulate = MarsDeepUIRef.COLOR_CYAN
				cv.add_child(title_lbl)
				
				var meta_lbl := Label.new()
				meta_lbl.text = "Coords: %s • Heading: %s • Target: %s (%s) • Mode: %s" % [
					p.get("coordinates", ""), p.get("heading", ""), p.get("target", ""),
					p.get("range_m", ""), p.get("camera_mode", "")
				]
				meta_lbl.modulate = Color(0.85, 0.9, 0.95)
				cv.add_child(meta_lbl)
				photo_list_vbox.add_child(card)

# =========================================================================
# STAGE I: FOUR SEQUENTIAL SCIENCE EXPERIMENTS (PART 7)
# =========================================================================

func _on_science_lab_pressed() -> void:
	modal_sequential_science.visible = true
	_update_depth_buttons()
	_update_science_modal_ui()

func _update_depth_buttons() -> void:
	if btn_depth_4m:
		btn_depth_4m.modulate = MarsDeepUIRef.COLOR_CYAN if is_equal_approx(selected_rimfax_depth, 4.5) else Color.WHITE
	if btn_depth_8m:
		btn_depth_8m.modulate = MarsDeepUIRef.COLOR_CYAN if is_equal_approx(selected_rimfax_depth, 8.2) else Color.WHITE
	if btn_depth_12m:
		btn_depth_12m.modulate = MarsDeepUIRef.COLOR_CYAN if is_equal_approx(selected_rimfax_depth, 12.0) else Color.WHITE

func _on_run_exp1_pressed() -> void:
	if not mars_3d: return
	var res: Dictionary = mars_3d.perform_experiment_1()
	_update_science_modal_ui()
	_check_all_science_completed()
	_broadcast_radio("SUPERCAM LIBS", "Laser pulses fired! Mineral breakdown: 38% Pyroxene, 26% Olivine, 22% Smectite, 14% Plagioclase.")

func _on_run_exp2_pressed() -> void:
	if not mars_3d: return
	var res: Dictionary = mars_3d.perform_experiment_2(selected_rimfax_depth)
	_update_science_modal_ui()
	_check_all_science_completed()
	_broadcast_radio("RIMFAX GPR", "Subsurface scan complete! Stratigraphic boundary confirmed at %.1f meters depth." % selected_rimfax_depth)

func _on_run_exp3_pressed() -> void:
	if not mars_3d: return
	var res: Dictionary = mars_3d.perform_experiment_3()
	_update_science_modal_ui()
	_check_all_science_completed()
	_broadcast_radio("MEDA WEATHER", "Atmospheric profile recorded: -63.4°C, 612 Pa, 7.4 m/s NNE wind, tau = 0.42.")

func _on_run_exp4_pressed() -> void:
	if not mars_3d: return
	var res: Dictionary = mars_3d.perform_experiment_4()
	_update_science_modal_ui()
	_check_all_science_completed()
	_broadcast_radio("PIXL & SHERLOC", "Sample Tube #042 hermetically sealed! Deep UV Raman detected abiotic organic carbon.")

func _update_science_modal_ui() -> void:
	if not mars_3d:
		return
	var done_count := 0
	if mars_3d.experiment_records.has(1) and mars_3d.experiment_records[1]["completed"]:
		done_count += 1
		if lbl_exp1_status:
			lbl_exp1_status.text = "[COMPLETE • VERIFIED]"
			lbl_exp1_status.modulate = MarsDeepUIRef.COLOR_GREEN
		if btn_run_exp1: btn_run_exp1.disabled = true
	if mars_3d.experiment_records.has(2) and mars_3d.experiment_records[2]["completed"]:
		done_count += 1
		if lbl_exp2_status:
			lbl_exp2_status.text = "[COMPLETE • REFLECTOR %.1fm]" % selected_rimfax_depth
			lbl_exp2_status.modulate = MarsDeepUIRef.COLOR_GREEN
		if btn_run_exp2: btn_run_exp2.disabled = true
	if mars_3d.experiment_records.has(3) and mars_3d.experiment_records[3]["completed"]:
		done_count += 1
		if lbl_exp3_status:
			lbl_exp3_status.text = "[COMPLETE • PROFILE LOGGED]"
			lbl_exp3_status.modulate = MarsDeepUIRef.COLOR_GREEN
		if btn_run_exp3: btn_run_exp3.disabled = true
	if mars_3d.experiment_records.has(4) and mars_3d.experiment_records[4]["completed"]:
		done_count += 1
		if lbl_exp4_status:
			lbl_exp4_status.text = "[COMPLETE • TUBE #042 CACHED]"
			lbl_exp4_status.modulate = MarsDeepUIRef.COLOR_GREEN
		if btn_run_exp4: btn_run_exp4.disabled = true
		
	if btn_science_lab:
		btn_science_lab.text = "🔬 SCIENCE (%d/4)" % done_count

# =========================================================================
# STAGE I: DEEP SPACE DATA TRANSMISSION (PART 9)
# =========================================================================

func _on_transmit_confirm_pressed() -> void:
	if not mars_3d:
		return
	var res: Dictionary = mars_3d.transmit_data_to_earth()
	if progress_bar_dsn:
		progress_bar_dsn.value = 100.0
	if lbl_earth_status:
		lbl_earth_status.text = "%s\n48.6 MB telemetry & %d photos archived across DSN Goldstone, Madrid & Canberra." % [
			res.get("earth_acknowledgement", "TRANSMISSION RECEIVED"),
			res.get("photos_transmitted", 0)
		]
		lbl_earth_status.modulate = MarsDeepUIRef.COLOR_GREEN
	_broadcast_radio("DEEP SPACE NETWORK", "DSN Goldstone DSS-14 confirmed: 48.6 MB telemetry & science datasets received and archived!")

# =========================================================================
# STAGE I: PERMANENT FREE-ROAM SANDBOX (PART 10)
# =========================================================================

func _on_enter_sandbox_pressed() -> void:
	banner_mission_complete.visible = false
	if mars_3d:
		mars_3d.enter_sandbox_mode()
	rover_console.visible = true
	rover_telemetry_panel.visible = true
	badge_phase.text = "MARS EXPLORATION • FREE-ROAM SANDBOX ACTIVE"
	_broadcast_radio("MISSION CONTROL", "Sandbox mode active. Unlimited Martian surface exploration authorized. Free-roam driving enabled across Jezero Crater!")
