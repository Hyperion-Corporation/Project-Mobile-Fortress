#include "simulation_core.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <cstring>

using namespace godot;

struct Position {
	Vector2 value;
};
struct Velocity {
	Vector2 value;
};
struct Health {
	int current;
	int max;
};

Vector2 SimulationCore::to_gd(mf::Vec2 v) {
	return Vector2(v.x, v.y);
}

mf::Vec2 SimulationCore::from_gd(Vector2 v) {
	return {v.x, v.y};
}

PackedVector2Array SimulationCore::to_gd_path(const std::vector<mf::Vec2> &path) {
	PackedVector2Array out;
	for (const auto &p : path) {
		out.push_back(to_gd(p));
	}
	return out;
}

std::vector<mf::Vec2> SimulationCore::from_gd_path(const PackedVector2Array &path) {
	std::vector<mf::Vec2> out;
	out.reserve(static_cast<size_t>(path.size()));
	for (int i = 0; i < path.size(); ++i) {
		out.push_back(from_gd(path[i]));
	}
	return out;
}

Dictionary SimulationCore::to_gd_hero(const mf::HeroCast &cast) {
	Dictionary result;
	result["success"] = cast.success;
	if (!cast.reason.empty()) {
		result["reason"] = String(cast.reason.c_str());
	}
	if (!cast.type.empty()) {
		result["type"] = String(cast.type.c_str());
	}
	result["hits"] = cast.hits;
	if (cast.cooldown_left > 0.0f) {
		result["cooldown_left"] = cast.cooldown_left;
	}
	return result;
}

Array SimulationCore::to_gd_events(const std::vector<mf::SimEvent> &events) {
	Array out;
	for (const auto &e : events) {
		Dictionary d;
		d["type"] = String(e.type.c_str());
		if (e.id != 0) {
			d["id"] = e.id;
		}
		if (e.front != 0 || e.type == "outpost_damaged" || e.type == "outpost_lost" || e.type == "raider_killed" || e.type == "hq_hit") {
			d["front"] = e.front;
		}
		if (e.type == "hq_hit") {
			d["damage"] = e.damage;
			d["hq_hp"] = e.hq_hp;
		}
		if (e.type == "outpost_damaged") {
			d["amount"] = e.amount;
			d["hp"] = e.hp;
			d["max_hp"] = e.max_hp;
			d["alive"] = e.alive;
		}
		if (e.type == "outpost_lost") {
			d["economic_only"] = e.economic_only;
		}
		if (e.type == "wave_spawned") {
			d["index"] = e.index;
		}
		if (e.type == "income") {
			d["land"] = e.land;
			d["sea"] = e.sea;
			d["land_income"] = e.land_income;
			d["sea_income"] = e.sea_income;
		}
		if (e.type == "victory") {
			d["reason"] = String(e.reason.c_str());
		}
		out.push_back(d);
	}
	return out;
}

