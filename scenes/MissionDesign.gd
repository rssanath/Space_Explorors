extends Control

## MissionDesign.gd - Beginner-Friendly 3D Spacecraft Designer Controller
## MARS DEEP • NASA Space Apps Challenge 2026 • Design. Launch. Explore.

const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")
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

# Top Navigation
@onready var btn_back: Button = $MarginContainer/VBoxContainer/Header/TopNav/BtnBack
@onready var btn_reset: Button = $MarginContainer/VBoxContainer/Header/TopNav/BtnReset
@onready var btn_eng_lab: Button = $MarginContainer/VBoxContainer/Header/TopNav/BtnEngLab
@onready var btn_continue: Button = $MarginContainer/VBoxContainer/Header/TopNav/BtnContinue

# Bottom Navigation
@onready var btn_bottom_back: Button = $MarginContainer/VBoxContainer/BottomBar/BtnBack
@onready var btn_bottom_reset: Button = $MarginContainer/VBoxContainer/BottomBar/BtnReset
@onready var btn_bottom_more: Button = $MarginContainer/VBoxContainer/BottomBar/BtnMoreDetails
@onready var btn_bottom_continue: Button = $MarginContainer/VBoxContainer/BottomBar/BtnContinue

# Left Panel Component Catalogue
@onready var catalogue_scroll: ScrollContainer = $MarginContainer/VBoxContainer/MainBody/LeftPanel/CatalogueScroll
@onready var catalogue_vbox: VBoxContainer = $MarginContainer/VBoxContainer/MainBody/LeftPanel/CatalogueScroll/CatalogueVBox

# Center Panel 3D Preview
@onready var preview_viewport_container: SubViewportContainer = $MarginContainer/VBoxContainer/MainBody/CenterPanel/SubViewportContainer
@onready var preview_viewport: SubViewport = $MarginContainer/VBoxContainer/MainBody/CenterPanel/SubViewportContainer/SubViewport
@onready var preview_3d = $MarginContainer/VBoxContainer/MainBody/CenterPanel/SubViewportContainer/SubViewport/SpacecraftPreview3D
@onready var btn_reset_cam: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/PreviewOverlay/BottomBar/BtnResetCam
@onready var btn_toggle_turntable: Button = $MarginContainer/VBoxContainer/MainBody/CenterPanel/PreviewOverlay/BottomBar/BtnToggleTurntable
@onready var lbl_turntable_status: Label = $MarginContainer/VBoxContainer/MainBody/CenterPanel/PreviewOverlay/BottomBar/LblTurntableStatus

# Right Panel - Four Simplified Indicators
@onready var lbl_weight_val: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/WeightCard/Margin/VBox/Readout/Val
@onready var lbl_weight_sub: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/WeightCard/Margin/VBox/Sub
@onready var bar_weight: ProgressBar = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/WeightCard/Margin/VBox/Bar

@onready var lbl_electricity_val: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/ElectricityCard/Margin/VBox/Readout/Val
@onready var lbl_electricity_sub: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/ElectricityCard/Margin/VBox/Sub
@onready var bar_electricity: ProgressBar = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/ElectricityCard/Margin/VBox/Bar

@onready var lbl_budget_val: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/BudgetCard/Margin/VBox/Readout/Val
@onready var lbl_budget_sub: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/BudgetCard/Margin/VBox/Sub
@onready var bar_budget: ProgressBar = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/BudgetCard/Margin/VBox/Bar

@onready var lbl_science_val: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/ScienceCard/Margin/VBox/Readout/Val
@onready var lbl_science_sub: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/ScienceCard/Margin/VBox/Sub
@onready var bar_science: ProgressBar = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/ScienceCard/Margin/VBox/Bar

# Status & Warnings Box
@onready var status_panel: PanelContainer = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/StatusCard
@onready var lbl_status_headline: Label = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/StatusCard/Margin/VBox/Headline
@onready var warnings_vbox: VBoxContainer = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/StatusCard/Margin/VBox/WarningsVBox

