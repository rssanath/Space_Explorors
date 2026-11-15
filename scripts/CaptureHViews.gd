extends SceneTree

## CaptureHViews.gd - Captures 6 High-Resolution Screenshots for Stage H
## Two-phase state machine: Phase 0 sets UI/modal state -> waits 12 frames -> Phase 1 captures PNG -> advances step.

var frames_waited := 0
var capture_step := 0
var state_setup_done := false
var menu_scene: Node = null
var demo_hud: CanvasLayer = null

func _init() -> void:
	print("[CaptureHViews] Initializing Stage H Visual Verification Capture...")
	var scn = load("res://scenes/MainMenu.tscn")
	if scn:
		menu_scene = scn.instantiate()
		root.add_child(menu_scene)
		DirAccess.make_dir_absolute("res://screenshots")
	else:
		print("[CaptureHViews] ERROR: Could not load MainMenu.tscn")
		quit(1)

func _process(_delta: float) -> bool:
	if menu_scene == null:
		return false
		
	if not state_setup_done:
		_setup_step_state(capture_step)
		state_setup_done = true
		frames_waited = 0
		return false
		
	frames_waited += 1
	if frames_waited < 14:
		return false
		
	# Frame settled and rendered
	_save_step_screenshot(capture_step)
	capture_step += 1
	state_setup_done = false
	frames_waited = 0
	
	if capture_step >= 6:
		print("[CaptureHViews] ALL 6 STAGE H SCREENSHOTS CAPTURED!")
		quit(0)
		return true
	return false

func _setup_step_state(step: int) -> void:
	match step:
		0:
			print("[CaptureHViews] Setup H1: 3D Main Menu Cinematic...")
			menu_scene._hide_all_modals()
		1:
			print("[CaptureHViews] Setup H2: Hackathon Demo & Judge Presentation Modal...")
			menu_scene._show_modal(menu_scene.modal_demo)
		2:
			print("[CaptureHViews] Setup H3: NASA Educational Objectives & Credits Modal...")
			menu_scene._show_modal(menu_scene.modal_credits)
		3:
			print("[CaptureHViews] Setup H4: Astronaut Controls Reference Modal...")
			menu_scene._show_modal(menu_scene.modal_controls)
		4:
			print("[CaptureHViews] Setup H5: Universal Game Settings Modal...")
			menu_scene._show_modal(menu_scene.modal_settings)
		5:
			print("[CaptureHViews] Setup H6: In-Game Floating Demo Mode HUD...")
			menu_scene._hide_all_modals()
			var hud_scn = load("res://scenes/ui/DemoModeHUD.tscn")
			if hud_scn:
				demo_hud = hud_scn.instantiate()
				root.add_child(demo_hud)
				demo_hud.visible = true

func _save_step_screenshot(step: int) -> void:
	var img = root.get_viewport().get_texture().get_image()
	if not img:
		print("[CaptureHViews] ERROR: Viewport texture empty at step %d" % step)
		return
		
	var path := ""
	match step:
		0: path = "res://screenshots/h1_main_menu_cinematic.png"
		1: path = "res://screenshots/h2_hackathon_demo_modal.png"
		2: path = "res://screenshots/h3_nasa_credits_modal.png"
		3: path = "res://screenshots/h4_controls_guide_modal.png"
		4: path = "res://screenshots/h5_settings_modal.png"
		5: path = "res://screenshots/h6_in_game_demo_hud.png"
		
	var err = img.save_png(path)
	if err == OK:
		print("[CaptureHViews] Saved: %s (%dx%d)" % [path, img.get_width(), img.get_height()])
	else:
		print("[CaptureHViews] ERROR: Failed to save %s (code %d)" % [path, err])
