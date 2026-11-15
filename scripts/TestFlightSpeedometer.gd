extends Node

## TestFlightSpeedometer.gd
## Verifies that after liftoff, as throttle is applied:
## 1. Velocity speedometer runs and updates.
## 2. Distance from Earth runs and increases.
## 3. Distance to Mars runs and decreases towards Mars.
## 4. Spacecraft 3D model physically moves forward along the trajectory arc.

func _ready() -> void:
	print("==================================================")
	print("VERIFYING FLIGHT SPEEDOMETER & MARS TRAJECTORY DYNAMICS")
	print("==================================================")
	
	var ms_scene = load("res://scenes/MissionSimulation.tscn")
	if not ms_scene:
		print("FAIL: Could not load MissionSimulation.tscn")
		get_tree().quit(1)
		return
		
	var ms_inst = ms_scene.instantiate()
	add_child(ms_inst)
	
	var sf = ms_inst.space_3d
	if not sf:
		print("FAIL: space_3d node missing")
		get_tree().quit(1)
		return
		
	# Check initial state in Earth parking orbit
	var v_init = sf.velocity_kms
	var d_earth_init = sf.distance_from_earth_km
	var d_mars_init = sf.distance_to_mars_km
	var z_init = sf.spacecraft_rig.position.z if sf.spacecraft_rig else 0.0
	
	print("[Initial State]")
	print("  Velocity: %.2f km/s" % v_init)
	print("  Distance Earth: %.0f km" % d_earth_init)
	print("  Distance Mars: %.2f M km" % (d_mars_init / 1000000.0))
	print("  Craft Z: %.2f m" % z_init)
	
	# Action: Player throttles up to 100% to accelerate towards Mars
	print("\n[Action] Player throttles up to 100%...")
	ms_inst._step_throttle(1.0)
	
	# Simulate physics tick (2.0 seconds)
	for i in range(20):
		sf._update_simulation_physics(0.1)
		ms_inst._on_3d_telemetry_changed(sf.get_telemetry_data())
		
	var v_burn = sf.velocity_kms
	var d_earth_burn = sf.distance_from_earth_km
	var d_mars_burn = sf.distance_to_mars_km
	var z_burn = sf.spacecraft_rig.position.z if sf.spacecraft_rig else 0.0
	
	print("\n[After TMI Burn Acceleration]")
	print("  Velocity (Speedometer): %.2f km/s (Initial: %.2f km/s)" % [v_burn, v_init])
	print("  Distance from Earth: %.0f km (Initial: %.0f km)" % [d_earth_burn, d_earth_init])
	print("  Distance to Mars: %.2f M km (Initial: %.2f M km)" % [d_mars_burn / 1000000.0, d_mars_init / 1000000.0])
	print("  Craft Z Position: %.2f m (Initial: %.2f m)" % [z_burn, z_init])
	print("  HUD Speed Label: %s" % ms_inst.lbl_speed_val.text)
	print("  HUD Earth Dist: %s" % ms_inst.lbl_dist_earth_val.text)
	print("  HUD Mars Dist: %s" % ms_inst.lbl_dist_mars_val.text)
	
	var v_increased = v_burn > v_init
	var d_earth_increased = d_earth_burn > d_earth_init
	var craft_moved_forward = z_burn < z_init # Negative Z is towards Mars
	
	# Now advance into interplanetary cruise
	print("\n[Action] Advancing along interplanetary cruise trajectory...")
	sf.time_warp_scale = 10.0
	for i in range(50):
		sf._update_simulation_physics(0.5)
		sf._update_3d_spatial_scene(0.5)
		ms_inst._on_3d_telemetry_changed(sf.get_telemetry_data())
		
	var v_cruise = sf.velocity_kms
	var d_earth_cruise = sf.distance_from_earth_km
	var d_mars_cruise = sf.distance_to_mars_km
	var z_cruise = sf.spacecraft_rig.position.z if sf.spacecraft_rig else 0.0
	
	print("\n[Deep Space Cruise Progress]")
	print("  Velocity (Speedometer): %.2f km/s" % v_cruise)
	print("  Distance from Earth: %.2f M km" % (d_earth_cruise / 1000000.0))
	print("  Distance to Mars: %.2f M km" % (d_mars_cruise / 1000000.0))
	print("  Craft Z Position: %.2f m" % z_cruise)
	print("  HUD Speed Label: %s" % ms_inst.lbl_speed_val.text)
	print("  HUD Earth Dist: %s" % ms_inst.lbl_dist_earth_val.text)
	print("  HUD Mars Dist: %s" % ms_inst.lbl_dist_mars_val.text)
	
	var cruise_earth_increased = d_earth_cruise > d_earth_burn
	var cruise_mars_decreased = d_mars_cruise < d_mars_burn
	var craft_traveled_towards_mars = z_cruise < z_burn
	
	print("\n==================================================")
	print("VERIFICATION CHECKLIST:")
	print("  1. Speedometer accelerates on throttle: %s" % ("PASS" if v_increased else "FAIL"))
	print("  2. Distance from Earth runs & increases: %s" % ("PASS" if d_earth_increased and cruise_earth_increased else "FAIL"))
	print("  3. Distance to Mars counts down towards Mars: %s" % ("PASS" if cruise_mars_decreased else "FAIL"))
	print("  4. 3D Spacecraft travels physically towards Mars: %s" % ("PASS" if craft_moved_forward and craft_traveled_towards_mars else "FAIL"))
	print("==================================================")
	
	if v_increased and d_earth_increased and cruise_earth_increased and cruise_mars_decreased and craft_traveled_towards_mars:
		print("SUCCESS: Flight speedometer and Mars movement are 100% functional and verified!")
		get_tree().quit(0)
	else:
		print("FAILURE: Flight speedometer or Mars movement failed check.")
		get_tree().quit(1)
