extends Node3D

## RocketPreview3D.gd - Complete Aerospace Launchpad Environment & Multi-Camera Simulation
## MARS DEEP • NASA Space Apps Challenge 2026

signal launch_animation_finished()
signal meco_achieved()
signal clamps_released()

enum CameraView {
	PAD_OVERVIEW,
	ENGINES_CLOSE,
	UNDER_ROCKET,
	COCKPIT,
	TRACKING_LIFTOFF
}

var _gm_cache: Node = null
func _get_gm() -> Node:
	if _gm_cache:
		return _gm_cache
	if Engine.has_singleton("GameManager"):
		_gm_cache = Engine.get_singleton("GameManager")
	elif is_inside_tree() and get_tree().root.has_node("GameManager"):
		_gm_cache = get_tree().root.get_node("GameManager")
	return _gm_cache

# Cameras & Views
@onready var cam_pad_overview: Camera3D = $Cameras/CamPadOverview
@onready var cam_engines_close: Camera3D = $Cameras/CamEnginesClose
@onready var cam_under_rocket: Camera3D = $Cameras/CamUnderRocket
@onready var cam_cockpit: Camera3D = $RocketAssembly/CockpitInterior/CamCockpit
@onready var cam_tracking_liftoff: Camera3D = $Cameras/CamTrackingLiftoff

# Active camera tracking
var active_camera_view: CameraView = CameraView.PAD_OVERVIEW
var current_camera: Camera3D = null

# Rocket Assembly
@onready var rocket_assembly: Node3D = $RocketAssembly
@onready var core_mesh: MeshInstance3D = $RocketAssembly/CoreStage
@onready var interstage_mesh: MeshInstance3D = $RocketAssembly/Interstage
@onready var upper_mesh: MeshInstance3D = $RocketAssembly/UpperStage
@onready var fairing_mesh: MeshInstance3D = $RocketAssembly/Fairing
@onready var fairing_cone: MeshInstance3D = $RocketAssembly/FairingNose
@onready var boosters_node: Node3D = $RocketAssembly/Boosters
@onready var engines_node: Node3D = $RocketAssembly/Engines
@onready var nozzle_main: MeshInstance3D = $RocketAssembly/Engines/NozzleMain

# Cockpit 3D Interior & Throttle Lever
@onready var cockpit_interior: Node3D = $RocketAssembly/CockpitInterior
@onready var throttle_lever_pivot: Node3D = $RocketAssembly/CockpitInterior/ThrottleLeverPivot

# Launchpad Facility & Clamps
@onready var umbilical_core: Node3D = $LaunchFacility/ServiceTower/UmbilicalArmCore
@onready var umbilical_upper: Node3D = $LaunchFacility/ServiceTower/UmbilicalArmUpper
@onready var clamps_node: Node3D = $LaunchFacility/HoldDownClamps
@onready var tower_warning_light: OmniLight3D = $LaunchFacility/ServiceTower/BeaconLight

# Exhaust & Smoke FX
@onready var exhaust_plume: Node3D = $RocketAssembly/ExhaustPlume
@onready var flame_mesh: MeshInstance3D = $RocketAssembly/ExhaustPlume/FlameMesh
@onready var flame_particles: CPUParticles3D = $RocketAssembly/ExhaustPlume/FlameParticles
@onready var trench_smoke_particles: CPUParticles3D = $LaunchFacility/FlameTrench/SmokeParticles
@onready var exhaust_light: OmniLight3D = $RocketAssembly/ExhaustPlume/ExhaustLight

# Camera Orbit State (for manual orbit in overview mode)
var is_dragging: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO
var target_yaw: float = 0.55
var target_pitch: float = -0.15
var target_dist: float = 24.0
var auto_rotate: bool = false

# Throttle & Engine State
var current_throttle: float = 0.0 # 0.0 to 1.0
var target_throttle: float = 0.0
var are_engines_ignited: bool = false
var are_clamps_released: bool = false

# Liftoff Flight Dynamics State
var is_launching: bool = false
var launch_time: float = 0.0
var altitude_m: float = 0.0
var velocity_m_s: float = 0.0
var meco_triggered: bool = false

# Initial Camera Tracking Points
var initial_ascent_cam_pos: Vector3 = Vector3(18.0, 3.5, 24.0)

# Tower Beacon Flash Timer
var beacon_timer: float = 0.0

