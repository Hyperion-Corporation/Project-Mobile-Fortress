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
