class_name PanelCard
extends PanelContainer

## PanelCard.gd - Aerospace Dark Glass Container Card
## Supports header title, technical badge, accent indicator, and expandable details.

const MarsDeepUIRef = preload("res://scripts/ui/MarsDeepUI.gd")

@export var title: String = "SYSTEM PANEL" : set = set_title
@export var badge_text: String = "" : set = set_badge_text
@export var accent_color: Color = Color("#00E5FF") : set = set_accent_color
@export var accent_visible: bool = true : set = set_accent_visible
@export var is_expandable: bool = false : set = set_is_expandable
@export var is_expanded: bool = true : set = set_is_expanded
@export_enum("default", "glass", "cyan", "orange", "secondary") var card_variant: String = "default" : set = set_card_variant

@onready var lbl_title: Label = $Margin/VBox/HeaderHBox/Title
@onready var lbl_badge: Label = $Margin/VBox/HeaderHBox/Badge
@onready var accent_rect: ColorRect = $Margin/VBox/HeaderHBox/AccentStripe
@onready var btn_toggle: Button = $Margin/VBox/HeaderHBox/ToggleBtn
@onready var header_divider: HSeparator = $Margin/VBox/HeaderDivider
@onready var content_slot: VBoxContainer = $Margin/VBox/ContentSlot
@onready var expandable_slot: VBoxContainer = $Margin/VBox/ExpandableSlot

signal expansion_toggled(expanded: bool)

func _ready() -> void:
	_apply_styling()
	_update_header()
	if btn_toggle:
		btn_toggle.pressed.connect(_on_toggle_pressed)

func set_title(val: String) -> void:
	title = val
	if is_node_ready() and lbl_title:
		lbl_title.text = title

func set_badge_text(val: String) -> void:
	badge_text = val
	if is_node_ready() and lbl_badge:
		lbl_badge.text = badge_text
		lbl_badge.visible = not badge_text.is_empty()

func set_accent_color(col: Color) -> void:
	accent_color = col
	if is_node_ready() and accent_rect:
		accent_rect.color = accent_color

func set_accent_visible(vis: bool) -> void:
	accent_visible = vis
	if is_node_ready() and accent_rect:
		accent_rect.visible = accent_visible

func set_is_expandable(exp: bool) -> void:
	is_expandable = exp
	if is_node_ready() and btn_toggle:
		btn_toggle.visible = is_expandable
		if is_node_ready() and expandable_slot:
			expandable_slot.visible = is_expanded if is_expandable else false

func set_is_expanded(exp: bool) -> void:
	is_expanded = exp
	if is_node_ready() and expandable_slot:
		expandable_slot.visible = is_expanded
	if is_node_ready() and btn_toggle:
		btn_toggle.text = "[-]" if is_expanded else "[+]"

func set_card_variant(v: String) -> void:
	card_variant = v
	if is_node_ready():
		_apply_styling()

func _apply_styling() -> void:
	var sb := MarsDeepUIRef.create_glass_card(card_variant)
	add_theme_stylebox_override("panel", sb)

func _update_header() -> void:
	if lbl_title:
		lbl_title.text = title
	if lbl_badge:
		lbl_badge.text = badge_text
		lbl_badge.visible = not badge_text.is_empty()
	if accent_rect:
		accent_rect.color = accent_color
		accent_rect.visible = accent_visible
	if btn_toggle:
		btn_toggle.visible = is_expandable
		btn_toggle.text = "[-]" if is_expanded else "[+]"
	if expandable_slot:
		expandable_slot.visible = is_expanded and is_expandable

func _on_toggle_pressed() -> void:
	is_expanded = not is_expanded
	_update_header()
	expansion_toggled.emit(is_expanded)

func add_content(control: Control) -> void:
	if content_slot:
		content_slot.add_child(control)

func add_expandable_content(control: Control) -> void:
	if expandable_slot:
		expandable_slot.add_child(control)
