class_name SettingsDialog
extends Control
## U3 Settings Dialog — Audio, Controls, Notifications, and Telemetry Consent Tiers.
## Styled with the Wōkòu-era coastal palette (Paper, Indigo, Cinnabar, Dusk).

signal settings_saved(settings: Dictionary)
signal closed

const ThemeTokensScript := preload("res://scripts/ui/theme_tokens.gd")

const PAPER := ThemeTokensScript.PAPER
const DUSK := ThemeTokensScript.INK
const INDIGO := ThemeTokensScript.SEA_INDIGO
const CINNABAR := ThemeTokensScript.CINNABAR
const PANEL_BG := ThemeTokensScript.PAPER_CARD
const ACCENT_BORDER := ThemeTokensScript.SEA_INDIGO_BRIGHT

var _current_settings: Dictionary = {}
var opener_control: Control = null

var _master_slider: HSlider
var _master_val_label: Label
var _bgm_slider: HSlider
var _bgm_val_label: Label
var _sfx_slider: HSlider
var _sfx_val_label: Label

var _large_text_check: CheckBox
var _fast_placement_check: CheckBox
var _screen_shake_check: CheckBox
var _notifications_check: CheckBox
var _telemetry_option: OptionButton
var _telemetry_desc: Label
var _developer_mode_check: CheckBox

var _save_btn: Button
var _reset_btn: Button
var _close_btn: Button


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_build_ui()
	_apply_density_sizes()
	load_and_apply_settings()
	_setup_focus_traversal()
	call_deferred("_set_initial_focus")
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func load_and_apply_settings() -> void:
	_current_settings = OfflinePersistence.read_settings()
	_update_ui_from_settings()


func _update_ui_from_settings() -> void:
	var master_vol: float = float(_current_settings.get("master_volume", 0.8))
	var bgm_vol: float = float(_current_settings.get("bgm_volume", 0.7))
	var sfx_vol: float = float(_current_settings.get("sfx_volume", 0.9))

	if _master_slider:
		_master_slider.value = master_vol * 100.0
		_master_val_label.text = "%d%%" % int(_master_slider.value)
	if _bgm_slider:
		_bgm_slider.value = bgm_vol * 100.0
		_bgm_val_label.text = "%d%%" % int(_bgm_slider.value)
	if _sfx_slider:
		_sfx_slider.value = sfx_vol * 100.0
		_sfx_val_label.text = "%d%%" % int(_sfx_slider.value)

	if _large_text_check:
		_large_text_check.button_pressed = bool(_current_settings.get("large_text", false))
		_apply_ui_scale(_large_text_check.button_pressed)
	if _fast_placement_check:
		_fast_placement_check.button_pressed = bool(_current_settings.get("fast_placement", true))
	if _screen_shake_check:
		_screen_shake_check.button_pressed = bool(_current_settings.get("screen_shake", true))
	if _notifications_check:
		_notifications_check.button_pressed = bool(_current_settings.get("notifications_enabled", false))

	var tier: String = str(_current_settings.get("telemetry_tier", "anonymous"))
	if _telemetry_option:
		match tier:
			"none":
				_telemetry_option.selected = 0
			"anonymous":
				_telemetry_option.selected = 1
			"full":
				_telemetry_option.selected = 2
			_:
				_telemetry_option.selected = 1
		_update_telemetry_desc(_telemetry_option.selected)
	if _developer_mode_check:
		_developer_mode_check.button_pressed = bool(_current_settings.get("developer_mode", false))


func _save_settings() -> void:
	_current_settings["master_volume"] = _master_slider.value / 100.0
	_current_settings["bgm_volume"] = _bgm_slider.value / 100.0
	_current_settings["sfx_volume"] = _sfx_slider.value / 100.0
	if _large_text_check:
		_current_settings["large_text"] = _large_text_check.button_pressed
		_apply_ui_scale(_large_text_check.button_pressed)
	_current_settings["fast_placement"] = _fast_placement_check.button_pressed
	_current_settings["screen_shake"] = _screen_shake_check.button_pressed
	_current_settings["notifications_enabled"] = _notifications_check.button_pressed

	match _telemetry_option.selected:
		0:
			_current_settings["telemetry_tier"] = "none"
		1:
			_current_settings["telemetry_tier"] = "anonymous"
		2:
			_current_settings["telemetry_tier"] = "full"
	_current_settings["developer_mode"] = _developer_mode_check.button_pressed
	var session := get_tree().root.get_node_or_null("GameSession")
	if session:
		session.set_developer_mode(_developer_mode_check.button_pressed, false)

	OfflinePersistence.write_settings(_current_settings)
	settings_saved.emit(_current_settings)
	_close()


