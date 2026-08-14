class_name SettingsDialog
extends Control
## U3 Settings Dialog — Audio, Controls, Notifications, and Telemetry Consent Tiers.
## Styled with the Wōkòu-era coastal palette (Paper, Indigo, Cinnabar, Dusk).

signal settings_saved(settings: Dictionary)
signal closed

const PAPER := Color(0.93, 0.86, 0.74, 1)
const DUSK := Color(0.18, 0.16, 0.18, 1)
const INDIGO := Color(0.12, 0.20, 0.30, 1)
const CINNABAR := Color(0.72, 0.20, 0.14, 1)
const PANEL_BG := Color(0.96, 0.93, 0.88, 0.98)
const ACCENT_BORDER := Color(0.24, 0.32, 0.40, 1)

var _current_settings: Dictionary = {}

var _master_slider: HSlider
var _master_val_label: Label
var _bgm_slider: HSlider
var _bgm_val_label: Label
var _sfx_slider: HSlider
var _sfx_val_label: Label

var _fast_placement_check: CheckBox
var _screen_shake_check: CheckBox
var _notifications_check: CheckBox
var _telemetry_option: OptionButton
var _telemetry_desc: Label

var _save_btn: Button
var _reset_btn: Button
var _close_btn: Button


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_build_ui()
	load_and_apply_settings()


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


func _save_settings() -> void:
	_current_settings["master_volume"] = _master_slider.value / 100.0
	_current_settings["bgm_volume"] = _bgm_slider.value / 100.0
	_current_settings["sfx_volume"] = _sfx_slider.value / 100.0
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

	OfflinePersistence.write_settings(_current_settings)
	settings_saved.emit(_current_settings)
	_close()


func _reset_defaults() -> void:
	_current_settings = OfflinePersistence.default_settings()
	_update_ui_from_settings()


func _close() -> void:
	closed.emit()
	queue_free()


