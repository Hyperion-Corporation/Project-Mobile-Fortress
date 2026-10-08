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

# Near-immortal combatants so the load survives the whole timed window
# (no deaths mid-run shrinking the world we claim to measure).
const RAIDER_HP := 20000.0
const RAIDER_SPEED := 5.0
const RAIDER_DAMAGE := 6.0
const DEFENDER_HP := 20000.0
const DEFENDER_RANGE := 120.0
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

	sim.queue_free()
	_finish(failures, ceiling_p95)


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

	# Pre-sized sample buffer: no allocation inside the timed loop.
	var samples := PackedInt32Array()
	samples.resize(MEASURED_TICKS)
	for i in MEASURED_TICKS:
		var t0 := Time.get_ticks_usec()
		sim.tick(FIXED_DT, false)
		samples[i] = int(Time.get_ticks_usec() - t0)

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
	return {"load": load, "p95": _quantile(samples, 0.95)}


func _quantile(sorted_samples: PackedInt32Array, p: float) -> int:
	var n := sorted_samples.size()
	var idx := clampi(int(ceil(p * float(n))) - 1, 0, n - 1)
	return sorted_samples[idx]


func _finish(failures: Array[String], ceiling_p95: int) -> void:
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		print("perf_budget_bench: FAIL (%d)" % failures.size())
		quit(1)
		return
	var verdict := "PASS"
	var code := 0
	if ceiling_p95 > SIM_BUDGET_US * GROSS_MULT:
		verdict = "FAIL"
		code = 1
	elif ceiling_p95 > SIM_BUDGET_US:
		verdict = "WARN"
	print(
		"perf_budget_bench: budget p95@%d <= %d us (30 FPS frame/4): p95=%d us -> %s"
		% [CEILING_LOAD, SIM_BUDGET_US, ceiling_p95, verdict]
	)
	quit(code)