func _reset_defaults() -> void:
	_current_settings = OfflinePersistence.default_settings()
	_current_settings["large_text"] = false
	_update_ui_from_settings()


func _close() -> void:
	closed.emit()
	if is_instance_valid(opener_control) and opener_control.is_inside_tree():
		opener_control.call_deferred("grab_focus")
	queue_free()


## Returns the logical-unit minimum height required for ≥48dp window pixels at current window.
func _density_min_h() -> float:
	var tree := get_tree()
	var ws := ThemeTokensScript.CANVAS_DESIGN_SIZE
	if tree and tree.root and tree.root.size.x >= 200 and tree.root.size.y >= 200:
		ws = Vector2(tree.root.size)
	else:
		var ds_size := DisplayServer.window_get_size()
		if ds_size.x >= 200 and ds_size.y >= 200:
			ws = Vector2(ds_size)
	return ThemeTokensScript.compute_density_min_size(ws)


func _apply_density_sizes() -> void:
	var min_h: float = _density_min_h()
	var vp: Viewport = get_viewport()
	var vp_h: float = vp.get_visible_rect().size.y if vp else ThemeTokensScript.CANVAS_DESIGN_SIZE.y
	var vp_w: float = vp.get_visible_rect().size.x if vp else ThemeTokensScript.CANVAS_DESIGN_SIZE.x
	var is_compact_landscape: bool = vp_h <= 720.0 and vp_w > 1280.0

	var panel: PanelContainer = get_node_or_null("Center/SettingsPanel")
	if panel:
		panel.custom_minimum_size = Vector2(clampf(vp_w * 0.70, 720.0, 1080.0) if is_compact_landscape else 680.0, 0)

	var audio_grid: GridContainer = get_node_or_null("Center/SettingsPanel/MainVBox/GridContainer")
	if audio_grid:
		audio_grid.columns = 9 if is_compact_landscape else 3

	var slider_w: float = 120.0 if is_compact_landscape else 160.0
	for sl in [_master_slider, _bgm_slider, _sfx_slider]:
		if sl:
			sl.custom_minimum_size = Vector2(slider_w, min_h)

	for cb in [_fast_placement_check, _screen_shake_check, _notifications_check, _large_text_check, _developer_mode_check]:
		if cb:
			cb.custom_minimum_size = Vector2(0, min_h)

	if _telemetry_option:
		_telemetry_option.custom_minimum_size = Vector2(0, min_h)

	for btn in [_reset_btn, _close_btn, _save_btn]:
		if btn:
			btn.custom_minimum_size = Vector2(btn.custom_minimum_size.x, min_h)

	var main_vbox: VBoxContainer = get_node_or_null("Center/SettingsPanel/MainVBox")
	if main_vbox:
		main_vbox.add_theme_constant_override("separation", 2 if is_compact_landscape else 4)


func _on_viewport_size_changed() -> void:
	_apply_density_sizes()
	if _large_text_check:
		_apply_ui_scale(_large_text_check.button_pressed)
	var center: CenterContainer = get_node_or_null("Center")
	if center:
		center.pivot_offset = center.size / 2.0


func _apply_ui_scale(enabled: bool) -> void:
	var center: CenterContainer = get_node_or_null("Center")
	if center:
		var s: float = 1.0
		if enabled:
			s = ThemeTokensScript.LARGE_TEXT_SCALE
			var vp: Viewport = get_viewport()
			var panel: Control = center.get_node_or_null("SettingsPanel")
			if vp and panel:
				var panel_h: float = maxf(panel.size.y, panel.get_combined_minimum_size().y)
				if panel_h > 0.0:
					var avail_h: float = vp.get_visible_rect().size.y - 16.0
					var max_s: float = avail_h / panel_h
					s = minf(s, max_s)
		center.pivot_offset = center.size / 2.0
		center.scale = Vector2(s, s)
		if not center.resized.is_connected(_on_center_resized):
			center.resized.connect(_on_center_resized)


func _on_center_resized() -> void:
	var center: CenterContainer = get_node_or_null("Center")
	if center:
		center.pivot_offset = center.size / 2.0


