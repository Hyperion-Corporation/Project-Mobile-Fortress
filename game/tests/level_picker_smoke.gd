extends SceneTree
## DT6: overlay LevelPickSelect loads a different dual-front JSON in place.

const SLICE0 := "res://assets/levels/slice0_dual_front.json"
const NIGHT := "res://assets/levels/night_tide_dual_front.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if not root.has_node("GameSession"):
		failures.append("GameSession missing")
		_finish(failures)
		return
	if not ClassDB.class_exists("SimulationCore"):
		failures.append("SimulationCore missing")
		_finish(failures)
		return

	var session: Node = root.get_node("GameSession")
	session.set_selected_level(SLICE0, "slice0_dual_front")
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
	if int(battle.sim.get_wave_count()) != 4:
		failures.append("expected slice0 4 waves, got %d" % int(battle.sim.get_wave_count()))

	var menu: Node = session.get_node_or_null("DevMenu")
	if menu == null:
		failures.append("DevMenu missing")
		_finish(failures)
		return
	var pick: OptionButton = menu.find_child("LevelPickSelect", true, false)
	if pick == null:
		failures.append("LevelPickSelect missing")
	elif pick.item_count < 2:
		failures.append("LevelPickSelect should list ≥2 levels")
	elif menu.find_child("LoadLevelBtn", true, false) == null:
		failures.append("LoadLevelBtn missing")
	else:
		var night_i := -1
		var slice_i := -1
		for i in pick.item_count:
			var meta: Variant = pick.get_item_metadata(i)
			if not meta is Dictionary:
				continue
			var lid := str(meta.get("id", ""))
			if lid == "night_tide_dual_front":
				night_i = i
			elif lid == "slice0_dual_front":
				slice_i = i
		if night_i < 0 or slice_i < 0:
			failures.append("picker missing slice0 or night_tide")
		else:
			pick.select(night_i)
			menu._on_load_level()
			await process_frame
			if str(session.selected_level_id) != "night_tide_dual_front":
				failures.append("session level_id not night_tide")
			if int(battle.sim.get_wave_count()) != 5:
				failures.append("DT6 load night_tide waves=%d" % int(battle.sim.get_wave_count()))
			if int(battle.sim.get_land_resources()) != 32:
				failures.append("DT6 load night_tide land=%d" % int(battle.sim.get_land_resources()))
			if battle.phase != battle.Phase.BUILD:
				failures.append("DT6 load should return to BUILD")
			pick.select(slice_i)
			menu._on_load_level()
			await process_frame
			if int(battle.sim.get_wave_count()) != 4 or int(battle.sim.get_land_resources()) != 40:
				failures.append("DT6 reload slice0 failed (waves=%d land=%d)" % [
					int(battle.sim.get_wave_count()), int(battle.sim.get_land_resources())
				])

	session.set_developer_mode(false)
	session.set_selected_level(SLICE0, "slice0_dual_front")
	battle.queue_free()
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Level picker smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Level picker smoke: FAIL (%d)" % failures.size())
		quit(1)
