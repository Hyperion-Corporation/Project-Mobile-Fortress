class_name UnitDefs
extends RefCounted
## Catalog for Slice-0 unit types (Ming + Portuguese). No power gacha.

enum Front { LAND, SEA, BOTH }
enum Kind { DEFENDER, HERO, CROSS_SUPPORT, RAIDER }

const PALETTE := {
	"ink": Color("1a1a2e"),
	"paper": Color("f4e9d8"),
	"land": Color("6b8f71"),
	"land_deep": Color("3d5c45"),
	"sea": Color("3d5a80"),
	"sea_deep": Color("1b3a4b"),
	"vermillion": Color("c23b22"),
	"gold": Color("c9a227"),
	"ochre": Color("c4842d"),
	"wokou": Color("2b2b2b"),
	"wokou_sail": Color("8b1e1e"),
	"hq": Color("5c4033"),
	"outpost": Color("a67c52"),
}

## unit_id -> definition
static func catalog() -> Dictionary:
	return {
		"spearman": {
			"name": "Ming Garrison Spearman",
			"front": Front.LAND,
			"kind": Kind.DEFENDER,
			"cost": 10,
			"currency": "land",
			"hp": 40,
			"damage": 8,
			"range": 1.6,
			"cooldown": 0.7,
			"color": PALETTE["vermillion"],
			"own_env_mult": 1.0,
			"cross_env_mult": 0.0,
		},
		"cannon": {
			"name": "Fo-lang-ji Cannon Crew",
			"front": Front.LAND,
			"kind": Kind.DEFENDER,
			"cost": 18,
			"currency": "land",
			"hp": 30,
			"damage": 14,
			"range": 2.8,
			"cooldown": 1.2,
			"color": PALETTE["ochre"],
			"own_env_mult": 1.0,
			"cross_env_mult": 0.35,
		},
		"arquebusier": {
			"name": "Portuguese Arquebusier",
			"front": Front.SEA,
			"kind": Kind.DEFENDER,
			"cost": 12,
			"currency": "sea",
			"hp": 32,
			"damage": 10,
			"range": 2.2,
			"cooldown": 0.85,
			"color": PALETTE["gold"],
			"own_env_mult": 1.0,
			"cross_env_mult": 0.25,
		},
		"junk": {
			"name": "East Asian War Junk",
			"front": Front.SEA,
			"kind": Kind.DEFENDER,
			"cost": 16,
			"currency": "sea",
			"hp": 45,
			"damage": 11,
			"range": 1.8,
			"cooldown": 0.9,
			"color": PALETTE["sea_deep"],
			"own_env_mult": 1.0,
			"cross_env_mult": 0.0,
		},
		"hero_dias": {
			"name": "Capitão Dias (Hero)",
			"front": Front.BOTH,
			"kind": Kind.HERO,
			"cost": 26,
			"currency": "sea",
			"hp": 48,
			"damage": 10,
			"range": 2.2,
			"cooldown": 1.1,
			"color": PALETTE["gold"],
			"own_env_mult": 1.0,
			"cross_env_mult": 0.65,
			"aura_radius": 1.6,
			"aura_damage_bonus": 0.2,
			"active_cooldown": 10.0,
			"active_damage": 22,
		},
		"hero_qi": {
			"name": "Commander Qi (Hero)",
			"front": Front.BOTH,
			"kind": Kind.HERO,
			"cost": 28,
			"currency": "land",
			"hp": 55,
			"damage": 12,
			"range": 2.0,
			"cooldown": 1.0,
			"color": PALETTE["vermillion"],
			"own_env_mult": 1.0,
			"cross_env_mult": 0.5,
			"aura_radius": 2.2,
			"aura_damage_bonus": 0.25,
			"active_cooldown": 8.0,
			"active_damage": 28,
		},
		"cross_support": {
			"name": "Signal Battery (Cross-Front)",
			"front": Front.BOTH,
			"kind": Kind.CROSS_SUPPORT,
			"cost": 20,
			"currency": "sea",
			"hp": 28,
			"damage": 6,
			"range": 12.0,
			"cooldown": 1.1,
			"color": PALETTE["gold"],
			"own_env_mult": 0.55,
			"cross_env_mult": 1.15,
		},
		"raider_land": {
			"name": "Wōkòu Raider",
			"front": Front.LAND,
			"kind": Kind.RAIDER,
			"hp": 28,
			"damage": 8,
			"speed": 55.0,
			"color": PALETTE["wokou"],
		},
		"raider_sea": {
			"name": "Pirate Smuggler Junk",
			"front": Front.SEA,
			"kind": Kind.RAIDER,
			"hp": 32,
			"damage": 9,
			"speed": 48.0,
			"color": PALETTE["wokou_sail"],
		},
	}


