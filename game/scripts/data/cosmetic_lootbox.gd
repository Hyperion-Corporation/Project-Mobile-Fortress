class_name CosmeticLootbox
extends RefCounted
## M2 / Q9 cosmetic lootbox system: transparent probability disclosure,
## bad-luck protection (pity counter), anti-Kompu-Gacha compliance,
## currency expiration limits, and offline inventory persistence.
##
## STRICT POLICY (consensus 2026-08-11):
## - NO gameplay-impacting hero/unit power stats (0% attack, HP, speed bonus).
## - Visual, theme, and audio aesthetics ONLY (skins, banners, ornaments).
## - Transparent disclosure of individual item drop percentages and pity mechanics.
## - Anti-Kompu-Gacha: no item requires collecting sets to unlock or equip.

const SCHEMA_VERSION := 1
const INVENTORY_PATH := "user://cosmetics_inventory.json"

const RARITY_COMMON := "common"
const RARITY_RARE := "rare"
const RARITY_EPIC := "epic"
const RARITY_LEGENDARY := "legendary"

## Base rarity drop probabilities (must sum exactly to 1.0)
const RARITY_PROBABILITIES: Dictionary = {
	RARITY_COMMON: 0.60,
	RARITY_RARE: 0.27,
	RARITY_EPIC: 0.10,
	RARITY_LEGENDARY: 0.03,
}

## Bad-luck protection (pity thresholds)
const EPIC_PITY_THRESHOLD := 10
const LEGENDARY_PITY_THRESHOLD := 50

## Duplicate conversion values in cosmetic tokens (dust/tokens)
const DUPLICATE_TOKENS: Dictionary = {
	RARITY_COMMON: 5,
	RARITY_RARE: 20,
	RARITY_EPIC: 100,
	RARITY_LEGENDARY: 500,
}

## Currency expiration terms (regulatory compliance)
const TOKEN_EXPIRATION_DAYS := 90
const WARNING_EXPIRATION_DAYS := 14

