#include "simulation_core.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include "simulation_state_generated.h"
#include <algorithm>
#include <cmath>

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
	ClassDB::bind_method(D_METHOD("spawn_raider", "front", "path", "hp", "speed", "damage", "outpost_path_i"), &SimulationCore::spawn_raider, DEFVAL(-1));
	ClassDB::bind_method(D_METHOD("damage_raider", "id", "amount"), &SimulationCore::damage_raider);
	ClassDB::bind_method(D_METHOD("spawn_defender", "front", "type", "position", "range_px", "damage", "cooldown", "own_env_mult", "cross_env_mult", "aura_radius", "aura_bonus"),
			&SimulationCore::spawn_defender, DEFVAL(1.0f), DEFVAL(0.0f), DEFVAL(0.0f), DEFVAL(0.0f));
	ClassDB::bind_method(D_METHOD("start_defender_travel", "id", "to", "new_front", "duration"), &SimulationCore::start_defender_travel, DEFVAL(1.6f));
	ClassDB::bind_method(D_METHOD("cast_hero_ability", "id"), &SimulationCore::cast_hero_ability);
	ClassDB::bind_method(D_METHOD("tick", "delta", "income_enabled"), &SimulationCore::tick, DEFVAL(true));
	ClassDB::bind_method(D_METHOD("load_level_json", "path"), &SimulationCore::load_level_json);
	ClassDB::bind_method(D_METHOD("start_combat"), &SimulationCore::start_combat);

	ClassDB::bind_method(D_METHOD("save_state"), &SimulationCore::save_state);
	ClassDB::bind_method(D_METHOD("load_state", "data"), &SimulationCore::load_state);

	ClassDB::bind_method(D_METHOD("init_grids", "size"), &SimulationCore::init_grids);
	ClassDB::bind_method(D_METHOD("set_cell_solid", "front", "cell", "solid"), &SimulationCore::set_cell_solid);

	ClassDB::bind_method(D_METHOD("get_raiders"), &SimulationCore::get_raiders);
	ClassDB::bind_method(D_METHOD("get_defenders"), &SimulationCore::get_defenders);
	ClassDB::bind_method(D_METHOD("get_raider_count"), &SimulationCore::get_raider_count);
	ClassDB::bind_method(D_METHOD("get_defender_count"), &SimulationCore::get_defender_count);
	ClassDB::bind_method(D_METHOD("spawn_entity", "type", "position"), &SimulationCore::spawn_entity);
}

SimulationCore::SimulationCore() {
	UtilityFunctions::print("[MF] SimulationCore ready (waves + defenders + outposts)");
}

SimulationCore::~SimulationCore() = default;

void SimulationCore::reset_run(int start_land, int start_sea, int start_hq) {
	land_resources = start_land;
	sea_resources = start_sea;
	hq_hp = start_hq;
	hq_max_hp = start_hq;
	enemies_killed = 0;
	units_placed = 0;
	land_outpost_hp = land_outpost_max;
	sea_outpost_hp = sea_outpost_max;
	land_outpost_alive = true;
	sea_outpost_alive = true;
	income_acc = 0.0f;
	raiders.clear();
	defenders.clear();
	registry.clear();
	next_raider_id = 1;
	next_defender_id = 10001;

	if (grid_size.x > 0 && grid_size.y > 0) {
		update_flow_field(0, Vector2i(grid_size.x - 1, grid_size.y / 2));
		update_flow_field(1, Vector2i(grid_size.x - 1, grid_size.y / 2));
	}
	in_combat = false;
	combat_time = 0.0f;
	current_wave = 0;
	for (auto &w : waves) {
		w.fired = false;
	}
}

int SimulationCore::get_land_resources() const { return land_resources; }
int SimulationCore::get_sea_resources() const { return sea_resources; }
int SimulationCore::get_hq_hp() const { return hq_hp; }
int SimulationCore::get_hq_max_hp() const { return hq_max_hp; }
int SimulationCore::get_enemies_killed() const { return enemies_killed; }
int SimulationCore::get_units_placed() const { return units_placed; }
bool SimulationCore::is_land_outpost_alive() const { return land_outpost_alive; }
bool SimulationCore::is_sea_outpost_alive() const { return sea_outpost_alive; }
int SimulationCore::get_land_outpost_hp() const { return land_outpost_hp; }
int SimulationCore::get_sea_outpost_hp() const { return sea_outpost_hp; }
int SimulationCore::get_land_outpost_max() const { return land_outpost_max; }
int SimulationCore::get_sea_outpost_max() const { return sea_outpost_max; }
bool SimulationCore::is_hq_alive() const { return hq_hp > 0; }
bool SimulationCore::get_in_combat() const { return in_combat; }
float SimulationCore::get_combat_time() const { return combat_time; }
float SimulationCore::get_build_phase_seconds() const { return build_phase_seconds; }
float SimulationCore::get_victory_time() const { return victory_time; }
int SimulationCore::get_current_wave() const { return current_wave; }
int SimulationCore::get_wave_count() const { return static_cast<int>(waves.size()); }

