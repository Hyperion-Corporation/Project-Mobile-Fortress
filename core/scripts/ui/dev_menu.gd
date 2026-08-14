extends CanvasLayer
## DT8 overlay + DT5 diagnostics + DT4 pause/step/speed + DT3 spawn/jump/reload.

const UnitDefsScript := preload("res://scripts/data/unit_defs.gd")

const INK := Color(0.10, 0.09, 0.12, 1)
const PAPER := Color(0.93, 0.86, 0.74, 0.94)
const CINNABAR := Color(0.72, 0.20, 0.14, 1)

var _diag: Label
var _speed_slider: HSlider
var _speed_label: Label
var _pause_btn: Button
var _front_select: OptionButton
var _type_select: OptionButton
var _cell_x: SpinBox
var _cell_y: SpinBox
var _wave_spin: SpinBox
var _click_spawn_btn: Button


func _ready() -> void:
	layer = 128
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	name = "DevMenu"
	_build()


func _process(_delta: float) -> void:
	if visible:
		_refresh_diag()


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -360
	panel.offset_top = 12
	panel.offset_right = -12
	panel.offset_bottom = 700
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = CINNABAR
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title := Label.new()
	title.name = "Title"
	title.text = "DEVELOPER · DT3 / DT4 / DT5"
	title.add_theme_color_override("font_color", CINNABAR)
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	_diag = Label.new()
	_diag.name = "DiagLabel"
	_diag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_diag.custom_minimum_size = Vector2(320, 0)
	_diag.add_theme_color_override("font_color", INK)
	_diag.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_diag)

	var time_sec := Label.new()
	time_sec.text = "TIME (DT4)"
	time_sec.add_theme_color_override("font_color", CINNABAR)
	time_sec.add_theme_font_size_override("font_size", 13)
	vbox.add_child(time_sec)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	_pause_btn = Button.new()
	_pause_btn.name = "PauseBtn"
	_pause_btn.text = "Pause"
	_pause_btn.pressed.connect(_on_pause_pressed)
	btn_row.add_child(_pause_btn)
	var step_btn := Button.new()
	step_btn.name = "StepBtn"
	step_btn.text = "Step 1/30s"
	step_btn.pressed.connect(_on_step_pressed)
	btn_row.add_child(step_btn)
	vbox.add_child(btn_row)

	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 8)
	_speed_label = Label.new()
	_speed_label.name = "SpeedLabel"
	_speed_label.custom_minimum_size = Vector2(56, 0)
	_speed_label.add_theme_color_override("font_color", INK)
	speed_row.add_child(_speed_label)
	_speed_slider = HSlider.new()
	_speed_slider.name = "SpeedSlider"
	_speed_slider.min_value = 0.5
	_speed_slider.max_value = 10.0
	_speed_slider.step = 0.5
	_speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speed_slider.value_changed.connect(_on_speed_changed)
	speed_row.add_child(_speed_slider)
	vbox.add_child(speed_row)

	var cheat_sec := Label.new()
	cheat_sec.text = "CHEATS (DT1 / DT2)"
	cheat_sec.add_theme_color_override("font_color", CINNABAR)
	cheat_sec.add_theme_font_size_override("font_size", 13)
	vbox.add_child(cheat_sec)

	var front_row := HBoxContainer.new()
	front_row.add_theme_constant_override("separation", 6)
	var front_lbl := Label.new()
	front_lbl.text = "Front"
	front_lbl.add_theme_color_override("font_color", INK)
	front_row.add_child(front_lbl)
	_front_select = OptionButton.new()
	_front_select.name = "FrontSelect"
	_front_select.add_item("Land", 0)
	_front_select.add_item("Sea", 1)
	_front_select.add_item("Both", 2)
	_front_select.select(2)
	front_row.add_child(_front_select)
	vbox.add_child(front_row)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	_add_cheat_btn(row1, "Fill 兩", _on_fill_res, "FillResBtn")
	_add_cheat_btn(row1, "∞ 兩", _on_toggle_infinite, "InfiniteResBtn")
	_add_cheat_btn(row1, "Income now", _on_income_now)
	vbox.add_child(row1)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	_add_cheat_btn(row2, "Skip build", _on_skip_build)
	_add_cheat_btn(row2, "Invuln", _on_toggle_invuln)
	_add_cheat_btn(row2, "Kill raiders", _on_kill_raiders)
	vbox.add_child(row2)
	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 6)
	_add_cheat_btn(row3, "No waves", _on_toggle_waves)
	_add_cheat_btn(row3, "Force win", _on_force_win)
	_add_cheat_btn(row3, "Force lose", _on_force_lose)
	vbox.add_child(row3)

	var scen_sec := Label.new()
	scen_sec.text = "SCENARIO (DT3)"
	scen_sec.add_theme_color_override("font_color", CINNABAR)
	scen_sec.add_theme_font_size_override("font_size", 13)
	vbox.add_child(scen_sec)

	var type_row := HBoxContainer.new()
	type_row.add_theme_constant_override("separation", 6)
	var type_lbl := Label.new()
	type_lbl.text = "Type"
	type_lbl.add_theme_color_override("font_color", INK)
	type_row.add_child(type_lbl)
	_type_select = OptionButton.new()
	_type_select.name = "SpawnTypeSelect"
	for unit_id in UnitDefsScript.catalog().keys():
		_type_select.add_item(str(unit_id))
	type_row.add_child(_type_select)
	vbox.add_child(type_row)

	var cell_row := HBoxContainer.new()
	cell_row.add_theme_constant_override("separation", 6)
	var cell_lbl := Label.new()
	cell_lbl.text = "Cell"
	cell_lbl.add_theme_color_override("font_color", INK)
	cell_row.add_child(cell_lbl)
	_cell_x = SpinBox.new()
	_cell_x.name = "CellX"
	_cell_x.min_value = 0
	_cell_x.max_value = 7
	_cell_x.value = 2
	_cell_x.rounded = true
	cell_row.add_child(_cell_x)
	_cell_y = SpinBox.new()
	_cell_y.name = "CellY"
	_cell_y.min_value = 0
	_cell_y.max_value = 4
	_cell_y.value = 1
	_cell_y.rounded = true
	cell_row.add_child(_cell_y)
	vbox.add_child(cell_row)

	var spawn_row := HBoxContainer.new()
	spawn_row.add_theme_constant_override("separation", 6)
	_add_cheat_btn(spawn_row, "Spawn at cell", _on_spawn_at_cell, "SpawnAtCellBtn")
	_click_spawn_btn = Button.new()
	_click_spawn_btn.name = "ClickSpawnBtn"
	_click_spawn_btn.text = "Click spawn"
	_click_spawn_btn.pressed.connect(_on_toggle_click_spawn)
	spawn_row.add_child(_click_spawn_btn)
	vbox.add_child(spawn_row)

	var wave_row := HBoxContainer.new()
	wave_row.add_theme_constant_override("separation", 6)
	var wave_lbl := Label.new()
	wave_lbl.text = "Wave"
	wave_lbl.add_theme_color_override("font_color", INK)
	wave_row.add_child(wave_lbl)
	_wave_spin = SpinBox.new()
	_wave_spin.name = "WaveSpin"
	_wave_spin.min_value = 1
	_wave_spin.max_value = 8
	_wave_spin.value = 1
	_wave_spin.rounded = true
	wave_row.add_child(_wave_spin)
	_add_cheat_btn(wave_row, "Jump wave", _on_jump_wave, "JumpWaveBtn")
	_add_cheat_btn(wave_row, "Reload level", _on_reload_level, "ReloadLevelBtn")
	vbox.add_child(wave_row)

	var hint := Label.new()
	hint.text = "~ / F12 close · pause uses the same T11 clock"
	hint.add_theme_color_override("font_color", Color(0.3, 0.28, 0.26, 1))
	hint.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hint)

	var close_btn := Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "Close"
	close_btn.pressed.connect(func():
		var session := get_tree().root.get_node_or_null("GameSession")
		if session:
			session.set_dev_menu_open(false)
	)
	vbox.add_child(close_btn)
	_bind_session()


