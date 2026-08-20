extends SceneTree
## DT1/DT2: SimulationCore debug APIs + force-lose goes through GameSession.end_run.

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
	sim.reset_run(4, 4, 40)
	if not sim.has_method("debug_set_resources"):
		failures.append("debug_set_resources not bound")
		_finish(failures)
		return

	sim.debug_set_resources(-1, 50)
	if sim.get_land_resources() != 50 or sim.get_sea_resources() != 50:
		failures.append("debug_set_resources failed")
	sim.debug_set_infinite_resources(1, true)
	if not sim.spend(1, 99) or sim.get_sea_resources() != 50:
		failures.append("infinite sea spend should not deduct")
	if sim.spend(0, 99):
		failures.append("land should still be finite")
	sim.debug_apply_income()
	if sim.get_land_resources() != 52:
		failures.append("debug_apply_income did not pay land")

	sim.debug_set_invincible(true)
	sim.damage_hq(30)
	if sim.get_hq_hp() != 40:
		failures.append("invincible HQ still took damage")
	var rid: int = sim.spawn_raider(0, PackedVector2Array([Vector2(0, 0), Vector2(10, 0)]), 20.0, 5.0, 4.0)
	if rid <= 0 or sim.debug_kill_all_raiders() < 1 or sim.get_raider_count() != 0:
		failures.append("debug_kill_all_raiders failed")

	sim.reset_run(10, 10, 100)
	if sim.debug_invincible() or sim.debug_waves_disabled() or sim.debug_infinite_resources(-1):
		failures.append("reset_run must clear cheat flags")

	var session: Node = root.get_node("GameSession")
	session.reset_run()
	session.end_run(false, "DT2 force lose")
	var stored: Dictionary = OfflinePersistence.read_results()
	if bool(stored.get("victory", true)):
		failures.append("force lose did not persist defeat through end_run")
	if str(stored.get("reason", "")) != "DT2 force lose":
		failures.append("force lose reason not persisted")

	# T30: overlay Fill 兩 honors land/sea/both
	sim.reset_run(4, 6, 40)
	session.set_developer_mode(true)
	session.set_dev_menu_open(true)
	await process_frame
	var menu: Node = session.get_node_or_null("DevMenu")
	var front_sel: OptionButton = menu.find_child("FrontSelect", true, false) if menu else null
	if front_sel == null:
		failures.append("FrontSelect missing from dev menu")
	else:
		front_sel.select(0)
		menu._on_fill_res()
		if sim.get_land_resources() != 999 or sim.get_sea_resources() != 6:
			failures.append("Fill land should not change sea (land=%d sea=%d)" % [
				sim.get_land_resources(), sim.get_sea_resources()
			])
		front_sel.select(1)
		menu._on_fill_res()
		if sim.get_land_resources() != 999 or sim.get_sea_resources() != 999:
			failures.append("Fill sea should leave land filled (land=%d sea=%d)" % [
				sim.get_land_resources(), sim.get_sea_resources()
			])
		front_sel.select(0)
		menu._on_toggle_infinite()
		if not sim.debug_infinite_resources(0) or sim.debug_infinite_resources(1):
			failures.append("∞ 兩 on Land should not enable sea infinite")

	session.set_developer_mode(false)
	sim.queue_free()
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Debug cheats smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Debug cheats smoke: FAIL (%d)" % failures.size())
		quit(1)
