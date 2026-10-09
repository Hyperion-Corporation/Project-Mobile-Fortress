extends SceneTree
## G10: synthesised ScreenTouch/ScreenDrag placement on both fronts.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if not ClassDB.class_exists("SimulationCore"):
		failures.append("SimulationCore not registered")
		_finish(failures)
		return

	var scene = load("res://scenes/battle/battle.tscn")
	if scene == null:
		failures.append("could not load battle.tscn")
		_finish(failures)
		return

	var battle = scene.instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame

	if battle.land_grid == null or battle.sea_grid == null or battle.sim == null:
		failures.append("battle grids/sim not ready")
		_finish(failures)
		return

	var land_cells: Array[Vector2i] = _placeable_cells(battle.land_grid)
	var sea_cells: Array[Vector2i] = _placeable_cells(battle.sea_grid)
	if land_cells.size() < 3:
		failures.append("need ≥3 placeable land cells, got %d" % land_cells.size())
		_finish(failures)
		return
	if sea_cells.size() < 2:
		failures.append("need ≥2 placeable sea cells, got %d" % sea_cells.size())
		_finish(failures)
		return

	var land_a: Vector2i = land_cells[0]
	var land_b: Vector2i = land_cells[1]
	var land_c: Vector2i = _far_cell(battle, battle.land_grid, land_cells, land_b)
	if land_c == land_a or land_c == land_b:
		for cell in land_cells:
			if cell != land_a and cell != land_b:
				land_c = cell
				break
	var sea_a: Vector2i = sea_cells[0]

	# HUD overlap: a STOP Control over a placeable cell must consume the finger.
	# This fails if BattleRoot._input starts a gesture before GUI hit-testing.
	battle.selected_unit_id = "spearman"
	var overlay_cell := Vector2i(1, 0)
	if not battle.land_grid.is_placeable(overlay_cell):
		overlay_cell = land_a
	var overlay_center: Vector2 = _cell_vp(battle, battle.land_grid, overlay_cell)
	var hud_root: Control = battle.hud.get_node("Root") as Control
	var hud_btn := Button.new()
	hud_btn.name = "TouchGuiProbeBtn"
	hud_btn.text = "STOP"
	hud_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_btn.size = Vector2(40, 40)
	hud_btn.position = overlay_center - Vector2(20, 20)
	var hud_clicks := {"n": 0}
	hud_btn.pressed.connect(func(): hud_clicks["n"] = int(hud_clicks["n"]) + 1)
	hud_root.add_child(hud_btn)
	await process_frame
	var btn_center: Vector2 = hud_btn.get_global_rect().get_center()
	var hud_before: int = int(battle.sim.get_defender_count())
	_push_touch(battle, 0, true, btn_center)
	_push_emulated_mouse(battle, btn_center, true)
	_push_touch(battle, 0, false, btn_center)
	_push_emulated_mouse(battle, btn_center, false)
	await process_frame
	if int(battle.sim.get_defender_count()) != hud_before:
		failures.append("HUD button over grid placed a unit")
	if battle.land_grid.occupants.has(overlay_cell):
		failures.append("HUD button occupied grid cell %s" % str(overlay_cell))
	if battle.is_touch_gesture_active():
		failures.append("HUD button left a touch gesture active")
	if int(hud_clicks["n"]) < 1:
		failures.append("HUD button over grid was not activated")
	hud_btn.queue_free()
	await process_frame

	# Pause overlay: a tap on a grid cell while paused must place nothing.
	var pause_cell: Vector2i = overlay_cell
	if battle.land_grid.occupants.has(pause_cell):
		pause_cell = land_a
	var pause_before: int = int(battle.sim.get_defender_count())
	var session: Node = root.get_node_or_null("GameSession")
	if session == null:
		failures.append("GameSession autoload missing")
	else:
		session.set_paused(true)
		await process_frame
		_push_touch(battle, 0, true, _cell_vp(battle, battle.land_grid, pause_cell))
		_push_touch(battle, 0, false, _cell_vp(battle, battle.land_grid, pause_cell))
		await process_frame
		if int(battle.sim.get_defender_count()) != pause_before:
			failures.append("touch while paused placed a unit")
		if battle.land_grid.occupants.has(pause_cell):
			failures.append("touch while paused occupied %s" % str(pause_cell))
		if battle.is_touch_gesture_active():
			failures.append("paused touch left a gesture active")
		session.set_paused(false)
		await process_frame

	# Boundary regressions: short motion still cancels outside the grid, and
	# sub-threshold motion previews the press cell that a tap will commit.
	var host_s: float = battle.land_host.scale.x if "land_host" in battle else 1.0
	var edge_center: Vector2 = _cell_vp(battle, battle.land_grid, Vector2i(0, 0))
	var edge_press := edge_center + Vector2(0, -30 * host_s)
	var edge_release := edge_center + Vector2(0, -34 * host_s)
	var edge_before: int = battle.sim.get_defender_count()
	_push_touch(battle, 0, true, edge_press)
	_push_touch(battle, 0, false, edge_release)
	if battle.sim.get_defender_count() != edge_before:
		failures.append("sub-threshold off-grid release placed a unit")
	var boundary_press := edge_center + Vector2(30 * host_s, 16 * host_s)
	var boundary_drag := edge_center + Vector2(34 * host_s, 16 * host_s)
	_push_touch(battle, 0, true, boundary_press)
	_push_drag(battle, 0, boundary_drag, boundary_drag - boundary_press)
	if battle.land_grid.touch_preview_cell != Vector2i(0, 0):
		failures.append("sub-threshold preview differs from tap commit cell")
	var cancel := InputEventScreenTouch.new()
	cancel.index = 0
	cancel.canceled = true
	battle.get_viewport().push_input(cancel, true)
	if battle.is_touch_gesture_active():
		failures.append("OS cancellation left a gesture active")
	_push_touch(battle, 0, true, _cell_vp(battle, battle.sea_grid, sea_a))
	if battle.sea_grid.touch_preview_kind != battle.sea_grid.PREVIEW_INVALID:
		failures.append("land-only unit preview is valid on sea")
	battle.get_viewport().push_input(cancel, true)
	battle.sim.debug_set_resources(0, 0)
	_push_touch(battle, 0, true, edge_center)
	if battle.land_grid.touch_preview_kind != battle.land_grid.PREVIEW_INVALID:
		failures.append("unaffordable unit preview is valid")
	battle.get_viewport().push_input(cancel, true)
	battle.sim.debug_set_resources(0, 40)

	# 1. Tap places on land (emulated mouse during the hold must not double-fire).
	battle.selected_unit_id = "spearman"
	var before: int = int(battle.sim.get_defender_count())
	var land_tap_vp: Vector2 = _cell_vp(battle, battle.land_grid, land_a)
	_push_touch(battle, 0, true, land_tap_vp)
	_push_emulated_mouse(battle, land_tap_vp, true)
	if int(battle.sim.get_defender_count()) != before:
		failures.append("emulated mouse placed during touch press (double-fire)")
	await process_frame
	_push_touch(battle, 0, false, land_tap_vp)
	_push_emulated_mouse(battle, land_tap_vp, false)
	await process_frame
	if int(battle.sim.get_defender_count()) != before + 1:
		failures.append("land tap did not place (count %d -> %d)" % [before, battle.sim.get_defender_count()])
	elif not battle.land_grid.occupants.has(land_a):
		failures.append("land tap did not occupy %s" % str(land_a))
	if battle.land_grid.touch_preview_kind != battle.land_grid.PREVIEW_NONE:
		failures.append("land preview lingered after tap release")

	# 2. Tap places on sea.
	battle.selected_unit_id = "arquebusier"
	before = int(battle.sim.get_defender_count())
	await _tap_cell(battle, battle.sea_grid, sea_a)
	if int(battle.sim.get_defender_count()) != before + 1:
		failures.append("sea tap did not place (count %d -> %d)" % [before, battle.sim.get_defender_count()])
	elif not battle.sea_grid.occupants.has(sea_a):
		failures.append("sea tap did not occupy %s" % str(sea_a))

	# 3. Drag-then-release places at the release cell, not the press cell.
	battle.selected_unit_id = "spearman"
	before = int(battle.sim.get_defender_count())
	var press_vp: Vector2 = _cell_vp(battle, battle.land_grid, land_b)
	var release_vp: Vector2 = _cell_vp(battle, battle.land_grid, land_c)
	_push_touch(battle, 0, true, press_vp)
	await process_frame
	if battle.land_grid.touch_preview_kind == battle.land_grid.PREVIEW_NONE:
		failures.append("drag press did not show a land preview")
	_push_drag(battle, 0, release_vp, release_vp - press_vp)
	await process_frame
	if battle.land_grid.touch_preview_cell != land_c:
		failures.append("drag preview cell %s want %s" % [str(battle.land_grid.touch_preview_cell), str(land_c)])
	_push_touch(battle, 0, false, release_vp)
	await process_frame
	if battle.land_grid.occupants.has(land_b):
		failures.append("drag-release placed at press cell %s" % str(land_b))
	if not battle.land_grid.occupants.has(land_c):
		failures.append("drag-release did not place at release cell %s" % str(land_c))
	if int(battle.sim.get_defender_count()) != before + 1:
		failures.append("drag-release defender count %d want %d" % [battle.sim.get_defender_count(), before + 1])

	# 4. Release off-grid cancels.
	var cancel_cell: Vector2i = Vector2i(-1, -1)
	for cell in land_cells:
		if not battle.land_grid.occupants.has(cell):
			cancel_cell = cell
			break
	if cancel_cell.x < 0:
		failures.append("no free land cell for off-grid cancel")
	else:
		battle.selected_unit_id = "spearman"
		before = int(battle.sim.get_defender_count())
		var start_vp: Vector2 = _cell_vp(battle, battle.land_grid, cancel_cell)
		_push_touch(battle, 0, true, start_vp)
		await process_frame
		_push_drag(battle, 0, Vector2(8, 8), Vector2(8, 8) - start_vp)
		_push_touch(battle, 0, false, Vector2(8, 8))
		await process_frame
		if int(battle.sim.get_defender_count()) != before:
			failures.append("off-grid release placed a unit")
		if battle.land_grid.occupants.has(cancel_cell):
			failures.append("off-grid release occupied the press cell")
		if battle.is_touch_gesture_active():
			failures.append("touch gesture still active after off-grid cancel")
		if battle.land_grid.touch_preview_kind != battle.land_grid.PREVIEW_NONE:
			failures.append("preview lingered after off-grid cancel")

	# 5. Second finger is ignored.
	var finger_a: Vector2i = Vector2i(-1, -1)
	var finger_b: Vector2i = Vector2i(-1, -1)
	for cell in land_cells:
		if battle.land_grid.occupants.has(cell):
			continue
		if finger_a.x < 0:
			finger_a = cell
		elif finger_b.x < 0:
			finger_b = cell
			break
	if finger_a.x < 0 or finger_b.x < 0:
		failures.append("need two free land cells for multi-touch")
	else:
		battle.selected_unit_id = "spearman"
		before = int(battle.sim.get_defender_count())
		var a_vp: Vector2 = _cell_vp(battle, battle.land_grid, finger_a)
		var b_vp: Vector2 = _cell_vp(battle, battle.land_grid, finger_b)
		_push_touch(battle, 0, true, a_vp)
		_push_touch(battle, 1, true, b_vp)
		_push_touch(battle, 1, false, b_vp)
		await process_frame
		if int(battle.sim.get_defender_count()) != before:
			failures.append("second finger placed a unit")
		if battle.land_grid.occupants.has(finger_b):
			failures.append("second finger occupied %s" % str(finger_b))
		if battle.land_grid.touch_preview_cell != finger_a:
			failures.append("second finger corrupted preview (cell %s)" % str(battle.land_grid.touch_preview_cell))
		_push_touch(battle, 0, false, a_vp)
		await process_frame
		if not battle.land_grid.occupants.has(finger_a):
			failures.append("primary finger did not place after ignoring second")
		if battle.land_grid.occupants.has(finger_b):
			failures.append("second finger occupied a cell after primary release")
		if int(battle.sim.get_defender_count()) != before + 1:
			failures.append("multi-touch defender count %d want %d" % [battle.sim.get_defender_count(), before + 1])

	# 6. Hero redeploy by touch: tap hero, then tap empty sea cell.
	_ensure_funds(battle)
	battle.selected_unit_id = "hero_qi"
	var hero_cell: Vector2i = Vector2i(-1, -1)
	for cell in land_cells:
		if battle.land_grid.is_placeable(cell):
			hero_cell = cell
			break
	if hero_cell.x < 0:
		failures.append("no land cell for hero_qi")
	else:
		await _tap_cell(battle, battle.land_grid, hero_cell)
		var hero_id := -1
		for defender in battle.sim.get_defenders():
			if str(defender.get("type", "")) == "hero_qi":
				hero_id = int(defender.get("id", -1))
				break
		if hero_id < 0:
			failures.append("hero_qi touch placement failed")
		else:
			await _tap_cell(battle, battle.land_grid, hero_cell)
			if int(battle.pending_hero_id) != hero_id:
				failures.append("touch did not select hero for redeploy")
			var dest: Vector2i = Vector2i(-1, -1)
			for cell in sea_cells:
				if battle.sea_grid.is_placeable(cell):
					dest = cell
					break
			if dest.x < 0:
				failures.append("no sea cell for hero redeploy")
			else:
				await _tap_cell(battle, battle.sea_grid, dest)
				var traveling := false
				for defender in battle.sim.get_defenders():
					if int(defender.get("id", -1)) == hero_id:
						traveling = bool(defender.get("traveling", false))
				if not traveling:
					failures.append("hero touch redeploy did not start travel")

	# 7. Mouse click still places (press, as before).
	_ensure_funds(battle)
	battle.selected_unit_id = "spearman"
	var mouse_cell: Vector2i = Vector2i(-1, -1)
	for cell in land_cells:
		if battle.land_grid.is_placeable(cell):
			mouse_cell = cell
			break
	if mouse_cell.x < 0:
		failures.append("no land cell for mouse click")
	else:
		before = int(battle.sim.get_defender_count())
		_push_mouse_click(battle, battle.land_grid, mouse_cell)
		await process_frame
		if not battle.land_grid.occupants.has(mouse_cell):
			failures.append("mouse click did not place on %s" % str(mouse_cell))
		if int(battle.sim.get_defender_count()) != before + 1:
			failures.append("mouse click defender count %d want %d" % [battle.sim.get_defender_count(), before + 1])

	battle.queue_free()
	_finish(failures)


