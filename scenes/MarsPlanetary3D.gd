extends Node3D

## MarsPlanetary3D.gd - 3D Mars Landing, EDL Descent & Surface Rover Simulation Engine
## Handles orbital site selection, powered descent physics, landing evaluation, 6-wheel rover driving, and 5 science objectives.

const GameManagerRef = preload("res://scripts/GameManager.gd")
const LaunchAudioRef = preload("res://scripts/LaunchAudio.gd")

enum GameSceneMode {
	ORBIT = 0,
	DESCENT = 1,
	SURFACE = 2
}

enum CameraViewMode {
	ORBIT_VIEW = 0,
	COCKPIT_DESCENT = 1,
	EXTERIOR_DESCENT = 2,
	ROVER_CHASE = 3,
	ROVER_MAST = 4,
	SURFACE_CINEMATIC = 5,
	ORBIT_INSPECT_360 = 6,
	ROVER_INSPECT_360 = 7
}

enum LandingOutcome {
	NONE,
	PERFECT,
	SAFE,
	HARD,
	FAILED
}

@export var scene_mode: GameSceneMode = GameSceneMode.ORBIT
@export var camera_mode: CameraViewMode = CameraViewMode.ORBIT_VIEW

# Orbit 360 Inspection Camera (Stage I Part 3)
var cam_orbit_pivot: Node3D = null
var cam_orbit_360: Camera3D = null
var orbit_cam_yaw: float = 0.0
var orbit_cam_pitch: float = 0.15
var orbit_cam_dist: float = 38.0
var is_orbit_mouse_dragging: bool = false
var site_indicator_mesh: MeshInstance3D = null

# Landing Sites Catalog (Stage I Part 3)
const LANDING_SITES: Dictionary = {
	"Jezero Crater": {
		"name": "Jezero Crater",
		"coordinates": "18.38° N, 77.58° E",
		"difficulty": "Medium-High",
		"terrain_type": "Ancient River Delta, Clay Mudstones & Boulder Fields",
		"science_objectives": "Sample lacustrine delta clay sediments for potential ancient biosignatures; date volcanic crater floor.",
		"target_offset": Vector3(-4.0, 0, 5.0)
	},
	"Gale Crater": {
		"name": "Gale Crater",
		"coordinates": "5.37° S, 137.81° E",
		"difficulty": "Medium",
		"terrain_type": "Sedimentary Terraces & Mount Sharp Slopes",
		"science_objectives": "Investigate layered aqueous stratigraphy; measure sulfate-clay transitions in ancient lake bed.",
		"target_offset": Vector3(6.0, 0, -4.0)
	},
	"Elysium Planitia": {
		"name": "Elysium Planitia",
		"coordinates": "4.50° N, 135.90° E",
		"difficulty": "Low-Medium",
		"terrain_type": "Smooth Volcanic Plains & Basaltic Lowlands",
		"science_objectives": "Survey subsurface structural layering and geothermal heat flow; low boulder collision risk.",
		"target_offset": Vector3(0.0, 0, 0.0)
	}
}

# Sequential Missions & Photography State (Stage I Parts 7, 8, 9, 10)
var current_mission_idx: int = 1
var captured_photos: Array[Dictionary] = []
var data_transmitted_to_earth: bool = false
var sandbox_mode_active: bool = false
var surface_features_generated: bool = false
var is_deploying_rover: bool = false

# Checkpoint Beacons & Records
var experiment_records: Dictionary = {
	1: {
		"id": "EXP_01_GEOLOGY",
		"name": "Geological Rock Analysis",
		"target_name": "Ancient Delta Rock Formation",
		"location": Vector3(-18.0, 0.6, 22.0),
		"instrument": "Mastcam-Z & SuperCam LIBS Laser",
		"completed": false,
		"data": {}
	},
	2: {
		"id": "EXP_02_SUBSURFACE",
		"name": "Subsurface Radar Stratigraphy",
		"target_name": "Sedimentary Stratum Outcrop",
		"location": Vector3(24.0, 0.6, -16.0),
		"instrument": "RIMFAX Ground-Penetrating Radar",
		"completed": false,
		"data": {}
	},
	3: {
		"id": "EXP_03_ATMOSPHERE",
		"name": "Atmospheric & Environmental Monitoring",
		"target_name": "Exposed Martian Plain",
		"location": Vector3(-26.0, 0.6, -20.0),
		"instrument": "MEDA Environmental Sensor Station",
		"completed": false,
		"data": {}
	},
	4: {
		"id": "EXP_04_SAMPLE",
		"name": "Sample Collection & Elemental Analysis",
		"target_name": "Sample Cache Outcrop",
		"location": Vector3(22.0, 0.6, 24.0),
		"instrument": "Robotic Arm Drill, PIXL & SHERLOC",
		"completed": false,
		"data": {}
	}
}

# Node References - Environments & Celestial
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var orbit_scene: Node3D = $OrbitScene
@onready var mars_globe: MeshInstance3D = $OrbitScene/MarsGlobe
@onready var descent_scene: Node3D = $DescentScene
@onready var surface_scene: Node3D = $SurfaceScene

# Descent Nodes
@onready var descent_craft: Node3D = $DescentScene/DescentCraft
@onready var parachute_rig: Node3D = $DescentScene/DescentCraft/ParachuteRig
@onready var heatshield_glow: MeshInstance3D = $DescentScene/DescentCraft/HeatShieldGlow
@onready var descent_flame: MeshInstance3D = $DescentScene/DescentCraft/DescentFlame
@onready var descent_particles: CPUParticles3D = $DescentScene/DescentCraft/DescentParticles
@onready var touchdown_dust: CPUParticles3D = $DescentScene/DescentCraft/TouchdownDust

# Rover Nodes
@onready var rover_rig: Node3D = $SurfaceScene/RoverRig
@onready var rover_mast: Node3D = $SurfaceScene/RoverRig/MastAssembly
@onready var robotic_arm: Node3D = $SurfaceScene/RoverRig/RoboticArm
@onready var arm_tool: MeshInstance3D = $SurfaceScene/RoverRig/RoboticArm/ToolHead
@onready var wheels: Array[MeshInstance3D] = [
	$SurfaceScene/RoverRig/Wheels/Wheel_FL,
	$SurfaceScene/RoverRig/Wheels/Wheel_ML,
	$SurfaceScene/RoverRig/Wheels/Wheel_RL,
	$SurfaceScene/RoverRig/Wheels/Wheel_FR,
	$SurfaceScene/RoverRig/Wheels/Wheel_MR,
	$SurfaceScene/RoverRig/Wheels/Wheel_RR
]
@onready var wheel_dust: CPUParticles3D = $SurfaceScene/RoverRig/WheelDust

# Lander on Surface
@onready var lander_surface: Node3D = $SurfaceScene/LanderStation
@onready var lander_ramp: MeshInstance3D = $SurfaceScene/LanderStation/DeployRamp

# Science Targets on Surface
@onready var science_targets_group: Node3D = $SurfaceScene/ScienceTargets
@onready var target_water: Node3D = $SurfaceScene/ScienceTargets/Target_Water
@onready var target_rock: Node3D = $SurfaceScene/ScienceTargets/Target_Rock
@onready var target_radar: Node3D = $SurfaceScene/ScienceTargets/Target_Subsurface
@onready var target_weather: Node3D = $SurfaceScene/ScienceTargets/Target_Weather
@onready var target_moxie: Node3D = $SurfaceScene/ScienceTargets/Target_MOXIE

