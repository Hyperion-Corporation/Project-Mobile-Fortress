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


static func get_def(id: String) -> Dictionary:
	var c := catalog()
	if not c.has(id):
		push_error("Unknown unit id: %s" % id)
		return {}
	return c[id].duplicate(true)
