extends Node

## GameManager.gd - Central Autoload Singleton for MARS DEEP
## Manages campaign progression, mission parameters, spacecraft configuration, and scene transitions.

signal mission_selected(level_id: String)
signal level_unlocked(level_id: String)
signal task_validated(task_id: String, is_valid: bool, feedback: String)
signal campaign_progress_updated()
signal spacecraft_config_changed()
signal launch_vehicle_selected(lv_id: String)
signal mission_route_selected(route_id: String)

const MISSIONS_DATA_PATH: String = "res://data/missions.json"
const COMPONENTS_DATA_PATH: String = "res://data/components.json"
const INSTRUMENTS_DATA_PATH: String = "res://data/instruments.json"
const LAUNCH_OPTIONS_DATA_PATH: String = "res://data/launch_options.json"
const SAVE_PATH: String = "user://mars_deep_save.json"

const MissionConfigRef = preload("res://scripts/MissionConfig.gd")
const MissionProgressRef = preload("res://scripts/MissionProgress.gd")
const MissionValidatorRef = preload("res://scripts/MissionValidator.gd")
const ResourceCalculatorRef = preload("res://scripts/ResourceCalculator.gd")
const MissionSimulatorRef = preload("res://scripts/MissionSimulator.gd")
const MissionScoringRef = preload("res://scripts/MissionScoring.gd")

var campaign_data: Dictionary = {}
var components_data: Dictionary = {}
var instruments_data: Dictionary = {}
var launch_options_data: Dictionary = {}

var progress: RefCounted
var current_level_id: String = "LVL_01"

# Spacecraft Design & Engineering State
var selected_archetype: String = "Surface Rover"
var selected_components: Array[String] = []
var selected_instruments: Array[String] = []
var selected_launch_vehicle_id: String = "LV_ATLAS_V_541"
var selected_mission_route: String = "ROUTE_B_HOHMANN"
var calculation_attempts: Array[Dictionary] = []

# Stage H: Demo Mode & Universal Settings
var is_demo_mode: bool = false
var global_canvas: CanvasLayer = null
var global_pause_menu: Control = null
var global_demo_hud: CanvasLayer = null
var game_settings: Dictionary = {
	"master_volume": 85.0,
	"music_volume": 80.0,
	"sfx_volume": 90.0,
	"mouse_sensitivity": 1.0,
	"fullscreen": false,
	"vsync": true
}

const MISSION_ROUTES: Dictionary = {
	"ROUTE_A_FAST": {
		"id": "ROUTE_A_FAST",
		"name": "Fast Transit Trajectory",
		"subtitle": "Direct / High Energy Insertion",
		"duration_days": 180,
		"delta_v_km_s": 4.8,
		"propellant_demand": "+40% Reserve",
		"advantage": "Faster arrival (-80 days) significantly reduces cosmic radiation dose for sensitive science packages and astronauts.",
		"tradeoff": "Requires substantially larger Delta-V budget and heavier propellant burn during Mars Orbit Insertion (MOI).",
		"recommended_for": "Time-critical science & high-reliability priority payloads."
	},
	"ROUTE_B_HOHMANN": {
		"id": "ROUTE_B_HOHMANN",
		"name": "Hohmann Transfer Trajectory",
		"subtitle": "Fuel-Saving / Minimum Energy Orbit",
		"duration_days": 260,
		"delta_v_km_s": 3.6,
		"propellant_demand": "Nominal (Minimum Energy)",
		"advantage": "Maximizes payload delivery capacity per kilogram of rocket propellant by following classic Keplerian tangent elliptical orbit.",
		"tradeoff": "Longer deep space cruise duration (~8.5 months) requiring sustained thermal and battery lifecycle endurance.",
		"recommended_for": "Heavy landers, surface rovers, and multi-instrument laboratories."
	}
}

func _ready() -> void:
	print("[GameManager] Initializing MARS DEEP System Architecture...")
	progress = MissionProgressRef.new()
	load_all_data()
	call_deferred("_setup_global_overlays")
	print("[GameManager] Architecture online. Campaign levels: %d, Total tasks: %d" % [
		campaign_data.get("levels", []).size(),
		progress.get_total_tasks_count()
	])

