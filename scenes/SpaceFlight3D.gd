extends Node3D

## SpaceFlight3D.gd - 3D Interplanetary Spaceflight Simulation Engine for MARS DEEP
## Features a complete heliocentric astrodynamics simulation:
## - Heliocentric transfer ellipse trajectory (Hohmann / Fast Transit)
## - Position vectors for Earth, Mars, and Spacecraft
## - Continuous calculation of Earth & Mars distances from actual simulated positions
## - Physically responsive propulsion (thrust, acceleration, propellant mass flow, coasting)
## - Time warp support (1x, 10x, Warp to Event) with stable numerical progression
## - 3D spatial motion of spacecraft, receding Earth, approaching Mars, starfield & interactive 3D Orbital Map

const GameManagerRef = preload("res://scripts/GameManager.gd")
const LaunchAudioRef = preload("res://scripts/LaunchAudio.gd")

# Camera View Modes
enum CameraMode {
	COCKPIT = 0,
	EXTERIOR = 1,
	NAV_MAP = 2,
	MARS_CINEMATIC = 3
}

# Flight Simulation Phases
enum FlightPhase {
	EARTH_ORBIT = 0,
	EARTH_DEPARTURE = 1,
	INTERPLANETARY_CRUISE = 2,
	MIDCOURSE_CORRECTION = 3,
	MARS_APPROACH = 4,
	MARS_ORBIT_INSERTION = 5,
	MARS_ORBIT_ACHIEVED = 6
}

@export var current_camera_mode: CameraMode = CameraMode.COCKPIT
@export var current_phase: FlightPhase = FlightPhase.EARTH_ORBIT

# Node References - Cameras
@onready var cam_cockpit: Camera3D = $SpacecraftRig/CockpitInterior/CamCockpit
@onready var cam_exterior: Camera3D = $SpacecraftRig/CameraPivot/CamExterior
@onready var cam_exterior_pivot: Node3D = $SpacecraftRig/CameraPivot
@onready var cam_nav_map: Camera3D = $Cameras/CamNavMap
@onready var cam_mars_cinematic: Camera3D = $Cameras/CamMarsCinematic

# Node References - Celestial Bodies
@onready var earth_system: Node3D = $CelestialBodies/EarthSystem
@onready var earth_mesh: MeshInstance3D = $CelestialBodies/EarthSystem/EarthMesh
@onready var mars_system: Node3D = $CelestialBodies/MarsSystem
@onready var mars_mesh: MeshInstance3D = $CelestialBodies/MarsSystem/MarsMesh

# Node References - Spacecraft Systems
@onready var spacecraft_rig: Node3D = $SpacecraftRig
@onready var modular_craft: Node3D = $SpacecraftRig/ModularCraft
@onready var bus_light: MeshInstance3D = $SpacecraftRig/ModularCraft/BusLight
@onready var bus_heavy: MeshInstance3D = $SpacecraftRig/ModularCraft/BusHeavy
@onready var solar_wing_l: Node3D = $SpacecraftRig/ModularCraft/SolarLeft
@onready var solar_wing_r: Node3D = $SpacecraftRig/ModularCraft/SolarRight
@onready var mmrtg_unit: Node3D = $SpacecraftRig/ModularCraft/MMRTGMount
@onready var dish_antenna: Node3D = $SpacecraftRig/ModularCraft/DishAntenna

# Propulsion & RCS
@onready var engine_exhaust: Node3D = $SpacecraftRig/ModularCraft/EngineExhaust
@onready var flame_mesh: MeshInstance3D = $SpacecraftRig/ModularCraft/EngineExhaust/FlameMesh
@onready var flame_particles: CPUParticles3D = $SpacecraftRig/ModularCraft/EngineExhaust/FlameParticles
@onready var exhaust_light: OmniLight3D = $SpacecraftRig/ModularCraft/EngineExhaust/ExhaustLight
@onready var rcs_pos_x: CPUParticles3D = $SpacecraftRig/ModularCraft/RCS_PosX
@onready var rcs_neg_x: CPUParticles3D = $SpacecraftRig/ModularCraft/RCS_NegX
@onready var rcs_pos_y: CPUParticles3D = $SpacecraftRig/ModularCraft/RCS_PosY
@onready var rcs_neg_y: CPUParticles3D = $SpacecraftRig/ModularCraft/RCS_NegY

# Cockpit Controls & Displays
@onready var cockpit_interior: Node3D = $SpacecraftRig/CockpitInterior
@onready var throttle_lever_pivot: Node3D = $SpacecraftRig/CockpitInterior/ThrottleLeverPivot
@onready var flight_stick_pivot: Node3D = $SpacecraftRig/CockpitInterior/FlightStickPivot
@onready var screen_nav_mesh: MeshInstance3D = $SpacecraftRig/CockpitInterior/ConsolePanel/ScreenNav
@onready var screen_att_mesh: MeshInstance3D = $SpacecraftRig/CockpitInterior/ConsolePanel/ScreenAttitude
@onready var screen_sys_mesh: MeshInstance3D = $SpacecraftRig/CockpitInterior/ConsolePanel/ScreenSystems

# Audio Players
@onready var audio_engine: AudioStreamPlayer = $AudioEngine
@onready var audio_rcs: AudioStreamPlayer = $AudioRCS
@onready var audio_comms: AudioStreamPlayer = $AudioComms
@onready var audio_alarm: AudioStreamPlayer = $AudioAlarm

# =========================================================================
# HELIOCENTRIC ASTRODYNAMICS & FLIGHT MODEL CONSTANTS
# =========================================================================
const AU_KM: float = 149597870.7
const R_EARTH_AU: float = 1.000 # 1.0 AU
const R_MARS_AU: float = 1.524  # 1.524 AU

# Trajectory & Mission Timing
var trajectory_progress: float = 0.0 # 0.0 at Earth departure, 1.0 at Mars arrival
var mission_day: float = 0.0
var total_transit_days: float = 260.0 # Hohmann = 260d, Fast = 180d
var base_days_per_second: float = 0.35 # At 1x warp, 1 sec = 0.35 days (~8.4 hrs)
var time_warp_scale: float = 1.0
var selected_route_id: String = "ROUTE_B_HOHMANN"

# Keplerian Ellipse Parameters
var sma_au: float = 1.262 # (1.0 + 1.524)/2 for Hohmann
var ecc: float = 0.2076   # (1.524 - 1.0)/(1.524 + 1.0)
var initial_mars_angle_rad: float = 0.775 # Mars lead angle at launch