# Cameras
@onready var cam_orbit: Camera3D = $OrbitScene/CamOrbit
@onready var cam_cockpit_descent: Camera3D = $DescentScene/DescentCraft/CockpitInterior/CamCockpitDescent
@onready var cam_exterior_descent: Camera3D = $DescentScene/DescentCraft/CamExteriorDescent
@onready var cam_rover_chase: Camera3D = $SurfaceScene/RoverRig/CamPivot/CamRoverChase
@onready var cam_rover_pivot: Node3D = $SurfaceScene/RoverRig/CamPivot
@onready var cam_rover_mast: Camera3D = $SurfaceScene/RoverRig/MastAssembly/CamRoverMast
@onready var cam_surface_cinematic: Camera3D = $SurfaceScene/CamSurfaceCinematic

# Audio
@onready var audio_engine: AudioStreamPlayer = $AudioEngine
@onready var audio_chatter: AudioStreamPlayer = $AudioChatter
@onready var audio_rover: AudioStreamPlayer = $AudioRover

# Descent Flight State
var descent_altitude_m: float = 8500.0
var descent_vertical_speed_ms: float = 65.0
var descent_horizontal_speed_ms: float = 12.0
var descent_fuel_kg: float = 240.0
var descent_thrust_pct: float = 0.0 # 0.0 to 1.0
var parachute_deployed: bool = false
var heatshield_jettisoned: bool = false
var landing_gear_deployed: bool = false
var is_touchdown_complete: bool = false
var landing_outcome: LandingOutcome = LandingOutcome.NONE
var selected_landing_site: String = "Jezero Crater"

# Rover Driving State
var rover_speed: float = 0.0 # m/s
var rover_max_speed: float = 4.5 # m/s
var rover_heading_rad: float = 0.0
var rover_battery_wh: float = 1200.0 # 1200 Wh battery capacity
var rover_distance_traveled_m: float = 0.0
var rover_steering_input: float = 0.0
var rover_throttle_input: float = 0.0
var is_rover_deployed: bool = false
var chase_cam_yaw: float = 0.0
var chase_cam_pitch: float = -0.25
var chase_cam_dist: float = 4.2
var is_mouse_looking: bool = false

# Science Discoveries & Samples State
var collected_samples: Array[Dictionary] = []
var completed_science_objectives: Dictionary = {
	"WATER": false,
	"ROCK": false,
	"RADAR": false,
	"WEATHER": false,
	"MOXIE": false
}
var active_nearest_target_name: String = ""
var active_nearest_target_dist: float = 999.0

# Signals
signal descent_telemetry_updated(data: Dictionary)
signal touchdown_occurred(outcome: LandingOutcome, vertical_speed: float)
signal rover_telemetry_updated(data: Dictionary)
signal sample_collected(sample_info: Dictionary)
signal objective_completed(obj_id: String, details: Dictionary)
signal photo_captured(photo_info: Dictionary)
signal experiment_completed(exp_idx: int, exp_data: Dictionary)
signal data_transmitted(status: Dictionary)
signal rover_deployed()

func _ready() -> void:
	print("[MarsPlanetary3D] Initializing Mars Landing & Planetary Exploration Simulation...")
	_setup_audio()
	_setup_orbit_360_camera()
	_setup_surface_environment()
	_setup_detailed_rover_model()
	set_scene_mode(GameSceneMode.ORBIT)

func _setup_audio() -> void:
	if audio_engine:
		audio_engine.stream = LaunchAudioRef.create_engine_rumble(2.0)
		audio_engine.volume_db = -80.0
	if audio_chatter:
		audio_chatter.stream = LaunchAudioRef.create_radio_chatter()
		audio_chatter.volume_db = -6.0
	if audio_rover:
		audio_rover.stream = LaunchAudioRef.create_rcs_burst()
		audio_rover.volume_db = -18.0

func _process(delta: float) -> void:
	match scene_mode:
		GameSceneMode.ORBIT:
			_process_orbit_mode(delta)
		GameSceneMode.DESCENT:
			_process_descent_mode(delta)
		GameSceneMode.SURFACE:
			_process_surface_mode(delta)

# =========================================================================
# MODE 1: MARS ORBIT
# =========================================================================

func _process_orbit_mode(delta: float) -> void:
	if mars_globe:
		mars_globe.rotate_y(delta * 0.03)

func select_landing_site(site_name: String) -> void:
	selected_landing_site = site_name
	print("[MarsPlanetary3D] Landing site selected: %s" % site_name)

# =========================================================================
# MODE 2: POWERED ENTRY, DESCENT & LANDING (EDL)
# =========================================================================

func start_descent_sequence() -> void:
	set_scene_mode(GameSceneMode.DESCENT)
	descent_altitude_m = 8500.0
	descent_vertical_speed_ms = 75.0
	descent_horizontal_speed_ms = 18.0
	descent_fuel_kg = 240.0
	descent_thrust_pct = 0.35
	parachute_deployed = true
	heatshield_jettisoned = false
	landing_gear_deployed = false
	is_touchdown_complete = false
	landing_outcome = LandingOutcome.NONE
	set_camera_view(CameraViewMode.COCKPIT_DESCENT)
	print("[MarsPlanetary3D] Entry, Descent and Landing (EDL) initiated from 8,500m.")

func _process_descent_mode(delta: float) -> void:
	if is_touchdown_complete:
		return
		
	# Atmospheric & Powered Descent Physics
	var mars_g := 3.72 # m/s²
	var max_engine_accel := 12.5 # m/s² at 100% thrust
	
	# Parachute drag deceleration
	var chute_drag := 2.8 if parachute_deployed and descent_altitude_m > 800.0 else 0.0
	var engine_accel := max_engine_accel * descent_thrust_pct if descent_fuel_kg > 0.0 else 0.0
	
	var net_vertical_accel := mars_g - (engine_accel + chute_drag)
	descent_vertical_speed_ms += net_vertical_accel * delta
	descent_vertical_speed_ms = clampf(descent_vertical_speed_ms, -2.0, 120.0) # Downward is positive speed
	
	descent_horizontal_speed_ms = move_toward(descent_horizontal_speed_ms, 0.0, delta * 2.2)
	descent_altitude_m -= descent_vertical_speed_ms * delta
	
	# Jettison heat shield & parachute milestones
	if descent_altitude_m < 3500.0 and not heatshield_jettisoned:
		heatshield_jettisoned = true
		if heatshield_glow: heatshield_glow.visible = false
		print("[MarsPlanetary3D] Heat shield jettisoned. Ground radar acquired.")
		
	if descent_altitude_m < 800.0 and parachute_deployed:
		parachute_deployed = false
		if parachute_rig: parachute_rig.visible = false
		landing_gear_deployed = true
		print("[MarsPlanetary3D] Parachute released. Powered descent retro-burn active.")
		
	# Consume landing fuel
	if descent_thrust_pct > 0.01 and descent_fuel_kg > 0.0:
		var fuel_rate := 3.5 * descent_thrust_pct
		descent_fuel_kg = maxf(0.0, descent_fuel_kg - fuel_rate * delta)
		
	# Engine plume visuals
	var is_firing := descent_thrust_pct > 0.05 and descent_fuel_kg > 0.0
	if descent_flame:
		descent_flame.visible = is_firing
		descent_flame.scale = Vector3(1.0, lerpf(0.5, 2.5, descent_thrust_pct), 1.0)
	if descent_particles:
		descent_particles.emitting = is_firing
		descent_particles.speed_scale = lerpf(1.0, 3.0, descent_thrust_pct)
		
	# Cockpit vibration during descent
	if cam_cockpit_descent and camera_mode == CameraViewMode.COCKPIT_DESCENT:
		var shake := (randf() - 0.5) * 0.025 * (descent_vertical_speed_ms / 60.0 + descent_thrust_pct * 0.5)
		cam_cockpit_descent.h_offset = shake
		cam_cockpit_descent.v_offset = shake
		
	# Audio update
	if audio_engine:
		if is_firing:
			if not audio_engine.playing:
				audio_engine.volume_db = -40.0
				audio_engine.play()
			audio_engine.volume_db = lerpf(-18.0, 2.0, descent_thrust_pct)
			audio_engine.pitch_scale = lerpf(0.85, 1.25, descent_thrust_pct)
		else:
			if audio_engine.playing: audio_engine.stop()
			
	# Move descent craft mesh downward
	if descent_craft:
		var display_y := clampf(descent_altitude_m * 0.01, 0.0, 85.0)
		descent_craft.position.y = display_y
		
	# Touchdown detection at surface (altitude <= 0.0)
	if descent_altitude_m <= 0.0:
		descent_altitude_m = 0.0
		_evaluate_touchdown()
		
	# Emit descent telemetry
	var data: Dictionary = {
		"altitude_m": descent_altitude_m,
		"vertical_speed_ms": descent_vertical_speed_ms,
		"horizontal_speed_ms": descent_horizontal_speed_ms,
		"fuel_kg": descent_fuel_kg,
		"thrust_pct": int(descent_thrust_pct * 100.0),
		"chute_deployed": parachute_deployed,
		"landing_gear": landing_gear_deployed,
		"site": selected_landing_site
	}
	descent_telemetry_updated.emit(data)

