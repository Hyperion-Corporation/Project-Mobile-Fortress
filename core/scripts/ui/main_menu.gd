extends Control
## Main menu — Wōkòu-era coastal theme (U1) over Slice-0 entry.

const SettingsDialogScript := preload("res://scripts/ui/settings_dialog.gd")

@onready var start_btn: Button = $Center/VBox/StartBtn
@onready var classic_btn: Button = $Center/VBox/ClassicBtn
@onready var quit_btn: Button = $Center/VBox/QuitBtn
@onready var blurb: Label = $Center/VBox/Blurb

const PAPER := Color(0.93, 0.86, 0.74, 1)
const DUSK := Color(0.18, 0.16, 0.18, 1)
const INDIGO := Color(0.12, 0.20, 0.30, 1)
const CINNABAR := Color(0.72, 0.20, 0.14, 1)

var _resume_btn: Button
var _last_run_label: Label


func _ready() -> void:
	_apply_coastal_theme()
	var has_cpp := ClassDB.class_exists("SimulationCore")
	blurb.text = (
		"1540s–1560s · East Asian coast\n"
		+ "Ming garrison + Portuguese support\n"
		+ "Defend land outposts and sea lanes against Wōkòu raids.\n\n"
		+ "Sim: %s · offline · dual-front"
		% ("C++ SimulationCore" if has_cpp else "GDScript fallback (classic only)")
	)
	start_btn.pressed.connect(func():
		GameSession.resume_snapshot_on_next_battle = false
		get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")
	)
	classic_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://main.tscn"))
	quit_btn.pressed.connect(func(): get_tree().quit())
	if not has_cpp:
		start_btn.disabled = true
		start_btn.text = "Defend the Coast (needs GDExtension)"
	else:
		start_btn.text = "Defend the Coast"
	classic_btn.text = "Classic prototype"
	_ensure_resume_and_history_ui(has_cpp)
	_ensure_version_label()
	_refresh_last_run()


func _apply_coastal_theme() -> void:
	var bg: ColorRect = get_node_or_null("Bg")
	if bg:
		bg.color = PAPER
	if get_node_or_null("Horizon") == null:
		var horizon := ColorRect.new()
		horizon.name = "Horizon"
		horizon.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		horizon.offset_top = -220
		horizon.color = INDIGO
		horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(horizon)
		move_child(horizon, 1)
	if get_node_or_null("InkBand") == null:
		var band := ColorRect.new()
		band.name = "InkBand"
		band.set_anchors_preset(Control.PRESET_TOP_WIDE)
		band.offset_bottom = 8
		band.color = CINNABAR
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(band)
		move_child(band, 2)
	var title: Label = get_node_or_null("Center/VBox/Title")
	if title:
		title.add_theme_font_size_override("font_size", 42)
		title.add_theme_color_override("font_color", DUSK)
	var subtitle: Label = get_node_or_null("Center/VBox/Subtitle")
	if subtitle:
		subtitle.text = "倭寇 Dual-Front Defense"
		subtitle.add_theme_color_override("font_color", CINNABAR)


func _ensure_resume_and_history_ui(has_cpp: bool) -> void:
	var vbox: VBoxContainer = $Center/VBox
	if vbox.get_node_or_null("ResumeBtn") == null:
		_resume_btn = Button.new()
		_resume_btn.name = "ResumeBtn"
		_resume_btn.custom_minimum_size = Vector2(280, 36)
		vbox.add_child(_resume_btn)
		vbox.move_child(_resume_btn, start_btn.get_index() + 1)
	else:
		_resume_btn = vbox.get_node("ResumeBtn")
	_resume_btn.text = "Resume last snapshot"
	_resume_btn.visible = has_cpp and OfflinePersistence.has_snapshot()
	_resume_btn.disabled = not _resume_btn.visible
	_resume_btn.pressed.connect(func():
		GameSession.resume_snapshot_on_next_battle = true
		get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")
	)

	if vbox.get_node_or_null("SettingsBtn") == null:
		var settings_btn := Button.new()
		settings_btn.name = "SettingsBtn"
		settings_btn.custom_minimum_size = Vector2(280, 36)
		settings_btn.text = "Settings · 設置"
		settings_btn.pressed.connect(_open_settings)
		vbox.add_child(settings_btn)
		vbox.move_child(settings_btn, quit_btn.get_index())

	if vbox.get_node_or_null("LastRunLabel") == null:
		_last_run_label = Label.new()
		_last_run_label.name = "LastRunLabel"
		_last_run_label.custom_minimum_size = Vector2(480, 0)
		_last_run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_last_run_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_last_run_label.add_theme_color_override("font_color", Color(0.2, 0.25, 0.3, 1))
		_last_run_label.add_theme_font_size_override("font_size", 13)
		vbox.add_child(_last_run_label)
		vbox.move_child(_last_run_label, classic_btn.get_index())
	else:
		_last_run_label = vbox.get_node("LastRunLabel")


func _ensure_version_label() -> void:
	if get_node_or_null("VersionLabel") != null:
		return
	var version := Label.new()
	version.name = "VersionLabel"
	version.text = "Slice-0 · DT8"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	version.offset_top = -28
	version.offset_bottom = -8
	version.add_theme_color_override("font_color", Color(0.35, 0.32, 0.30, 1))
	version.add_theme_font_size_override("font_size", 12)
	version.mouse_filter = Control.MOUSE_FILTER_STOP
	version.gui_input.connect(_on_version_gui_input)
	add_child(version)


func _on_version_gui_input(event: InputEvent) -> void:
	var tapped := false
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		tapped = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		tapped = (event as InputEventScreenTouch).pressed
	if tapped:
		var session := get_tree().root.get_node_or_null("GameSession")
		if session:
			session.register_dev_tap()


func _open_settings() -> void:
	if get_node_or_null("SettingsDialog") != null:
		return
	var dlg := SettingsDialogScript.new()
	dlg.name = "SettingsDialog"
	add_child(dlg)


func _refresh_last_run() -> void:
	if _last_run_label == null:
		return
	var result: Dictionary = OfflinePersistence.read_results()
	var history: Array = OfflinePersistence.read_history()
	var summary := OfflinePersistence.format_results_summary(result)
	if history.size() > 0:
		summary += "\n(%d run(s) in offline history)" % history.size()
	_last_run_label.text = summary