void SimulationCore::_bind_methods() {
	ClassDB::bind_method(D_METHOD("reset_run", "start_land", "start_sea", "start_hq"), &SimulationCore::reset_run, DEFVAL(14), DEFVAL(14), DEFVAL(100));
	ClassDB::bind_method(D_METHOD("get_land_resources"), &SimulationCore::get_land_resources);
	ClassDB::bind_method(D_METHOD("get_sea_resources"), &SimulationCore::get_sea_resources);
	ClassDB::bind_method(D_METHOD("get_hq_hp"), &SimulationCore::get_hq_hp);
	ClassDB::bind_method(D_METHOD("get_hq_max_hp"), &SimulationCore::get_hq_max_hp);
	ClassDB::bind_method(D_METHOD("get_enemies_killed"), &SimulationCore::get_enemies_killed);
	ClassDB::bind_method(D_METHOD("get_units_placed"), &SimulationCore::get_units_placed);
	ClassDB::bind_method(D_METHOD("is_land_outpost_alive"), &SimulationCore::is_land_outpost_alive);
	ClassDB::bind_method(D_METHOD("is_sea_outpost_alive"), &SimulationCore::is_sea_outpost_alive);
	ClassDB::bind_method(D_METHOD("get_land_outpost_hp"), &SimulationCore::get_land_outpost_hp);
	ClassDB::bind_method(D_METHOD("get_sea_outpost_hp"), &SimulationCore::get_sea_outpost_hp);
	ClassDB::bind_method(D_METHOD("get_land_outpost_max"), &SimulationCore::get_land_outpost_max);
	ClassDB::bind_method(D_METHOD("get_sea_outpost_max"), &SimulationCore::get_sea_outpost_max);
	ClassDB::bind_method(D_METHOD("is_hq_alive"), &SimulationCore::is_hq_alive);
	ClassDB::bind_method(D_METHOD("get_in_combat"), &SimulationCore::get_in_combat);
	ClassDB::bind_method(D_METHOD("get_combat_time"), &SimulationCore::get_combat_time);
	ClassDB::bind_method(D_METHOD("get_build_phase_seconds"), &SimulationCore::get_build_phase_seconds);
	ClassDB::bind_method(D_METHOD("get_victory_time"), &SimulationCore::get_victory_time);
	ClassDB::bind_method(D_METHOD("get_current_wave"), &SimulationCore::get_current_wave);
	ClassDB::bind_method(D_METHOD("get_wave_count"), &SimulationCore::get_wave_count);
	ClassDB::bind_method(D_METHOD("spend", "front", "amount"), &SimulationCore::spend);
	ClassDB::bind_method(D_METHOD("gain", "front", "amount"), &SimulationCore::gain);
	ClassDB::bind_method(D_METHOD("damage_hq", "amount"), &SimulationCore::damage_hq);
	ClassDB::bind_method(D_METHOD("set_outpost_alive", "front", "alive"), &SimulationCore::set_outpost_alive);
	ClassDB::bind_method(D_METHOD("note_unit_placed"), &SimulationCore::note_unit_placed);
	ClassDB::bind_method(D_METHOD("set_lane_path", "front", "path"), &SimulationCore::set_lane_path);
	ClassDB::bind_method(D_METHOD("spawn_raider", "front", "path", "hp", "speed", "damage", "outpost_path_i", "entry_row"),
			&SimulationCore::spawn_raider, DEFVAL(-1), DEFVAL(-1));
	ClassDB::bind_method(D_METHOD("damage_raider", "id", "amount"), &SimulationCore::damage_raider);
	ClassDB::bind_method(D_METHOD("spawn_defender", "front", "type", "position", "range_px", "damage", "cooldown", "own_env_mult", "cross_env_mult", "aura_radius", "aura_bonus"),
			&SimulationCore::spawn_defender, DEFVAL(1.0f), DEFVAL(0.0f), DEFVAL(0.0f), DEFVAL(0.0f));
	ClassDB::bind_method(D_METHOD("upgrade_defender", "id"), &SimulationCore::upgrade_defender);
	ClassDB::bind_method(D_METHOD("start_defender_travel", "id", "to", "new_front", "duration"), &SimulationCore::start_defender_travel, DEFVAL(1.6f));
	ClassDB::bind_method(D_METHOD("cast_hero_ability", "id"), &SimulationCore::cast_hero_ability);
	ClassDB::bind_method(D_METHOD("tick", "delta", "income_enabled"), &SimulationCore::tick, DEFVAL(true));
	ClassDB::bind_method(D_METHOD("load_level_json", "path"), &SimulationCore::load_level_json);
	ClassDB::bind_method(D_METHOD("start_combat"), &SimulationCore::start_combat);
	ClassDB::bind_method(D_METHOD("save_state"), &SimulationCore::save_state);
	ClassDB::bind_method(D_METHOD("load_state", "data"), &SimulationCore::load_state);
	ClassDB::bind_method(D_METHOD("init_grids", "size"), &SimulationCore::init_grids);
	ClassDB::bind_method(D_METHOD("set_cell_solid", "front", "cell", "solid"), &SimulationCore::set_cell_solid);
	ClassDB::bind_method(D_METHOD("flow_active"), &SimulationCore::flow_active);
	ClassDB::bind_method(D_METHOD("get_raiders"), &SimulationCore::get_raiders);
	ClassDB::bind_method(D_METHOD("get_defenders"), &SimulationCore::get_defenders);
	ClassDB::bind_method(D_METHOD("get_raider_count"), &SimulationCore::get_raider_count);
	ClassDB::bind_method(D_METHOD("get_defender_count"), &SimulationCore::get_defender_count);
	ClassDB::bind_method(D_METHOD("spawn_entity", "type", "position"), &SimulationCore::spawn_entity);
	ClassDB::bind_method(D_METHOD("debug_set_resources", "front", "amount"), &SimulationCore::debug_set_resources);
	ClassDB::bind_method(D_METHOD("debug_set_infinite_resources", "front", "enabled"), &SimulationCore::debug_set_infinite_resources);
	ClassDB::bind_method(D_METHOD("debug_infinite_resources", "front"), &SimulationCore::debug_infinite_resources);
	ClassDB::bind_method(D_METHOD("debug_apply_income"), &SimulationCore::debug_apply_income);
	ClassDB::bind_method(D_METHOD("debug_set_invincible", "enabled"), &SimulationCore::debug_set_invincible);
	ClassDB::bind_method(D_METHOD("debug_invincible"), &SimulationCore::debug_invincible);
	ClassDB::bind_method(D_METHOD("debug_set_waves_disabled", "disabled"), &SimulationCore::debug_set_waves_disabled);
	ClassDB::bind_method(D_METHOD("debug_waves_disabled"), &SimulationCore::debug_waves_disabled);
	ClassDB::bind_method(D_METHOD("debug_kill_all_raiders"), &SimulationCore::debug_kill_all_raiders);
}