func _evaluate_touchdown() -> void:
	is_touchdown_complete = true
	descent_thrust_pct = 0.0
	if descent_flame: descent_flame.visible = false
	if descent_particles: descent_particles.emitting = false
	if audio_engine: audio_engine.stop()
	if touchdown_dust: touchdown_dust.restart()
	
	# Determine landing outcome by touchdown vertical velocity
	if descent_vertical_speed_ms < 1.5 and descent_horizontal_speed_ms < 1.0:
		landing_outcome = LandingOutcome.PERFECT
	elif descent_vertical_speed_ms < 3.2:
		landing_outcome = LandingOutcome.SAFE
	elif descent_vertical_speed_ms < 5.0:
		landing_outcome = LandingOutcome.HARD
	else:
		landing_outcome = LandingOutcome.FAILED
		
	touchdown_occurred.emit(landing_outcome, descent_vertical_speed_ms)
	print("[MarsPlanetary3D] Touchdown complete! Outcome: %s (Touchdown Speed: %.2f m/s)." % [
		get_landing_outcome_name(), descent_vertical_speed_ms
	])

func get_landing_outcome_name() -> String:
	match landing_outcome:
		LandingOutcome.PERFECT: return "PERFECT TOUCHDOWN • NOMINAL SPECS"
		LandingOutcome.SAFE: return "SAFE TOUCHDOWN • ALL SYSTEMS OPERATIONAL"
		LandingOutcome.HARD: return "HARD LANDING • MINOR STRUCTURAL STRESS"
		LandingOutcome.FAILED: return "TOUCHDOWN FAILED • VELOCITY LIMIT EXCEEDED"
		_: return "UNDETERMINED"

func adjust_descent_thrust(delta_thrust: float) -> void:
	descent_thrust_pct = clampf(descent_thrust_pct + delta_thrust, 0.0, 1.0)

func adjust_horizontal_drift(lateral_delta: float) -> void:
	descent_horizontal_speed_ms = clampf(descent_horizontal_speed_ms + lateral_delta, -10.0, 10.0)

# =========================================================================
# MODE 3: MARS SURFACE & ROVER DRIVING
# =========================================================================

func start_surface_mode() -> void:
	set_scene_mode(GameSceneMode.SURFACE)
	is_rover_deployed = false
	rover_speed = 0.0
	rover_heading_rad = 0.0
	rover_distance_traveled_m = 0.0
	rover_battery_wh = 1200.0
	if rover_rig:
		rover_rig.position = Vector3(0, 0.45, 0) # Near lander
		rover_rig.rotation = Vector3.ZERO
	set_camera_view(CameraViewMode.ROVER_CHASE)
	print("[MarsPlanetary3D] Martian surface environment initialized. Lander ready for rover egress.")

