extends Control
## Main menu — modular battle (default) or classic main.gd prototype.

@onready var start_btn: Button = $Center/VBox/StartBtn
@onready var classic_btn: Button = $Center/VBox/ClassicBtn
@onready var quit_btn: Button = $Center/VBox/QuitBtn
@onready var blurb: Label = $Center/VBox/Blurb


func _ready() -> void:
	var has_cpp := ClassDB.class_exists("SimulationCore")
	blurb.text = (
		"Mobile Fortress — Slice-0\n"
		+ "Ming + Portuguese · dual-front · offline\n"
		+ "Sim: %s\n\n" % ("C++ SimulationCore" if has_cpp else "GDScript fallback (classic only)")
		+ "Modular battle uses scene graph + GDExtension.\n"
		+ "Classic keeps the single-file canvas prototype."
	)
	start_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/battle/battle.tscn"))
	classic_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://main.tscn"))
	quit_btn.pressed.connect(func(): get_tree().quit())
	if not has_cpp:
		start_btn.disabled = true
		start_btn.text = "Modular Battle (needs GDExtension)"