SimulationCore::SimulationCore() {
	UtilityFunctions::print("[MF] SimulationCore ready (waves + defenders + outposts)");
}

SimulationCore::~SimulationCore() = default;

void SimulationCore::reset_run(int start_land, int start_sea, int start_hq) {
	world.reset_run(start_land, start_sea, start_hq);
}

int SimulationCore::get_land_resources() const { return world.land_resources(); }
int SimulationCore::get_sea_resources() const { return world.sea_resources(); }
int SimulationCore::get_hq_hp() const { return world.hq_hp(); }
int SimulationCore::get_hq_max_hp() const { return world.hq_max_hp(); }
int SimulationCore::get_enemies_killed() const { return world.enemies_killed(); }
int SimulationCore::get_units_placed() const { return world.units_placed(); }
bool SimulationCore::is_land_outpost_alive() const { return world.land_outpost_alive(); }
bool SimulationCore::is_sea_outpost_alive() const { return world.sea_outpost_alive(); }
int SimulationCore::get_land_outpost_hp() const { return world.land_outpost_hp(); }
int SimulationCore::get_sea_outpost_hp() const { return world.sea_outpost_hp(); }
int SimulationCore::get_land_outpost_max() const { return world.land_outpost_max(); }
int SimulationCore::get_sea_outpost_max() const { return world.sea_outpost_max(); }
bool SimulationCore::is_hq_alive() const { return world.hq_alive(); }
bool SimulationCore::get_in_combat() const { return world.in_combat(); }
float SimulationCore::get_combat_time() const { return world.combat_time(); }
float SimulationCore::get_build_phase_seconds() const { return world.build_phase_seconds(); }
float SimulationCore::get_victory_time() const { return world.victory_time(); }
int SimulationCore::get_current_wave() const { return world.current_wave(); }
int SimulationCore::get_wave_count() const { return world.wave_count(); }

bool SimulationCore::spend(int front, int amount) { return world.spend(front, amount); }
void SimulationCore::gain(int front, int amount) { world.gain(front, amount); }
void SimulationCore::damage_hq(int amount) { world.damage_hq(amount); }
void SimulationCore::set_outpost_alive(int front, bool alive) { world.set_outpost_alive(front, alive); }
void SimulationCore::note_unit_placed() { world.note_unit_placed(); }