func deploy_rover_sequence() -> void:
	is_deploying_rover = true
	is_rover_deployed = true
	
	# Step 1: Camera frames lander and deployment bay
	set_camera_view(CameraViewMode.SURFACE_CINEMATIC)
	if cam_surface_cinematic:
		cam_surface_cinematic.position = Vector3(6.5, 2.4, 9.5)
		cam_surface_cinematic.look_at(Vector3(0, 0.8, 2.0), Vector3.UP)
		
	# Step 2: Ramp extends down smoothly
	if lander_ramp:
		var tw_ramp := create_tween()
		tw_ramp.tween_property(lander_ramp, "rotation:x", 0.45, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# Step 3: Rover slowly rolls down the ramp onto the regolith
	if rover_rig:
		rover_rig.position = Vector3(0, 1.15, 0.5)
		var tw_r := create_tween()
		tw_r.tween_interval(0.8)
		tw_r.tween_property(rover_rig, "position", Vector3(0, 0.45, 6.5), 2.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Animate wheels turning during descent
		var tw_w := create_tween()
		tw_w.tween_interval(0.8)
		tw_w.tween_method(func(val: float):
			for w in wheels:
				if w: w.rotation.x = val
		, 0.0, 12.0, 2.8)
		
	if audio_chatter:
		var tw_a := create_tween()
		tw_a.tween_interval(3.2)
		tw_a.tween_callback(func(): audio_chatter.play())
		
	# Step 4: Touchdown on soil, dust puff, camera switch to chase
	var tw_end := create_tween()
	tw_end.tween_interval(3.8)
	tw_end.tween_callback(func():
		if touchdown_dust:
			touchdown_dust.restart()
		set_camera_view(CameraViewMode.ROVER_CHASE)
		is_rover_deployed = true
		is_deploying_rover = false
		rover_deployed.emit()
		print("[MarsPlanetary3D] Rover deployment complete! Controls online.")
	)

func _process_surface_mode(delta: float) -> void:
	if not is_rover_deployed or not rover_rig:
		return
		
	# Rover Driving Kinematics
	var target_speed := rover_throttle_input * rover_max_speed
	rover_speed = move_toward(rover_speed, target_speed, delta * 3.5)
	
	# Steering & Heading
	if abs(rover_speed) > 0.05:
		rover_heading_rad += -rover_steering_input * delta * 1.6 * sign(rover_speed)
		rover_rig.rotation.y = rover_heading_rad
		
	# Move rover along forward vector
	var forward := -rover_rig.transform.basis.z
	var move_vec := forward * rover_speed * delta
	rover_rig.position += move_vec
	
	# Clamp position within explorable region (-80m to +80m)
	rover_rig.position.x = clampf(rover_rig.position.x, -75.0, 75.0)
	rover_rig.position.z = clampf(rover_rig.position.z, -75.0, 75.0)
	
	# Surface terrain following (No wheel sinking, no floating)
	var h_current := get_terrain_height(rover_rig.position.x, rover_rig.position.z)
	rover_rig.position.y = lerpf(rover_rig.position.y, h_current + 0.45, clampf(delta * 12.0, 0.0, 1.0))
	
	# Surface normal gradient pitch & roll
	var h_fwd := get_terrain_height(rover_rig.position.x - sin(rover_heading_rad) * 1.4, rover_rig.position.z - cos(rover_heading_rad) * 1.4)
	var h_back := get_terrain_height(rover_rig.position.x + sin(rover_heading_rad) * 1.4, rover_rig.position.z + cos(rover_heading_rad) * 1.4)
	var target_pitch := (h_fwd - h_back) / 2.8
	rover_rig.rotation.x = lerpf(rover_rig.rotation.x, target_pitch, clampf(delta * 6.0, 0.0, 1.0))
	
	# Accumulate distance & consume battery
	var step_dist := move_vec.length()
	rover_distance_traveled_m += step_dist
	if abs(rover_speed) > 0.1:
		if sandbox_mode_active:
			rover_battery_wh = 1200.0
		else:
			rover_battery_wh = maxf(0.0, rover_battery_wh - (step_dist * 0.4))
		
	# Animate wheel rotation proportional to forward motion
	var wheel_rot_delta := (rover_speed / 0.35) * delta # r = 0.35m
	for w in wheels:
		if w: w.rotate_x(wheel_rot_delta)
		
	# Dust particle trail when driving
	if wheel_dust:
		wheel_dust.emitting = abs(rover_speed) > 0.4
		
	# Update chase camera orientation
	if cam_rover_pivot:
		cam_rover_pivot.rotation.y = lerpf(cam_rover_pivot.rotation.y, chase_cam_yaw, delta * 6.0)
		cam_rover_pivot.rotation.x = lerpf(cam_rover_pivot.rotation.x, chase_cam_pitch, delta * 6.0)
		if cam_rover_chase:
			cam_rover_chase.position.z = lerpf(cam_rover_chase.position.z, chase_cam_dist, delta * 6.0)
			
	# Distance to nearest science target
	_update_nearest_science_target()
	
	# Emit telemetry
	var dist_to_lander := rover_rig.position.distance_to(Vector3.ZERO)
	var nav_data := get_rover_navigation_data()
	var r_data: Dictionary = {
		"speed_kmh": rover_speed * 3.6,
		"distance_traveled_m": rover_distance_traveled_m,
		"distance_to_lander_m": dist_to_lander,
		"battery_wh": rover_battery_wh,
		"battery_pct": (rover_battery_wh / 1200.0) * 100.0,
		"nearest_target": active_nearest_target_name,
		"nearest_dist_m": active_nearest_target_dist,
		"samples_count": collected_samples.size(),
		"nav": nav_data
	}
	rover_telemetry_updated.emit(r_data)

func _update_nearest_science_target() -> void:
	if not rover_rig:
		return
	var targets: Dictionary = {
		"WATER": target_water,
		"ROCK": target_rock,
		"RADAR": target_radar,
		"WEATHER": target_weather,
		"MOXIE": target_moxie
	}
	
	var min_d := 999.0
	var min_name := "None in Range"
	
	for tid in targets:
		var node: Node3D = targets[tid]
		if node:
			var d := rover_rig.position.distance_to(node.position)
			if d < min_d:
				min_d = d
				min_name = tid
				
	active_nearest_target_name = min_name
	active_nearest_target_dist = min_d

func set_rover_drive_input(throttle: float, steering: float) -> void:
	rover_throttle_input = clampf(throttle, -1.0, 1.0)
	rover_steering_input = clampf(steering, -1.0, 1.0)

# =========================================================================
# SCIENCE OBJECTIVES & SAMPLE COLLECTION
# =========================================================================

func interact_with_nearest_target() -> Dictionary:
	if not is_rover_deployed:
		return {"success": false, "message": "Rover not deployed."}
		
	if active_nearest_target_dist > 12.0:
		return {
			"success": false,
			"message": "Out of interaction range. Drive closer to %s (Current: %.1fm, Needed: <12m)." % [
				active_nearest_target_name, active_nearest_target_dist
			]
		}
		
	var obj_id := active_nearest_target_name
	var result: Dictionary = {}
	
	# Animate robotic arm toward target
	if robotic_arm:
		var tw := create_tween()
		tw.tween_property(robotic_arm, "rotation:x", 0.6, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.8)
		tw.tween_property(robotic_arm, "rotation:x", 0.0, 0.5)
		
	match obj_id:
		"WATER":
			result = {
				"id": "SAMPLE_WATER_01",
				"name": "Jezero Delta Mudstone Core",
				"location": selected_landing_site + " Ancient Delta",
				"instrument": "Mastcam-Z & PIXL",
				"observation": "Finely laminated clay-bearing mudstone containing aqueous phyllosilicates. Evidence of sustained lacustrine deposition.",
				"significance": "Highest astrobiological priority sample for potential ancient biosignatures."
			}
			completed_science_objectives["WATER"] = true
			collected_samples.append(result)
			sample_collected.emit(result)
			objective_completed.emit("WATER", result)
			
		"ROCK":
			result = {
				"id": "SAMPLE_ROCK_02",
				"name": "Olivine-Rich Igneous Basalt",
				"location": selected_landing_site + " Crater Floor",
				"instrument": "SuperCam Laser & SHERLOC",
				"observation": "Pyroxene and olivine crystalline basalt indicating volcanic lava flow underlying delta deposits.",
				"significance": "Crucial chronometric pin for dating the early volcanic epoch of Mars."
			}
			completed_science_objectives["ROCK"] = true
			collected_samples.append(result)
			sample_collected.emit(result)
			objective_completed.emit("ROCK", result)
			
		"RADAR":
			result = {
				"id": "RADAR_SCAN_03",
				"name": "RIMFAX Subsurface Radargram",
				"location": "Crater Subsurface Structural Profile",
				"instrument": "RIMFAX Ground-Penetrating Radar",
				"observation": "Radar dielectric permittivity scan penetrating 12 meters into regolith, identifying cross-bedded subterranean strata.",
				"significance": "First 3D cross-section imaging of Martian paleolake sub-floor geometry."
			}
			completed_science_objectives["RADAR"] = true
			objective_completed.emit("RADAR", result)
			
		"WEATHER":
			result = {
				"id": "WEATHER_LOG_04",
				"name": "MEDA Atmospheric Profile",
				"location": "Surface Boundary Layer",
				"instrument": "MEDA Environmental Sensor Station",
				"observation": "Surface pressure: 6.8 mbar, ambient temperature: -52°C, wind speed: 4.2 m/s from NNE, optical dust optical depth tau = 0.45.",
				"significance": "Validates Mars global circulation atmospheric models."
			}
			completed_science_objectives["WEATHER"] = true
			objective_completed.emit("WEATHER", result)
			
		"MOXIE":
			result = {
				"id": "ISRU_MOXIE_05",
				"name": "MOXIE Oxygen Production Yield",
				"location": "Lander Base Station",
				"instrument": "MOXIE Solid Oxide Electrolysis",
				"observation": "Catalytic solid oxide electrolysis converted atmospheric CO2 into 99.6% purity breathable O2 at 5.8 grams/hour.",
				"significance": "Pivotal proof-of-concept for human mission in-situ propellant generation."
			}
			completed_science_objectives["MOXIE"] = true
			objective_completed.emit("MOXIE", result)
			
	if audio_chatter: audio_chatter.play()
	return {"success": true, "data": result}

func are_all_science_objectives_met() -> bool:
	for k in completed_science_objectives:
		if not completed_science_objectives[k]:
			return false
	return true

# =========================================================================
# CAMERA MANAGEMENT
# =========================================================================

func set_scene_mode(mode: GameSceneMode) -> void:
	scene_mode = mode
	if orbit_scene: orbit_scene.visible = (scene_mode == GameSceneMode.ORBIT)
	if descent_scene: descent_scene.visible = (scene_mode == GameSceneMode.DESCENT)
	if surface_scene: surface_scene.visible = (scene_mode == GameSceneMode.SURFACE)
	
	match scene_mode:
		GameSceneMode.ORBIT:
			set_camera_view(CameraViewMode.ORBIT_VIEW)
		GameSceneMode.DESCENT:
			set_camera_view(CameraViewMode.COCKPIT_DESCENT)
		GameSceneMode.SURFACE:
			set_camera_view(CameraViewMode.ROVER_CHASE)

func set_camera_view(view: CameraViewMode) -> void:
	camera_mode = view
	if cam_orbit: cam_orbit.current = (camera_mode == CameraViewMode.ORBIT_VIEW)
	if cam_orbit_360: cam_orbit_360.current = (camera_mode == CameraViewMode.ORBIT_INSPECT_360)
	if cam_cockpit_descent: cam_cockpit_descent.current = (camera_mode == CameraViewMode.COCKPIT_DESCENT)
	if cam_exterior_descent: cam_exterior_descent.current = (camera_mode == CameraViewMode.EXTERIOR_DESCENT)
	if cam_rover_chase: cam_rover_chase.current = (camera_mode == CameraViewMode.ROVER_CHASE or camera_mode == CameraViewMode.ROVER_INSPECT_360)
	if cam_rover_mast: cam_rover_mast.current = (camera_mode == CameraViewMode.ROVER_MAST)
	if cam_surface_cinematic: cam_surface_cinematic.current = (camera_mode == CameraViewMode.SURFACE_CINEMATIC)
	print("[MarsPlanetary3D] Camera view switched to: %d" % int(camera_mode))

func handle_mouse_look(relative: Vector2) -> void:
	if camera_mode == CameraViewMode.ORBIT_INSPECT_360:
		handle_orbit_mouse_look(relative)
	elif camera_mode == CameraViewMode.ROVER_CHASE and is_mouse_looking:
		chase_cam_yaw -= relative.x * 0.005
		chase_cam_pitch = clampf(chase_cam_pitch - relative.y * 0.005, -1.0, 0.4)
	elif camera_mode == CameraViewMode.COCKPIT_DESCENT:
		if cam_cockpit_descent:
			cam_cockpit_descent.rotation.y = clampf(cam_cockpit_descent.rotation.y - relative.x * 0.003, -0.6, 0.6)
			cam_cockpit_descent.rotation.x = clampf(cam_cockpit_descent.rotation.x - relative.y * 0.003, -0.4, 0.4)

# =========================================================================
# STAGE I: 360-DEGREE MARS ORBIT CAMERA & LANDING RECONNAISSANCE
# =========================================================================

func _setup_orbit_360_camera() -> void:
	if not orbit_scene:
		return
	if cam_orbit_pivot and is_instance_valid(cam_orbit_pivot):
		return
	cam_orbit_pivot = Node3D.new()
	cam_orbit_pivot.name = "OrbitInspectPivot"
	if mars_globe:
		cam_orbit_pivot.position = mars_globe.position
	else:
		cam_orbit_pivot.position = Vector3(0, 0, -32)
	orbit_scene.add_child(cam_orbit_pivot)
	
	cam_orbit_360 = Camera3D.new()
	cam_orbit_360.name = "CamOrbit360"
	cam_orbit_360.position = Vector3(0, 0, orbit_cam_dist)
	cam_orbit_360.fov = 50.0
	cam_orbit_pivot.add_child(cam_orbit_360)
	_update_orbit_cam_transform()

func _update_orbit_cam_transform() -> void:
	if cam_orbit_pivot:
		cam_orbit_pivot.rotation.y = orbit_cam_yaw
		cam_orbit_pivot.rotation.x = orbit_cam_pitch
	if cam_orbit_360:
		cam_orbit_360.position = Vector3(0, 0, orbit_cam_dist)

func handle_orbit_mouse_look(relative: Vector2) -> void:
	orbit_cam_yaw -= relative.x * 0.005
	orbit_cam_pitch = clampf(orbit_cam_pitch - relative.y * 0.005, -1.2, 1.2)
	_update_orbit_cam_transform()

func handle_orbit_zoom(delta_zoom: float) -> void:
	orbit_cam_dist = clampf(orbit_cam_dist + delta_zoom, 22.0, 70.0)
	_update_orbit_cam_transform()

func adjust_orbit_angles(delta_yaw: float, delta_pitch: float) -> void:
	orbit_cam_yaw += delta_yaw
	orbit_cam_pitch = clampf(orbit_cam_pitch + delta_pitch, -1.2, 1.2)
	_update_orbit_cam_transform()

func reset_orbit_camera() -> void:
	orbit_cam_yaw = 0.0
	orbit_cam_pitch = 0.15
	orbit_cam_dist = 38.0
	_update_orbit_cam_transform()

# =========================================================================
# STAGE I & J: DETAILED PROCEDURAL SURFACE TERRAIN & ENVIRONMENT
# =========================================================================

func get_terrain_height(x: float, z: float) -> float:
	var h: float = 0.0
	
	# Primary undulating Martian topography (multi-scale sine harmonics)
	h += sin(x * 0.045) * cos(z * 0.045) * 1.85
	h += sin(x * 0.09 + 1.2) * cos(z * 0.08 - 0.7) * 0.95
	h += sin((x + z) * 0.16) * 0.42
	
	# Site-specific geological topography
	match selected_landing_site:
		"Jezero Crater":
			# Ancient river delta fan and depressed crater lake bed
			var d_center := Vector2(x, z).length()
			if d_center < 38.0:
				h -= (1.0 - (d_center / 38.0)) * 1.6
			if x > 8.0 and z > -18.0:
				h += clampf((x - 8.0) * 0.07, 0.0, 1.0) * 2.4
		"Gale Crater":
			# High slope climbing towards Mount Sharp in south-east
			var dist_sharp := Vector2(x - 55.0, z - 55.0).length()
			h += maxf(0.0, (110.0 - dist_sharp) * 0.075) * 2.6
			h += sin(z * 0.11) * 1.3
		"Elysium Planitia":
			# Vast basaltic plains with undulating low lava pressure ridges
			h = sin(x * 0.032) * 0.7 + cos(z * 0.048) * 0.6
			
	# Keep lander / rover initial footprint near (0, 0) smooth and stable
	var footprint := Vector2(x, z).length()
	if footprint < 12.0:
		var blend := footprint / 12.0
		h = lerpf(0.0, h, blend * blend)
		
	return h

func _generate_procedural_terrain_mesh() -> void:
	if not surface_scene:
		return
	var terrain_node: MeshInstance3D = surface_scene.get_node_or_null("TerrainMesh")
	if not terrain_node:
		return
		
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var grid_size := 36
	var world_size := 160.0
	var step := world_size / float(grid_size)
	var half_size := world_size * 0.5
	
	for gz in range(grid_size):
		for gx in range(grid_size):
			var x0 := -half_size + float(gx) * step
			var z0 := -half_size + float(gz) * step
			var x1 := x0 + step
			var z1 := z0 + step
			
			var y00 := get_terrain_height(x0, z0)
			var y10 := get_terrain_height(x1, z0)
			var y01 := get_terrain_height(x0, z1)
			var y11 := get_terrain_height(x1, z1)
			
			var v00 := Vector3(x0, y00, z0)
			var v10 := Vector3(x1, y10, z0)
			var v01 := Vector3(x0, y01, z1)
			var v11 := Vector3(x1, y11, z1)
			
			var n1 := (v10 - v00).cross(v01 - v00).normalized()
			var n2 := (v11 - v10).cross(v01 - v10).normalized()
			
			var uv00 := Vector2(float(gx) / grid_size, float(gz) / grid_size) * 8.0
			var uv10 := Vector2(float(gx + 1) / grid_size, float(gz) / grid_size) * 8.0
			var uv01 := Vector2(float(gx) / grid_size, float(gz + 1) / grid_size) * 8.0
			var uv11 := Vector2(float(gx + 1) / grid_size, float(gz + 1) / grid_size) * 8.0
			
			# Triangle 1
			st.set_normal(n1)
			st.set_uv(uv00)
			st.add_vertex(v00)
			st.set_normal(n1)
			st.set_uv(uv10)
			st.add_vertex(v10)
			st.set_normal(n1)
			st.set_uv(uv01)
			st.add_vertex(v01)
			
			# Triangle 2
			st.set_normal(n2)
			st.set_uv(uv10)
			st.add_vertex(v10)
			st.set_normal(n2)
			st.set_uv(uv11)
			st.add_vertex(v11)
			st.set_normal(n2)
			st.set_uv(uv01)
			st.add_vertex(v01)
			
	var arr_mesh := st.commit()
	
	# Rich site-tailored Martian material
	var mat_surface := StandardMaterial3D.new()
	match selected_landing_site:
		"Jezero Crater":
			mat_surface.albedo_color = Color(0.82, 0.38, 0.18)
			mat_surface.roughness = 0.90
		"Gale Crater":
			mat_surface.albedo_color = Color(0.74, 0.34, 0.20)
			mat_surface.roughness = 0.85
		"Elysium Planitia":
			mat_surface.albedo_color = Color(0.58, 0.32, 0.22)
			mat_surface.roughness = 0.78
			
	terrain_node.mesh = arr_mesh
	terrain_node.material_override = mat_surface

func _setup_surface_environment() -> void:
	if not surface_scene or surface_features_generated:
		return
	surface_features_generated = true
	
	_generate_procedural_terrain_mesh()
	
	var terrain_group := Node3D.new()
	terrain_group.name = "ProceduralTerrainFeatures"
	surface_scene.add_child(terrain_group)
	
	# Materials for terrain variety
	var mat_dune := StandardMaterial3D.new()
	mat_dune.albedo_color = Color(0.85, 0.40, 0.18)
	mat_dune.roughness = 0.92
	
	var mat_rock := StandardMaterial3D.new()
	mat_rock.albedo_color = Color(0.32, 0.22, 0.19)
	mat_rock.roughness = 0.78
	
	var mat_mountain := StandardMaterial3D.new()
	mat_mountain.albedo_color = Color(0.62, 0.30, 0.18)
	mat_mountain.roughness = 0.95
	
	# 1. Undulating Sand Dunes & Rolling Mounds
	var dune_coords: Array[Vector3] = [
		Vector3(-30, 0, 10), Vector3(-15, 0, -35), Vector3(35, 0, 15),
		Vector3(20, 0, 40), Vector3(-45, 0, -15), Vector3(40, 0, -30),
		Vector3(-10, 0, 45), Vector3(10, 0, -50), Vector3(-50, 0, 30),
		Vector3(50, 0, 45)
	]
	for i in range(dune_coords.size()):
		var dune := MeshInstance3D.new()
		var s_mesh := SphereMesh.new()
		s_mesh.radius = 12.0 + (i % 5) * 1.5
		s_mesh.height = 2.2 + (i % 3) * 0.5
		s_mesh.radial_segments = 16
		s_mesh.rings = 8
		s_mesh.material = mat_dune
		dune.mesh = s_mesh
		var dpos := dune_coords[i]
		dpos.y = get_terrain_height(dpos.x, dpos.z) - 0.2
		dune.position = dpos
		dune.scale = Vector3(1.8, 0.3, 1.2)
		dune.rotation.y = (i * 0.4)
		terrain_group.add_child(dune)
		
	# 2. Impact Crater Structure with Raised Rim (Subsurface scan site)
	var crater_rim := MeshInstance3D.new()
	var t_mesh := TorusMesh.new()
	t_mesh.inner_radius = 4.0
	t_mesh.outer_radius = 6.2
	t_mesh.rings = 24
	t_mesh.ring_segments = 12
	t_mesh.material = mat_rock
	crater_rim.mesh = t_mesh
	var cx := -26.0
	var cz := -18.0
	crater_rim.position = Vector3(cx, get_terrain_height(cx, cz) + 0.2, cz)
	crater_rim.scale = Vector3(1.0, 0.4, 1.0)
	terrain_group.add_child(crater_rim)
	
	# 3. Scattered Boulders & Stone Outcrops (Non-floating: clamped to get_terrain_height)
	var rng := RandomNumberGenerator.new()
	rng.seed = 202611
	for b in range(36):
		var boulder := MeshInstance3D.new()
		var b_mesh := BoxMesh.new()
		var sx := rng.randf_range(0.5, 2.6)
		var sy := rng.randf_range(0.35, 1.8)
		var sz := rng.randf_range(0.5, 2.4)
		b_mesh.size = Vector3(sx, sy, sz)
		b_mesh.material = mat_rock
		boulder.mesh = b_mesh
		var px := rng.randf_range(-68.0, 68.0)
		var pz := rng.randf_range(-68.0, 68.0)
		if Vector2(px, pz).length() < 12.0:
			px += 18.0 # Keep lander/rover initial footprint clear
		var py := get_terrain_height(px, pz) + sy * 0.45 # Clamped naturally to terrain height!
		boulder.position = Vector3(px, py, pz)
		boulder.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0, TAU), rng.randf_range(-0.2, 0.2))
		terrain_group.add_child(boulder)
		
	# 4. Distant Perimeter Mountain Ring (r ~ 85m to 95m)
	var mountain_ring := Node3D.new()
	mountain_ring.name = "PerimeterMountains"
	terrain_group.add_child(mountain_ring)
	for m in range(16):
		var angle := (float(m) / 16.0) * TAU
		var m_radius := rng.randf_range(84.0, 96.0)
		var mx := cos(angle) * m_radius
		var mz := sin(angle) * m_radius
		var m_inst := MeshInstance3D.new()
		var p_mesh := PrismMesh.new()
		p_mesh.size = Vector3(rng.randf_range(26.0, 40.0), rng.randf_range(18.0, 30.0), rng.randf_range(22.0, 34.0))
		p_mesh.material = mat_mountain
		m_inst.mesh = p_mesh
		m_inst.position = Vector3(mx, get_terrain_height(mx, mz) + p_mesh.size.y * 0.4, mz)
		m_inst.rotation.y = angle + PI * 0.5 + rng.randf_range(-0.25, 0.25)
		mountain_ring.add_child(m_inst)
		
	# 5. Ambient Drifting Dust Particles
	var ambient_dust := CPUParticles3D.new()
	ambient_dust.name = "AmbientDriftingDust"
	ambient_dust.amount = 80
	ambient_dust.lifetime = 6.0
	ambient_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ambient_dust.emission_box_extents = Vector3(60, 6, 60)
	ambient_dust.direction = Vector3(0.8, -0.1, 0.3).normalized()
	ambient_dust.spread = 20.0
	ambient_dust.gravity = Vector3(0, -0.2, 0)
	ambient_dust.initial_velocity_min = 2.0
	ambient_dust.initial_velocity_max = 5.0
	ambient_dust.scale_amount_min = 0.08
	ambient_dust.scale_amount_max = 0.22
	ambient_dust.color = Color(0.92, 0.45, 0.22, 0.35)
	ambient_dust.position = Vector3(0, 3.5, 0)
	terrain_group.add_child(ambient_dust)

