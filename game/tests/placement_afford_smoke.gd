extends SceneTree
## T61: battle uses UnitDefs.placement_plan; main menu shows citadel rank + campaign stars.
## Mutation that removes the other-grid wallet fallback in placement_plan must fail
## the Qi-on-sea / 0-land placement assertion below.

const ProgressionScript := preload("res://scripts/data/progression.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_helper(failures)
	await _check_battle(failures)
	await _check_menu(failures)
	_finish(failures)


func _check_helper(failures: Array[String]) -> void:
	var rows := [
		{"id": "spearman", "front": "land", "land": 10, "sea": 0, "wallet": "land", "spawn": "land"},
		{"id": "spearman", "front": "sea", "land": 40, "sea": 40, "wallet": "", "spawn": ""},
		{"id": "cannon", "front": "land", "land": 18, "sea": 0, "wallet": "land", "spawn": "land"},
		{"id": "arquebusier", "front": "sea", "land": 0, "sea": 12, "wallet": "sea", "spawn": "sea"},
		{"id": "arquebusier", "front": "land", "land": 40, "sea": 40, "wallet": "", "spawn": ""},
		{"id": "junk", "front": "sea", "land": 0, "sea": 16, "wallet": "sea", "spawn": "sea"},
		{"id": "hero_qi", "front": "land", "land": 28, "sea": 0, "wallet": "land", "spawn": "land"},
		{"id": "hero_qi", "front": "land", "land": 0, "sea": 40, "wallet": "", "spawn": ""},
		{"id": "hero_qi", "front": "sea", "land": 0, "sea": 28, "wallet": "sea", "spawn": "sea"},
		{"id": "hero_dias", "front": "sea", "land": 0, "sea": 26, "wallet": "sea", "spawn": "sea"},
		{"id": "hero_dias", "front": "land", "land": 26, "sea": 0, "wallet": "land", "spawn": "land"},
		{"id": "hero_dias", "front": "sea", "land": 40, "sea": 0, "wallet": "", "spawn": ""},
		{"id": "cross_support", "front": "sea", "land": 0, "sea": 20, "wallet": "sea", "spawn": "sea"},
		{"id": "cross_support", "front": "land", "land": 20, "sea": 0, "wallet": "land", "spawn": "land"},
		{"id": "cross_support", "front": "sea", "land": 20, "sea": 0, "wallet": "", "spawn": ""},
	]
	for row in rows:
		var plan: Dictionary = UnitDefs.placement_plan(
			str(row["id"]), str(row["front"]), int(row["land"]), int(row["sea"])
		)
		var want: String = str(row["wallet"])
		var got := str(plan.get("wallet", ""))
		if got != want:
			failures.append("%s on %s land=%d sea=%d wallet=%s want %s" % [
				row["id"], row["front"], row["land"], row["sea"], got, want
			])
		if want == "":
			continue
		if not bool(plan.get("allowed", false)):
			failures.append("%s on %s should be allowed" % [row["id"], row["front"]])


func _check_battle(failures: Array[String]) -> void:
	if not ClassDB.class_exists("SimulationCore"):
		failures.append("SimulationCore not registered")
		return
	var scene = load("res://scenes/battle/battle.tscn")
	if scene == null:
		failures.append("could not load battle.tscn")
		return
	var battle = scene.instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	if battle.sim == null:
		failures.append("battle.sim is null")
		battle.queue_free()
		return

	# Mutation target: placement_plan fallback (Qi on sea, 0 land, enough sea).
	if battle.sim.has_method("debug_set_resources"):
		battle.sim.debug_set_resources(0, 0)
		battle.sim.debug_set_resources(1, 40)
	var land_before: int = battle.sim.get_land_resources()
	var sea_before: int = battle.sim.get_sea_resources()
	var sea_cell := _first_placeable(battle.sea_grid)
	if sea_cell.x < 0:
		failures.append("no placeable sea cell")
	else:
		battle.selected_unit_id = "hero_qi"
		battle._on_cell_clicked("sea", sea_cell)
		var qi_id := -1
		var qi_front := -1
		for defender in battle.sim.get_defenders():
			if str(defender.get("type", "")) == "hero_qi":
				qi_id = int(defender.get("id", -1))
				qi_front = int(defender.get("front", -1))
				break
		if qi_id < 0:
			failures.append("battle did not place Qi on sea via placement_plan fallback")
		elif qi_front != 1:
			failures.append("Qi spawn front was %d, want sea (1)" % qi_front)
		if battle.sim.get_land_resources() != land_before:
			failures.append("Qi sea-fallback charged land (was %d now %d)" % [
				land_before, battle.sim.get_land_resources()
			])
		if battle.sim.get_sea_resources() != sea_before - 28:
			failures.append("Qi sea-fallback should spend 28 sea (was %d now %d)" % [
				sea_before, battle.sim.get_sea_resources()
			])

	# Same-front land unit: surplus sea must not pay.
	if battle.sim.has_method("debug_set_resources"):
		battle.sim.debug_set_resources(0, 9)
		battle.sim.debug_set_resources(1, 100)
	var land_cell := _first_placeable(battle.land_grid)
	var defs_before: int = battle.sim.get_defender_count()
	if land_cell.x < 0:
		failures.append("no placeable land cell")
	else:
		battle.selected_unit_id = "spearman"
		battle._on_cell_clicked("land", land_cell)
		if battle.sim.get_defender_count() != defs_before:
			failures.append("spearman placed with 9 land; fallback must not apply on own grid")
		if battle.status_message.find("Not enough resources") < 0:
			failures.append("short spearman should report Not enough resources")

	# Own-currency pay on own grid.
	if battle.sim.has_method("debug_set_resources"):
		battle.sim.debug_set_resources(0, 10)
		battle.sim.debug_set_resources(1, 0)
	defs_before = battle.sim.get_defender_count()
	land_cell = _first_placeable(battle.land_grid)
	if land_cell.x >= 0:
		battle.selected_unit_id = "spearman"
		battle._on_cell_clicked("land", land_cell)
		if battle.sim.get_defender_count() != defs_before + 1:
			failures.append("spearman with 10 land should place")
		if battle.sim.get_land_resources() != 0:
			failures.append("spearman should spend the land wallet")

	# Infinite-wallet cheats must still reach SimWorld.spend with an empty purse.
	battle.sim.debug_set_resources(0, 0)
	battle.sim.debug_set_resources(1, 0)
	battle.sim.debug_set_infinite_resources(0, true)
	battle.selected_unit_id = "spearman"
	land_cell = _first_placeable(battle.land_grid)
	defs_before = battle.sim.get_defender_count()
	if not battle._preview_valid_for(battle.land_grid, land_cell):
		failures.append("infinite land wallet should allow placement preview")
	battle._on_cell_clicked("land", land_cell)
	if battle.sim.get_defender_count() != defs_before + 1:
		failures.append("infinite land wallet should place Spearman with zero land")
	if battle.sim.get_land_resources() != 0:
		failures.append("infinite land placement should not deduct resources")
	# Sea-currency support on land must use infinite own currency before fallback.
	battle.sim.debug_set_infinite_resources(0, false)
	battle.sim.debug_set_infinite_resources(1, true)
	battle.sim.debug_set_resources(0, 20)
	battle.selected_unit_id = "cross_support"
	land_cell = _first_placeable(battle.land_grid)
	defs_before = battle.sim.get_defender_count()
	battle._on_cell_clicked("land", land_cell)
	if battle.sim.get_defender_count() != defs_before + 1 or battle.sim.get_land_resources() != 20:
		failures.append("infinite sea must pay before finite land fallback")
	battle.sim.debug_set_infinite_resources(1, false)

	# T69: failed unique spawn refunds the wallet that paid, not own-currency.
	if battle.has_method("debug_load_level"):
		battle.debug_load_level()
		await process_frame
	if battle.sim.has_method("debug_set_resources"):
		battle.sim.debug_set_resources(0, 28)
		battle.sim.debug_set_resources(1, 0)
	var qi_land := _first_placeable(battle.land_grid)
	battle.selected_unit_id = "hero_qi"
	if qi_land.x >= 0:
		battle._on_cell_clicked("land", qi_land)
	if battle.sim.has_method("debug_set_resources"):
		battle.sim.debug_set_resources(0, 0)
		battle.sim.debug_set_resources(1, 40)
	var land_at_fail: int = battle.sim.get_land_resources()
	var sea_at_fail: int = battle.sim.get_sea_resources()
	var qi_sea := _first_placeable(battle.sea_grid)
	if qi_sea.x < 0:
		failures.append("no sea cell for failed Qi spawn")
	else:
		battle.selected_unit_id = "hero_qi"
		battle._on_cell_clicked("sea", qi_sea)
		if battle.sim.get_land_resources() != land_at_fail or battle.sim.get_sea_resources() != sea_at_fail:
			failures.append("failed Qi sea-fallback refunded the wrong wallet (land %d→%d sea %d→%d)" % [
				land_at_fail, battle.sim.get_land_resources(), sea_at_fail, battle.sim.get_sea_resources()
			])
		var qi_count := 0
		for defender in battle.sim.get_defenders():
			if str(defender.get("type", "")) == "hero_qi":
				qi_count += 1
		if qi_count != 1:
			failures.append("second Qi should fail unique spawn, count=%d" % qi_count)

	if battle.sim.has_method("debug_set_resources"):
		battle.sim.debug_set_resources(0, 0)
		battle.sim.debug_set_resources(1, 26)
	var dias_sea := _first_placeable(battle.sea_grid)
	battle.selected_unit_id = "hero_dias"
	if dias_sea.x >= 0:
		battle._on_cell_clicked("sea", dias_sea)
	if battle.sim.has_method("debug_set_resources"):
		battle.sim.debug_set_resources(0, 40)
		battle.sim.debug_set_resources(1, 0)
	land_at_fail = battle.sim.get_land_resources()
	sea_at_fail = battle.sim.get_sea_resources()
	var dias_land := _first_placeable(battle.land_grid)
	if dias_land.x < 0:
		failures.append("no land cell for failed Dias spawn")
	else:
		battle.selected_unit_id = "hero_dias"
		battle._on_cell_clicked("land", dias_land)
		if battle.sim.get_land_resources() != land_at_fail or battle.sim.get_sea_resources() != sea_at_fail:
			failures.append("failed Dias land-fallback refunded the wrong wallet (land %d→%d sea %d→%d)" % [
				land_at_fail, battle.sim.get_land_resources(), sea_at_fail, battle.sim.get_sea_resources()
			])

	# Infinite payer: spend deducted nothing, so a failed spawn must not gain.
	if battle.sim.has_method("debug_set_infinite_resources"):
		battle.sim.debug_set_resources(0, 0)
		battle.sim.debug_set_resources(1, 0)
		battle.sim.debug_set_infinite_resources(1, true)
		land_at_fail = battle.sim.get_land_resources()
		sea_at_fail = battle.sim.get_sea_resources()
		qi_sea = _first_placeable(battle.sea_grid)
		battle.selected_unit_id = "hero_qi"
		if qi_sea.x >= 0:
			battle._on_cell_clicked("sea", qi_sea)
		if battle.sim.get_land_resources() != land_at_fail or battle.sim.get_sea_resources() != sea_at_fail:
			failures.append("infinite sea failed spawn must not gain (land %d→%d sea %d→%d)" % [
				land_at_fail, battle.sim.get_land_resources(), sea_at_fail, battle.sim.get_sea_resources()
			])
		battle.sim.debug_set_infinite_resources(1, false)

	battle.queue_free()
	await process_frame


func _check_menu(failures: Array[String]) -> void:
	ProgressionScript.reset_progression()
	var seeded := {
		"schema_version": ProgressionScript.SCHEMA_VERSION,
		"total_prestige": 300,
		"levels": {
			"slice0_dual_front": {"runs": 1, "best_stars": 3, "best_prestige": 200},
			"night_tide_dual_front": {"runs": 1, "best_stars": 2, "best_prestige": 100},
		},
	}
	OfflinePersistence.write_json(ProgressionScript.PROGRESSION_PATH, seeded)

	var scene := load("res://scenes/main_menu.tscn")
	if scene == null:
		failures.append("could not load main_menu.tscn")
		return
	var menu = scene.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	var rank: Label = menu.get_node_or_null("Center/VBox/CampaignRankLabel")
	if rank == null:
		failures.append("CampaignRankLabel missing")
	else:
		var text := str(rank.text)
		if text.find("Sentry Bastion") < 0:
			failures.append("menu rank missing current title (got %s)" % text)
		if text.find("750") < 0 and text.find("Garrison Fortress") < 0:
			failures.append("menu rank missing next-rank progress (got %s)" % text)
		if text.find("campaign ★ 5") < 0 and text.find("campaign ★5") < 0:
			failures.append("menu rank missing campaign star total 5 (got %s)" % text)
	ProgressionScript.reset_progression()
	menu.queue_free()


func _first_placeable(grid: Node) -> Vector2i:
	if grid == null:
		return Vector2i(-1, -1)
	for x in range(0, 8):
		for y in range(0, 5):
			var cell := Vector2i(x, y)
			if grid.is_placeable(cell):
				return cell
	return Vector2i(-1, -1)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Placement afford smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Placement afford smoke: FAIL (%d)" % failures.size())
		quit(1)
