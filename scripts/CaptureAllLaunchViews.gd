extends SceneTree

## CaptureAllLaunchViews.gd - Captures all 6 requested launch sequence visual screenshots
## MARS DEEP • NASA Space Apps Challenge 2026

func _init() -> void:
	print("[Capture] Starting All Launch Views Screenshot Generator...")
	var scene = load("res://scenes/LaunchPreparation.tscn")
	var instance = scene.instantiate()
	root.add_child(instance)
	
	# Wait for initial frames to settle
	for i in range(15):
		await process_frame
		
	var r3d = instance.rocket_3d
	
	# 1. Full rocket standing on the launchpad (Pad Overview)
	r3d.set_camera_view(0)
	for i in range(5): await process_frame
	_save_screenshot("screenshots/1_full_rocket_launchpad.png")
	
	# 2. Rocket with countdown visible but unobstructed
	instance.is_countdown_running = true
	instance.countdown_time = 8.5
	instance.lbl_countdown_clock.text = "T - 00:08.5"
	instance.lbl_countdown_status.text = "TERMINAL COUNTDOWN IN PROGRESS"
	for i in range(5): await process_frame
	_save_screenshot("screenshots/2_rocket_countdown_unobstructed.png")
	
	# 3. Under-rocket engine camera
	r3d.set_camera_view(2) # CAM_UNDER_ROCKET
	for i in range(5): await process_frame
	_save_screenshot("screenshots/3_under_rocket_camera.png")
	
	# 4. Cockpit throttle control
	r3d.set_camera_view(3) # CAM_COCKPIT
	instance.set_player_throttle(0.45)
	for i in range(5): await process_frame
	_save_screenshot("screenshots/4_cockpit_throttle_control.png")
	
	# 5. Ignition with smoke and exhaust in flame trench
	r3d.set_camera_view(2) # CAM_UNDER_ROCKET
	r3d.ignite_engines(0.75)
	instance.engines_at_idle = true
	instance.set_player_throttle(0.75)
	instance.lbl_countdown_status.text = "MAIN ENGINE IGNITION • ALL SYSTEMS GO"
	for i in range(12): await process_frame
	_save_screenshot("screenshots/5_ignition_smoke_exhaust.png")
	
	# 6. Rocket lifting off
	r3d.set_camera_view(4) # CAM_TRACKING_LIFTOFF
	r3d.release_clamps()
	instance.set_player_throttle(1.0)
	# Advance ascent physics
	for i in range(35):
		r3d._process_liftoff_physics(0.05)
		await process_frame
	instance.lbl_countdown_status.text = "CLAMPS RELEASED • LIFTOFF! MARS BOUND!"
	for i in range(5): await process_frame
	_save_screenshot("screenshots/6_rocket_lifting_off.png")
	
	print("[Capture] All 6 screenshots successfully captured!")
	quit(0)

func _save_screenshot(path: String) -> void:
	var img = root.get_viewport().get_texture().get_image()
	var err = img.save_png(path)
	if err == OK:
		print("[Capture] Saved: ", path)
	else:
		print("[Capture] Error saving ", path, ": ", err)