func _setup_global_overlays() -> void:
	# 1. Global Pause Menu inside CanvasLayer (layer 100)
	if global_canvas == null:
		global_canvas = CanvasLayer.new()
		global_canvas.name = "GlobalOverlayLayer"
		global_canvas.layer = 100
		global_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(global_canvas)
		
		var pm_scene = load("res://scenes/ui/PauseMenu.tscn")
		if pm_scene:
			global_pause_menu = pm_scene.instantiate()
			global_canvas.add_child(global_pause_menu)
			
	# 2. Global Demo Mode HUD (layer 120)
	if global_demo_hud == null:
		var demo_scene = load("res://scenes/ui/DemoModeHUD.tscn")
		if demo_scene:
			global_demo_hud = demo_scene.instantiate()
			add_child(global_demo_hud)
			global_demo_hud.visible = is_demo_mode

func load_all_data() -> void:
	campaign_data = _load_json_file(MISSIONS_DATA_PATH)
	components_data = _load_json_file(COMPONENTS_DATA_PATH)
	instruments_data = _load_json_file(INSTRUMENTS_DATA_PATH)
	launch_options_data = _load_json_file(LAUNCH_OPTIONS_DATA_PATH)
	
	var levels: Array = campaign_data.get("levels", [])
	progress.initialize_from_data(levels)

func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[GameManager] File not found: " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[GameManager] Could not open file for reading: " + path)
		return {}
	var text := file.get_as_text()
	var json := JSON.new()
	var parse_result := json.parse(text)
	if parse_result != OK:
		push_error("[GameManager] JSON parse error in %s: %s at line %d" % [path, json.get_error_message(), json.get_error_line()])
		return {}
	return json.data if typeof(json.data) == TYPE_DICTIONARY else {}

# MISSION & CAMPAIGN MANAGEMENT
func select_level(level_id: String) -> bool:
	if not progress.is_level_unlocked(level_id):
		push_warning("[GameManager] Level locked: " + level_id)
		return false
	current_level_id = level_id
	mission_selected.emit(level_id)
	return true

func get_current_level() -> Dictionary:
	return progress.get_level(current_level_id)