void SimulationCore::set_lane_path(int front, PackedVector2Array path) {
	world.set_lane_path(front, from_gd_path(path));
}

bool SimulationCore::flow_active() const { return world.flow_active(); }

int SimulationCore::spawn_raider(int front, PackedVector2Array path, float hp, float speed, float damage, int outpost_path_i,
		int entry_row) {
	return world.spawn_raider(front, from_gd_path(path), hp, speed, damage, outpost_path_i, entry_row);
}

void SimulationCore::damage_raider(int id, float amount) { world.damage_raider(id, amount); }

int SimulationCore::spawn_defender(int front, const String &type, Vector2 position, float range_px, float damage, float cooldown,
		float own_env_mult, float cross_env_mult, float aura_radius, float aura_bonus) {
	return world.spawn_defender(front, std::string(type.utf8().get_data()), from_gd(position), range_px, damage, cooldown,
			own_env_mult, cross_env_mult, aura_radius, aura_bonus);
}

bool SimulationCore::upgrade_defender(int id) { return world.upgrade_defender(id); }

bool SimulationCore::start_defender_travel(int id, Vector2 to, int new_front, float duration) {
	return world.start_defender_travel(id, from_gd(to), new_front, duration);
}

Dictionary SimulationCore::cast_hero_ability(int id) {
	return to_gd_hero(world.cast_hero_ability(id));
}

void SimulationCore::start_combat() { world.start_combat(); }

Array SimulationCore::tick(double delta, bool income_enabled) {
	return to_gd_events(world.tick(delta, income_enabled));
}

PackedByteArray SimulationCore::save_state() const {
	const std::vector<uint8_t> raw = world.save_state();
	PackedByteArray result;
	result.resize(static_cast<int64_t>(raw.size()));
	if (!raw.empty()) {
		memcpy(result.ptrw(), raw.data(), raw.size());
	}
	return result;
}

bool SimulationCore::load_state(const PackedByteArray &data) {
	if (data.size() == 0) {
		return false;
	}
	const bool ok = world.load_state(data.ptr(), static_cast<size_t>(data.size()));
	if (ok) {
		UtilityFunctions::print("[MF] load_state OK bytes=", data.size(),
				" defenders=", static_cast<int64_t>(world.defender_count()),
				" raiders=", static_cast<int64_t>(world.raider_count()),
				" combat=", world.in_combat());
	} else {
		UtilityFunctions::push_warning("[MF] FlatBuffers VerifySimulationStateBuffer failed");
	}
	return ok;
}

bool SimulationCore::load_level_json(const String &path) {
	if (!FileAccess::file_exists(path)) {
		UtilityFunctions::push_warning(String("[MF] level not found: ") + path);
		return false;
	}
	Ref<FileAccess> f = FileAccess::open(path, FileAccess::READ);
	if (f.is_null()) {
		return false;
	}
	String text = f->get_as_text();
	Variant parsed = JSON::parse_string(text);
	if (parsed.get_type() != Variant::DICTIONARY) {
		return false;
	}
	Dictionary level = parsed;
	int land = world.land_resources();
	int sea = world.sea_resources();
	int hq = world.hq_max_hp();
	if (level.has("startingLandCurrency")) {
		land = static_cast<int>(level["startingLandCurrency"]);
	}
	if (level.has("startingSeaCurrency")) {
		sea = static_cast<int>(level["startingSeaCurrency"]);
	}
	if (level.has("hqMaxHp")) {
		hq = static_cast<int>(level["hqMaxHp"]);
	}
	world.reset_run(land, sea, hq);
	if (level.has("buildPhaseSeconds")) {
		world.set_build_phase_seconds(static_cast<float>(level["buildPhaseSeconds"]));
	}
	if (level.has("victoryTimeSeconds")) {
		world.set_victory_time(static_cast<float>(level["victoryTimeSeconds"]));
	}
	world.clear_waves();
	if (level.has("waves") && level["waves"].get_type() == Variant::ARRAY) {
		Array arr = level["waves"];
		for (int i = 0; i < arr.size(); ++i) {
			if (arr[i].get_type() != Variant::DICTIONARY) {
				continue;
			}
			Dictionary w = arr[i];
			world.add_wave(
					static_cast<float>(w.get("delaySeconds", 0.0)),
					static_cast<int>(w.get("landCount", w.get("enemyCount", 2))),
					static_cast<int>(w.get("seaCount", 2)));
		}
	}
	if (world.wave_count() == 0) {
		world.add_wave(2.0f, 2, 2);
		world.add_wave(12.0f, 3, 3);
		world.add_wave(24.0f, 4, 4);
		world.add_wave(38.0f, 5, 5);
	}
	UtilityFunctions::print("[MF] loaded level waves=", static_cast<int64_t>(world.wave_count()),
			" land=", world.land_resources(), " sea=", world.sea_resources());
	return true;
}

