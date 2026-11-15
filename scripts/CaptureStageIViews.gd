extends SceneTree

## CaptureStageIViews.gd - Captures complete Stage I views
## MARS DEEP • Stage I: Mars Orbit, Landing & Scientific Exploration Experience

func _init() -> void:
	print("[Capture Stage I] Starting Stage I screenshot capture suite...")
	
	# Ensure screenshots directory exists
	DirAccess.make_dir_absolute("res://screenshots")
	
	# -------------------------------------------------------------
	# PART A: STAGE E VIEWS (MissionSimulation.tscn)
	# -------------------------------------------------------------
	print("[Capture Stage I] Loading MissionSimulation.tscn...")
	var sim_scene = load("res://scenes/MissionSimulation.tscn")
	var sim_inst = sim_scene.instantiate()
	root.add_child(sim_inst)
	
	for i in range(25): await process_frame
	
	var sp3d = sim_inst.space_3d
	
	# 1. Braking Window Warning
	print("[Capture Stage I] 1. Braking window warning...")
	sp3d.set_flight_phase(2) # CRUISE
	sp3d.set_camera_view(0) # COCKPIT
	sim_inst._trigger_maneuver_window()
	sim_inst._on_3d_telemetry_changed(sp3d.get_telemetry_data())
	for i in range(15): await process_frame
	_save_screenshot("screenshots/i1_braking_window_warning.png")
	
	# 2. Reverse-Thrust Burn
	print("[Capture Stage I] 2. Reverse-thrust burn...")
	sim_inst._on_retrograde_burn_pressed()
	sp3d._update_simulation_physics(1.0)
	sim_inst._on_3d_telemetry_changed(sp3d.get_telemetry_data())
	for i in range(15): await process_frame
	_save_screenshot("screenshots/i2_reverse_thrust_burn.png")
	
	# 3. Mars Approach & Attitude Guidance
	print("[Capture Stage I] 3. Mars approach & attitude guidance...")
	if sim_inst.modal_maneuver: sim_inst.modal_maneuver.visible = false
	sp3d.set_flight_phase(4) # APPROACH
	sp3d.set_camera_view(0) # COCKPIT
	sim_inst._trigger_mars_arrival()
	sim_inst._on_3d_telemetry_changed(sp3d.get_telemetry_data())
	for i in range(15): await process_frame
	_save_screenshot("screenshots/i3_mars_approach_guidance.png")
	
	sim_inst.queue_free()
	for i in range(10): await process_frame
	
	# -------------------------------------------------------------
	# PART B: STAGE F & I MARS EXPLORATION VIEWS (MarsExploration.tscn)
	# -------------------------------------------------------------
	print("[Capture Stage I] Loading MarsExploration.tscn...")
	var mars_scene = load("res://scenes/MarsExploration.tscn")
	var mars_inst = mars_scene.instantiate()
	root.add_child(mars_inst)
	
	for i in range(25): await process_frame
	var m3d = mars_inst.mars_3d
	
	# 4. 360-Degree Mars Inspection Camera
	print("[Capture Stage I] 4. 360-degree Mars inspection camera...")
	mars_inst.modal_site_select.visible = true
	mars_inst._on_cam_orbit_360_pressed()
	m3d.adjust_orbit_angles(0.4, 0.15)
	for i in range(15): await process_frame
	_save_screenshot("screenshots/i4_mars_360_inspection.png")
	
	# 5. Detailed Martian Terrain
	print("[Capture Stage I] 5. Detailed Martian terrain...")
	mars_inst.modal_site_select.visible = false
	m3d.select_landing_site("Jezero Crater")
	m3d.start_surface_mode()
	m3d.set_camera_view(5) # SURFACE_CINEMATIC
	mars_inst.descent_telemetry_panel.visible = false
	mars_inst.rover_telemetry_panel.visible = true
	for i in range(20): await process_frame
	_save_screenshot("screenshots/i5_detailed_martian_terrain.png")
	
	# 6. Animated Rover Deployment
	print("[Capture Stage I] 6. Animated rover deployment...")
	mars_inst.modal_deploy_rover.visible = true
	m3d.set_camera_view(3) # ROVER_CHASE
	if m3d.lander_ramp: m3d.lander_ramp.rotation.x = 0.45
	if m3d.rover_rig: m3d.rover_rig.position = Vector3(0, 0.45, 3.2)
	for i in range(15): await process_frame
	_save_screenshot("screenshots/i6_rover_deployment.png")
	
	# 7. 6-Wheel Rover Driving with Dust Trail
	print("[Capture Stage I] 7. 6-wheel rover driving with dust trail...")
	mars_inst.modal_deploy_rover.visible = false
	m3d.deploy_rover_sequence()
	m3d.rover_speed = 3.6
	if m3d.wheel_dust: m3d.wheel_dust.emitting = true
	if m3d.rover_rig: m3d.rover_rig.position = Vector3(5.0, 0.45, 12.0)
	mars_inst.rover_console.visible = true
	for i in range(15): await process_frame
	_save_screenshot("screenshots/i7_rover_driving.png")
	
	# 8. Four Sequential Science Checkpoints
	print("[Capture Stage I] 8. Four science checkpoints...")
	mars_inst._on_science_lab_pressed()
	for i in range(15): await process_frame
	_save_screenshot("screenshots/i8_four_science_checkpoints.png")
	
	# 9. Instrument Readings & RIMFAX Subsurface Scan
	print("[Capture Stage I] 9. Instrument readings & RIMFAX scan...")
	mars_inst._on_run_exp1_pressed()
	mars_inst._on_run_exp2_pressed()
	for i in range(15): await process_frame
	_save_screenshot("screenshots/i9_instrument_readings.png")
	
	# 10. Viewport Photo Gallery
	print("[Capture Stage I] 10. Viewport photo gallery...")
	mars_inst.modal_sequential_science.visible = false
	mars_inst._on_run_exp3_pressed()
	mars_inst._on_run_exp4_pressed()
	# Capture two photos
	m3d.capture_viewport_photo()
	m3d.capture_viewport_photo()
	mars_inst._on_photo_gallery_pressed()
	for i in range(15): await process_frame
	_save_screenshot("screenshots/i10_rover_photo_gallery.png")
	
	# 11. Deep Space Data Transmission
	print("[Capture Stage I] 11. Deep space data transmission...")
	mars_inst.modal_photo_gallery.visible = false
	mars_inst.modal_data_transmission.visible = true
	mars_inst.progress_bar_dsn.value = 65.0
	for i in range(15): await process_frame
	_save_screenshot("screenshots/i11_deep_space_transmission.png")
	
	# 12. Earth Acknowledgement & Confirmation
	print("[Capture Stage I] 12. Earth acknowledgement & confirmation...")
	mars_inst._on_transmit_confirm_pressed()
	for i in range(15): await process_frame
	_save_screenshot("screenshots/i12_earth_acknowledgement.png")
	
	# 13. Final Mars Sandbox Exploration
	print("[Capture Stage I] 13. Final Mars sandbox exploration...")
	mars_inst.modal_data_transmission.visible = false
	mars_inst._on_enter_sandbox_pressed()
	m3d.set_camera_view(3) # ROVER_CHASE
	if m3d.rover_rig: m3d.rover_rig.position = Vector3(-12.0, 0.45, 18.0)
	for i in range(20): await process_frame
	_save_screenshot("screenshots/i13_final_mars_sandbox.png")
	
	print("[Capture Stage I] All 13 Stage I screenshots successfully captured!")
	quit(0)

func _save_screenshot(path: String) -> void:
	var img = root.get_viewport().get_texture().get_image()
	var err = img.save_png(path)
	if err == OK:
		print("[Capture Stage I] Successfully saved: ", path)
	else:
		print("[Capture Stage I] Error saving ", path, ": ", err)