# Advanced Expandable Specs Panel
@onready var btn_toggle_advanced: Button = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/BtnToggleAdvanced
@onready var advanced_specs_panel: PanelContainer = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/AdvancedSpecsPanel
@onready var advanced_grid: GridContainer = $MarginContainer/VBoxContainer/MainBody/RightPanel/RightScroll/RightVBox/AdvancedSpecsPanel/Margin/VBox/Grid

# Reset Dialog
@onready var reset_dialog: ConfirmationDialog = $ResetConfirmDialog

var is_turntable_active: bool = true
var is_advanced_expanded: bool = false
var _card_map: Dictionary = {} # Maps item id -> { "btn": Button, "details": Control, "card": PanelContainer }

# BEGINNER FRIENDLY CATALOGUE MAPPING
const BEGINNER_SECTIONS := [
	{
		"section_num": "1",
		"title": "Spacecraft Body",
		"category_key": "structure",
		"icon": "🛰️",
		"items": [
			{
				"id": "BUS_LIGHT",
				"simple_name": "Light Body",
				"icon": "🛰️",
				"simple_desc": "A lightweight spacecraft structure that carries fewer instruments."
			},
			{
				"id": "BUS_HEAVY",
				"simple_name": "Heavy Body",
				"icon": "🛡️",
				"simple_desc": "A stronger structure that can carry more equipment."
			}
		]
	},
	{
		"section_num": "2",
		"title": "Power Source",
		"category_key": "power",
		"icon": "⚡",
		"items": [
			{
				"id": "PWR_SOLAR_ULTRAFLEX",
				"simple_name": "Solar Panels",
				"icon": "☀️",
				"simple_desc": "Generate electricity using sunlight."
			},
			{
				"id": "PWR_MMRTG",
				"simple_name": "Nuclear Battery",
				"icon": "🔋",
				"simple_desc": "Generate electricity using heat from radioactive material."
			}
		]
	},
	{
		"section_num": "3",
		"title": "Engine",
		"category_key": "propulsion",
		"icon": "🚀",
		"items": [
			{
				"id": "PROP_BIPROP",
				"simple_name": "Standard Engine",
				"icon": "🚀",
				"simple_desc": "A reliable rocket engine providing steady thrust for Mars orbit insertion."
			},
			{
				"id": "PROP_DUAL_MODE",
				"simple_name": "Powerful Engine",
				"icon": "🔥",
				"simple_desc": "A high-thrust rocket engine providing extra power for rapid orbital maneuvers."
			}
		]
	},
	{
		"section_num": "4",
		"title": "Communication",
		"category_key": "telecom",
		"icon": "📡",
		"items": [
			{
				"id": "COMMS_UHF_RELAY",
				"simple_name": "Basic Antenna",
				"icon": "📡",
				"simple_desc": "A compact antenna for relaying data to orbiters passing overhead."
			},
			{
				"id": "COMMS_HIGH_GAIN",
				"simple_name": "Long-Range Antenna",
				"icon": "🌐",
				"simple_desc": "A steerable dish antenna sending high-speed data directly back to Earth."
			}
		]
	},
	{
		"section_num": "5",
		"title": "Temperature Control",
		"category_key": "thermal",
		"icon": "❄️",
		"items": [
			{
				"id": "THM_LOUVERS",
				"simple_name": "Basic Cooling",
				"icon": "❄️",
				"simple_desc": "Mechanical louvers that vent excess heat to keep temperatures stable."
			},
			{
				"id": "THM_HEATPIPE_LOUVER",
				"simple_name": "Advanced Cooling",
				"icon": "🌡️",
				"simple_desc": "Liquid heat pipes and radiators to protect delicate electronics from extreme space temperatures."
			}
		]
	},
	{
		"section_num": "6",
		"title": "Science Tools",
		"category_key": "science",
		"icon": "🔬",
		"items": [
			{
				"id": "INST_MASTCAM_Z",
				"simple_name": "Camera",
				"icon": "📷",
				"simple_desc": "High-definition zoom cameras to photograph the Martian terrain and spot interesting rock targets."
			},
			{
				"id": "INST_SUPERCAM",
				"simple_name": "Rock Analyzer",
				"icon": "🔬",
				"simple_desc": "Shoots a harmless laser at distant rocks to examine their chemical composition from afar."
			},
			{
				"id": "INST_RIMFAX",
				"simple_name": "Underground Radar",
				"icon": "📡",
				"simple_desc": "Ground-penetrating radar to look up to 10 meters beneath the surface for buried rock layers and ice."
			},
			{
				"id": "INST_MEDA",
				"simple_name": "Weather Sensor",
				"icon": "🌪️",
				"simple_desc": "Monitors Martian weather, including atmospheric pressure, dust storms, winds, and temperature."
			},
			{
				"id": "INST_MOXIE",
				"simple_name": "Oxygen Experiment",
				"icon": "🧪",
				"simple_desc": "An experimental machine that breathes in Mars carbon dioxide and produces pure breathable oxygen."
			},
			{
				"id": "INST_PIXL",
				"simple_name": "Micro-Rock Chemist",
				"icon": "🔎",
				"simple_desc": "Micro-focus X-ray sensor that scans rock minerals down to sub-millimeter grains."
			},
			{
				"id": "INST_SHERLOC",
				"simple_name": "Biosignature Scanner",
				"icon": "✨",
				"simple_desc": "Ultraviolet sensor designed to hunt for ancient organic chemicals and life signatures."
			}
		]
	}
]

