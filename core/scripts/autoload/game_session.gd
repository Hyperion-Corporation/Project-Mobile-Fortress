extends Node
## Global session state for offline Slice-0 (save hooks, civ pair, run stats).

const ProgressionScript := preload("res://scripts/data/progression.gd")
const DevMenuScript := preload("res://scripts/ui/dev_menu.gd")
const PlaytestLogScript := preload("res://scripts/data/playtest_log.gd")
const CIV_PRIMARY := "Ming"
const CIV_SUPPORT := "Portuguese"
const DEV_TAP_WINDOW := 2.5
const DEV_TAP_NEEDED := 5

signal phase_changed(phase: String)
signal resources_changed(land: int, sea: int)
signal hq_changed(hp: int, max_hp: int)
signal pause_changed(paused: bool)
signal run_ended(victory: bool, reason: String)
signal developer_mode_changed(enabled: bool)
signal dev_menu_toggled(open: bool)

var land_currency: int = 40
var sea_currency: int = 40
var hq_hp: int = 100
var hq_max_hp: int = 100

var enemies_killed: int = 0
var units_placed: int = 0
var outposts_lost: int = 0

var is_paused: bool = false
var last_result: Dictionary = {}
var _run_recorded: bool = false

var developer_mode: bool = false
var time_scale: float = 1.0
var last_sim_tick_ms: float = 0.0
var last_raider_land: int = 0
var last_raider_sea: int = 0
var last_defender_count: int = 0
var _step_pending: bool = false
var _dev_menu: CanvasLayer
var _dev_taps: Array[float] = []
const STEP_DT := 1.0 / 30.0


func _ready() -> void:
	developer_mode = bool(OfflinePersistence.read_settings().get("developer_mode", false))
	_ensure_dev_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key := event as InputEventKey
	if key.keycode == KEY_F12 or key.physical_keycode == KEY_F12 \
			or key.keycode == KEY_QUOTELEFT or key.physical_keycode == KEY_QUOTELEFT \
			or key.keycode == KEY_ASCIITILDE or key.physical_keycode == KEY_ASCIITILDE:
		set_developer_mode(true)
		toggle_dev_menu()
		get_viewport().set_input_as_handled()


func set_developer_mode(enabled: bool, persist: bool = true) -> void:
	if developer_mode == enabled:
		return
	developer_mode = enabled
	if persist:
		var settings: Dictionary = OfflinePersistence.read_settings()
		settings["developer_mode"] = enabled
		OfflinePersistence.write_settings(settings)
	developer_mode_changed.emit(enabled)
	if not enabled:
		set_dev_menu_open(false)


func register_dev_tap() -> bool:
	var now := Time.get_unix_time_from_system()
	_dev_taps.append(now)
	while _dev_taps.size() > 0 and now - _dev_taps[0] > DEV_TAP_WINDOW:
		_dev_taps.pop_front()
	if _dev_taps.size() >= DEV_TAP_NEEDED:
		_dev_taps.clear()
		set_developer_mode(true)
		set_dev_menu_open(true)
		return true
	return false


func toggle_dev_menu() -> void:
	_ensure_dev_menu()
	set_dev_menu_open(not _dev_menu.visible)


func set_dev_menu_open(open: bool) -> void:
	_ensure_dev_menu()
	if open and not developer_mode:
		return
	if _dev_menu.visible == open:
		return
	_dev_menu.visible = open
	dev_menu_toggled.emit(open)


func is_dev_menu_open() -> bool:
	return _dev_menu != null and _dev_menu.visible


func _ensure_dev_menu() -> void:
	if _dev_menu != null and is_instance_valid(_dev_menu):
		return
	_dev_menu = DevMenuScript.new()
	add_child(_dev_menu)


func set_time_scale(scale: float) -> void:
	time_scale = clampf(scale, 0.5, 10.0)


func request_step() -> void:
	if is_paused:
		_step_pending = true


func consume_step() -> bool:
	if not _step_pending:
		return false
	_step_pending = false
	return true


func note_sim_frame(tick_usec: int, raider_land: int, raider_sea: int, defenders: int) -> void:
	last_sim_tick_ms = float(tick_usec) / 1000.0
	last_raider_land = raider_land
	last_raider_sea = raider_sea
	last_defender_count = defenders


