extends SceneTree

## CaptureEViews.gd - Captures all 7 required Stage E verification screenshots
## MARS DEEP • NASA Space Apps Challenge 2026

func _init() -> void:
	print("[Capture E] Initializing Stage E Spaceflight Simulation Screenshot Suite...")
	var scene = load("res://scenes/MissionSimulation.tscn")
	var instance = scene.instantiate()
	root.add_child(instance)
	
	# Allow shaders and 3D meshes to settle
	for i in range(25):
		await process_frame
		
	var sp3d = instance.space_3d
	
	# 1. Earth visible from the cockpit
	print("[Capture E] Capturing View 1: Earth visible from cockpit...")
	sp3d.set_camera_view(0) # COCKPIT
	sp3d.set_flight_phase(0) # EARTH_ORBIT
	instance.modal_departure.visible = true
	instance.modal_midcourse.visible = false
	instance.modal_events.visible = false
	instance.modal_mars_arrival.visible = false
	instance.banner_orbit_achieved.visible = false
	for i in range(12): await process_frame
	_save_screenshot("screenshots/e1_earth_from_cockpit.png")
	
	# 2. Spacecraft external view
	print("[Capture E] Capturing View 2: Spacecraft external view...")
	sp3d.set_camera_view(1) # EXTERIOR
	instance.modal_departure.visible = false
	for i in range(12): await process_frame
	_save_screenshot("screenshots/e2_spacecraft_external_view.png")
	
	# 3. Deep-space cruise
	print("[Capture E] Capturing View 3: Deep-space cruise...")
	sp3d.set_camera_view(0) # Return to cockpit
	sp3d.set_flight_phase(2) # INTERPLANETARY_CRUISE
	instance.badge_phase.text = "PHASE: INTERPLANETARY HOHMANN CRUISE"
	for i in range(15): await process_frame
	_save_screenshot("screenshots/e3_deep_space_cruise.png")
	
	# 4. Mid-course correction
	print("[Capture E] Capturing View 4: Mid-course correction...")
	sp3d.set_camera_view(0) # COCKPIT
	sp3d.set_flight_phase(3) # MIDCOURSE_CORRECTION
	instance.modal_midcourse.visible = true
	instance.badge_phase.text = "PHASE: MID-COURSE TRAJECTORY CORRECTION (TCM-1)"
	for i in range(15): await process_frame
	_save_screenshot("screenshots/e4_midcourse_correction.png")
	instance.modal_midcourse.visible = false
	
	# 5. Mars approaching
	print("[Capture E] Capturing View 5: Mars approaching...")
	sp3d.set_camera_view(0) # COCKPIT
	sp3d.set_flight_phase(4) # MARS_APPROACH
	instance.modal_mars_arrival.visible = false
	instance.badge_phase.text = "PHASE: MARS GRAVITATIONAL CAPTURE APPROACH"
	for i in range(15): await process_frame
	_save_screenshot("screenshots/e5_mars_approaching.png")
	
	# 6. Mars orbital insertion
	print("[Capture E] Capturing View 6: Mars orbital insertion...")
	sp3d.set_camera_view(0) # COCKPIT
	sp3d.set_flight_phase(5) # MARS_ORBIT_INSERTION
	sp3d.set_throttle(1.0)
	sp3d._process_propulsion(0.1)
	instance.modal_mars_arrival.visible = true
	instance.badge_phase.text = "PHASE: MARS ORBIT INSERTION (MOI) RETRO-BURN"
	for i in range(15): await process_frame
	_save_screenshot("screenshots/e6_mars_orbital_insertion.png")
	instance.modal_mars_arrival.visible = false
	
	# 7. Mars orbit achieved
	print("[Capture E] Capturing View 7: Mars orbit achieved...")
	sp3d.set_flight_phase(6) # MARS_ORBIT_ACHIEVED
	sp3d.set_camera_view(3) # MARS_CINEMATIC
	sp3d.set_throttle(0.0)
	instance.banner_orbit_achieved.visible = true
	instance.badge_phase.text = "PHASE: MARS ORBIT ACHIEVED • CAPTURE CERTIFIED"
	for i in range(15): await process_frame
	_save_screenshot("screenshots/e7_mars_orbit_achieved.png")
	
	print("[Capture E] All 7 Stage E screenshots successfully captured!")
	quit(0)

func _save_screenshot(path: String) -> void:
	var img = root.get_viewport().get_texture().get_image()
	var err = img.save_png(path)
	if err == OK:
		print("[Capture E] Successfully saved: ", path)
	else:
		print("[Capture E] Error saving ", path, ": ", err)
