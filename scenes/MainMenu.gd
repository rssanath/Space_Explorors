extends Node3D

## MainMenu.gd - Cinematic 3D Main Menu & Hackathon Presentation Hub
## Features rotating 3D Mars, orbiting modular spacecraft, spherical starfield,
## hackathon presentation mode for judges, settings, controls, and NASA credits.

const GameManagerRef = preload("res://scripts/GameManager.gd")
const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")
const LaunchAudioRef = preload("res://scripts/LaunchAudio.gd")

# 3D Node References
@onready var camera: Camera3D = $Camera3D
@onready var mars_anchor: Node3D = $MarsAnchor
@onready var mars_mesh: MeshInstance3D = $MarsAnchor/MarsMesh
@onready var atmosphere_mesh: MeshInstance3D = $MarsAnchor/AtmosphereMesh
@onready var craft_orbit_pivot: Node3D = $MarsAnchor/CraftOrbitPivot
@onready var orbiting_spacecraft: Node3D = $MarsAnchor/CraftOrbitPivot/OrbitingCraft
@onready var starfield_node: MultiMeshInstance3D = $Starfield
@onready var audio_ambience: AudioStreamPlayer = $AudioPlayer

# Main Menu UI Buttons
@onready var btn_start: Button = $UI/MainMenuPanel/MarginContainer/VBoxContainer/ButtonsVBox/BtnStart
@onready var btn_continue: Button = $UI/MainMenuPanel/MarginContainer/VBoxContainer/ButtonsVBox/BtnContinue
@onready var btn_demo_mode: Button = $UI/MainMenuPanel/MarginContainer/VBoxContainer/ButtonsVBox/BtnDemoMode
@onready var btn_briefing: Button = $UI/MainMenuPanel/MarginContainer/VBoxContainer/ButtonsVBox/BtnBriefing
@onready var btn_controls: Button = $UI/MainMenuPanel/MarginContainer/VBoxContainer/ButtonsVBox/BtnControls
@onready var btn_settings: Button = $UI/MainMenuPanel/MarginContainer/VBoxContainer/ButtonsVBox/BtnSettings
@onready var btn_credits: Button = $UI/MainMenuPanel/MarginContainer/VBoxContainer/ButtonsVBox/BtnCredits
@onready var btn_exit: Button = $UI/MainMenuPanel/MarginContainer/VBoxContainer/ButtonsVBox/BtnExit

# Modals
@onready var modal_demo: Control = $UI/ModalDemo
@onready var btn_demo_stage1: Button = $UI/ModalDemo/Panel/Margin/VBox/Grid/BtnStage1
@onready var btn_demo_stage2: Button = $UI/ModalDemo/Panel/Margin/VBox/Grid/BtnStage2
@onready var btn_demo_stage3: Button = $UI/ModalDemo/Panel/Margin/VBox/Grid/BtnStage3
@onready var btn_demo_stage4: Button = $UI/ModalDemo/Panel/Margin/VBox/Grid/BtnStage4
@onready var btn_demo_stage5: Button = $UI/ModalDemo/Panel/Margin/VBox/Grid/BtnStage5
@onready var btn_demo_stage6: Button = $UI/ModalDemo/Panel/Margin/VBox/Grid/BtnStage6
@onready var btn_demo_stage7: Button = $UI/ModalDemo/Panel/Margin/VBox/Grid/BtnStage7
@onready var btn_demo_stage8: Button = $UI/ModalDemo/Panel/Margin/VBox/Grid/BtnStage8
@onready var btn_close_demo: Button = $UI/ModalDemo/Panel/Margin/VBox/BtnCloseDemo

@onready var modal_credits: Control = $UI/ModalCredits
@onready var btn_close_credits: Button = $UI/ModalCredits/Panel/Margin/VBox/BtnCloseCredits

@onready var modal_controls: Control = $UI/ModalControls
@onready var btn_close_controls: Button = $UI/ModalControls/Panel/Margin/VBox/BtnCloseControls

@onready var modal_settings: Control = $UI/ModalSettings
@onready var slider_master: HSlider = $UI/ModalSettings/Panel/Margin/VBox/MasterBox/SliderMaster
@onready var slider_sfx: HSlider = $UI/ModalSettings/Panel/Margin/VBox/SFXBox/SliderSFX
@onready var check_fullscreen: CheckBox = $UI/ModalSettings/Panel/Margin/VBox/CheckFullscreen
@onready var btn_close_settings: Button = $UI/ModalSettings/Panel/Margin/VBox/BtnCloseSettings

