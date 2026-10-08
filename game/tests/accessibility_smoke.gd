extends SceneTree
## Headless smoke test for U8 Accessibility Pass (GitHub #25):
## - Minimum touch targets (>= 48 dp ThemeTokens.MIN_TOUCH_TARGET_SIZE)
## - Full keyboard/gamepad focus traversal (no dead-ends, closed loop, opener restoration)
## - WCAG AA contrast ratios computed from ThemeTokens color pairs
## - Large-text (UI scale) setting round-tripping through OfflinePersistence & scaling scenes
## - Screen-reader metadata (accessibility_name / accessibility_description) on controls

const ThemeTokensScript := preload("res://scripts/ui/theme_tokens.gd")
const SettingsDialogScript := preload("res://scripts/ui/settings_dialog.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	# =========================================================================
	# 1. Test WCAG AA Contrast Ratios computed from ThemeTokens
	# =========================================================================
	var pairs_to_check: Array[Dictionary] = [
		{"fg_name": "INK", "fg": ThemeTokensScript.INK, "bg_name": "PAPER", "bg": ThemeTokensScript.PAPER, "min": 4.5},
		{"fg_name": "INK", "fg": ThemeTokensScript.INK, "bg_name": "PAPER_CARD", "bg": ThemeTokensScript.PAPER_CARD, "min": 4.5},
		{"fg_name": "INK_MUTED", "fg": ThemeTokensScript.INK_MUTED, "bg_name": "PAPER", "bg": ThemeTokensScript.PAPER, "min": 4.5},
		{"fg_name": "INK_MUTED", "fg": ThemeTokensScript.INK_MUTED, "bg_name": "PAPER_CARD", "bg": ThemeTokensScript.PAPER_CARD, "min": 4.5},
		{"fg_name": "CINNABAR", "fg": ThemeTokensScript.CINNABAR, "bg_name": "PAPER", "bg": ThemeTokensScript.PAPER, "min": 4.5},
		{"fg_name": "CINNABAR", "fg": ThemeTokensScript.CINNABAR, "bg_name": "PAPER_CARD", "bg": ThemeTokensScript.PAPER_CARD, "min": 4.5},
		{"fg_name": "CINNABAR_DEEP", "fg": ThemeTokensScript.CINNABAR_DEEP, "bg_name": "PAPER", "bg": ThemeTokensScript.PAPER, "min": 4.5},
		{"fg_name": "SEA_INDIGO", "fg": ThemeTokensScript.SEA_INDIGO, "bg_name": "PAPER", "bg": ThemeTokensScript.PAPER, "min": 4.5},
		{"fg_name": "SEA_INDIGO", "fg": ThemeTokensScript.SEA_INDIGO, "bg_name": "PAPER_CARD", "bg": ThemeTokensScript.PAPER_CARD, "min": 4.5},
		{"fg_name": "FOCUS_BORDER (SEA_INDIGO)", "fg": ThemeTokensScript.SEA_INDIGO, "bg_name": "PAPER", "bg": ThemeTokensScript.PAPER, "min": 3.0},
		{"fg_name": "FOCUS_BORDER (SEA_INDIGO)", "fg": ThemeTokensScript.SEA_INDIGO, "bg_name": "PAPER_CARD", "bg": ThemeTokensScript.PAPER_CARD, "min": 3.0},
	]

	for check: Dictionary in pairs_to_check:
		var ratio: float = ThemeTokensScript.get_contrast_ratio(check["fg"], check["bg"])
		var min_required: float = float(check["min"])
		if ratio < min_required:
			failures.append("Contrast failure: %s on %s is %.2f:1 (required >= %.1f:1)" % [
				check["fg_name"], check["bg_name"], ratio, min_required
			])

	# =========================================================================
	# 2. Test Minimum Touch Targets & Screen-Reader Metadata on MainMenu
	# =========================================================================
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn")
	if menu_scene == null:
		failures.append("Failed to load main_menu.tscn")
		_finish(failures)
		return

	var menu_instance: Control = menu_scene.instantiate()
	root.add_child(menu_instance)
	await process_frame

	var min_target := ThemeTokensScript.MIN_TOUCH_TARGET_SIZE
	var menu_vbox: VBoxContainer = menu_instance.get_node_or_null("Center/VBox")
	if menu_vbox == null:
		failures.append("Main menu Center/VBox missing")
	else:
		var interactive_menu_controls: Array[Control] = []
		for child: Node in menu_vbox.get_children():
			if child is Button or child is OptionButton:
				interactive_menu_controls.append(child as Control)

		for ctrl: Control in interactive_menu_controls:
			if ctrl.custom_minimum_size.y < min_target:
				failures.append("Main menu control %s height %.1f < min touch target %.1f" % [
					ctrl.name, ctrl.custom_minimum_size.y, min_target
				])
			if ctrl.accessibility_name.strip_edges().is_empty():
				failures.append("Main menu control %s missing accessibility_name" % ctrl.name)
			if ctrl.accessibility_description.strip_edges().is_empty():
				failures.append("Main menu control %s missing accessibility_description" % ctrl.name)

		var version_label: Control = menu_instance.get_node_or_null("VersionLabel")
		if version_label == null:
			failures.append("Main menu VersionLabel missing")
		else:
			if version_label.custom_minimum_size.y < min_target:
				failures.append("VersionLabel touch target height %.1f < min touch target %.1f" % [
					version_label.custom_minimum_size.y, min_target
				])
			if version_label.accessibility_name.strip_edges().is_empty():
				failures.append("VersionLabel missing accessibility_name")

	# =========================================================================
	# 3. Test Focus Traversal on MainMenu (no dead-ends, closed loop)
	# =========================================================================
	if menu_vbox != null:
		var focusable_menu: Array[Control] = []
		for child: Node in menu_vbox.get_children():
			if (child is Button or child is OptionButton) and (child as Control).visible and not (child as Control).is_queued_for_deletion():
				var c := child as Control
				if c.focus_mode != Control.FOCUS_NONE:
					focusable_menu.append(c)

		if focusable_menu.size() < 4:
			failures.append("Expected at least 4 focusable controls on MainMenu, found %d" % focusable_menu.size())
		else:
			var visited: Array[Control] = []
			var curr: Control = focusable_menu[0]
			var max_steps: int = focusable_menu.size() + 2
			for _step in range(max_steps):
				visited.append(curr)
				var next_path := curr.focus_next
				if next_path.is_empty():
					failures.append("Focus dead-end: control %s has empty focus_next" % curr.name)
					break
				var next_node := curr.get_node_or_null(next_path) as Control
				if next_node == null:
					failures.append("Focus broken path: control %s points to invalid node %s" % [curr.name, str(next_path)])
					break
				if next_node == focusable_menu[0]:
					# Completed loop!
					break
				curr = next_node

			for expected_ctrl: Control in focusable_menu:
				if not visited.has(expected_ctrl):
					failures.append("Focus traversal missed control: %s" % expected_ctrl.name)

	# Clean up menu
	menu_instance.queue_free()
	await process_frame

	# =========================================================================
	# 4. Test SettingsDialog Touch Targets, A11y Metadata, and Focus Traversal
	# =========================================================================
	var dlg: SettingsDialog = SettingsDialogScript.new()
	var opener_btn := Button.new()
	opener_btn.name = "DummyOpenerBtn"
	root.add_child(opener_btn)
	dlg.opener_control = opener_btn
	root.add_child(dlg)
	await process_frame

	var sliders: Array[HSlider] = [
		dlg.get_node_or_null("Center/SettingsPanel/MainVBox/GridContainer/MasterSlider"),
		dlg.get_node_or_null("Center/SettingsPanel/MainVBox/GridContainer/BgmSlider"),
		dlg.get_node_or_null("Center/SettingsPanel/MainVBox/GridContainer/SfxSlider")
	]
	for sl: HSlider in sliders:
		if sl == null:
			failures.append("Audio slider missing in SettingsDialog")
		else:
			if sl.custom_minimum_size.y < min_target:
				failures.append("Slider %s height %.1f < min touch target %.1f" % [sl.name, sl.custom_minimum_size.y, min_target])
			if sl.accessibility_name.strip_edges().is_empty():
				failures.append("Slider %s missing accessibility_name" % sl.name)
			if sl.accessibility_description.strip_edges().is_empty():
				failures.append("Slider %s missing accessibility_description" % sl.name)

	var checkboxes: Array[CheckBox] = [
		dlg._large_text_check,
		dlg._fast_placement_check,
		dlg._screen_shake_check,
		dlg._notifications_check,
		dlg._developer_mode_check
	]
	for cb: CheckBox in checkboxes:
		if cb == null:
			failures.append("Required CheckBox missing in SettingsDialog")
		else:
			if cb.custom_minimum_size.y < min_target:
				failures.append("CheckBox %s height %.1f < min touch target %.1f" % [cb.name, cb.custom_minimum_size.y, min_target])
			if cb.accessibility_name.strip_edges().is_empty():
				failures.append("CheckBox %s missing accessibility_name" % cb.name)

	var opt: OptionButton = dlg._telemetry_option
	if opt == null:
		failures.append("TelemetryOption missing in SettingsDialog")
	else:
		if opt.custom_minimum_size.y < min_target:
			failures.append("TelemetryOption height %.1f < min touch target %.1f" % [opt.custom_minimum_size.y, min_target])
		if opt.accessibility_name.strip_edges().is_empty():
			failures.append("TelemetryOption missing accessibility_name")

	var action_buttons: Array[Button] = [
		dlg._reset_btn,
		dlg._close_btn,
		dlg._save_btn
	]
	for ab: Button in action_buttons:
		if ab == null:
			failures.append("Action button missing in SettingsDialog")
		else:
			if ab.custom_minimum_size.y < min_target:
				failures.append("Action button %s height %.1f < min touch target %.1f" % [ab.name, ab.custom_minimum_size.y, min_target])
			if ab.accessibility_name.strip_edges().is_empty():
				failures.append("Action button %s missing accessibility_name" % ab.name)

	# Focus loop in SettingsDialog
	var start_focus: Control = sliders[0]
	if start_focus != null:
		var curr_focus: Control = start_focus
		var dlg_visited: Array[Control] = []
		var loop_closed := false
		for _step in range(20):
			dlg_visited.append(curr_focus)
			var next_p := curr_focus.focus_next
			if next_p.is_empty():
				failures.append("SettingsDialog focus dead-end at: %s" % curr_focus.name)
				break
			var next_c := curr_focus.get_node_or_null(next_p) as Control
			if next_c == null:
				failures.append("SettingsDialog invalid focus_next path: %s on %s" % [str(next_p), curr_focus.name])
				break
			if next_c == start_focus:
				loop_closed = true
				break
			curr_focus = next_c

		var expected_controls: Array[Control] = []
		expected_controls.append_array(sliders)
		expected_controls.append_array(checkboxes)
		expected_controls.append(opt)
		expected_controls.append_array(action_buttons)
		for expected: Control in expected_controls:
			if expected != null and not dlg_visited.has(expected):
				failures.append("SettingsDialog focus traversal missed %s" % expected.name)
		if not loop_closed:
			failures.append("SettingsDialog focus traversal did not close its loop")

	# Test Focus Return to opener control on close
	dlg._close()
	await process_frame
	if not opener_btn.has_focus():
		failures.append("Opener control did not receive focus after SettingsDialog closed")
	opener_btn.queue_free()

	# =========================================================================
	# 5. Test Large-Text Persistence Round-Trip & Scene Scaling
	# =========================================================================
	var initial_settings := OfflinePersistence.read_settings()

	# Test 5a: write large_text = true
	var custom_settings := initial_settings.duplicate(true)
	custom_settings["large_text"] = true
	OfflinePersistence.write_settings(custom_settings)
	var loaded_true := OfflinePersistence.read_settings()
	if not bool(loaded_true.get("large_text", false)):
		failures.append("Failed to persist large_text=true via OfflinePersistence")

	# A disabled-only assertion cannot detect a missing menu scaling implementation.
	var large_menu: Control = menu_scene.instantiate()
	root.add_child(large_menu)
	await process_frame
	var large_center: Control = large_menu.get_node("Center")
	if not large_center.scale.is_equal_approx(Vector2.ONE * ThemeTokensScript.LARGE_TEXT_SCALE):
		failures.append("MainMenu did not apply persisted large_text=true")
	large_menu.queue_free()
	await process_frame

	# Test 5b: SettingsDialog loads large_text and scales panel
	var test_dlg: SettingsDialog = SettingsDialogScript.new()
	root.add_child(test_dlg)
	await process_frame
	if not test_dlg._large_text_check.button_pressed:
		failures.append("SettingsDialog did not reflect loaded large_text=true")
	var center_node: CenterContainer = test_dlg.get_node_or_null("Center")
	if center_node == null:
		failures.append("CenterContainer missing for scale test")
	elif abs(center_node.scale.x - ThemeTokensScript.LARGE_TEXT_SCALE) > 0.01:
		failures.append("Settings Center scale %.2f != expected %.2f" % [center_node.scale.x, ThemeTokensScript.LARGE_TEXT_SCALE])

	# Test 5c: toggle large_text off and save
	test_dlg._large_text_check.button_pressed = false
	test_dlg._save_settings()
	await process_frame
	var loaded_false := OfflinePersistence.read_settings()
	if bool(loaded_false.get("large_text", true)):
		failures.append("Failed to persist large_text=false via SettingsDialog save")

	# Test 5d: MainMenu scales with large_text setting
	var scaled_menu: Control = menu_scene.instantiate()
	root.add_child(scaled_menu)
	await process_frame
	var center_ctrl: Control = scaled_menu.get_node_or_null("Center")
	if center_ctrl == null:
		failures.append("Center container missing on MainMenu for scale check")
	elif abs(center_ctrl.scale.x - 1.0) > 0.01:
		failures.append("MainMenu Center scale expected 1.0 when large_text=false, got: %.2f" % center_ctrl.scale.x)
	scaled_menu.queue_free()

	# Restore the settings present before the persistence checks.
	OfflinePersistence.write_settings(initial_settings)

	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Accessibility smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Accessibility smoke: FAIL (%d)" % failures.size())
		quit(1)
