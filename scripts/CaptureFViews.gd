extends SceneTree

## CaptureFViews.gd - Captures 10 High-Resolution Screenshots for Stage F
## Two-phase state machine: Phase 0 sets state -> waits 12 frames -> Phase 1 captures PNG -> advances step.

const MarsPlanetary3DRef = preload("res://scenes/MarsPlanetary3D.gd")

var frames_waited := 0
var capture_step := 0
var state_setup_done := false
var mars_scene: Node = null
var m3d: Node3D = null

func _init() -> void:
	print("[CaptureFViews] Initializing 2-phase visual capture sequence...")
	var scn = load("res://scenes/MarsExploration.tscn")
	if scn:
		mars_scene = scn.instantiate()
		root.add_child(mars_scene)
		DirAccess.make_dir_absolute("res://screenshots")
	else:
		print("[CaptureFViews] ERROR: Could not load MarsExploration.tscn")
		quit(1)

func _process(_delta: float) -> bool:
	if m3d == null:
		if mars_scene.mars_3d != null:
			m3d = mars_scene.mars_3d
		elif mars_scene.has_node("MarginContainer/VBoxContainer/MainBody/ViewportContainer/SubViewport/MarsPlanetary3D"):
			m3d = mars_scene.get_node("MarginContainer/VBoxContainer/MainBody/ViewportContainer/SubViewport/MarsPlanetary3D")
		if m3d == null:
			return false
			
	if not state_setup_done:
		_setup_step_state(capture_step)
		state_setup_done = true
		frames_waited = 0
		return false
		
	frames_waited += 1
	if frames_waited < 12:
		return false
		
	# Frame is fully rendered and settled
	_save_step_screenshot(capture_step)
	capture_step += 1
	state_setup_done = false
	frames_waited = 0
	
	if capture_step >= 10:
		print("[CaptureFViews] ALL 10 STAGE F SCREENSHOTS CAPTURED!")
		quit(0)
		return true
	return false