bool SimulationCore::spend(int front, int amount) {
	if (amount < 0) {
		return false;
	}
	if (front == 0) {
		if (land_resources < amount) {
			return false;
		}
		land_resources -= amount;
		return true;
	}
	if (front == 1) {
		if (sea_resources < amount) {
			return false;
		}
		sea_resources -= amount;
		return true;
	}
	return false;
}

void SimulationCore::gain(int front, int amount) {
	if (amount <= 0) {
		return;
	}
	if (front == 0) {
		land_resources += amount;
	} else if (front == 1) {
		sea_resources += amount;
	}
}

void SimulationCore::damage_hq(int amount) {
	if (amount <= 0) {
		return;
	}
	hq_hp = std::max(0, hq_hp - amount);
}

void SimulationCore::set_outpost_alive(int front, bool alive) {
	if (front == 0) {
		land_outpost_alive = alive;
		if (!alive) {
			land_outpost_hp = 0;
		} else if (land_outpost_hp <= 0) {
			land_outpost_hp = land_outpost_max;
		}
	} else if (front == 1) {
		sea_outpost_alive = alive;
		if (!alive) {
			sea_outpost_hp = 0;
		} else if (sea_outpost_hp <= 0) {
			sea_outpost_hp = sea_outpost_max;
		}
	}
}

void SimulationCore::damage_outpost(int front, int amount, Array &events) {
	if (amount <= 0) {
		return;
	}
	bool was_alive = (front == 0) ? land_outpost_alive : sea_outpost_alive;
	if (!was_alive) {
		return;
	}
	if (front == 0) {
		land_outpost_hp = std::max(0, land_outpost_hp - amount);
		if (land_outpost_hp <= 0) {
			land_outpost_alive = false;
		}
	} else if (front == 1) {
		sea_outpost_hp = std::max(0, sea_outpost_hp - amount);
		if (sea_outpost_hp <= 0) {
			sea_outpost_alive = false;
		}
	} else {
		return;
	}

	Dictionary dmg;
	dmg["type"] = "outpost_damaged";
	dmg["front"] = front;
	dmg["amount"] = amount;
	dmg["hp"] = (front == 0) ? land_outpost_hp : sea_outpost_hp;
	dmg["max_hp"] = (front == 0) ? land_outpost_max : sea_outpost_max;
	dmg["alive"] = (front == 0) ? land_outpost_alive : sea_outpost_alive;
	events.push_back(dmg);

	bool now_alive = (front == 0) ? land_outpost_alive : sea_outpost_alive;
	if (was_alive && !now_alive) {
		Dictionary lost;
		lost["type"] = "outpost_lost";
		lost["front"] = front;
		lost["economic_only"] = true;
		events.push_back(lost);
	}
}

void SimulationCore::note_unit_placed() {
	units_placed += 1;
}

void SimulationCore::set_lane_path(int front, PackedVector2Array path) {
	if (front == 0) {
		land_path = path;
	} else if (front == 1) {
		sea_path = path;
	}
}

int SimulationCore::spawn_raider(int front, PackedVector2Array path, float hp, float speed, float damage, int outpost_path_i) {
	if (path.size() == 0) {
		return -1;
	}
	if (static_cast<int>(raiders.size()) >= 40) {
		return -1;
	}
	RaiderData r;
	r.id = next_raider_id++;
	r.front = front;
	r.hp = hp;
	r.max_hp = hp;
	r.speed = speed;
	r.damage = damage;
	r.path = path;
	r.path_i = 0;
	r.position = path[0];
	r.alive = true;
	r.struck_outpost = false;
	if (outpost_path_i < 0) {
		r.outpost_path_i = std::max(1, static_cast<int>(path.size()) / 2);
	} else {
		r.outpost_path_i = outpost_path_i;
	}
	raiders.push_back(r);
	return r.id;
}

