extends Node3D

## MissionControl3D.gd - 3D NASA Mission Control & Flight Operations Center
## Renders the high-tech mission debrief environment: central video wall, operator consoles,
## animated orbital trajectory projections, and cinematic camera views.

const LaunchAudioRef = preload("res://scripts/LaunchAudio.gd")

enum ViewMode {
	OVERVIEW = 0,
	VIDEO_WALL = 1,
	CONSOLE_OPERATOR = 2,
	MARS_CINEMATIC = 3
}

@export var current_view: ViewMode = ViewMode.OVERVIEW

# Cameras
@onready var cam_overview: Camera3D = $CamOverview
@onready var cam_wall: Camera3D = $CamVideoWall
@onready var cam_console: Camera3D = $CamConsole
@onready var cam_mars: Camera3D = $CamMarsCinematic

# 3D Elements
@onready var video_wall_screen: MeshInstance3D = $CommandCenter/VideoWall/ScreenMesh
@onready var earth_projection: MeshInstance3D = $CommandCenter/VideoWall/EarthHolo
@onready var mars_projection: MeshInstance3D = $CommandCenter/VideoWall/MarsHolo
@onready var trajectory_arc: MeshInstance3D = $CommandCenter/VideoWall/TrajectoryArc
@onready var cinematic_mars_globe: MeshInstance3D = $CinematicMars/MarsGlobe
@onready var cinematic_rover_model: Node3D = $CinematicMars/RoverModel
@onready var room_audio: AudioStreamPlayer = $AudioRoomHum
@onready var radio_audio: AudioStreamPlayer = $AudioRadioComms

var wall_pulse_time: float = 0.0
var mars_rotation_angle: float = 0.0
var target_cam_pos: Vector3 = Vector3.ZERO
var target_cam_rot: Vector3 = Vector3.ZERO

func _ready() -> void:
	print("[MissionControl3D] Initializing NASA Mission Control debrief environment...")
	_setup_audio()
	set_camera_view(ViewMode.OVERVIEW)

func _setup_audio() -> void:
	if room_audio:
		room_audio.stream = LaunchAudioRef.create_engine_rumble(3.0)
		room_audio.volume_db = -32.0
		room_audio.pitch_scale = 0.45 # Low ambient server room hum
		room_audio.play()
		
	if radio_audio:
		radio_audio.stream = LaunchAudioRef.create_radio_chatter()
		radio_audio.volume_db = -10.0

func _process(delta: float) -> void:
	wall_pulse_time += delta
	
	# Animate Video Wall holographic Earth & Mars
	if earth_projection:
		earth_projection.rotate_y(delta * 0.4)
	if mars_projection:
		mars_projection.rotate_y(delta * 0.35)
		
	# Animate Cinematic Mars view
	if cinematic_mars_globe:
		mars_rotation_angle += delta * 0.15
		cinematic_mars_globe.rotation.y = mars_rotation_angle
		
	# Subtle trajectory beam glow oscillation
	if trajectory_arc and trajectory_arc.material_override:
		var mat := trajectory_arc.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 0.8 + 0.4 * sin(wall_pulse_time * 2.5)

func set_camera_view(mode: ViewMode) -> void:
	current_view = mode
	if cam_overview: cam_overview.current = (mode == ViewMode.OVERVIEW)
	if cam_wall: cam_wall.current = (mode == ViewMode.VIDEO_WALL)
	if cam_console: cam_console.current = (mode == ViewMode.CONSOLE_OPERATOR)
	if cam_mars: cam_mars.current = (mode == ViewMode.MARS_CINEMATIC)
	
	# Toggle visibility between mission control room and cinematic space
	var is_space := (mode == ViewMode.MARS_CINEMATIC)
	if has_node("CommandCenter"):
		$CommandCenter.visible = not is_space
	if has_node("CinematicMars"):
		$CinematicMars.visible = is_space
		
	print("[MissionControl3D] Camera view switched to: %d" % int(mode))

func play_radio_comm() -> void:
	if radio_audio and not radio_audio.playing:
		radio_audio.play()
