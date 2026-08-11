extends Control
## Main menu — modular battle (default) or classic main.gd prototype.

@onready var start_btn: Button = $Center/VBox/StartBtn
@onready var classic_btn: Button = $Center/VBox/ClassicBtn
@onready var quit_btn: Button = $Center/VBox/QuitBtn
@onready var blurb: Label = $Center/VBox/Blurb

var _resume_btn: Button
var _last_run_label: Label


func _ready() -> void:
	var has_cpp := ClassDB.class_exists("SimulationCore")
	blurb.text = (
		"Mobile Fortress — Slice-0\n"
		+ "Ming + Portuguese · dual-front · offline\n"
		+ "Sim: %s\n\n" % ("C++ SimulationCore" if has_cpp else "GDScript fallback (classic only)")
		+ "Modular battle uses scene graph + GDExtension.\n"
		+ "Classic keeps the single-file canvas prototype."
	)
	start_btn.pressed.connect(func():
		GameSession.resume_snapshot_on_next_battle = false
		get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")
	)
	classic_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://main.tscn"))
	quit_btn.pressed.connect(func(): get_tree().quit())
	if not has_cpp:
		start_btn.disabled = true
		start_btn.text = "Modular Battle (needs GDExtension)"
	_ensure_resume_and_history_ui(has_cpp)
	_refresh_last_run()


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


func _refresh_last_run() -> void:
	if _last_run_label == null:
		return
	var result: Dictionary = OfflinePersistence.read_results()
	var history: Array = OfflinePersistence.read_history()
	var summary := OfflinePersistence.format_results_summary(result)
	if history.size() > 0:
		summary += "\n(%d run(s) in offline history)" % history.size()
	_last_run_label.text = summary