var initial_camera_pos: Vector3
var sim_time: float = 0.0
var craft_orbit_angle: float = 0.0

const MARS_ROTATION_SPEED: float = 0.04
const CRAFT_ORBIT_SPEED: float = 0.25

func _ready() -> void:
	print("[MainMenu] Initializing Cinematic Redesign & Hackathon Hub...")
	if camera:
		initial_camera_pos = camera.position
		
	_setup_procedural_mars()
	_setup_starfield()
	_setup_ambience_audio()
	_setup_ui_styles()
	_connect_ui_signals()
	_update_continue_button()
	
	_hide_all_modals()

func _process(delta: float) -> void:
	sim_time += delta
	
	# Planetary axial rotation
	if mars_mesh:
		mars_mesh.rotate_y(MARS_ROTATION_SPEED * delta)
	if atmosphere_mesh:
		atmosphere_mesh.rotate_y(MARS_ROTATION_SPEED * 0.8 * delta)
		
	# Spacecraft Keplerian orbit around Mars
	if craft_orbit_pivot:
		craft_orbit_angle += CRAFT_ORBIT_SPEED * delta
		craft_orbit_pivot.rotation.y = craft_orbit_angle
		
	# Subtle floating camera motion
	if camera:
		var ox: float = sin(sim_time * 0.35) * 0.05
		var oy: float = cos(sim_time * 0.28) * 0.04
		camera.position = initial_camera_pos + Vector3(ox, oy, 0.0)

func _setup_procedural_mars() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.38, 0.20, 1.0)
	
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	
	var noise_tex := NoiseTexture2D.new()
	noise_tex.seamless = true
	noise_tex.width = 512
	noise_tex.height = 256
	noise_tex.noise = noise
	
	mat.roughness = 0.85
	mat.rim_enabled = true
	mat.rim = 0.75
	mat.rim_tint = 0.4
	
	if mars_mesh:
		mars_mesh.material_override = mat
		
	var atmo_mat := StandardMaterial3D.new()
	atmo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	atmo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	atmo_mat.albedo_color = Color(1.0, 0.45, 0.22, 0.25)
	atmo_mat.rim_enabled = true
	atmo_mat.rim = 1.0
	atmo_mat.rim_tint = 0.85
	
	if atmosphere_mesh:
		atmosphere_mesh.material_override = atmo_mat

func _setup_starfield() -> void:
	if not starfield_node: return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = 1200
	multimesh.visible_instance_count = 1200
	
	var quad := QuadMesh.new()
	quad.size = Vector2(0.4, 0.4)
	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	star_mat.vertex_color_use_as_albedo = true
	quad.material = star_mat
	multimesh.mesh = quad
	
	var rng := RandomNumberGenerator.new()
	rng.seed = 42828
	for i in range(1200):
		var u: float = rng.randf_range(-1.0, 1.0)
		var theta: float = rng.randf_range(0.0, TAU)
		var rad: float = rng.randf_range(160.0, 240.0)
		var sqrt_u: float = sqrt(maxf(0.0, 1.0 - u * u))
		var pos := Vector3(rad * sqrt_u * cos(theta), rad * u, rad * sqrt_u * sin(theta))
		var t := Transform3D(Basis(), pos)
		var sc: float = rng.randf_range(0.6, 2.2)
		t = t.scaled_local(Vector3(sc, sc, sc))
		multimesh.set_instance_transform(i, t)
		
		var col := Color(0.9, 0.95, 1.0, rng.randf_range(0.6, 1.0))
		if rng.randf() > 0.7: col = Color(0.4, 0.85, 1.0, rng.randf_range(0.7, 1.0))
		multimesh.set_instance_color(i, col)
		
	starfield_node.multimesh = multimesh

func _setup_ambience_audio() -> void:
	if audio_ambience:
		audio_ambience.stream = LaunchAudioRef.create_engine_rumble(4.0)
		audio_ambience.volume_db = -28.0
		audio_ambience.pitch_scale = 0.55
		audio_ambience.play()

func _setup_ui_styles() -> void:
	var p_style = MarsDeepUIRef.create_panel_style(Color(0.04, 0.06, 0.09, 0.94), MarsDeepUIRef.COLOR_CYAN, 1, 6, 16)
	if modal_demo: modal_demo.get_node("Panel").add_theme_stylebox_override("panel", p_style)
	if modal_credits: modal_credits.get_node("Panel").add_theme_stylebox_override("panel", p_style)
	if modal_controls: modal_controls.get_node("Panel").add_theme_stylebox_override("panel", p_style)
	if modal_settings: modal_settings.get_node("Panel").add_theme_stylebox_override("panel", p_style)

