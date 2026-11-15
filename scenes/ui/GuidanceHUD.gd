extends Control

## GuidanceHUD.gd - Universal Player Guidance & Non-Intrusive Notification HUD
## Provides persistent upper-left objective tracker, top-center auto-dismissing warnings,
## top-right completion toasts, and beginner-friendly help drawer.

signal help_requested()
signal objective_action_triggered(action_id: String)

@onready var panel_guidance: PanelContainer = $GuidancePanel
@onready var lbl_step_badge: Label = $GuidancePanel/Margin/VBox/HeaderHBox/StepBadge
@onready var lbl_title: Label = $GuidancePanel/Margin/VBox/HeaderHBox/Title
@onready var btn_help: Button = $GuidancePanel/Margin/VBox/HeaderHBox/BtnHelp
@onready var lbl_objective: Label = $GuidancePanel/Margin/VBox/LblObjective
@onready var lbl_how_to: Label = $GuidancePanel/Margin/VBox/LblHowTo
@onready var lbl_next_step: Label = $GuidancePanel/Margin/VBox/LblNextStep
@onready var progress_bar: ProgressBar = $GuidancePanel/Margin/VBox/ProgressBar

# Warning Banner (Top-Center)
@onready var banner_warning: PanelContainer = $WarningBanner
@onready var lbl_warning: Label = $WarningBanner/Margin/HBox/LblWarningText
@onready var icon_warning: Label = $WarningBanner/Margin/HBox/IconWarning

# Toast Banner (Top-Right)
@onready var banner_toast: PanelContainer = $ToastBanner
@onready var lbl_toast: Label = $ToastBanner/Margin/HBox/LblToastText

# Help Drawer (Safe Side Panel)
@onready var drawer_help: PanelContainer = $HelpDrawer
@onready var lbl_help_title: Label = $HelpDrawer/Margin/VBox/HeaderHBox/HelpTitle
@onready var lbl_help_content: Label = $HelpDrawer/Margin/VBox/HelpContent
@onready var btn_close_help: Button = $HelpDrawer/Margin/VBox/HeaderHBox/BtnCloseHelp

var _toast_timer: float = 0.0
var _warning_active: bool = false
var _current_help_text: String = ""

func _ready() -> void:
	if banner_warning:
		banner_warning.visible = false
	if banner_toast:
		banner_toast.visible = false
	if drawer_help:
		drawer_help.visible = false
		
	if btn_help:
		btn_help.pressed.connect(_on_help_pressed)
	if btn_close_help:
		btn_close_help.pressed.connect(func(): drawer_help.visible = false)

func _process(delta: float) -> void:
	if banner_toast and banner_toast.visible:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			var tw := create_tween()
			tw.tween_property(banner_toast, "modulate:a", 0.0, 0.4)
			tw.tween_callback(func():
				banner_toast.visible = false
				banner_toast.modulate.a = 1.0
			)

func set_guidance(step_text: String, objective: String, how_to: String, next_step: String, progress_pct: float = 0.0, help_details: String = "") -> void:
	if lbl_step_badge:
		lbl_step_badge.text = step_text
	if lbl_objective:
		lbl_objective.text = "CURRENT OBJECTIVE: %s" % objective
	if lbl_how_to:
		lbl_how_to.text = "HOW TO COMPLETE:\n%s" % how_to
	if lbl_next_step:
		lbl_next_step.text = "NEXT: %s" % next_step
	if progress_bar:
		progress_bar.value = progress_pct
	_current_help_text = help_details if help_details != "" else how_to

func show_warning(warning_text: String, duration_s: float = 0.0) -> void:
	if not banner_warning:
		return
	lbl_warning.text = warning_text
	banner_warning.visible = true
	_warning_active = true
	
	# Pulse warning banner
	var tw := create_tween()
	tw.set_loops(3)
	tw.tween_property(banner_warning, "modulate", Color(1.2, 0.6, 0.6, 1.0), 0.3)
	tw.tween_property(banner_warning, "modulate", Color.WHITE, 0.3)
	
	if duration_s > 0.0:
		get_tree().create_timer(duration_s).timeout.connect(func():
			if banner_warning and _warning_active:
				hide_warning()
		)

func hide_warning() -> void:
	if banner_warning:
		banner_warning.visible = false
		_warning_active = false

func show_completion_toast(message: String, duration_s: float = 2.8) -> void:
	if not banner_toast:
		return
	lbl_toast.text = "✓ %s" % message
	banner_toast.modulate.a = 1.0
	banner_toast.visible = true
	_toast_timer = duration_s

func toggle_help() -> void:
	if drawer_help:
		drawer_help.visible = not drawer_help.visible
		if drawer_help.visible and lbl_help_content:
			lbl_help_content.text = _current_help_text

func _on_help_pressed() -> void:
	toggle_help()
	help_requested.emit()
