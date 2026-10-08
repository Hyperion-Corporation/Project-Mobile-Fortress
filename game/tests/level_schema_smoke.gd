extends SceneTree
## T52 (G5): level-JSON validation smoke.
##
## Validates every LevelCatalog level against game/src/level-schema.json
## (required keys, value types/ranges, per-wave landCount/seaCount), then
## cross-checks that SimulationCore.load_level_json actually loads what the
## JSON says (wave count, starting currencies, HQ, build/victory times).
## A deliberately broken in-memory copy must fail validation, proving the
## checks are real. level_01.json is a legacy single-front leftover: it must
## exist on disk and stay out of the dual-front catalog (it is not validated
## against the schema). Deterministic and fast: safe as a CI gate.

const LevelCatalogScript := preload("res://scripts/data/level_catalog.gd")
const SCHEMA_PATH := "res://src/level-schema.json"
const LEGACY_PATH := "res://assets/levels/level_01.json"


func _init() -> void:
	var failures: Array[String] = []
	if not ClassDB.class_exists("SimulationCore"):
		failures.append("SimulationCore GDExtension class is not registered (native library missing?)")
		_finish(failures)
		return

	var schema: Dictionary = _load_json(SCHEMA_PATH, failures)
	var levels: Array = LevelCatalogScript.list_levels()
	if levels.is_empty():
		failures.append("LevelCatalog.list_levels() returned no levels")

	var sim: Node = ClassDB.instantiate("SimulationCore")
	root.add_child(sim)
	for entry in levels:
		var path := str(entry.get("path", ""))
		if path.is_empty():
			failures.append("catalog entry missing path: %s" % str(entry))
			continue
		var data: Dictionary = _load_json(path, failures)
		if data.is_empty():
			continue
		var errors: Array[String] = _validate_level(path, data)
		for error in errors:
			failures.append(error)
		if errors.is_empty():
			_cross_check_loader(sim, path, data, failures)
	sim.queue_free()

	# Deliberately broken copies must fail validation (negative control).
	if not schema.is_empty():
		var good: Dictionary = _load_json(
			str(levels[0].get("path")) if not levels.is_empty()
			else "res://assets/levels/slice0_dual_front.json", failures)
		if not good.is_empty():
			var broken_waves: Dictionary = good.duplicate(true)
			(broken_waves["waves"] as Array)[0].erase("seaCount")
			if _validate_level("broken-no-seaCount", broken_waves).is_empty():
				failures.append("negative control: wave without seaCount passed validation")
			var broken_nowaves: Dictionary = good.duplicate(true)
			broken_nowaves["waves"] = []
			if _validate_level("broken-empty-waves", broken_nowaves).is_empty():
				failures.append("negative control: empty waves array passed validation")
			var broken_noid: Dictionary = good.duplicate(true)
			broken_noid.erase("id")
			if _validate_level("broken-no-id", broken_noid).is_empty():
				failures.append("negative control: level without id passed validation")

	# Legacy leftover: present on disk, excluded from the dual-front catalog.
	if not FileAccess.file_exists(LEGACY_PATH):
		failures.append("legacy %s missing from disk" % LEGACY_PATH)
	for entry in levels:
		if str(entry.get("id", "")) == "level_01":
			failures.append("legacy level_01 must not be in the dual-front catalog")

	_finish(failures)