## Pure cosmetic skin catalog (1540s-1560s Wōkòu East Asian + Age of Sail themes)
const COSMETIC_CATALOG: Array[Dictionary] = [
	# Common tier (4 items, 15.0% each = 60.0% total)
	{
		"id": "spearman_bamboo",
		"name": "Bamboo Militia Banner",
		"target_unit": "spearman",
		"rarity": RARITY_COMMON,
		"category": "unit_skin",
		"description": "Woven bamboo standard carried by coastal levies defending local village outposts."
	},
	{
		"id": "arquebusier_ashigaru",
		"name": "Captured Ashigaru Coat",
		"target_unit": "arquebusier",
		"rarity": RARITY_COMMON,
		"category": "unit_skin",
		"description": "Reinforced blue coat repurposed from defeated raider gunners along the Fujian coast."
	},
	{
		"id": "cannon_iron",
		"name": "Cast-Iron Culverin",
		"target_unit": "cannon",
		"rarity": RARITY_COMMON,
		"category": "unit_skin",
		"description": "Sturdy coastal iron barrel cast with Ming ordnance seals."
	},
	{
		"id": "junk_patrol",
		"name": "Coastal Patrol Sampan",
		"target_unit": "junk",
		"rarity": RARITY_COMMON,
		"category": "unit_skin",
		"description": "Light cedar-hulled scout vessel rigged with quick-tack bamboo sails."
	},

	# Rare tier (4 items, 6.75% each = 27.0% total)
	{
		"id": "qi_silk_sash",
		"name": "Ming Crimson Sash",
		"target_unit": "hero_qi",
		"rarity": RARITY_RARE,
		"category": "hero_skin",
		"description": "Embroidered crimson military officer sash denoting field command under General Qi."
	},
	{
		"id": "dias_velvet_cape",
		"name": "Lisbon Mariner Cape",
		"target_unit": "hero_dias",
		"rarity": RARITY_RARE,
		"category": "hero_skin",
		"description": "Heavy wool and velvet maritime mantle weathered by Atlantic and Indian Ocean voyages."
	},
	{
		"id": "battery_bronze_gong",
		"name": "Bronze Signal Gong",
		"target_unit": "cross_support",
		"rarity": RARITY_RARE,
		"category": "unit_skin",
		"description": "Ornate engraved gong tuned to alert garrisons across both land and sea approaches."
	},
	{
		"id": "bastion_timber_palisade",
		"name": "Timber Stockade HQ",
		"target_unit": "citadel",
		"rarity": RARITY_RARE,
		"category": "hq_skin",
		"description": "Reinforced cedar stockade palisade with sharpened spikes and red banners."
	},

	# Epic tier (4 items, 2.5% each = 10.0% total)
	{
		"id": "qi_ceremonial_brigandine",
		"name": "Imperial Ceremonial Brigandine",
		"target_unit": "hero_qi",
		"rarity": RARITY_EPIC,
		"category": "hero_skin",
		"description": "Polished steel plates riveted beneath gold-trimmed vermilion silk with dragon crest."
	},
	{
		"id": "dias_caravel_cuirass",
		"name": "Armada Captain Cuirass",
		"target_unit": "hero_dias",
		"rarity": RARITY_EPIC,
		"category": "hero_skin",
		"description": "Fluted steel breastplate bearing the Cross of the Order of Christ with gold inlay."
	},
	{
		"id": "cannon_dragon_carronade",
		"name": "Twin-Dragon Carronade",
		"target_unit": "cannon",
		"rarity": RARITY_EPIC,
		"category": "unit_skin",
		"description": "Heavy bronze cannon chased with coiled imperial dragons along the chamber."
	},
	{
		"id": "junk_ironclad_turtle",
		"name": "Ironclad War Junk",
		"target_unit": "junk",
		"rarity": RARITY_EPIC,
		"category": "unit_skin",
		"description": "Armored naval flagship featuring iron-sheathed bulwarks and twin lantern towers."
	},

	# Legendary tier (3 items, 1.0% each = 3.0% total)
	{
		"id": "qi_mandarin_general",
		"name": "Great General of the Southern Seas",
		"target_unit": "hero_qi",
		"rarity": RARITY_LEGENDARY,
		"category": "hero_skin",
		"description": "Magnificent gilded general regalia with phoenix helmet plumes and tiger shoulder guards."
	},
	{
		"id": "dias_viceroy_regalia",
		"name": "Viceroy of Goa Ceremonial Regalia",
		"target_unit": "hero_dias",
		"rarity": RARITY_LEGENDARY,
		"category": "hero_skin",
		"description": "Full parade armor with engraved nautical astrolabe and damascened gold arabesques."
	},
	{
		"id": "citadel_granite_bastion",
		"name": "Indomitable Granite Citadel",
		"target_unit": "citadel",
		"rarity": RARITY_LEGENDARY,
		"category": "hq_skin",
		"description": "Monumental dressed-granite ramparts crowned with dual watchtowers and imperial war banners."
	},
]


## Returns the base rarity drop percentages.
static func get_rarity_probabilities() -> Dictionary:
	return RARITY_PROBABILITIES.duplicate(true)


