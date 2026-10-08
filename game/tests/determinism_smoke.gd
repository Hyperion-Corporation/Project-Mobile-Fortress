extends SceneTree
## T65 (Q4/S7): Godot-boundary determinism smoke.
##
## For every LevelCatalog level, a fixed-dt scripted session (fixed defender
## placements at fixed ticks, combat started at a fixed tick, run past the
## second wave) executes twice in fresh SimulationCore instances, and the two
## full `save_state` buffers must be byte-identical. A third run saves
## mid-wave, loads into a fresh core, and must reach the same end buffer.
## A one-tick perturbation of one placement must change the digest, proving
## the comparison is looking at something. Deterministic and allocation-free
## on the GDScript side; safe as a CI gate.

const LevelCatalogScript := preload("res://scripts/data/level_catalog.gd")
const FIXED_DT := 1.0 / 30.0
const COMBAT_AT_TICK := 60
const GRID_SIZE := Vector2i(8, 5)
const OUTPOST_CELL := Vector2i(4, 2)
const END_MARGIN_S := 6.0
const SAVE_MARGIN_S := 2.0

# Fixed script: [tick, front, x, y]. The negative control shifts the first
# entry by one tick.
const PLACEMENTS := [
	[0, 0, 200.0, 100.0],
	[0, 1, 200.0, 400.0],
	[20, 0, 350.0, 140.0],
	[20, 1, 350.0, 360.0],
	[40, 0, 500.0, 100.0],
	[40, 1, 500.0, 400.0],
]


func _init() -> void:
	var wall_start := Time.get_ticks_msec()
	var failures: Array[String] = []
	if not ClassDB.class_exists("SimulationCore"):
		failures.append("SimulationCore GDExtension class is not registered (native library missing?)")
		_finish(failures, wall_start)
		return
	var levels: Array = LevelCatalogScript.list_levels()
	if levels.is_empty():
		failures.append("LevelCatalog.list_levels() returned no levels")
	for entry in levels:
		_check_level(entry, failures)
	_finish(failures, wall_start)


func _check_level(entry: Dictionary, failures: Array[String]) -> void:
	var path := str(entry.get("path", ""))
	var level_id := str(entry.get("id", path))
	if path.is_empty():
		failures.append("catalog entry missing path: %s" % str(entry))
		return
	var waves: Array = _level_waves(path, failures)
	if waves.size() < 2:
		failures.append("%s: need at least two waves for the determinism script" % path)
		return
	var combat_ticks := int(ceil((float(waves[1]["delaySeconds"]) + END_MARGIN_S) / FIXED_DT))
	var save_tick := COMBAT_AT_TICK + int(ceil((float(waves[1]["delaySeconds"]) + SAVE_MARGIN_S) / FIXED_DT))

	var first := _scripted_run(path, combat_ticks, 0, -1, failures)
	var second := _scripted_run(path, combat_ticks, 0, -1, failures)
	if failures.is_empty():
		if first["waves_fired"] < 2 or second["waves_fired"] < 2:
			failures.append("%s: script covered fewer than two waves (%d/%d)" % [path, first["waves_fired"], second["waves_fired"]])
		elif first["buf"] != second["buf"]:
			failures.append("%s: identical scripts diverged (%s vs %s)" % [path, _digest(first["buf"]), _digest(second["buf"])])
		else:
			print("Determinism smoke: %s match other (%s, %d bytes, %d waves)" % [level_id, _digest(first["buf"]), (first["buf"] as PackedByteArray).size(), first["waves_fired"]])

	var resumed := _scripted_run(path, combat_ticks, 0, save_tick, failures)
	if failures.is_empty() and resumed["buf"] != first["buf"]:
		failures.append("%s: save/load mid-wave diverged (%s vs %s)" % [path, _digest(resumed["buf"]), _digest(first["buf"])])

	var perturbed := _scripted_run(path, combat_ticks, 1, -1, failures)
	if failures.is_empty() and perturbed["buf"] == first["buf"]:
		failures.append("%s: one-tick placement shift left the digest unchanged (comparison is blind)" % path)


## Runs the fixed script. `shift` delays the first placement by that many
## ticks (negative control). `save_tick >= 0` snapshots there and resumes in
## a fresh core. Returns {"buf", "waves_fired"} (empty buf on setup failure).
func _scripted_run(path: String, combat_ticks: int, shift: int, save_tick: int, failures: Array[String]) -> Dictionary:
	var sim: Node = _fresh_setup(path, failures)
	if sim == null:
		return {"buf": PackedByteArray(), "waves_fired": 0}
	var total := COMBAT_AT_TICK + combat_ticks
	var tick_counter := 0
	while tick_counter < total:
		if tick_counter == save_tick:
			var snapshot: PackedByteArray = sim.save_state()
			sim.queue_free()
			sim = _fresh_setup(path, failures)
			if sim == null:
				return {"buf": PackedByteArray(), "waves_fired": 0}
			if not sim.load_state(snapshot):
				failures.append("%s: mid-wave load_state failed" % path)
				sim.queue_free()
				return {"buf": PackedByteArray(), "waves_fired": 0}
		if tick_counter == COMBAT_AT_TICK:
			sim.start_combat()
		for i in PLACEMENTS.size():
			var scheduled: int = int(PLACEMENTS[i][0]) + (shift if i == 0 else 0)
			if scheduled == tick_counter:
				sim.spawn_defender(int(PLACEMENTS[i][1]), "spearman",
					Vector2(float(PLACEMENTS[i][2]), float(PLACEMENTS[i][3])), 120.0, 6.0, 1.0)
		sim.tick(FIXED_DT, true)
		tick_counter += 1
	var result := {"buf": sim.save_state(), "waves_fired": int(sim.get_current_wave())}
	sim.queue_free()
	return result


func _fresh_setup(path: String, failures: Array[String]) -> Node:
	var sim: Node = ClassDB.instantiate("SimulationCore")
	root.add_child(sim)
	if not sim.load_level_json(path):
		failures.append("%s: load_level_json failed" % path)
		sim.queue_free()
		return null
	# Grid setup mirrors BattleRoot so waves run on live flow fields.
	sim.init_grids(GRID_SIZE)
	sim.set_cell_solid(0, OUTPOST_CELL, true)
	sim.set_cell_solid(1, OUTPOST_CELL, true)
	return sim


func _level_waves(path: String, failures: Array[String]) -> Array:
	if not FileAccess.file_exists(path):
		failures.append("missing level file: %s" % path)
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not (parsed as Dictionary).has("waves"):
		failures.append("%s: no waves array" % path)
		return []
	return ((parsed as Dictionary)["waves"] as Array)


func _digest(buf: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(buf)
	return (ctx.finish() as PackedByteArray).hex_encode().left(16)


func _finish(failures: Array[String], wall_start: int) -> void:
	var wall_s := float(Time.get_ticks_msec() - wall_start) / 1000.0
	if failures.is_empty():
		print("Determinism smoke: PASS (%.1fs wall)" % wall_s)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Determinism smoke: FAIL (%d, %.1fs wall)" % [failures.size(), wall_s])
		quit(1)
