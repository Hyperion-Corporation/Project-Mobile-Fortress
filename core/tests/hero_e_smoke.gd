extends SceneTree
## T23 follow-up: E must fire every *ready* hero even if another is on cooldown.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	await _assert_ready_hero_still_fires(failures, "hero_qi", "hero_dias",
			"E skipped ready Dias while Qi was on cooldown")
	await _assert_ready_hero_still_fires(failures, "hero_dias", "hero_qi",
			"E skipped ready Qi while Dias was on cooldown")
	_finish(failures)


func _assert_ready_hero_still_fires(
		failures: Array[String], cooling_type: String, ready_type: String, fail_msg: String
) -> void:
	var scene = load("res://scenes/battle/battle.tscn")
	if scene == null:
		failures.append("could not load battle.tscn")
		return
	var battle = scene.instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame

	if not _place_hero(battle, cooling_type, "land"):
		failures.append("could not place %s" % cooling_type)
		battle.queue_free()
		return
	if not _place_hero(battle, ready_type, "sea"):
		failures.append("could not place %s" % ready_type)
		battle.queue_free()
		return

	battle._start_combat()
	if int(battle.phase) != int(battle.Phase.COMBAT):
		failures.append("combat did not start for %s/%s" % [cooling_type, ready_type])
		battle.queue_free()
		return

	var cooling_id := _hero_id(battle, cooling_type)
	var ready_id := _hero_id(battle, ready_type)
	if cooling_id < 0 or ready_id < 0:
		failures.append("missing hero ids for %s/%s" % [cooling_type, ready_type])
		battle.queue_free()
		return

	battle.sim.cast_hero_ability(cooling_id)
	if float(_cooldown(battle, cooling_id)) <= 0.0:
		failures.append("%s did not enter cooldown before E" % cooling_type)
		battle.queue_free()
		return
	if float(_cooldown(battle, ready_id)) > 0.0:
		failures.append("%s was not ready before E" % ready_type)
		battle.queue_free()
		return

	battle._hero_ability()
	if float(_cooldown(battle, ready_id)) <= 0.0:
		failures.append(fail_msg)

	battle.queue_free()
	await process_frame


func _place_hero(battle, unit_id: String, front: String) -> bool:
	var grid = battle.land_grid if front == "land" else battle.sea_grid
	battle.selected_unit_id = unit_id
	for x in range(0, 8):
		for y in range(0, 5):
			var cell := Vector2i(x, y)
			if grid.is_placeable(cell):
				battle._on_cell_clicked(front, cell)
				return _hero_id(battle, unit_id) >= 0
	return false


func _hero_id(battle, unit_id: String) -> int:
	for defender in battle.sim.get_defenders():
		if str(defender.get("type", "")) == unit_id:
			return int(defender.get("id", -1))
	return -1


func _cooldown(battle, hero_id: int) -> float:
	for defender in battle.sim.get_defenders():
		if int(defender.get("id", -1)) == hero_id:
			return float(defender.get("ability_cooldown_left", 0.0))
	return 0.0


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Hero E smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Hero E smoke: FAIL (%d)" % failures.size())
		quit(1)