func _connect_ui_signals() -> void:
	if btn_start: btn_start.pressed.connect(_on_start_pressed)
	if btn_continue: btn_continue.pressed.connect(_on_continue_pressed)
	if btn_demo_mode: btn_demo_mode.pressed.connect(_on_demo_mode_pressed)
	if btn_briefing: btn_briefing.pressed.connect(_on_briefing_pressed)
	if btn_controls: btn_controls.pressed.connect(func(): _show_modal(modal_controls))
	if btn_settings: btn_settings.pressed.connect(func(): _show_modal(modal_settings))
	if btn_credits: btn_credits.pressed.connect(func(): _show_modal(modal_credits))
	if btn_exit: btn_exit.pressed.connect(func(): get_tree().quit())
	
	if btn_close_demo: btn_close_demo.pressed.connect(_hide_all_modals)
	if btn_close_credits: btn_close_credits.pressed.connect(_hide_all_modals)
	if btn_close_controls: btn_close_controls.pressed.connect(_hide_all_modals)
	if btn_close_settings: btn_close_settings.pressed.connect(_hide_all_modals)
	
	# Demo Stage Buttons
	if btn_demo_stage1: btn_demo_stage1.pressed.connect(func(): _demo_jump("res://scenes/MissionBriefing.tscn"))
	if btn_demo_stage2: btn_demo_stage2.pressed.connect(func(): _demo_jump("res://scenes/MissionDesign.tscn"))
	if btn_demo_stage3: btn_demo_stage3.pressed.connect(func(): _demo_jump("res://scenes/EngineeringLab.tscn"))
	if btn_demo_stage4: btn_demo_stage4.pressed.connect(func(): _demo_jump("res://scenes/LaunchPreparation.tscn"))
	if btn_demo_stage5: btn_demo_stage5.pressed.connect(func(): _demo_jump("res://scenes/MissionSimulation.tscn"))
	if btn_demo_stage6: btn_demo_stage6.pressed.connect(func(): _demo_jump("res://scenes/MarsExploration.tscn"))
	if btn_demo_stage7: btn_demo_stage7.pressed.connect(func(): _demo_jump("res://scenes/MarsExploration.tscn"))
	if btn_demo_stage8: btn_demo_stage8.pressed.connect(func(): _demo_jump("res://scenes/MissionReport.tscn"))
	
	# Settings controls
	if slider_master: slider_master.value_changed.connect(_on_master_vol_changed)
	if slider_sfx: slider_sfx.value_changed.connect(_on_sfx_vol_changed)
	if check_fullscreen: check_fullscreen.toggled.connect(_on_fullscreen_toggled)

func _update_continue_button() -> void:
	if btn_continue and has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		var has_save: bool = gm.has_saved_game()
		btn_continue.disabled = not has_save
		if has_save:
			btn_continue.text = "CONTINUE MISSION (STAGE %s)" % gm.current_level_id
		else:
			btn_continue.text = "CONTINUE MISSION (NO SAVE)"

func _hide_all_modals() -> void:
	if modal_demo: modal_demo.visible = false
	if modal_credits: modal_credits.visible = false
	if modal_controls: modal_controls.visible = false
	if modal_settings: modal_settings.visible = false

func _show_modal(modal: Control) -> void:
	_hide_all_modals()
	if modal: modal.visible = true

func _on_start_pressed() -> void:
	print("[MainMenu] Starting New Campaign Mission...")
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").start_new_mission()
	else:
		get_tree().change_scene_to_file("res://scenes/MissionBriefing.tscn")

func _on_continue_pressed() -> void:
	print("[MainMenu] Continuing Saved Mission...")
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").continue_mission()
	else:
		get_tree().change_scene_to_file("res://scenes/MissionDesign.tscn")

func _on_demo_mode_pressed() -> void:
	_show_modal(modal_demo)

func _on_briefing_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MissionBriefing.tscn")

func _demo_jump(target_scene: String) -> void:
	print("[MainMenu] DEMO MODE: Jumping directly to %s" % target_scene)
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").activate_demo_mode()
	get_tree().change_scene_to_file(target_scene)

func _on_master_vol_changed(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0) if value > 0.0 else -80.0)

func _on_sfx_vol_changed(_value: float) -> void:
	pass

func _on_fullscreen_toggled(is_toggled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if is_toggled else DisplayServer.WINDOW_MODE_WINDOWED)