func _update_telemetry_desc(idx: int) -> void:
	if _telemetry_desc == null:
		return
	match idx:
		0:
			_telemetry_desc.text = "Tier 0 (Strict Offline): No telemetry or analytics are collected or retained."
			_telemetry_desc.add_theme_color_override("font_color", ThemeTokensScript.INK_MUTED)
		1:
			_telemetry_desc.text = "Tier 1 (Anonymous Diagnostics): Anonymous frame times, render metrics, and crash diagnostics to improve engine performance."
			_telemetry_desc.add_theme_color_override("font_color", INDIGO)
		2:
			_telemetry_desc.text = "Tier 2 (Full Gameplay Analytics): Anonymous civ/hero preferences and wave survival curves to assist tactical balance tuning."
			_telemetry_desc.add_theme_color_override("font_color", CINNABAR)


func _build_ui() -> void:
	# Dim backdrop
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.65)
	add_child(backdrop)

	# Main Panel Container centered
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.custom_minimum_size = Vector2(560, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = INDIGO
	style.border_width_left = 3
	style.border_width_top = 8
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 20
	style.content_margin_top = 10
	style.content_margin_right = 20
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	ThemeTokensScript.animate_fade_in(panel, 0.25)

	var main_vbox := VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.add_theme_constant_override("separation", 5)
	panel.add_child(main_vbox)

	# Title Header
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 1)
	var title_lbl := Label.new()
	title_lbl.text = "SETTINGS · 設置"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", DUSK)
	title_box.add_child(title_lbl)

	var subtitle_lbl := Label.new()
	subtitle_lbl.text = "Audio, Controls, & Telemetry Privacy"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 12)
	subtitle_lbl.add_theme_color_override("font_color", CINNABAR)
	title_box.add_child(subtitle_lbl)
	main_vbox.add_child(title_box)

	# Section 1: Audio
	var audio_sec := Label.new()
	audio_sec.text = "AUDIO"
	audio_sec.add_theme_font_size_override("font_size", 12)
	audio_sec.add_theme_color_override("font_color", INDIGO)
	main_vbox.add_child(audio_sec)

	var audio_grid := GridContainer.new()
	audio_grid.name = "GridContainer"
	audio_grid.columns = 3
	audio_grid.add_theme_constant_override("h_separation", 8)
	audio_grid.add_theme_constant_override("v_separation", 2)

	# Master
	var master_lbl := Label.new()
	master_lbl.text = "Master Volume:"
	master_lbl.add_theme_color_override("font_color", DUSK)
	audio_grid.add_child(master_lbl)
	_master_slider = HSlider.new()
	_master_slider.name = "MasterSlider"
	_master_slider.custom_minimum_size = Vector2(220, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	_master_slider.min_value = 0
	_master_slider.max_value = 100
	_master_slider.value = 80
	ThemeTokensScript.set_a11y_metadata(_master_slider, "Master Volume", "Adjust master audio level")
	audio_grid.add_child(_master_slider)
	_master_val_label = Label.new()
	_master_val_label.name = "MasterValLabel"
	_master_val_label.text = "80%"
	_master_val_label.custom_minimum_size = Vector2(45, 0)
	_master_val_label.add_theme_color_override("font_color", DUSK)
	audio_grid.add_child(_master_val_label)
	_master_slider.value_changed.connect(func(v: float): _master_val_label.text = "%d%%" % int(v))

	# BGM
	var bgm_lbl := Label.new()
	bgm_lbl.text = "Music (BGM):"
	bgm_lbl.add_theme_color_override("font_color", DUSK)
	audio_grid.add_child(bgm_lbl)
	_bgm_slider = HSlider.new()
	_bgm_slider.name = "BgmSlider"
	_bgm_slider.custom_minimum_size = Vector2(220, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	_bgm_slider.min_value = 0
	_bgm_slider.max_value = 100
	_bgm_slider.value = 70
	ThemeTokensScript.set_a11y_metadata(_bgm_slider, "Music Volume", "Adjust background music volume")
	audio_grid.add_child(_bgm_slider)
	_bgm_val_label = Label.new()
	_bgm_val_label.name = "BgmValLabel"
	_bgm_val_label.text = "70%"
	_bgm_val_label.custom_minimum_size = Vector2(45, 0)
	_bgm_val_label.add_theme_color_override("font_color", DUSK)
	audio_grid.add_child(_bgm_val_label)
	_bgm_slider.value_changed.connect(func(v: float): _bgm_val_label.text = "%d%%" % int(v))

	# SFX
	var sfx_lbl := Label.new()
	sfx_lbl.text = "Sound Effects:"
	sfx_lbl.add_theme_color_override("font_color", DUSK)
	audio_grid.add_child(sfx_lbl)
	_sfx_slider = HSlider.new()
	_sfx_slider.name = "SfxSlider"
	_sfx_slider.custom_minimum_size = Vector2(220, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	_sfx_slider.min_value = 0
	_sfx_slider.max_value = 100
	_sfx_slider.value = 90
	ThemeTokensScript.set_a11y_metadata(_sfx_slider, "Sound Effects Volume", "Adjust tactical sound effects volume")
	audio_grid.add_child(_sfx_slider)
	_sfx_val_label = Label.new()
	_sfx_val_label.name = "SfxValLabel"
	_sfx_val_label.text = "90%"
	_sfx_val_label.custom_minimum_size = Vector2(45, 0)
	_sfx_val_label.add_theme_color_override("font_color", DUSK)
	audio_grid.add_child(_sfx_val_label)
	_sfx_slider.value_changed.connect(func(v: float): _sfx_val_label.text = "%d%%" % int(v))

	main_vbox.add_child(audio_grid)

	# Section 2: Controls & Feedback
	var ctrl_sec := Label.new()
	ctrl_sec.text = "CONTROLS & DISPLAY"
	ctrl_sec.add_theme_font_size_override("font_size", 12)
	ctrl_sec.add_theme_color_override("font_color", INDIGO)
	main_vbox.add_child(ctrl_sec)

	var ctrl_hbox := HBoxContainer.new()
	ctrl_hbox.add_theme_constant_override("separation", 8)

	_fast_placement_check = CheckBox.new()
	_fast_placement_check.name = "FastPlacementCheck"
	_fast_placement_check.text = "Fast Tap Placement"
	_fast_placement_check.button_pressed = true
	_fast_placement_check.custom_minimum_size = Vector2(0, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	ThemeTokensScript.set_a11y_metadata(_fast_placement_check, "Fast Tap Placement", "Tap once to immediately deploy units")
	ctrl_hbox.add_child(_fast_placement_check)

	_screen_shake_check = CheckBox.new()
	_screen_shake_check.name = "ScreenShakeCheck"
	_screen_shake_check.text = "Screen Shake on Impact"
	_screen_shake_check.button_pressed = true
	_screen_shake_check.custom_minimum_size = Vector2(0, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	ThemeTokensScript.set_a11y_metadata(_screen_shake_check, "Screen Shake", "Enable camera shake during combat explosions")
	ctrl_hbox.add_child(_screen_shake_check)

	_notifications_check = CheckBox.new()
	_notifications_check.name = "NotificationsCheck"
	_notifications_check.text = "Tactical Raid Alerts"
	_notifications_check.button_pressed = false
	_notifications_check.custom_minimum_size = Vector2(0, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	ThemeTokensScript.set_a11y_metadata(_notifications_check, "Tactical Alerts", "Receive notifications when Wōkòu fleets approach")
	ctrl_hbox.add_child(_notifications_check)

	_large_text_check = CheckBox.new()
	_large_text_check.name = "LargeTextCheck"
	_large_text_check.text = "Large Text (UI Scale)"
	_large_text_check.button_pressed = false
	_large_text_check.custom_minimum_size = Vector2(0, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	_large_text_check.toggled.connect(func(pressed: bool):
		_apply_ui_scale(pressed)
	)
	ThemeTokensScript.set_a11y_metadata(_large_text_check, "Large Text", "Enable large text and scaled user interface")
	ctrl_hbox.add_child(_large_text_check)

	main_vbox.add_child(ctrl_hbox)

	# Section 3: Telemetry & Privacy (U3 / AI Research)
	var priv_sec := Label.new()
	priv_sec.text = "DATA & TELEMETRY CONSENT"
	priv_sec.add_theme_font_size_override("font_size", 12)
	priv_sec.add_theme_color_override("font_color", INDIGO)
	main_vbox.add_child(priv_sec)

	var priv_vbox := VBoxContainer.new()
	priv_vbox.name = "VBoxContainer"
	priv_vbox.add_theme_constant_override("separation", 2)

	_telemetry_option = OptionButton.new()
	_telemetry_option.name = "TelemetryOption"
	_telemetry_option.add_item("Tier 0 — Strict Offline (No Data Collection)")
	_telemetry_option.add_item("Tier 1 — Anonymous Diagnostics & Crash Traces")
	_telemetry_option.add_item("Tier 2 — Full Balance Analytics & Civ Preferences")
	_telemetry_option.selected = 1
	_telemetry_option.custom_minimum_size = Vector2(0, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	ThemeTokensScript.set_a11y_metadata(_telemetry_option, "Data and Telemetry Consent", "Choose telemetry privacy tier")
	_telemetry_option.item_selected.connect(_update_telemetry_desc)
	priv_vbox.add_child(_telemetry_option)

	_telemetry_desc = Label.new()
	_telemetry_desc.name = "TelemetryDesc"
	_telemetry_desc.custom_minimum_size = Vector2(480, 28)
	_telemetry_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_telemetry_desc.add_theme_font_size_override("font_size", 11)
	_update_telemetry_desc(1)
	priv_vbox.add_child(_telemetry_desc)

	main_vbox.add_child(priv_vbox)

	var dev_sec := Label.new()
	dev_sec.text = "DEVELOPER MODE"
	dev_sec.add_theme_font_size_override("font_size", 12)
	dev_sec.add_theme_color_override("font_color", INDIGO)
	main_vbox.add_child(dev_sec)
	_developer_mode_check = CheckBox.new()
	_developer_mode_check.name = "DeveloperModeCheck"
	_developer_mode_check.text = "Enable developer tools (not telemetry)"
	_developer_mode_check.custom_minimum_size = Vector2(0, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	ThemeTokensScript.set_a11y_metadata(_developer_mode_check, "Developer Tools", "Enable scenario control and developer diagnostics")
	main_vbox.add_child(_developer_mode_check)

	# Action Buttons
	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_END
	btn_hbox.add_theme_constant_override("separation", 10)

	_reset_btn = Button.new()
	_reset_btn.name = "ResetBtn"
	_reset_btn.text = "Reset Defaults"
	_reset_btn.custom_minimum_size = Vector2(130, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	_reset_btn.pressed.connect(_reset_defaults)
	ThemeTokensScript.set_a11y_metadata(_reset_btn, "Reset Defaults", "Restore all settings to default values")
	btn_hbox.add_child(_reset_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hbox.add_child(spacer)

	_close_btn = Button.new()
	_close_btn.name = "CancelBtn"
	_close_btn.text = "Cancel"
	_close_btn.custom_minimum_size = Vector2(100, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	_close_btn.pressed.connect(_close)
	ThemeTokensScript.set_a11y_metadata(_close_btn, "Cancel", "Discard changes and close settings")
	btn_hbox.add_child(_close_btn)

	_save_btn = Button.new()
	_save_btn.name = "SaveBtn"
	_save_btn.text = "Save & Apply"
	_save_btn.custom_minimum_size = Vector2(130, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	_save_btn.pressed.connect(_save_settings)
	ThemeTokensScript.set_a11y_metadata(_save_btn, "Save and Apply", "Save settings to offline persistence and apply")
	btn_hbox.add_child(_save_btn)

	main_vbox.add_child(btn_hbox)


func _setup_focus_traversal() -> void:
	var controls: Array[Control] = [
		_master_slider,
		_bgm_slider,
		_sfx_slider,
		_fast_placement_check,
		_screen_shake_check,
		_notifications_check,
		_large_text_check,
		_telemetry_option,
		_developer_mode_check,
		_reset_btn,
		_close_btn,
		_save_btn
	]

	# Apply accessible styling (contrast + focus rings) to all interactive controls
	for ctrl in controls:
		if ctrl is CheckBox:
			ThemeTokensScript.apply_accessible_checkbox(ctrl as CheckBox)
		elif ctrl is Button:
			ThemeTokensScript.apply_accessible_button(ctrl as Button)
		else:
			ThemeTokensScript.apply_accessible_focus(ctrl)

	# Closed-loop next / previous focus chain
	for i in range(controls.size()):
		var ctrl := controls[i]
		if ctrl == null:
			continue
		var next_ctrl := controls[(i + 1) % controls.size()]
		var prev_ctrl := controls[(i - 1 + controls.size()) % controls.size()]
		ctrl.focus_next = next_ctrl.get_path()
		ctrl.focus_previous = prev_ctrl.get_path()

	# Explicit directional navigation trapped completely inside SettingsDialog in all 4 directions:
	# Sliders: vertical between sliders; horizontal stays on self (so left/right adjusts value)
	_master_slider.focus_neighbor_top = _save_btn.get_path()
	_master_slider.focus_neighbor_bottom = _bgm_slider.get_path()
	_master_slider.focus_neighbor_left = _master_slider.get_path()
	_master_slider.focus_neighbor_right = _master_slider.get_path()

	_bgm_slider.focus_neighbor_top = _master_slider.get_path()
	_bgm_slider.focus_neighbor_bottom = _sfx_slider.get_path()
	_bgm_slider.focus_neighbor_left = _bgm_slider.get_path()
	_bgm_slider.focus_neighbor_right = _bgm_slider.get_path()

	_sfx_slider.focus_neighbor_top = _bgm_slider.get_path()
	_sfx_slider.focus_neighbor_bottom = _fast_placement_check.get_path()
	_sfx_slider.focus_neighbor_left = _sfx_slider.get_path()
	_sfx_slider.focus_neighbor_right = _sfx_slider.get_path()

	# Controls row (4 checkboxes in HBox):
	_fast_placement_check.focus_neighbor_top = _sfx_slider.get_path()
	_fast_placement_check.focus_neighbor_bottom = _telemetry_option.get_path()
	_fast_placement_check.focus_neighbor_left = _large_text_check.get_path()
	_fast_placement_check.focus_neighbor_right = _screen_shake_check.get_path()

	_screen_shake_check.focus_neighbor_top = _sfx_slider.get_path()
	_screen_shake_check.focus_neighbor_bottom = _telemetry_option.get_path()
	_screen_shake_check.focus_neighbor_left = _fast_placement_check.get_path()
	_screen_shake_check.focus_neighbor_right = _notifications_check.get_path()

	_notifications_check.focus_neighbor_top = _sfx_slider.get_path()
	_notifications_check.focus_neighbor_bottom = _telemetry_option.get_path()
	_notifications_check.focus_neighbor_left = _screen_shake_check.get_path()
	_notifications_check.focus_neighbor_right = _large_text_check.get_path()

	_large_text_check.focus_neighbor_top = _sfx_slider.get_path()
	_large_text_check.focus_neighbor_bottom = _telemetry_option.get_path()
	_large_text_check.focus_neighbor_left = _notifications_check.get_path()
	_large_text_check.focus_neighbor_right = _fast_placement_check.get_path()

	# Telemetry tier dropdown:
	_telemetry_option.focus_neighbor_top = _fast_placement_check.get_path()
	_telemetry_option.focus_neighbor_bottom = _developer_mode_check.get_path()
	_telemetry_option.focus_neighbor_left = _telemetry_option.get_path()
	_telemetry_option.focus_neighbor_right = _telemetry_option.get_path()

	# Developer mode toggle:
	_developer_mode_check.focus_neighbor_top = _telemetry_option.get_path()
	_developer_mode_check.focus_neighbor_bottom = _reset_btn.get_path()
	_developer_mode_check.focus_neighbor_left = _developer_mode_check.get_path()
	_developer_mode_check.focus_neighbor_right = _developer_mode_check.get_path()

	# Action buttons (Reset, Cancel, Save):
	_reset_btn.focus_neighbor_top = _developer_mode_check.get_path()
	_reset_btn.focus_neighbor_bottom = _master_slider.get_path()
	_reset_btn.focus_neighbor_left = _save_btn.get_path()
	_reset_btn.focus_neighbor_right = _close_btn.get_path()

	_close_btn.focus_neighbor_top = _developer_mode_check.get_path()
	_close_btn.focus_neighbor_bottom = _master_slider.get_path()
	_close_btn.focus_neighbor_left = _reset_btn.get_path()
	_close_btn.focus_neighbor_right = _save_btn.get_path()

	_save_btn.focus_neighbor_top = _developer_mode_check.get_path()
	_save_btn.focus_neighbor_bottom = _master_slider.get_path()
	_save_btn.focus_neighbor_left = _close_btn.get_path()
	_save_btn.focus_neighbor_right = _reset_btn.get_path()


func _set_initial_focus() -> void:
	if _master_slider:
		_master_slider.grab_focus()
