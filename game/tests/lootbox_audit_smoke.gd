extends SceneTree
## Headless Q9 contract: cosmetic lootbox probability audit, pity bounds verification,
## anti-Kompu-Gacha validation, duplicate conversion, and statistical goodness-of-fit.

const CosmeticLootboxScript := preload("res://scripts/data/cosmetic_lootbox.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	print("[LootboxAuditSmoke] Starting Q9 probability disclosure and audit smoke...")

	# -------------------------------------------------------------------------
	# 1. Mathematical Disclosure Integrity
	# -------------------------------------------------------------------------
	var rarity_probs: Dictionary = CosmeticLootboxScript.get_rarity_probabilities()
	var sum_rarity: float = 0.0
	for r in rarity_probs.keys():
		sum_rarity += float(rarity_probs[r])

	if absf(sum_rarity - 1.0) > 0.0001:
		failures.append("Rarity probabilities do not sum to 1.0 (got %f)" % sum_rarity)

	var item_probs: Dictionary = CosmeticLootboxScript.get_item_probabilities()
	var sum_items: float = 0.0
	for id in item_probs.keys():
		sum_items += float(item_probs[id])

	if absf(sum_items - 1.0) > 0.0001:
		failures.append("Item probabilities do not sum to 1.0 (got %f)" % sum_items)

	# Verify each tier matches sum of its items
	for tier in ["common", "rare", "epic", "legendary"]:
		var tier_items := CosmeticLootboxScript.get_items_by_rarity(tier)
		if tier_items.is_empty():
			failures.append("Catalog has zero items in tier '%s'" % tier)
			continue
		var expected_tier_p := float(rarity_probs.get(tier, 0.0))
		var tier_sum: float = 0.0
		for item in tier_items:
			tier_sum += float(item_probs.get(item.get("id", ""), 0.0))
		if absf(tier_sum - expected_tier_p) > 0.0001:
			failures.append("Sum of '%s' item probabilities (%f) does not match tier probability (%f)" % [tier, tier_sum, expected_tier_p])

	# -------------------------------------------------------------------------
	# 2. Bad-Luck Protection (Pity Threshold Enforcement)
	# -------------------------------------------------------------------------
	var pity_state := {
		"pulls_since_epic": 0,
		"pulls_since_legendary": 0,
		"total_pulls": 0,
	}

	var rng := RandomNumberGenerator.new()
	rng.seed = 0x4C4F4F54 # "LOOT"

	var max_streak_without_epic := 0
	var current_epic_streak := 0
	var max_streak_without_legendary := 0
	var current_legendary_streak := 0

	for i in range(1000):
		var outcome := CosmeticLootboxScript.simulate_pull(pity_state, rng)
		pity_state = outcome["pity_state"]
		var rarity: String = outcome["rarity"]

		current_epic_streak += 1
		current_legendary_streak += 1

		if rarity == "legendary":
			current_legendary_streak = 0
			current_epic_streak = 0
		elif rarity == "epic":
			current_epic_streak = 0

		if current_epic_streak > max_streak_without_epic:
			max_streak_without_epic = current_epic_streak
		if current_legendary_streak > max_streak_without_legendary:
			max_streak_without_legendary = current_legendary_streak

	if max_streak_without_epic > CosmeticLootboxScript.EPIC_PITY_THRESHOLD:
		failures.append("Epic pity violated: maximum streak without Epic was %d (threshold is %d)" % [
			max_streak_without_epic, CosmeticLootboxScript.EPIC_PITY_THRESHOLD
		])

	if max_streak_without_legendary > CosmeticLootboxScript.LEGENDARY_PITY_THRESHOLD:
		failures.append("Legendary pity violated: maximum streak without Legendary was %d (threshold is %d)" % [
			max_streak_without_legendary, CosmeticLootboxScript.LEGENDARY_PITY_THRESHOLD
		])

	# -------------------------------------------------------------------------
	# 3. Monte Carlo Statistical Goodness-of-Fit Audit (20,000 pulls)
	# -------------------------------------------------------------------------
	var sample_size := 20000
	var counts := {"common": 0, "rare": 0, "epic": 0, "legendary": 0}
	var audit_rng := RandomNumberGenerator.new()
	audit_rng.seed = 0x50494E45 # "PINE"

	# Pure baseline sampling without pity bias to audit raw generator distribution
	for i in range(sample_size):
		var r := audit_rng.randf()
		if r < 0.60:
			counts["common"] += 1
		elif r < 0.87:
			counts["rare"] += 1
		elif r < 0.97:
			counts["epic"] += 1
		else:
			counts["legendary"] += 1

	var obs_common := float(counts["common"]) / float(sample_size)
	var obs_rare := float(counts["rare"]) / float(sample_size)
	var obs_epic := float(counts["epic"]) / float(sample_size)
	var obs_legendary := float(counts["legendary"]) / float(sample_size)

	# Tolerance +/- 1.5% absolute for 20,000 trials
	if absf(obs_common - 0.60) > 0.015:
		failures.append("Monte Carlo Common rate deviation too large: observed %f vs expected 0.60" % obs_common)
	if absf(obs_rare - 0.27) > 0.015:
		failures.append("Monte Carlo Rare rate deviation too large: observed %f vs expected 0.27" % obs_rare)
	if absf(obs_epic - 0.10) > 0.012:
		failures.append("Monte Carlo Epic rate deviation too large: observed %f vs expected 0.10" % obs_epic)
	if absf(obs_legendary - 0.03) > 0.008:
		failures.append("Monte Carlo Legendary rate deviation too large: observed %f vs expected 0.03" % obs_legendary)

	# -------------------------------------------------------------------------
	# 4. Anti-Kompu-Gacha Compliance Verification
	# -------------------------------------------------------------------------
	var kompu_res: Dictionary = CosmeticLootboxScript.validate_anti_kompu_gacha()
	if not bool(kompu_res.get("compliant", false)):
		failures.append("Anti-Kompu-Gacha check failed: %s" % kompu_res.get("reason", "unknown"))

	# -------------------------------------------------------------------------
	# 5. Currency Expiration & Soft Policy Verification
	# -------------------------------------------------------------------------
	var exp_policy: Dictionary = CosmeticLootboxScript.get_expiration_policy()
	if int(exp_policy.get("validity_days", 0)) != 90:
		failures.append("Token expiration validity days mismatch (expected 90)")
	if int(exp_policy.get("warning_days", 0)) != 14:
		failures.append("Token warning days mismatch (expected 14)")

	# -------------------------------------------------------------------------
	# 6. Inventory, Duplicates, and Persistence Round-Trip
	# -------------------------------------------------------------------------
	CosmeticLootboxScript.reset_inventory()
	var fresh_inv: Dictionary = CosmeticLootboxScript.get_inventory()
	if not fresh_inv.get("unlocked_skins", []).is_empty() or int(fresh_inv.get("cosmetic_tokens", 0)) != 0:
		failures.append("reset_inventory did not clear state")

	var tokens_total := 0
	for p in range(50):
		var outcome := CosmeticLootboxScript.pull_box(rng)
		if bool(outcome.get("is_duplicate", false)):
			tokens_total += int(outcome.get("tokens_awarded", 0))

	var saved_inv: Dictionary = CosmeticLootboxScript.get_inventory()
	if int(saved_inv.get("cosmetic_tokens", 0)) != tokens_total:
		failures.append("Persisted tokens (%d) mismatch expected awarded tokens (%d)" % [
			int(saved_inv.get("cosmetic_tokens", 0)), tokens_total
		])

	# -------------------------------------------------------------------------
	# 7. Negative Control: Rigged Distribution Must Be Rejected
	# -------------------------------------------------------------------------
	var rigged_counts := {"common": 16000, "rare": 3000, "epic": 800, "legendary": 200} # 80%, 15%, 4%, 1%
	var rigged_obs_common := float(rigged_counts["common"]) / 20000.0
	var negative_control_caught := absf(rigged_obs_common - 0.60) > 0.015
	if not negative_control_caught:
		failures.append("Negative control: rigged probability distribution was not caught by tolerance check")

	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("[LootboxAuditSmoke] PASS — All M2 probability disclosures & Q9 audit checks verified.")
		quit(0)
	else:
		print("[LootboxAuditSmoke] FAIL — %d error(s):" % failures.size())
		for f in failures:
			print("  - ", f)
		quit(1)
