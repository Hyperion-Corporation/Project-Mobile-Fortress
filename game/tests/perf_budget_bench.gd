extends SceneTree
## T44 (P7): headless SimulationCore tick-budget benchmark.
##
## NOT a CI smoke (deliberately not named *_smoke.gd): timing is machine-
## dependent, so it must never gate CI. Run it manually before the VS10
## collaborator playtest and after sim changes to catch gross regressions.
##
## What it does: loads the real slice0 dual-front level through the same
## public SimulationCore API the game uses, builds a dual-front entity load
## (raiders + combat-engaged defenders on both fronts), warms up, then times
## MEASURED_TICKS fixed-dt ticks per load level and reports min / median /
## p95 / p99 / max tick time in microseconds plus the entity counts actually
## reached (so a reader can verify the load was real, not an empty world).
## A second scenario times flow-field recompute directly: on live 8x5 grids
## during combat, solid cells are placed/removed defender-style while flow
## raiders advance, and each set_cell_solid call (which runs the full BFS
## recompute synchronously) is timed with its own percentiles and budget.
##
## Budget: VS-A8 requires 30+ FPS with 10-40 units. One 30 FPS frame is
## 33_333 us; the sim tick is only part of a frame (rendering, HUD sync,
## audio and OS margin take the rest), so this benchmark assigns the sim at
## most ~1/4 of the frame: SIM_BUDGET_US = 8_000. p95 at the 40-unit design
## ceiling is compared against that budget. PASS/WARN still exit 0 (mobile
## hardware and thermal behavior differ — see docs/BENCHMARKS.md); only a
## gross regression (p95 > 3x budget) or a broken setup exits non-zero.
##
## Fails loudly if the native GDExtension did not load: benchmarking a
## fallback backend instead of SimulationCore would be worse than no number.

const LEVEL := "res://assets/levels/slice0_dual_front.json"
const FIXED_DT := 1.0 / 30.0
const WARMUP_TICKS := 200
const MEASURED_TICKS := 2000
const LOAD_LEVELS: Array[int] = [10, 20, 40, 60]
const CEILING_LOAD := 40
const SIM_BUDGET_US := 8000
const GROSS_MULT := 3

# Flow-recompute scenario (P3): placing/removing solid defenders on live
# grids during combat. set_cell_solid runs the whole-front BFS synchronously,
# so the timed call IS the recompute. Same frame-fraction budget as the tick:
# recompute shares the frame with the tick, rendering, and HUD sync.
const FLOW_TOGGLES := 2000
const FLOW_BUDGET_US := 8000
const GRID_SIZE := Vector2i(8, 5)
const OUTPOST_CELL := Vector2i(4, 2)
const FLOW_RAIDERS_PER_FRONT := 10
const FLOW_RAIDER_HP := 20000.0
const FLOW_RAIDER_SPEED := 26.0

var _flow_spawn_idx := 0

# Near-immortal raiders so the load survives the whole timed window
# (no deaths mid-run shrinking the world we claim to measure).
const RAIDER_HP := 20000.0
const RAIDER_SPEED := 5.0
const RAIDER_DAMAGE := 6.0
# Synthetic long reach keeps both fronts firing throughout the moving raid.
const DEFENDER_RANGE := 500.0
const COMBAT_PROBE_TICKS := 60
const DEFENDER_DAMAGE := 6.0
const DEFENDER_COOLDOWN := 1.0
const LANE_END_X := 750.0


func _init() -> void:
	var failures: Array[String] = []
	if not ClassDB.class_exists("SimulationCore"):
		push_error("perf_budget_bench: FAIL — SimulationCore GDExtension class is not registered (native library missing?). Refusing to benchmark a fallback backend.")
		print("perf_budget_bench: FAIL (no native backend)")
		quit(1)
		return
	var sim: Node = ClassDB.instantiate("SimulationCore")
	if not sim.has_method("save_state"):
		push_error("perf_budget_bench: FAIL — SimulationCore instance lacks native-only methods; not the C++ backend.")
		print("perf_budget_bench: FAIL (not native backend)")
		quit(1)
		return
	root.add_child(sim)
	print("perf_budget_bench: backend=native SimulationCore dt=1/30 warmup=%d measured=%d ticks/level" % [WARMUP_TICKS, MEASURED_TICKS])

	var ceiling_p95 := 0
	for load in LOAD_LEVELS:
		var stats: Dictionary = _measure_load(sim, load, failures)
		if not stats.is_empty() and int(stats.get("load", 0)) == CEILING_LOAD:
			ceiling_p95 = int(stats.get("p95", 0))

	var flow_p95 := _measure_flow(sim, failures)

	sim.queue_free()
	_finish(failures, ceiling_p95, flow_p95)


