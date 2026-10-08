extends SceneTree
## T52 (G5): level-JSON validation smoke.
##
## Validates every LevelCatalog level against the loaded
## game/src/level-schema.json itself (required keys, types, integer vs
## number, minimums, lengths — a bounded draft-07 subset), then cross-checks
## that SimulationCore.load_level_json actually loads what the JSON says
## (wave count, starting currencies, HQ, build/victory times). Deliberately
## broken in-memory copies (bad level data AND a tampered schema) must fail
## validation, proving the checks are real. level_01.json is a legacy
## single-front leftover: it must exist on disk and stay out of the
## dual-front catalog (it is not validated against the schema).
## Deterministic and fast: safe as a CI gate.

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
		var errors: Array[String] = []
		_validate_against_schema(data, schema, path, errors)
		for error in errors:
			failures.append(error)
		if errors.is_empty():
			_cross_check_loader(sim, path, data, failures)
	sim.queue_free()

	# Deliberately broken copies must fail validation (negative controls).
	# A vacuous validator would let these through and FAIL this smoke.
	if not schema.is_empty():
		var good: Dictionary = _load_json(
			str(levels[0].get("path")) if not levels.is_empty()
			else "res://assets/levels/slice0_dual_front.json", failures)
		if not good.is_empty():
			var broken_waves: Dictionary = good.duplicate(true)
			(broken_waves["waves"] as Array)[0].erase("seaCount")
			_expect_invalid(schema, "broken-no-seaCount", broken_waves, failures)
			var broken_nowaves: Dictionary = good.duplicate(true)
			broken_nowaves["waves"] = []
			_expect_invalid(schema, "broken-empty-waves", broken_nowaves, failures)
			var broken_noid: Dictionary = good.duplicate(true)
			broken_noid.erase("id")
			_expect_invalid(schema, "broken-no-id", broken_noid, failures)
			var broken_pattern: Dictionary = good.duplicate(true)
			(broken_pattern["waves"] as Array)[0]["spawnPattern"] = 42
			_expect_invalid(schema, "broken-numeric-spawnPattern", broken_pattern, failures)
			var broken_count: Dictionary = good.duplicate(true)
			(broken_count["waves"] as Array)[0]["enemyCount"] = 1.5
			_expect_invalid(schema, "broken-fractional-enemyCount", broken_count, failures)
			# The schema itself is the authority: a stricter schema must fail
			# levels that were valid before.
			var strict_schema: Dictionary = schema.duplicate(true)
			(strict_schema["required"] as Array).append("t55MissingRequired")
			_expect_invalid(strict_schema, "strict-schema-missing-key", good, failures)

	# Legacy leftover: present on disk, excluded from the dual-front catalog.
	if not FileAccess.file_exists(LEGACY_PATH):
		failures.append("legacy %s missing from disk" % LEGACY_PATH)
	for entry in levels:
		if str(entry.get("id", "")) == "level_01":
			failures.append("legacy level_01 must not be in the dual-front catalog")

	_finish(failures)


## Fails the smoke unless `data` violates `schema`. In-memory only.
func _expect_invalid(schema: Dictionary, label: String, data: Dictionary, failures: Array[String]) -> void:
	var errors: Array[String] = []
	_validate_against_schema(data, schema, label, errors)
	if errors.is_empty():
		failures.append("negative control: %s passed validation" % label)


## Bounded JSON-Schema draft-07 subset, driven entirely by the loaded
## schema document: object/array/string/number/integer types, required,
## properties, items, minimum, minLength, minItems, enum. Unknown keywords
## (title, description, $schema) are ignored. Absent optional keys are never
## an error. JSON numbers arrive as float, so integer means whole-valued.
func _validate_against_schema(value: Variant, schema: Dictionary, path: String, errors: Array[String]) -> void:
	if schema.has("enum") and schema["enum"] is Array:
		if not (schema["enum"] as Array).has(value):
			errors.append("%s: value not in schema enum" % path)
			return
	if not schema.has("type"):
		return
	var type_name := str(schema["type"])
	if type_name == "object":
		if not value is Dictionary:
			errors.append("%s: expected object" % path)
			return
		var data: Dictionary = value
		if schema.has("required") and schema["required"] is Array:
			for key in (schema["required"] as Array):
				if not data.has(str(key)):
					errors.append("%s: missing required key '%s'" % [path, str(key)])
		if schema.has("properties") and schema["properties"] is Dictionary:
			var properties: Dictionary = schema["properties"]
			for key in data.keys():
				if properties.has(str(key)) and properties[str(key)] is Dictionary:
					_validate_against_schema(data[key], properties[str(key)], "%s.%s" % [path, str(key)], errors)
	elif type_name == "array":
		if not value is Array:
			errors.append("%s: expected array" % path)
			return
		var items: Array = value
		if schema.has("minItems") and items.size() < int(schema["minItems"]):
			errors.append("%s: expected at least %d items (got %d)" % [path, int(schema["minItems"]), items.size()])
		if schema.has("items") and schema["items"] is Dictionary:
			for i in items.size():
				_validate_against_schema(items[i], schema["items"], "%s[%d]" % [path, i], errors)
	elif type_name == "string":
		if not value is String:
			errors.append("%s: expected string" % path)
			return
		if schema.has("minLength") and (value as String).length() < int(schema["minLength"]):
			errors.append("%s: string shorter than minLength %d" % [path, int(schema["minLength"])])
	elif type_name == "number" or type_name == "integer":
		if not (value is float or value is int):
			errors.append("%s: expected %s" % [path, type_name])
			return
		var number_value := float(value)
		if type_name == "integer" and number_value != floor(number_value):
			errors.append("%s: expected integer (got %s)" % [path, str(value)])
			return
		if schema.has("minimum") and number_value < float(schema["minimum"]):
			errors.append("%s: below schema minimum %s" % [path, str(schema["minimum"])])


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


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Level schema smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Level schema smoke: FAIL (%d)" % failures.size())
		quit(1)
