extends SceneTree
## A4: SimulationCore heuristic DDA toggle, intensity readout, and wave scaling.

const LEVEL := "res://assets/levels/slice0_dual_front.json"


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
	if not session.has_method("set_dda_enabled") or not session.has_method("apply_dda"):
		failures.append("GameSession DDA toggle is missing")
		_finish(failures)
		return
	if session.dda_enabled:
		failures.append("GameSession DDA should default off")

	var sim: Node = ClassDB.instantiate("SimulationCore")
	sim.name = "SimulationCore"
	root.add_child(sim)
	for method in ["set_dda_enabled", "dda_enabled", "get_dda_intensity"]:
		if not sim.has_method(method):
			failures.append("SimulationCore missing %s" % method)
	if not failures.is_empty():
		_finish(failures)
		return

	sim.reset_run(14, 14, 100)
	if sim.dda_enabled() or not is_equal_approx(sim.get_dda_intensity(), 1.0):
		failures.append("director should default off at intensity 1")
	sim.damage_hq(80)
	if not is_equal_approx(sim.get_dda_intensity(), 1.0):
		failures.append("disabled director changed intensity while HQ was low")

	session.set_dda_enabled(true)
	session.apply_dda(sim)
	if not session.dda_enabled or not sim.dda_enabled():
		failures.append("apply_dda did not enable the director")
	session.reset_run()
	if not session.dda_enabled:
		failures.append("GameSession.reset_run cleared the DDA preference")
	sim.reset_run(14, 14, 100)
	if not sim.dda_enabled():
		failures.append("SimulationCore.reset_run cleared the director flag")
	session.set_dda_enabled(false)
	session.apply_dda(sim)
	if sim.dda_enabled():
		failures.append("apply_dda did not disable the director")

	var losing := _fresh_sim()
	var baseline := _fresh_sim()
	if not _load(losing) or not _load(baseline):
		failures.append("slice0 level JSON did not load")
		_finish(failures)
		return
	_collapse(losing)
	_collapse(baseline)
	losing.set_dda_enabled(true)
	baseline.set_dda_enabled(false)
	if not is_equal_approx(losing.get_dda_intensity(), 0.75):
		failures.append("losing run did not clamp intensity to 0.75 (got %s)" % losing.get_dda_intensity())
	if not is_equal_approx(baseline.get_dda_intensity(), 1.0):
		failures.append("disabled twin intensity was not 1")
	losing.start_combat()
	baseline.start_combat()
	losing.tick(2.0, false)
	baseline.tick(2.0, false)
	var losing_hp := _hps(losing)
	var base_hp := _hps(baseline)
	if losing.get_raider_count() >= baseline.get_raider_count():
		failures.append("losing director did not reduce the unspawned wave count (%d vs %d)" % [losing.get_raider_count(), baseline.get_raider_count()])
	if losing_hp.is_empty() or base_hp.is_empty() or float(losing_hp[0]) >= float(base_hp[0]):
		failures.append("losing director did not reduce raider HP")
	if base_hp.is_empty() or not is_equal_approx(float(base_hp[0]), 50.0):
		failures.append("disabled wave HP was not the authored 50")

	var rich_a := _fresh_sim()
	var rich_b := _fresh_sim()
	if not _load(rich_a) or not _load(rich_b):
		failures.append("dominating level load failed")
		_finish(failures)
		return
	var intensity_a := _dominate(rich_a)
	var intensity_b := _dominate(rich_b)
	if not is_equal_approx(intensity_a, intensity_b) or not is_equal_approx(intensity_a, 1.25):
		failures.append("dominating runs were not deterministic at the 1.25 cap (%s vs %s)" % [intensity_a, intensity_b])
	var hps_a := _hps(rich_a)
	var hps_b := _hps(rich_b)
	if hps_a != hps_b:
		failures.append("dominating runs diverged in raider HP")
	if rich_a.get_raider_count() != rich_b.get_raider_count() or rich_a.get_raider_count() <= 8:
		failures.append("dominating wave was not scaled up (count %d)" % rich_a.get_raider_count())
	if hps_a.is_empty() or not is_equal_approx(float(hps_a[0]), 66.25):
		failures.append("dominating wave HP was not 53 * 1.25")

	var off_a := _fresh_sim()
	var off_b := _fresh_sim()
	_load(off_a)
	_load(off_b)
	off_b.set_dda_enabled(false)
	_collapse(off_a)
	_collapse(off_b)
	off_a.start_combat()
	off_b.start_combat()
	for _i in 90:
		off_a.tick(1.0 / 30.0, true)
		off_b.tick(1.0 / 30.0, true)
	if off_a.get_hq_hp() != off_b.get_hq_hp() or off_a.get_raider_count() != off_b.get_raider_count() or _hps(off_a) != _hps(off_b):
		failures.append("explicit disable diverged from the default-off baseline")

	session.set_dda_enabled(false)
	_finish(failures)


func _fresh_sim() -> Node:
	var sim: Node = ClassDB.instantiate("SimulationCore")
	root.add_child(sim)
	return sim


func _load(sim: Node) -> bool:
	if not sim.load_level_json(LEVEL):
		return false
	var lane := PackedVector2Array([Vector2(0, 0), Vector2(800, 0)])
	sim.set_lane_path(0, lane)
	sim.set_lane_path(1, lane)
	return true


func _collapse(sim: Node) -> void:
	sim.damage_hq(sim.get_hq_hp())
	sim.set_outpost_alive(0, false)
	sim.set_outpost_alive(1, false)
	sim.spend(0, sim.get_land_resources())
	sim.spend(1, sim.get_sea_resources())


func _dominate(sim: Node) -> float:
	sim.set_dda_enabled(true)
	sim.gain(0, 200)
	sim.gain(1, 200)
	sim.start_combat()
	sim.tick(2.0, false)
	sim.debug_kill_all_raiders()
	sim.tick(0.05, false)
	var intensity := float(sim.get_dda_intensity())
	sim.tick(10.0, false)
	return intensity


func _hps(sim: Node) -> Array:
	var hps: Array = []
	for raider in sim.get_raiders():
		hps.append(float(raider.get("hp", -1.0)))
	hps.sort()
	return hps


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("DDA smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("DDA smoke: FAIL (%d)" % failures.size())
		quit(1)