func _ready() -> void:
	exhaust_plume.visible = false
	if trench_smoke_particles:
		trench_smoke_particles.emitting = false
	if flame_particles:
		flame_particles.emitting = false
		
	var gm = _get_gm()
	if gm:
		if not gm.launch_vehicle_selected.is_connected(update_rocket_model):
			gm.launch_vehicle_selected.connect(update_rocket_model)
		update_rocket_model(gm.selected_launch_vehicle_id)
	else:
		update_rocket_model("LV_ATLAS_V_541")
		
	set_camera_view(CameraView.PAD_OVERVIEW)
	_update_throttle_visuals(0.0)

func _process(delta: float) -> void:
	# Flash tower warning beacons
	beacon_timer += delta * 2.5
	if tower_warning_light:
		tower_warning_light.visible = (fmod(beacon_timer, 2.0) > 1.0) or are_engines_ignited
		
	# Smoothly interpolate throttle value to target
	current_throttle = move_toward(current_throttle, target_throttle, delta * 1.5)
	_update_throttle_visuals(current_throttle)
	
	if is_launching and are_clamps_released:
		_process_liftoff_physics(delta)
	elif are_engines_ignited and not are_clamps_released:
		_process_pad_idle(delta)

func _process_pad_idle(delta: float) -> void:
	# Pre-launch pad rumble vibration scaled to engine power
	if current_camera:
		var rumble_intensity := 0.015 * current_throttle
		current_camera.h_offset = (randf() - 0.5) * rumble_intensity
		current_camera.v_offset = (randf() - 0.5) * rumble_intensity

func _process_liftoff_physics(delta: float) -> void:
	launch_time += delta
	
	# Initial thrust buildup (0.35s ramp), then full net upward acceleration
	var thrust_scale := clampf(launch_time / 0.35, 0.4, 1.0)
	var thrust_accel := (15.5 * current_throttle * thrust_scale) - 9.8
	velocity_m_s = maxf(0.0, velocity_m_s + thrust_accel * delta)
	altitude_m += velocity_m_s * delta
	
	# Physically move rocket world position upward
	rocket_assembly.position.y = altitude_m
	
	# Smooth camera tracking
	if active_camera_view == CameraView.TRACKING_LIFTOFF and cam_tracking_liftoff:
		# Gradually elevate camera position as rocket climbs
		cam_tracking_liftoff.position.y = initial_ascent_cam_pos.y + (altitude_m * 0.15)
		var look_target := rocket_assembly.global_position + Vector3(0, 4.0, 0)
		cam_tracking_liftoff.look_at(look_target, Vector3.UP)
		var shake := (randf() - 0.5) * 0.02 * current_throttle
		cam_tracking_liftoff.h_offset = shake
		cam_tracking_liftoff.v_offset = shake
	elif active_camera_view == CameraView.UNDER_ROCKET and cam_under_rocket:
		# Low angle tracks rocket as it ascends away
		var look_target := rocket_assembly.global_position + Vector3(0, 1.0, 0)
		cam_under_rocket.look_at(look_target, Vector3.UP)
	elif active_camera_view == CameraView.PAD_OVERVIEW and cam_pad_overview:
		var look_target := rocket_assembly.global_position + Vector3(0, 3.0, 0)
		cam_pad_overview.look_at(look_target, Vector3.UP)
		
	# Trigger MECO (Main Engine Cutoff) after ascending
	if altitude_m >= 70.0 and not meco_triggered:
		meco_triggered = true
		print("[RocketPreview3D] MECO (Main Engine Cutoff) achieved at altitude %.1fm!" % altitude_m)
		meco_achieved.emit()
		target_throttle = 0.0
		if flame_particles:
			flame_particles.emitting = false
		if exhaust_plume:
			exhaust_plume.visible = false
		
	if launch_time >= 7.5:
		is_launching = false
		launch_animation_finished.emit()

func set_camera_view(view: CameraView) -> void:
	active_camera_view = view
	cam_pad_overview.current = false
	cam_engines_close.current = false
	cam_under_rocket.current = false
	cam_cockpit.current = false
	cam_tracking_liftoff.current = false
	
	# Cockpit interior is visible in cockpit view
	cockpit_interior.visible = (view == CameraView.COCKPIT)
	
	match view:
		CameraView.PAD_OVERVIEW:
			cam_pad_overview.current = true
			current_camera = cam_pad_overview
			cam_pad_overview.look_at(rocket_assembly.global_position + Vector3(0, 4.0, 0), Vector3.UP)
		CameraView.ENGINES_CLOSE:
			cam_engines_close.current = true
			current_camera = cam_engines_close
			cam_engines_close.look_at(rocket_assembly.global_position + Vector3(0, 0.5, 0), Vector3.UP)
		CameraView.UNDER_ROCKET:
			cam_under_rocket.current = true
			current_camera = cam_under_rocket
			cam_under_rocket.look_at(rocket_assembly.global_position + Vector3(0, 1.2, 0), Vector3.UP)
		CameraView.COCKPIT:
			cam_cockpit.current = true
			current_camera = cam_cockpit
		CameraView.TRACKING_LIFTOFF:
			cam_tracking_liftoff.current = true
			current_camera = cam_tracking_liftoff
			cam_tracking_liftoff.position = initial_ascent_cam_pos + Vector3(0, altitude_m * 0.15, 0)
			cam_tracking_liftoff.look_at(rocket_assembly.global_position + Vector3(0, 4.0, 0), Vector3.UP)