func _bind_session() -> void:
	var session := get_tree().root.get_node_or_null("GameSession") if get_tree() else null
	if session == null:
		return
	if not session.pause_changed.is_connected(_on_pause_changed):
		session.pause_changed.connect(_on_pause_changed)
	_speed_slider.value = float(session.time_scale)
	_on_speed_changed(_speed_slider.value)
	_on_pause_changed(bool(session.is_paused))


func _session() -> Node:
	if get_tree() == null:
		return null
	return get_tree().root.get_node_or_null("GameSession")


func _on_pause_pressed() -> void:
	var session := _session()
	if session:
		session.toggle_paused()


func _on_step_pressed() -> void:
	var session := _session()
	if session:
		session.set_paused(true)
		session.request_step()


func _on_speed_changed(value: float) -> void:
	var session := _session()
	if session:
		session.set_time_scale(value)
		_speed_label.text = "%.1fx" % session.time_scale
	else:
		_speed_label.text = "%.1fx" % value


func _on_pause_changed(paused: bool) -> void:
	if _pause_btn:
		_pause_btn.text = "Resume" if paused else "Pause"


func _refresh_diag() -> void:
	if _diag == null:
		return
	var session := _session()
	var fps := Engine.get_frames_per_second()
	var tick_ms := 0.0
	var land_n := 0
	var sea_n := 0
	var defs := 0
	if session:
		tick_ms = float(session.last_sim_tick_ms)
		land_n = int(session.last_raider_land)
		sea_n = int(session.last_raider_sea)
		defs = int(session.last_defender_count)
	var mem_line := "mem: n/a"
	if Performance.has_method("get_monitor"):
		var bytes := float(Performance.get_monitor(Performance.MEMORY_STATIC))
		if bytes > 0.0:
			mem_line = "static mem: %.1f MB" % (bytes / (1024.0 * 1024.0))
	_diag.text = "FPS %.0f · tick %.2f ms\nraiders L %d / S %d · defenders %d\n%s" % [
		fps, tick_ms, land_n, sea_n, defs, mem_line
	]
	var sim := _find_sim()
	if sim and sim.has_method("get_wave_count") and _wave_spin:
		var n: int = int(sim.get_wave_count())
		if n > 0:
			_wave_spin.max_value = n