func _tap_cell(battle: Node, grid: Node, cell: Vector2i) -> void:
	var vp: Vector2 = _cell_vp(battle, grid, cell)
	_push_touch(battle, 0, true, vp)
	await process_frame
	_push_touch(battle, 0, false, vp)
	await process_frame


func _push_touch(battle: Node, index: int, pressed: bool, vp_pos: Vector2) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.pressed = pressed
	ev.position = vp_pos
	battle.get_viewport().push_input(ev, true)


func _push_drag(battle: Node, index: int, vp_pos: Vector2, relative: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = vp_pos
	ev.relative = relative
	battle.get_viewport().push_input(ev, true)


func _push_emulated_mouse(battle: Node, vp_pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = vp_pos
	ev.global_position = vp_pos
	battle.get_viewport().push_input(ev, true)


func _push_mouse_click(battle: Node, grid: Node, cell: Vector2i) -> void:
	var vp: Vector2 = _cell_vp(battle, grid, cell)
	_push_emulated_mouse(battle, vp, true)
	_push_emulated_mouse(battle, vp, false)


func _cell_vp(battle: Node, grid: Node, cell: Vector2i) -> Vector2:
	var world: Vector2 = grid.cell_to_global_center(cell)
	return battle.get_canvas_transform() * world


func _ensure_funds(battle: Node) -> void:
	if battle.sim.has_method("debug_set_resources"):
		battle.sim.debug_set_resources(0, 80)
		battle.sim.debug_set_resources(1, 80)
		battle._sync_session_from_sim()


func _placeable_cells(grid: Node) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in range(0, int(grid.cols)):
		for y in range(0, int(grid.rows)):
			var cell := Vector2i(x, y)
			if grid.is_placeable(cell):
				out.append(cell)
	return out


func _far_cell(battle: Node, grid: Node, cells: Array[Vector2i], origin: Vector2i) -> Vector2i:
	var origin_vp: Vector2 = _cell_vp(battle, grid, origin)
	var best: Vector2i = origin
	var best_d := 0.0
	for cell in cells:
		if cell == origin:
			continue
		var d: float = origin_vp.distance_to(_cell_vp(battle, grid, cell))
		if d > best_d:
			best_d = d
			best = cell
	return best


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Touch placement smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Touch placement smoke: FAIL (%d)" % failures.size())
		quit(1)
