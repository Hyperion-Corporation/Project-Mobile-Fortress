extends Node
## Global session state for offline Slice-0 (save hooks, civ pair, run stats).

const CIV_PRIMARY := "Ming"
const CIV_SUPPORT := "Portuguese"

signal phase_changed(phase: String)
signal resources_changed(land: int, sea: int)
signal hq_changed(hp: int, max_hp: int)
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


func reset_run() -> void:
	land_currency = 40
	sea_currency = 40
	hq_hp = hq_max_hp
	enemies_killed = 0
	units_placed = 0
	outposts_lost = 0
	is_paused = false
	last_result.clear()
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


func end_run(victory: bool, reason: String) -> void:
	last_result = {
		"victory": victory,
		"reason": reason,
		"enemies_killed": enemies_killed,
		"units_placed": units_placed,
		"outposts_lost": outposts_lost,
		"land_currency": land_currency,
		"sea_currency": sea_currency,
		"civs": [CIV_PRIMARY, CIV_SUPPORT],
	}
	_write_local_export()
	run_ended.emit(victory, reason)


func _write_local_export() -> void:
	## Static/batch export for local dashboard later (VS8).
	var path := "user://last_run_results.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write %s" % path)
		return
	f.store_string(JSON.stringify(last_result, "\t"))
	f.close()
