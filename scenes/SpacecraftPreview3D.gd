extends Node3D

## SpacecraftPreview3D.gd - Interactive 3D Procedural Spacecraft Preview
## Renders dynamic components, solar wings, high-gain dishes, thrusters, and instruments in real-time.

const GameManagerRef = preload("res://scripts/GameManager.gd")

var _gm_cache: Node = null
func _get_gm() -> Node:
	if _gm_cache:
		return _gm_cache
	if Engine.has_singleton("GameManager"):
		_gm_cache = Engine.get_singleton("GameManager")
	elif is_inside_tree() and get_tree().root.has_node("GameManager"):
		_gm_cache = get_tree().root.get_node("GameManager")
	return _gm_cache

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var craft_root: Node3D = $SpacecraftRoot

# Subsystem Mount Nodes
@onready var bus_mount: Node3D = $SpacecraftRoot/BusMount
@onready var solar_left: Node3D = $SpacecraftRoot/SolarLeft
@onready var solar_right: Node3D = $SpacecraftRoot/SolarRight
@onready var mmrtg_mount: Node3D = $SpacecraftRoot/MMRTGMount
@onready var engine_mount: Node3D = $SpacecraftRoot/EngineMount
@onready var rcs_mount: Node3D = $SpacecraftRoot/RCSMount
@onready var comms_hga: Node3D = $SpacecraftRoot/CommsHGA
@onready var comms_uhf: Node3D = $SpacecraftRoot/CommsUHF
@onready var thermal_mount: Node3D = $SpacecraftRoot/ThermalMount
@onready var mast_mount: Node3D = $SpacecraftRoot/MastMount
@onready var mastcam_node: Node3D = $SpacecraftRoot/MastMount/MastcamZ
@onready var supercam_node: Node3D = $SpacecraftRoot/MastMount/SuperCam
@onready var meda_node: Node3D = $SpacecraftRoot/MastMount/MEDA
@onready var pixl_node: Node3D = $SpacecraftRoot/InstrumentsMount/PIXL
@onready var sherloc_node: Node3D = $SpacecraftRoot/InstrumentsMount/SHERLOC
@onready var rimfax_node: Node3D = $SpacecraftRoot/InstrumentsMount/RIMFAX
@onready var moxie_node: Node3D = $SpacecraftRoot/InstrumentsMount/MOXIE
@onready var bus_light_mesh: MeshInstance3D = $SpacecraftRoot/BusMount/BusLight
@onready var bus_heavy_mesh: MeshInstance3D = $SpacecraftRoot/BusMount/BusHeavy
@onready var bus_placeholder_mesh: MeshInstance3D = $SpacecraftRoot/BusMount/BusPlaceholder

# Camera Orbit & Zoom State
var is_dragging: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO
var target_yaw: float = 0.6
var target_pitch: float = -0.35
var target_dist: float = 5.2
var auto_rotate: bool = true

const MIN_DIST: float = 2.6
const MAX_DIST: float = 8.5
const ROTATION_SPEED: float = 0.006
const ZOOM_SPEED: float = 0.35

func _ready() -> void:
	var gm = _get_gm()
	if gm:
		gm.spacecraft_config_changed.connect(update_spacecraft_model)
	reset_camera()
	update_spacecraft_model()

func _process(delta: float) -> void:
	if auto_rotate and not is_dragging:
		target_yaw += delta * 0.25
		
	# Smoothly interpolate camera pivot
	camera_pivot.rotation.y = lerpf(camera_pivot.rotation.y, target_yaw, delta * 8.0)
	camera_pivot.rotation.x = lerpf(camera_pivot.rotation.x, target_pitch, delta * 8.0)
	camera.position.z = lerpf(camera.position.z, target_dist, delta * 8.0)

func handle_subviewport_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = mb.pressed
			last_mouse_pos = mb.position
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			target_dist = clampf(target_dist - ZOOM_SPEED, MIN_DIST, MAX_DIST)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			target_dist = clampf(target_dist + ZOOM_SPEED, MIN_DIST, MAX_DIST)
			
	elif event is InputEventMouseMotion and is_dragging:
		var mm := event as InputEventMouseMotion
		var diff := mm.position - last_mouse_pos
		last_mouse_pos = mm.position
		target_yaw -= diff.x * ROTATION_SPEED
		target_pitch = clampf(target_pitch - diff.y * ROTATION_SPEED, -1.2, 0.4)

func reset_camera() -> void:
	target_yaw = 0.6
	target_pitch = -0.32
	target_dist = 5.2

func set_auto_rotate(enabled: bool) -> void:
	auto_rotate = enabled

func update_spacecraft_model() -> void:
	var gm = _get_gm()
	if not gm:
		return
		
	var has_light_bus: bool = gm.has_component("BUS_LIGHT")
	var has_heavy_bus: bool = gm.has_component("BUS_HEAVY")
	var has_any_bus: bool = has_light_bus or has_heavy_bus
	
	if bus_light_mesh:
		bus_light_mesh.visible = has_light_bus
	if bus_heavy_mesh:
		bus_heavy_mesh.visible = has_heavy_bus
	if bus_placeholder_mesh:
		bus_placeholder_mesh.visible = not has_any_bus
		
	# Power Systems
	var has_solar: bool = gm.has_component("PWR_SOLAR_ULTRAFLEX")
	var has_mmrtg: bool = gm.has_component("PWR_MMRTG")
	if solar_left:
		solar_left.visible = has_solar
	if solar_right:
		solar_right.visible = has_solar
	if mmrtg_mount:
		mmrtg_mount.visible = has_mmrtg
		
	# Propulsion Systems
	var has_biprop: bool = gm.has_component("PROP_BIPROP") or gm.has_component("PROP_DUAL_MODE")
	var has_rcs: bool = gm.has_component("PROP_MONO_RCS")
	if engine_mount:
		engine_mount.visible = has_biprop
	if rcs_mount:
		rcs_mount.visible = has_rcs
		
	# Telecom Systems
	var has_hga: bool = gm.has_component("COMMS_HIGH_GAIN")
	var has_uhf: bool = gm.has_component("COMMS_UHF_RELAY")
	if comms_hga:
		comms_hga.visible = has_hga
	if comms_uhf:
		comms_uhf.visible = has_uhf
		
	# Thermal Radiators
	var has_thermal: bool = gm.has_component("THM_HEATPIPE_LOUVER") or gm.has_component("THM_LOUVERS")
	if thermal_mount:
		thermal_mount.visible = has_thermal
		
	# Scientific Instruments
	var has_mastcam: bool = gm.has_instrument("INST_MASTCAM_Z")
	var has_supercam: bool = gm.has_instrument("INST_SUPERCAM")
	var has_meda: bool = gm.has_instrument("INST_MEDA")
	var has_pixl: bool = gm.has_instrument("INST_PIXL")
	var has_sherloc: bool = gm.has_instrument("INST_SHERLOC")
	var has_rimfax: bool = gm.has_instrument("INST_RIMFAX")
	var has_moxie: bool = gm.has_instrument("INST_MOXIE")
	
	var needs_mast: bool = has_mastcam or has_supercam or has_meda
	if mast_mount:
		mast_mount.visible = needs_mast
	if mastcam_node:
		mastcam_node.visible = has_mastcam
	if supercam_node:
		supercam_node.visible = has_supercam
	if meda_node:
		meda_node.visible = has_meda
	if pixl_node:
		pixl_node.visible = has_pixl
	if sherloc_node:
		sherloc_node.visible = has_sherloc
	if rimfax_node:
		rimfax_node.visible = has_rimfax
	if moxie_node:
		moxie_node.visible = has_moxie
