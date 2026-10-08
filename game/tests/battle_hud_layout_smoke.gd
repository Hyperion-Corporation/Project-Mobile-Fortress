extends SceneTree
## Headless smoke test for Battle HUD phone-scale targets & Citadel Rank (T59 / GitHub #25, #14):
## - Every interactive HUD control (unit buttons, pause, speed, save/load, pause-overlay, results)
##   is at least 48 px in rendered window pixels in BOTH dimensions across all 4 viewports:
##   1280×720, 720×1280, 390×844, 844×390, with Large Text off and on.
## - No interactive controls overlap each other and none clip outside the viewport.
## - Rendered window pixel dimensions are measured via get_final_transform().basis_xform().
## - Grid coverage at 1280×720 does not exceed pre-T59 baseline (16640 px²).
## - Results panel displays citadel rank title and progress to the next rank.

const ThemeTokensScript := preload("res://scripts/ui/theme_tokens.gd")
const ProgressionScript := preload("res://scripts/data/progression.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var initial_settings: Dictionary = OfflinePersistence.read_settings()

	var battle_scene: PackedScene = load("res://scenes/battle/battle.tscn")
	if battle_scene == null:
		failures.append("Failed to load res://scenes/battle/battle.tscn")
		_finish(failures)
		return

	# Measured independently from 2250145^ at 1280×720, Large Text off:
	# StatusLabel intersects the two grid bounding boxes by 16640 px².
	# Never derive the reference from the HUD under test: that hides regressions.
	var baseline_covered := 16640.0

	# =========================================================================
	# 2. Test Phone-Scale Targets across Viewports & Large Text
	# =========================================================================
	var viewport_sizes: Array[Vector2i] = [
		Vector2i(1280, 720),
		Vector2i(720, 1280),
		Vector2i(390, 844),
		Vector2i(844, 390)
	]

	for large_text_enabled: bool in [false, true]:
		var test_settings: Dictionary = initial_settings.duplicate(true)
		test_settings["large_text"] = large_text_enabled
		OfflinePersistence.write_settings(test_settings)

		for vp_size: Vector2i in viewport_sizes:
			root.size = vp_size
			var battle: Node2D = battle_scene.instantiate()
			root.add_child(battle)
			await process_frame
			await process_frame
			await create_timer(0.1).timeout

			var hud: CanvasLayer = battle.get_node_or_null("HUD")
			if hud == null:
				failures.append("HUD missing in battle scene at vp %s" % str(vp_size))
				battle.queue_free()
				continue

			var vp_rect: Rect2 = battle.get_viewport_rect()
			var vp_final_xform: Transform2D = battle.get_viewport().get_final_transform()

			# -----------------------------------------------------------------
			# A. Check Grid Coverage at 1280×720
			# -----------------------------------------------------------------
			if vp_size == Vector2i(1280, 720) and not large_text_enabled:
				var l_r: Rect2 = _get_grid_bounding_rect(battle.land_grid)
				var s_r: Rect2 = _get_grid_bounding_rect(battle.sea_grid)
				var cur_covered: float = _compute_hud_grid_coverage(hud, l_r, s_r)
				if cur_covered > baseline_covered:
					failures.append("HUD covered area at 1280x720 increased: %.1f px² > baseline %.1f px²" % [cur_covered, baseline_covered])

			# -----------------------------------------------------------------
			# B. Main Battle HUD Buttons: Unit, Action, Pause, Speed
			# -----------------------------------------------------------------
			var main_hud_buttons: Array[Control] = []
			var pause_btn: Control = hud.get_node_or_null("Root/SideBar/PauseBtn")
			if pause_btn == null:
				pause_btn = hud.get_node_or_null("Root/TopBar/PauseBtn")
			if pause_btn == null:
				failures.append("PauseBtn missing at vp %s" % str(vp_size))
			else:
				main_hud_buttons.append(pause_btn)

			var speed_btn: Control = hud.get_node_or_null("Root/SideBar/SpeedBtn")
			if speed_btn == null:
				speed_btn = hud.get_node_or_null("Root/TopBar/SpeedBtn")
			if speed_btn == null:
				failures.append("SpeedBtn missing at vp %s" % str(vp_size))
			else:
				main_hud_buttons.append(speed_btn)

			var sidebar: Control = hud.get_node_or_null("Root/SideBar")
			if sidebar == null:
				failures.append("SideBar missing at vp %s" % str(vp_size))
			else:
				var expected_sidebar_buttons: Array[String] = [
					"BtnSpear", "BtnCannon", "BtnArq", "BtnJunk",
					"BtnHero", "BtnHeroDias", "BtnCross",
					"StartCombatBtn", "HeroAbilityBtn", "SaveBtn", "LoadBtn"
				]
				for btn_name: String in expected_sidebar_buttons:
					var b: Control = sidebar.get_node_or_null(btn_name)
					if b == null:
						failures.append("SideBar button %s missing at vp %s" % [btn_name, str(vp_size)])
					else:
						main_hud_buttons.append(b)

			# Validate main HUD buttons
			_validate_control_targets(main_hud_buttons, vp_rect, vp_final_xform, vp_size, large_text_enabled, "MainHUD", failures)
			_validate_non_overlapping(main_hud_buttons, vp_size, large_text_enabled, "MainHUD", failures)

			# -----------------------------------------------------------------
			# C. Pause Overlay Buttons
			# -----------------------------------------------------------------
			var session: Node = root.get_node_or_null("GameSession")
			if session != null:
				session.set_paused(true)
			await process_frame
			await process_frame

			var pause_overlay: Control = hud.get_node_or_null("Root/PauseOverlay")
			if pause_overlay == null or not pause_overlay.visible:
				failures.append("PauseOverlay not visible when paused at vp %s (lt=%s)" % [str(vp_size), large_text_enabled])
			else:
				var pause_buttons: Array[Control] = [
					pause_overlay.get_node_or_null("PausePanel/VBox/ResumeBtn"),
					pause_overlay.get_node_or_null("PausePanel/VBox/PauseSaveBtn"),
					pause_overlay.get_node_or_null("PausePanel/VBox/PauseMenuBtn")
				]
				for pb: Control in pause_buttons:
					if pb == null:
						failures.append("Pause overlay button missing at vp %s" % str(vp_size))
				_validate_control_targets(pause_buttons, vp_rect, vp_final_xform, vp_size, large_text_enabled, "PausePanel", failures)
				_validate_non_overlapping(pause_buttons, vp_size, large_text_enabled, "PausePanel", failures)

			if session != null:
				session.set_paused(false)
			await process_frame

			# -----------------------------------------------------------------
			# D. Results Panel Buttons & Citadel Rank Display
			# -----------------------------------------------------------------
			var dummy_stats: Dictionary = {
				"stars": 3,
				"prestige_earned": 120,
				"total_prestige": 870,
				"enemies_killed": 15,
				"units_placed": 4,
				"outposts_lost": 0,
				"combat_time": 25.0,
				"wave": 2
			}
			hud.show_result(true, "All coastal sectors secure", dummy_stats)
			await process_frame
			await process_frame

			var res_panel: PanelContainer = hud.result_panel
			if res_panel == null or not res_panel.visible:
				failures.append("ResultPanel not visible after show_result at vp %s" % str(vp_size))
			else:
				var res_buttons: Array[Control] = [
					res_panel.get_node_or_null("VBox/RestartBtn"),
					res_panel.get_node_or_null("VBox/MenuBtn")
				]
				for rb: Control in res_buttons:
					if rb == null:
						failures.append("Result panel button missing at vp %s" % str(vp_size))
				_validate_control_targets(res_buttons, vp_rect, vp_final_xform, vp_size, large_text_enabled, "ResultPanel", failures)
				_validate_non_overlapping(res_buttons, vp_size, large_text_enabled, "ResultPanel", failures)

				# Verify citadel rank content in result text
				var res_text: Label = hud.result_label
				if res_text == null:
					failures.append("ResultText label missing at vp %s" % str(vp_size))
				else:
					var txt: String = res_text.text
					if not txt.contains("Rank:"):
						failures.append("ResultText missing 'Rank:' label at vp %s" % str(vp_size))
					var expected_tier: Dictionary = ProgressionScript.get_prestige_tier(870)
					var expected_title: String = str(expected_tier.get("title", ""))
					if not txt.contains(expected_title):
						failures.append("ResultText missing citadel rank '%s' at vp %s" % [expected_title, str(vp_size)])
					if not txt.contains("needed") and not txt.contains("Max Rank"):
						failures.append("ResultText missing next rank progression details at vp %s" % str(vp_size))

			battle.queue_free()
			await process_frame

	OfflinePersistence.write_settings(initial_settings)
	root.size = Vector2i(1280, 720)
	_finish(failures)


func _validate_control_targets(
	controls: Array[Control],
	vp_rect: Rect2,
	vp_final_xform: Transform2D,
	vp_size: Vector2i,
	large_text_enabled: bool,
	group_name: String,
	failures: Array[String]
) -> void:
	for ctrl: Control in controls:
		if ctrl == null or not ctrl.is_inside_tree() or not ctrl.visible:
			continue
		var r: Rect2 = ctrl.get_global_rect()
		if not vp_rect.encloses(r):
			failures.append("%s control %s (%s) clips outside viewport %s at vp %s (lt=%s)" % [
				group_name, ctrl.name, r, vp_rect, vp_size, large_text_enabled
			])
		var rendered_size: Vector2 = vp_final_xform.basis_xform(r.size).abs()
		if rendered_size.x < 47.9:
			failures.append("%s control %s rendered width %.1f px < 48dp target at vp %s (lt=%s)" % [
				group_name, ctrl.name, rendered_size.x, vp_size, large_text_enabled
			])
		if rendered_size.y < 47.9:
			failures.append("%s control %s rendered height %.1f px < 48dp target at vp %s (lt=%s)" % [
				group_name, ctrl.name, rendered_size.y, vp_size, large_text_enabled
			])


func _validate_non_overlapping(
	controls: Array[Control],
	vp_size: Vector2i,
	large_text_enabled: bool,
	group_name: String,
	failures: Array[String]
) -> void:
	for i in range(controls.size()):
		for j in range(i + 1, controls.size()):
			var a: Control = controls[i]
			var b: Control = controls[j]
			if a != null and b != null and a.is_inside_tree() and b.is_inside_tree() and a.visible and b.visible:
				if a.get_global_rect().intersects(b.get_global_rect()):
					failures.append("%s controls overlap: %s and %s at vp %s (lt=%s)" % [
						group_name, a.name, b.name, vp_size, large_text_enabled
					])


func _get_grid_bounding_rect(grid: GridFront) -> Rect2:
	if grid == null:
		return Rect2()
	var g_min := Vector2(1e9, 1e9)
	var g_max := Vector2(-1e9, -1e9)
	for y in range(grid.rows):
		for x in range(grid.cols):
			var p: Vector2 = grid.cell_to_global_center(Vector2i(x, y))
			g_min.x = minf(g_min.x, p.x - 64.0)
			g_min.y = minf(g_min.y, p.y - 32.0)
			g_max.x = maxf(g_max.x, p.x + 64.0)
			g_max.y = maxf(g_max.y, p.y + 32.0)
	return Rect2(g_min, g_max - g_min)


func _compute_hud_grid_coverage(hud: CanvasLayer, land_rect: Rect2, sea_rect: Rect2) -> float:
	if hud == null:
		return 0.0
	var covered := 0.0
	var root_node: Control = hud.get_node_or_null("Root")
	if root_node == null:
		return 0.0
	for child: Node in root_node.get_children():
		if child is Control and (child as Control).visible:
			var cr: Rect2 = (child as Control).get_global_rect()
			if cr.intersects(land_rect):
				var inter: Rect2 = cr.intersection(land_rect)
				covered += inter.size.x * inter.size.y
			if cr.intersects(sea_rect):
				var inter2: Rect2 = cr.intersection(sea_rect)
				covered += inter2.size.x * inter2.size.y
	return covered


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Battle HUD layout smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Battle HUD layout smoke: FAIL (%d errors)" % failures.size())
		quit(1)
