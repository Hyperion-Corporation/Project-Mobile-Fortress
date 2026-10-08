extends SceneTree
## Headless G8 contract: star rating, prestige, persist, GameSession wiring.

const ProgressionScript := preload("res://scripts/data/progression.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_wipe_progression()

	if ProgressionScript.compute_stars({"victory": false, "hq_hp": 100, "hq_max_hp": 100, "outposts_lost": 0}) != 0:
		failures.append("defeat must score 0 stars")
	if ProgressionScript.compute_stars({"victory": true, "hq_hp": 80, "hq_max_hp": 100, "outposts_lost": 0}) != 3:
		failures.append("full outposts + ≥66% HQ should be 3 stars")
	if ProgressionScript.compute_stars({"victory": true, "hq_hp": 40, "hq_max_hp": 100, "outposts_lost": 1}) != 2:
		failures.append("one outpost lost + ≥33% HQ should be 2 stars")
	if ProgressionScript.compute_stars({"victory": true, "hq_hp": 10, "hq_max_hp": 100, "outposts_lost": 2}) != 1:
		failures.append("victory with heavy losses should still be 1 star")
	if ProgressionScript.compute_prestige({"enemies_killed": 7, "units_placed": 4}, 2) != 218:
		failures.append("prestige formula mismatch (2*100 + 7*2 + 4)")

	var first: Dictionary = ProgressionScript.record_run({
		"victory": true,
		"hq_hp": 80,
		"hq_max_hp": 100,
		"outposts_lost": 0,
		"enemies_killed": 3,
		"units_placed": 2,
	}, "slice0_dual_front")
	if int(first.get("stars", 0)) != 3:
		failures.append("record_run did not store 3 stars")
	if int(first.get("prestige_earned", 0)) != 308:
		failures.append("record_run prestige_earned wrong")
	if int(first.get("total_prestige", 0)) != 308:
		failures.append("first run total_prestige should equal earned")
	if ProgressionScript.best_stars() != 3 or ProgressionScript.total_prestige() != 308:
		failures.append("progression.json did not persist best_stars / total")

	var second: Dictionary = ProgressionScript.record_run({
		"victory": true,
		"hq_hp": 40,
		"hq_max_hp": 100,
		"outposts_lost": 1,
		"enemies_killed": 0,
		"units_placed": 0,
	}, "slice0_dual_front")
	if int(second.get("stars", 0)) != 2:
		failures.append("second run stars should be 2")
	if int(second.get("best_stars", 0)) != 3:
		failures.append("best_stars must not drop on a weaker run")
	if int(second.get("total_prestige", 0)) != 508:
		failures.append("total_prestige should accumulate (308 + 200)")

	if not root.has_node("GameSession"):
		failures.append("GameSession autoload is missing")
		_finish(failures)
		return

	var session: Node = root.get_node("GameSession")
	session.reset_run()
	session.enemies_killed = 1
	session.units_placed = 1
	session.outposts_lost = 0
	session.hq_hp = 100
	session.end_run(false, "g8-defeat")
	var defeat: Dictionary = session.last_result
	if int(defeat.get("stars", -1)) != 0:
		failures.append("GameSession defeat must merge 0 stars")
	if int(defeat.get("prestige_earned", -1)) != 3:
		failures.append("defeat still earns kill/place prestige (0*100 + 1*2 + 1)")
	var persisted: Dictionary = OfflinePersistence.read_results()
	if int(persisted.get("stars", -1)) != 0:
		failures.append("results JSON missing G8 stars after end_run")

	session.reset_run()
	session.end_run(false, "g8-second-close")
	session.end_run(true, "g8-should-not-rescore", {"combat_time": 1.0})
	if int(session.last_result.get("stars", -1)) != 0:
		failures.append("second end_run on same run must not rescore stars")
	if bool(session.last_result.get("victory", true)):
		failures.append("second end_run must not flip victory after the first close")

	# Prestige tiers & ranks
	var t0: Dictionary = ProgressionScript.get_prestige_tier(0)
	if int(t0.get("rank", -1)) != 0 or t0.get("title", "") != "Coastal Beacon":
		failures.append("tier 0 title/rank mismatch: %s" % str(t0))
	var t1: Dictionary = ProgressionScript.get_prestige_tier(250)
	if int(t1.get("rank", -1)) != 1 or t1.get("title", "") != "Sentry Bastion":
		failures.append("tier 1 title/rank mismatch: %s" % str(t1))
	var t2: Dictionary = ProgressionScript.get_prestige_tier(750)
	if int(t2.get("rank", -1)) != 2 or t2.get("title", "") != "Garrison Fortress":
		failures.append("tier 2 title/rank mismatch: %s" % str(t2))
	var t3: Dictionary = ProgressionScript.get_prestige_tier(1500)
	if int(t3.get("rank", -1)) != 3 or t3.get("title", "") != "Maritime Citadel":
		failures.append("tier 3 title/rank mismatch: %s" % str(t3))
	var t4: Dictionary = ProgressionScript.get_prestige_tier(3000)
	if int(t4.get("rank", -1)) != 4 or t4.get("title", "") != "Commander Headquarters":
		failures.append("tier 4 title/rank mismatch: %s" % str(t4))
	var t5: Dictionary = ProgressionScript.get_prestige_tier(5000)
	if int(t5.get("rank", -1)) != 5 or t5.get("title", "") != "Imperial Coastal Stronghold":
		failures.append("tier 5 title/rank mismatch: %s" % str(t5))

	# Just below a threshold stays on the lower rank
	if int(ProgressionScript.get_prestige_tier(249).get("rank", -1)) != 0:
		failures.append("249 prestige must still be rank 0")
	if int(ProgressionScript.get_prestige_tier(4999).get("rank", -1)) != 4:
		failures.append("4999 prestige must still be rank 4")

	# Next tier calculations
	var next_p: Dictionary = ProgressionScript.get_next_prestige_tier(100)
	if int(next_p.get("current_rank", -1)) != 0 or int(next_p.get("remaining_prestige", -1)) != 150:
		failures.append("get_next_prestige_tier remaining prestige mismatch: %s" % str(next_p))
	if absf(float(next_p.get("progress_ratio", 0.0)) - 0.4) > 0.001:
		failures.append("get_next_prestige_tier progress ratio mismatch (100/250=0.4): %s" % str(next_p))
	var max_tier_calc: Dictionary = ProgressionScript.get_next_prestige_tier(6000)
	if not bool(max_tier_calc.get("max_rank_reached", false)) or int(max_tier_calc.get("remaining_prestige", -1)) != 0:
		failures.append("max tier calc mismatch: %s" % str(max_tier_calc))

	# Multi-level aggregation & campaign progress
	_wipe_progression()
	ProgressionScript.record_run({"victory": true, "hq_hp": 90, "hq_max_hp": 100, "outposts_lost": 0}, "level_alpha")
	ProgressionScript.record_run({"victory": true, "hq_hp": 40, "hq_max_hp": 100, "outposts_lost": 1}, "level_beta")
	if ProgressionScript.total_stars() != 5:
		failures.append("total_stars across alpha (3) and beta (2) should be 5, got %d" % ProgressionScript.total_stars())
	if not ProgressionScript.is_level_completed("level_alpha") or not ProgressionScript.is_level_perfected("level_alpha"):
		failures.append("level_alpha should be completed and perfected")
	if not ProgressionScript.is_level_completed("level_beta") or ProgressionScript.is_level_perfected("level_beta"):
		failures.append("level_beta should be completed but not perfected")
	if ProgressionScript.is_level_completed("level_gamma"):
		failures.append("unplayed level_gamma should not be completed")

	var summary_alpha: Dictionary = ProgressionScript.get_level_summary("level_alpha")
	if int(summary_alpha.get("best_stars", 0)) != 3 or not bool(summary_alpha.get("perfected", false)):
		failures.append("summary_alpha mismatch: %s" % str(summary_alpha))

	var all_summaries: Dictionary = ProgressionScript.get_all_level_summaries()
	if not all_summaries.has("level_alpha") or not all_summaries.has("level_beta") or all_summaries.size() != 2:
		failures.append("get_all_level_summaries mismatch: %s" % str(all_summaries))

	# A malformed level entry must not break aggregation
	var raw: Dictionary = ProgressionScript.read()
	raw["levels"]["level_broken"] = "not a dictionary"
	OfflinePersistence.write_json(ProgressionScript.PROGRESSION_PATH, raw)
	if ProgressionScript.total_stars() != 5:
		failures.append("total_stars must skip malformed entries, got %d" % ProgressionScript.total_stars())
	if int(ProgressionScript.get_level_summary("level_broken").get("best_stars", -1)) != 0:
		failures.append("malformed level summary should read as unplayed")

	# Reset progression
	if not ProgressionScript.reset_progression():
		failures.append("reset_progression returned false")
	if ProgressionScript.total_prestige() != 0 or ProgressionScript.total_stars() != 0:
		failures.append("reset_progression did not clear prestige or stars")

	_wipe_progression()
	_finish(failures)


func _wipe_progression() -> void:
	if FileAccess.file_exists(ProgressionScript.PROGRESSION_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ProgressionScript.PROGRESSION_PATH))


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Progression smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Progression smoke: FAIL (%d)" % failures.size())
		quit(1)