static func has_def(id: String) -> bool:
	return catalog().has(id)


static func get_def(id: String) -> Dictionary:
	var c := catalog()
	if not c.has(id):
		push_error("Unknown unit id: %s" % id)
		return {}
	return c[id].duplicate(true)


static func is_hero(id: String) -> bool:
	if not has_def(id):
		return false
	var d := get_def(id)
	return not d.is_empty() and int(d.get("kind", Kind.DEFENDER)) == Kind.HERO


static func get_currency(id: String) -> String:
	if not has_def(id):
		return ""
	var d := get_def(id)
	return str(d.get("currency", ""))


static func get_cost(id: String) -> int:
	if not has_def(id):
		return 0
	var d := get_def(id)
	return int(d.get("cost", 0))


static func can_afford(id: String, land_res: int, sea_res: int) -> bool:
	if not has_def(id):
		return false
	var d := get_def(id)
	if d.is_empty():
		return false
	var cost := int(d.get("cost", 0))
	var cur := str(d.get("currency", ""))
	if cur == "land":
		return land_res >= cost
	elif cur == "sea":
		return sea_res >= cost
	return false


static func get_units_for_front(front: Front) -> Array[String]:
	var result: Array[String] = []
	var cat := catalog()
	for id in cat.keys():
		var ufront: int = int(cat[id].get("front", Front.BOTH))
		if ufront == front or ufront == Front.BOTH:
			result.append(id)
	return result


static func get_cross_support_units() -> Array[String]:
	var result: Array[String] = []
	var cat := catalog()
	for id in cat.keys():
		if int(cat[id].get("kind", Kind.DEFENDER)) == Kind.CROSS_SUPPORT:
			result.append(id)
	return result


static func get_defender_units() -> Array[String]:
	var result: Array[String] = []
	var cat := catalog()
	for id in cat.keys():
		if int(cat[id].get("kind", Kind.DEFENDER)) == Kind.DEFENDER:
			result.append(id)
	return result


static func get_hero_units() -> Array[String]:
	var result: Array[String] = []
	var cat := catalog()
	for id in cat.keys():
		if int(cat[id].get("kind", Kind.DEFENDER)) == Kind.HERO:
			result.append(id)
	return result


## Front whose currency pays for the unit. For `Front.BOTH` units this is the
## default placement assumed by `get_effective_damage`.
static func get_home_front(id: String) -> Front:
	if not has_def(id):
		return Front.LAND
	var d := get_def(id)
	var ufront := int(d.get("front", Front.LAND))
	if ufront != Front.BOTH:
		return ufront as Front
	return Front.SEA if str(d.get("currency", "land")) == "sea" else Front.LAND