func _setup_step_state(step: int) -> void:
	match step:
		0:
			# F1: Mars from Orbit
			print("[CaptureFViews] Setup F1: Mars from Orbit...")
			mars_scene.current_stage_step = 0
			mars_scene.modal_site_select.visible = true
			mars_scene.modal_checklist.visible = false
			mars_scene.descent_telemetry_panel.visible = false
			mars_scene.rover_telemetry_panel.visible = false
			m3d.set_scene_mode(MarsPlanetary3DRef.GameSceneMode.ORBIT)
			mars_scene._broadcast_radio("FLIGHT DIRECTOR (HOUSTON)", "Mars orbit nominal. Spacecraft in 350 km observation trajectory. Select primary planetary landing site.")
			
		1:
			# F2: Cockpit Descent
			print("[CaptureFViews] Setup F2: Cockpit Descent...")
			mars_scene.modal_site_select.visible = false
			mars_scene.modal_checklist.visible = false
			mars_scene.current_stage_step = 2
			mars_scene.descent_telemetry_panel.visible = true
			mars_scene.descent_console.visible = true
			mars_scene.badge_phase.text = "PHASE 3: PLAYER-CONTROLLED POWERED DESCENT"
			m3d.set_scene_mode(MarsPlanetary3DRef.GameSceneMode.DESCENT)
			m3d.set_camera_view(MarsPlanetary3DRef.CameraViewMode.COCKPIT_DESCENT)
			m3d.descent_altitude_m = 3450.0
			m3d.descent_vertical_speed_ms = 44.5
			m3d.descent_horizontal_speed_ms = 2.4
			m3d.descent_thrust_pct = 0.40
			m3d.parachute_deployed = true
			m3d.heatshield_jettisoned = true
			m3d.landing_gear_deployed = false
			mars_scene.lbl_alt_val.text = "3450 m"
			mars_scene.lbl_vspeed_val.text = "44.5 m/s"
			mars_scene.lbl_hspeed_val.text = "2.4 m/s"
			mars_scene.lbl_fuel_val.text = "215.0 kg"
			mars_scene.lbl_chute_status.text = "DEPLOYED"
			mars_scene.lbl_thrust_pct.text = "40%"
			mars_scene.slider_thrust.value = 40.0
			mars_scene._broadcast_radio("FLIGHT DYNAMICS", "Seven Minutes of Terror: Cockpit radar altimeter locked. Parachute deployed.")
			
		2:
			# F3: Exterior Retro-Engine Operation
			print("[CaptureFViews] Setup F3: Retro-Engine Operation...")
			m3d.set_camera_view(MarsPlanetary3DRef.CameraViewMode.EXTERIOR_DESCENT)
			m3d.descent_altitude_m = 160.0
			m3d.descent_vertical_speed_ms = 7.8
			m3d.descent_thrust_pct = 0.90
			m3d.parachute_deployed = false
			m3d.landing_gear_deployed = true
			if m3d.descent_flame: m3d.descent_flame.visible = true
			mars_scene.lbl_alt_val.text = "160 m"
			mars_scene.lbl_vspeed_val.text = "7.8 m/s"
			mars_scene.lbl_chute_status.text = "GEAR LOCKED"
			mars_scene.lbl_thrust_pct.text = "90%"
			mars_scene.slider_thrust.value = 90.0
			mars_scene._broadcast_radio("PROPULSION", "Retro-propulsion terminal deceleration burn engaged. Landing legs locked.")
			
		3:
			# F4: Touchdown Assessment
			print("[CaptureFViews] Setup F4: Touchdown...")
			m3d.descent_altitude_m = 0.0
			m3d.descent_vertical_speed_ms = 1.15
			m3d.descent_horizontal_speed_ms = 0.2
			m3d._evaluate_touchdown()
			mars_scene.current_stage_step = 3
			mars_scene.modal_touchdown.visible = true
			mars_scene.descent_console.visible = false
			mars_scene.badge_phase.text = "PHASE 4: TOUCHDOWN & ROVER DEPLOYMENT"
			mars_scene.lbl_touchdown_outcome.text = "PERFECT TOUCHDOWN • NOMINAL SPECS"
			mars_scene.lbl_touchdown_stats.text = "Touchdown Vertical Speed: 1.15 m/s • Residual Fuel: 182.4 kg • Landing Site: Jezero Crater"
			mars_scene.btn_touchdown_proceed.visible = true
			mars_scene.btn_touchdown_retry.visible = false
			mars_scene._broadcast_radio("FLIGHT DIRECTOR", "TOUCHDOWN CONFIRMED! MARS DEEP IS ON THE SURFACE OF MARS!")
			
		4:
			# F5: Wide Martian Surface Landscape
			print("[CaptureFViews] Setup F5: Wide Martian Landscape...")
			mars_scene.modal_touchdown.visible = false
			mars_scene.modal_deploy_rover.visible = false
			mars_scene.descent_telemetry_panel.visible = false
			mars_scene.rover_telemetry_panel.visible = false
			mars_scene.descent_console.visible = false
			mars_scene.rover_console.visible = false
			m3d.set_scene_mode(MarsPlanetary3DRef.GameSceneMode.SURFACE)
			m3d.set_camera_view(MarsPlanetary3DRef.CameraViewMode.SURFACE_CINEMATIC)
			if m3d.cam_surface_cinematic:
				m3d.cam_surface_cinematic.position = Vector3(22.0, 7.5, 28.0)
				m3d.cam_surface_cinematic.look_at(Vector3(0, 1.5, 0), Vector3.UP)
			mars_scene._broadcast_radio("GEOLOGY TEAM", "Jezero Crater sedimentary plains and ancient river delta terrain surveyed.")
			
		5:
			# F6: Rover Egress down Ramp
			print("[CaptureFViews] Setup F6: Rover Egress down Ramp...")
			m3d.start_surface_mode()
			mars_scene.modal_deploy_rover.visible = true
			if m3d.lander_ramp: m3d.lander_ramp.rotation.x = 0.45
			if m3d.rover_rig: m3d.rover_rig.position = Vector3(0, 0.45, 3.2)
			m3d.set_camera_view(MarsPlanetary3DRef.CameraViewMode.SURFACE_CINEMATIC)
			if m3d.cam_surface_cinematic:
				m3d.cam_surface_cinematic.position = Vector3(7.0, 2.5, 8.5)
				m3d.cam_surface_cinematic.look_at(Vector3(0, 0.8, 2.5), Vector3.UP)
			mars_scene._broadcast_radio("SURFACE OPERATIONS", "Deployment ramp extended. Egressing 6-wheel science rover.")
			
		6:
			# F7: Third-person Driving
			print("[CaptureFViews] Setup F7: Third-Person Driving...")
			mars_scene.modal_deploy_rover.visible = false
			mars_scene.current_stage_step = 5
			mars_scene.badge_phase.text = "PHASE 5: SURFACE EXPLORATION & SCIENCE HARVEST"
			mars_scene.rover_telemetry_panel.visible = true
			mars_scene.rover_console.visible = true
			mars_scene._update_camera_buttons_for_mode(2)
			m3d.is_rover_deployed = true
			if m3d.rover_rig:
				m3d.rover_rig.position = Vector3(5.0, 0.45, 14.0)
				m3d.rover_rig.rotation.y = 0.35
			m3d.rover_speed = 3.6
			m3d.rover_distance_traveled_m = 64.2
			m3d.rover_battery_wh = 1120.0
			mars_scene.lbl_rover_speed_val.text = "3.6 km/h"
			mars_scene.lbl_rover_battery_val.text = "1120 Wh (93%)"
			mars_scene.lbl_rover_dist_lander.text = "14.9 m"
			mars_scene.lbl_target_range_val.text = "ANCIENT WATER OUTFLOW (11.2m)"
			mars_scene.lbl_samples_count_val.text = "0 / 5 OBJECTIVES"
			m3d.set_camera_view(MarsPlanetary3DRef.CameraViewMode.ROVER_CHASE)
			mars_scene._broadcast_radio("ROVER CONTROL", "Rover traversing regolith at 3.6 km/h. Rocker-bogie suspension nominal.")
			
		7:
			# F8: Science Instrument Interaction
			print("[CaptureFViews] Setup F8: Science Instrument Mastcam...")
			if m3d.rover_rig:
				m3d.rover_rig.position = Vector3(12.0, 0.45, 18.0)
				m3d.rover_rig.rotation.y = -0.2
			if m3d.robotic_arm:
				m3d.robotic_arm.rotation.x = -0.45
				m3d.robotic_arm.rotation.y = 0.4
			mars_scene.lbl_target_range_val.text = "ANCIENT WATER OUTFLOW (2.4m)"
			m3d.set_camera_view(MarsPlanetary3DRef.CameraViewMode.ROVER_MAST)
			mars_scene._broadcast_radio("SCIENCE PAYLOAD", "SuperCam laser firing and PIXL microscopic spectrometer analyzing target rock.")
			
		8:
			# F9: Sample Collection Modal
			print("[CaptureFViews] Setup F9: Sample Collection Modal...")
			var sample_data = {
				"id": "SAMPLE_WATER_01",
				"name": "Jezero Delta Smectite Clay Outcrop",
				"location": "Jezero Delta Ancient River Fan",
				"instrument": "SuperCam Laser & PIXL Spectrometer",
				"observation": "Hydrated phyllosilicate clay minerals exhibiting layered sedimentation with distinct organic-associated carbon signatures.",
				"significance": "Direct astrobiological biosignature candidate confirming sustained lacustrine river delta habitability on Mars."
			}
			mars_scene._show_discovery_card(sample_data)
			mars_scene.lbl_samples_count_val.text = "1 / 5 OBJECTIVES"
			mars_scene._broadcast_radio("CHIEF SCIENTIST", "Discovery logged: Jezero Delta Smectite Clay Outcrop. Sample cached.")
			
		9:
			# F10: Final Exploration Complete Scene
			print("[CaptureFViews] Setup F10: Final Exploration Complete...")
			mars_scene.modal_discovery.visible = false
			mars_scene.current_stage_step = 6
			mars_scene.badge_phase.text = "PHASE 6: MARS EXPLORATION COMPLETE"
			mars_scene.banner_mission_complete.visible = true
			mars_scene.btn_nav_report.disabled = false
			for k in m3d.completed_science_objectives.keys():
				m3d.completed_science_objectives[k] = true
			mars_scene.lbl_samples_count_val.text = "5 / 5 OBJECTIVES (100%)"
			m3d.set_camera_view(MarsPlanetary3DRef.CameraViewMode.SURFACE_CINEMATIC)
			if m3d.cam_surface_cinematic:
				m3d.cam_surface_cinematic.position = Vector3(-16.0, 5.0, 22.0)
				m3d.cam_surface_cinematic.look_at(Vector3(0, 1.2, 7.0), Vector3.UP)
			mars_scene._broadcast_radio("NASA ADMINISTRATOR", "CONGRATULATIONS COMMANDER! ALL PRIMARY MISSION OBJECTIVES COMPLETED ON MARS! MISSION CERTIFIED!")

func _save_step_screenshot(step: int) -> void:
	var paths = [
		"res://screenshots/f1_mars_from_orbit.png",
		"res://screenshots/f2_first_person_descent.png",
		"res://screenshots/f3_landing_engine_operation.png",
		"res://screenshots/f4_touchdown.png",
		"res://screenshots/f5_martian_surface.png",
		"res://screenshots/f6_rover_deployment.png",
		"res://screenshots/f7_third_person_rover_driving.png",
		"res://screenshots/f8_science_instrument_interaction.png",
		"res://screenshots/f9_sample_collection.png",
		"res://screenshots/f10_final_mars_exploration.png"
	]
	if step >= 0 and step < paths.size():
		var path: String = paths[step]
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(path)
			print("[CaptureFViews] Successfully Saved Step %d: %s" % [step + 1, path])