# Simulated Heliocentric Coordinates (AU in 2D orbital plane)
var sc_helio_pos_au: Vector2 = Vector2(1.0, 0.0)
var earth_helio_pos_au: Vector2 = Vector2(1.0, 0.0)
var mars_helio_pos_au: Vector2 = Vector2(1.524, 0.0)

# Physical Flight Dynamics State
var velocity_kms: float = 7.78 # Starts in LEO orbital speed
var engine_thrust_kn: float = 0.0
var max_engine_thrust_kn: float = 75.0 # Max main engine thrust
var spacecraft_dry_mass_kg: float = 800.0
var propellant_kg: float = 850.0
var initial_propellant_kg: float = 850.0
var engine_isp_s: float = 320.0
var acceleration_ms2: float = 0.0
var throttle: float = 0.0
var target_throttle: float = 0.0
var is_engine_burning: bool = false
var is_coasting: bool = true

# Retrograde & Braking Flight Dynamics (Stage I Part 1)
var is_retrograde_burning: bool = false
var retrograde_throttle: float = 0.0
var target_cutoff_velocity_kms: float = 9.85
var maneuver_window_active: bool = false
var maneuver_countdown_s: float = 12.0
var maneuver_missed: bool = false
var maneuver_required_dv_kms: float = 1.39

# Mars Orbital Insertion Attitude Guidance (Stage I Part 2)
var target_moi_attitude: Vector3 = Vector3(-0.314, 0.436, 0.0) # Target pitch -18 deg, yaw +25 deg
var attitude_alignment_error: float = 1.0
var is_attitude_aligned: bool = false
var moi_burn_progress: float = 0.0

# Telemetry Distances (Calculated from simulation vectors)
var distance_from_earth_km: float = 420.0
var distance_to_mars_km: float = 225000000.0

# Cabin Life Support & Power
var cabin_pressure_kpa: float = 101.3
var cabin_o2_percent: float = 20.9
var power_generation_w: float = 450.0
var power_consumption_w: float = 175.4

# Orientation & Camera Controls
var craft_rotation: Vector3 = Vector3.ZERO
var craft_angular_vel: Vector3 = Vector3.ZERO
var cockpit_look_angles: Vector2 = Vector2.ZERO
var ext_orbit_yaw: float = 0.4
var ext_orbit_pitch: float = -0.3
var ext_orbit_dist: float = 6.5
var is_mouse_dragging: bool = false
var is_orientation_mode: bool = false
var mars_orbit_angle: float = 0.0
var mars_orbit_path_mesh: MeshInstance3D = null

# Procedural Visual Nodes
var starfield_mesh: MultiMeshInstance3D = null
var orbital_map_root: Node3D = null
var sc_map_marker: MeshInstance3D = null
var earth_map_marker: MeshInstance3D = null
var mars_map_marker: MeshInstance3D = null

# Signals
signal phase_advanced(new_phase: FlightPhase)
signal telemetry_changed(data: Dictionary)
signal burn_started(burn_name: String)
signal burn_completed(burn_name: String)
signal event_triggered(event_id: String, details: Dictionary)

func _ready() -> void:
	print("[SpaceFlight3D] Initializing Interplanetary 3D Spaceflight Engine...")
	_setup_procedural_audio()
	_setup_starfield()
	_setup_orbital_map()
	_setup_lighting()
	_load_spacecraft_configuration()
	set_camera_view(CameraMode.COCKPIT)
	set_flight_phase(FlightPhase.EARTH_ORBIT)

func _setup_procedural_audio() -> void:
	if audio_engine:
		audio_engine.stream = LaunchAudioRef.create_engine_rumble(2.0)
		audio_engine.volume_db = -80.0
	if audio_rcs:
		audio_rcs.stream = LaunchAudioRef.create_rcs_burst()
		audio_rcs.volume_db = -12.0
	if audio_comms:
		audio_comms.stream = LaunchAudioRef.create_radio_chatter()
		audio_comms.volume_db = -6.0
	if audio_alarm:
		audio_alarm.stream = LaunchAudioRef.create_alarm_beep()
		audio_alarm.volume_db = -8.0

func _setup_starfield() -> void:
	if starfield_mesh != null:
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = 1200
	multimesh.visible_instance_count = 1200
	
	var quad := QuadMesh.new()
	quad.size = Vector2(0.55, 0.55)
	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	star_mat.vertex_color_use_as_albedo = true
	quad.material = star_mat
	multimesh.mesh = quad
	
	var rng := RandomNumberGenerator.new()
	rng.seed = 99318
	for i in range(1200):
		var u: float = rng.randf_range(-1.0, 1.0)
		var theta: float = rng.randf_range(0.0, TAU)
		var rad: float = rng.randf_range(160.0, 320.0)
		var sqrt_u: float = sqrt(maxf(0.0, 1.0 - u * u))
		var pos := Vector3(rad * sqrt_u * cos(theta), rad * u, rad * sqrt_u * sin(theta))
		var t := Transform3D(Basis(), pos)
		var sc: float = rng.randf_range(0.8, 2.5)
		t = t.scaled_local(Vector3(sc, sc, sc))
		multimesh.set_instance_transform(i, t)
		
		var col := Color(0.95, 0.98, 1.0, rng.randf_range(0.6, 1.0))
		if rng.randf() > 0.7: col = Color(0.4, 0.85, 1.0, rng.randf_range(0.7, 1.0))
		elif rng.randf() > 0.85: col = Color(1.0, 0.7, 0.4, rng.randf_range(0.7, 1.0))
		multimesh.set_instance_color(i, col)
		
	starfield_mesh = MultiMeshInstance3D.new()
	starfield_mesh.name = "DeepSpaceStarfield"
	starfield_mesh.multimesh = multimesh
	add_child(starfield_mesh)

func _setup_lighting() -> void:
	# Add a soft secondary fill light for external spacecraft visibility
	var fill_light := DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.transform = Transform3D(Basis().rotated(Vector3.UP, PI * 0.75), Vector3.ZERO)
	fill_light.light_color = Color(0.3, 0.4, 0.55, 1.0)
	fill_light.light_energy = 0.75
	fill_light.shadow_enabled = false
	add_child(fill_light)