func _add_cheat_btn(row: HBoxContainer, caption: String, cb: Callable, node_name: String = "") -> void:
	var b := Button.new()
	b.text = caption
	if node_name != "":
		b.name = node_name
	b.pressed.connect(cb)
	row.add_child(b)


func _selected_front() -> int:
	if _front_select == null:
		return -1
	var id := _front_select.get_item_id(_front_select.selected)
	return -1 if id == 2 else id


func _find_sim() -> Node:
	if get_tree() == null:
		return null
	return get_tree().root.find_child("SimulationCore", true, false)


func _find_battle() -> Node:
	if get_tree() == null:
		return null
	return get_tree().root.find_child("BattleRoot", true, false)


func _on_fill_res() -> void:
	var sim := _find_sim()
	if sim and sim.has_method("debug_set_resources"):
		sim.debug_set_resources(_selected_front(), 999)


func _on_toggle_infinite() -> void:
	var sim := _find_sim()
	if sim and sim.has_method("debug_set_infinite_resources"):
		var front := _selected_front()
		var on: bool = not bool(sim.debug_infinite_resources(front))
		sim.debug_set_infinite_resources(front, on)


func _on_income_now() -> void:
	var sim := _find_sim()
	if sim and sim.has_method("debug_apply_income"):
		sim.debug_apply_income()


func _on_skip_build() -> void:
	var battle := _find_battle()
	if battle and battle.has_method("_start_combat"):
		battle.build_time_left = 0.0
		battle._start_combat()


func _on_toggle_invuln() -> void:
	var sim := _find_sim()
	if sim and sim.has_method("debug_set_invincible"):
		sim.debug_set_invincible(not bool(sim.debug_invincible()))


func _on_kill_raiders() -> void:
	var sim := _find_sim()
	if sim and sim.has_method("debug_kill_all_raiders"):
		sim.debug_kill_all_raiders()


func _on_toggle_waves() -> void:
	var sim := _find_sim()
	if sim and sim.has_method("debug_set_waves_disabled"):
		sim.debug_set_waves_disabled(not bool(sim.debug_waves_disabled()))


func _on_force_win() -> void:
	var battle := _find_battle()
	if battle and battle.has_method("_finish"):
		battle._finish(true, "DT2 force win")
	else:
		var session := _session()
		if session:
			session.end_run(true, "DT2 force win")


func _on_force_lose() -> void:
	var battle := _find_battle()
	if battle and battle.has_method("_finish"):
		battle._finish(false, "DT2 force lose")
	else:
		var session := _session()
		if session:
			session.end_run(false, "DT2 force lose")


func _selected_type() -> String:
	if _type_select == null or _type_select.item_count == 0:
		return ""
	return _type_select.get_item_text(_type_select.selected)


func _on_spawn_at_cell() -> void:
	var type_id := _selected_type()
	var cell := Vector2i(int(_cell_x.value), int(_cell_y.value))
	var front := _selected_front()
	var battle := _find_battle()
	if battle and battle.has_method("debug_spawn_at_cell"):
		battle.debug_spawn_at_cell(type_id, front, cell)
		return
	var sim := _find_sim()
	if sim and sim.has_method("debug_spawn_raider_at") and type_id.begins_with("raider"):
		sim.debug_spawn_raider_at(0 if front < 0 else front, cell)


func _on_toggle_click_spawn() -> void:
	var battle := _find_battle()
	if battle == null:
		return
	if str(battle.debug_click_spawn) == "":
		battle.debug_click_spawn = _selected_type()
		if _click_spawn_btn:
			_click_spawn_btn.text = "Click spawn: ON"
	else:
		battle.debug_click_spawn = ""
		if _click_spawn_btn:
			_click_spawn_btn.text = "Click spawn"


func _on_jump_wave() -> void:
	var wave_n := int(_wave_spin.value) if _wave_spin else 1
	var battle := _find_battle()
	if battle and battle.has_method("debug_jump_wave"):
		battle.debug_jump_wave(wave_n)
		return
	var sim := _find_sim()
	if sim and sim.has_method("debug_jump_wave"):
		sim.debug_jump_wave(wave_n - 1)


func _on_reload_level() -> void:
	var battle := _find_battle()
	if battle and battle.has_method("debug_reload_level"):
		battle.debug_reload_level()
	elif battle and battle.has_method("_restart"):
		battle._restart()
