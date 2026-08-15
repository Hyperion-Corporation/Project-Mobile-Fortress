extends SceneTree
## DT7: Mark Session Event writes user://; sync maps to PlaytestNotesView shape.

const PlaytestLogScript := preload("res://scripts/data/playtest_log.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if not root.has_node("GameSession"):
		failures.append("GameSession missing")
		_finish(failures)
		return

	PlaytestLogScript.open_session_id = ""
	PlaytestLogScript.tester_name = "smoke-tester"
	OfflinePersistence.write_json(PlaytestLogScript.STORE_PATH, PlaytestLogScript.default_store())

	var session: Node = root.get_node("GameSession")
	session.playtest_set_tester("smoke-tester")
	var ev: Dictionary = session.playtest_mark_event("first beat")
	if str(ev.get("label", "")) != "mark":
		failures.append("mark_event did not return a mark")
	var store: Dictionary = PlaytestLogScript.load_store()
	if (store.get("sessions", []) as Array).size() != 1:
		failures.append("first mark should open one session")
	else:
		var s: Dictionary = store["sessions"][0]
		if str(s.get("tester", "")) != "smoke-tester":
			failures.append("tester not stored")
		if (s.get("events", []) as Array).size() != 1:
			failures.append("first mark missing event")
	session.playtest_mark_event("second beat")
	store = PlaytestLogScript.load_store()
	if (store["sessions"][0].get("events", []) as Array).size() != 2:
		failures.append("second mark should append")

	session.end_run(false, "DT7 smoke lose")
	store = PlaytestLogScript.load_store()
	var labels: PackedStringArray = PackedStringArray()
	for event in store["sessions"][0].get("events", []):
		labels.append(str(event.get("label", "")))
	if not "run_ended" in labels:
		failures.append("open session should record end_run")

	var dest := "user://dt7_dashboard_sync.json"
	var result: Dictionary = session.playtest_sync(ProjectSettings.globalize_path(dest))
	if not bool(result.get("ok", false)):
		failures.append("sync failed: %s" % str(result))
	var dash: Variant = OfflinePersistence.read_json(dest)
	if not dash is Dictionary:
		failures.append("dashboard dest missing")
	else:
		if str(dash.get("gate", "")) != "VS10":
			failures.append("dashboard gate missing")
		var sessions: Array = dash.get("sessions", [])
		if sessions.is_empty():
			failures.append("sync wrote no sessions")
		else:
			var row: Dictionary = sessions[0]
			for key in ["date", "tester", "platform", "build_commit", "hard_criteria_pass", "art_criteria_pass", "verdict", "notes"]:
				if not row.has(key):
					failures.append("dashboard session missing %s" % key)
			if str(row.get("tester", "")) != "smoke-tester":
				failures.append("synced tester mismatch")
			if str(row.get("notes", "")).find("first beat") < 0:
				failures.append("events were not folded into notes")
			if row.has("events"):
				failures.append("dashboard session should not keep raw events array")

	# Overlay buttons
	session.set_developer_mode(true)
	session.set_dev_menu_open(true)
	await process_frame
	var menu: Node = session.get_node_or_null("DevMenu")
	if menu == null:
		failures.append("DevMenu missing")
	else:
		for child_name in ["MarkSessionBtn", "SyncDashboardBtn", "TesterEdit"]:
			if menu.find_child(child_name, true, false) == null:
				failures.append("%s missing from dev menu" % child_name)
		menu._on_mark_session()
		store = PlaytestLogScript.load_store()
		if (store["sessions"][0].get("events", []) as Array).size() < 4:
			failures.append("overlay Mark Session Event did not append")

	# Pipeline script merge (does not touch the committed dashboard file)
	var src_os := ProjectSettings.globalize_path("user://dt7_script_src.json")
	var dest_os := ProjectSettings.globalize_path("user://dt7_script_dest.json")
	OfflinePersistence.write_json("user://dt7_script_src.json", {
		"schema_version": 1,
		"sessions": [{
			"id": "sess_script",
			"date": "2026-08-15",
			"tester": "script-tester",
			"platform": "Linux",
			"build_commit": "abc1234",
			"hard_criteria_pass": true,
			"art_criteria_pass": false,
			"verdict": "shows_promise",
			"notes": "hand-off",
			"events": [{"iso": "2026-08-15T00:00:00", "label": "mark", "note": "pip", "phase": "COMBAT"}],
		}],
	})
	OfflinePersistence.write_json("user://dt7_script_dest.json", PlaytestLogScript.default_dashboard())
	var core := ProjectSettings.globalize_path("res://")
	var script := core.path_join("../scripts/sync_playtest_session.sh").simplify_path()
	var out: Array = []
	var code := OS.execute("bash", PackedStringArray([script, src_os, dest_os]), out, true, false)
	if code != 0:
		failures.append("sync_playtest_session.sh exit %d: %s" % [code, str(out)])
	else:
		var merged: Variant = OfflinePersistence.read_json("user://dt7_script_dest.json")
		if not merged is Dictionary or (merged["sessions"] as Array).is_empty():
			failures.append("script wrote no sessions")
		elif str((merged["sessions"] as Array)[0].get("tester", "")) != "script-tester":
			failures.append("script tester mismatch")
		elif str((merged["sessions"] as Array)[0].get("notes", "")).find("pip") < 0:
			failures.append("script did not fold events into notes")

	session.set_developer_mode(false)
	PlaytestLogScript.open_session_id = ""
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Playtest log smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Playtest log smoke: FAIL (%d)" % failures.size())
		quit(1)