## Builds a `load`-entity dual-front world, warms up, times the tick call
## only, and prints one result line. Returns {"load","p95"} (empty on setup failure).
func _measure_load(sim: Node, load: int, failures: Array[String]) -> Dictionary:
	sim.reset_run(40, 40, 100)
	if not sim.load_level_json(LEVEL):
		failures.append("load_level_json failed for load=%d" % load)
		return {}
	var raiders_total: int = load / 2
	var defenders_total: int = load - raiders_total
	for front in [0, 1]:
		var lane_y := 100.0 + float(front) * 300.0
		var rf: int = raiders_total / 2 + (raiders_total % 2 if front == 0 else 0)
		var df: int = defenders_total / 2 + (defenders_total % 2 if front == 0 else 0)
		for i in rf:
			var start_x := -50.0 + float(i) * 25.0
			var path := PackedVector2Array([Vector2(start_x, lane_y), Vector2(LANE_END_X, lane_y)])
			var rid: int = sim.spawn_raider(front, path, RAIDER_HP, RAIDER_SPEED, RAIDER_DAMAGE)
			if rid <= 0:
				failures.append("spawn_raider failed at load=%d front=%d" % [load, front])
				return {}
		for j in df:
			var dx := Vector2(-50.0 + float(j) * 37.0 + 60.0, lane_y + (40.0 if j % 2 == 0 else -40.0))
			var did: int = sim.spawn_defender(
				front, "spearman", dx, DEFENDER_RANGE, DEFENDER_DAMAGE, DEFENDER_COOLDOWN
			)
			if did < 0:
				failures.append("spawn_defender failed at load=%d front=%d" % [load, front])
				return {}

	var start_raiders: int = sim.get_raider_count()
	var start_defenders: int = sim.get_defender_count()
	if start_raiders + start_defenders != load:
		failures.append(
			"load=%d setup reached %d entities (raiders=%d defenders=%d), not a real %d-entity world"
			% [load, start_raiders + start_defenders, start_raiders, start_defenders, load]
		)
		return {}

	for _w in WARMUP_TICKS:
		sim.tick(FIXED_DT, false)

	var before := _front_totals(sim)
	# Pre-sized sample buffer: no benchmark-side allocation inside the timed loop.
	# The public native tick itself returns an Array of events.
	var samples := PackedInt32Array()
	samples.resize(MEASURED_TICKS)
	for i in MEASURED_TICKS:
		var t0 := Time.get_ticks_usec()
		sim.tick(FIXED_DT, false)
		samples[i] = int(Time.get_ticks_usec() - t0)

	var after := _front_totals(sim)
	_check_activity(before, after, load, "measurement", failures)
	samples.sort()
	var end_total: int = sim.get_raider_count() + sim.get_defender_count()
	var line := (
		"load=%3d start(r=%d d=%d) n=%d | min=%5d med=%5d p95=%5d p99=%5d max=%5d us | end_entities=%d"
		% [
			load, start_raiders, start_defenders, MEASURED_TICKS,
			samples[0], _quantile(samples, 0.50), _quantile(samples, 0.95),
			_quantile(samples, 0.99), samples[samples.size() - 1], end_total,
		]
	)
	print("perf_budget_bench: " + line)
	if end_total != load:
		failures.append("load=%d world decayed to %d entities during measurement" % [load, end_total])
	# Untimed tail probe catches a raid that has moved out of defender range.
	for _probe in COMBAT_PROBE_TICKS:
		sim.tick(FIXED_DT, false)
	_check_activity(after, _front_totals(sim), load, "tail probe", failures)
	return {"load": load, "p95": _quantile(samples, 0.95)}


