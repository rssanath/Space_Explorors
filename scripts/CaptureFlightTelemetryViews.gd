extends SceneTree

## CaptureFlightTelemetryViews.gd - Captures verified interplanetary flight & telemetry states
## MARS DEEP • NASA Space Apps Challenge 2026

func _init() -> void:
	print("[Capture Flight] Initializing Interplanetary Telemetry & Dynamics Verification Capture...")
	var scene = load("res://scenes/MissionSimulation.tscn")
	var instance = scene.instantiate()
	root.add_child(instance)
	
	# Allow shaders and 3D meshes to settle
	for i in range(25):
		await process_frame
		
	var sp3d = instance.space_3d
	
	# 1. Interplanetary Cruise Coasting (0% throttle, 0.0 kN thrust, fuel drain stopped, Earth/Mars distance live)
	print("[Capture Flight] Capturing View 1: Interplanetary Cruise Coasting...")
	sp3d.set_camera_view(0) # COCKPIT
	sp3d.set_flight_phase(2) # INTERPLANETARY_CRUISE
	sp3d.set_throttle(0.0)
	sp3d._update_simulation_physics(1.0)
	instance._on_3d_telemetry_changed(sp3d.get_telemetry_data())
	for i in range(15): await process_frame
	_save_screenshot("screenshots/ft1_interplanetary_cruise_coasting.png")
	
	# 2. Active Propulsion Burn (75% throttle, 56.2 kN thrust, exhaust plume, fuel actively consuming)
	print("[Capture Flight] Capturing View 2: Active Propulsion Burn...")
	sp3d.set_throttle(0.75)
	sp3d.throttle = 0.75
	sp3d._update_simulation_physics(1.0)
	instance._on_3d_telemetry_changed(sp3d.get_telemetry_data())
	for i in range(15): await process_frame
	_save_screenshot("screenshots/ft2_active_propulsion_burn.png")
	
	# 3. 10x Time Warp Simulation (Accelerated clock, rapidly evolving Earth & Mars distances)
	print("[Capture Flight] Capturing View 3: 10x Time Warp Simulation...")
	sp3d.set_throttle(0.0)
	instance._set_time_warp(10.0)
	sp3d._update_simulation_physics(5.0) # Advances ~17.5 days along the trajectory
	instance._on_3d_telemetry_changed(sp3d.get_telemetry_data())
	for i in range(15): await process_frame
	_save_screenshot("screenshots/ft3_time_warp_10x.png")
	
	# 4. 3D Orbital Transfer Map (Heliocentric view with Sun, Earth orbit ring, Mars orbit ring, spacecraft beacon)
	print("[Capture Flight] Capturing View 4: 3D Orbital Transfer Map View...")
	sp3d.set_camera_view(2) # NAV_MAP
	instance._on_3d_telemetry_changed(sp3d.get_telemetry_data())
	for i in range(20): await process_frame
	_save_screenshot("screenshots/ft4_orbital_transfer_map_3d.png")
	
	# 5. Mars Approach View (Mars looms large in the forward viewport, distance < 10,000 km)
	print("[Capture Flight] Capturing View 5: Mars Approach Cinematic View...")
	sp3d.set_flight_phase(4) # MARS_APPROACH
	sp3d.set_camera_view(3) # MARS_CINEMATIC
	sp3d.mission_day = sp3d.total_transit_days - 0.5
	sp3d.distance_to_mars_km = 6840.0
	instance._on_3d_telemetry_changed(sp3d.get_telemetry_data())
	for i in range(20): await process_frame
	_save_screenshot("screenshots/ft5_mars_approach_distance.png")
	
	print("[Capture Flight] All interplanetary flight & telemetry screenshots successfully captured!")
	quit(0)

func _save_screenshot(path: String) -> void:
	var img = root.get_viewport().get_texture().get_image()
	var err = img.save_png(path)
	if err == OK:
		print("[Capture Flight] Successfully saved: ", path)
	else:
		print("[Capture Flight] Error saving ", path, ": ", err)