func _setup_orbital_map() -> void:
	if orbital_map_root != null:
		return
	orbital_map_root = Node3D.new()
	orbital_map_root.name = "OrbitalMap3D"
	orbital_map_root.position = Vector3(0, 0, 0)
	add_child(orbital_map_root)
	
	# Sun at center of map
	var sun_mesh_inst := MeshInstance3D.new()
	var s_sphere := SphereMesh.new()
	s_sphere.radius = 2.8
	s_sphere.height = 5.6
	var s_mat := StandardMaterial3D.new()
	s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s_mat.albedo_color = Color(1.0, 0.9, 0.25, 1.0)
	sun_mesh_inst.mesh = s_sphere
	sun_mesh_inst.material_override = s_mat
	orbital_map_root.add_child(sun_mesh_inst)
	
	# Earth orbit ring (radius = 18.0)
	var e_ring := MeshInstance3D.new()
	var e_torus := TorusMesh.new()
	e_torus.inner_radius = 17.85
	e_torus.outer_radius = 18.15
	e_torus.rings = 64
	var ring_mat_e := StandardMaterial3D.new()
	ring_mat_e.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat_e.albedo_color = Color(0.15, 0.55, 0.95, 0.35)
	ring_mat_e.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	e_ring.mesh = e_torus
	e_ring.material_override = ring_mat_e
	orbital_map_root.add_child(e_ring)
	
	# Mars orbit ring (radius = 27.43)
	var m_ring := MeshInstance3D.new()
	var m_torus := TorusMesh.new()
	m_torus.inner_radius = 27.25
	m_torus.outer_radius = 27.60
	m_torus.rings = 64
	var ring_mat_m := StandardMaterial3D.new()
	ring_mat_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat_m.albedo_color = Color(0.95, 0.45, 0.2, 0.35)
	ring_mat_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m_ring.mesh = m_torus
	m_ring.material_override = ring_mat_m
	orbital_map_root.add_child(m_ring)
	
	# Earth map marker
	earth_map_marker = MeshInstance3D.new()
	var em_mesh := SphereMesh.new()
	em_mesh.radius = 1.0
	em_mesh.height = 2.0
	var em_mat := StandardMaterial3D.new()
	em_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em_mat.albedo_color = Color(0.2, 0.65, 1.0, 1.0)
	earth_map_marker.mesh = em_mesh
	earth_map_marker.material_override = em_mat
	orbital_map_root.add_child(earth_map_marker)
	
	# Mars map marker
	mars_map_marker = MeshInstance3D.new()
	var mm_mesh := SphereMesh.new()
	mm_mesh.radius = 0.8
	mm_mesh.height = 1.6
	var mm_mat := StandardMaterial3D.new()
	mm_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm_mat.albedo_color = Color(1.0, 0.45, 0.2, 1.0)
	mars_map_marker.mesh = mm_mesh
	mars_map_marker.material_override = mm_mat
	orbital_map_root.add_child(mars_map_marker)
	
	# Spacecraft map marker (Golden pulsing beacon)
	sc_map_marker = MeshInstance3D.new()
	var scm_mesh := SphereMesh.new()
	scm_mesh.radius = 0.95
	scm_mesh.height = 1.9
	var scm_mat := StandardMaterial3D.new()
	scm_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	scm_mat.albedo_color = Color(1.0, 0.85, 0.1, 1.0)
	sc_map_marker.mesh = scm_mesh
	sc_map_marker.material_override = scm_mat
	orbital_map_root.add_child(sc_map_marker)
	
	orbital_map_root.visible = false

func _load_spacecraft_configuration() -> void:
	var gm: Node = null
	if Engine.has_singleton("GameManager"):
		gm = Engine.get_singleton("GameManager")
	elif is_inside_tree() and get_tree().root.has_node("GameManager"):
		gm = get_tree().root.get_node("GameManager")
		
	if gm:
		# Bus selection
		var has_heavy: bool = gm.has_component("BUS_HEAVY") if gm.has_method("has_component") else false
		if bus_light and bus_heavy:
			bus_light.visible = not has_heavy
			bus_heavy.visible = has_heavy
			
		# Power subsystem (Solar vs MMRTG)
		var has_rtg: bool = gm.has_component("PWR_MMRTG") if gm.has_method("has_component") else false
		if mmrtg_unit:
			mmrtg_unit.visible = has_rtg
		if solar_wing_l and solar_wing_r:
			solar_wing_l.visible = not has_rtg
			solar_wing_r.visible = not has_rtg
			
		# Route configuration
		var route: Dictionary = gm.get_selected_mission_route() if gm.has_method("get_selected_mission_route") else {}
		selected_route_id = route.get("id", "ROUTE_B_HOHMANN")
		total_transit_days = float(route.get("duration_days", 260))
		
		# Configure orbital transfer mechanics based on route
		if selected_route_id == "ROUTE_A_FAST":
			sma_au = 1.340 # Higher energy ellipse
			ecc = 0.285
			total_transit_days = 180.0
			base_days_per_second = 0.45
		else:
			sma_au = 1.262 # Standard Hohmann ellipse
			ecc = 0.2076
			total_transit_days = 260.0
			base_days_per_second = 0.35
			
		# Propellant and mass
		spacecraft_dry_mass_kg = gm.calculate_spacecraft_dry_mass() if gm.has_method("calculate_spacecraft_dry_mass") else 800.0
		propellant_kg = 850.0 if not has_heavy else 1250.0
		initial_propellant_kg = propellant_kg
		print("[SpaceFlight3D] Spacecraft configured. Route: %s (%dd), Propellant: %.1f kg." % [selected_route_id, int(total_transit_days), propellant_kg])

# =========================================================================
# CORE SIMULATION UPDATE LOOP
# =========================================================================

func _process(delta: float) -> void:
	_process_flight_controls(delta)
	_update_simulation_physics(delta)
	_process_celestial_bodies(delta)
	_process_cameras(delta)
	_emit_telemetry_tick(delta)

func _process_propulsion(delta: float) -> void:
	_update_simulation_physics(delta)

func _process_flight_controls(delta: float) -> void:
	# Continuous angular damping
	craft_angular_vel = craft_angular_vel.move_toward(Vector3.ZERO, delta * 1.8)
	craft_rotation += craft_angular_vel * delta
	
	if spacecraft_rig:
		spacecraft_rig.rotation.x = craft_rotation.x
		spacecraft_rig.rotation.y = craft_rotation.y
		spacecraft_rig.rotation.z = craft_rotation.z
		
	# Smoothly tilt flight stick in cockpit
	if flight_stick_pivot:
		flight_stick_pivot.rotation.z = lerpf(flight_stick_pivot.rotation.z, -craft_angular_vel.y * 0.4, delta * 8.0)
		flight_stick_pivot.rotation.x = lerpf(flight_stick_pivot.rotation.x, craft_angular_vel.x * 0.4, delta * 8.0)

