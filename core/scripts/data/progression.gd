class_name Progression
extends RefCounted
## G8 score/progression system: per-level star rating (0-3) plus a cumulative
## HQ prestige score persisted across offline runs, in the same user:// /
## OfflinePersistence style as VS8 (no network).

const SCHEMA_VERSION := 1
const PROGRESSION_PATH := "user://progression.json"
const DEFAULT_LEVEL_ID := "slice0_dual_front"

const STARS_3_MAX_OUTPOSTS_LOST := 0
const STARS_3_MIN_HQ_RATIO := 0.66
const STARS_2_MAX_OUTPOSTS_LOST := 1
const STARS_2_MIN_HQ_RATIO := 0.33


## Pure function: 0 stars on defeat, otherwise 1-3 based on outposts held and
## HQ health remaining at the end of the run.
static func compute_stars(result: Dictionary) -> int:
	if not bool(result.get("victory", false)):
		return 0
	var outposts_lost := int(result.get("outposts_lost", 0))
	var hq_hp := float(result.get("hq_hp", 0))
	var hq_max := maxf(1.0, float(result.get("hq_max_hp", 100)))
	var hq_ratio := hq_hp / hq_max
	if outposts_lost <= STARS_3_MAX_OUTPOSTS_LOST and hq_ratio >= STARS_3_MIN_HQ_RATIO:
		return 3
	if outposts_lost <= STARS_2_MAX_OUTPOSTS_LOST and hq_ratio >= STARS_2_MIN_HQ_RATIO:
		return 2
	return 1


## Pure function: prestige points a single run contributes toward the HQ total.
static func compute_prestige(result: Dictionary, stars: int) -> int:
	var kills := int(result.get("enemies_killed", 0))
	var placed := int(result.get("units_placed", 0))
	return stars * 100 + kills * 2 + placed


static func _load() -> Dictionary:
	var parsed: Variant = OfflinePersistence.read_json(PROGRESSION_PATH)
	if parsed is Dictionary and parsed.get("levels", null) is Dictionary:
		return parsed
	return {"schema_version": SCHEMA_VERSION, "total_prestige": 0, "levels": {}}


## Scores a finished run, folds it into the persisted per-level best-stars /
## cumulative HQ prestige record, and returns the updated summary — callers
## merge the returned fields into the results payload they already write.
static func record_run(result: Dictionary, level_id: String = DEFAULT_LEVEL_ID) -> Dictionary:
	var stars := compute_stars(result)
	var prestige_earned := compute_prestige(result, stars)

	var data := _load()
	data["total_prestige"] = int(data.get("total_prestige", 0)) + prestige_earned
	var levels: Dictionary = data["levels"]
	var entry: Dictionary = levels.get(level_id, {"runs": 0, "best_stars": 0, "best_prestige": 0})
	entry["runs"] = int(entry.get("runs", 0)) + 1
	entry["best_stars"] = maxi(int(entry.get("best_stars", 0)), stars)
	entry["best_prestige"] = maxi(int(entry.get("best_prestige", 0)), prestige_earned)
	levels[level_id] = entry
	data["levels"] = levels
	OfflinePersistence.write_json(PROGRESSION_PATH, data)

	return {
		"stars": stars,
		"prestige_earned": prestige_earned,
		"total_prestige": int(data["total_prestige"]),
		"best_stars": int(entry["best_stars"]),
	}


static func read() -> Dictionary:
	return _load()


static func total_prestige() -> int:
	return int(_load().get("total_prestige", 0))


static func best_stars(level_id: String = DEFAULT_LEVEL_ID) -> int:
	var levels: Dictionary = _load().get("levels", {})
	var entry: Dictionary = levels.get(level_id, {})
	return int(entry.get("best_stars", 0))


static func format_stars(stars: int) -> String:
	stars = clampi(stars, 0, 3)
	return "★".repeat(stars) + "☆".repeat(3 - stars)