void SimulationCore::damage_raider(int id, float amount) {
	for (auto &r : raiders) {
		if (r.id == id && r.alive) {
			r.hp -= amount;
			if (r.hp <= 0.0f) {
				r.alive = false;
				enemies_killed += 1;
			}
			return;
		}
	}
}

int SimulationCore::spawn_defender(int front, const String &type, Vector2 position, float range_px, float damage, float cooldown,
		float own_env_mult, float cross_env_mult, float aura_radius, float aura_bonus) {
	DefenderData d;
	d.id = next_defender_id++;
	d.front = front;
	d.type = type;
	d.position = position;
	d.range_px = range_px;
	d.damage = damage;
	d.hp = 100.0f;
	d.cooldown = std::max(0.1f, cooldown);
	d.cooldown_left = 0.0f;
	d.ability_cooldown = 8.0f;
	d.ability_cooldown_left = 0.0f;
	d.own_env_mult = own_env_mult;
	d.cross_env_mult = cross_env_mult;
	d.aura_radius = aura_radius;
	d.aura_bonus = aura_bonus;
	d.alive = true;
	d.travel_from = position;
	d.travel_to = position;
	defenders.push_back(d);
	units_placed += 1;
	return d.id;
}

bool SimulationCore::start_defender_travel(int id, Vector2 to, int new_front, float duration) {
	for (auto &d : defenders) {
		if (d.id == id && d.alive && !d.traveling) {
			d.traveling = true;
			d.travel_from = d.position;
			d.travel_to = to;
			d.travel_t = 0.0f;
			d.travel_duration = std::max(0.2f, duration);
			d.front = new_front;
			return true;
		}
	}
	return false;
}

Dictionary SimulationCore::cast_hero_ability(int id) {
	Dictionary result;
	result["success"] = false;

	for (auto &d : defenders) {
		if (d.id != id || !d.alive || d.traveling) {
			continue;
		}
		if (d.ability_cooldown_left > 0.0f) {
			result["reason"] = "on_cooldown";
			result["cooldown_left"] = d.ability_cooldown_left;
			return result;
		}
		if (d.type == "hero_qi" || d.type == "hero") {
			int hits = 0;
			float radius_px = 250.0f;
			float damage = 35.0f;
			for (auto &r : raiders) {
				if (r.alive && d.position.distance_to(r.position) <= radius_px) {
					r.hp -= damage;
					hits += 1;
					if (r.hp <= 0.0f) {
						r.alive = false;
						enemies_killed += 1;
					}
				}
			}
			d.ability_cooldown_left = d.ability_cooldown;
			result["success"] = true;
			result["type"] = "pulse";
			result["hits"] = hits;
			return result;
		}
		result["reason"] = "not_hero";
		return result;
	}
	result["reason"] = "not_found";
	return result;
}

float SimulationCore::total_aura_at(Vector2 pos) const {
	float bonus = 0.0f;
	for (const auto &d : defenders) {
		if (!d.alive || d.aura_radius <= 0.0f) {
			continue;
		}
		if (d.position.distance_to(pos) <= d.aura_radius) {
			bonus += d.aura_bonus;
		}
	}
	return bonus;
}

void SimulationCore::run_travel(double delta) {
	for (auto &d : defenders) {
		if (!d.alive || !d.traveling) {
			continue;
		}
		d.travel_t += static_cast<float>(delta) / d.travel_duration;
		float t = std::clamp(d.travel_t, 0.0f, 1.0f);
		d.position = d.travel_from.lerp(d.travel_to, t);
		if (t >= 1.0f) {
			d.traveling = false;
			d.position = d.travel_to;
		}
	}
}