func _update_simulation_physics(delta: float) -> void:
	# 1. Smooth throttle response
	throttle = move_toward(throttle, target_throttle, delta * 2.0)
	
	# Auto-engage Trans-Mars Injection if player increases throttle in Earth orbit
	if current_phase == FlightPhase.EARTH_ORBIT and (throttle > 0.02 or target_throttle > 0.02):
		set_flight_phase(FlightPhase.EARTH_DEPARTURE)
	
	# Update 3D Throttle lever in cockpit (-0.65 to +0.65 rad)
	if throttle_lever_pivot:
		throttle_lever_pivot.rotation.x = lerpf(-0.65, 0.65, throttle)
		
	# 2. Engine Thrust & Fuel Consumption Dynamics
	is_engine_burning = (throttle > 0.01 or retrograde_throttle > 0.01) and (propellant_kg > 0.0)
	
	if is_engine_burning:
		is_coasting = false
		var eff_throt := maxf(throttle, retrograde_throttle)
		engine_thrust_kn = eff_throt * max_engine_thrust_kn
		var total_mass_kg := spacecraft_dry_mass_kg + propellant_kg
		acceleration_ms2 = (engine_thrust_kn * 1000.0) / maxf(100.0, total_mass_kg)
		
		# Fuel consumption: m_dot = Thrust / (Isp * g0)
		var m_dot := (engine_thrust_kn * 1000.0) / (engine_isp_s * 9.80665) # kg/s
		var burn_delta := delta * (1.0 + (time_warp_scale - 1.0) * 0.15) * 0.35
		var consumed := m_dot * burn_delta
		propellant_kg = maxf(0.0, propellant_kg - consumed)
		
		# Velocity change from burn
		if current_phase == FlightPhase.MARS_ORBIT_INSERTION or is_retrograde_burning or retrograde_throttle > 0.01:
			# Braking retrograde burn (reduces velocity opposite to flight vector)
			var retro_factor := 6.0 if current_phase == FlightPhase.MARS_ORBIT_INSERTION else 5.0
			var floor_v := 3.4 if current_phase == FlightPhase.MARS_ORBIT_INSERTION else target_cutoff_velocity_kms
			velocity_kms = maxf(floor_v, velocity_kms - (acceleration_ms2 * delta * 0.001 * retro_factor))
		else:
			# Prograde acceleration burn
			velocity_kms += acceleration_ms2 * delta * 0.001 * 3.5
			
		# Cockpit rumble vibration during engine burn
		if cam_cockpit and current_camera_mode == CameraMode.COCKPIT:
			var shake := (randf() - 0.5) * 0.012 * eff_throt
			cam_cockpit.h_offset = shake
			cam_cockpit.v_offset = shake
	else:
		engine_thrust_kn = 0.0
		acceleration_ms2 = 0.0
		is_coasting = true
		
	# Maneuver window countdown timer
	if maneuver_window_active:
		maneuver_countdown_s -= delta
		if maneuver_countdown_s <= 0.0:
			maneuver_countdown_s = 0.0
			if not (is_retrograde_burning or retrograde_throttle > 0.01):
				maneuver_missed = true
				# Auto-recover so the player is never trapped or frozen in departure!
				recover_maneuver_burn()
				
	# Attitude alignment calculation
	update_attitude_guidance()
		
	# 3. Audio & Particle Updates
	if flame_mesh:
		flame_mesh.visible = is_engine_burning
		var sc := lerpf(0.5, 2.2, throttle)
		flame_mesh.scale = Vector3(sc * 0.8, sc, sc * 0.8)
	if flame_particles:
		flame_particles.emitting = is_engine_burning
		flame_particles.speed_scale = lerpf(1.0, 3.0, throttle)
	if exhaust_light:
		exhaust_light.visible = is_engine_burning
		exhaust_light.light_energy = lerpf(1.5, 6.0, throttle)
		
	if audio_engine:
		if is_engine_burning:
			if not audio_engine.playing:
				audio_engine.volume_db = -40.0
				audio_engine.play()
			var target_db := lerpf(-24.0, 2.0, throttle)
			audio_engine.volume_db = move_toward(audio_engine.volume_db, target_db, delta * 30.0)
			audio_engine.pitch_scale = lerpf(0.85, 1.35, throttle)
		else:
			if audio_engine.playing:
				audio_engine.volume_db = move_toward(audio_engine.volume_db, -80.0, delta * 45.0)
				if audio_engine.volume_db <= -75.0:
					audio_engine.stop()
					
	# 4. Advance Mission Time & Trajectory Progress
	# Both during burn AND during coasting, interplanetary journey advances continuously!
	var sim_dt := minf(delta, 10.0) * base_days_per_second * time_warp_scale
	if is_engine_burning and (current_phase == FlightPhase.INTERPLANETARY_CRUISE or current_phase == FlightPhase.EARTH_DEPARTURE):
		sim_dt *= (1.0 + throttle * 1.5) # Burns hasten trajectory transit
		
	if current_phase == FlightPhase.EARTH_DEPARTURE:
		mission_day += delta * 0.5 * (1.0 + throttle * 1.0) * time_warp_scale
		trajectory_progress = clampf(mission_day / total_transit_days, 0.0, 1.0)
		if mission_day >= 2.0:
			set_flight_phase(FlightPhase.INTERPLANETARY_CRUISE)
	elif current_phase >= FlightPhase.INTERPLANETARY_CRUISE and current_phase <= FlightPhase.MARS_APPROACH:
		mission_day = minf(total_transit_days, mission_day + sim_dt)
		trajectory_progress = clampf(mission_day / total_transit_days, 0.0, 1.0)
		# When within 2% of destination, auto-enter Mars Approach
		if trajectory_progress >= 0.98 and current_phase == FlightPhase.INTERPLANETARY_CRUISE:
			set_flight_phase(FlightPhase.MARS_APPROACH)
	elif current_phase >= FlightPhase.MARS_ORBIT_INSERTION:
		mission_day = total_transit_days
		trajectory_progress = 1.0
		
	# 5. Calculate Simulated Heliocentric Positions (Astronomical Units)
	var theta_transfer := trajectory_progress * PI # 0 at Earth, PI at Mars
	var r_sc_au := (sma_au * (1.0 - ecc * ecc)) / (1.0 + ecc * cos(theta_transfer))
	sc_helio_pos_au = Vector2(r_sc_au * cos(theta_transfer), r_sc_au * sin(theta_transfer))
	
	# Earth revolves around Sun at 1.0 AU (Period 365.25 days)
	var earth_angle := (TAU / 365.25) * mission_day
	earth_helio_pos_au = Vector2(R_EARTH_AU * cos(earth_angle), R_EARTH_AU * sin(earth_angle))
	
	# Mars revolves around Sun at 1.524 AU (Period 686.98 days)
	var mars_angle := initial_mars_angle_rad + (TAU / 686.98) * mission_day
	mars_helio_pos_au = Vector2(R_MARS_AU * cos(mars_angle), R_MARS_AU * sin(mars_angle))
	
	# 6. Recalculate Earth and Mars Distances From Real Position Vectors
	var earth_dist_au := sc_helio_pos_au.distance_to(earth_helio_pos_au)
	var mars_dist_au := sc_helio_pos_au.distance_to(mars_helio_pos_au)
	
	if current_phase == FlightPhase.EARTH_ORBIT:
		distance_from_earth_km = 420.0
		distance_to_mars_km = maxf(150000000.0, mars_dist_au * AU_KM)
	elif current_phase == FlightPhase.EARTH_DEPARTURE:
		distance_from_earth_km = lerpf(420.0, 2500000.0, clampf(mission_day / 2.0, 0.0, 1.0))
		distance_to_mars_km = maxf(120000000.0, mars_dist_au * AU_KM)
	elif current_phase == FlightPhase.MARS_APPROACH:
		distance_from_earth_km = maxf(180000000.0, earth_dist_au * AU_KM)
		distance_to_mars_km = lerpf(30000.0, 350.0, clampf((trajectory_progress - 0.98) / 0.02, 0.0, 1.0))
	elif current_phase == FlightPhase.MARS_ORBIT_INSERTION:
		distance_from_earth_km = maxf(180000000.0, earth_dist_au * AU_KM)
		distance_to_mars_km = 350.0
	elif current_phase == FlightPhase.MARS_ORBIT_ACHIEVED:
		distance_from_earth_km = maxf(180000000.0, earth_dist_au * AU_KM)
		distance_to_mars_km = 300.0
	else:
		# Standard Interplanetary Cruise & Mid-Course Correction:
		# Evolving continuously from vector geometry!
		distance_from_earth_km = maxf(1000000.0, earth_dist_au * AU_KM)
		distance_to_mars_km = maxf(30000.0, mars_dist_au * AU_KM)
		
	# 7. Keplerian Vis-Viva Coasting Velocity
	if not is_engine_burning and current_phase == FlightPhase.INTERPLANETARY_CRUISE:
		var r_km := r_sc_au * AU_KM
		var a_km := sma_au * AU_KM
		var mu_sun := 1.3271244e11
		velocity_kms = sqrt(mu_sun * (2.0 / r_km - 1.0 / a_km))
		
	# 8. Update 3D World Spatial Scene & Map
	_update_3d_spatial_scene(delta)
	_update_orbital_map_markers()