func _ready() -> void:
	print("[MissionDesign] Initializing Beginner-Friendly Spacecraft Designer...")
	_connect_events()
	_build_beginner_catalogue()
	_update_dashboard()
	
	if advanced_specs_panel:
		advanced_specs_panel.visible = false
	if preview_viewport_container:
		preview_viewport_container.gui_input.connect(_on_preview_gui_input)

func _connect_events() -> void:
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)
	if btn_reset:
		btn_reset.pressed.connect(_on_reset_pressed)
	if btn_eng_lab:
		btn_eng_lab.pressed.connect(_on_eng_lab_pressed)
	if btn_continue:
		btn_continue.pressed.connect(_on_continue_pressed)
		
	# Bottom Navigation
	if btn_bottom_back:
		btn_bottom_back.pressed.connect(_on_back_pressed)
	if btn_bottom_reset:
		btn_bottom_reset.pressed.connect(_on_reset_pressed)
	if btn_bottom_more:
		btn_bottom_more.pressed.connect(_on_toggle_advanced_pressed)
	if btn_bottom_continue:
		btn_bottom_continue.pressed.connect(_on_continue_pressed)
		
	if btn_reset_cam:
		btn_reset_cam.pressed.connect(_on_reset_cam_pressed)
	if btn_toggle_turntable:
		btn_toggle_turntable.pressed.connect(_on_toggle_turntable_pressed)
	if btn_toggle_advanced:
		btn_toggle_advanced.pressed.connect(_on_toggle_advanced_pressed)
		
	if reset_dialog:
		reset_dialog.confirmed.connect(_on_reset_confirmed)
		
	var gm = _get_gm()
	if gm:
		gm.spacecraft_config_changed.connect(_on_spacecraft_config_changed)

func _on_spacecraft_config_changed() -> void:
	_refresh_card_states()
	_update_dashboard()

func _on_preview_gui_input(event: InputEvent) -> void:
	if preview_3d and preview_3d.has_method("handle_subviewport_input"):
		preview_3d.handle_subviewport_input(event)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MissionBriefing.tscn")

func _on_reset_pressed() -> void:
	if reset_dialog:
		reset_dialog.popup_centered()

func _on_reset_confirmed() -> void:
	var gm = _get_gm()
	if gm:
		gm.reset_spacecraft_design()

func _on_eng_lab_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/EngineeringLab.tscn")

func _on_continue_pressed() -> void:
	var gm = _get_gm()
	if not gm:
		return
	var telemetry: Dictionary = gm.get_design_telemetry()
	var validation: Dictionary = telemetry.get("validation", {})
	if validation.get("is_valid", false):
		get_tree().change_scene_to_file("res://scenes/EngineeringLab.tscn")
	else:
		if status_panel:
			var tween := create_tween()
			tween.tween_property(status_panel, "modulate", Color(1.8, 0.4, 0.4, 1.0), 0.15)
			tween.tween_property(status_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)

func _on_reset_cam_pressed() -> void:
	if preview_3d and preview_3d.has_method("reset_camera"):
		preview_3d.reset_camera()