void SimulationCore::run_defender_combat(double delta, Array &events) {
	for (auto &d : defenders) {
		if (!d.alive || d.traveling) {
			continue;
		}
		if (d.cooldown_left > 0.0f) {
			d.cooldown_left -= static_cast<float>(delta);
		}
		if (d.ability_cooldown_left > 0.0f) {
			d.ability_cooldown_left -= static_cast<float>(delta);
		}
		if (d.cooldown_left > 0.0f) {
			continue;
		}
		RaiderData *best = nullptr;
		float best_d = 1e9f;
		for (auto &r : raiders) {
			if (!r.alive) {
				continue;
			}
			float dist = d.position.distance_to(r.position);
			if (dist > d.range_px) {
				continue;
			}
			bool same = (r.front == d.front);
			float mult = same ? d.own_env_mult : d.cross_env_mult;
			if (mult <= 0.0f) {
				continue;
			}
			if (dist < best_d) {
				best_d = dist;
				best = &r;
			}
		}
		if (best == nullptr) {
			continue;
		}
		bool same = (best->front == d.front);
		float mult = same ? d.own_env_mult : d.cross_env_mult;
		float dmg = d.damage * mult * (1.0f + total_aura_at(d.position));
		best->hp -= dmg;
		d.cooldown_left = d.cooldown;
		if (best->hp <= 0.0f) {
			best->alive = false;
			enemies_killed += 1;
			Dictionary kill;
			kill["type"] = "raider_killed";
			kill["id"] = best->id;
			kill["front"] = best->front;
			events.push_back(kill);
		}
	}
}

void SimulationCore::check_and_spawn_waves(Array &events) {
	if (!in_combat || current_wave >= (int)waves.size()) return;

	if (combat_time >= waves[current_wave].delay) {
		WaveData w = waves[current_wave];

		for (int i = 0; i < w.land_count; i++) {
			Vector2 start_pos = map_to_local(0, Vector2i(0, grid_size.y > 0 ? grid_size.y / 2 : 2));
			start_pos.x -= static_cast<float>(i) * 32.0f; // stagger
			PackedVector2Array path; // Unused for Flow Field
			float hp = 50.0f + static_cast<float>(current_wave) * 3.0f;
			float speed = 26.0f + static_cast<float>(current_wave % 4) * 2.0f;
			spawn_raider(0, path, hp, speed, 6.0f, -1);
		}

		for (int i = 0; i < w.sea_count; i++) {
			Vector2 start_pos = map_to_local(1, Vector2i(0, grid_size.y > 0 ? grid_size.y / 2 : 2));
			start_pos.x -= static_cast<float>(i) * 32.0f; // stagger
			PackedVector2Array path; // Unused for Flow Field
			float hp = 50.0f + static_cast<float>(current_wave) * 3.0f;
			float speed = 26.0f + static_cast<float>(current_wave % 4) * 2.0f;
			spawn_raider(1, path, hp, speed, 6.0f, -1);
		}

		Dictionary ev;
		ev["type"] = "wave_spawned";
		ev["index"] = current_wave + 1;
		events.push_back(ev);

		current_wave++;
	}
}

