extends Control
## Main menu — start Slice-0 dual-front battle.

@onready var start_btn: Button = $Center/VBox/StartBtn
@onready var quit_btn: Button = $Center/VBox/QuitBtn
@onready var blurb: Label = $Center/VBox/Blurb


func _ready() -> void:
	blurb.text = (
		"Mobile Fortress — Slice-0\n"
		+ "Ming + Portuguese · Land & Sea dual-front\n"
		+ "Offline prototype · isometric-readable ukiyo-e palette\n\n"
		+ "Build fortifications on both shores, then weather the raid."
	)
	start_btn.pressed.connect(_on_start)
	quit_btn.pressed.connect(func(): get_tree().quit())


func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")
