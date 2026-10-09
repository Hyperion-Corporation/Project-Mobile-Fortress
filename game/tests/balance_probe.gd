extends SceneTree
## T73 (A4 tuning input, Q10 prep): manual scripted balance probe.
##
## NOT a smoke (deliberately not named *_smoke.gd): results are balance data,
## not pass/fail gates, and runtimes are machine-dependent. Never wire into
## CI. Run via scripts/run_balance_probe.sh or directly:
##   godot --path game --headless --script res://tests/balance_probe.gd
##
## For every catalog level × 5 fixed strategies (none, land-only, sea-only,
## balanced cheap, heroes + Signal Battery) × DDA off/on, a fixed-dt run
## plays to the end through SimulationCore. Placements happen pre-combat at
## fixed ticks; the probe enforces wallets from the level's starting
## currencies with UnitDefs.placement_plan (the real affordability rule) and
## spawns with the real battle conversions (range×48, aura×48). Hero active
## abilities are never cast — a stated bot limitation. Reports per run:
## victory/defeat, combat time, HQ HP left, outposts lost, stars (pure
## Progression.compute_stars), kills, currency unspent, DDA min/max
## intensity. Sanity assertions only: no-defender runs must lose, one repeat
## must be identical, DDA engagement is reported not asserted.

const LevelCatalogScript := preload("res://scripts/data/level_catalog.gd")
const FIXED_DT := 1.0 / 30.0
const COMBAT_AT_TICK := 30
const END_MARGIN_S := 60.0
const GRID_SIZE := Vector2i(8, 5)
const OUTPOST_CELL := Vector2i(4, 2)

# [unit_id, front 0=land/1=sea, cell]. Priority order; wallet-gated.
const STRATS := {
	"none": [],
	"land": [
		["spearman", 0, Vector2i(1, 1)],
		["spearman", 0, Vector2i(5, 1)],
		["spearman", 0, Vector2i(2, 3)],
		["cannon", 0, Vector2i(6, 3)],
	],
	"sea": [
		["arquebusier", 1, Vector2i(1, 1)],
		["arquebusier", 1, Vector2i(5, 1)],
		["junk", 1, Vector2i(2, 3)],
	],
	"cheap": [
		["spearman", 0, Vector2i(1, 1)],
		["arquebusier", 1, Vector2i(1, 1)],
		["spearman", 0, Vector2i(5, 3)],
		["arquebusier", 1, Vector2i(5, 3)],
	],
	"heroes": [
		["hero_qi", 0, Vector2i(3, 1)],
		["hero_dias", 1, Vector2i(3, 3)],
		["cross_support", 0, Vector2i(1, 3)],
		["spearman", 0, Vector2i(6, 1)],
		["arquebusier", 1, Vector2i(6, 1)],
	],
}
const STRAT_ORDER := ["none", "land", "sea", "cheap", "heroes"]


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
		_finish(failures, wall_start)
		return
	print("balance_probe: level | strat | dda | outcome | t(s) | hq | out_lost | stars | kills | unspent L/S | intensity min-max")
	var dda_engaged := false
	for entry in levels:
		var path := str(entry.get("path", ""))
		var level_id := str(entry.get("id", path))
		for strat in STRAT_ORDER:
			for dda in [false, true]:
				var row: Dictionary = _play_run(path, strat, dda, failures)
				if row.is_empty():
					continue
				_print_row(level_id, strat, dda, row)
				if bool(row.get("dda_moved", false)):
					dda_engaged = true
				if strat == "none" and not dda and bool(row.get("victory", false)):
					failures.append("%s: no-defender run won — the probe is wrong, not the game" % level_id)
		# Sanity: one strategy repeated must be identical.
		var a := _play_run(path, "cheap", false, failures)
		var b := _play_run(path, "cheap", false, failures)
		if not a.is_empty() and not b.is_empty() and a["digest"] != b["digest"]:
			failures.append("%s: repeated cheap/DDA-off run diverged" % level_id)
	if not dda_engaged:
		print("balance_probe: NOTE dda_never_engaged — no DDA-on run differed from its DDA-off twin; see BENCHMARKS.md for why")
	else:
		print("balance_probe: NOTE dda_engaged — at least one DDA-on run differed from its DDA-off twin")
	_finish(failures, wall_start)


