extends SceneTree
## T48: A4 battle hookup, DT5 intensity readout, DT7 wave-start DDA fields.

const PlaytestLogScript := preload("res://scripts/data/playtest_log.gd")
const SLICE0 := "res://assets/levels/slice0_dual_front.json"
const NIGHT := "res://assets/levels/night_tide_dual_front.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if not ClassDB.class_exists("SimulationCore"):
		failures.append("SimulationCore class is not registered")
		_finish(failures)
		return
	if not root.has_node("GameSession"):
		failures.append("GameSession autoload missing")
		_finish(failures)
		return

	var session: Node = root.get_node("GameSession")
	session.set_dda_enabled(false)
	session.set_paused(false)
	session.set_time_scale(1.0)
	session.set_selected_level(SLICE0, "slice0_dual_front")
	PlaytestLogScript.open_session_id = ""
	PlaytestLogScript.tester_name = "dda-battle-smoke"
	OfflinePersistence.write_json(PlaytestLogScript.STORE_PATH, PlaytestLogScript.default_store())

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
		_finish(failures, session, battle)
		return
	if bool(battle.sim.dda_enabled()):
		failures.append("director should stay off when the overlay setting is off")
	if not is_equal_approx(float(battle.sim.get_dda_intensity()), 1.0):
		failures.append("disabled battle intensity was not 1 (got %s)" % battle.sim.get_dda_intensity())

	session.set_developer_mode(true)
	session.set_dev_menu_open(true)
	await process_frame
	await process_frame
	var menu: Node = session.get_node_or_null("DevMenu")
	if menu == null:
		failures.append("DevMenu missing")
		_finish(failures, session, battle)
		return
	var diag: Label = menu.find_child("DiagLabel", true, false)
	if diag == null:
		failures.append("DT5 DiagLabel missing")
	else:
		if menu.has_method("_refresh_diag"):
			menu._refresh_diag()
		if not str(diag.text).contains("DDA off"):
			failures.append("overlay did not read DDA off (got %s)" % diag.text)
		if not str(diag.text).contains("intensity 1.00"):
			failures.append("overlay did not read intensity 1.00 while off (got %s)" % diag.text)
	var toggle: CheckBox = menu.find_child("DdaToggle", true, false)
	if toggle == null:
		failures.append("DdaToggle missing from dev overlay")
	elif toggle.button_pressed:
		failures.append("DdaToggle should default off")

	if menu.has_method("_on_dda_toggled"):
		menu._on_dda_toggled(true)
	else:
		failures.append("overlay DDA handler missing")
	if not bool(session.dda_enabled) or not bool(battle.sim.dda_enabled()):
		failures.append("overlay toggle did not enable the director on the live sim")
	if not bool(OfflinePersistence.read_settings().get("dda_enabled", false)):
		failures.append("overlay toggle did not persist dda_enabled")
	await process_frame
	if menu.has_method("_refresh_diag"):
		menu._refresh_diag()
	if diag and not str(diag.text).contains("DDA on"):
		failures.append("overlay did not read DDA on after toggle (got %s)" % diag.text)
	if toggle and not toggle.button_pressed:
		failures.append("DdaToggle did not follow the persisted setting")

	battle.queue_free()
	await process_frame
	battle = scene.instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	if battle.sim == null:
		failures.append("reloaded battle.sim is null")
		_finish(failures, session, battle)
		return
	if not bool(battle.sim.dda_enabled()):
		failures.append("new battle after persisted on did not enable the director")

	if not bool(battle.debug_load_level(NIGHT)):
		failures.append("debug_load_level night_tide failed")
	elif not bool(battle.sim.dda_enabled()):
		failures.append("debug_load_level dropped the overlay DDA setting")
	if not bool(battle.debug_load_level(SLICE0)):
		failures.append("debug_load_level slice0 failed")
	elif not bool(battle.sim.dda_enabled()):
		failures.append("reloaded level dropped the overlay DDA setting")

	_place_spearman(battle)
	if battle.sim.get_defender_count() < 1:
		failures.append("could not place a land spearman")
	if not battle.save_snapshot():
		failures.append("save_snapshot failed")
	session.set_dda_enabled(false)
	session.apply_dda(battle.sim)
	if bool(battle.sim.dda_enabled()):
		failures.append("apply_dda false did not disable the live sim")
	if not battle.load_snapshot():
		failures.append("load_snapshot failed")
	elif bool(battle.sim.dda_enabled()):
		failures.append("load_snapshot let the v2 snapshot DDA flag beat the overlay setting")

	if not battle.save_snapshot():
		failures.append("save_snapshot of DDA-off state failed")
	session.set_dda_enabled(true)
	if not battle.load_snapshot():
		failures.append("load_snapshot (setting on, snapshot off) failed")
	elif not bool(battle.sim.dda_enabled()):
		failures.append("load_snapshot did not re-apply the overlay setting over a DDA-off snapshot")

	PlaytestLogScript.ensure_open_session()
	if battle.phase != battle.Phase.BUILD:
		battle.debug_load_level(SLICE0)
	_place_spearman(battle)
	battle._start_combat()
	battle._advance_sim(2.1)
	var store: Dictionary = PlaytestLogScript.load_store()
	var wave_events: Array = []
	if (store.get("sessions", []) as Array).is_empty():
		failures.append("playtest session missing after wave start")
	else:
		for event in store["sessions"][0].get("events", []):
			if event is Dictionary and str(event.get("label", "")) == "wave_start":
				wave_events.append(event)
		if wave_events.is_empty():
			failures.append("wave_start was not recorded in the playtest log")
		else:
			var wave_ev: Dictionary = wave_events[0]
			if not bool(wave_ev.get("dda_enabled", false)):
				failures.append("wave_start dda_enabled was not true")
			if not wave_ev.has("dda_intensity"):
				failures.append("wave_start missing dda_intensity")
			if str(wave_ev.get("note", "")).find("DDA on") < 0:
				failures.append("wave_start note missing DDA on")

	session.set_dda_enabled(false)
	session.apply_dda(battle.sim)
	if bool(battle.sim.dda_enabled()):
		failures.append("disabling the overlay setting left the director on")
	if bool(OfflinePersistence.read_settings().get("dda_enabled", true)):
		failures.append("disabling the overlay setting did not persist off")

	PlaytestLogScript.open_session_id = ""
	PlaytestLogScript.ensure_open_session()
	battle.debug_load_level(SLICE0)
	_place_spearman(battle)
	battle._start_combat()
	battle._advance_sim(2.1)
	store = PlaytestLogScript.load_store()
	var off_events: Array = []
	for session_row in store.get("sessions", []):
		if not session_row is Dictionary:
			continue
		if str(session_row.get("id", "")) != PlaytestLogScript.open_session_id:
			continue
		for event in session_row.get("events", []):
			if event is Dictionary and str(event.get("label", "")) == "wave_start":
				off_events.append(event)
	if off_events.is_empty():
		failures.append("wave_start was not recorded with DDA off")
	else:
		var off_ev: Dictionary = off_events[0]
		if bool(off_ev.get("dda_enabled", true)):
			failures.append("wave_start dda_enabled should be false when the setting is off")
		if not is_equal_approx(float(off_ev.get("dda_intensity", -1.0)), 1.0):
			failures.append("off-path wave_start intensity was not 1")

	_finish(failures, session, battle)


func _place_spearman(battle: Node) -> void:
	if battle.sim.get_defender_count() > 0:
		return
	battle.selected_unit_id = "spearman"
	for x in range(5, 8):
		for y in range(0, 5):
			var cell := Vector2i(x, y)
			if battle.land_grid and battle.land_grid.is_placeable(cell):
				battle._on_cell_clicked("land", cell)
				return


func _finish(failures: Array[String], session: Node = null, battle: Node = null) -> void:
	if battle != null and is_instance_valid(battle):
		battle.queue_free()
	if session != null and is_instance_valid(session):
		session.set_dda_enabled(false)
		session.set_paused(false)
		session.set_time_scale(1.0)
		session.set_developer_mode(false)
	PlaytestLogScript.open_session_id = ""
	if failures.is_empty():
		print("DDA battle smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("DDA battle smoke: FAIL (%d)" % failures.size())
		quit(1)