PackedByteArray SimulationCore::save_state() const {
	using namespace MobileFortress::Schema;
	flatbuffers::FlatBufferBuilder builder(2048);

	std::vector<flatbuffers::Offset<Defender>> fbs_defenders;
	fbs_defenders.reserve(defenders.size());
	for (const auto &d : defenders) {
		auto type_str = builder.CreateString(d.type.utf8().get_data());
		Vec2 pos(d.position.x, d.position.y);
		Vec2 tfrom(d.travel_from.x, d.travel_from.y);
		Vec2 tto(d.travel_to.x, d.travel_to.y);
		fbs_defenders.push_back(CreateDefender(
				builder,
				d.id,
				d.front,
				type_str,
				&pos,
				d.alive,
				d.hp,
				d.damage,
				d.range_px,
				d.cooldown,
				d.cooldown_left,
				d.ability_cooldown,
				d.ability_cooldown_left,
				d.traveling,
				&tfrom,
				&tto,
				d.travel_t,
				d.travel_duration,
				d.aura_radius,
				d.aura_bonus,
				d.own_env_mult,
				d.cross_env_mult));
	}

	std::vector<flatbuffers::Offset<Raider>> fbs_raiders;
	fbs_raiders.reserve(raiders.size());
	for (const auto &r : raiders) {
		std::vector<Vec2> rpath;
		rpath.reserve(static_cast<size_t>(r.path.size()));
		for (int i = 0; i < r.path.size(); ++i) {
			rpath.emplace_back(r.path[i].x, r.path[i].y);
		}
		auto path_vec = builder.CreateVectorOfStructs(rpath);
		Vec2 pos(r.position.x, r.position.y);
		fbs_raiders.push_back(CreateRaider(
				builder,
				r.id,
				r.front,
				path_vec,
				r.hp,
				r.max_hp,
				r.speed,
				r.damage,
				r.path_i,
				r.outpost_path_i,
				r.struck_outpost,
				r.alive,
				&pos));
	}

	std::vector<flatbuffers::Offset<Wave>> fbs_waves;
	fbs_waves.reserve(waves.size());
	for (const auto &w : waves) {
		fbs_waves.push_back(CreateWave(builder, w.delay, w.land_count, w.sea_count, w.fired));
	}

	std::vector<Vec2> land_pts;
	land_pts.reserve(static_cast<size_t>(land_path.size()));
	for (int i = 0; i < land_path.size(); ++i) {
		land_pts.emplace_back(land_path[i].x, land_path[i].y);
	}
	std::vector<Vec2> sea_pts;
	sea_pts.reserve(static_cast<size_t>(sea_path.size()));
	for (int i = 0; i < sea_path.size(); ++i) {
		sea_pts.emplace_back(sea_path[i].x, sea_path[i].y);
	}

	auto state = CreateSimulationState(
			builder,
			land_resources,
			sea_resources,
			hq_hp,
			hq_max_hp,
			land_outpost_hp,
			sea_outpost_hp,
			land_outpost_max,
			sea_outpost_max,
			land_outpost_alive,
			sea_outpost_alive,
			enemies_killed,
			units_placed,
			in_combat,
			combat_time,
			current_wave,
			build_phase_seconds,
			victory_time,
			income_acc,
			next_raider_id,
			next_defender_id,
			builder.CreateVector(fbs_defenders),
			builder.CreateVector(fbs_raiders),
			builder.CreateVector(fbs_waves),
			builder.CreateVectorOfStructs(land_pts),
			builder.CreateVectorOfStructs(sea_pts),
			1);

	builder.Finish(state);

	PackedByteArray result;
	result.resize(static_cast<int64_t>(builder.GetSize()));
	memcpy(result.ptrw(), builder.GetBufferPointer(), builder.GetSize());
	return result;
}

