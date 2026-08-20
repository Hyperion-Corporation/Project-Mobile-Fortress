extends SceneTree
## S4 FlatBuffers snapshot round-trip contract test.

func _init() -> void:
	var failures: Array[String] = []
	if not ClassDB.class_exists("SimulationCore"):
		failures.append("SimulationCore not registered")
		_finish(failures)
		return

	var sim: Node = ClassDB.instantiate("SimulationCore")
	root.add_child(sim)
	sim.reset_run(30, 25, 90)
	if not sim.load_level_json("res://assets/levels/slice0_dual_front.json"):
		failures.append("load_level_json failed")

	var lane := PackedVector2Array([Vector2(0, 0), Vector2(50, 0), Vector2(100, 0)])
	sim.set_lane_path(0, lane)
	sim.set_lane_path(1, lane)
	sim.spawn_defender(0, "spearman", Vector2(10, 5), 80.0, 12.0, 0.5)
	var hero_id: int = sim.spawn_defender(1, "hero_qi", Vector2(20, 5), 100.0, 10.0, 0.8, 1.0, 0.5, 120.0, 0.2)
	sim.start_defender_travel(hero_id, Vector2(60, 10), 0, 1.0)
	sim.spawn_raider(0, lane, 40.0, 10.0, 5.0, 1)
	sim.start_combat()
	sim.tick(0.5, true)

	var land_before: int = sim.get_land_resources()
	var sea_before: int = sim.get_sea_resources()
	var hq_before: int = sim.get_hq_hp()
	var def_before: int = sim.get_defender_count()
	var raid_before: int = sim.get_raider_count()
	var wave_before: int = sim.get_current_wave()

	var bytes: PackedByteArray = sim.save_state()
	if bytes.size() < 16:
		failures.append("save_state too small: %d" % bytes.size())

	# Mutate after snapshot
	sim.spend(0, min(5, land_before))
	sim.spawn_raider(1, lane, 10.0, 5.0, 1.0, 99)

	if not sim.load_state(bytes):
		failures.append("load_state failed")
	if sim.get_land_resources() != land_before:
		failures.append("land not restored (%d vs %d)" % [sim.get_land_resources(), land_before])
	if sim.get_sea_resources() != sea_before:
		failures.append("sea not restored")
	if sim.get_hq_hp() != hq_before:
		failures.append("hq not restored")
	if sim.get_defender_count() != def_before:
		failures.append("defender count not restored")
	if sim.get_raider_count() != raid_before:
		failures.append("raider count not restored")
	if not sim.get_in_combat():
		failures.append("in_combat not restored")
	if sim.get_current_wave() != wave_before:
		failures.append("current_wave not restored")

	# user:// file round-trip
	var path := "user://mf_slice0_snapshot.bin"
	var wf := FileAccess.open(path, FileAccess.WRITE)
	if wf == null:
		failures.append("could not write user:// snapshot")
	else:
		wf.store_buffer(bytes)
		wf.close()
		var rf := FileAccess.open(path, FileAccess.READ)
		var loaded: PackedByteArray = rf.get_buffer(rf.get_length())
		rf.close()
		if not sim.load_state(loaded):
			failures.append("file buffer load_state failed")

	# second in-memory round-trip
	var bytes2: PackedByteArray = sim.save_state()
	if not sim.load_state(bytes2):
		failures.append("second load_state failed")

	sim.queue_free()
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("FlatBuffers snapshot smoke: PASS")
		quit(0)
		return
	for f in failures:
		push_error(f)
	print("FlatBuffers snapshot smoke: FAIL (%d)" % failures.size())
	quit(1)
