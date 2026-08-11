extends SceneTree
## Headless smoke for offline run-result persistence.

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
	session.end_run(true, "smoke-test victory")

	var path := "user://last_run_results.json"
	if not FileAccess.file_exists(path):
		failures.append("run result JSON was not written")
	else:
		var file := FileAccess.open(path, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text()) if file else null
		if not parsed is Dictionary:
			failures.append("run result JSON is not a dictionary")
		else:
			if not bool(parsed.get("victory", false)):
				failures.append("victory result was not persisted")
			if str(parsed.get("reason", "")) != "smoke-test victory":
				failures.append("result reason was not persisted")
			if parsed.get("civs", []) != ["Ming", "Portuguese"]:
				failures.append("civilization pair was not persisted")

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
