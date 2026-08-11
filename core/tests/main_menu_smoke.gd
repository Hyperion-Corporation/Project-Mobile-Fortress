extends SceneTree
## Headless smoke for the configured main-menu entry point.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if not ClassDB.class_exists("SimulationCore"):
		failures.append("SimulationCore not registered")

	var scene := load("res://scenes/main_menu.tscn")
	if scene == null:
		failures.append("could not load main_menu.tscn")
		_finish(failures)
		return

	var menu = scene.instantiate()
	root.add_child(menu)
	await process_frame

	for node_path in ["Center/VBox/StartBtn", "Center/VBox/ClassicBtn", "Center/VBox/QuitBtn"]:
		if menu.get_node_or_null(node_path) == null:
			failures.append("missing menu control: %s" % node_path)

	var start_btn: Button = menu.get_node("Center/VBox/StartBtn")
	var blurb: Label = menu.get_node("Center/VBox/Blurb")
	if start_btn.disabled:
		failures.append("modular battle button disabled with SimulationCore present")
	if not blurb.text.contains("C++ SimulationCore"):
		failures.append("menu did not report the C++ simulation backend")

	menu.queue_free()
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Main menu smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Main menu smoke: FAIL (%d)" % failures.size())
		quit(1)