func get_rover_navigation_data() -> Dictionary:
	var rec: Dictionary = experiment_records.get(current_mission_idx, {})
	var target_pos: Vector3 = rec.get("location", Vector3.ZERO)
	var rover_pos: Vector3 = rover_rig.position if rover_rig else Vector3.ZERO
	var dist_m := rover_pos.distance_to(target_pos)
	
	# Relative bearing / compass angle from rover heading
	var to_target_2d := Vector2(target_pos.x - rover_pos.x, target_pos.z - rover_pos.z)
	var target_angle := atan2(to_target_2d.x, to_target_2d.y)
	var relative_angle := wrapf(target_angle - rover_heading_rad, -PI, PI)
	
	var dir_arrow := "▲"
	if abs(relative_angle) < 0.35:
		dir_arrow = "▲"
	elif relative_angle > 0.35 and relative_angle < 1.4:
		dir_arrow = "►"
	elif relative_angle >= 1.4:
		dir_arrow = "▼"
	elif relative_angle < -0.35 and relative_angle > -1.4:
		dir_arrow = "◄"
	else:
		dir_arrow = "▼"
		
	var is_in_range := (dist_m < 5.0)
	
	return {
		"checkpoint_idx": current_mission_idx,
		"checkpoint_name": rec.get("name", "Science Target"),
		"target_name": rec.get("target_name", "Martian Outcrop"),
		"instrument": rec.get("instrument", "Science Suite"),
		"distance_m": dist_m,
		"bearing_deg": rad_to_deg(relative_angle),
		"direction_arrow": dir_arrow,
		"compass_arrow": dir_arrow,
		"is_in_range": is_in_range,
		"is_completed": rec.get("completed", false)
	}