func _on_toggle_turntable_pressed() -> void:
	is_turntable_active = not is_turntable_active
	if preview_3d and preview_3d.has_method("set_auto_rotate"):
		preview_3d.set_auto_rotate(is_turntable_active)
	if lbl_turntable_status:
		lbl_turntable_status.text = "TURNTABLE: ON" if is_turntable_active else "TURNTABLE: OFF"

func _on_toggle_advanced_pressed() -> void:
	is_advanced_expanded = not is_advanced_expanded
	if advanced_specs_panel:
		advanced_specs_panel.visible = is_advanced_expanded
	if btn_toggle_advanced:
		btn_toggle_advanced.text = "[-] HIDE ADVANCED SPECS" if is_advanced_expanded else "[+] MORE DETAILS & SPECS"

# ==============================================================================
# BEGINNER CATALOGUE GENERATION
# ==============================================================================
func _build_beginner_catalogue() -> void:
	if not catalogue_vbox:
		return
		
	for child in catalogue_vbox.get_children():
		child.queue_free()
	_card_map.clear()
	
	for section in BEGINNER_SECTIONS:
		var sec_num: String = section.get("section_num", "")
		var sec_title: String = section.get("title", "")
		var sec_cat: String = section.get("category_key", "")
		var sec_icon: String = section.get("icon", "")
		
		# Section Header Bar
		var sec_header := PanelContainer.new()
		var sec_sb := StyleBoxFlat.new()
		sec_sb.bg_color = Color(0.090, 0.122, 0.133, 0.95)
		sec_sb.border_color = MarsDeepUIRef.COLOR_BORDER_SUBTLE
		sec_sb.set_border_width_all(1)
		sec_sb.border_width_left = 3
		sec_sb.border_color = MarsDeepUIRef.COLOR_CYAN
		sec_sb.set_corner_radius_all(3)
		sec_sb.content_margin_left = 10
		sec_sb.content_margin_top = 6
		sec_sb.content_margin_right = 10
		sec_sb.content_margin_bottom = 6
		sec_header.add_theme_stylebox_override("panel", sec_sb)
		
		var sec_lbl := Label.new()
		sec_lbl.text = "%s. %s" % [sec_num, sec_title.to_upper()]
		sec_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_CYAN)
		sec_lbl.add_theme_font_size_override("font_size", 12)
		sec_header.add_child(sec_lbl)
		catalogue_vbox.add_child(sec_header)
		
		# Cards in this section
		var items: Array = section.get("items", [])
		for item_meta in items:
			var card := _create_beginner_card(item_meta, sec_cat)
			catalogue_vbox.add_child(card)
			
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 4)
		catalogue_vbox.add_child(spacer)

