extends Control

## SceneNav.gd - Generic stage scene navigator for MARS DEEP placeholder scenes.

@export var stage_title: String = "MISSION STAGE"
@export var stage_subtitle: String = "Subsystem Architecture"
@export var stage_description: String = "Engineering modules for this stage will be initialized in upcoming development stages."
@export var next_scene_path: String = ""

@onready var lbl_title: Label = get_node_or_null("MarginContainer/VBoxContainer/Header/TitleVBox/Title")
@onready var lbl_subtitle: Label = get_node_or_null("MarginContainer/VBoxContainer/Header/TitleVBox/Subtitle")
@onready var lbl_desc: Label = get_node_or_null("MarginContainer/VBoxContainer/ContentPanel/Margin/VBox/Desc")
@onready var btn_back: Button = get_node_or_null("MarginContainer/VBoxContainer/Footer/BtnBack")
@onready var btn_home: Button = get_node_or_null("MarginContainer/VBoxContainer/Footer/BtnHome")
@onready var btn_next: Button = get_node_or_null("MarginContainer/VBoxContainer/Footer/BtnNext")

func _ready() -> void:
	if lbl_title:
		lbl_title.text = stage_title
	if lbl_subtitle:
		lbl_subtitle.text = stage_subtitle
	if lbl_desc:
		lbl_desc.text = stage_description
		
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)
	if btn_home:
		btn_home.pressed.connect(_on_home_pressed)
	if btn_next:
		if next_scene_path.is_empty():
			btn_next.visible = false
		else:
			btn_next.pressed.connect(_on_next_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MissionBriefing.tscn")

func _on_home_pressed() -> void:
	GameManager.return_to_main_menu()

func _on_next_pressed() -> void:
	if not next_scene_path.is_empty():
		get_tree().change_scene_to_file(next_scene_path)