func set_throttle(val: float) -> void:
	target_throttle = clampf(val, 0.0, 1.0)

func ignite_engines(startup_throttle: float = 0.65) -> void:
	are_engines_ignited = true
	target_throttle = startup_throttle
	exhaust_plume.visible = true
	if flame_particles:
		flame_particles.emitting = true
	if trench_smoke_particles:
		trench_smoke_particles.emitting = true

func release_clamps() -> void:
	if are_clamps_released:
		return
	are_clamps_released = true
	is_launching = true
	launch_time = 0.0
	velocity_m_s = 0.0
	
	# Animate all 4 hold-down clamps opening backwards
	for clamp in clamps_node.get_children():
		var arm = clamp.get_node_or_null("ClampArm")
		if arm:
			var tw := create_tween()
			tw.tween_property(arm, "rotation:x", -0.85, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
	# Retract umbilical swing arms away from rocket
	if umbilical_core:
		var tw_core := create_tween()
		tw_core.tween_property(umbilical_core, "rotation:y", 1.4, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if umbilical_upper:
		var tw_upper := create_tween()
		tw_upper.tween_property(umbilical_upper, "rotation:y", 1.4, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	clamps_released.emit()

func set_throttle_visual(throt: float) -> void:
	current_throttle = clampf(throt, 0.0, 1.0)
	target_throttle = current_throttle
	_update_throttle_visuals(current_throttle)

func _update_throttle_visuals(throt: float) -> void:
	# Physically move 3D throttle lever in cockpit: -0.65 rad (0%) to +0.65 rad (100%)
	if throttle_lever_pivot:
		throttle_lever_pivot.rotation.x = lerpf(-0.65, 0.65, throt)
		
	# Scale exhaust flame mesh & emission
	if flame_mesh:
		var scale_y := lerpf(0.5, 1.8, throt)
		var scale_xz := lerpf(0.6, 1.2, throt) + (sin(Time.get_ticks_msec() * 0.04) * 0.04)
		flame_mesh.scale = Vector3(scale_xz, scale_y, scale_xz)
		
	if exhaust_light:
		exhaust_light.light_energy = lerpf(1.5, 5.0, throt)
		
	if flame_particles:
		flame_particles.speed_scale = lerpf(0.8, 2.5, throt)
		flame_particles.amount = int(lerpf(32, 96, throt))

func update_rocket_model(lv_id: String) -> void:
	for child in boosters_node.get_children():
		boosters_node.remove_child(child)
		child.queue_free()
		
	var mat_white := StandardMaterial3D.new()
	mat_white.albedo_color = Color(0.86, 0.88, 0.90)
	mat_white.metallic = 0.25
	mat_white.roughness = 0.45
	
	var mat_orange := StandardMaterial3D.new()
	mat_orange.albedo_color = Color(0.78, 0.42, 0.16)
	mat_orange.metallic = 0.05
	mat_orange.roughness = 0.80
	
	var mat_carbon := StandardMaterial3D.new()
	mat_carbon.albedo_color = Color(0.14, 0.16, 0.18)
	mat_carbon.metallic = 0.5
	mat_carbon.roughness = 0.4
	
	var mat_nozzle := StandardMaterial3D.new()
	mat_nozzle.albedo_color = Color(0.20, 0.22, 0.24)
	mat_nozzle.metallic = 0.85
	mat_nozzle.roughness = 0.35

	nozzle_main.material_override = mat_nozzle

	match lv_id:
		"LV_ATLAS_V_541":
			core_mesh.material_override = mat_white
			core_mesh.scale = Vector3(1.0, 1.0, 1.0)
			upper_mesh.material_override = mat_white
			interstage_mesh.material_override = mat_carbon
			fairing_mesh.material_override = mat_white
			fairing_cone.material_override = mat_white
			_create_solid_boosters(4, 0.35, 3.2, 0.95, mat_white)
			
		"LV_FALCON_HEAVY":
			core_mesh.material_override = mat_white
			core_mesh.scale = Vector3(1.0, 1.1, 1.0)
			upper_mesh.material_override = mat_white
			interstage_mesh.material_override = mat_carbon
			fairing_mesh.material_override = mat_white
			fairing_cone.material_override = mat_white
			_create_side_liquid_boosters(2, 0.65, 6.0, 1.5, mat_white)
			
		"LV_DELTA_IV_HEAVY":
			core_mesh.material_override = mat_orange
			core_mesh.scale = Vector3(1.15, 1.1, 1.15)
			upper_mesh.material_override = mat_white
			interstage_mesh.material_override = mat_carbon
			fairing_mesh.material_override = mat_white
			fairing_cone.material_override = mat_white
			_create_side_liquid_boosters(2, 0.75, 6.5, 1.8, mat_orange)
			
		"LV_SLS_BLOCK_1B":
			core_mesh.material_override = mat_orange
			core_mesh.scale = Vector3(1.4, 1.35, 1.4)
			upper_mesh.material_override = mat_white
			interstage_mesh.material_override = mat_carbon
			fairing_mesh.material_override = mat_white
			fairing_cone.material_override = mat_white
			_create_solid_boosters(2, 0.55, 8.2, 1.85, mat_white)
			
		_:
			core_mesh.material_override = mat_white
			upper_mesh.material_override = mat_white

func _create_solid_boosters(count: int, radius: float, height: float, offset_r: float, mat: Material) -> void:
	var angle_step := TAU / float(count)
	for i in range(count):
		var angle := i * angle_step
		var booster := Node3D.new()
		booster.name = "Booster_%d" % i
		
		var b_cyl := MeshInstance3D.new()
		var cyl_mesh := CylinderMesh.new()
		cyl_mesh.top_radius = radius
		cyl_mesh.bottom_radius = radius
		cyl_mesh.height = height
		b_cyl.mesh = cyl_mesh
		b_cyl.material_override = mat
		b_cyl.position.y = height * 0.5 + 0.3
		booster.add_child(b_cyl)
		
		var b_cone := MeshInstance3D.new()
		var cone_mesh := CylinderMesh.new()
		cone_mesh.top_radius = 0.05
		cone_mesh.bottom_radius = radius
		cone_mesh.height = radius * 2.5
		b_cone.mesh = cone_mesh
		b_cone.material_override = mat
		b_cone.position.y = height + (radius * 1.25) + 0.3
		booster.add_child(b_cone)
		
		booster.position = Vector3(cos(angle) * offset_r, 0.0, sin(angle) * offset_r)
		boosters_node.add_child(booster)

func _create_side_liquid_boosters(count: int, radius: float, height: float, offset_x: float, mat: Material) -> void:
	for i in range(count):
		var side_sign := -1.0 if i == 0 else 1.0
		var booster := Node3D.new()
		booster.name = "LiquidCore_%d" % i
		
		var b_cyl := MeshInstance3D.new()
		var cyl_mesh := CylinderMesh.new()
		cyl_mesh.top_radius = radius
		cyl_mesh.bottom_radius = radius
		cyl_mesh.height = height
		b_cyl.mesh = cyl_mesh
		b_cyl.material_override = mat
		b_cyl.position.y = height * 0.5 + 0.3
		booster.add_child(b_cyl)
		
		var b_cone := MeshInstance3D.new()
		var cone_mesh := CylinderMesh.new()
		cone_mesh.top_radius = 0.1
		cone_mesh.bottom_radius = radius
		cone_mesh.height = radius * 2.8
		b_cone.mesh = cone_mesh
		b_cone.material_override = mat
		b_cone.position.y = height + (radius * 1.4) + 0.3
		booster.add_child(b_cone)
		
		booster.position = Vector3(side_sign * offset_x, 0.0, 0.0)
		boosters_node.add_child(booster)

func handle_subviewport_input(event: InputEvent) -> void:
	if is_launching or active_camera_view != CameraView.PAD_OVERVIEW:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = mb.pressed
			last_mouse_pos = mb.position
	elif event is InputEventMouseMotion and is_dragging:
		var mm := event as InputEventMouseMotion
		target_yaw -= mm.relative.x * 0.005
		target_pitch = clampf(target_pitch - mm.relative.y * 0.005, -0.6, 0.6)
		if cam_pad_overview:
			cam_pad_overview.rotation = Vector3(target_pitch, target_yaw, 0)
