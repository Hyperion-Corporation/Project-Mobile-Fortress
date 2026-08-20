extends SceneTree
## G5: dual-front catalog includes night tide; battle loads GameSession.selected_level_path.

const LevelCatalogScript := preload("res://scripts/data/level_catalog.gd")
const SLICE0 := "res://assets/levels/slice0_dual_front.json"
const NIGHT := "res://assets/levels/night_tide_dual_front.json"


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

	var levels: Array = LevelCatalogScript.list_levels()
	if levels.size() < 2:
		failures.append("catalog should list ≥2 dual-front levels (got %d)" % levels.size())
	var ids: PackedStringArray = PackedStringArray()
	for entry in levels:
		ids.append(str(entry.get("id", "")))
	if not "slice0_dual_front" in ids or not "night_tide_dual_front" in ids:
		failures.append("catalog missing slice0 or night_tide: %s" % str(ids))
	if "level_01" in ids:
		failures.append("single-front level_01 should not be in the dual-front catalog")

	var sim: Node = ClassDB.instantiate("SimulationCore")
	root.add_child(sim)
	if not sim.load_level_json(SLICE0):
		failures.append("slice0 load failed")
	var slice_waves: int = int(sim.get_wave_count())
	var slice_land: int = int(sim.get_land_resources())
	if not sim.load_level_json(NIGHT):
		failures.append("night_tide load failed")
	if int(sim.get_wave_count()) == slice_waves:
		failures.append("night_tide should have a different wave count (%d == %d)" % [
			int(sim.get_wave_count()), slice_waves
		])
	if int(sim.get_land_resources()) == slice_land:
		failures.append("night_tide should change starting land 兩")
	if int(sim.get_wave_count()) != 5:
		failures.append("night_tide should have 5 waves (got %d)" % int(sim.get_wave_count()))
	if int(sim.get_sea_resources()) != 28 or int(sim.get_hq_max_hp()) != 90:
		failures.append("night_tide start sea/HQ mismatch (sea=%d hq=%d)" % [
			int(sim.get_sea_resources()), int(sim.get_hq_max_hp())
		])
	sim.queue_free()

	var session: Node = root.get_node("GameSession")
	session.set_selected_level(NIGHT, "night_tide_dual_front")
	if str(session.selected_level_path) != NIGHT:
		failures.append("set_selected_level did not stick")

	var scene = load("res://scenes/battle/battle.tscn")
	if scene == null:
		failures.append("could not load battle.tscn")
		_finish(failures)
		return
	var battle = scene.instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	if battle.sim.get_wave_count() != 5:
		failures.append("battle did not load night_tide waves (got %d)" % int(battle.sim.get_wave_count()))
	if int(battle.sim.get_land_resources()) != 32:
		failures.append("battle night_tide land start=%d" % int(battle.sim.get_land_resources()))
	battle.queue_free()
	session.set_selected_level(SLICE0, "slice0_dual_front")
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Level catalog smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Level catalog smoke: FAIL (%d)" % failures.size())
		quit(1)
