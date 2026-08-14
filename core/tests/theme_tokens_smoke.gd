extends SceneTree
## Headless smoke test for U10 ThemeTokens design system & transition helpers.

const ThemeTokensScript := preload("res://scripts/ui/theme_tokens.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	# 1. Test color constants
	if ThemeTokensScript.INK == Color.TRANSPARENT:
		failures.append("INK color constant invalid")
	if ThemeTokensScript.CINNABAR == Color.TRANSPARENT:
		failures.append("CINNABAR color constant invalid")
	if ThemeTokensScript.PAPER == Color.TRANSPARENT:
		failures.append("PAPER color constant invalid")

	# 2. Test glyph constants
	if ThemeTokensScript.GLYPH_LAND_CURRENCY != "兩":
		failures.append("GLYPH_LAND_CURRENCY mismatch")
	if ThemeTokensScript.GLYPH_SEA_CURRENCY != "海關兩":
		failures.append("GLYPH_SEA_CURRENCY mismatch")

	# 3. Test StyleBox generators
	var panel_style := ThemeTokensScript.make_panel_style()
	if panel_style == null:
		failures.append("make_panel_style returned null")
	elif panel_style.border_color != ThemeTokensScript.CINNABAR:
		failures.append("make_panel_style default border mismatch")

	var btn_style := ThemeTokensScript.make_button_style()
	if btn_style == null:
		failures.append("make_button_style returned null")

	# 4. Test Animation Helpers on in-tree node
	var dummy_ctrl := Control.new()
	root.add_child(dummy_ctrl)
	dummy_ctrl.position = Vector2(100, 100)

	ThemeTokensScript.animate_fade_in(dummy_ctrl, 0.1)
	if not dummy_ctrl.visible:
		failures.append("animate_fade_in did not set visible=true")

	ThemeTokensScript.animate_slide_fade_in(dummy_ctrl, -10.0, 0.1)
	if not dummy_ctrl.visible:
		failures.append("animate_slide_fade_in did not set visible=true")

	await process_frame
	dummy_ctrl.queue_free()

	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("ThemeTokens smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("ThemeTokens smoke: FAIL (%d)" % failures.size())
		quit(1)
