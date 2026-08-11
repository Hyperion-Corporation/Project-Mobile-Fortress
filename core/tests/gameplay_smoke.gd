extends SceneTree
## End-to-end headless smoke test for the active Slice-0 scene.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame

	var failures: Array[String] = []
	if not bool(game.use_cpp):
		failures.append("active scene did not initialize SimulationCore")
	if game.waves.size() < 2:
		failures.append("level wave data was not loaded")

	# Cell 0 is land; cell 15 is the first sea cell in the dual-front array.
	game._place_unit(0)
	game.selected_unit = 1
	game._place_unit(15)
	if game.units.size() != 2:
		failures.append("dual-front unit placement failed")

	game._start_combat()
	if int(game.phase) != 1:
		failures.append("combat phase did not start")

	await create_timer(3.0).timeout
	if game._raider_count() <= 0:
		failures.append("first configured wave did not spawn raiders")
	if game._hq() > game._hq_max():
		failures.append("HQ state exceeded its maximum")

	game.queue_free()
	if failures.is_empty():
		print("Gameplay smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Gameplay smoke: FAIL (%d)" % failures.size())
		quit(1)
