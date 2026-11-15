extends Node

## CaptureStageJViews.gd
## Captures 10 high-resolution verification screenshots for Stage J in MARS DEEP.

var capture_index: int = 0
var timer: float = 0.0

var ms_scene: Node = null
var me_scene: Node = null
var current_mode: int = 0 # 0: Flight/Sim, 1: Mars Exploration

func _ready() -> void:
	print("[CaptureStageJViews] Starting automated Stage J visual capture suite...")
	get_viewport().size = Vector2i(1280, 720)
	_load_flight_simulation()

func _load_flight_simulation() -> void:
	if me_scene:
		me_scene.queue_free()
		me_scene = null
		
	var scene_res = load("res://scenes/MissionSimulation.tscn")
	ms_scene = scene_res.instantiate()
	add_child(ms_scene)
	current_mode = 0

func _load_mars_exploration() -> void:
	if ms_scene:
		ms_scene.queue_free()
		ms_scene = null
		
	var scene_res = load("res://scenes/MarsExploration.tscn")
	me_scene = scene_res.instantiate()
	add_child(me_scene)
	current_mode = 1

func _process(delta: float) -> void:
	timer += delta
	
	match capture_index:
		0:
			# J1: Clean rocket flight with no obstructive popups
			if timer > 0.8:
				_save_screenshot("j1_clean_rocket_flight_no_popups.png")
				capture_index += 1
				timer = 0.0
		1:
			# J2: Booster activation & engine plume burn
			if timer > 0.3 and timer < 0.4:
				if ms_scene and ms_scene.has_node("SpaceFlight3D"):
					var sf = ms_scene.get_node("SpaceFlight3D")
					sf.set_propulsion_burn(true, 1.0)
					sf.set_time_warp(1)
					if ms_scene.guidance_hud:
						ms_scene.guidance_hud.set_guidance(
							"STEP 1/5", "TRANS-MARS INJECTION", "Main propulsion active. Accelerating to 3.8 km/s.", "Coasting trajectory", 20.0
						)
			elif timer > 1.0:
				_save_screenshot("j2_booster_activation_transition.png")
				capture_index += 1
				timer = 0.0
		2:
			# J3: Spacecraft rotating near Mars with 3D orientation & alignment indicator
			if timer > 0.3 and timer < 0.4:
				if ms_scene and ms_scene.has_node("SpaceFlight3D"):
					var sf = ms_scene.get_node("SpaceFlight3D")
					sf.set_flight_phase(5) # MARS_ORBIT_INSERTION
					sf.is_orientation_mode = true
					sf.apply_yaw_input(0.35)
					sf.apply_pitch_input(-0.25)
					sf.apply_roll_input(0.15)
					if ms_scene.guidance_hud:
						ms_scene.guidance_hud.set_guidance(
							"STEP 4/5", "MARS ORBIT INSERTION ATTITUDE", "Rotate spacecraft [A/D Yaw, W/S Pitch, Q/E Roll] to align retrograde.", "MOI burn", 75.0
						)
			elif timer > 1.0:
				_save_screenshot("j3_spacecraft_rotating_near_mars.png")
				capture_index += 1
				timer = 0.0
		3:
			# J4: Spacecraft traveling around Mars on curved orbital path ring
			if timer > 0.3 and timer < 0.4:
				if ms_scene and ms_scene.has_node("SpaceFlight3D"):
					var sf = ms_scene.get_node("SpaceFlight3D")
					sf.set_flight_phase(6) # MARS_ORBIT_ACHIEVED
					sf.mars_orbit_angle = 1.2
					sf.set_camera_view(sf.CameraMode.MARS_CINEMATIC)
					if ms_scene.guidance_hud:
						ms_scene.guidance_hud.set_guidance(
							"STEP 5/5", "MARS ORBIT ACHIEVED", "Spacecraft captured in stable 350 km orbit. Orbit path confirmed.", "Mars entry reconnaissance", 90.0
						)
			elif timer > 1.0:
				_save_screenshot("j4_spacecraft_travelling_around_mars.png")
				capture_index += 1
				timer = 0.0
				_load_mars_exploration()
		4:
			# J5: 360-degree Mars inspection camera
			if timer > 0.4 and timer < 0.5:
				if me_scene:
					me_scene._on_cam_orbit_360_pressed()
					if me_scene.mars_3d:
						me_scene.mars_3d.adjust_orbit_angles(0.7, 0.25)
			elif timer > 1.2:
				_save_screenshot("j5_360_degree_mars_inspection.png")
				capture_index += 1
				timer = 0.0
		5:
			# J6: Detailed procedural rocky Mars terrain
			if timer > 0.3 and timer < 0.4:
				if me_scene:
					me_scene._select_site("Jezero Crater")
					me_scene._on_start_edl_pressed()
					me_scene._on_touchdown_occurred(1, 1.8)
					me_scene._on_touchdown_proceed_pressed()
			elif timer > 1.2:
				_save_screenshot("j6_detailed_rocky_mars_terrain.png")
				capture_index += 1
				timer = 0.0
		6:
			# J7: Rover deployment cinematic animation
			if timer > 0.3 and timer < 0.4:
				if me_scene:
					me_scene._on_confirm_deploy_rover_pressed()
					if me_scene.mars_3d and me_scene.mars_3d.cam_surface_cinematic:
						me_scene.mars_3d.set_camera_view(me_scene.mars_3d.CameraViewMode.SURFACE_CINEMATIC)
			elif timer > 1.2:
				_save_screenshot("j7_rover_deployment_animation.png")
				capture_index += 1
				timer = 0.0
		7:
			# J8: Guided rover exploration with navigation marker & direction arrow
			if timer > 0.3 and timer < 0.4:
				if me_scene and me_scene.mars_3d:
					me_scene.mars_3d.set_camera_view(me_scene.mars_3d.CameraViewMode.ROVER_CHASE)
					me_scene.mars_3d.set_rover_drive_input(1.0, 0.2)
					me_scene.mars_3d._process_surface_mode(1.0)
			elif timer > 1.2:
				_save_screenshot("j8_guided_rover_checkpoint.png")
				capture_index += 1
				timer = 0.0
		8:
			# J9: Experiment interface & scientific sample analysis
			if timer > 0.3 and timer < 0.4:
				if me_scene:
					me_scene._on_science_lab_pressed()
					me_scene._on_run_exp1_pressed()
					me_scene._on_run_exp2_pressed()
			elif timer > 1.0:
				_save_screenshot("j9_experiment_interface.png")
				capture_index += 1
				timer = 0.0
		9:
			# J10: Earth data transmission with 100% completion & DSN receipt
			if timer > 0.3 and timer < 0.4:
				if me_scene:
					me_scene.modal_sequential_science.visible = false
					me_scene._on_run_exp3_pressed()
					me_scene._on_run_exp4_pressed()
					me_scene.modal_data_transmission.visible = true
					me_scene._on_transmit_confirm_pressed()
			elif timer > 1.0:
				_save_screenshot("j10_earth_data_transmission.png")
				print("[CaptureStageJViews] All 10 Stage J screenshots captured successfully!")
				capture_index += 1
				get_tree().quit(0)

func _save_screenshot(filename: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://" + filename
	var abs_path: String = ProjectSettings.globalize_path(path)
	img.save_png(abs_path)
	print("[CaptureStageJViews] Saved screenshot: %s (%s)" % [filename, abs_path])
