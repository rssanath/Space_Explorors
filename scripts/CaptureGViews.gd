extends SceneTree

## CaptureGViews.gd - Captures 7 High-Resolution Screenshots for Stage G
## Two-phase state machine: Phase 0 sets tab/camera state -> waits 12 frames -> Phase 1 captures PNG -> advances step.

var frames_waited := 0
var capture_step := 0
var state_setup_done := false
var report_scene: Node = null
var mc3d: Node3D = null

func _init() -> void:
	print("[CaptureGViews] Initializing Stage G 7-shot visual verification capture...")
	var scn = load("res://scenes/MissionReport.tscn")
	if scn:
		# Ensure all campaign levels certified for final debrief capture
		if Engine.has_singleton("GameManager"):
			var gm = Engine.get_singleton("GameManager")
			if gm and gm.progress:
				for lvl in ["LVL_01", "LVL_02", "LVL_03", "LVL_04", "LVL_05"]:
					gm.progress.certify_level(lvl)
					
		report_scene = scn.instantiate()
		root.add_child(report_scene)
		DirAccess.make_dir_absolute("res://screenshots")
	else:
		print("[CaptureGViews] ERROR: Could not load MissionReport.tscn")
		quit(1)

func _process(_delta: float) -> bool:
	if mc3d == null:
		if report_scene.mission_control_3d != null:
			mc3d = report_scene.mission_control_3d
			# Certify full campaign on GameManager Autoload!
			var gm = report_scene._get_gm()
			if gm and gm.progress:
				for lvl in ["LVL_01", "LVL_02", "LVL_03", "LVL_04", "LVL_05"]:
					gm.progress.certify_level(lvl)
				report_scene._populate_all_data()
		if mc3d == null:
			return false
			
	if not state_setup_done:
		_setup_step_state(capture_step)
		state_setup_done = true
		frames_waited = 0
		return false
		
	frames_waited += 1
	if frames_waited < 12:
		return false
		
	# Frame is settled and rendered
	_save_step_screenshot(capture_step)
	capture_step += 1
	state_setup_done = false
	frames_waited = 0
	
	if capture_step >= 7:
		print("[CaptureGViews] ALL 7 STAGE G SCREENSHOTS CAPTURED!")
		quit(0)
		return true
	return false

func _setup_step_state(step: int) -> void:
	match step:
		0:
			# G1: Final Mars Cinematic View
			print("[CaptureGViews] Setup G1: Final Mars Cinematic...")
			report_scene._switch_tab(6) # Tab 6: Cinematic
			mc3d.set_camera_view(mc3d.ViewMode.MARS_CINEMATIC)
			report_scene._broadcast_radio("CAPCOM (HOUSTON)", "MARS DEEP: DESIGN. LAUNCH. EXPLORE. Outstanding achievement, Commander. Mission Accomplished.")
			
		1:
			# G2: 3D Mission Control Debrief Room
			print("[CaptureGViews] Setup G2: Mission Control Overview...")
			report_scene._switch_tab(0) # Tab 0: Overview
			mc3d.set_camera_view(mc3d.ViewMode.OVERVIEW)
			report_scene._broadcast_radio("NASA ADMINISTRATOR", "Welcome to Mission Control, Commander. Review your comprehensive flight performance and certification.")
			
		2:
			# G3: Complete 16-Stage Mission Flight Timeline
			print("[CaptureGViews] Setup G3: Complete Mission Timeline...")
			report_scene._switch_tab(1) # Tab 1: Timeline
			mc3d.set_camera_view(mc3d.ViewMode.VIDEO_WALL)
			report_scene._broadcast_radio("FLIGHT DYNAMICS", "16-stage flight timeline logged from Cape Canaveral liftoff to Jezero Crater touchdown.")
			
		3:
			# G4: Science Discovery Gallery
			print("[CaptureGViews] Setup G4: Science Discovery Gallery...")
			report_scene._switch_tab(3) # Tab 3: Science
			report_scene._select_science_discovery(0) # Jezero Delta Clays
			mc3d.set_camera_view(mc3d.ViewMode.VIDEO_WALL)
			report_scene._broadcast_radio("CHIEF SCIENTIST", "Astrobiology discovery gallery: Sample caches cross-referenced against real-world NASA Mars mission telemetry.")
			
		4:
			# G5: Spacecraft Specs & Performance Analysis Report
			print("[CaptureGViews] Setup G5: Spacecraft Specs & Performance...")
			report_scene._switch_tab(4) # Tab 4: Specs
			mc3d.set_camera_view(mc3d.ViewMode.CONSOLE_OPERATOR)
			report_scene._broadcast_radio("SYSTEMS INTEGRATOR", "Spacecraft technical telemetry and subsystem telemetry verified against design baseline.")
			
		5:
			# G6: Achievement Gallery (10 Badges)
			print("[CaptureGViews] Setup G6: Achievement Gallery...")
			report_scene._switch_tab(5) # Tab 5: Achievements
			mc3d.set_camera_view(mc3d.ViewMode.OVERVIEW)
			report_scene._broadcast_radio("NASA AWARDS BOARD", "Honorary achievement medals awarded based on verified mission flight milestones.")
			
		6:
			# G7: Final NASA Certification Screen (Overview Tab with Camera on Video Wall)
			print("[CaptureGViews] Setup G7: Final NASA Certification Screen...")
			report_scene._switch_tab(0) # Tab 0: Overview
			mc3d.set_camera_view(mc3d.ViewMode.VIDEO_WALL)
			report_scene._broadcast_radio("NASA ADMINISTRATOR", "FINAL CERTIFICATION CONFERRED: NASA Exceptional Engineering Achievement Medal.")

func _save_step_screenshot(step: int) -> void:
	var paths = [
		"res://screenshots/g1_final_mars_cinematic.png",
		"res://screenshots/g2_mission_control_debrief.png",
		"res://screenshots/g3_complete_mission_timeline.png",
		"res://screenshots/g4_science_discovery_gallery.png",
		"res://screenshots/g5_performance_report.png",
		"res://screenshots/g6_achievement_gallery.png",
		"res://screenshots/g7_final_certification_screen.png"
	]
	if step >= 0 and step < paths.size():
		var path: String = paths[step]
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(path)
			print("[CaptureGViews] Successfully Saved Step %d: %s" % [step + 1, path])
