extends SceneTree
## DT3: jump-wave, spawn-at-cell, reload current level. No RNG.

const LEVEL := "res://assets/levels/slice0_dual_front.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if not ClassDB.class_exists("SimulationCore"):
		failures.append("SimulationCore missing")
		_finish(failures)
		return
	if not root.has_node("GameSession"):
		failures.append("GameSession missing")
		_finish(failures)
		return

	var sim: Node = ClassDB.instantiate("SimulationCore")
	sim.name = "SimulationCore"
	root.add_child(sim)
	if not sim.load_level_json(LEVEL):
		failures.append("load_level_json failed")
		_finish(failures)
		return
	if int(sim.get_wave_count()) < 2:
		failures.append("level should have ≥2 waves")
	if not bool(sim.debug_jump_wave(1)):
		failures.append("debug_jump_wave(1) rejected")
	if int(sim.get_current_wave()) != 1:
		failures.append("jump left current_wave=%d want 1" % int(sim.get_current_wave()))
	sim.tick(0.05, false)
	if int(sim.get_current_wave()) != 2:
		failures.append("tick after jump should fire wave 2 (now %d)" % int(sim.get_current_wave()))
	var after_jump: int = int(sim.get_raider_count())
	if after_jump < 1:
		failures.append("jump-to-wave 2 spawned no raiders")
	if bool(sim.debug_jump_wave(99)):
		failures.append("out-of-range jump should fail")

	sim.init_grids(Vector2i(8, 5))
	var rid: int = int(sim.debug_spawn_raider_at(0, Vector2i(2, 1), 40.0, 20.0, 6.0))
	if rid <= 0:
		failures.append("debug_spawn_raider_at failed")
	var found := false
	for raider in sim.get_raiders():
		if int(raider.get("id", -1)) == rid:
			found = true
			if int(raider.get("entry_row", -99)) != 1:
				failures.append("spawned raider entry_row=%s" % str(raider.get("entry_row")))
	if not found:
		failures.append("spawned raider not in get_raiders")

	if not sim.load_level_json(LEVEL):
		failures.append("reload load_level_json failed")
	elif int(sim.get_current_wave()) != 0 or int(sim.get_raider_count()) != 0:
		failures.append("reload should reset wave/raiders (wave=%d raiders=%d)" % [
			int(sim.get_current_wave()), int(sim.get_raider_count())
		])
	sim.queue_free()

	var session: Node = root.get_node("GameSession")
	session.set_developer_mode(true)
	session.set_dev_menu_open(true)
	await process_frame

	var scene = load("res://scenes/battle/battle.tscn")
	if scene == null:
		failures.append("could not load battle.tscn")
		_finish(failures)
		return
	var battle = scene.instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame

	var menu: Node = session.get_node_or_null("DevMenu")
	if menu == null:
		failures.append("DevMenu missing")
	else:
		for child_name in ["SpawnTypeSelect", "CellX", "CellY", "WaveSpin", "JumpWaveBtn", "ReloadLevelBtn", "SpawnAtCellBtn"]:
			if menu.find_child(child_name, true, false) == null:
				failures.append("%s missing from dev menu" % child_name)
		var type_sel: OptionButton = menu.find_child("SpawnTypeSelect", true, false)
		var cell_x: SpinBox = menu.find_child("CellX", true, false)
		var cell_y: SpinBox = menu.find_child("CellY", true, false)
		var wave_spin: SpinBox = menu.find_child("WaveSpin", true, false)
		if type_sel and cell_x and cell_y:
			_select_option(type_sel, "spearman")
			cell_x.value = 6
			cell_y.value = 0
			menu._on_spawn_at_cell()
			if int(battle.sim.get_defender_count()) < 1:
				failures.append("overlay spawn spearman did not add a defender")
			_select_option(type_sel, "raider_land")
			cell_x.value = 2
			cell_y.value = 1
			var before_r: int = int(battle.sim.get_raider_count())
			menu._on_spawn_at_cell()
			if int(battle.sim.get_raider_count()) <= before_r:
				failures.append("overlay spawn raider_land did not add a raider")
		if wave_spin:
			wave_spin.value = 2
			menu._on_jump_wave()
			if battle.phase != battle.Phase.COMBAT:
				failures.append("jump wave should enter COMBAT")
			await process_frame
			await process_frame
			if int(battle.sim.get_current_wave()) < 1:
				failures.append("overlay jump wave 2 left current_wave=%d" % int(battle.sim.get_current_wave()))

	session.set_developer_mode(false)
	battle.queue_free()
	_finish(failures)


func _select_option(sel: OptionButton, id: String) -> void:
	for i in sel.item_count:
		if sel.get_item_text(i) == id:
			sel.select(i)
			return


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Scenario control smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Scenario control smoke: FAIL (%d)" % failures.size())
		quit(1)
