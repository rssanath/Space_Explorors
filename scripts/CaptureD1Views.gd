extends SceneTree

## CaptureD1Views.gd - Captures the 5 required Stage D.1 verification screenshots
## MARS DEEP • NASA Space Apps Challenge 2026

func _init() -> void:
	print("[Capture D.1] Initializing Stage D.1 Launch Experience Screenshot Suite...")
	var scene = load("res://scenes/LaunchPreparation.tscn")
	var instance = scene.instantiate()
	root.add_child(instance)
	
	# Allow shaders and meshes to compile and settle
	for i in range(25):
		await process_frame
		
	var r3d = instance.rocket_3d
	
	# VIEW 1: Under-rocket camera actually showing the engine bells, clamps, trench
	print("[Capture D.1] Capturing View 1: Under-Rocket Engines & Clamps...")
	r3d.set_camera_view(2) # CAM_UNDER_ROCKET
	instance.is_countdown_running = true
	instance.countdown_time = 5.0
	instance.lbl_countdown_clock.text = "T - 00:05.0"
	instance.lbl_countdown_status.text = "CAM 3: UNDER-ROCKET TRENCH VIEW • NOZZLES & CLAMPS READY"
	for i in range(12): await process_frame
	_save_screenshot("screenshots/d1_under_rocket_engines.png")
	
	# VIEW 2: Moving 3D throttle lever in cockpit
	print("[Capture D.1] Capturing View 2: Moving 3D Throttle Lever in Cockpit...")
	r3d.set_camera_view(3) # CAM_COCKPIT
	instance.set_player_throttle(0.90) # Lever pushed to 90%
	r3d.set_throttle_visual(0.90)
	instance.lbl_countdown_status.text = "CAM 4: FLIGHT DECK • 3D THROTTLE LEVER AT 90% LAUNCH THRESHOLD"
	for i in range(12): await process_frame
	_save_screenshot("screenshots/d1_moving_throttle_lever.png")
	
	# VIEW 3: Ignition in flame trench
	print("[Capture D.1] Capturing View 3: Ignition in Flame Trench...")
	r3d.set_camera_view(2) # CAM_UNDER_ROCKET
	r3d.ignite_engines(0.85)
	instance.engines_at_idle = true
	instance.set_player_throttle(0.85)
	instance.lbl_countdown_status.text = "MAIN ENGINE IGNITION • FLAME DEFLECTOR ACTIVE • 85% THROTTLE"
	for i in range(20): await process_frame
	_save_screenshot("screenshots/d1_ignition_trench.png")
	
	# VIEW 4: Rocket physically separating from launchpad
	print("[Capture D.1] Capturing View 4: Rocket Physically Separating from Launchpad...")
	r3d.set_camera_view(1) # CAM_ENGINES_CLOSE (showing pad separation & retracted clamps)
	r3d.release_clamps()
	instance.set_player_throttle(1.0)
	# Advance liftoff physics by ~1.5 seconds of upward motion
	for step in range(30):
		r3d._process_liftoff_physics(0.05)
		await process_frame
	instance.lbl_countdown_status.text = "HOLD-DOWN CLAMPS RELEASED • VERTICAL LIFTOFF CONFIRMED"
	for i in range(12): await process_frame
	_save_screenshot("screenshots/d1_rocket_pad_separation.png")
	
	# VIEW 5: Ascent tracking camera following rocket smoothly
	print("[Capture D.1] Capturing View 5: Ascent Tracking Camera Smooth Follow...")
	r3d.set_camera_view(4) # CAM_TRACKING_LIFTOFF
	# Advance ascent physics further to 25m+ altitude
	for step in range(45):
		r3d._process_liftoff_physics(0.05)
		await process_frame
	instance.lbl_countdown_status.text = "ASCENT TRACKING • TOWER CLEARED • NOMINAL FLIGHT"
	for i in range(15): await process_frame
	_save_screenshot("screenshots/d1_ascent_tracking.png")
	
	print("[Capture D.1] All 5 Stage D.1 screenshots successfully captured!")
	quit(0)

func _save_screenshot(path: String) -> void:
	var img = root.get_viewport().get_texture().get_image()
	var err = img.save_png(path)
	if err == OK:
		print("[Capture D.1] Successfully saved: ", path)
	else:
		print("[Capture D.1] Error saving ", path, ": ", err)