Array SimulationCore::get_raiders() const {
	Array out;
	for (const auto &r : world.raiders()) {
		if (!r.alive) {
			continue;
		}
		Dictionary d;
		d["id"] = r.id;
		d["front"] = r.front;
		d["hp"] = r.hp;
		d["max_hp"] = r.max_hp;
		d["position"] = to_gd(r.position);
		d["path_i"] = r.path_i;
		d["path_len"] = static_cast<int>(r.path.size());
		d["uses_flow"] = r.path.empty();
		d["entry_row"] = r.entry_row;
		out.push_back(d);
	}
	return out;
}

Array SimulationCore::get_defenders() const {
	Array out;
	for (const auto &d : world.defenders()) {
		if (!d.alive) {
			continue;
		}
		Dictionary dict;
		dict["id"] = d.id;
		dict["front"] = d.front;
		dict["type"] = String(d.type.c_str());
		dict["position"] = to_gd(d.position);
		dict["traveling"] = d.traveling;
		dict["range_px"] = d.range_px;
		dict["damage"] = d.damage;
		dict["ability_cooldown_left"] = d.ability_cooldown_left;
		out.push_back(dict);
	}
	return out;
}

int SimulationCore::get_raider_count() const { return world.raider_count(); }
int SimulationCore::get_defender_count() const { return world.defender_count(); }

void SimulationCore::init_grids(Vector2i size) {
	world.init_grids(size.x, size.y);
	if (world.flow_active()) {
		UtilityFunctions::print("[MF] C++ Flow Field initialized ", size.x, "x", size.y);
	}
}

void SimulationCore::set_cell_solid(int front, Vector2i cell, bool solid) {
	world.set_cell_solid(front, mf::Vec2i(cell.x, cell.y), solid);
}

void SimulationCore::debug_set_resources(int front, int amount) { world.debug_set_resources(front, amount); }
void SimulationCore::debug_set_infinite_resources(int front, bool enabled) { world.debug_set_infinite_resources(front, enabled); }
bool SimulationCore::debug_infinite_resources(int front) const { return world.debug_infinite_resources(front); }
void SimulationCore::debug_apply_income() { world.debug_apply_income(); }
void SimulationCore::debug_set_invincible(bool enabled) { world.debug_set_invincible(enabled); }
bool SimulationCore::debug_invincible() const { return world.debug_invincible(); }
void SimulationCore::debug_set_waves_disabled(bool disabled) { world.debug_set_waves_disabled(disabled); }
bool SimulationCore::debug_waves_disabled() const { return world.debug_waves_disabled(); }
int SimulationCore::debug_kill_all_raiders() { return world.debug_kill_all_raiders(); }

void SimulationCore::_process(double delta) {
	auto view = registry.view<Position, Velocity>();
	for (auto entity : view) {
		auto &pos = view.get<Position>(entity);
		auto &vel = view.get<Velocity>(entity);
		pos.value += vel.value * static_cast<float>(delta);
	}
}

void SimulationCore::spawn_entity(const String &type, Vector2 position) {
	auto entity = registry.create();
	registry.emplace<Position>(entity, position);
	registry.emplace<Health>(entity, 100, 100);
	UtilityFunctions::print("Spawned entity of type: ", type, " at ", position);
}
