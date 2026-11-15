extends CanvasLayer

## DemoModeHUD.gd - Floating Hackathon Presentation & Judge Mode Controller
## Provides an on-screen stage selector allowing judges to instantly navigate
## across all 8 major simulation milestones in MARS DEEP.

const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")

const DEMO_STAGES: Array[Dictionary] = [
	{"name": "1. Main Menu", "scene": "res://scenes/MainMenu.tscn"},
	{"name": "2. Mission Briefing", "scene": "res://scenes/MissionBriefing.tscn"},
	{"name": "3. 3D Spacecraft Designer", "scene": "res://scenes/MissionDesign.tscn"},
	{"name": "4. Engineering Lab & Math", "scene": "res://scenes/EngineeringLab.tscn"},
	{"name": "5. Pad 39A Launch & Cockpit", "scene": "res://scenes/LaunchPreparation.tscn"},
	{"name": "6. Interplanetary Spaceflight", "scene": "res://scenes/MissionSimulation.tscn"},
	{"name": "7. Mars Descent & Rover", "scene": "res://scenes/MarsExploration.tscn"},
	{"name": "8. Mission Debrief & Report", "scene": "res://scenes/MissionReport.tscn"}
]

@onready var panel: PanelContainer = $TopBar/PanelContainer
@onready var lbl_badge: Label = $TopBar/PanelContainer/Margin/HBox/LblBadge
@onready var opt_stages: OptionButton = $TopBar/PanelContainer/Margin/HBox/OptStages
@onready var btn_jump: Button = $TopBar/PanelContainer/Margin/HBox/BtnJump
@onready var btn_exit_demo: Button = $TopBar/PanelContainer/Margin/HBox/BtnExitDemo

func _ready() -> void:
	layer = 120 # Draw above other HUDs
	_apply_styles()
	_populate_stages()
	_connect_signals()
	_update_visibility()

func _apply_styles() -> void:
	if panel:
		panel.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.04, 0.08, 0.12, 0.95), MarsDeepUIRef.COLOR_ORANGE, 1, 4, 8))

func _populate_stages() -> void:
	if not opt_stages: return
	opt_stages.clear()
	for s in DEMO_STAGES:
		opt_stages.add_item(s.get("name", ""))

func _connect_signals() -> void:
	if btn_jump: btn_jump.pressed.connect(_on_jump_pressed)
	if btn_exit_demo: btn_exit_demo.pressed.connect(_on_exit_demo_pressed)

func _update_visibility() -> void:
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		visible = gm.is_demo_mode
	else:
		visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if has_node("/root/GameManager"):
			var gm = get_node("/root/GameManager")
			if gm and gm.is_demo_mode:
				visible = not visible

func _on_jump_pressed() -> void:
	var idx := opt_stages.selected
	jump_to_stage(idx)

func jump_to_stage(idx: int) -> void:
	if idx >= 0 and idx < DEMO_STAGES.size():
		var target_scene: String = DEMO_STAGES[idx].get("scene", "")
		print("[DemoModeHUD] Judge jumping to Stage %d: %s" % [idx + 1, target_scene])
		get_tree().change_scene_to_file(target_scene)

func _on_exit_demo_pressed() -> void:
	print("[DemoModeHUD] Exiting Demo Mode...")
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").deactivate_demo_mode()
	visible = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