func submit_task_calculation(level_id: String, task_id: String, player_val: Variant) -> Dictionary:
	var task: Dictionary = progress.get_task(task_id)
	if task.is_empty():
		return {"is_valid": false, "message": "Task not found."}
		
	var validation_result: Dictionary = MissionValidatorRef.validate_task_submission(task, player_val)
	var is_valid: bool = validation_result.get("is_valid", false)
	var feedback: String = validation_result.get("message", "")
	
	calculation_attempts.append({
		"task_id": task_id,
		"level_id": level_id,
		"submitted_value": player_val,
		"is_valid": is_valid,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	if is_valid:
		progress.complete_task(level_id, task_id, player_val)
		campaign_progress_updated.emit()
		save_game()
		
	task_validated.emit(task_id, is_valid, feedback)
	return validation_result

func is_level_unlocked(level_id: String) -> bool:
	return progress.is_level_unlocked(level_id)

func is_task_completed(task_id: String) -> bool:
	return progress.is_task_completed(task_id)

func get_total_progress_ratio() -> float:
	var total: int = progress.get_total_tasks_count()
	if total == 0:
		return 0.0
	return float(progress.get_completed_tasks_count()) / float(total)

# SAVE / LOAD PERSISTENCE
func save_game() -> void:
	var save_dict: Dictionary = {
		"version": "1.0.0",
		"current_level_id": current_level_id,
		"selected_archetype": selected_archetype,
		"selected_components": selected_components,
		"selected_instruments": selected_instruments,
		"selected_launch_vehicle_id": selected_launch_vehicle_id,
		"selected_mission_route": selected_mission_route,
		"progress": progress.serialize() if progress else {},
		"saved_at": Time.get_datetime_string_from_system()
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict, "\t"))
		file.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = json.data
	current_level_id = data.get("current_level_id", "LVL_01")
	selected_archetype = data.get("selected_archetype", "Surface Rover")
	selected_launch_vehicle_id = data.get("selected_launch_vehicle_id", "LV_ATLAS_V_541")
	selected_mission_route = data.get("selected_mission_route", "ROUTE_B_HOHMANN")
	
	if data.has("selected_components"):
		selected_components.clear()
		for c in data["selected_components"]:
			selected_components.append(str(c))
			
	if data.has("selected_instruments"):
		selected_instruments.clear()
		for inst in data["selected_instruments"]:
			selected_instruments.append(str(inst))
			
	if data.has("progress"):
		progress.deserialize(data["progress"])
		
	campaign_progress_updated.emit()
	spacecraft_config_changed.emit()
	return true

func reset_for_replay(keep_unlocked: bool = false) -> void:
	calculation_attempts.clear()
	if progress:
		progress.reset_for_replay(keep_unlocked)
	campaign_progress_updated.emit()
	save_game()

func has_saved_game() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		return true
	if progress != null:
		return progress.get_completed_tasks_count() > 0 or current_level_id != "LVL_01"
	return false

func start_new_mission() -> void:
	is_demo_mode = false
	reset_for_replay(false)
	current_level_id = "LVL_01"
	get_tree().call_deferred("change_scene_to_file", "res://scenes/MissionBriefing.tscn")

func continue_mission() -> void:
	is_demo_mode = false
	load_game()
	match current_level_id:
		"LVL_01":
			if progress and progress.is_level_completed("LVL_01"):
				get_tree().change_scene_to_file("res://scenes/EngineeringLab.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/MissionDesign.tscn")
		"LVL_02":
			get_tree().change_scene_to_file("res://scenes/EngineeringLab.tscn")
		"LVL_03":
			get_tree().change_scene_to_file("res://scenes/LaunchPreparation.tscn")
		"LVL_04":
			get_tree().change_scene_to_file("res://scenes/MissionSimulation.tscn")
		"LVL_05":
			if progress and progress.is_level_completed("LVL_05"):
				get_tree().change_scene_to_file("res://scenes/MissionReport.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/MarsExploration.tscn")
		_:
			get_tree().change_scene_to_file("res://scenes/MissionDesign.tscn")

func activate_demo_mode() -> void:
	is_demo_mode = true
	if global_demo_hud:
		global_demo_hud.visible = true
	print("[GameManager] HACKATHON DEMO MODE ACTIVATED. All stages unlocked for presentation.")
	for lvl in ["LVL_01", "LVL_02", "LVL_03", "LVL_04", "LVL_05"]:
		if progress:
			progress.certify_level(lvl)

func deactivate_demo_mode() -> void:
	is_demo_mode = false
	if global_demo_hud:
		global_demo_hud.visible = false
	print("[GameManager] Demo mode deactivated. Restoring normal campaign save.")
	load_game()

# SPACECRAFT DESIGN MANAGEMENT
func select_component(comp_id: String) -> void:
	var comp: Dictionary = get_component_by_id(comp_id)
	var cat: String = comp.get("category", "")
	
	# Enforce single-selection per hardware subsystem category
	if cat in ["structure", "power", "propulsion", "telecom", "thermal"]:
		var to_remove: Array[String] = []
		for cid in selected_components:
			var existing_comp: Dictionary = get_component_by_id(cid)
			if existing_comp.get("category", "") == cat:
				to_remove.append(cid)
		for r in to_remove:
			selected_components.erase(r)
			
	if not selected_components.has(comp_id):
		selected_components.append(comp_id)
		
	spacecraft_config_changed.emit()
	save_game()

func deselect_component(comp_id: String) -> void:
	if selected_components.has(comp_id):
		selected_components.erase(comp_id)
		spacecraft_config_changed.emit()
		save_game()

func toggle_component(comp_id: String) -> void:
	if selected_components.has(comp_id):
		deselect_component(comp_id)
	else:
		select_component(comp_id)

func has_component(comp_id: String) -> bool:
	return selected_components.has(comp_id)

func add_instrument(inst_id: String) -> bool:
	if selected_instruments.has(inst_id):
		return false
	selected_instruments.append(inst_id)
	spacecraft_config_changed.emit()
	save_game()
	return true

func remove_instrument(inst_id: String) -> bool:
	if selected_instruments.has(inst_id):
		selected_instruments.erase(inst_id)
		spacecraft_config_changed.emit()
		save_game()
		return true
	return false

func has_instrument(inst_id: String) -> bool:
	return selected_instruments.has(inst_id)

func reset_spacecraft_design() -> void:
	selected_components.clear()
	selected_instruments.clear()
	spacecraft_config_changed.emit()
	save_game()

func get_component_by_id(comp_id: String) -> Dictionary:
	var cats: Dictionary = components_data.get("categories", {})
	for c_name in cats:
		for item in cats[c_name]:
			if item.get("id", "") == comp_id:
				return item
	return {}

func get_instrument_by_id(inst_id: String) -> Dictionary:
	var insts: Array = instruments_data.get("instruments", [])
	for item in insts:
		if item.get("id", "") == inst_id:
			return item
	return {}

func get_design_telemetry() -> Dictionary:
	var mass_summary = ResourceCalculatorRef.calculate_design_mass(selected_components, selected_instruments, components_data, instruments_data)
	var power_summary = ResourceCalculatorRef.calculate_design_power(selected_components, selected_instruments, components_data, instruments_data)
	var total_cost = ResourceCalculatorRef.calculate_design_cost(selected_components, selected_instruments, components_data, instruments_data)
	var payload_summary = ResourceCalculatorRef.calculate_design_payload_summary(selected_instruments, instruments_data)
	var validation = MissionValidatorRef.validate_spacecraft_design(selected_components, selected_instruments, components_data, instruments_data)
	
	return {
		"mass": mass_summary,
		"power": power_summary,
		"cost_m": total_cost,
		"payload": payload_summary,
		"validation": validation
	}

# LAUNCH VEHICLE & TRAJECTORY MANAGEMENT
func select_launch_vehicle(lv_id: String) -> bool:
	var lvs: Array = launch_options_data.get("launch_vehicles", [])
	var found := false
	for lv in lvs:
		if lv.get("id", "") == lv_id:
			found = true
			break
	if not found and not lvs.is_empty():
		return false
	selected_launch_vehicle_id = lv_id
	launch_vehicle_selected.emit(lv_id)
	save_game()
	return true

func get_selected_launch_vehicle() -> Dictionary:
	return get_launch_vehicle_by_id(selected_launch_vehicle_id)

func get_launch_vehicle_by_id(lv_id: String) -> Dictionary:
	var lvs: Array = launch_options_data.get("launch_vehicles", [])
	for lv in lvs:
		if lv.get("id", "") == lv_id:
			return lv
	return {}

func get_all_launch_vehicles() -> Array:
	return launch_options_data.get("launch_vehicles", [])

func select_mission_route(route_id: String) -> bool:
	if not MISSION_ROUTES.has(route_id):
		return false
	selected_mission_route = route_id
	mission_route_selected.emit(route_id)
	save_game()
	return true

func get_selected_mission_route() -> Dictionary:
	return MISSION_ROUTES.get(selected_mission_route, MISSION_ROUTES["ROUTE_B_HOHMANN"])

func get_all_mission_routes() -> Dictionary:
	return MISSION_ROUTES

# SCENE NAVIGATION
func start_mission() -> void:
	get_tree().change_scene_to_file("res://scenes/MissionBriefing.tscn")

func return_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# STAGE H: UNIVERSAL SETTINGS
func set_setting(key: String, value: Variant) -> void:
	game_settings[key] = value
	apply_settings()

func get_setting(key: String, default_value: Variant = null) -> Variant:
	return game_settings.get(key, default_value)

func apply_settings() -> void:
	if game_settings.has("master_volume"):
		var mv: float = float(game_settings["master_volume"])
		var bus_idx := AudioServer.get_bus_index("Master")
		if bus_idx >= 0:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(mv / 100.0) if mv > 0.0 else -80.0)
	if game_settings.has("fullscreen"):
		var fs: bool = bool(game_settings["fullscreen"])
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fs else DisplayServer.WINDOW_MODE_WINDOWED)