## Flow-recompute scenario (P3): live 8x5 grids during combat with flow
## raiders advancing, timing each defender-style solid place/remove (each
## call runs the full one-front BFS recompute synchronously). Ticks run
## untimed between timed recomputes so the world stays live. Returns the
## recompute p95, or -1 on setup failure.
func _measure_flow(sim: Node, failures: Array[String]) -> int:
	sim.reset_run(40, 40, 100)
	if not sim.load_level_json(LEVEL):
		failures.append("flow scenario: load_level_json failed")
		return -1
	if not sim.has_method("init_grids") or not sim.has_method("set_cell_solid"):
		failures.append("flow scenario: native grid API missing")
		return -1
	sim.init_grids(GRID_SIZE)
	# Outpost solids mirror BattleRoot._setup_grids.
	sim.set_cell_solid(0, OUTPOST_CELL, true)
	sim.set_cell_solid(1, OUTPOST_CELL, true)
	if not sim.flow_active():
		failures.append("flow scenario: grids not live after init_grids")
		return -1
	# Combat without scheduled waves: only the flow raiders below exist.
	sim.debug_set_waves_disabled(true)
	sim.start_combat()
	for front in [0, 1]:
		for i in FLOW_RAIDERS_PER_FRONT:
			var cell := Vector2i(i % GRID_SIZE.x, (i * 2 + front) % GRID_SIZE.y)
			if cell == OUTPOST_CELL:
				cell = Vector2i((cell.x + 1) % GRID_SIZE.x, cell.y)
			var rid: int = sim.debug_spawn_raider_at(
				front, cell, FLOW_RAIDER_HP, FLOW_RAIDER_SPEED, RAIDER_DAMAGE)
			if rid <= 0:
				failures.append("flow scenario: debug_spawn_raider_at failed front=%d" % front)
				return -1
	if sim.get_raider_count() != 2 * FLOW_RAIDERS_PER_FRONT:
		failures.append("flow scenario: reached %d raiders, not a real %d-raider flow world"
			% [sim.get_raider_count(), 2 * FLOW_RAIDERS_PER_FRONT])
		return -1
	var flow_raiders := 0
	for raider in sim.get_raiders():
		if bool(raider.uses_flow):
			flow_raiders += 1
	if flow_raiders != 2 * FLOW_RAIDERS_PER_FRONT:
		failures.append("flow scenario: %d/%d raiders on flow paths (not measuring recompute)"
			% [flow_raiders, 2 * FLOW_RAIDERS_PER_FRONT])
		return -1

	# Toggle cells defender-style: one full place pass then one full remove
	# pass over the grid (minus the outpost cell), repeated. Varied BFS work,
	# never a permanently walled grid. Each sample below times one call.
	var cells: Array[Vector2i] = []
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			var cell := Vector2i(x, y)
			if cell != OUTPOST_CELL:
				cells.append(cell)
	# Raiders that reach the last column damage the HQ and despawn (that IS
	# the flow path working end to end), so top up untimed to keep the load
	# exact. HQ damage is monotonic and top-up-proof, so it is the liveness
	# signal: a falling HQ proves raiders kept flowing into the target.
	var hq_before: int = sim.get_hq_hp()
	var samples := PackedInt32Array()
	samples.resize(FLOW_TOGGLES)
	for i in FLOW_TOGGLES:
		# One timed sample is exactly one set_cell_solid call (one
		# single-front recompute); fronts alternate sample to sample.
		var front := i % 2
		var step := i / 2
		var cell: Vector2i = cells[step % cells.size()]
		var solid := ((step / cells.size()) % 2 == 0)
		var t0 := Time.get_ticks_usec()
		sim.set_cell_solid(front, cell, solid)
		samples[i] = int(Time.get_ticks_usec() - t0)
		if i % 10 == 9:
			sim.tick(FIXED_DT, false)
			_top_up_flow_raiders(sim, failures)
			if not failures.is_empty():
				return -1
	samples.sort()
	_top_up_flow_raiders(sim, failures)
	if sim.get_raider_count() != 2 * FLOW_RAIDERS_PER_FRONT:
		failures.append("flow scenario: ended with %d raiders, not the full %d-raider load"
			% [sim.get_raider_count(), 2 * FLOW_RAIDERS_PER_FRONT])
	if sim.get_hq_hp() >= hq_before:
		failures.append("flow scenario: HQ took no damage (hq=%d, no raider completed the flow path)"
			% sim.get_hq_hp())
	var p95 := _quantile(samples, 0.95)
	print("perf_budget_bench: flow recomputes=%d raiders=%d | min=%5d med=%5d p95=%5d p99=%5d max=%5d us/recompute"
		% [FLOW_TOGGLES, 2 * FLOW_RAIDERS_PER_FRONT,
			samples[0], _quantile(samples, 0.50), p95,
			_quantile(samples, 0.99), samples[samples.size() - 1]])
	return p95


