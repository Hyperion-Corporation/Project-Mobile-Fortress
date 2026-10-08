extends SceneTree
## Headless smoke test for G12 unit catalog validation and cross-front synergy multipliers.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	# 1. Validate complete catalog schema & bounds
	var validation_errors := UnitDefs.validate_catalog()
	if not validation_errors.is_empty():
		for err in validation_errors:
			failures.append("Catalog validation error: %s" % err)

	# 2. Roster completeness
	var expected_units := [
		"spearman", "cannon", "arquebusier", "junk",
		"cross_support", "hero_qi", "hero_dias",
		"raider_land", "raider_sea"
	]
	var cat := UnitDefs.catalog()
	for uid in expected_units:
		if not cat.has(uid):
			failures.append("Missing expected roster unit: %s" % uid)

	# 3. Environment-locked resource rules
	if UnitDefs.get_currency("spearman") != "land":
		failures.append("spearman should use land currency")
	if UnitDefs.get_currency("cannon") != "land":
		failures.append("cannon should use land currency")
	if UnitDefs.get_currency("hero_qi") != "land":
		failures.append("hero_qi should use land currency")
	if UnitDefs.get_currency("arquebusier") != "sea":
		failures.append("arquebusier should use sea currency")
	if UnitDefs.get_currency("junk") != "sea":
		failures.append("junk should use sea currency")
	if UnitDefs.get_currency("hero_dias") != "sea":
		failures.append("hero_dias should use sea currency")
	if UnitDefs.get_currency("cross_support") != "sea":
		failures.append("cross_support should use sea currency")

	# Test can_afford environment locking
	if not UnitDefs.can_afford("spearman", 10, 0):
		failures.append("Should afford spearman with 10 land resources")
	if UnitDefs.can_afford("spearman", 9, 100):
		failures.append("Should NOT afford spearman when short on land resources, even with surplus sea")
	if not UnitDefs.can_afford("cross_support", 0, 20):
		failures.append("Should afford cross_support with 20 sea resources")
	if UnitDefs.can_afford("cross_support", 100, 19):
		failures.append("Should NOT afford cross_support when short on sea resources, even with surplus land")

	# 4. Cross-front synergy & multiplier calculations
	# Signal Battery (cross_support): Base 6 dmg, 1.15 cross mult, 0.55 own mult
	var sig_land_dmg := UnitDefs.get_effective_damage("cross_support", UnitDefs.Front.LAND)
	var sig_sea_dmg := UnitDefs.get_effective_damage("cross_support", UnitDefs.Front.SEA)
	if absf(sig_land_dmg - 6.9) > 0.001:
		failures.append("Signal battery cross-front land damage expected 6.9, got %f" % sig_land_dmg)
	if absf(sig_sea_dmg - 3.3) > 0.001:
		failures.append("Signal battery own-front sea damage expected 3.3, got %f" % sig_sea_dmg)

	# Cannon: Base 14 dmg, own 1.0 (14.0), cross 0.35 (4.9)
	var cannon_land_dmg := UnitDefs.get_effective_damage("cannon", UnitDefs.Front.LAND)
	var cannon_sea_dmg := UnitDefs.get_effective_damage("cannon", UnitDefs.Front.SEA)
	if absf(cannon_land_dmg - 14.0) > 0.001:
		failures.append("Cannon land damage expected 14.0, got %f" % cannon_land_dmg)
	if absf(cannon_sea_dmg - 4.9) > 0.001:
		failures.append("Cannon cross-front sea damage expected 4.9, got %f" % cannon_sea_dmg)

	# Spearman: Base 8 dmg, own 1.0 (8.0), cross 0.0 (0.0)
	var spear_land_dmg := UnitDefs.get_effective_damage("spearman", UnitDefs.Front.LAND)
	var spear_sea_dmg := UnitDefs.get_effective_damage("spearman", UnitDefs.Front.SEA)
	if absf(spear_land_dmg - 8.0) > 0.001:
		failures.append("Spearman land damage expected 8.0, got %f" % spear_land_dmg)
	if absf(spear_sea_dmg - 0.0) > 0.001:
		failures.append("Spearman cross-front sea damage expected 0.0, got %f" % spear_sea_dmg)

	# 5. Classification helpers
	var heroes := UnitDefs.get_hero_units()
	if not (heroes.has("hero_qi") and heroes.has("hero_dias") and heroes.size() == 2):
		failures.append("get_hero_units mismatch: %s" % str(heroes))

	var cross_units := UnitDefs.get_cross_support_units()
	if not (cross_units.has("cross_support") and cross_units.size() == 1):
		failures.append("get_cross_support_units mismatch: %s" % str(cross_units))

	var defenders := UnitDefs.get_defender_units()
	if not (defenders.has("spearman") and defenders.has("cannon") and defenders.has("arquebusier") and defenders.has("junk") and defenders.size() == 4):
		failures.append("get_defender_units mismatch: %s" % str(defenders))

	var land_units := UnitDefs.get_units_for_front(UnitDefs.Front.LAND)
	if not (land_units.has("spearman") and land_units.has("cannon") and land_units.has("hero_qi") and land_units.has("hero_dias") and land_units.has("cross_support")):
		failures.append("get_units_for_front(LAND) missing expected units: %s" % str(land_units))
	if land_units.has("arquebusier") or land_units.has("junk"):
		failures.append("get_units_for_front(LAND) should not contain sea-only units")

	var sea_units := UnitDefs.get_units_for_front(UnitDefs.Front.SEA)
	if not (sea_units.has("arquebusier") and sea_units.has("junk") and sea_units.has("hero_qi") and sea_units.has("hero_dias") and sea_units.has("cross_support")):
		failures.append("get_units_for_front(SEA) missing expected units: %s" % str(sea_units))
	if sea_units.has("spearman") or sea_units.has("cannon"):
		failures.append("get_units_for_front(SEA) should not contain land-only units")

	# 6. Edge cases & unknown identifiers
	if UnitDefs.has_def("unknown_unit"):
		failures.append("has_def should return false for unknown unit")
	if not UnitDefs.has_def("spearman"):
		failures.append("has_def should return true for spearman")
	if UnitDefs.get_cost("unknown_unit") != 0:
		failures.append("Unknown unit cost should be 0")
	if UnitDefs.get_currency("unknown_unit") != "":
		failures.append("Unknown unit currency should be empty")
	if UnitDefs.can_afford("unknown_unit", 100, 100):
		failures.append("can_afford should return false for unknown unit")
	if UnitDefs.get_effective_damage("unknown_unit", UnitDefs.Front.LAND) != 0.0:
		failures.append("Effective damage should be 0.0 for unknown unit")
	if UnitDefs.is_hero("unknown_unit"):
		failures.append("Unknown unit should not be hero")

	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Unit catalog smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Unit catalog smoke: FAIL (%d)" % failures.size())
		quit(1)