func _update_telemetry_desc(idx: int) -> void:
	if _telemetry_desc == null:
		return
	match idx:
		0:
			_telemetry_desc.text = "Tier 0 (Strict Offline): No telemetry or analytics are collected or retained."
			_telemetry_desc.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 1))
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
	panel.custom_minimum_size = Vector2(580, 520)

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
	style.content_margin_left = 24
	style.content_margin_top = 16
	style.content_margin_right = 24
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.add_theme_constant_override("separation", 14)
	panel.add_child(main_vbox)

	# Title Header
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 2)
	var title_lbl := Label.new()
	title_lbl.text = "SETTINGS · 設置"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 24)
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
	audio_sec.add_theme_font_size_override("font_size", 14)
	audio_sec.add_theme_color_override("font_color", INDIGO)
	main_vbox.add_child(audio_sec)

	var audio_grid := GridContainer.new()
	audio_grid.name = "GridContainer"
	audio_grid.columns = 3
	audio_grid.add_theme_constant_override("h_separation", 12)
	audio_grid.add_theme_constant_override("v_separation", 6)

	# Master
	var master_lbl := Label.new()
	master_lbl.text = "Master Volume:"
	master_lbl.add_theme_color_override("font_color", DUSK)
	audio_grid.add_child(master_lbl)
	_master_slider = HSlider.new()
	_master_slider.name = "MasterSlider"
	_master_slider.custom_minimum_size = Vector2(240, 20)
	_master_slider.min_value = 0
	_master_slider.max_value = 100
	_master_slider.value = 80
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
	_bgm_slider.custom_minimum_size = Vector2(240, 20)
	_bgm_slider.min_value = 0
	_bgm_slider.max_value = 100
	_bgm_slider.value = 70
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
	_sfx_slider.custom_minimum_size = Vector2(240, 20)
	_sfx_slider.min_value = 0
	_sfx_slider.max_value = 100
	_sfx_slider.value = 90
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
	ctrl_sec.add_theme_font_size_override("font_size", 14)
	ctrl_sec.add_theme_color_override("font_color", INDIGO)
	main_vbox.add_child(ctrl_sec)

	var ctrl_hbox := HBoxContainer.new()
	ctrl_hbox.add_theme_constant_override("separation", 20)

	_fast_placement_check = CheckBox.new()
	_fast_placement_check.name = "FastPlacementCheck"
	_fast_placement_check.text = "Fast Tap Placement"
	_fast_placement_check.button_pressed = true
	_fast_placement_check.add_theme_color_override("font_color", DUSK)
	ctrl_hbox.add_child(_fast_placement_check)

	_screen_shake_check = CheckBox.new()
	_screen_shake_check.name = "ScreenShakeCheck"
	_screen_shake_check.text = "Screen Shake on Impact"
	_screen_shake_check.button_pressed = true
	_screen_shake_check.add_theme_color_override("font_color", DUSK)
	ctrl_hbox.add_child(_screen_shake_check)

	_notifications_check = CheckBox.new()
	_notifications_check.name = "NotificationsCheck"
	_notifications_check.text = "Tactical Raid Alerts"
	_notifications_check.button_pressed = false
	_notifications_check.add_theme_color_override("font_color", DUSK)
	ctrl_hbox.add_child(_notifications_check)

	main_vbox.add_child(ctrl_hbox)

	# Section 3: Telemetry & Privacy (U3 / AI Research)
	var priv_sec := Label.new()
	priv_sec.text = "DATA & TELEMETRY CONSENT"
	priv_sec.add_theme_font_size_override("font_size", 14)
	priv_sec.add_theme_color_override("font_color", INDIGO)
	main_vbox.add_child(priv_sec)

	var priv_vbox := VBoxContainer.new()
	priv_vbox.name = "VBoxContainer"
	priv_vbox.add_theme_constant_override("separation", 4)

	_telemetry_option = OptionButton.new()
	_telemetry_option.name = "TelemetryOption"
	_telemetry_option.add_item("Tier 0 — Strict Offline (No Data Collection)")
	_telemetry_option.add_item("Tier 1 — Anonymous Diagnostics & Crash Traces")
	_telemetry_option.add_item("Tier 2 — Full Balance Analytics & Civ Preferences")
	_telemetry_option.selected = 1
	_telemetry_option.item_selected.connect(_update_telemetry_desc)
	priv_vbox.add_child(_telemetry_option)

	_telemetry_desc = Label.new()
	_telemetry_desc.name = "TelemetryDesc"
	_telemetry_desc.custom_minimum_size = Vector2(520, 36)
	_telemetry_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_telemetry_desc.add_theme_font_size_override("font_size", 12)
	_update_telemetry_desc(1)
	priv_vbox.add_child(_telemetry_desc)

	main_vbox.add_child(priv_vbox)

	# Action Buttons
	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_END
	btn_hbox.add_theme_constant_override("separation", 12)

	_reset_btn = Button.new()
	_reset_btn.name = "ResetBtn"
	_reset_btn.text = "Reset Defaults"
	_reset_btn.custom_minimum_size = Vector2(120, 34)
	_reset_btn.pressed.connect(_reset_defaults)
	btn_hbox.add_child(_reset_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hbox.add_child(spacer)

	_close_btn = Button.new()
	_close_btn.name = "CancelBtn"
	_close_btn.text = "Cancel"
	_close_btn.custom_minimum_size = Vector2(90, 34)
	_close_btn.pressed.connect(_close)
	btn_hbox.add_child(_close_btn)

	_save_btn = Button.new()
	_save_btn.name = "SaveBtn"
	_save_btn.text = "Save & Apply"
	_save_btn.custom_minimum_size = Vector2(130, 34)
	_save_btn.pressed.connect(_save_settings)
	btn_hbox.add_child(_save_btn)

	main_vbox.add_child(btn_hbox)