## Mirrors game/src/level-schema.json: required keys, numeric types/ranges,
## and per-wave landCount/seaCount. Returns a list of error strings.
func _validate_level(path: String, data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for key in ["id", "displayName", "waves"]:
		if not data.has(key):
			errors.append("%s: missing required key '%s'" % [path, key])
	if data.has("id") and not (data["id"] is String and not str(data["id"]).is_empty()):
		errors.append("%s: 'id' must be a non-empty string" % path)
	if data.has("displayName") and not (data["displayName"] is String and not str(data["displayName"]).is_empty()):
		errors.append("%s: 'displayName' must be a non-empty string" % path)
	for key in ["civPrimary", "civSupport"]:
		if data.has(key) and not data[key] is String:
			errors.append("%s: '%s' must be a string" % [path, key])
	_check_number(path, data, errors, "buildPhaseSeconds", 0.0, false)
	_check_number(path, data, errors, "victoryTimeSeconds", 0.0, false)
	_check_number(path, data, errors, "enemySpawnIntervalSeconds", 0.0, false)
	_check_number(path, data, errors, "hqMaxHp", 1.0, true)
	_check_number(path, data, errors, "startingLandCurrency", 0.0, true)
	_check_number(path, data, errors, "startingSeaCurrency", 0.0, true)
	if data.has("waves"):
		if not data["waves"] is Array:
			errors.append("%s: 'waves' must be an array" % path)
		elif (data["waves"] as Array).is_empty():
			errors.append("%s: 'waves' must not be empty (loader falls back to built-in waves)" % path)
		else:
			for i in (data["waves"] as Array).size():
				var wave: Variant = (data["waves"] as Array)[i]
				var where := "%s waves[%d]" % [path, i]
				if not wave is Dictionary:
					errors.append("%s: must be an object" % where)
					continue
				if not wave.has("delaySeconds") or not _is_number(wave["delaySeconds"]):
					errors.append("%s: missing/nonnumeric 'delaySeconds'" % where)
				elif float(wave["delaySeconds"]) < 0.0:
					errors.append("%s: 'delaySeconds' must be >= 0" % where)
				for count_key in ["landCount", "seaCount"]:
					if not wave.has(count_key) or not _is_number(wave[count_key]):
						errors.append("%s: missing/nonnumeric '%s' (dual-front levels require both)" % [where, count_key])
					elif float(wave[count_key]) < 0.0 or float(wave[count_key]) != floor(float(wave[count_key])):
						errors.append("%s: '%s' must be an integer >= 0" % [where, count_key])
				if wave.has("enemyCount") and (not _is_number(wave["enemyCount"]) or float(wave["enemyCount"]) < 0.0):
					errors.append("%s: deprecated 'enemyCount' must be a number >= 0" % where)
	return errors


## Proves the C++ loader honors the JSON: wave count and every
## loader-read scalar matches after load_level_json.
func _cross_check_loader(sim: Node, path: String, data: Dictionary, failures: Array[String]) -> void:
	if not sim.load_level_json(path):
		failures.append("%s: load_level_json returned false" % path)
		return
	var want_waves := (data["waves"] as Array).size()
	if int(sim.get_wave_count()) != want_waves:
		failures.append("%s: loader wave_count=%d, JSON has %d waves" % [path, int(sim.get_wave_count()), want_waves])
	if data.has("startingLandCurrency") and int(sim.get_land_resources()) != int(data["startingLandCurrency"]):
		failures.append("%s: loader land=%d, JSON startingLandCurrency=%s" % [path, int(sim.get_land_resources()), str(data["startingLandCurrency"])])
	if data.has("startingSeaCurrency") and int(sim.get_sea_resources()) != int(data["startingSeaCurrency"]):
		failures.append("%s: loader sea=%d, JSON startingSeaCurrency=%s" % [path, int(sim.get_sea_resources()), str(data["startingSeaCurrency"])])
	if data.has("hqMaxHp") and int(sim.get_hq_max_hp()) != int(data["hqMaxHp"]):
		failures.append("%s: loader hq_max=%d, JSON hqMaxHp=%s" % [path, int(sim.get_hq_max_hp()), str(data["hqMaxHp"])])
	if data.has("buildPhaseSeconds") and not is_equal_approx(float(sim.get_build_phase_seconds()), float(data["buildPhaseSeconds"])):
		failures.append("%s: loader build_phase=%s, JSON buildPhaseSeconds=%s" % [path, str(sim.get_build_phase_seconds()), str(data["buildPhaseSeconds"])])
	if data.has("victoryTimeSeconds") and not is_equal_approx(float(sim.get_victory_time()), float(data["victoryTimeSeconds"])):
		failures.append("%s: loader victory=%s, JSON victoryTimeSeconds=%s" % [path, str(sim.get_victory_time()), str(data["victoryTimeSeconds"])])


func _load_json(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("missing file: %s" % path)
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		failures.append("%s: not a JSON object" % path)
		return {}
	return parsed


func _is_number(value: Variant) -> bool:
	return value is float or value is int


func _check_number(path: String, data: Dictionary, errors: Array[String], key: String, minimum: float, integer: bool) -> void:
	if not data.has(key):
		return
	if not _is_number(data[key]):
		errors.append("%s: '%s' must be a number" % [path, key])
		return
	var value := float(data[key])
	if value < minimum or (integer and value != floor(value)):
		errors.append("%s: '%s' must be %s >= %s" % [path, key, "an integer" if integer else "a number", str(minimum)])


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Level schema smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Level schema smoke: FAIL (%d)" % failures.size())
		quit(1)