func _create_beginner_card(item_meta: Dictionary, category_key: String) -> PanelContainer:
	var item_id: String = item_meta.get("id", "")
	var simple_name: String = item_meta.get("simple_name", "")
	var icon_char: String = item_meta.get("icon", "🛰️")
	var simple_desc: String = item_meta.get("simple_desc", "")
	
	# Fetch full technical JSON data
	var tech_data: Dictionary = {}
	var gm = _get_gm()
	if gm:
		if category_key == "science":
			tech_data = gm.get_instrument_by_id(item_id)
		else:
			tech_data = gm.get_component_by_id(item_id)
		
	var official_name: String = tech_data.get("name", simple_name)
	var mass: float = float(tech_data.get("mass_kg", 0.0))
	var cost: float = float(tech_data.get("cost_m", 0.0))
	var desc_full: String = tech_data.get("description", simple_desc)
	
	# Card Container
	var card := PanelContainer.new()
	var card_sb := MarsDeepUIRef.create_panel_style(MarsDeepUIRef.COLOR_PANEL, MarsDeepUIRef.COLOR_BORDER_SUBTLE, 1, 6, 10)
	card.add_theme_stylebox_override("panel", card_sb)
	card.set_meta("item_id", item_id)
	card.set_meta("category_key", category_key)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	
	# Top Header: Icon + Simple Name + Status Tag
	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 8)
	
	var icon_lbl := Label.new()
	icon_lbl.text = icon_char
	icon_lbl.add_theme_font_size_override("font_size", 16)
	top_hbox.add_child(icon_lbl)
	
	var name_lbl := Label.new()
	name_lbl.text = simple_name
	name_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_PRIMARY)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(name_lbl)
	
	var tag_lbl := Label.new()
	tag_lbl.text = "NOT EQUIPPED"
	tag_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_MUTED)
	tag_lbl.add_theme_font_size_override("font_size", 10)
	top_hbox.add_child(tag_lbl)
	vbox.add_child(top_hbox)
	
	# One-Sentence Beginner Explanation
	var desc_lbl := Label.new()
	desc_lbl.text = simple_desc
	desc_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_SECONDARY)
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	
	# Action Button Row (SELECT + MORE DETAILS)
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	
	var btn_select := Button.new()
	btn_select.text = "SELECT"
	btn_select.custom_minimum_size = Vector2(110, 28)
	btn_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_select.pressed.connect(_on_item_select_pressed.bind(item_id, category_key))
	btn_row.add_child(btn_select)
	
	var btn_details := Button.new()
	btn_details.text = "MORE DETAILS"
	btn_details.custom_minimum_size = Vector2(100, 28)
	btn_row.add_child(btn_details)
	vbox.add_child(btn_row)
	
	# Collapsible MORE DETAILS Container (hidden initially)
	var details_panel := PanelContainer.new()
	var dt_sb := StyleBoxFlat.new()
	dt_sb.bg_color = MarsDeepUIRef.COLOR_BG
	dt_sb.border_color = Color(0.18, 0.25, 0.28, 0.6)
	dt_sb.set_border_width_all(1)
	dt_sb.set_corner_radius_all(4)
	dt_sb.content_margin_left = 8
	dt_sb.content_margin_top = 8
	dt_sb.content_margin_right = 8
	dt_sb.content_margin_bottom = 8
	details_panel.add_theme_stylebox_override("panel", dt_sb)
	details_panel.visible = false
	
	var dt_vbox := VBoxContainer.new()
	dt_vbox.add_theme_constant_override("separation", 4)
	details_panel.add_child(dt_vbox)
	
	var tech_name_lbl := Label.new()
	tech_name_lbl.text = "NASA SPEC: %s" % official_name
	tech_name_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_CYAN)
	tech_name_lbl.add_theme_font_size_override("font_size", 10)
	tech_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dt_vbox.add_child(tech_name_lbl)
	
	var specs_lbl := Label.new()
	var pwr_str := ""
	if tech_data.has("power_output_w"):
		pwr_str = " | Power: +%.0f W" % float(tech_data["power_output_w"])
	elif tech_data.has("power_w"):
		pwr_str = " | Power: -%.0f W" % float(tech_data["power_w"])
	specs_lbl.text = "Mass: %.1f kg | Cost: $%.1fM%s" % [mass, cost, pwr_str]
	specs_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_ORANGE)
	specs_lbl.add_theme_font_size_override("font_size", 10)
	dt_vbox.add_child(specs_lbl)
	
	var purpose_lbl := Label.new()
	var purpose_text: String = tech_data.get("primary_discipline", "")
	if purpose_text.is_empty():
		purpose_text = desc_full
	else:
		purpose_text = "[%s] %s" % [purpose_text, desc_full]
	purpose_lbl.text = purpose_text
	purpose_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_SECONDARY)
	purpose_lbl.add_theme_font_size_override("font_size", 10)
	purpose_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dt_vbox.add_child(purpose_lbl)
	
	vbox.add_child(details_panel)
	
	# Wire up MORE DETAILS toggle
	btn_details.pressed.connect(func():
		details_panel.visible = not details_panel.visible
		btn_details.text = "LESS DETAILS" if details_panel.visible else "MORE DETAILS"
	)
	
	_card_map[item_id] = {
		"btn": btn_select,
		"tag": tag_lbl,
		"card": card,
		"category": category_key
	}
	
	_update_card_visual(item_id)
	return card

func _on_item_select_pressed(item_id: String, category_key: String) -> void:
	var gm = _get_gm()
	if not gm:
		return
	if category_key == "science":
		if gm.has_instrument(item_id):
			gm.remove_instrument(item_id)
		else:
			gm.add_instrument(item_id)
	else:
		gm.select_component(item_id)

