extends SceneTree
## DT8: developer-mode unlock is independent of telemetry and opens the stub overlay.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if not root.has_node("GameSession"):
		failures.append("GameSession autoload missing")
		_finish(failures)
		return

	var session: Node = root.get_node("GameSession")
	session.set_developer_mode(false)
	if bool(session.developer_mode):
		failures.append("could not clear developer_mode")

	# Four taps do not unlock; fifth does.
	var unlocked := false
	for i in 4:
		if session.register_dev_tap():
			failures.append("unlocked after %d taps" % (i + 1))
	unlocked = session.register_dev_tap()
	if not unlocked or not bool(session.developer_mode):
		failures.append("5-tap sequence did not unlock developer_mode")
	if not session.is_dev_menu_open():
		failures.append("dev menu did not open after 5-tap unlock")

	var stored: Dictionary = OfflinePersistence.read_settings()
	if not bool(stored.get("developer_mode", false)):
		failures.append("developer_mode was not persisted")
	if str(stored.get("telemetry_tier", "")) == "":
		failures.append("telemetry_tier missing after developer_mode persist")

	session.set_dev_menu_open(false)
	session.toggle_dev_menu()
	if not session.is_dev_menu_open():
		failures.append("toggle_dev_menu did not reopen overlay")

	session.set_developer_mode(false)
	if session.is_dev_menu_open():
		failures.append("disabling developer_mode left the overlay open")
	if bool(OfflinePersistence.read_settings().get("developer_mode", true)):
		failures.append("disabling developer_mode did not persist")

	# Telemetry and developer_mode stay independent on disk
	var mixed := OfflinePersistence.default_settings()
	mixed["telemetry_tier"] = "none"
	mixed["developer_mode"] = true
	OfflinePersistence.write_settings(mixed)
	var again: Dictionary = OfflinePersistence.read_settings()
	if str(again.get("telemetry_tier", "")) != "none":
		failures.append("telemetry_tier overwritten by developer_mode write")
	if not bool(again.get("developer_mode", false)):
		failures.append("developer_mode lost beside telemetry_tier none")

	session.set_developer_mode(false)
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Dev access smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Dev access smoke: FAIL (%d)" % failures.size())
		quit(1)
