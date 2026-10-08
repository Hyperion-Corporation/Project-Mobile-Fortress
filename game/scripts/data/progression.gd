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

## Historical Wōkòu-era coastal defense prestige ranks
const PRESTIGE_TIERS: Array[Dictionary] = [
	{
		"rank": 0,
		"prestige_required": 0,
		"title": "Coastal Beacon",
		"historical_title": "烽火台 (Fenghuotai)",
		"description": "Initial signal post alerting coastal garrisons to raiding fleets."
	},
	{
		"rank": 1,
		"prestige_required": 250,
		"title": "Sentry Bastion",
		"historical_title": "哨所堡 (Shaosuobao)",
		"description": "Stockaded outpost providing forward observation along tidal corridors."
	},
	{
		"rank": 2,
		"prestige_required": 750,
		"title": "Garrison Fortress",
		"historical_title": "千户所城 (Qianhusuo)",
		"description": "Fortified garrison post commanding local land and littoral approaches."
	},
	{
		"rank": 3,
		"prestige_required": 1500,
		"title": "Maritime Citadel",
		"historical_title": "卫城 (Weicheng)",
		"description": "Major regional walled citadel coordinating combined army and naval maneuvers."
	},
	{
		"rank": 4,
		"prestige_required": 3000,
		"title": "Commander Headquarters",
		"historical_title": "总兵督府 (Zongbing Dufu)",
		"description": "High military command center directing coastal defense fleets and ordnance."
	},
	{
		"rank": 5,
		"prestige_required": 5000,
		"title": "Imperial Coastal Stronghold",
		"historical_title": "海防总要塞 (Haifang Zongyaosai)",
		"description": "Impregnable bastion securing the entire eastern seaboard against all raiding armadas."
	},
]


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


static func get_prestige_tier(prestige: int = -1) -> Dictionary:
	var p := total_prestige() if prestige < 0 else prestige
	var active_tier: Dictionary = PRESTIGE_TIERS[0]
	for tier in PRESTIGE_TIERS:
		if p >= int(tier["prestige_required"]):
			active_tier = tier
		else:
			break
	return active_tier.duplicate(true)


static func get_next_prestige_tier(prestige: int = -1) -> Dictionary:
	var p := total_prestige() if prestige < 0 else prestige
	var current_tier: Dictionary = get_prestige_tier(p)
	var next_tier: Dictionary = {}
	for tier in PRESTIGE_TIERS:
		if int(tier["rank"]) == int(current_tier["rank"]) + 1:
			next_tier = tier
			break
	if next_tier.is_empty():
		return {
			"current_rank": int(current_tier["rank"]),
			"max_rank_reached": true,
			"remaining_prestige": 0,
			"progress_ratio": 1.0,
			"next_title": current_tier["title"],
			"next_prestige_required": int(current_tier["prestige_required"]),
		}
	var cur_req := int(current_tier["prestige_required"])
	var next_req := int(next_tier["prestige_required"])
	var needed := maxi(0, next_req - p)
	var span := maxf(1.0, float(next_req - cur_req))
	var progress := clampf(float(p - cur_req) / span, 0.0, 1.0)
	return {
		"current_rank": int(current_tier["rank"]),
		"max_rank_reached": false,
		"remaining_prestige": needed,
		"progress_ratio": progress,
		"next_title": str(next_tier["title"]),
		"next_prestige_required": next_req,
	}


static func total_stars() -> int:
	var sum := 0
	var levels: Dictionary = _load().get("levels", {})
	for level_id in levels.keys():
		var entry: Dictionary = levels[level_id]
		sum += int(entry.get("best_stars", 0))
	return sum


static func is_level_completed(level_id: String) -> bool:
	return best_stars(level_id) > 0


static func is_level_perfected(level_id: String) -> bool:
	return best_stars(level_id) >= 3


static func get_level_summary(level_id: String = DEFAULT_LEVEL_ID) -> Dictionary:
	var levels: Dictionary = _load().get("levels", {})
	var entry: Dictionary = levels.get(level_id, {"runs": 0, "best_stars": 0, "best_prestige": 0})
	var stars: int = int(entry.get("best_stars", 0))
	return {
		"level_id": level_id,
		"runs": int(entry.get("runs", 0)),
		"best_stars": stars,
		"best_prestige": int(entry.get("best_prestige", 0)),
		"completed": stars > 0,
		"perfected": stars >= 3,
		"stars_formatted": format_stars(stars),
	}


static func get_all_level_summaries() -> Dictionary:
	var result: Dictionary = {}
	var levels: Dictionary = _load().get("levels", {})
	for level_id in levels.keys():
		result[level_id] = get_level_summary(level_id)
	return result


static func reset_progression() -> bool:
	var blank := {
		"schema_version": SCHEMA_VERSION,
		"total_prestige": 0,
		"levels": {}
	}
	return OfflinePersistence.write_json(PROGRESSION_PATH, blank)