func _refresh_card_states() -> void:
	for item_id in _card_map:
		_update_card_visual(item_id)

func _update_card_visual(item_id: String) -> void:
	if not _card_map.has(item_id):
		return
	var entry: Dictionary = _card_map[item_id]
	var btn: Button = entry["btn"]
	var tag_lbl: Label = entry["tag"]
	var card: PanelContainer = entry["card"]
	var cat: String = entry["category"]
	
	var is_active: bool = false
	var gm = _get_gm()
	if gm:
		if cat == "science":
			is_active = gm.has_instrument(item_id)
		else:
			is_active = gm.has_component(item_id)
		
	var sb: StyleBoxFlat = card.get_theme_stylebox("panel")
	if is_active:
		btn.text = "EQUIPPED  ✓"
		btn.modulate = Color(0.3, 1.0, 0.5, 1.0)
		tag_lbl.text = "MOUNTED" if cat == "science" else "INSTALLED"
		tag_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_GREEN)
		
		if sb:
			sb.border_color = MarsDeepUIRef.COLOR_CYAN
			sb.border_width_left = 3
			sb.bg_color = Color(0.08, 0.12, 0.15, 0.95)
	else:
		btn.text = "SELECT" if cat != "science" else "MOUNT TOOL"
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
		tag_lbl.text = "AVAILABLE"
		tag_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_MUTED)
		
		if sb:
			sb.border_color = MarsDeepUIRef.COLOR_BORDER_SUBTLE
			sb.border_width_left = 1
			sb.bg_color = MarsDeepUIRef.COLOR_PANEL