func _update_3d_spatial_scene(delta: float = 0.016) -> void:
	if current_phase == FlightPhase.MARS_ORBIT_ACHIEVED:
		# Visible circular/elliptical orbital flight around Mars!
		mars_orbit_angle += delta * 0.45 * time_warp_scale
		var r_orbit := 16.0
		var sx := cos(mars_orbit_angle) * r_orbit
		var sz := sin(mars_orbit_angle) * r_orbit
		var sy := sin(mars_orbit_angle * 1.5) * 2.2 # Slight 15° orbital inclination
		if spacecraft_rig:
			spacecraft_rig.position = Vector3(sx, sy, sz)
			spacecraft_rig.rotation.y = -mars_orbit_angle + PI * 0.5
			spacecraft_rig.rotation.x = -0.1
		if mars_system:
			mars_system.visible = true
			mars_system.position = Vector3.ZERO
			mars_system.scale = Vector3(1.25, 1.25, 1.25)
		if cam_mars_cinematic and current_camera_mode == CameraMode.MARS_CINEMATIC:
			var cam_angle := mars_orbit_angle * 0.22 + 0.8
			cam_mars_cinematic.position = Vector3(cos(cam_angle) * 34.0, 16.0, sin(cam_angle) * 34.0)
			cam_mars_cinematic.look_at(Vector3.ZERO, Vector3.UP)
		return

	var p := trajectory_progress
	
	# Spacecraft 3D coordinate along the visual cruise corridor
	# Curves along transfer arc in 3D world space
	var visual_z := lerpf(0.0, -180.0, p)
	var visual_x := sin(p * PI) * 28.0
	
	if spacecraft_rig:
		spacecraft_rig.position = Vector3(visual_x, 0.0, visual_z)
		
	# Earth System: Recedes behind the spacecraft and shrinks smoothly
	if earth_system:
		if p < 0.02:
			earth_system.visible = true
			earth_system.position = Vector3(0.0, -20.0, visual_z + 18.0)
			earth_system.scale = Vector3.ONE * lerpf(1.0, 0.35, p / 0.02)
		elif p < 0.70:
			earth_system.visible = true
			var e_dist_3d := lerpf(25.0, 160.0, (p - 0.02) / 0.68)
			earth_system.position = Vector3(visual_x * 0.2, -10.0, visual_z + e_dist_3d)
			earth_system.scale = Vector3.ONE * lerpf(0.25, 0.035, (p - 0.02) / 0.68)
		else:
			earth_system.visible = false
			
	# Mars System: Appears ahead, growing from distant dot to massive planetary world
	if mars_system:
		if p < 0.05:
			mars_system.visible = true
			mars_system.position = Vector3(0.0, 2.0, -200.0)
			mars_system.scale = Vector3.ONE * 0.04
		elif p < 0.88:
			mars_system.visible = true
			var frac := (p - 0.05) / 0.83
			var m_dist_3d := lerpf(-200.0, visual_z - 36.0, frac)
			mars_system.position = Vector3(visual_x * 0.3, lerpf(2.0, -2.0, frac), m_dist_3d)
			mars_system.scale = Vector3.ONE * lerpf(0.05, 0.40, frac)
		else:
			# Mars Approach & Orbit Insertion: Mars looms directly outside the cockpit window
			mars_system.visible = true
			var frac_arr := (p - 0.88) / 0.12
			mars_system.position = Vector3(visual_x, lerpf(-2.0, -8.0, frac_arr), visual_z - lerpf(36.0, 16.0, frac_arr))
			mars_system.scale = Vector3.ONE * lerpf(0.40, 1.25, frac_arr)