## Returns all items filtered by rarity.
static func get_items_by_rarity(rarity: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in COSMETIC_CATALOG:
		if str(item.get("rarity", "")) == rarity:
			result.append(item.duplicate(true))
	return result


## Returns exact individual item drop probabilities as disclosed to players.
static func get_item_probabilities() -> Dictionary:
	var item_probs: Dictionary = {}
	for rarity in [RARITY_COMMON, RARITY_RARE, RARITY_EPIC, RARITY_LEGENDARY]:
		var pool := get_items_by_rarity(rarity)
		var pool_size := maxi(1, pool.size())
		var rarity_p := float(RARITY_PROBABILITIES.get(rarity, 0.0))
		var per_item_p := rarity_p / float(pool_size)
		for item in pool:
			var id := str(item.get("id", ""))
			item_probs[id] = per_item_p
	return item_probs


## Returns formal bad-luck protection / pity rules.
static func get_pity_rules() -> Dictionary:
	return {
		"epic_pity_threshold": EPIC_PITY_THRESHOLD,
		"legendary_pity_threshold": LEGENDARY_PITY_THRESHOLD,
		"epic_description": "Guaranteed Epic or higher within %d pulls." % EPIC_PITY_THRESHOLD,
		"legendary_description": "Guaranteed Legendary within %d pulls." % LEGENDARY_PITY_THRESHOLD,
		"duplicate_token_conversion": DUPLICATE_TOKENS.duplicate(true),
	}


## Returns currency expiration rules ensuring legal and regulatory compliance.
static func get_expiration_policy() -> Dictionary:
	return {
		"validity_days": TOKEN_EXPIRATION_DAYS,
		"warning_days": WARNING_EXPIRATION_DAYS,
		"policy_summary": "Unused cosmetic tokens expire %d days after issuance; warnings begin %d days prior." % [TOKEN_EXPIRATION_DAYS, WARNING_EXPIRATION_DAYS],
		"non_predatory": true,
		"cash_value": false,
	}


## Anti-Kompu-Gacha compliance verification: ensures no item requires collecting
## other items to unlock or equip.
static func validate_anti_kompu_gacha() -> Dictionary:
	for item in COSMETIC_CATALOG:
		if item.has("prerequisite_skins") or item.has("set_requirement"):
			return {
				"compliant": false,
				"failing_item": item.get("id", ""),
				"reason": "Item has prerequisite collection requirements (violates Kompu-Gacha rules)."
			}
	return {
		"compliant": true,
		"total_items": COSMETIC_CATALOG.size(),
		"reason": "All cosmetic items are standalone and immediately equipable without set completion."
	}


## Full regulatory disclosure payload combining probabilities, pity, and policy.
static func get_full_disclosure() -> Dictionary:
	return {
		"policy_title": "Mobile Fortress Cosmetic Lootbox Transparency & Probability Disclosure",
		"gameplay_impact": "None (0% stat boost; cosmetics strictly visual and audio)",
		"anti_p2w": true,
		"rarity_probabilities": get_rarity_probabilities(),
		"item_probabilities": get_item_probabilities(),
		"pity_rules": get_pity_rules(),
		"expiration_policy": get_expiration_policy(),
		"anti_kompu_gacha": validate_anti_kompu_gacha(),
	}


## Simulates a single pull given current pity state and optional RNG.
## Returns a Dictionary with:
## - "item": Dictionary (selected cosmetic skin)
## - "rarity": String
## - "is_pity": bool
## - "pity_state": Dictionary (updated counters)
static func simulate_pull(pity_state: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	var pulls_since_epic := int(pity_state.get("pulls_since_epic", 0))
	var pulls_since_legendary := int(pity_state.get("pulls_since_legendary", 0))

	var chosen_rarity := ""
	var is_pity := false

	# Hard pity checks
	if pulls_since_legendary + 1 >= LEGENDARY_PITY_THRESHOLD:
		chosen_rarity = RARITY_LEGENDARY
		is_pity = true
	elif pulls_since_epic + 1 >= EPIC_PITY_THRESHOLD:
		chosen_rarity = RARITY_EPIC
		is_pity = true
	else:
		# Random draw based on disclosed probability thresholds
		var roll := (rng.randf() if rng != null else randf())
		var p_common := float(RARITY_PROBABILITIES[RARITY_COMMON])
		var p_rare := float(RARITY_PROBABILITIES[RARITY_RARE])
		var p_epic := float(RARITY_PROBABILITIES[RARITY_EPIC])

		if roll < p_common:
			chosen_rarity = RARITY_COMMON
		elif roll < p_common + p_rare:
			chosen_rarity = RARITY_RARE
		elif roll < p_common + p_rare + p_epic:
			chosen_rarity = RARITY_EPIC
		else:
			chosen_rarity = RARITY_LEGENDARY

	# Pick uniform random item within chosen rarity
	var pool := get_items_by_rarity(chosen_rarity)
	var idx := 0
	if pool.size() > 1:
		idx = (rng.randi_range(0, pool.size() - 1) if rng != null else randi() % pool.size())
	var selected_item: Dictionary = pool[idx]

	# Advance pity counters
	var new_pulls_epic := pulls_since_epic + 1
	var new_pulls_legendary := pulls_since_legendary + 1

	if chosen_rarity == RARITY_LEGENDARY:
		new_pulls_legendary = 0
		new_pulls_epic = 0
	elif chosen_rarity == RARITY_EPIC:
		new_pulls_epic = 0

	var next_pity := {
		"pulls_since_epic": new_pulls_epic,
		"pulls_since_legendary": new_pulls_legendary,
		"total_pulls": int(pity_state.get("total_pulls", 0)) + 1,
	}

	return {
		"item": selected_item,
		"rarity": chosen_rarity,
		"is_pity": is_pity,
		"pity_state": next_pity,
	}


# -----------------------------------------------------------------------------
# Persistence & Inventory Management
# -----------------------------------------------------------------------------

static func _load() -> Dictionary:
	var parsed: Variant = OfflinePersistence.read_json(INVENTORY_PATH)
	if parsed is Dictionary and parsed.has("unlocked_skins"):
		return parsed
	return {
		"schema_version": SCHEMA_VERSION,
		"cosmetic_tokens": 0,
		"unlocked_skins": [],
		"pity_state": {
			"pulls_since_epic": 0,
			"pulls_since_legendary": 0,
			"total_pulls": 0,
		},
		"pull_history": [],
		"token_expiration_unix": int(Time.get_unix_time_from_system()) + (TOKEN_EXPIRATION_DAYS * 86400),
	}


static func save(data: Dictionary) -> void:
	OfflinePersistence.write_json(INVENTORY_PATH, data)


static func get_inventory() -> Dictionary:
	return _load()


static func reset_inventory() -> void:
	var clean := {
		"schema_version": SCHEMA_VERSION,
		"cosmetic_tokens": 0,
		"unlocked_skins": [],
		"pity_state": {
			"pulls_since_epic": 0,
			"pulls_since_legendary": 0,
			"total_pulls": 0,
		},
		"pull_history": [],
		"token_expiration_unix": int(Time.get_unix_time_from_system()) + (TOKEN_EXPIRATION_DAYS * 86400),
	}
	save(clean)


## Executes a formal lootbox pull, persisting inventory, tokens, and history.
static func pull_box(rng: RandomNumberGenerator = null) -> Dictionary:
	var data := _load()
	var pity_state: Dictionary = data.get("pity_state", {})
	var outcome := simulate_pull(pity_state, rng)

	data["pity_state"] = outcome["pity_state"]

	var item: Dictionary = outcome["item"]
	var item_id := str(item.get("id", ""))
	var rarity := str(outcome.get("rarity", ""))
	var unlocked_skins: Array = data.get("unlocked_skins", [])

	var is_duplicate := unlocked_skins.has(item_id)
	var tokens_awarded := 0

	if is_duplicate:
		tokens_awarded = int(DUPLICATE_TOKENS.get(rarity, 5))
		data["cosmetic_tokens"] = int(data.get("cosmetic_tokens", 0)) + tokens_awarded
	else:
		unlocked_skins.append(item_id)
		data["unlocked_skins"] = unlocked_skins

	var history: Array = data.get("pull_history", [])
	history.append({
		"item_id": item_id,
		"rarity": rarity,
		"is_duplicate": is_duplicate,
		"tokens_awarded": tokens_awarded,
		"is_pity": bool(outcome.get("is_pity", false)),
		"timestamp": int(Time.get_unix_time_from_system()),
	})
	data["pull_history"] = history

	save(data)

	return {
		"item": item,
		"rarity": rarity,
		"is_duplicate": is_duplicate,
		"tokens_awarded": tokens_awarded,
		"is_pity": bool(outcome.get("is_pity", false)),
		"total_tokens": int(data["cosmetic_tokens"]),
		"pity_state": data["pity_state"],
	}