## Base damage against a raider on `target_front`, before hero auras. Mirrors
## `SimWorld`: a defender uses `own_env_mult` against raiders on the front it
## stands on and `cross_env_mult` against the other front. Single-front units
## always stand on their own front; for `Front.BOTH` units pass `placed_front`
## (defaults to `get_home_front`).
static func get_effective_damage(unit_id: String, target_front: Front, placed_front: int = -1) -> float:
	if not has_def(unit_id):
		return 0.0
	var d := get_def(unit_id)
	if d.is_empty() or int(d.get("kind", Kind.DEFENDER)) == Kind.RAIDER:
		return 0.0
	var stands_on := int(d.get("front", Front.BOTH))
	if stands_on == Front.BOTH:
		stands_on = placed_front if placed_front == Front.LAND or placed_front == Front.SEA else int(get_home_front(unit_id))
	var mult := float(d.get("own_env_mult", 1.0)) if stands_on == target_front else float(d.get("cross_env_mult", 0.0))
	return float(d.get("damage", 0)) * mult


static func validate_catalog() -> Array[String]:
	var errors: Array[String] = []
	var cat := catalog()
	if cat.is_empty():
		errors.append("Catalog is empty")
		return errors
	for id in cat.keys():
		var u: Dictionary = cat[id]
		if not (u.get("name") is String) or str(u.get("name", "")).strip_edges().is_empty():
			errors.append("Unit '%s' missing valid name" % id)
		var hp := float(u.get("hp", 0))
		if hp <= 0.0:
			errors.append("Unit '%s' non-positive hp: %f" % [id, hp])
		var dmg := float(u.get("damage", 0))
		if dmg < 0.0:
			errors.append("Unit '%s' negative damage: %f" % [id, dmg])
		var front: int = int(u.get("front", -1))
		if front != Front.LAND and front != Front.SEA and front != Front.BOTH:
			errors.append("Unit '%s' invalid front enum: %d" % [id, front])
		var kind: int = int(u.get("kind", -1))
		if kind != Kind.DEFENDER and kind != Kind.HERO and kind != Kind.CROSS_SUPPORT and kind != Kind.RAIDER:
			errors.append("Unit '%s' invalid kind enum: %d" % [id, kind])
		if kind != Kind.RAIDER:
			var cost := int(u.get("cost", 0))
			if cost <= 0:
				errors.append("Playable unit '%s' non-positive cost: %d" % [id, cost])
			var cur := str(u.get("currency", ""))
			if cur != "land" and cur != "sea":
				errors.append("Playable unit '%s' invalid currency: %s" % [id, cur])
			var range_val := float(u.get("range", 0.0))
			if range_val <= 0.0:
				errors.append("Playable unit '%s' non-positive range: %f" % [id, range_val])
			var cd := float(u.get("cooldown", 0.0))
			if cd <= 0.0:
				errors.append("Playable unit '%s' non-positive cooldown: %f" % [id, cd])
			var own_m := float(u.get("own_env_mult", -1.0))
			if own_m < 0.0:
				errors.append("Playable unit '%s' negative own_env_mult: %f" % [id, own_m])
			var cross_m := float(u.get("cross_env_mult", -1.0))
			if cross_m < 0.0:
				errors.append("Playable unit '%s' negative cross_env_mult: %f" % [id, cross_m])
		if kind == Kind.HERO:
			var act_cd := float(u.get("active_cooldown", 0.0))
			if act_cd <= 0.0:
				errors.append("Hero '%s' non-positive active_cooldown: %f" % [id, act_cd])
			var act_dmg := float(u.get("active_damage", 0.0))
			if act_dmg <= 0.0:
				errors.append("Hero '%s' non-positive active_damage: %f" % [id, act_dmg])
			var aura_r := float(u.get("aura_radius", 0.0))
			if aura_r <= 0.0:
				errors.append("Hero '%s' non-positive aura_radius: %f" % [id, aura_r])
			var aura_b := float(u.get("aura_damage_bonus", 0.0))
			if aura_b <= 0.0:
				errors.append("Hero '%s' non-positive aura_damage_bonus: %f" % [id, aura_b])
		if kind == Kind.RAIDER:
			var spd := float(u.get("speed", 0.0))
			if spd <= 0.0:
				errors.append("Raider '%s' non-positive speed: %f" % [id, spd])
	return errors