func _update_orbital_map_markers() -> void:
	if orbital_map_root == null:
		return
	# Scale factor: 1 AU = 18.0 map units
	var map_scale := 18.0
	
	if earth_map_marker:
		earth_map_marker.position = Vector3(earth_helio_pos_au.x * map_scale, 0.1, earth_helio_pos_au.y * map_scale)
	if mars_map_marker:
		mars_map_marker.position = Vector3(mars_helio_pos_au.x * map_scale, 0.1, mars_helio_pos_au.y * map_scale)
	if sc_map_marker:
		sc_map_marker.position = Vector3(sc_helio_pos_au.x * map_scale, 0.15, sc_helio_pos_au.y * map_scale)
		# Pulsing marker scale for radar beacon effect
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.25
		sc_map_marker.scale = Vector3.ONE * pulse

func _process_celestial_bodies(delta: float) -> void:
	if earth_system and earth_system.visible:
		earth_system.rotate_y(delta * 0.02)
	if mars_system and mars_system.visible:
		mars_system.rotate_y(delta * 0.025)

func _process_cameras(delta: float) -> void:
	match current_camera_mode:
		CameraMode.COCKPIT:
			if cam_cockpit:
				cam_cockpit.rotation.y = lerpf(cam_cockpit.rotation.y, cockpit_look_angles.x, delta * 8.0)
				cam_cockpit.rotation.x = lerpf(cam_cockpit.rotation.x, cockpit_look_angles.y, delta * 8.0)
		CameraMode.EXTERIOR:
			if cam_exterior_pivot:
				cam_exterior_pivot.rotation.y = lerpf(cam_exterior_pivot.rotation.y, ext_orbit_yaw, delta * 6.0)
				cam_exterior_pivot.rotation.x = lerpf(cam_exterior_pivot.rotation.x, ext_orbit_pitch, delta * 6.0)
				if cam_exterior:
					cam_exterior.position.z = lerpf(cam_exterior.position.z, ext_orbit_dist, delta * 6.0)

func get_telemetry_data() -> Dictionary:
	var err := get_attitude_alignment_error()
	var align_pct := clampf((1.0 - (err / PI)) * 100.0, 0.0, 100.0)
	return {
		"phase_id": current_phase,
		"phase_name": get_phase_name(),
		"mission_day": mission_day,
		"total_days": total_transit_days,
		"trajectory_progress": trajectory_progress,
		"route_id": selected_route_id,
		"velocity_kms": velocity_kms,
		"distance_earth_km": distance_from_earth_km,
		"distance_mars_km": distance_to_mars_km,
		"propellant_kg": propellant_kg,
		"propellant_initial_kg": initial_propellant_kg,
		"propellant_pct": (propellant_kg / initial_propellant_kg) * 100.0 if initial_propellant_kg > 0.0 else 0.0,
		"thrust_kn": engine_thrust_kn,
		"acceleration_ms2": acceleration_ms2,
		"cabin_pressure_kpa": cabin_pressure_kpa,
		"cabin_o2_pct": cabin_o2_percent,
		"power_gen_w": power_generation_w,
		"power_cons_w": power_consumption_w,
		"net_power_w": power_generation_w - power_consumption_w,
		"throttle_pct": int(maxf(throttle, retrograde_throttle) * 100.0),
		"is_burning": is_engine_burning,
		"is_coasting": is_coasting,
		"camera_mode": current_camera_mode,
		"is_retrograde": is_retrograde_burning or retrograde_throttle > 0.01,
		"retrograde_throttle_pct": int(retrograde_throttle * 100.0),
		"maneuver_window_active": maneuver_window_active,
		"maneuver_countdown_s": maneuver_countdown_s,
		"maneuver_missed": maneuver_missed,
		"target_cutoff_velocity_kms": target_cutoff_velocity_kms,
		"attitude_alignment_error": attitude_alignment_error,
		"alignment_pct": align_pct,
		"is_attitude_aligned": is_attitude_aligned,
		"target_moi_pitch_deg": rad_to_deg(target_moi_attitude.x),
		"target_moi_yaw_deg": rad_to_deg(target_moi_attitude.y),
		"current_pitch_deg": rad_to_deg(craft_rotation.x),
		"current_yaw_deg": rad_to_deg(craft_rotation.y),
		"mars_orbit_angle": mars_orbit_angle
	}

func _get_telemetry_data() -> Dictionary:
	return get_telemetry_data()

func _emit_telemetry_tick(_delta: float) -> void:
	telemetry_changed.emit(get_telemetry_data())

func set_retrograde_burn(active: bool, retro_throt: float = 1.0) -> void:
	is_retrograde_burning = active
	retrograde_throttle = clampf(retro_throt, 0.0, 1.0) if active else 0.0
	if active:
		if current_phase != FlightPhase.MARS_ORBIT_INSERTION:
			target_throttle = 0.0 # Reduce forward throttle for cruise maneuver
		else:
			target_throttle = 1.0 # 100% main engine burn for MOI
		burn_started.emit("RETROGRADE BRAKING BURN")
	else:
		burn_completed.emit("RETROGRADE BRAKING BURN")

func trigger_maneuver_window(countdown_s: float = 12.0) -> void:
	maneuver_window_active = true
	maneuver_countdown_s = countdown_s
	maneuver_missed = false

func recover_maneuver_burn() -> void:
	# Corrective recovery burn
	maneuver_missed = false
	maneuver_window_active = false
	velocity_kms = target_cutoff_velocity_kms
	propellant_kg = maxf(0.0, propellant_kg - 25.0)

func get_attitude_alignment_error() -> float:
	var dp := absf(craft_rotation.x - target_moi_attitude.x)
	var dy := absf(craft_rotation.y - target_moi_attitude.y)
	return sqrt(dp * dp + dy * dy)

func update_attitude_guidance() -> void:
	attitude_alignment_error = get_attitude_alignment_error()
	is_attitude_aligned = (attitude_alignment_error < 0.20) # ~11.5 deg threshold

# =========================================================================
# FLIGHT CONTROLS API (Player Input Handlers)
# =========================================================================

func apply_yaw_input(dir: float) -> void:
	craft_angular_vel.y += dir * 0.35
	craft_angular_vel.y = clampf(craft_angular_vel.y, -1.2, 1.2)
	_fire_rcs_burst(dir > 0)

func apply_roll_input(dir: float) -> void:
	craft_angular_vel.z += dir * 0.45
	craft_angular_vel.z = clampf(craft_angular_vel.z, -1.5, 1.5)
	_fire_rcs_burst(dir > 0)

