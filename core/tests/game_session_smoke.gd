extends SceneTree
## Headless smoke for offline run-result persistence (VS8).

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if not root.has_node("GameSession"):
		failures.append("GameSession autoload is missing")
		_finish(failures)
		return

	var session: Node = root.get_node("GameSession")
	session.reset_run()
	session.enemies_killed = 7
	session.units_placed = 4
	session.outposts_lost = 1
	session.land_currency = 23
	session.sea_currency = 31
	session.end_run(true, "smoke-test victory", {
		"sim": "cpp",
		"path": "smoke",
		"combat_time": 12.5,
		"wave": 2,
	})

	# last_run_results.json
	if not OfflinePersistence.has_results():
		failures.append("run result JSON was not written")
	else:
		var parsed: Dictionary = OfflinePersistence.read_results()
		if not bool(parsed.get("victory", false)):
			failures.append("victory result was not persisted")
		if str(parsed.get("reason", "")) != "smoke-test victory":
			failures.append("result reason was not persisted")
		if parsed.get("civs", []) != ["Ming", "Portuguese"]:
			failures.append("civilization pair was not persisted")
		if int(parsed.get("schema_version", 0)) != OfflinePersistence.SCHEMA_VERSION:
			failures.append("schema_version missing/wrong")
		if str(parsed.get("sim", "")) != "cpp":
			failures.append("sim backend not persisted")
		if int(parsed.get("enemies_killed", 0)) != 7:
			failures.append("enemies_killed not persisted")
		if float(parsed.get("combat_time", 0.0)) != 12.5:
			failures.append("extra combat_time not merged into results")

	# run history append
	var hist: Array = OfflinePersistence.read_history()
	if hist.is_empty():
		failures.append("run history is empty after end_run")
	else:
		var last: Dictionary = hist[hist.size() - 1]
		if str(last.get("reason", "")) != "smoke-test victory":
			failures.append("history last entry reason mismatch")

	# snapshot bytes round-trip helper
	var sample := PackedByteArray([1, 2, 3, 4, 5])
	if not OfflinePersistence.write_snapshot(sample):
		failures.append("write_snapshot failed")
	var loaded: PackedByteArray = OfflinePersistence.read_snapshot()
	if loaded != sample:
		failures.append("snapshot bytes round-trip failed")
	if not OfflinePersistence.has_snapshot():
		failures.append("has_snapshot false after write")

	# summary helper non-empty
	var summary: String = OfflinePersistence.format_results_summary(OfflinePersistence.read_results())
	if summary.is_empty() or summary.contains("No prior"):
		failures.append("format_results_summary empty for real results")

	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Game session smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Game session smoke: FAIL (%d)" % failures.size())
		quit(1)