# =========================================================================
# STAGE I: DETAILED ROVER MODEL & KINEMATICS
# =========================================================================

func _setup_detailed_rover_model() -> void:
	if not rover_rig:
		return
	if rover_rig.has_node("MMRTG_Generator"):
		return
		
	var mat_dark := StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.2, 0.2, 0.22)
	mat_dark.metallic = 0.8
	mat_dark.roughness = 0.4
	
	var mat_dish := StandardMaterial3D.new()
	mat_dish.albedo_color = Color(0.9, 0.9, 0.92)
	mat_dish.metallic = 0.5
	mat_dish.roughness = 0.25
	
	# 1. Rear Multi-Mission Radioisotope Thermoelectric Generator (MMRTG)
	var mmrtg := Node3D.new()
	mmrtg.name = "MMRTG_Generator"
	mmrtg.position = Vector3(0, 0.25, 0.85)
	rover_rig.add_child(mmrtg)
	
	var mmrtg_body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.16
	cyl.bottom_radius = 0.16
	cyl.height = 0.42
	cyl.material = mat_dark
	mmrtg_body.mesh = cyl
	mmrtg_body.rotation.x = PI * 0.5
	mmrtg.add_child(mmrtg_body)
	
	# 2. High Gain Antenna (HGA Dish)
	var hga := Node3D.new()
	hga.name = "HighGainAntenna"
	hga.position = Vector3(-0.35, 0.35, 0.3)
	rover_rig.add_child(hga)
	
	var dish := MeshInstance3D.new()
	var d_cyl := CylinderMesh.new()
	d_cyl.top_radius = 0.22
	d_cyl.bottom_radius = 0.05
	d_cyl.height = 0.08
	d_cyl.material = mat_dish
	dish.mesh = d_cyl
	dish.rotation.x = -0.4
	dish.rotation.y = 0.6
	hga.add_child(dish)
	
	# 3. Rocker-Bogie Suspension Structural Tubes
	var suspension := Node3D.new()
	suspension.name = "SuspensionRig"
	rover_rig.add_child(suspension)
	
	for side in [-1.0, 1.0]:
		var strut := MeshInstance3D.new()
		var strut_mesh := BoxMesh.new()
		strut_mesh.size = Vector3(0.06, 0.06, 1.4)
		strut_mesh.material = mat_dark
		strut.mesh = strut_mesh
		strut.position = Vector3(side * 0.72, -0.08, 0.0)
		suspension.add_child(strut)

