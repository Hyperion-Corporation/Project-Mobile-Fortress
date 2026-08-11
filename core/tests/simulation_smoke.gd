extends SceneTree
## Headless contract test for the Godot↔C++ Slice-0 simulation bridge.

func _init() -> void:
	var failures: Array[String] = []
	if not ClassDB.class_exists("SimulationCore"):
		failures.append("SimulationCore class is not registered")
		_finish(failures)
		return

	var sim: Node = ClassDB.instantiate("SimulationCore")
	root.add_child(sim)
	sim.reset_run(10, 20, 100)
	if sim.get_land_resources() != 10 or sim.get_sea_resources() != 20:
		failures.append("reset_run did not set front resources")
	if not sim.spend(0, 4) or sim.get_land_resources() != 6:
		failures.append("land resource spend failed")
	if sim.spend(1, 25):
		failures.append("overspend was accepted")

	var path := PackedVector2Array([Vector2(0, 0), Vector2(10, 0)])
	var raider_id: int = sim.spawn_raider(0, path, 12.0, 20.0, 7.0)
	if raider_id <= 0 or sim.get_raider_count() != 1:
		failures.append("raider spawn failed")
	sim.damage_raider(raider_id, 5.0)
	if sim.get_raiders().size() != 1:
		failures.append("partial raider damage removed the raider")
	sim.damage_raider(raider_id, 7.0)
	if sim.get_raider_count() != 0 or sim.get_enemies_killed() != 1:
		failures.append("raider death accounting failed")

	# HQ hit on short path
	var second_id: int = sim.spawn_raider(1, path, 10.0, 40.0, 7.0)
	if second_id <= 0:
		failures.append("second raider spawn failed")
	sim.tick(0.5, false)
	var events: Array = sim.tick(0.5, false)
	var saw_hq_hit := false
	for event in events:
		if event is Dictionary and event.get("type", "") == "hq_hit":
			saw_hq_hit = true
	if not saw_hq_hit or sim.get_hq_hp() != 93:
		failures.append("raider HQ-hit event or damage was incorrect")

	# Outpost mid-path strike is deterministic
	sim.reset_run(10, 20, 100)
	var long_path := PackedVector2Array([
		Vector2(0, 0), Vector2(20, 0), Vector2(40, 0), Vector2(60, 0), Vector2(80, 0)
	])
	# Force outpost waypoint at index 2; HP 40, strike max(4, damage)
	var oid: int = sim.spawn_raider(0, long_path, 30.0, 200.0, 10.0, 2)
	if oid <= 0:
		failures.append("outpost-test raider spawn failed")
	var saw_outpost := false
	var saw_lost := false
	for _i in 40:
		var evs: Array = sim.tick(0.05, false)
		for event in evs:
			if not event is Dictionary:
				continue
			var t: String = str(event.get("type", ""))
			if t == "outpost_damaged":
				saw_outpost = true
			if t == "outpost_lost":
				saw_lost = true
	if not saw_outpost:
		failures.append("expected outpost_damaged event on mid-path")
	if sim.get_land_outpost_hp() >= 40:
		failures.append("outpost HP did not decrease after strike")
	# Burn remaining outpost HP with more strikers
	for _j in 6:
		sim.spawn_raider(0, long_path, 20.0, 400.0, 10.0, 2)
		for _k in 30:
			var evs2: Array = sim.tick(0.05, false)
			for event in evs2:
				if event is Dictionary and str(event.get("type", "")) == "outpost_lost":
					saw_lost = true
	if not saw_lost or sim.is_land_outpost_alive():
		failures.append("expected outpost_lost after sustained strikes")
	# Economic only: HQ still alive after outpost loss
	if sim.get_hq_hp() <= 0:
		failures.append("outpost loss must not auto-destroy HQ")

	# Defenders: spawn + auto combat
	sim.reset_run(40, 40, 100)
	var did: int = sim.spawn_defender(0, "spearman", Vector2(30, 0), 80.0, 20.0, 0.2, 1.0, 0.0, 0.0, 0.0)
	if did < 0 or sim.get_defender_count() != 1:
		failures.append("spawn_defender failed")
	var rpath := PackedVector2Array([Vector2(0, 0), Vector2(100, 0)])
	sim.spawn_raider(0, rpath, 15.0, 5.0, 1.0, 99) # no outpost strike
	for _t in 40:
		sim.tick(0.1, false)
	if sim.get_enemies_killed() < 1:
		failures.append("defender combat did not kill nearby raider")

	# Commander Qi active ability and cooldown contract
	sim.reset_run(40, 40, 100)
	var hero_id: int = sim.spawn_defender(
		0, "hero_qi", Vector2(0, 0), 100.0, 12.0, 1.0, 1.0, 0.5, 100.0, 0.25
	)
	var pulse_path := PackedVector2Array([Vector2(50, 0), Vector2(100, 0)])
	sim.spawn_raider(0, pulse_path, 20.0, 5.0, 1.0, 99)
	var pulse: Dictionary = sim.cast_hero_ability(hero_id)
	if not pulse.get("success", false) or int(pulse.get("hits", 0)) != 1:
		failures.append("hero pulse did not hit a nearby raider")
	var cooldown_pulse: Dictionary = sim.cast_hero_ability(hero_id)
	if cooldown_pulse.get("reason", "") != "on_cooldown":
		failures.append("hero pulse cooldown was not enforced")

	# Cross-front damage is amplified by a nearby commander aura
	sim.reset_run(40, 40, 100)
	sim.spawn_defender(
		0, "hero_qi", Vector2(0, 0), 0.0, 0.0, 1.0, 0.0, 0.0, 100.0, 0.25
	)
	sim.spawn_defender(
		0, "cross_support", Vector2(0, 0), 100.0, 10.0, 0.1, 0.5, 1.0, 0.0, 0.0
	)
	var cross_path := PackedVector2Array([Vector2(50, 0), Vector2(100, 0)])
	sim.spawn_raider(1, cross_path, 20.0, 0.0, 1.0, 99)
	sim.tick(0.1, false)
	var cross_raiders: Array = sim.get_raiders()
	if cross_raiders.is_empty() or float(cross_raiders[0].get("hp", 20.0)) >= 10.0:
		failures.append("cross-front damage or commander aura was not applied")

	# Level JSON + C++-owned wave spawn
	sim.reset_run(40, 40, 100)
	if not sim.load_level_json("res://assets/levels/slice0_dual_front.json"):
		failures.append("load_level_json failed")
	elif sim.get_wave_count() < 2:
		failures.append("level JSON did not load waves")
	else:
		var lane := PackedVector2Array([Vector2(0, 0), Vector2(40, 0), Vector2(80, 0)])
		sim.set_lane_path(0, lane)
		sim.set_lane_path(1, lane)
		sim.spawn_defender(0, "spearman", Vector2(20, 0), 50.0, 10.0, 0.5)
		sim.start_combat()
		for _t in 40:
			sim.tick(0.1, false)
		if sim.get_current_wave() < 1 and sim.get_raider_count() < 1:
			failures.append("C++ wave spawn after start_combat failed")

	sim.queue_free()
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("SimulationCore smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("SimulationCore smoke: FAIL (%d)" % failures.size())
		quit(1)
