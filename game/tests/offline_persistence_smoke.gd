extends SceneTree
## VS8 modular path: FlatBuffers snapshot via OfflinePersistence + battle_root helpers.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if not ClassDB.class_exists("SimulationCore"):
		failures.append("SimulationCore missing")
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

	if not battle.has_method("save_snapshot") or not battle.has_method("load_snapshot"):
		failures.append("battle missing save/load_snapshot")
		_finish(failures)
		return

	# Place a unit via sim if available so snapshot is non-trivial
	var sim: Node = battle.get_node_or_null("SimulationCore")
	if sim == null:
		failures.append("SimulationCore node missing on battle")
		_finish(failures)
		return
	sim.spawn_defender(0, "spearman", Vector2(100, 100), 80.0, 10.0, 1.0)
	sim.spawn_raider(0, PackedVector2Array([Vector2(0, 0), Vector2(40, 0)]), 30.0, 5.0, 4.0, 99)

	if not battle.save_snapshot():
		failures.append("save_snapshot returned false")
	if not OfflinePersistence.has_snapshot():
		failures.append("snapshot file missing after save")

	var before_def: int = sim.get_defender_count()
	var before_r: int = sim.get_raider_count()
	sim.reset_run(1, 2, 3)
	if sim.get_defender_count() != 0:
		failures.append("reset_run did not clear entities before load test")

	if not battle.load_snapshot():
		failures.append("load_snapshot returned false")
	if sim.get_defender_count() != before_def:
		failures.append("load did not restore defender count (got %d want %d)" % [sim.get_defender_count(), before_def])
	if sim.get_raider_count() != before_r:
		failures.append("load did not restore raider count (got %d want %d)" % [sim.get_raider_count(), before_r])

	# End run should write results + history
	if battle.has_method("_finish"):
		battle._finish(true, "offline-persistence-smoke")
		await process_frame
		var results: Dictionary = OfflinePersistence.read_results()
		if str(results.get("reason", "")) != "offline-persistence-smoke":
			failures.append("end_run results reason not written")
		if str(results.get("path", "")) != "modular":
			failures.append("modular path tag missing from results")
		if not bool(results.get("victory", false)):
			failures.append("victory not set in results")

	battle.queue_free()
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Offline persistence smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Offline persistence smoke: FAIL (%d)" % failures.size())
		quit(1)