# ==============================================================================
# RIGHT PANEL: FOUR SIMPLIFIED INDICATORS & WARNINGS
# ==============================================================================
func _update_dashboard() -> void:
	var gm = _get_gm()
	if not gm:
		return
		
	var telemetry: Dictionary = gm.get_design_telemetry()
	var mass: Dictionary = telemetry.get("mass", {})
	var power: Dictionary = telemetry.get("power", {})
	var cost_m: float = telemetry.get("cost_m", 0.0)
	var payload: Dictionary = telemetry.get("payload", {})
	var validation: Dictionary = telemetry.get("validation", {})
	
	var dry_kg: float = mass.get("dry_mass_kg", 0.0)
	var wet_kg: float = mass.get("wet_mass_kg", 0.0)
	var bus_capacity: float = mass.get("max_payload_capacity_kg", 900.0)
	var payload_kg: float = mass.get("payload_mass_kg", 0.0)
	
	# 1. Spacecraft Weight
	if lbl_weight_val:
		lbl_weight_val.text = "%.1f kg" % dry_kg
	if lbl_weight_sub:
		lbl_weight_sub.text = "Wet: %.1f kg | Payload: %.1f kg / %.0f kg max" % [wet_kg, payload_kg, bus_capacity]
	if bar_weight:
		bar_weight.max_value = max(1.0, bus_capacity)
		bar_weight.value = payload_kg
		var fill_sb := StyleBoxFlat.new()
		fill_sb.set_corner_radius_all(2)
		if payload_kg > bus_capacity:
			fill_sb.bg_color = MarsDeepUIRef.COLOR_RED
		elif payload_kg > bus_capacity * 0.85:
			fill_sb.bg_color = MarsDeepUIRef.COLOR_YELLOW
		else:
			fill_sb.bg_color = MarsDeepUIRef.COLOR_CYAN
		bar_weight.add_theme_stylebox_override("fill", fill_sb)
		
	# 2. Available Electricity
	var gen_w: float = power.get("generated_w", 0.0)
	var con_w: float = power.get("consumed_w", 0.0)
	var bal_w: float = power.get("balance_w", 0.0)
	if lbl_electricity_val:
		if bal_w >= 0.0:
			lbl_electricity_val.text = "+%.1f W (Positive)" % bal_w
			lbl_electricity_val.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_GREEN)
		else:
			lbl_electricity_val.text = "%.1f W (DEFICIT)" % bal_w
			lbl_electricity_val.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_RED)
	if lbl_electricity_sub:
		lbl_electricity_sub.text = "Generating: %.0f W • Consuming: %.0f W" % [gen_w, con_w]
	if bar_electricity:
		bar_electricity.max_value = max(1.0, gen_w)
		bar_electricity.value = con_w
		var p_sb := StyleBoxFlat.new()
		p_sb.set_corner_radius_all(2)
		p_sb.bg_color = MarsDeepUIRef.COLOR_RED if bal_w < 0.0 else MarsDeepUIRef.COLOR_GREEN
		bar_electricity.add_theme_stylebox_override("fill", p_sb)

	# 3. Mission Budget
	const BUDGET_CAP: float = 450.0
	if lbl_budget_val:
		lbl_budget_val.text = "$%.1f M" % cost_m
		if cost_m > BUDGET_CAP:
			lbl_budget_val.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_RED)
		else:
			lbl_budget_val.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_GREEN)
	if lbl_budget_sub:
		var rem: float = BUDGET_CAP - cost_m
		lbl_budget_sub.text = "Budget Cap: $%.1fM | Remaining: $%.1fM" % [BUDGET_CAP, rem]
	if bar_budget:
		bar_budget.max_value = BUDGET_CAP
		bar_budget.value = cost_m
		var b_sb := StyleBoxFlat.new()
		b_sb.set_corner_radius_all(2)
		b_sb.bg_color = MarsDeepUIRef.COLOR_RED if cost_m > BUDGET_CAP else MarsDeepUIRef.COLOR_CYAN
		bar_budget.add_theme_stylebox_override("fill", b_sb)

	# 4. Science Capability
	var sc_pts: int = int(payload.get("total_science_value", 0))
	var tool_cnt: int = int(payload.get("count", 0))
	if lbl_science_val:
		lbl_science_val.text = "%d Science Pts" % sc_pts
	if lbl_science_sub:
		lbl_science_sub.text = "%d of 7 Tools Mounted • %.0f MB/sol" % [tool_cnt, float(payload.get("total_data_volume_mb_per_sol", 0.0))]
	if bar_science:
		bar_science.max_value = 5.0
		bar_science.value = float(tool_cnt)
		var sc_sb := StyleBoxFlat.new()
		sc_sb.set_corner_radius_all(2)
		sc_sb.bg_color = MarsDeepUIRef.COLOR_YELLOW if tool_cnt > 0 else MarsDeepUIRef.COLOR_RED
		bar_science.add_theme_stylebox_override("fill", sc_sb)

	# 5. Simple Warnings & Certification Status
	var is_valid: bool = validation.get("is_valid", false)
	var errors: Array = validation.get("errors", [])
	
	# Compute Simple Beginner Warnings with optional technical explanations
	var simple_warnings: Array[Dictionary] = []
	if payload_kg > bus_capacity or wet_kg > 1200.0:
		simple_warnings.append({
			"simple": "Your spacecraft is too heavy for the selected structure.",
			"tech": "Payload mass (%.1f kg) exceeds chassis capacity (%.0f kg) or wet mass exceeds limits." % [payload_kg, bus_capacity]
		})
	if bal_w < 0.0:
		simple_warnings.append({
			"simple": "Your spacecraft needs more electricity to operate all its equipment.",
			"tech": "Electrical deficit of %.1f W (generating %.0f W vs consuming %.0f W)." % [abs(bal_w), gen_w, con_w]
		})
	if cost_m > BUDGET_CAP:
		simple_warnings.append({
			"simple": "You have spent more money than your mission budget allows.",
			"tech": "Estimated mission cost ($%.1fM) exceeds budget ceiling ($%.1fM)." % [cost_m, BUDGET_CAP]
		})
	if tool_cnt == 0:
		simple_warnings.append({
			"simple": "Select at least one scientific instrument before continuing.",
			"tech": "Science payload bay is empty. Mission requires at least one scientific sensor."
		})
		
	# Missing core subsystems
	if gm:
		if not gm.has_component("BUS_LIGHT") and not gm.has_component("BUS_HEAVY"):
			simple_warnings.append({
				"simple": "Spacecraft body not selected.",
				"tech": "No chassis structure installed."
			})
		if not gm.has_component("PWR_SOLAR_ULTRAFLEX") and not gm.has_component("PWR_MMRTG"):
			simple_warnings.append({
				"simple": "Power source not selected.",
				"tech": "No electrical power system installed."
			})
		if not gm.has_component("PROP_BIPROP") and not gm.has_component("PROP_DUAL_MODE") and not gm.has_component("PROP_MONO_RCS"):
			simple_warnings.append({
				"simple": "Engine not selected.",
				"tech": "No main orbital maneuver engine installed."
			})
		if not gm.has_component("COMMS_UHF_RELAY") and not gm.has_component("COMMS_HIGH_GAIN"):
			simple_warnings.append({
				"simple": "Antenna not selected.",
				"tech": "No radio communications subsystem installed."
			})
		if not gm.has_component("THM_LOUVERS") and not gm.has_component("THM_HEATPIPE_LOUVER"):
			simple_warnings.append({
				"simple": "Temperature cooling not selected.",
				"tech": "No thermal control louvers or radiators installed."
			})
		
	if lbl_status_headline:
		if is_valid and simple_warnings.is_empty():
			lbl_status_headline.text = "✅ SPACECRAFT READY FOR LAUNCH"
			lbl_status_headline.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_GREEN)
		else:
			lbl_status_headline.text = "⚠️ FLIGHT CHECKS INCOMPLETE"
			lbl_status_headline.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_YELLOW)
			
	if warnings_vbox:
		for child in warnings_vbox.get_children():
			child.queue_free()
		if simple_warnings.is_empty() and is_valid:
			var ok_lbl := Label.new()
			ok_lbl.text = "All systems nominal and flight certified."
			ok_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_GREEN)
			ok_lbl.add_theme_font_size_override("font_size", 11)
			warnings_vbox.add_child(ok_lbl)
		else:
			for w_data in simple_warnings:
				var w_text: String = w_data["simple"]
				var t_text: String = w_data.get("tech", "")
				
				var w_lbl := Label.new()
				if not t_text.is_empty():
					w_lbl.text = "• %s\n  ↳ %s" % [w_text, t_text]
				else:
					w_lbl.text = "• " + w_text
				w_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_RED if "not" in w_text or "missing" in w_text or "exceeded" in w_text or "heavy" in w_text or "electricity" in w_text or "allows" in w_text else MarsDeepUIRef.COLOR_YELLOW)
				w_lbl.add_theme_font_size_override("font_size", 11)
				warnings_vbox.add_child(w_lbl)
				
	# 6. Advanced Specs Grid
	_update_advanced_specs(mass, power, cost_m, payload, telemetry)