bool SimulationCore::load_state(const PackedByteArray &data) {
	using namespace MobileFortress::Schema;
	if (data.size() == 0) {
		return false;
	}

	flatbuffers::Verifier verifier(data.ptr(), static_cast<size_t>(data.size()));
	if (!VerifySimulationStateBuffer(verifier)) {
		UtilityFunctions::push_warning("[MF] FlatBuffers VerifySimulationStateBuffer failed");
		return false;
	}

	const SimulationState *state = GetSimulationState(data.ptr());
	if (state == nullptr) {
		return false;
	}

	land_resources = state->land_resources();
	sea_resources = state->sea_resources();
	hq_hp = state->hq_hp();
	hq_max_hp = state->hq_max_hp();
	land_outpost_hp = state->land_outpost_hp();
	sea_outpost_hp = state->sea_outpost_hp();
	if (state->land_outpost_max() > 0) {
		land_outpost_max = state->land_outpost_max();
	}
	if (state->sea_outpost_max() > 0) {
		sea_outpost_max = state->sea_outpost_max();
	}
	land_outpost_alive = state->land_outpost_alive();
	sea_outpost_alive = state->sea_outpost_alive();
	enemies_killed = state->enemies_killed();
	units_placed = state->units_placed();
	in_combat = state->in_combat();
	combat_time = state->combat_time();
	current_wave = state->current_wave();
	if (state->build_phase_seconds() > 0.0f) {
		build_phase_seconds = state->build_phase_seconds();
	}
	if (state->victory_time() > 0.0f) {
		victory_time = state->victory_time();
	}
	income_acc = state->income_acc();
	next_raider_id = state->next_raider_id() > 0 ? state->next_raider_id() : 1;
	next_defender_id = state->next_defender_id() > 0 ? state->next_defender_id() : 10001;

	defenders.clear();
	if (state->defenders()) {
		for (const Defender *d : *state->defenders()) {
			if (d == nullptr) {
				continue;
			}
			DefenderData cd;
			cd.id = d->id();
			cd.front = d->front();
			cd.type = d->type() ? String(d->type()->c_str()) : String();
			if (d->position()) {
				cd.position = Vector2(d->position()->x(), d->position()->y());
			}
			cd.alive = d->alive();
			cd.hp = d->hp();
			cd.damage = d->damage();
			cd.range_px = d->range_px();
			cd.cooldown = d->cooldown();
			cd.cooldown_left = d->cooldown_left();
			cd.ability_cooldown = d->ability_cooldown();
			cd.ability_cooldown_left = d->ability_cooldown_left();
			cd.traveling = d->traveling();
			if (d->travel_from()) {
				cd.travel_from = Vector2(d->travel_from()->x(), d->travel_from()->y());
			}
			if (d->travel_to()) {
				cd.travel_to = Vector2(d->travel_to()->x(), d->travel_to()->y());
			}
			cd.travel_t = d->travel_t();
			cd.travel_duration = d->travel_duration() > 0.0f ? d->travel_duration() : 1.6f;
			cd.aura_radius = d->aura_radius();
			cd.aura_bonus = d->aura_bonus();
			cd.own_env_mult = d->own_env_mult();
			cd.cross_env_mult = d->cross_env_mult();
			defenders.push_back(cd);
		}
	}

	raiders.clear();
	if (state->raiders()) {
		for (const Raider *r : *state->raiders()) {
			if (r == nullptr) {
				continue;
			}
			RaiderData cr;
			cr.id = r->id();
			cr.front = r->front();
			cr.hp = r->hp();
			cr.max_hp = r->max_hp() > 0.0f ? r->max_hp() : r->hp();
			cr.speed = r->speed();
			cr.damage = r->damage();
			cr.path_i = r->path_index();
			cr.outpost_path_i = r->outpost_path_index();
			cr.struck_outpost = r->struck_outpost();
			cr.alive = r->alive();
			if (r->position()) {
				cr.position = Vector2(r->position()->x(), r->position()->y());
			}
			if (r->path()) {
				for (const Vec2 *p : *r->path()) {
					if (p) {
						cr.path.push_back(Vector2(p->x(), p->y()));
					}
				}
			}
			raiders.push_back(cr);
		}
	}

	waves.clear();
	if (state->waves()) {
		for (const Wave *w : *state->waves()) {
			if (w == nullptr) {
				continue;
			}
			WaveData wd;
			wd.delay = w->delay();
			wd.land_count = w->land_count();
			wd.sea_count = w->sea_count();
			wd.fired = w->fired();
			waves.push_back(wd);
		}
	}

	land_path.clear();
	if (state->land_path()) {
		for (const Vec2 *p : *state->land_path()) {
			if (p) {
				land_path.push_back(Vector2(p->x(), p->y()));
			}
		}
	}
	sea_path.clear();
	if (state->sea_path()) {
		for (const Vec2 *p : *state->sea_path()) {
			if (p) {
				sea_path.push_back(Vector2(p->x(), p->y()));
			}
		}
	}

	UtilityFunctions::print("[MF] load_state OK bytes=", data.size(),
			" defenders=", static_cast<int64_t>(defenders.size()),
			" raiders=", static_cast<int64_t>(raiders.size()),
			" combat=", in_combat);
	return true;
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
	if (level.has("startingLandCurrency")) {
		land_resources = static_cast<int>(level["startingLandCurrency"]);
	}
	if (level.has("startingSeaCurrency")) {
		sea_resources = static_cast<int>(level["startingSeaCurrency"]);
	}
	if (level.has("hqMaxHp")) {
		hq_max_hp = static_cast<int>(level["hqMaxHp"]);
		hq_hp = hq_max_hp;
	}
	if (level.has("buildPhaseSeconds")) {
		build_phase_seconds = static_cast<float>(level["buildPhaseSeconds"]);
	}
	if (level.has("victoryTimeSeconds")) {
		victory_time = static_cast<float>(level["victoryTimeSeconds"]);
	}

	waves.clear();
	if (level.has("waves") && level["waves"].get_type() == Variant::ARRAY) {
		Array arr = level["waves"];
		for (int i = 0; i < arr.size(); ++i) {
			if (arr[i].get_type() != Variant::DICTIONARY) {
				continue;
			}
			Dictionary w = arr[i];
			WaveData wd;
			wd.delay = static_cast<float>(w.get("delaySeconds", 0.0));
			wd.land_count = static_cast<int>(w.get("landCount", w.get("enemyCount", 2)));
			wd.sea_count = static_cast<int>(w.get("seaCount", 2));
			wd.fired = false;
			waves.push_back(wd);
		}
	}
	if (waves.empty()) {
		waves.push_back({2.0f, 2, 2, false});
		waves.push_back({12.0f, 3, 3, false});
		waves.push_back({24.0f, 4, 4, false});
		waves.push_back({38.0f, 5, 5, false});
	}
	UtilityFunctions::print("[MF] loaded level waves=", static_cast<int64_t>(waves.size()),
			" land=", land_resources, " sea=", sea_resources);
	return true;
}

