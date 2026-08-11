extends SceneTree
## Headless smoke for modular battle_root + SimulationCore defenders.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if not ClassDB.class_exists("SimulationCore"):
		failures.append("SimulationCore not registered")
		_finish(failures)
		return

	var scene = load("res://scenes/battle/battle.tscn")
	if scene == null:
		failures.append("could not load battle.tscn")
		_finish(failures)
		return

	var battle = scene.instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame

	if battle.sim == null:
		failures.append("battle.sim is null")
	if battle.land_grid == null or battle.sea_grid == null:
		failures.append("grids not set up")

	# Place land spearman on a placeable cell
	var land_cell := Vector2i(6, 1)
	if battle.land_grid and battle.land_grid.is_placeable(land_cell):
		battle.selected_unit_id = "spearman"
		battle._on_cell_clicked("land", land_cell)
	else:
		# try a few cells
		for x in range(5, 8):
			for y in range(0, 5):
				var c := Vector2i(x, y)
				if battle.land_grid.is_placeable(c):
					battle.selected_unit_id = "spearman"
					battle._on_cell_clicked("land", c)
					land_cell = c
					break

	await process_frame
	if battle.sim.get_defender_count() < 1:
		failures.append("spawn_defender via placement failed")

	# Sea unit
	battle.selected_unit_id = "arquebusier"
	for x in range(5, 8):
		for y in range(0, 5):
			var c2 := Vector2i(x, y)
			if battle.sea_grid.is_placeable(c2):
				battle._on_cell_clicked("sea", c2)
				break

	await process_frame
	if battle.sim.get_defender_count() < 2:
		failures.append("dual-front defender placement failed")

	battle._start_combat()
	if int(battle.phase) != int(battle.Phase.COMBAT):
		failures.append("combat phase did not start")

	await create_timer(3.0).timeout
	if battle.sim.get_raider_count() <= 0 and battle.wave_index < 1:
		failures.append("expected wave spawn after combat start")

	# Defenders should be able to kill over time
	var kills_before: int = battle.sim.get_enemies_killed()
	await create_timer(4.0).timeout
	var kills_after: int = battle.sim.get_enemies_killed()
	if kills_after < kills_before:
		failures.append("enemy kill count went backwards")

	battle.queue_free()
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Modular battle smoke: PASS")
		quit(0)
	else:
		for f in failures:
			push_error(f)
		print("Modular battle smoke: FAIL (%d)" % failures.size())
		quit(1)