# =========================================================================
# STAGE I: REAL VIEWPORT PHOTOGRAPHY (PART 8)
# =========================================================================

func capture_viewport_photo() -> Dictionary:
	var img: Image = null
	if DisplayServer.get_name() != "headless":
		var vp := get_viewport()
		if vp:
			var tex := vp.get_texture()
			if tex:
				img = tex.get_image()
	if img == null:
		img = Image.create(640, 360, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.82, 0.38, 0.20, 1.0))
			
	var photo_num := captured_photos.size() + 1
	var photo_id := "SOL34_MASTCAM_%03d" % photo_num
	var rover_pos := rover_rig.position if rover_rig else Vector3.ZERO
	var photo_info: Dictionary = {
		"id": photo_id,
		"sol": 34,
		"timestamp": Time.get_time_string_from_system(),
		"coordinates": "X: %.1fm, Z: %.1fm" % [rover_pos.x, rover_pos.z],
		"heading": "%.1f°" % rad_to_deg(rover_heading_rad),
		"target": active_nearest_target_name,
		"range_m": "%.1fm" % active_nearest_target_dist,
		"camera_mode": "Mastcam-Z Stereo Multi-Spectral",
		"image": img,
		"texture": ImageTexture.create_from_image(img) if img else null
	}
	captured_photos.append(photo_info)
	photo_captured.emit(photo_info)
	print("[MarsPlanetary3D] Viewport photo captured: %s (%s)" % [photo_id, photo_info["coordinates"]])
	return photo_info

# =========================================================================
# STAGE I: FOUR SEQUENTIAL SCIENCE EXPERIMENTS (PART 7)
# =========================================================================