void SimulationCore::start_combat() {
	in_combat = true;
	combat_time = 0.0f;
	current_wave = 0;
	for (auto &w : waves) {
		w.fired = false;
	}
}

Array SimulationCore::tick(double delta, bool income_enabled) {
	Array events;
	if (in_combat) {
		combat_time += static_cast<float>(delta);
		check_and_spawn_waves(events);
	}

	if (income_enabled && in_combat) {
		income_acc += static_cast<float>(delta);
		if (income_acc >= 4.0f) {
			income_acc = 0.0f;
			if (land_outpost_alive) {
				land_resources += 2;
			}
			if (sea_outpost_alive) {
				sea_resources += 2;
			}
			Dictionary inc;
			inc["type"] = "income";
			inc["land"] = land_resources;
			inc["sea"] = sea_resources;
			events.push_back(inc);
		}
	}

	run_travel(delta);

	for (auto &r : raiders) {
		if (!r.alive) continue;

		Vector2i cell = local_to_map(r.front, r.position);
		auto &grid = (r.front == 0) ? land_flow : sea_flow;

		// If reached HQ
		if (cell.x >= grid_size.x - 1) {
			damage_hq(static_cast<int>(r.damage));
			r.alive = false;
			Dictionary ev;
			ev["type"] = "hq_hit";
			ev["id"] = r.id;
			ev["front"] = r.front;
			ev["damage"] = r.damage;
			ev["hq_hp"] = hq_hp;
			events.push_back(ev);
			if (hq_hp <= 0) {
				Dictionary dead;
				dead["type"] = "hq_destroyed";
				events.push_back(dead);
			}
			continue;
		}

		Vector2 target_pos;
		if (cell.x < 0 || cell.x >= grid_size.x || cell.y < 0 || cell.y >= grid_size.y) {
			// Off grid (just spawned), move to (0, mid)
			target_pos = map_to_local(r.front, Vector2i(0, grid_size.y > 0 ? grid_size.y / 2 : 2));
		} else {
			int idx = cell.y * grid_size.x + cell.x;
			Vector2i dir = grid[idx].dir;
			if (dir == Vector2i(0, 0)) {
				// Blocked or at target, just move right if possible
				dir = Vector2i(1, 0);
			}
			Vector2i next_cell = cell + dir;
			target_pos = map_to_local(r.front, next_cell);
		}

		Vector2 dir = target_pos - r.position;
		float dist = dir.length();
		float step = r.speed * static_cast<float>(delta);

		if (dist > 0.001f) {
			r.position += (dir / dist) * step;
		}

		// Outpost hit logic (legacy)
		if (!r.struck_outpost && cell.x >= grid_size.x / 2) {
			r.struck_outpost = true;
			int strike = std::max(4, static_cast<int>(r.damage));
			damage_outpost(r.front, strike, events);
		}
	}

	run_defender_combat(delta, events);

	raiders.erase(std::remove_if(raiders.begin(), raiders.end(),
						  [](const RaiderData &r) { return !r.alive; }),
			raiders.end());
	defenders.erase(std::remove_if(defenders.begin(), defenders.end(),
						  [](const DefenderData &d) { return !d.alive; }),
			defenders.end());

	// Victory signal for presentation
	if (in_combat && combat_time >= victory_time && get_raider_count() == 0) {
		bool all_fired = true;
		for (const auto &w : waves) {
			if (!w.fired) {
				all_fired = false;
				break;
			}
		}
		if (all_fired) {
			Dictionary win;
			win["type"] = "victory";
			win["reason"] = "Raid weathered — fortress holds";
			events.push_back(win);
		}
	}

	return events;
}

Array SimulationCore::get_raiders() const {
	Array out;
	for (const auto &r : raiders) {
		if (!r.alive) {
			continue;
		}
		Dictionary d;
		d["id"] = r.id;
		d["front"] = r.front;
		d["hp"] = r.hp;
		d["max_hp"] = r.max_hp;
		d["position"] = r.position;
		d["path_i"] = r.path_i;
		out.push_back(d);
	}
	return out;
}