func apply_pitch_input(dir: float) -> void:
	craft_angular_vel.x += dir * 0.3
	craft_angular_vel.x = clampf(craft_angular_vel.x, -1.0, 1.0)
	_fire_rcs_burst(dir > 0)

func _fire_rcs_burst(is_positive: bool) -> void:
	if is_positive:
		if rcs_pos_x: rcs_pos_x.restart()
		if rcs_pos_y: rcs_pos_y.restart()
	else:
		if rcs_neg_x: rcs_neg_x.restart()
		if rcs_neg_y: rcs_neg_y.restart()
		
	if audio_rcs:
		audio_rcs.play()

func set_throttle(val: float) -> void:
	target_throttle = clampf(val, 0.0, 1.0)
	if target_throttle > 0.02 and current_phase == FlightPhase.EARTH_ORBIT:
		set_flight_phase(FlightPhase.EARTH_DEPARTURE)

func step_throttle(delta_pct: float) -> void:
	set_throttle(target_throttle + delta_pct)

func handle_cockpit_look(relative: Vector2) -> void:
	if current_camera_mode == CameraMode.COCKPIT:
		cockpit_look_angles.x = clampf(cockpit_look_angles.x - relative.x * 0.003, -0.75, 0.75)
		cockpit_look_angles.y = clampf(cockpit_look_angles.y - relative.y * 0.003, -0.45, 0.45)
	elif current_camera_mode == CameraMode.EXTERIOR and is_mouse_dragging:
		ext_orbit_yaw -= relative.x * 0.005
		ext_orbit_pitch = clampf(ext_orbit_pitch - relative.y * 0.005, -1.2, 1.2)

func handle_zoom(delta_zoom: float) -> void:
	if current_camera_mode == CameraMode.EXTERIOR:
		ext_orbit_dist = clampf(ext_orbit_dist + delta_zoom, 3.5, 14.0)

# =========================================================================
# CAMERA MANAGEMENT
# =========================================================================

func set_camera_view(mode: int) -> void:
	current_camera_mode = mode as CameraMode
	
	if cam_cockpit: cam_cockpit.current = (current_camera_mode == CameraMode.COCKPIT)
	if cam_exterior: cam_exterior.current = (current_camera_mode == CameraMode.EXTERIOR)
	if cam_nav_map: cam_nav_map.current = (current_camera_mode == CameraMode.NAV_MAP)
	if cam_mars_cinematic: cam_mars_cinematic.current = (current_camera_mode == CameraMode.MARS_CINEMATIC)
	
	# Show orbital map root only when viewing the map
	if orbital_map_root:
		orbital_map_root.visible = (current_camera_mode == CameraMode.NAV_MAP)
		
	# Show/hide cockpit interior to avoid mesh obstruction
	if cockpit_interior:
		cockpit_interior.visible = true
		
	print("[SpaceFlight3D] Switched Camera View: %s" % get_camera_view_name())

func cycle_camera_view() -> void:
	var next_mode := (int(current_camera_mode) + 1) % 4
	set_camera_view(next_mode)

func get_camera_view_name() -> String:
	match current_camera_mode:
		CameraMode.COCKPIT: return "Cockpit First-Person View"
		CameraMode.EXTERIOR: return "External Spacecraft Orbit View"
		CameraMode.NAV_MAP: return "Orbital Transfer Map View"
		CameraMode.MARS_CINEMATIC: return "Mars Approach Cinematic View"
		_: return "Unknown View"

# =========================================================================
# FLIGHT PHASE & TRANSITIONS API
# =========================================================================

func set_flight_phase(phase: int) -> void:
	current_phase = phase as FlightPhase
	
	match current_phase:
		FlightPhase.EARTH_ORBIT:
			_setup_earth_orbit_state()
		FlightPhase.EARTH_DEPARTURE:
			_setup_earth_departure_state()
		FlightPhase.INTERPLANETARY_CRUISE:
			_setup_cruise_state()
		FlightPhase.MIDCOURSE_CORRECTION:
			_setup_midcourse_state()
		FlightPhase.MARS_APPROACH:
			_setup_mars_approach_state()
		FlightPhase.MARS_ORBIT_INSERTION:
			_setup_mars_insertion_state()
		FlightPhase.MARS_ORBIT_ACHIEVED:
			_setup_mars_orbit_achieved_state()
			
	phase_advanced.emit(current_phase)
	print("[SpaceFlight3D] Flight Phase Advanced to: %s" % get_phase_name())

func get_phase_name() -> String:
	match current_phase:
		FlightPhase.EARTH_ORBIT: return "EARTH ORBIT • PRE-INJECTION"
		FlightPhase.EARTH_DEPARTURE: return "TRANS-MARS INJECTION (TMI) BURN"
		FlightPhase.INTERPLANETARY_CRUISE: return "INTERPLANETARY HOHMANN CRUISE"
		FlightPhase.MIDCOURSE_CORRECTION: return "MID-COURSE TRAJECTORY CORRECTION"
		FlightPhase.MARS_APPROACH: return "MARS GRAVITATIONAL CAPTURE APPROACH"
		FlightPhase.MARS_ORBIT_INSERTION: return "MARS ORBIT INSERTION (MOI) BURN"
		FlightPhase.MARS_ORBIT_ACHIEVED: return "MARS ORBIT ACHIEVED • CAPTURE CERTIFIED"
		_: return "UNKNOWN PHASE"

func _setup_earth_orbit_state() -> void:
	velocity_kms = 7.78
	distance_from_earth_km = 420.0
	distance_to_mars_km = 225000000.0
	mission_day = 0.0
	trajectory_progress = 0.0
	target_throttle = 0.0
	
	if earth_system:
		earth_system.visible = true
		earth_system.position = Vector3(0, -20.0, -16.0)
		earth_system.scale = Vector3.ONE
	if mars_system:
		mars_system.visible = false
		mars_system.position = Vector3(0, 0, -250.0)
		mars_system.scale = Vector3(0.04, 0.04, 0.04)

