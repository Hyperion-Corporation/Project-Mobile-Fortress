extends SceneTree
## Headless smoke test for U9 UnitToken procedural tactical rendering.

const UnitTokenScript := preload("res://scripts/ui/unit_token.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	# 1. Test defender setup (spearman & heroes)
	var spearman: Node2D = UnitTokenScript.new()
	root.add_child(spearman)
	var spear_def: Dictionary = UnitDefs.get_def("spearman")
	spearman.setup_defender("spearman", spear_def)
	if spearman.is_hero:
		failures.append("spearman incorrectly marked as hero")
	if spearman.is_raider:
		failures.append("spearman incorrectly marked as raider")

	var qi: Node2D = UnitTokenScript.new()
	root.add_child(qi)
	var qi_def: Dictionary = UnitDefs.get_def("hero_qi")
	qi.setup_defender("hero_qi", qi_def)
	if not qi.is_hero:
		failures.append("hero_qi not marked as hero")
	if qi.size_radius <= spearman.size_radius:
		failures.append("hero size_radius should be larger than standard defender")

	var dias: Node2D = UnitTokenScript.new()
	root.add_child(dias)
	var dias_def: Dictionary = UnitDefs.get_def("hero_dias")
	dias.setup_defender("hero_dias", dias_def)
	if not dias.is_hero:
		failures.append("hero_dias not marked as hero")

	# 2. Test raider setup (land & sea)
	var raider_land: Node2D = UnitTokenScript.new()
	root.add_child(raider_land)
	raider_land.setup_raider(0)
	if not raider_land.is_raider:
		failures.append("raider_land not marked as raider")
	if raider_land.front_id != 0:
		failures.append("raider_land front_id mismatch")

	var raider_sea: Node2D = UnitTokenScript.new()
	root.add_child(raider_sea)
	raider_sea.setup_raider(1)
	if not raider_sea.is_raider:
		failures.append("raider_sea not marked as raider")

	# 3. Test outpost setup & HP ratio
	var outpost: Node2D = UnitTokenScript.new()
	root.add_child(outpost)
	outpost.setup_outpost(0)
	outpost.set_hp_ratio(0.5)
	if abs(outpost.hp_ratio - 0.5) > 0.01:
		failures.append("outpost hp_ratio not updated correctly: %f" % outpost.hp_ratio)

	# 4. Test state updates
	spearman.set_traveling(true)
	if not spearman.is_traveling:
		failures.append("set_traveling failed")
	qi.set_selected(true)
	if not qi.is_selected:
		failures.append("set_selected failed")

	# 5. Test GridFront tile variety mapping
	var land_grid: GridFront = load("res://scripts/battle/grid_front.gd").new()
	land_grid.front_id = "land"
	land_grid.cols = 8
	land_grid.rows = 5
	var land_tile := land_grid._get_environmental_tile(Vector2i(0, 0))
	if land_tile != Vector2i(0, 0):
		failures.append("land base tile mismatch: %s" % str(land_tile))
	var outpost_tile := land_grid._get_environmental_tile(Vector2i(4, 2))
	if outpost_tile != Vector2i(2, 1):
		failures.append("land outpost tile mismatch: %s" % str(outpost_tile))

	var sea_grid: GridFront = load("res://scripts/battle/grid_front.gd").new()
	sea_grid.front_id = "sea"
	sea_grid.cols = 8
	sea_grid.rows = 5
	var sea_outpost_tile := sea_grid._get_environmental_tile(Vector2i(4, 2))
	if sea_outpost_tile != Vector2i(2, 0):
		failures.append("sea outpost tile mismatch: %s" % str(sea_outpost_tile))
	var sea_tile := sea_grid._get_environmental_tile(Vector2i(0, 3))
	if sea_tile != Vector2i(1, 0):
		failures.append("sea base tile mismatch: %s" % str(sea_tile))

	land_grid.queue_free()
	sea_grid.queue_free()

	await process_frame

	spearman.queue_free()
	qi.queue_free()
	dias.queue_free()
	raider_land.queue_free()
	raider_sea.queue_free()
	outpost.queue_free()

	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("UnitToken smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("UnitToken smoke: FAIL (%d)" % failures.size())
		quit(1)