func perform_experiment_1() -> Dictionary:
	var exp_data: Dictionary = {
		"id": "EXP_01_GEOLOGY",
		"name": "Geological Rock Analysis",
		"instrument": "Mastcam-Z & SuperCam LIBS Laser",
		"target": "Ancient Delta Rock Formation",
		"site": selected_landing_site,
		"composition": {
			"Pyroxene": "38%",
			"Olivine": "26%",
			"Smectite Clay": "22%",
			"Plagioclase": "14%"
		},
		"laser_pulses": 30,
		"summary": "Laser-induced breakdown spectroscopy (LIBS) confirms pyroxene-olivine igneous basalt with smectite clay alteration bands, indicative of sustained water interaction.",
		"status": "COMPLETE"
	}
	experiment_records[1]["completed"] = true
	experiment_records[1]["data"] = exp_data
	completed_science_objectives["ROCK"] = true
	if not collected_samples.has(exp_data):
		collected_samples.append(exp_data)
	sample_collected.emit(exp_data)
	objective_completed.emit("ROCK", exp_data)
	experiment_completed.emit(1, exp_data)
	if audio_chatter: audio_chatter.play()
	return exp_data

func perform_experiment_2(selected_depth_m: float = 8.2) -> Dictionary:
	var is_depth_correct: bool = abs(selected_depth_m - 8.2) < 0.6
	var exp_data: Dictionary = {
		"id": "EXP_02_SUBSURFACE",
		"name": "Subsurface Radar Stratigraphy",
		"instrument": "RIMFAX Ground-Penetrating Radar",
		"target": "Sedimentary Stratum Outcrop",
		"frequency_mhz": "150-1200 MHz Ultra-Wideband GPR",
		"selected_depth_m": selected_depth_m,
		"depth_verified": is_depth_correct,
		"stratigraphy": [
			{"layer": 1, "depth": "0.0 - 2.5m", "description": "Loose Eolian Regolith & Sand Drift"},
			{"layer": 2, "depth": "2.5 - 8.2m", "description": "Interbedded Cross-Bedded Lacustrine Sandstones & Carbonates"},
			{"layer": 3, "depth": "> 8.2m", "description": "Dense Crystalline Igneous Floor Basement"}
		],
		"disclaimer": "EDUCATIONAL NOTICE: Subsurface radargram generated for educational simulation based on NASA Mars 2020 RIMFAX mission parameters.",
		"summary": "RIMFAX GPR scan penetrates 12m into regolith. Boundary reflector at 8.2m confirms depth of ancient lake sediment sequence above volcanic floor.",
		"status": "COMPLETE"
	}
	experiment_records[2]["completed"] = true
	experiment_records[2]["data"] = exp_data
	completed_science_objectives["RADAR"] = true
	objective_completed.emit("RADAR", exp_data)
	experiment_completed.emit(2, exp_data)
	if audio_chatter: audio_chatter.play()
	return exp_data

func perform_experiment_3() -> Dictionary:
	var exp_data: Dictionary = {
		"id": "EXP_03_ATMOSPHERE",
		"name": "Atmospheric & Environmental Monitoring",
		"instrument": "MEDA Environmental Sensor Station",
		"target": "Surface Boundary Layer",
		"metrics": {
			"temperature_c": -63.4,
			"pressure_pa": 612.0,
			"pressure_mbar": 6.12,
			"wind_speed_ms": 7.4,
			"wind_direction": "NNE (22.5°)",
			"dust_optical_depth_tau": 0.42,
			"humidity_pct": 2.1
		},
		"summary": "Ambient surface pressure 612 Pa, temperature -63.4°C with moderate NNE wind of 7.4 m/s. Atmospheric dust optical depth tau = 0.42 within nominal seasonal envelope.",
		"status": "COMPLETE"
	}
	experiment_records[3]["completed"] = true
	experiment_records[3]["data"] = exp_data
	completed_science_objectives["WEATHER"] = true
	objective_completed.emit("WEATHER", exp_data)
	experiment_completed.emit(3, exp_data)
	if audio_chatter: audio_chatter.play()
	return exp_data

func perform_experiment_4() -> Dictionary:
	if robotic_arm:
		var tw := create_tween()
		tw.tween_property(robotic_arm, "rotation:x", 0.65, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_interval(1.0)
		tw.tween_property(robotic_arm, "rotation:x", 0.0, 0.6)
		
	var exp_data: Dictionary = {
		"id": "EXP_04_SAMPLE",
		"name": "Sample Coring & Spectroscopic Analysis",
		"instrument": "Rotary Percussive Drill, PIXL Micro-XRF & SHERLOC UV Raman",
		"target": "Sample Cache Outcrop",
		"core_tube_id": "TUBE_MARS_042",
		"core_length_cm": 5.4,
		"core_status": "HERMETICALLY SEALED & CACHED",
		"pixl_xrf": "High-resolution elemental map reveals Si-Al phyllosilicate grains enriched with Fe and Ca carbonate precipitates.",
		"sherloc_raman": "Deep UV Raman spectroscopy detects aromatic organic carbon rings consistent with abiotic macromolecular prebiotic organic compounds.",
		"disclaimer": "SCIENTIFIC NOTICE: Raman organic spectral detections reflect abiotic organic carbon compounds. No extraterrestrial life or active biological biosignature is confirmed.",
		"status": "COMPLETE"
	}
	experiment_records[4]["completed"] = true
	experiment_records[4]["data"] = exp_data
	completed_science_objectives["WATER"] = true
	completed_science_objectives["MOXIE"] = true
	if not collected_samples.has(exp_data):
		collected_samples.append(exp_data)
	sample_collected.emit(exp_data)
	objective_completed.emit("WATER", exp_data)
	objective_completed.emit("MOXIE", exp_data)
	experiment_completed.emit(4, exp_data)
	if audio_chatter: audio_chatter.play()
	return exp_data

func get_all_experiments_completed() -> bool:
	for i in range(1, 5):
		if not experiment_records[i]["completed"]:
			return false
	return true

# =========================================================================
# STAGE I: DEEP SPACE DATA TRANSMISSION (PART 9)
# =========================================================================

func transmit_data_to_earth() -> Dictionary:
	data_transmitted_to_earth = true
	var status: Dictionary = {
		"status": "TRANSMISSION_CONFIRMED",
		"signal_strength_dbm": -118.4,
		"data_volume_mb": 48.6,
		"light_time_delay_min": 12.5,
		"uplink_frequency": "8.4 GHz (Deep Space X-Band)",
		"hga_alignment_pct": 100.0,
		"ground_stations": ["Goldstone (DSS-14)", "Madrid (DSS-63)", "Canberra (DSS-43)"],
		"earth_acknowledgement": "EARTH RECEIVED YOUR DATA SUCCESSFULLY • ALL FOUR EXPERIMENT REPORTS ARCHIVED AT NASA JPL PDS",
		"photos_transmitted": captured_photos.size(),
		"experiments_archived": 4
	}
	data_transmitted.emit(status)
	print("[MarsPlanetary3D] Deep Space Data Transmission successful: %s" % status["earth_acknowledgement"])
	return status

# =========================================================================
# STAGE I: PERMANENT FREE-ROAM SANDBOX MODE (PART 10)
# =========================================================================

func enter_sandbox_mode() -> void:
	sandbox_mode_active = true
	is_rover_deployed = true
	rover_battery_wh = 1200.0
	set_scene_mode(GameSceneMode.SURFACE)
	set_camera_view(CameraViewMode.ROVER_CHASE)
	print("[MarsPlanetary3D] MARS SANDBOX MODE ACTIVATED: Unlimited free-roam driving on Mars enabled!")

func is_sandbox_active() -> bool:
	return sandbox_mode_active

