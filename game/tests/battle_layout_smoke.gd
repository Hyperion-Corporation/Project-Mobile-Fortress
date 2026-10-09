extends SceneTree
## Headless smoke test for Battle dual-grid visibility & layout (T70 / GitHub #12, #25):
## - Both LandGrid and SeaGrid are fully visible inside viewport across all 4 viewports:
##   1280×720 (landscape), 844×390 (phone landscape), 720×1280 (portrait), 390×844 (phone portrait).
## - Neither grid clips off-canvas: vp_rect.encloses(land_rect) and vp_rect.encloses(sea_rect).
## - LandGrid and SeaGrid do not overlap each other: not land_rect.intersects(sea_rect).
## - Grids do not overlap interactive HUD buttons.
## - Rendered cell size in window pixels is measured and reported across all 4 viewports.
## - Bastion/HQ at column 7 (cell (7, 2)) is in bounds and rendered.
## - Includes disposable mutation check to prove off-canvas grids fail the test.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	var battle_scene: PackedScene = load("res://scenes/battle/battle.tscn")
	if battle_scene == null:
		failures.append("Failed to load res://scenes/battle/battle.tscn")
		_finish(failures)
		return

	var viewport_sizes: Array[Vector2i] = [
		Vector2i(1280, 720),
		Vector2i(844, 390),
		Vector2i(720, 1280),
		Vector2i(390, 844),
	]

	print("\n=== T70 Battle Layout Smoke: Testing Dual-Grid Viewport Containment & Touch Targets ===")

	var initial_settings := OfflinePersistence.read_settings()
	var saved_paths := [Progression.PROGRESSION_PATH, OfflinePersistence.RESULTS_PATH, OfflinePersistence.HISTORY_PATH]
	var saved_files: Dictionary = {}
	for path in saved_paths:
		saved_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	OfflinePersistence.write_json(Progression.PROGRESSION_PATH, {"schema_version": 1, "total_prestige": 5000, "levels": {"slice0_dual_front": {"best_stars": 3}}})
	OfflinePersistence.write_results({"victory": true, "stars": 3, "enemies_killed": 20})
	OfflinePersistence.write_json(OfflinePersistence.HISTORY_PATH, {"schema_version": 1, "runs": [{"victory": true, "stars": 3}]})
	for large_text in [false, true]:
		var settings := initial_settings.duplicate(true)
		settings["large_text"] = large_text
		OfflinePersistence.write_settings(settings)
		for vp_size: Vector2i in viewport_sizes:
			root.size = vp_size
			var battle: Node2D = battle_scene.instantiate()
			root.add_child(battle)
			await process_frame
			await process_frame
			await create_timer(0.05).timeout

			var land_grid: GridFront = battle.get("land_grid")
			var sea_grid: GridFront = battle.get("sea_grid")
			var hud: CanvasLayer = battle.get_node_or_null("HUD")

			if land_grid == null or sea_grid == null:
				failures.append("Grids missing at vp %s" % str(vp_size))
				battle.queue_free()
				continue

			var vp_rect: Rect2 = battle.get_viewport_rect()
			var vp_final_xform: Transform2D = battle.get_viewport().get_final_transform()

			var land_rect: Rect2 = land_grid.get_bounding_rect()
			var sea_rect: Rect2 = sea_grid.get_bounding_rect()

			# 1. Viewport containment
			if not vp_rect.encloses(land_rect):
				failures.append("LandGrid clips outside viewport at %s: land_rect=%s, vp=%s" % [
					str(vp_size), str(land_rect), str(vp_rect)
				])
			if not vp_rect.encloses(sea_rect):
				failures.append("SeaGrid clips outside viewport at %s: sea_rect=%s, vp=%s" % [
					str(vp_size), str(sea_rect), str(vp_rect)
				])

			# 2. Non-overlap between grids
			if land_rect.intersects(sea_rect):
				failures.append("LandGrid and SeaGrid overlap at %s: land_rect=%s, sea_rect=%s" % [
					str(vp_size), str(land_rect), str(sea_rect)
				])

			# Check every visible interactive HUD control, including controls moved by layout.
			if hud != null:
				for btn in hud.find_children("*", "BaseButton", true, false):
					if btn.is_visible_in_tree():
						for grid_rect in [land_rect, sea_rect]:
							if btn.get_global_rect().intersects(grid_rect):
								failures.append("Grid overlaps %s at %s (large_text=%s)" % [btn.name, vp_size, large_text])
			# All 80 centers resolve to their distinct cell/front and match sim projection.
			for front in [0, 1]:
				var grid: GridFront = land_grid if front == 0 else sea_grid
				for y in grid.rows:
					for x in grid.cols:
						var cell := Vector2i(x, y)
						var center := grid.cell_to_global_center(cell)
						if not battle._probe_grids(battle.get_canvas_transform() * center) or battle._hit_front_id != grid.front_id or battle._hit_cell != cell:
							failures.append("Touch probe misses cell/front: %s/%s" % [front, cell])
						if grid.world_to_cell(center) != cell:
							failures.append("Cell center round trip failed: %s/%s" % [front, cell])
						if not grid.get("_click_area").get_global_rect().has_point(center):
							failures.append("Mouse input misses cell center: %s/%s" % [front, cell])
						var projected: Vector2 = battle._sim_to_screen_pos(front, battle._cell_to_sim_pos(front, cell))
						if not projected.is_equal_approx(center):
							failures.append("Sim projection differs from drawn cell: %s/%s" % [front, cell])
				var outpost: Node2D = battle.visual_nodes.get("outpost_" + str(front))
				if outpost == null or not outpost.global_position.is_equal_approx(grid.cell_to_global_center(Vector2i(4, 2))):
					failures.append("Outpost marker missing or misplaced: %s" % front)

			# 4. Measure rendered cell dimensions in window pixels
			var cell_canvas_w: float = 128.0 * battle.land_host.scale.x
			var cell_canvas_h: float = 64.0 * battle.land_host.scale.y
			var cell_rendered: Vector2 = vp_final_xform.basis_xform(Vector2(cell_canvas_w, cell_canvas_h)).abs()
			var note_below_40 := ""
			if cell_rendered.x < 40.0 or cell_rendered.y < 40.0:
				note_below_40 = " [NOTE: Dimension < 40px on phone scale; documented ergonomics finding]"

			print("  LT=%s VP %4dx%4d | Host scale: %.3f | Rendered cell: %5.1f x %5.1f px%s" % [
				large_text, vp_size.x, vp_size.y,
				battle.land_host.scale.x,
				cell_rendered.x, cell_rendered.y,
				note_below_40
			])

			# 5. Bastion / HQ Citadel check at (cols - 1, rows / 2) -> (7, 2)
			var hq_cell := Vector2i(land_grid.cols - 1, land_grid.rows / 2)
			if not land_grid.in_bounds(hq_cell) or not sea_grid.in_bounds(hq_cell):
				failures.append("HQ bastion cell %s out of bounds at %s" % [str(hq_cell), str(vp_size)])

			battle.queue_free()
			await process_frame

	# -------------------------------------------------------------------------
	# 6. Disposable Mutation Proof: Off-canvas grid triggers failure
	# -------------------------------------------------------------------------
	root.size = Vector2i(1280, 720)
	var mutation_battle: Node2D = battle_scene.instantiate()
	root.add_child(mutation_battle)
	await process_frame
	await process_frame

	# Intentionally mutate SeaHost position off the bottom
	mutation_battle.sea_host.position.y += 400.0
	var mutated_sea_rect: Rect2 = mutation_battle.sea_grid.get_bounding_rect()
	var mutated_vp_rect: Rect2 = mutation_battle.get_viewport_rect()
	var mutation_caught := not mutated_vp_rect.encloses(mutated_sea_rect)

	mutation_battle.queue_free()
	await process_frame

	if not mutation_caught:
		failures.append("Disposable mutation test failed: off-canvas grid was not detected!")
	else:
		print("  Disposable mutation check: PASS (off-canvas grid correctly detected)")

	root.size = Vector2i(1280, 720)
	OfflinePersistence.write_settings(initial_settings)
	for path in saved_paths:
		if saved_files[path] == null:
			DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(saved_files[path])
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("\nBattle layout smoke: PASS\n")
		quit(0)
	else:
		for f in failures:
			push_error(f)
		print("\nBattle layout smoke: FAIL (%d errors)\n" % failures.size())
		quit(1)
