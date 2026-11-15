extends Control

## PauseMenu.gd - Global In-Game Pause Menu for MARS DEEP
## Provides Resume, Restart, Controls Guide, Audio/Graphics Settings, and Main Menu navigation.

const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")

@onready var modal_panel: PanelContainer = $CenterContainer/PanelContainer
@onready var btn_resume: Button = $CenterContainer/PanelContainer/Margin/VBox/BtnResume
@onready var btn_restart: Button = $CenterContainer/PanelContainer/Margin/VBox/BtnRestart
@onready var btn_controls: Button = $CenterContainer/PanelContainer/Margin/VBox/BtnControls
@onready var btn_settings: Button = $CenterContainer/PanelContainer/Margin/VBox/BtnSettings
@onready var btn_main_menu: Button = $CenterContainer/PanelContainer/Margin/VBox/BtnMainMenu

@onready var modal_controls: PanelContainer = $CenterContainer/ModalControls
@onready var btn_close_controls: Button = $CenterContainer/ModalControls/Margin/VBox/BtnCloseControls

@onready var modal_settings: PanelContainer = $CenterContainer/ModalSettings
@onready var slider_master_vol: HSlider = $CenterContainer/ModalSettings/Margin/VBox/MasterHBox/SliderMaster
@onready var slider_sfx_vol: HSlider = $CenterContainer/ModalSettings/Margin/VBox/SFXHBox/SliderSFX
@onready var check_fullscreen: CheckBox = $CenterContainer/ModalSettings/Margin/VBox/CheckFullscreen
@onready var btn_close_settings: Button = $CenterContainer/ModalSettings/Margin/VBox/BtnCloseSettings

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_styles()
	_connect_signals()

func _apply_styles() -> void:
	if modal_panel:
		modal_panel.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.04, 0.07, 0.11, 0.95), MarsDeepUIRef.COLOR_CYAN, 1, 6, 16))
	if modal_controls:
		modal_controls.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.03, 0.05, 0.09, 0.98), MarsDeepUIRef.COLOR_CYAN, 1, 6, 16))
	if modal_settings:
		modal_settings.add_theme_stylebox_override("panel", MarsDeepUIRef.create_panel_style(Color(0.03, 0.05, 0.09, 0.98), MarsDeepUIRef.COLOR_CYAN, 1, 6, 16))

func _connect_signals() -> void:
	if btn_resume: btn_resume.pressed.connect(resume_game)
	if btn_restart: btn_restart.pressed.connect(_on_restart_pressed)
	if btn_controls: btn_controls.pressed.connect(_on_controls_pressed)
	if btn_settings: btn_settings.pressed.connect(_on_settings_pressed)
	if btn_main_menu: btn_main_menu.pressed.connect(_on_main_menu_pressed)
	
	if btn_close_controls: btn_close_controls.pressed.connect(func(): modal_controls.visible = false; modal_panel.visible = true)
	if btn_close_settings: btn_close_settings.pressed.connect(func(): modal_settings.visible = false; modal_panel.visible = true)
	
	if slider_master_vol: slider_master_vol.value_changed.connect(_on_master_vol_changed)
	if slider_sfx_vol: slider_sfx_vol.value_changed.connect(_on_sfx_vol_changed)
	if check_fullscreen: check_fullscreen.toggled.connect(_on_fullscreen_toggled)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		var cur_scene = get_tree().current_scene
		if cur_scene and (cur_scene.name == "MainMenu" or "MainMenu" in cur_scene.scene_file_path):
			return
		if visible:
			resume_game()
		else:
			pause_game()

func pause_game() -> void:
	visible = true
	modal_panel.visible = true
	modal_controls.visible = false
	modal_settings.visible = false
	get_tree().paused = true

func resume_game() -> void:
	visible = false
	get_tree().paused = false

func _on_restart_pressed() -> void:
	resume_game()
	get_tree().reload_current_scene()

func _on_controls_pressed() -> void:
	modal_panel.visible = false
	modal_controls.visible = true

func _on_settings_pressed() -> void:
	modal_panel.visible = false
	modal_settings.visible = true

func _on_main_menu_pressed() -> void:
	resume_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_master_vol_changed(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0) if value > 0.0 else -80.0)

func _on_sfx_vol_changed(_value: float) -> void:
	# Optional SFX bus attenuation
	pass

func _on_fullscreen_toggled(is_toggled: bool) -> void:
	if is_toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