func set_paused(paused: bool) -> void:
	if is_paused == paused:
		return
	is_paused = paused
	if not paused:
		_step_pending = false
	pause_changed.emit(paused)


func toggle_paused() -> bool:
	set_paused(not is_paused)
	return is_paused

## When true, next modular battle scene loads FlatBuffers snapshot after ready.
var resume_snapshot_on_next_battle: bool = false


func reset_run() -> void:
	land_currency = 40
	sea_currency = 40
	hq_hp = hq_max_hp
	enemies_killed = 0
	units_placed = 0
	outposts_lost = 0
	set_paused(false)
	_step_pending = false
	last_result.clear()
	_run_recorded = false
	resources_changed.emit(land_currency, sea_currency)
	hq_changed.emit(hq_hp, hq_max_hp)


func spend(front: String, amount: int) -> bool:
	if front == "land":
		if land_currency < amount:
			return false
		land_currency -= amount
	elif front == "sea":
		if sea_currency < amount:
			return false
		sea_currency -= amount
	else:
		return false
	resources_changed.emit(land_currency, sea_currency)
	return true


func gain(front: String, amount: int) -> void:
	if front == "land":
		land_currency += amount
	elif front == "sea":
		sea_currency += amount
	resources_changed.emit(land_currency, sea_currency)


func damage_hq(amount: int) -> void:
	hq_hp = maxi(0, hq_hp - amount)
	hq_changed.emit(hq_hp, hq_max_hp)
	if hq_hp <= 0:
		end_run(false, "Main HQ destroyed")


func end_run(victory: bool, reason: String, extra: Dictionary = {}) -> void:
	if _run_recorded:
		for key in extra.keys():
			if key == "sim":
				continue
			last_result[key] = extra[key]
		OfflinePersistence.write_results(last_result)
		return
	last_result = {
		"schema_version": OfflinePersistence.SCHEMA_VERSION,
		"timestamp_unix": Time.get_unix_time_from_system(),
		"victory": victory,
		"reason": reason,
		"enemies_killed": enemies_killed,
		"units_placed": units_placed,
		"outposts_lost": outposts_lost,
		"land_currency": land_currency,
		"sea_currency": sea_currency,
		"hq_hp": hq_hp,
		"hq_max_hp": hq_max_hp,
		"civs": [CIV_PRIMARY, CIV_SUPPORT],
		"sim": str(extra.get("sim", "unknown")),
	}
	for key in extra.keys():
		if key == "sim":
			continue
		last_result[key] = extra[key]
	var level_id := str(last_result.get("level_id", ProgressionScript.DEFAULT_LEVEL_ID))
	var progress: Dictionary = ProgressionScript.record_run(last_result, level_id)
	for key in progress.keys():
		last_result[key] = progress[key]
	_run_recorded = true
	OfflinePersistence.write_results(last_result)
	OfflinePersistence.append_history(last_result)
	PlaytestLogScript.note_run_ended(last_result)
	run_ended.emit(victory, reason)


func get_last_results() -> Dictionary:
	if not last_result.is_empty():
		return last_result
	return OfflinePersistence.read_results()


func has_last_results() -> bool:
	return not last_result.is_empty() or OfflinePersistence.has_results()


func playtest_set_tester(name: String) -> void:
	PlaytestLogScript.tester_name = name.strip_edges() if name.strip_edges() != "" else "tester"


func playtest_mark_event(note: String = "") -> Dictionary:
	var extra := {"note": note}
	var battle := get_tree().root.find_child("BattleRoot", true, false) if get_tree() else null
	if battle:
		extra["phase"] = _phase_name(battle)
		extra["wave"] = int(battle.get("wave_index"))
	return PlaytestLogScript.mark_event("mark", extra)


func _phase_name(battle: Node) -> String:
	if battle.get("phase") == null:
		return ""
	var p: int = int(battle.phase)
	if p == 0:
		return "BUILD"
	if p == 1:
		return "COMBAT"
	return "RESULT"


func playtest_sync(dest_override: String = "") -> Dictionary:
	return PlaytestLogScript.sync_to_dashboard(dest_override)


func playtest_export() -> String:
	return PlaytestLogScript.export_copy()
