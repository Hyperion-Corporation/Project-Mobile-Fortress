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

	# Hero placement and cross-front redeployment
	battle.selected_unit_id = "hero_qi"
	var hero_cell := Vector2i(-1, -1)
	for x in range(0, 8):
		for y in range(0, 5):
			var candidate := Vector2i(x, y)
			if battle.land_grid.is_placeable(candidate):
				hero_cell = candidate
				break
		if hero_cell.x >= 0:
			break
	if hero_cell.x < 0:
		failures.append("could not find a land cell for hero")
	else:
		battle._on_cell_clicked("land", hero_cell)
		await process_frame
		var hero_id := -1
		for defender in battle.sim.get_defenders():
			if str(defender.get("type", "")) == "hero_qi":
				hero_id = int(defender.get("id", -1))
				break
		if hero_id < 0:
			failures.append("hero placement failed")
		else:
			battle._on_cell_clicked("land", hero_cell)
			var target_cell := Vector2i(-1, -1)
			for x in range(0, 8):
				for y in range(0, 5):
					var candidate := Vector2i(x, y)
					if battle.sea_grid.is_placeable(candidate):
						target_cell = candidate
						break
				if target_cell.x >= 0:
					break
			if target_cell.x < 0:
				failures.append("could not find a sea redeployment cell")
			else:
				battle._on_cell_clicked("sea", target_cell)
				var traveling := false
				for defender in battle.sim.get_defenders():
					if int(defender.get("id", -1)) == hero_id:
						traveling = bool(defender.get("traveling", false))
				if not traveling:
					failures.append("hero redeployment did not start travel")

	battle._start_combat()
	if int(battle.phase) != int(battle.Phase.COMBAT):
		failures.append("combat phase did not start")
	if battle.sim.has_method("get_in_combat") and not battle.sim.get_in_combat():
		failures.append("sim not in combat after start")

	await create_timer(3.0).timeout
	var wave_ok: bool = false
	wave_ok = battle.sim.get_raider_count() > 0
	if battle.sim.has_method("get_current_wave") and battle.sim.get_current_wave() >= 1:
		wave_ok = true
	if not wave_ok:
		failures.append("expected C++ wave spawn after combat start")
	await create_timer(2.0).timeout
	for defender in battle.sim.get_defenders():
		if str(defender.get("type", "")) == "hero_qi":
			if bool(defender.get("traveling", true)):
				failures.append("hero remained traveling after redeployment duration")
			if int(defender.get("front", -1)) != 1:
				failures.append("hero did not arrive on the sea front")

	# U2 pause overlay: Esc-equivalent flag must freeze sim and show overlay
	var session: Node = root.get_node_or_null("GameSession")
	if session == null:
		failures.append("GameSession autoload missing")
	else:
		var combat_before_pause: float = battle.sim.get_combat_time()
		session.set_paused(true)
		await process_frame
		var pause_overlay: CanvasItem = battle.hud.get_node_or_null("Root/PauseOverlay")
		if pause_overlay == null or not pause_overlay.visible:
			failures.append("pause overlay not visible when GameSession is paused")
		await create_timer(0.4).timeout
		if absf(battle.sim.get_combat_time() - combat_before_pause) > 0.001:
			failures.append("sim combat time advanced while paused")
		session.set_paused(false)
		await process_frame
		if pause_overlay != null and pause_overlay.visible:
			failures.append("pause overlay still visible after resume")
	if battle.hud.has_method("set_outposts"):
		var op: Label = battle.hud.get_node_or_null("Root/TopBar/OutpostLabel")
		if op == null or op.text.find("🌾 糧倉") < 0 or op.text.find("⛵ 港埠") < 0:
			failures.append("U4/U10 outpost status badges missing")

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
