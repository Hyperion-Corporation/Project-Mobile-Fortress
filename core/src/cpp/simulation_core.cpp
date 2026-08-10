#include "simulation_core.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <algorithm>

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
	ClassDB::bind_method(D_METHOD("is_hq_alive"), &SimulationCore::is_hq_alive);
	ClassDB::bind_method(D_METHOD("spend", "front", "amount"), &SimulationCore::spend);
	ClassDB::bind_method(D_METHOD("gain", "front", "amount"), &SimulationCore::gain);
	ClassDB::bind_method(D_METHOD("damage_hq", "amount"), &SimulationCore::damage_hq);
	ClassDB::bind_method(D_METHOD("set_outpost_alive", "front", "alive"), &SimulationCore::set_outpost_alive);
	ClassDB::bind_method(D_METHOD("note_unit_placed"), &SimulationCore::note_unit_placed);
	ClassDB::bind_method(D_METHOD("spawn_raider", "front", "path", "hp", "speed", "damage"), &SimulationCore::spawn_raider);
	ClassDB::bind_method(D_METHOD("damage_raider", "id", "amount"), &SimulationCore::damage_raider);
	ClassDB::bind_method(D_METHOD("tick", "delta", "income_enabled"), &SimulationCore::tick, DEFVAL(true));
	ClassDB::bind_method(D_METHOD("get_raiders"), &SimulationCore::get_raiders);
	ClassDB::bind_method(D_METHOD("get_raider_count"), &SimulationCore::get_raider_count);
	ClassDB::bind_method(D_METHOD("spawn_entity", "type", "position"), &SimulationCore::spawn_entity);
}

SimulationCore::SimulationCore() {
	UtilityFunctions::print("[MF] SimulationCore ready (EnTT + dual-front Slice-0 API)");
}

SimulationCore::~SimulationCore() = default;

void SimulationCore::reset_run(int start_land, int start_sea, int start_hq) {
	land_resources = start_land;
	sea_resources = start_sea;
	hq_hp = start_hq;
	hq_max_hp = start_hq;
	enemies_killed = 0;
	units_placed = 0;
	land_outpost_alive = true;
	sea_outpost_alive = true;
	income_acc = 0.0f;
	raiders.clear();
	registry.clear();
	next_raider_id = 1;
}

int SimulationCore::get_land_resources() const { return land_resources; }
int SimulationCore::get_sea_resources() const { return sea_resources; }
int SimulationCore::get_hq_hp() const { return hq_hp; }
int SimulationCore::get_hq_max_hp() const { return hq_max_hp; }
int SimulationCore::get_enemies_killed() const { return enemies_killed; }
int SimulationCore::get_units_placed() const { return units_placed; }
bool SimulationCore::is_land_outpost_alive() const { return land_outpost_alive; }
bool SimulationCore::is_sea_outpost_alive() const { return sea_outpost_alive; }
bool SimulationCore::is_hq_alive() const { return hq_hp > 0; }

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
	} else if (front == 1) {
		sea_outpost_alive = alive;
	}
}

void SimulationCore::note_unit_placed() {
	units_placed += 1;
}

int SimulationCore::spawn_raider(int front, PackedVector2Array path, float hp, float speed, float damage) {
	if (path.size() == 0) {
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

Array SimulationCore::tick(double delta, bool income_enabled) {
	Array events;
	if (income_enabled) {
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

	for (auto &r : raiders) {
		if (!r.alive) {
			continue;
		}
		if (r.path.size() == 0) {
			continue;
		}
		if (r.path_i >= r.path.size() - 1) {
			// Reached HQ end
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

		Vector2 target = r.path[r.path_i + 1];
		Vector2 dir = target - r.position;
		float dist = dir.length();
		float step = r.speed * static_cast<float>(delta);
		if (dist <= step || dist < 0.001f) {
			r.position = target;
			r.path_i += 1;
		} else {
			r.position += dir.normalized() * step;
		}
	}

	// Compact dead raiders occasionally to keep list small
	raiders.erase(std::remove_if(raiders.begin(), raiders.end(),
						  [](const RaiderData &r) { return !r.alive; }),
			raiders.end());

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
		out.push_back(d);
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

void SimulationCore::_process(double delta) {
	// Keep legacy entity move system for smoke tests.
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