## Restores the flow scenario to its full raider load (untimed). Spawn
## cells cycle across both grids so replacements keep flowing.
func _top_up_flow_raiders(sim: Node, failures: Array[String]) -> void:
	var want: int = 2 * FLOW_RAIDERS_PER_FRONT - int(sim.get_raider_count())
	for _k in want:
		var front := _flow_spawn_idx % 2
		var cell := Vector2i(
			(_flow_spawn_idx / 2) % GRID_SIZE.x,
			(_flow_spawn_idx * 3 + front) % GRID_SIZE.y)
		_flow_spawn_idx += 1
		if cell == OUTPOST_CELL:
			cell = Vector2i((cell.x + 1) % GRID_SIZE.x, cell.y)
		if sim.debug_spawn_raider_at(front, cell, FLOW_RAIDER_HP, FLOW_RAIDER_SPEED, RAIDER_DAMAGE) <= 0:
			failures.append("flow scenario: top-up spawn failed")
			return


## Snapshot counts, total HP and total x per front outside the timed loop.
func _front_totals(sim: Node) -> Array[Vector3]:
	var totals: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
	for raider in sim.get_raiders():
		var front := int(raider.front)
		totals[front] += Vector3(1.0, float(raider.hp), float(raider.position.x))
	return totals


func _check_activity(before: Array[Vector3], after: Array[Vector3], load: int,
		phase: String, failures: Array[String]) -> void:
	for front in [0, 1]:
		if before[front].x <= 0 or after[front].x != before[front].x:
			failures.append("load=%d front=%d %s: raider count changed or empty" % [load, front, phase])
		if after[front].y >= before[front].y or after[front].z <= before[front].z:
			failures.append("load=%d front=%d %s: no combat damage or movement" % [load, front, phase])


func _quantile(sorted_samples: PackedInt32Array, p: float) -> int:
	var n := sorted_samples.size()
	var idx := clampi(int(ceil(p * float(n))) - 1, 0, n - 1)
	return sorted_samples[idx]


func _finish(failures: Array[String], ceiling_p95: int, flow_p95: int) -> void:
	if flow_p95 < 0:
		failures.append("flow scenario did not produce a measurement")
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		print("perf_budget_bench: FAIL (%d)" % failures.size())
		quit(1)
		return
	var verdict := "PASS"
	var code := 0
	if ceiling_p95 > SIM_BUDGET_US * GROSS_MULT or flow_p95 > FLOW_BUDGET_US * GROSS_MULT:
		verdict = "FAIL"
		code = 1
	elif ceiling_p95 > SIM_BUDGET_US or flow_p95 > FLOW_BUDGET_US:
		verdict = "WARN"
	print(
		"perf_budget_bench: budget p95@%d <= %d us (30 FPS frame/4): p95=%d us -> %s"
		% [CEILING_LOAD, SIM_BUDGET_US, ceiling_p95, verdict]
	)
	print(
		"perf_budget_bench: flow budget p95 <= %d us/recompute: p95=%d us -> %s"
		% [FLOW_BUDGET_US, flow_p95, verdict]
	)
	quit(code)
