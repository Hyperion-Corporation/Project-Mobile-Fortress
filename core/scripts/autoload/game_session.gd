extends Node
## Global session state for offline Slice-0 (save hooks, civ pair, run stats).

const ProgressionScript := preload("res://scripts/data/progression.gd")
const CIV_PRIMARY := "Ming"
const CIV_SUPPORT := "Portuguese"

signal phase_changed(phase: String)
signal resources_changed(land: int, sea: int)
signal hq_changed(hp: int, max_hp: int)
signal pause_changed(paused: bool)
signal run_ended(victory: bool, reason: String)

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


func set_paused(paused: bool) -> void:
	if is_paused == paused:
		return
	is_paused = paused
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
	run_ended.emit(victory, reason)


func get_last_results() -> Dictionary:
	if not last_result.is_empty():
		return last_result
	return OfflinePersistence.read_results()


func has_last_results() -> bool:
	return not last_result.is_empty() or OfflinePersistence.has_results()
