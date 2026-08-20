extends SceneTree
## Headless smoke test for U3 Settings dialog & telemetry consent persistence.

const SettingsDialogScript := preload("res://scripts/ui/settings_dialog.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	# 1. Test OfflinePersistence default settings
	var def := OfflinePersistence.default_settings()
	if not def.has("master_volume") or not def.has("telemetry_tier"):
		failures.append("default_settings missing required keys")
	if def.get("telemetry_tier") != "anonymous":
		failures.append("default telemetry tier expected 'anonymous', got: %s" % str(def.get("telemetry_tier")))
	if bool(def.get("developer_mode", true)):
		failures.append("developer_mode must default off and stay separate from telemetry")

	# 2. Test writing & reading custom settings
	var custom := {
		"master_volume": 0.5,
		"bgm_volume": 0.4,
		"sfx_volume": 0.6,
		"fast_placement": false,
		"screen_shake": false,
		"notifications_enabled": true,
		"telemetry_tier": "full"
	}
	OfflinePersistence.write_settings(custom)
	var loaded := OfflinePersistence.read_settings()
	if float(loaded.get("master_volume", 0.0)) != 0.5:
		failures.append("master_volume not persisted correctly: %s" % str(loaded.get("master_volume")))
	if str(loaded.get("telemetry_tier", "")) != "full":
		failures.append("telemetry_tier not persisted correctly: %s" % str(loaded.get("telemetry_tier")))
	if bool(loaded.get("notifications_enabled", false)) != true:
		failures.append("notifications_enabled not persisted correctly")

	# 3. Instantiate SettingsDialog UI component
	var dlg := SettingsDialogScript.new()
	root.add_child(dlg)
	await process_frame

	var panel: PanelContainer = dlg.get_node_or_null("Center/SettingsPanel")
	if panel == null:
		failures.append("SettingsPanel node not found")

	var master_slider: HSlider = dlg.get_node_or_null("Center/SettingsPanel/MainVBox/GridContainer/MasterSlider")
	if master_slider == null:
		failures.append("MasterSlider not found in dialog")
	elif abs(master_slider.value - 50.0) > 0.01:
		failures.append("MasterSlider value did not reflect loaded 50%% setting: %f" % master_slider.value)

	var telemetry_opt: OptionButton = dlg.get_node_or_null("Center/SettingsPanel/MainVBox/VBoxContainer/TelemetryOption")
	if telemetry_opt == null:
		failures.append("TelemetryOption OptionButton not found")
	elif telemetry_opt.selected != 2:
		failures.append("TelemetryOption selection did not reflect 'full' tier (expected index 2, got %d)" % telemetry_opt.selected)

	# 4. Test dialog reset to defaults
	dlg._reset_defaults()
	if abs(dlg._master_slider.value - 80.0) > 0.01:
		failures.append("Reset defaults did not restore MasterSlider to 80%%")
	if dlg._telemetry_option.selected != 1:
		failures.append("Reset defaults did not restore TelemetryOption to 'anonymous' (idx 1)")
	var dev_check: CheckBox = dlg.get_node_or_null("Center/SettingsPanel/MainVBox/DeveloperModeCheck")
	if dev_check == null:
		failures.append("DeveloperModeCheck missing from settings")
	elif dev_check.button_pressed:
		failures.append("Reset defaults left Developer Mode on")

	# 5. Test saving through dialog (array so the lambda can mutate it)
	var saved_notified := [false]
	dlg.settings_saved.connect(func(_s: Dictionary):
		saved_notified[0] = true
	)
	dlg._save_settings()
	await process_frame

	if not saved_notified[0]:
		failures.append("settings_saved signal not emitted on save")

	var re_read := OfflinePersistence.read_settings()
	if str(re_read.get("telemetry_tier", "")) != "anonymous":
		failures.append("Saved settings did not persist reset 'anonymous' tier: %s" % str(re_read.get("telemetry_tier")))

	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Settings smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Settings smoke: FAIL (%d)" % failures.size())
		quit(1)