Array SimulationCore::get_defenders() const {
	Array out;
	for (const auto &d : defenders) {
		if (!d.alive) {
			continue;
		}
		Dictionary dict;
		dict["id"] = d.id;
		dict["front"] = d.front;
		dict["type"] = d.type;
		dict["position"] = d.position;
		dict["traveling"] = d.traveling;
		dict["range_px"] = d.range_px;
		dict["ability_cooldown_left"] = d.ability_cooldown_left;
		out.push_back(dict);
	}
	return out;
}

int SimulationCore::get_raider_count() const {
	int n = 0;
	for (const auto &r : raiders) {
		if (r.alive) {
			n++;
		}
	}
	return n;
}

int SimulationCore::get_defender_count() const {
	int n = 0;
	for (const auto &d : defenders) {
		if (d.alive) {
			n++;
		}
	}
	return n;
}

void SimulationCore::init_grids(Vector2i size) {
	grid_size = size;
	land_flow.resize(size.x * size.y);
	sea_flow.resize(size.x * size.y);
	for (auto &c : land_flow) { c.solid = false; c.cost = 9999; }
	for (auto &c : sea_flow) { c.solid = false; c.cost = 9999; }
	UtilityFunctions::print("[MF] C++ Flow Field initialized ", size.x, "x", size.y);
}

void SimulationCore::set_cell_solid(int front, Vector2i cell, bool solid) {
	if (cell.x < 0 || cell.y < 0 || cell.x >= grid_size.x || cell.y >= grid_size.y) return;
	auto &grid = (front == 0) ? land_flow : sea_flow;
	grid[cell.y * grid_size.x + cell.x].solid = solid;
	update_flow_field(front, Vector2i(grid_size.x - 1, grid_size.y / 2));
}

void SimulationCore::mark_cell_solid(int front, Vector2i cell, bool solid) {
	set_cell_solid(front, cell, solid);
}

void SimulationCore::update_flow_field(int front, Vector2i target) {
	if (grid_size.x <= 0 || grid_size.y <= 0) return;
	auto &grid = (front == 0) ? land_flow : sea_flow;

	for (auto &c : grid) {
		c.cost = 9999;
		c.dir = Vector2i(0, 0);
	}

	std::vector<Vector2i> queue;
	int ty = std::clamp(target.y, 0, grid_size.y - 1);
	int tx = std::clamp(target.x, 0, grid_size.x - 1);
	Vector2i t(tx, ty);

	grid[t.y * grid_size.x + t.x].cost = 0;
	queue.push_back(t);

	Vector2i dirs[4] = { Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1) };

	int head = 0;
	while(head < queue.size()) {
		Vector2i curr = queue[head++];
		int curr_cost = grid[curr.y * grid_size.x + curr.x].cost;

		for (auto d : dirs) {
			Vector2i next = curr + d;
			if (next.x < 0 || next.y < 0 || next.x >= grid_size.x || next.y >= grid_size.y) continue;

			int idx = next.y * grid_size.x + next.x;
			if (grid[idx].solid) continue;

			if (curr_cost + 1 < grid[idx].cost) {
				grid[idx].cost = curr_cost + 1;
				grid[idx].dir = Vector2i(-d.x, -d.y); // point back to curr
				queue.push_back(next);
			}
		}
	}
}

Vector2 SimulationCore::map_to_local(int front, Vector2i cell) const {
	float tile_w = 64.0f;
	float tile_h = 32.0f;
	float px = (cell.x - cell.y) * (tile_w * 0.5f);
	float py = (cell.x + cell.y) * (tile_h * 0.5f);
	if (front == 1) {
		px += 300.0f;
		py += 600.0f;
	} else {
		px += 300.0f;
		py += 200.0f;
	}
	return Vector2(px, py);
}

Vector2i SimulationCore::local_to_map(int front, Vector2 pos) const {
	float tile_w = 64.0f;
	float tile_h = 32.0f;
	float px = pos.x;
	float py = pos.y;
	if (front == 1) {
		px -= 300.0f;
		py -= 600.0f;
	} else {
		px -= 300.0f;
		py -= 200.0f;
	}

	float dx = px / (tile_w * 0.5f);
	float dy = py / (tile_h * 0.5f);

	int cx = std::round((dy + dx) * 0.5f);
	int cy = std::round((dy - dx) * 0.5f);
	return Vector2i(cx, cy);
}

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