func _update_advanced_specs(mass: Dictionary, power: Dictionary, cost_m: float, payload: Dictionary, telemetry: Dictionary) -> void:
	if not advanced_grid:
		return
	for child in advanced_grid.get_children():
		child.queue_free()
		
	var specs := [
		["Bus Structure Mass", "%.1f kg" % float(mass.get("bus_mass_kg", 0.0))],
		["Subsystems Dry Mass", "%.1f kg" % float(mass.get("subsystem_mass_kg", 0.0))],
		["Payload Mass", "%.1f kg" % float(mass.get("payload_mass_kg", 0.0))],
		["Propellant Wet Mass", "%.1f kg" % float(mass.get("wet_mass_kg", 0.0))],
		["Power Margin", "%.1f%%" % float(power.get("margin_percent", 0.0))],
		["Telemetry Output", "%.0f MB/sol" % float(payload.get("total_data_volume_mb_per_sol", 0.0))],
		["Science Value", "+%d pts" % int(payload.get("total_science_value", 0))],
		["Total Investment", "$%.1f M" % cost_m]
	]
	
	for pair in specs:
		var k_lbl := Label.new()
		k_lbl.text = pair[0] + ":"
		k_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_SECONDARY)
		k_lbl.add_theme_font_size_override("font_size", 10)
		advanced_grid.add_child(k_lbl)
		
		var v_lbl := Label.new()
		v_lbl.text = pair[1]
		v_lbl.add_theme_color_override("font_color", MarsDeepUIRef.COLOR_TEXT_PRIMARY)
		v_lbl.add_theme_font_size_override("font_size", 10)
		advanced_grid.add_child(v_lbl)