## Plays one full run. Returns the report row (empty on setup failure).
func _play_run(path: String, strat: String, dda: bool, failures: Array[String]) -> Dictionary:
	var sim: Node = ClassDB.instantiate("SimulationCore")
	root.add_child(sim)
	if not sim.load_level_json(path):
		failures.append("%s: load_level_json failed" % path)
		sim.queue_free()
		return {}
	sim.init_grids(GRID_SIZE)
	sim.set_cell_solid(0, OUTPOST_CELL, true)
	sim.set_cell_solid(1, OUTPOST_CELL, true)
	sim.set_dda_enabled(dda)
	var land: int = sim.get_land_resources()
	var sea: int = sim.get_sea_resources()
	var want: Array = STRATS[strat]
	var queue: Array = want.duplicate()
	var placed := 0
	var spent := 0
	var intensity_min := 1.0
	var intensity_max := 1.0
	var victory := false
	var defeat := false
	var cap := COMBAT_AT_TICK + int(ceil((float(sim.get_victory_time()) + END_MARGIN_S) / FIXED_DT))
	var tick_counter := 0
	var end_tick := cap
	while tick_counter < cap:
		if tick_counter < COMBAT_AT_TICK and not queue.is_empty() and tick_counter % 5 == 0:
			var order: Array = queue.pop_front()
			var plan: Dictionary = UnitDefs.placement_plan(str(order[0]), "land" if int(order[1]) == 0 else "sea", land, sea)
			if bool(plan.get("allowed", false)) and str(plan.get("wallet", "")) != "":
				var cost: int = int(plan.get("cost", 0))
				if str(plan.get("wallet", "")) == "land":
					land -= cost
				else:
					sea -= cost
				_place(sim, str(order[0]), int(order[1]), order[2])
				placed += 1
				spent += cost
		if tick_counter == COMBAT_AT_TICK:
			sim.start_combat()
		var events: Array = sim.tick(FIXED_DT, true)
		if dda:
			var intensity := float(sim.get_dda_intensity())
			intensity_min = minf(intensity_min, intensity)
			intensity_max = maxf(intensity_max, intensity)
		for ev in events:
			if ev is Dictionary and str(ev.get("type", "")) == "victory":
				victory = true
				end_tick = tick_counter
			elif ev is Dictionary and str(ev.get("type", "")) == "hq_destroyed":
				defeat = true
				end_tick = tick_counter
		tick_counter += 1
		if victory or defeat:
			break
	var outposts_lost := (0 if sim.is_land_outpost_alive() else 1) + (0 if sim.is_sea_outpost_alive() else 1)
	var hq: int = sim.get_hq_hp()
	var stars: int = Progression.compute_stars({
		"victory": victory, "outposts_lost": outposts_lost,
		"hq_hp": hq, "hq_max_hp": int(sim.get_hq_max_hp())})
	var digest := _digest(sim.save_state())
	var row := {
		"victory": victory, "defeat": defeat,
		"t": snappedf(float(end_tick - COMBAT_AT_TICK) * FIXED_DT, 0.1),
		"hq": hq, "outposts_lost": outposts_lost, "stars": stars,
		"kills": int(sim.get_enemies_killed()),
		"land_left": int(sim.get_land_resources()), "sea_left": int(sim.get_sea_resources()),
		"placed": placed, "spent": spent,
		"int_min": snappedf(intensity_min, 0.01), "int_max": snappedf(intensity_max, 0.01),
		"dda_moved": dda and (intensity_min < 1.0 or intensity_max > 1.0),
		"digest": digest,
	}
	sim.queue_free()
	return row


func _place(sim: Node, unit_id: String, front: int, cell: Vector2i) -> void:
	var def: Dictionary = UnitDefs.get_def(unit_id)
	var base_y := 200.0 if front == 0 else 600.0
	var pos := Vector2(300.0 + float(cell.x - cell.y) * 32.0, base_y + float(cell.x + cell.y) * 16.0)
	var did: int = sim.spawn_defender(front, unit_id, pos,
		float(def.get("range", 1.5)) * 48.0, float(def.get("damage", 10.0)),
		float(def.get("cooldown", 1.0)), float(def.get("own_env_mult", 1.0)),
		float(def.get("cross_env_mult", 0.0)),
		float(def.get("aura_radius", 0.0)) * 48.0, float(def.get("aura_damage_bonus", 0.0)))
	if did >= 0 and int(def.get("kind", UnitDefs.Kind.DEFENDER)) != UnitDefs.Kind.HERO:
		sim.set_cell_solid(front, cell, true)


func _print_row(level_id: String, strat: String, dda: bool, row: Dictionary) -> void:
	var outcome := "timeout"
	if bool(row.get("victory", false)):
		outcome = "victory"
	elif bool(row.get("defeat", false)):
		outcome = "defeat"
	print("balance_probe: %s | %s | %s | %s | %.1f | %d | %d | %d | %d | %d/%d | %.2f-%.2f" % [
		level_id, strat, "on" if dda else "off", outcome, float(row.get("t", 0.0)),
		int(row.get("hq", 0)), int(row.get("outposts_lost", 0)), int(row.get("stars", 0)),
		int(row.get("kills", 0)), int(row.get("land_left", 0)), int(row.get("sea_left", 0)),
		float(row.get("int_min", 1.0)), float(row.get("int_max", 1.0))])


func _digest(buf: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(buf)
	return (ctx.finish() as PackedByteArray).hex_encode().left(16)


func _finish(failures: Array[String], wall_start: int) -> void:
	var wall_s := float(Time.get_ticks_msec() - wall_start) / 1000.0
	if failures.is_empty():
		print("balance_probe: DONE (%.1fs wall)" % wall_s)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("balance_probe: FAIL (%d, %.1fs wall)" % [failures.size(), wall_s])
		quit(1)
