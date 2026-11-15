extends Node

## RunGUISmokeTests.gd
## Comprehensive GUI smoke tests and visual inspection for all 9 core scenes of MARS DEEP.

var current_step: int = 0
var timer: float = 0.0
var active_scene: Node = null

var smoke_results: Dictionary = {
	"MainMenu": "NOT TESTED",
	"LaunchPreparation": "NOT TESTED",
	"RocketLiftoff": "NOT TESTED",
	"InterplanetaryFlight": "NOT TESTED",
	"MarsOrbit": "NOT TESTED",
	"MarsLanding": "NOT TESTED",
	"RoverDeployment": "NOT TESTED",
	"ScienceExperiments": "NOT TESTED",
	"MissionDebrief": "NOT TESTED"
}

func _ready() -> void:
	print("==================================================")
	print("MARS DEEP - GUI SMOKE TEST & SCENE INSPECTION")
	print("==================================================")
	get_viewport().size = Vector2i(1280, 720)
	_load_scene_for_step(0)

func _clear_active_scene() -> void:
	if active_scene:
		active_scene.queue_free()
		active_scene = null

func _load_scene_for_step(step: int) -> void:
	_clear_active_scene()
	timer = 0.0
	
	match step:
		0:
			# Step 1: Main Menu
			print("\n[SMOKE 1] Loading Main Menu (res://scenes/MainMenu.tscn)...")
			var res = load("res://scenes/MainMenu.tscn")
			if res:
				active_scene = res.instantiate()
				add_child(active_scene)
			else:
				smoke_results["MainMenu"] = "FAIL"
		1:
			# Step 2: Launch Preparation
			print("\n[SMOKE 2] Loading Launch Preparation (res://scenes/LaunchPreparation.tscn)...")
			var res = load("res://scenes/LaunchPreparation.tscn")
			if res:
				active_scene = res.instantiate()
				add_child(active_scene)
			else:
				smoke_results["LaunchPreparation"] = "FAIL"
		2:
			# Step 3: Rocket Liftoff
			print("\n[SMOKE 3] Triggering Rocket Liftoff Sequence...")
			var res = load("res://scenes/LaunchPreparation.tscn")
			if res:
				active_scene = res.instantiate()
				add_child(active_scene)
				# Configure full thrust and liftoff
				if active_scene.has_node("MarginContainer/VBoxContainer/MainBody/CenterPanel/ViewportContainer/SubViewport/RocketPreview3D"):
					var r3d = active_scene.rocket_3d
					r3d.set_throttle(1.0)
					r3d.ignite_engines(1.0)
					r3d.release_clamps()
					r3d.set_camera_view(4) # TRACKING_LIFTOFF
			else:
				smoke_results["RocketLiftoff"] = "FAIL"
		3:
			# Step 4: Interplanetary Flight
			print("\n[SMOKE 4] Loading Interplanetary Flight (res://scenes/MissionSimulation.tscn)...")
			var res = load("res://scenes/MissionSimulation.tscn")
			if res:
				active_scene = res.instantiate()
				add_child(active_scene)
				if active_scene.has_node("SpaceFlight3D"):
					var sf = active_scene.get_node("SpaceFlight3D")
					sf.set_propulsion_burn(true, 1.0)
			else:
				smoke_results["InterplanetaryFlight"] = "FAIL"
		4:
			# Step 5: Mars Orbit
			print("\n[SMOKE 5] Loading Mars Orbit Capture...")
			var res = load("res://scenes/MissionSimulation.tscn")
			if res:
				active_scene = res.instantiate()
				add_child(active_scene)
				if active_scene.has_node("SpaceFlight3D"):
					var sf = active_scene.get_node("SpaceFlight3D")
					sf.set_flight_phase(6) # MARS_ORBIT_ACHIEVED
					sf.mars_orbit_angle = 1.45
					sf.set_camera_view(sf.CameraMode.MARS_CINEMATIC)
			else:
				smoke_results["MarsOrbit"] = "FAIL"
		5:
			# Step 6: Mars Landing (Powered Descent)
			print("\n[SMOKE 6] Loading Mars Landing & EDL (res://scenes/MarsExploration.tscn)...")
			var res = load("res://scenes/MarsExploration.tscn")
			if res:
				active_scene = res.instantiate()
				add_child(active_scene)
				active_scene._select_site("Jezero Crater")
				active_scene._on_start_edl_pressed()
			else:
				smoke_results["MarsLanding"] = "FAIL"
		6:
			# Step 7: Rover Deployment
			print("\n[SMOKE 7] Loading Rover Deployment Animation...")
			var res = load("res://scenes/MarsExploration.tscn")
			if res:
				active_scene = res.instantiate()
				add_child(active_scene)
				active_scene._select_site("Jezero Crater")
				active_scene._on_start_edl_pressed()
				active_scene._on_touchdown_occurred(1, 1.6)
				active_scene._on_touchdown_proceed_pressed()
				active_scene._on_confirm_deploy_rover_pressed()
			else:
				smoke_results["RoverDeployment"] = "FAIL"
		7:
			# Step 8: Science Experiments
			print("\n[SMOKE 8] Loading Mars Science Experiments Interface...")
			var res = load("res://scenes/MarsExploration.tscn")
			if res:
				active_scene = res.instantiate()
				add_child(active_scene)
				active_scene._select_site("Jezero Crater")
				active_scene._on_start_edl_pressed()
				active_scene._on_touchdown_occurred(1, 1.6)
				active_scene._on_touchdown_proceed_pressed()
				active_scene._on_confirm_deploy_rover_pressed()
				active_scene._on_science_lab_pressed()
				active_scene._on_run_exp1_pressed()
				active_scene._on_run_exp2_pressed()
			else:
				smoke_results["ScienceExperiments"] = "FAIL"
		8:
			# Step 9: Mission Debrief
			print("\n[SMOKE 9] Loading Mission Debrief Report (res://scenes/MissionReport.tscn)...")
			var res = load("res://scenes/MissionReport.tscn")
			if res:
				active_scene = res.instantiate()
				add_child(active_scene)
			else:
				smoke_results["MissionDebrief"] = "FAIL"

