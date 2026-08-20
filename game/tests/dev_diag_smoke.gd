extends SceneTree
## DT5/DT4: overlay stats + pause/step/speed on the T11 clock.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if not root.has_node("GameSession"):
		failures.append("GameSession autoload missing")
		_finish(failures)
		return
	var session: Node = root.get_node("GameSession")

	session.set_time_scale(0.1)
	if absf(float(session.time_scale) - 0.5) > 0.001:
		failures.append("time_scale did not clamp up to 0.5")
	session.set_time_scale(99.0)
	if absf(float(session.time_scale) - 10.0) > 0.001:
		failures.append("time_scale did not clamp down to 10")
	session.set_time_scale(1.0)

	session.set_paused(false)
	session.request_step()
	if session.consume_step():
		failures.append("step should not queue while unpaused")
	session.set_paused(true)
	session.request_step()
	if not session.consume_step():
		failures.append("paused request_step was not consumed")
	if session.consume_step():
		failures.append("step flag was not cleared")
	session.set_paused(false)

	session.set_developer_mode(true)
	session.set_dev_menu_open(true)
	await process_frame
	var menu: Node = session.get_node_or_null("DevMenu")
	if menu == null:
		failures.append("DevMenu missing")
	else:
		if menu.find_child("DiagLabel", true, false) == null:
			failures.append("DT5 DiagLabel missing")
		if menu.find_child("SpeedSlider", true, false) == null:
			failures.append("DT4 SpeedSlider missing")
		if menu.find_child("StepBtn", true, false) == null:
			failures.append("DT4 StepBtn missing")

	var scene = load("res://scenes/battle/battle.tscn")
	if scene == null:
		failures.append("could not load battle.tscn")
		_finish(failures)
		return
	var battle = scene.instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	battle.selected_unit_id = "spearman"
	for x in range(5, 8):
		for y in range(0, 5):
			if battle.land_grid.is_placeable(Vector2i(x, y)):
				battle._on_cell_clicked("land", Vector2i(x, y))
				break
	battle._start_combat()
	await process_frame
	session.set_paused(true)
	var t0: float = battle.sim.get_combat_time()
	session.request_step()
	await process_frame
	await process_frame
	var t1: float = battle.sim.get_combat_time()
	if t1 <= t0 + 0.001:
		failures.append("paused step did not advance sim (%.4f -> %.4f)" % [t0, t1])
	var t2: float = battle.sim.get_combat_time()
	await process_frame
	await process_frame
	if absf(battle.sim.get_combat_time() - t2) > 0.001:
		failures.append("sim advanced while paused without a step")

	session.set_paused(false)
	session.set_developer_mode(false)
	session.set_time_scale(1.0)
	battle.queue_free()
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Dev diag smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Dev diag smoke: FAIL (%d)" % failures.size())
		quit(1)