func _setup_earth_departure_state() -> void:
	target_throttle = 1.0
	burn_started.emit("TRANS-MARS INJECTION (TMI)")
	
	if earth_system:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(earth_system, "position", Vector3(0, -50.0, -180.0), 3.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(earth_system, "scale", Vector3(0.12, 0.12, 0.12), 3.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	velocity_kms = 11.24 # Earth escape velocity
	distance_from_earth_km = 12500.0
	mission_day = 0.5
	trajectory_progress = 0.5 / total_transit_days

func _setup_cruise_state() -> void:
	target_throttle = 0.0
	velocity_kms = 9.85
	if mission_day < 35.0:
		mission_day = 35.0
	trajectory_progress = mission_day / total_transit_days
	
	# Dynamically derive heliocentric positions and distances from real orbital vectors
	var theta_transfer := trajectory_progress * PI
	var r_sc_au := (sma_au * (1.0 - ecc * ecc)) / (1.0 + ecc * cos(theta_transfer))
	sc_helio_pos_au = Vector2(r_sc_au * cos(theta_transfer), r_sc_au * sin(theta_transfer))
	var earth_angle := (TAU / 365.25) * mission_day
	earth_helio_pos_au = Vector2(R_EARTH_AU * cos(earth_angle), R_EARTH_AU * sin(earth_angle))
	var mars_angle := initial_mars_angle_rad + (TAU / 686.98) * mission_day
	mars_helio_pos_au = Vector2(R_MARS_AU * cos(mars_angle), R_MARS_AU * sin(mars_angle))
	
	distance_from_earth_km = maxf(1000000.0, sc_helio_pos_au.distance_to(earth_helio_pos_au) * AU_KM)
	distance_to_mars_km = maxf(30000.0, sc_helio_pos_au.distance_to(mars_helio_pos_au) * AU_KM)
	
	if earth_system:
		earth_system.visible = true
		earth_system.position = Vector3(0, -15.0, 160.0)
		earth_system.scale = Vector3(0.06, 0.06, 0.06)
		
	if mars_system:
		mars_system.visible = true
		mars_system.position = Vector3(0, 2.0, -140.0)
		mars_system.scale = Vector3(0.15, 0.15, 0.15)

func _setup_midcourse_state() -> void:
	target_throttle = 0.0
	mission_day = maxf(mission_day, 45.0)
	trajectory_progress = mission_day / total_transit_days
	
	var theta_transfer_m := trajectory_progress * PI
	var r_sc_au_m := (sma_au * (1.0 - ecc * ecc)) / (1.0 + ecc * cos(theta_transfer_m))
	sc_helio_pos_au = Vector2(r_sc_au_m * cos(theta_transfer_m), r_sc_au_m * sin(theta_transfer_m))
	var earth_angle_m := (TAU / 365.25) * mission_day
	earth_helio_pos_au = Vector2(R_EARTH_AU * cos(earth_angle_m), R_EARTH_AU * sin(earth_angle_m))
	var mars_angle_m := initial_mars_angle_rad + (TAU / 686.98) * mission_day
	mars_helio_pos_au = Vector2(R_MARS_AU * cos(mars_angle_m), R_MARS_AU * sin(mars_angle_m))
	
	distance_from_earth_km = maxf(1000000.0, sc_helio_pos_au.distance_to(earth_helio_pos_au) * AU_KM)
	distance_to_mars_km = maxf(30000.0, sc_helio_pos_au.distance_to(mars_helio_pos_au) * AU_KM)

func _setup_mars_approach_state() -> void:
	target_throttle = 0.0
	velocity_kms = 5.62 # Hyperbolic approach velocity
	mission_day = total_transit_days - 2.0
	trajectory_progress = (total_transit_days - 2.0) / total_transit_days
	distance_from_earth_km = 215000000.0
	distance_to_mars_km = 15000.0
	
	if earth_system:
		earth_system.visible = false
		
	if mars_system:
		mars_system.visible = true
		mars_system.position = Vector3(0, -2.5, -32.0)
		mars_system.scale = Vector3(0.95, 0.95, 0.95)

func _setup_mars_insertion_state() -> void:
	target_throttle = 1.0
	burn_started.emit("MARS ORBIT INSERTION (MOI)")
	
	var tw := create_tween()
	tw.tween_property(self, "craft_rotation:y", PI, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	velocity_kms = 3.84 # Captured orbital velocity
	distance_to_mars_km = 350.0

func _setup_mars_orbit_achieved_state() -> void:
	target_throttle = 0.0
	velocity_kms = 3.42 # Stable circular orbit speed
	mission_day = total_transit_days
	trajectory_progress = 1.0
	distance_to_mars_km = 300.0
	mars_orbit_angle = 0.0
	
	if mars_system:
		mars_system.visible = true
		mars_system.position = Vector3.ZERO
		mars_system.scale = Vector3(1.25, 1.25, 1.25)
		
	if mars_orbit_path_mesh == null:
		mars_orbit_path_mesh = MeshInstance3D.new()
		mars_orbit_path_mesh.name = "MarsOrbitPath"
		var torus := TorusMesh.new()
		torus.inner_radius = 15.8
		torus.outer_radius = 16.2
		torus.rings = 64
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.2, 0.9, 1.0, 0.65)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mars_orbit_path_mesh.mesh = torus
		mars_orbit_path_mesh.material_override = mat
		add_child(mars_orbit_path_mesh)
	mars_orbit_path_mesh.visible = true
	
	set_camera_view(CameraMode.MARS_CINEMATIC)
	burn_completed.emit("MARS ORBIT INSERTION (MOI)")

# =========================================================================
# DECISION & EVENT RESOLUTIONS
# =========================================================================

func execute_midcourse_burn(dv_ms: float, fuel_consumed: float) -> void:
	print("[SpaceFlight3D] Executing TCM-1 Mid-Course Correction: Delta-V = %.1f m/s, Fuel = %.1f kg." % [dv_ms, fuel_consumed])
	target_throttle = 0.65
	burn_started.emit("TCM-1 MID-COURSE CORRECTION")
	
	propellant_kg = maxf(0.0, propellant_kg - fuel_consumed)
	
	var tw := create_tween()
	tw.tween_interval(1.8)
	tw.tween_callback(func():
		target_throttle = 0.0
		burn_completed.emit("TCM-1 MID-COURSE CORRECTION")
		set_flight_phase(FlightPhase.INTERPLANETARY_CRUISE)
	)

func resolve_solar_tracking() -> void:
	power_generation_w = 460.0
	if audio_comms: audio_comms.play()
	print("[SpaceFlight3D] Solar array tracking nominal. Power restored to 460W.")

func resolve_radiation_shielding() -> void:
	var tw := create_tween()
	tw.tween_property(self, "craft_rotation:x", -0.4, 1.0)
	if audio_comms: audio_comms.play()
	print("[SpaceFlight3D] Aft storm shelter orientation locked towards Sun.")