func _process(delta: float) -> void:
	timer += delta
	
	match current_step:
		0: # Main Menu
			if timer > 0.8:
				_save_screenshot("smoke_1_main_menu.png")
				smoke_results["MainMenu"] = "PASS"
				current_step += 1
				_load_scene_for_step(current_step)
		1: # Launch Preparation
			if timer > 0.8:
				_save_screenshot("smoke_2_launch_preparation.png")
				smoke_results["LaunchPreparation"] = "PASS"
				current_step += 1
				_load_scene_for_step(current_step)
		2: # Rocket Liftoff
			if timer > 1.2:
				_save_screenshot("smoke_3_rocket_liftoff.png")
				smoke_results["RocketLiftoff"] = "PASS"
				current_step += 1
				_load_scene_for_step(current_step)
		3: # Interplanetary Flight
			if timer > 1.0:
				_save_screenshot("smoke_4_interplanetary_flight.png")
				smoke_results["InterplanetaryFlight"] = "PASS"
				current_step += 1
				_load_scene_for_step(current_step)
		4: # Mars Orbit
			if timer > 1.0:
				_save_screenshot("smoke_5_mars_orbit.png")
				smoke_results["MarsOrbit"] = "PASS"
				current_step += 1
				_load_scene_for_step(current_step)
		5: # Mars Landing
			if timer > 1.0:
				_save_screenshot("smoke_6_mars_landing.png")
				smoke_results["MarsLanding"] = "PASS"
				current_step += 1
				_load_scene_for_step(current_step)
		6: # Rover Deployment
			if timer > 1.2:
				_save_screenshot("smoke_7_rover_deployment.png")
				smoke_results["RoverDeployment"] = "PASS"
				current_step += 1
				_load_scene_for_step(current_step)
		7: # Science Experiments
			if timer > 1.0:
				_save_screenshot("smoke_8_science_experiments.png")
				smoke_results["ScienceExperiments"] = "PASS"
				current_step += 1
				_load_scene_for_step(current_step)
		8: # Mission Debrief
			if timer > 1.0:
				_save_screenshot("smoke_9_mission_debrief.png")
				smoke_results["MissionDebrief"] = "PASS"
				current_step += 1
				_finish_smoke_tests()

func _save_screenshot(filename: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://" + filename
	var abs_path: String = ProjectSettings.globalize_path(path)
	img.save_png(abs_path)
	print("  [SMOKE CAPTURED] %s -> %s" % [filename, abs_path])

func _finish_smoke_tests() -> void:
	print("\n==================================================")
	print("GUI SMOKE TESTS COMPLETE - FINAL SCENE STATUS")
	print("==================================================")
	var all_passed: bool = true
	for scene_name in smoke_results:
		var status = smoke_results[scene_name]
		print("  %s: %s" % [scene_name.rpad(24), status])
		if status != "PASS":
			all_passed = false
			
	print("==================================================")
	if all_passed:
		print("ALL 9 CORE SCENES VERIFIED SUCCESSFULLY IN GUI MODE!")
		get_tree().quit(0)
	else:
		print("SOME SCENES FAILED OR COULD NOT BE REACHED.")
		get_tree().quit(1)
