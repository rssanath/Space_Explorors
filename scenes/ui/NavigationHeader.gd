class_name NavigationHeader
extends PanelContainer

## NavigationHeader.gd - Unified Aerospace Top Navigation Bar
## Provides MARS DEEP branding, mission title, campaign level tier, progress readout,
## and consistent Back/Home scene navigation.

const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")

@export var screen_title: String = "MISSION CONTROL" : set = set_screen_title
@export var show_back_button: bool = true : set = set_show_back_button
@export var show_home_button: bool = true : set = set_show_home_button
@export var custom_back_scene: String = ""

@onready var lbl_brand: Label = $Margin/HBox/BrandVBox/BrandTitle
@onready var lbl_brand_sub: Label = $Margin/HBox/BrandVBox/BrandSub
@onready var lbl_screen_title: Label = $Margin/HBox/TitleVBox/ScreenTitle
@onready var lbl_mission_tier: Label = $Margin/HBox/TitleVBox/MissionTier
@onready var lbl_progress: Label = $Margin/HBox/TelemetryHBox/ProgressBadge
@onready var btn_back: Button = $Margin/HBox/NavButtons/BtnBack
@onready var btn_home: Button = $Margin/HBox/NavButtons/BtnHome

signal back_pressed
signal home_pressed

func _ready() -> void:
	_apply_styling()
	_update_header()
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)
	if btn_home:
		btn_home.pressed.connect(_on_home_pressed)

func set_screen_title(val: String) -> void:
	screen_title = val
	if is_node_ready() and lbl_screen_title:
		lbl_screen_title.text = screen_title

func set_show_back_button(s: bool) -> void:
	show_back_button = s
	if is_node_ready() and btn_back:
		btn_back.visible = show_back_button

func set_show_home_button(s: bool) -> void:
	show_home_button = s
	if is_node_ready() and btn_home:
		btn_home.visible = show_home_button

func _apply_styling() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MarsDeepUIRef.COLOR_PANEL_TRANSPARENT
	sb.border_color = MarsDeepUIRef.COLOR_BORDER_SUBTLE
	sb.border_width_bottom = 1
	sb.content_margin_left = 16
	sb.content_margin_top = 8
	sb.content_margin_right = 16
	sb.content_margin_bottom = 8
	add_theme_stylebox_override("panel", sb)

func _update_header() -> void:
	if lbl_screen_title:
		lbl_screen_title.text = screen_title
		
	if Engine.is_editor_hint():
		return
		
	# Connect to GameManager runtime telemetry if present
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		var current_lvl: Dictionary = gm.get_current_level()
		if lbl_mission_tier and not current_lvl.is_empty():
			var lvl_id: String = current_lvl.get("level_id", "01")
			var title_str: String = current_lvl.get("title", "Mission Architect")
			lbl_mission_tier.text = "TIER %s • %s" % [lvl_id, title_str.to_upper()]
			
		if lbl_progress:
			var tasks_done: int = 0
			var total_tasks: int = 23
			if gm.mission_progress:
				tasks_done = gm.mission_progress.completed_tasks.size()
			lbl_progress.text = "TASKS: %d / %d" % [tasks_done, total_tasks]
			
	if btn_back:
		btn_back.visible = show_back_button
	if btn_home:
		btn_home.visible = show_home_button

func _on_back_pressed() -> void:
	back_pressed.emit()
	if not custom_back_scene.is_empty():
		get_tree().change_scene_to_file(custom_back_scene)
	else:
		# Standard back flow
		get_tree().change_scene_to_file("res://scenes/MissionBriefing.tscn")

func _on_home_pressed() -> void:
	home_pressed.emit()
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").return_to_main_menu()
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
