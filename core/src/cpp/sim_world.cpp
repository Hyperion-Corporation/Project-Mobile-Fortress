#include "sim_world.h"

#include "simulation_state_generated.h"

#include <cstring>

namespace mf {

void SimWorld::reset_run(int start_land, int start_sea, int start_hq) {
	land_resources_ = start_land;
	sea_resources_ = start_sea;
	hq_hp_ = start_hq;
	hq_max_hp_ = start_hq;
	enemies_killed_ = 0;
	units_placed_ = 0;
	land_outpost_hp_ = land_outpost_max_;
	sea_outpost_hp_ = sea_outpost_max_;
	land_outpost_alive_ = true;
	sea_outpost_alive_ = true;
	income_acc_ = 0.0f;
	raiders_.clear();
	defenders_.clear();
	next_raider_id_ = 1;
	next_defender_id_ = 10001;
	if (grid_size_.x > 0 && grid_size_.y > 0) {
		update_flow_field(0, Vec2i(grid_size_.x - 1, grid_size_.y / 2));
		update_flow_field(1, Vec2i(grid_size_.x - 1, grid_size_.y / 2));
	}
	in_combat_ = false;
	combat_time_ = 0.0f;
	current_wave_ = 0;
	for (auto &w : waves_) {
		w.fired = false;
	}
}

bool SimWorld::flow_active() const {
	return grid_size_.x > 0 && grid_size_.y > 0 && !land_flow_.empty() && !sea_flow_.empty();
}

bool SimWorld::spend(int front, int amount) {
	if (amount < 0) {
		return false;
	}
	if (front == 0) {
		if (land_resources_ < amount) {
			return false;
		}
		land_resources_ -= amount;
		return true;
	}
	if (front == 1) {
		if (sea_resources_ < amount) {
			return false;
		}
		sea_resources_ -= amount;
		return true;
	}
	return false;
}

bool SimWorld::is_hero_type(const std::string &type) {
	return type == "hero_qi" || type == "hero" || type == "hero_dias";
}

int SimWorld::outpost_income(int hp, int max_hp, bool alive) {
	if (!alive || hp <= 0 || max_hp <= 0) {
		return 0;
	}
	// Full HP → 2; half or better → 1; standing but badly damaged → 1.
	const int scaled = (2 * hp) / max_hp;
	return std::max(1, scaled);
}

void SimWorld::gain(int front, int amount) {
	if (amount <= 0) {
		return;
	}
	if (front == 0) {
		land_resources_ += amount;
	} else if (front == 1) {
		sea_resources_ += amount;
	}
}

void SimWorld::damage_hq(int amount) {
	if (amount <= 0) {
		return;
	}
	hq_hp_ = std::max(0, hq_hp_ - amount);
}

void SimWorld::set_outpost_alive(int front, bool alive) {
	if (front == 0) {
		land_outpost_alive_ = alive;
		if (!alive) {
			land_outpost_hp_ = 0;
		} else if (land_outpost_hp_ <= 0) {
			land_outpost_hp_ = land_outpost_max_;
		}
	} else if (front == 1) {
		sea_outpost_alive_ = alive;
		if (!alive) {
			sea_outpost_hp_ = 0;
		} else if (sea_outpost_hp_ <= 0) {
			sea_outpost_hp_ = sea_outpost_max_;
		}
	}
}

void SimWorld::set_lane_path(int front, const std::vector<Vec2> &path) {
	if (front == 0) {
		land_path_ = path;
	} else if (front == 1) {
		sea_path_ = path;
	}
}

std::vector<Vec2> SimWorld::default_lane_path(int front) const {
	const float y = (front == 0) ? 150.0f : 250.0f;
	return {Vec2(-20.0f, y), Vec2(200.0f, y), Vec2(400.0f, y)};
}

int SimWorld::spawn_raider(int front, const std::vector<Vec2> &path, float hp, float speed, float damage, int outpost_path_i,
		int entry_row) {
	if (static_cast<int>(raiders_.size()) >= 40) {
		return -1;
	}
	if (path.empty() && !flow_active()) {
		return -1;
	}
	Raider r;
	r.id = next_raider_id_++;
	r.front = front;
	r.hp = hp;
	r.max_hp = hp;
	r.speed = speed;
	r.damage = damage;
	r.path = path;
	r.path_i = 0;
	r.entry_row = entry_row;
	if (!path.empty()) {
		r.position = path[0];
	} else {
		const int row = pick_entry_row(front, entry_row);
		r.entry_row = row;
		r.position = map_to_local(front, Vec2i(0, row));
		r.position.x -= 32.0f;
	}
	r.alive = true;
	r.struck_outpost = false;
	if (outpost_path_i < 0) {
		if (!path.empty()) {
			r.outpost_path_i = std::max(1, static_cast<int>(path.size()) / 2);
		} else {
			r.outpost_path_i = -1;
		}
	} else {
		r.outpost_path_i = outpost_path_i;
	}
	raiders_.push_back(r);
	return r.id;
}

void SimWorld::damage_raider(int id, float amount) {
	for (auto &r : raiders_) {
		if (r.id == id && r.alive) {
			r.hp -= amount;
			if (r.hp <= 0.0f) {
				r.alive = false;
				enemies_killed_ += 1;
			}
			return;
		}
	}
}

int SimWorld::spawn_defender(int front, const std::string &type, Vec2 position, float range_px, float damage, float cooldown,
		float own_env_mult, float cross_env_mult, float aura_radius, float aura_bonus) {
	if (is_hero_type(type)) {
		for (const auto &existing : defenders_) {
			if (existing.alive && existing.type == type) {
				return -1;
			}
		}
	}
	Defender d;
	d.id = next_defender_id_++;
	d.front = front;
	d.type = type;
	d.position = position;
	d.range_px = range_px;
	d.damage = damage;
	d.hp = 100.0f;
	d.cooldown = std::max(0.1f, cooldown);
	d.cooldown_left = 0.0f;
	d.ability_cooldown = (type == "hero_dias") ? 10.0f : 8.0f;
	d.ability_cooldown_left = 0.0f;
	d.own_env_mult = own_env_mult;
	d.cross_env_mult = cross_env_mult;
	d.aura_radius = aura_radius;
	d.aura_bonus = aura_bonus;
	d.alive = true;
	d.travel_from = position;
	d.travel_to = position;
	defenders_.push_back(d);
	units_placed_ += 1;
	return d.id;
}

bool SimWorld::upgrade_defender(int id) {
	for (auto &d : defenders_) {
		if (d.id == id && d.alive && !d.traveling) {
			d.damage *= 1.25f;
			d.range_px += 12.0f;
			return true;
		}
	}
	return false;
}

bool SimWorld::start_defender_travel(int id, Vec2 to, int new_front, float duration) {
	for (auto &d : defenders_) {
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

HeroCast SimWorld::cast_hero_ability(int id) {
	HeroCast result;
	for (auto &d : defenders_) {
		if (d.id != id || !d.alive || d.traveling) {
			continue;
		}
		if (d.ability_cooldown_left > 0.0f) {
			result.reason = "on_cooldown";
			result.cooldown_left = d.ability_cooldown_left;
			return result;
		}
		if (d.type == "hero_qi" || d.type == "hero") {
			int hits = 0;
			const float radius_px = 250.0f;
			const float damage = 35.0f;
			for (auto &r : raiders_) {
				if (r.alive && d.position.distance_to(r.position) <= radius_px) {
					r.hp -= damage;
					hits += 1;
					if (r.hp <= 0.0f) {
						r.alive = false;
						enemies_killed_ += 1;
					}
				}
			}
			d.ability_cooldown_left = d.ability_cooldown;
			result.success = true;
			result.type = "pulse";
			result.hits = hits;
			return result;
		}
		if (d.type == "hero_dias") {
			// Cross-front salvo: Portuguese guns rake the opposite grid (no world-radius —
			// land/sea origins are hundreds of px apart by design).
			int hits = 0;
			const float damage = 22.0f;
			for (auto &r : raiders_) {
				if (!r.alive || r.front == d.front) {
					continue;
				}
				r.hp -= damage;
				hits += 1;
				if (r.hp <= 0.0f) {
					r.alive = false;
					enemies_killed_ += 1;
				}
			}
			d.ability_cooldown_left = d.ability_cooldown;
			result.success = true;
			result.type = "salvo";
			result.hits = hits;
			return result;
		}
		result.reason = "not_hero";
		return result;
	}
	result.reason = "not_found";
	return result;
}

float SimWorld::total_aura_at(Vec2 pos) const {
	float bonus = 0.0f;
	for (const auto &d : defenders_) {
		if (!d.alive || d.aura_radius <= 0.0f) {
			continue;
		}
		if (d.position.distance_to(pos) <= d.aura_radius) {
			bonus += d.aura_bonus;
		}
	}
	return bonus;
}

void SimWorld::run_travel(double delta) {
	for (auto &d : defenders_) {
		if (!d.alive || !d.traveling) {
			continue;
		}
		d.travel_t += static_cast<float>(delta) / d.travel_duration;
		const float t = std::clamp(d.travel_t, 0.0f, 1.0f);
		d.position = d.travel_from.lerp(d.travel_to, t);
		if (t >= 1.0f) {
			d.traveling = false;
			d.position = d.travel_to;
		}
	}
}

void SimWorld::run_defender_combat(double delta, std::vector<SimEvent> &events) {
	for (auto &d : defenders_) {
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
		Raider *best = nullptr;
		float best_d = 1e9f;
		for (auto &r : raiders_) {
			if (!r.alive) {
				continue;
			}
			const float dist = d.position.distance_to(r.position);
			if (dist > d.range_px) {
				continue;
			}
			const bool same = (r.front == d.front);
			const float mult = same ? d.own_env_mult : d.cross_env_mult;
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
		const bool same = (best->front == d.front);
		const float mult = same ? d.own_env_mult : d.cross_env_mult;
		const float dmg = d.damage * mult * (1.0f + total_aura_at(d.position));
		best->hp -= dmg;
		d.cooldown_left = d.cooldown;
		if (best->hp <= 0.0f) {
			best->alive = false;
			enemies_killed_ += 1;
			SimEvent kill;
			kill.type = "raider_killed";
			kill.id = best->id;
			kill.front = best->front;
			events.push_back(kill);
		}
	}
}

void SimWorld::spawn_wave_raiders(int front, int count, int wave_index) {
	const bool use_flow = flow_active();
	for (int i = 0; i < count; i++) {
		const float hp = 50.0f + static_cast<float>(wave_index) * 3.0f;
		const float speed = 26.0f + static_cast<float>(wave_index % 4) * 2.0f;
		std::vector<Vec2> path;
		int entry_row = -1;
		if (!use_flow) {
			if (front == 0 && !land_path_.empty()) {
				path = land_path_;
			} else if (front == 1 && !sea_path_.empty()) {
				path = sea_path_;
			} else {
				path = default_lane_path(front);
			}
			if (!path.empty() && i > 0) {
				path[0].x -= static_cast<float>(i) * 20.0f;
			}
		} else {
			entry_row = pick_entry_row(front, i);
		}
		spawn_raider(front, path, hp, speed, 6.0f, -1, entry_row);
	}
}

void SimWorld::check_and_spawn_waves(std::vector<SimEvent> &events) {
	if (!in_combat_ || current_wave_ >= static_cast<int>(waves_.size())) {
		return;
	}
	if (combat_time_ >= waves_[current_wave_].delay) {
		Wave &w = waves_[current_wave_];
		spawn_wave_raiders(0, w.land_count, current_wave_);
		spawn_wave_raiders(1, w.sea_count, current_wave_);
		w.fired = true;
		SimEvent ev;
		ev.type = "wave_spawned";
		ev.index = current_wave_ + 1;
		events.push_back(ev);
		current_wave_++;
	}
}

void SimWorld::start_combat() {
	in_combat_ = true;
	combat_time_ = 0.0f;
	current_wave_ = 0;
	for (auto &w : waves_) {
		w.fired = false;
	}
}

void SimWorld::clear_waves() {
	waves_.clear();
}

void SimWorld::add_wave(float delay, int land_count, int sea_count) {
	waves_.push_back(Wave{delay, land_count, sea_count, false});
}

void SimWorld::set_build_phase_seconds(float seconds) {
	if (seconds > 0.0f) {
		build_phase_seconds_ = seconds;
	}
}

void SimWorld::set_victory_time(float seconds) {
	if (seconds > 0.0f) {
		victory_time_ = seconds;
	}
}

std::vector<SimEvent> SimWorld::tick(double delta, bool income_enabled) {
	std::vector<SimEvent> events;
	if (in_combat_) {
		combat_time_ += static_cast<float>(delta);
		check_and_spawn_waves(events);
	}
	if (income_enabled && in_combat_) {
		income_acc_ += static_cast<float>(delta);
		if (income_acc_ >= 4.0f) {
			income_acc_ = 0.0f;
			const int land_pay = outpost_income(land_outpost_hp_, land_outpost_max_, land_outpost_alive_);
			const int sea_pay = outpost_income(sea_outpost_hp_, sea_outpost_max_, sea_outpost_alive_);
			land_resources_ += land_pay;
			sea_resources_ += sea_pay;
			SimEvent inc;
			inc.type = "income";
			inc.land = land_resources_;
			inc.sea = sea_resources_;
			inc.land_income = land_pay;
			inc.sea_income = sea_pay;
			events.push_back(inc);
		}
	}
	run_travel(delta);
	for (auto &r : raiders_) {
		if (!r.alive) {
			continue;
		}
		if (!r.path.empty()) {
			advance_raider_along_path(r, delta, events);
		} else if (flow_active()) {
			advance_raider_along_flow(r, delta, events);
		}
	}
	run_defender_combat(delta, events);
	raiders_.erase(std::remove_if(raiders_.begin(), raiders_.end(),
						   [](const Raider &r) { return !r.alive; }),
			raiders_.end());
	defenders_.erase(std::remove_if(defenders_.begin(), defenders_.end(),
							[](const Defender &d) { return !d.alive; }),
			defenders_.end());
	if (in_combat_ && combat_time_ >= victory_time_ && raider_count() == 0) {
		bool all_fired = true;
		for (const auto &w : waves_) {
			if (!w.fired) {
				all_fired = false;
				break;
			}
		}
		if (all_fired) {
			SimEvent win;
			win.type = "victory";
			win.reason = "Raid weathered — fortress holds";
			events.push_back(win);
		}
	}
	return events;
}

int SimWorld::raider_count() const {
	int n = 0;
	for (const auto &r : raiders_) {
		if (r.alive) {
			n++;
		}
	}
	return n;
}

int SimWorld::defender_count() const {
	int n = 0;
	for (const auto &d : defenders_) {
		if (d.alive) {
			n++;
		}
	}
	return n;
}

void SimWorld::advance_raider_along_path(Raider &r, double delta, std::vector<SimEvent> &events) {
	if (r.path.empty()) {
		return;
	}
	if (r.path_i >= static_cast<int>(r.path.size()) - 1) {
		damage_hq(static_cast<int>(r.damage));
		r.alive = false;
		SimEvent ev;
		ev.type = "hq_hit";
		ev.id = r.id;
		ev.front = r.front;
		ev.damage = r.damage;
		ev.hq_hp = hq_hp_;
		events.push_back(ev);
		if (hq_hp_ <= 0) {
			SimEvent dead;
			dead.type = "hq_destroyed";
			events.push_back(dead);
		}
		return;
	}
	const Vec2 target = r.path[static_cast<size_t>(r.path_i + 1)];
	const Vec2 dir = target - r.position;
	const float dist = dir.length();
	const float step = r.speed * static_cast<float>(delta);
	if (dist <= step || dist < 0.001f) {
		r.position = target;
		r.path_i += 1;
		if (!r.struck_outpost && r.path_i >= r.outpost_path_i) {
			r.struck_outpost = true;
			damage_outpost(r.front, std::max(4, static_cast<int>(r.damage)), events);
		}
	} else {
		r.position = r.position + dir.normalized() * step;
	}
}

void SimWorld::advance_raider_along_flow(Raider &r, double delta, std::vector<SimEvent> &events) {
	const Vec2i cell = local_to_map(r.front, r.position);
	if (cell.x >= grid_size_.x - 1 && cell.x >= 0 && cell.y >= 0 && cell.y < grid_size_.y) {
		damage_hq(static_cast<int>(r.damage));
		r.alive = false;
		SimEvent ev;
		ev.type = "hq_hit";
		ev.id = r.id;
		ev.front = r.front;
		ev.damage = r.damage;
		ev.hq_hp = hq_hp_;
		events.push_back(ev);
		if (hq_hp_ <= 0) {
			SimEvent dead;
			dead.type = "hq_destroyed";
			events.push_back(dead);
		}
		return;
	}
	Vec2 target_pos;
	if (cell.x < 0 || cell.x >= grid_size_.x || cell.y < 0 || cell.y >= grid_size_.y) {
		const int row = r.entry_row >= 0 ? r.entry_row : grid_size_.y / 2;
		target_pos = map_to_local(r.front, Vec2i(0, row));
	} else {
		const Vec2i step = pick_flow_step(r.front, cell);
		target_pos = map_to_local(r.front, cell + step);
	}
	const Vec2 dir = target_pos - r.position;
	const float dist = dir.length();
	const float step = r.speed * static_cast<float>(delta);
	if (dist > 0.001f) {
		r.position = r.position + dir.normalized() * step;
	}
	if (!r.struck_outpost && cell.x >= grid_size_.x / 2 && cell.x >= 0) {
		r.struck_outpost = true;
		damage_outpost(r.front, std::max(4, static_cast<int>(r.damage)), events);
	}
}

void SimWorld::damage_outpost(int front, int amount, std::vector<SimEvent> &events) {
	if (amount <= 0) {
		return;
	}
	const bool was_alive = (front == 0) ? land_outpost_alive_ : sea_outpost_alive_;
	if (!was_alive) {
		return;
	}
	if (front == 0) {
		land_outpost_hp_ = std::max(0, land_outpost_hp_ - amount);
		if (land_outpost_hp_ <= 0) {
			land_outpost_alive_ = false;
		}
	} else if (front == 1) {
		sea_outpost_hp_ = std::max(0, sea_outpost_hp_ - amount);
		if (sea_outpost_hp_ <= 0) {
			sea_outpost_alive_ = false;
		}
	} else {
		return;
	}
	SimEvent dmg;
	dmg.type = "outpost_damaged";
	dmg.front = front;
	dmg.amount = amount;
	dmg.hp = (front == 0) ? land_outpost_hp_ : sea_outpost_hp_;
	dmg.max_hp = (front == 0) ? land_outpost_max_ : sea_outpost_max_;
	dmg.alive = (front == 0) ? land_outpost_alive_ : sea_outpost_alive_;
	events.push_back(dmg);
	const bool now_alive = (front == 0) ? land_outpost_alive_ : sea_outpost_alive_;
	if (was_alive && !now_alive) {
		SimEvent lost;
		lost.type = "outpost_lost";
		lost.front = front;
		lost.economic_only = true;
		events.push_back(lost);
	}
}

void SimWorld::init_grids(int width, int height) {
	if (width <= 0 || height <= 0) {
		return;
	}
	grid_size_ = Vec2i(width, height);
	land_flow_.assign(static_cast<size_t>(width * height), FlowCell{});
	sea_flow_.assign(static_cast<size_t>(width * height), FlowCell{});
	update_flow_field(0, Vec2i(grid_size_.x - 1, grid_size_.y / 2));
	update_flow_field(1, Vec2i(grid_size_.x - 1, grid_size_.y / 2));
}

bool SimWorld::is_cell_solid(int front, Vec2i cell) const {
	if (!flow_active()) {
		return false;
	}
	if (cell.x < 0 || cell.y < 0 || cell.x >= grid_size_.x || cell.y >= grid_size_.y) {
		return false;
	}
	const auto &grid = (front == 0) ? land_flow_ : sea_flow_;
	return grid[static_cast<size_t>(cell.y * grid_size_.x + cell.x)].solid;
}

Vec2i SimWorld::flow_dir_at(int front, Vec2i cell) const {
	if (!flow_active()) {
		return {0, 0};
	}
	if (cell.x < 0 || cell.y < 0 || cell.x >= grid_size_.x || cell.y >= grid_size_.y) {
		return {0, 0};
	}
	const auto &grid = (front == 0) ? land_flow_ : sea_flow_;
	return grid[static_cast<size_t>(cell.y * grid_size_.x + cell.x)].dir;
}

int SimWorld::pick_entry_row(int front, int preferred) const {
	if (!flow_active() || grid_size_.y <= 0) {
		return 0;
	}
	const int start = preferred >= 0 ? (preferred % grid_size_.y) : (grid_size_.y / 2);
	for (int k = 0; k < grid_size_.y; ++k) {
		const int row = (start + k) % grid_size_.y;
		if (!is_cell_solid(front, Vec2i(0, row))) {
			return row;
		}
	}
	return start;
}

Vec2i SimWorld::pick_flow_step(int front, Vec2i cell) const {
	const Vec2i fallback{1, 0};
	if (!flow_active()) {
		return fallback;
	}
	if (cell.x < 0 || cell.y < 0 || cell.x >= grid_size_.x || cell.y >= grid_size_.y) {
		return fallback;
	}
	const auto &grid = (front == 0) ? land_flow_ : sea_flow_;
	Vec2i fdir = grid[static_cast<size_t>(cell.y * grid_size_.x + cell.x)].dir;
	if (fdir == Vec2i(0, 0)) {
		fdir = fallback;
	}
	const Vec2i next = cell + fdir;
	if (!is_cell_solid(front, next)) {
		return fdir;
	}
	const Vec2i dirs[4] = {Vec2i(1, 0), Vec2i(0, 1), Vec2i(0, -1), Vec2i(-1, 0)};
	int best_cost = 9999;
	Vec2i best = fallback;
	for (const auto d : dirs) {
		const Vec2i cand = cell + d;
		if (cand.x < 0 || cand.y < 0 || cand.x >= grid_size_.x || cand.y >= grid_size_.y) {
			continue;
		}
		if (is_cell_solid(front, cand)) {
			continue;
		}
		const int cost = grid[static_cast<size_t>(cand.y * grid_size_.x + cand.x)].cost;
		if (cost < best_cost) {
			best_cost = cost;
			best = d;
		}
	}
	return best;
}

void SimWorld::set_cell_solid(int front, Vec2i cell, bool solid) {
	if (!flow_active()) {
		return;
	}
	if (cell.x < 0 || cell.y < 0 || cell.x >= grid_size_.x || cell.y >= grid_size_.y) {
		return;
	}
	auto &grid = (front == 0) ? land_flow_ : sea_flow_;
	grid[static_cast<size_t>(cell.y * grid_size_.x + cell.x)].solid = solid;
	update_flow_field(front, Vec2i(grid_size_.x - 1, grid_size_.y / 2));
}

void SimWorld::update_flow_field(int front, Vec2i target) {
	if (grid_size_.x <= 0 || grid_size_.y <= 0) {
		return;
	}
	auto &grid = (front == 0) ? land_flow_ : sea_flow_;
	for (auto &c : grid) {
		c.cost = 9999;
		c.dir = Vec2i(0, 0);
	}
	std::vector<Vec2i> queue;
	const int ty = std::clamp(target.y, 0, grid_size_.y - 1);
	const int tx = std::clamp(target.x, 0, grid_size_.x - 1);
	const Vec2i t(tx, ty);
	grid[static_cast<size_t>(t.y * grid_size_.x + t.x)].cost = 0;
	queue.push_back(t);
	const Vec2i dirs[4] = {Vec2i(1, 0), Vec2i(-1, 0), Vec2i(0, 1), Vec2i(0, -1)};
	size_t head = 0;
	while (head < queue.size()) {
		const Vec2i curr = queue[head++];
		const int curr_cost = grid[static_cast<size_t>(curr.y * grid_size_.x + curr.x)].cost;
		for (const auto d : dirs) {
			const Vec2i next = curr + d;
			if (next.x < 0 || next.y < 0 || next.x >= grid_size_.x || next.y >= grid_size_.y) {
				continue;
			}
			const int idx = next.y * grid_size_.x + next.x;
			if (grid[static_cast<size_t>(idx)].solid) {
				continue;
			}
			if (curr_cost + 1 < grid[static_cast<size_t>(idx)].cost) {
				grid[static_cast<size_t>(idx)].cost = curr_cost + 1;
				grid[static_cast<size_t>(idx)].dir = Vec2i(-d.x, -d.y);
				queue.push_back(next);
			}
		}
	}
}

Vec2 SimWorld::map_to_local(int front, Vec2i cell) const {
	const float tile_w = 64.0f;
	const float tile_h = 32.0f;
	float px = (cell.x - cell.y) * (tile_w * 0.5f);
	float py = (cell.x + cell.y) * (tile_h * 0.5f);
	if (front == 1) {
		px += 300.0f;
		py += 600.0f;
	} else {
		px += 300.0f;
		py += 200.0f;
	}
	return {px, py};
}

Vec2i SimWorld::local_to_map(int front, Vec2 pos) const {
	const float tile_w = 64.0f;
	const float tile_h = 32.0f;
	float px = pos.x;
	float py = pos.y;
	if (front == 1) {
		px -= 300.0f;
		py -= 600.0f;
	} else {
		px -= 300.0f;
		py -= 200.0f;
	}
	const float dx = px / (tile_w * 0.5f);
	const float dy = py / (tile_h * 0.5f);
	return {static_cast<int>(std::round((dy + dx) * 0.5f)), static_cast<int>(std::round((dy - dx) * 0.5f))};
}

std::vector<uint8_t> SimWorld::save_state() const {
	using namespace MobileFortress::Schema;
	flatbuffers::FlatBufferBuilder builder(2048);
	std::vector<flatbuffers::Offset<MobileFortress::Schema::Defender>> fbs_defenders;
	fbs_defenders.reserve(defenders_.size());
	for (const auto &d : defenders_) {
		auto type_str = builder.CreateString(d.type);
		MobileFortress::Schema::Vec2 pos(d.position.x, d.position.y);
		MobileFortress::Schema::Vec2 tfrom(d.travel_from.x, d.travel_from.y);
		MobileFortress::Schema::Vec2 tto(d.travel_to.x, d.travel_to.y);
		fbs_defenders.push_back(CreateDefender(
				builder, d.id, d.front, type_str, &pos, d.alive, d.hp, d.damage, d.range_px, d.cooldown,
				d.cooldown_left, d.ability_cooldown, d.ability_cooldown_left, d.traveling, &tfrom, &tto,
				d.travel_t, d.travel_duration, d.aura_radius, d.aura_bonus, d.own_env_mult, d.cross_env_mult));
	}
	std::vector<flatbuffers::Offset<MobileFortress::Schema::Raider>> fbs_raiders;
	fbs_raiders.reserve(raiders_.size());
	for (const auto &r : raiders_) {
		std::vector<MobileFortress::Schema::Vec2> rpath;
		rpath.reserve(r.path.size());
		for (const auto &p : r.path) {
			rpath.emplace_back(p.x, p.y);
		}
		auto path_vec = builder.CreateVectorOfStructs(rpath);
		MobileFortress::Schema::Vec2 pos(r.position.x, r.position.y);
		fbs_raiders.push_back(CreateRaider(
				builder, r.id, r.front, path_vec, r.hp, r.max_hp, r.speed, r.damage, r.path_i,
				r.outpost_path_i, r.struck_outpost, r.alive, &pos));
	}
	std::vector<flatbuffers::Offset<MobileFortress::Schema::Wave>> fbs_waves;
	fbs_waves.reserve(waves_.size());
	for (const auto &w : waves_) {
		fbs_waves.push_back(CreateWave(builder, w.delay, w.land_count, w.sea_count, w.fired));
	}
	std::vector<MobileFortress::Schema::Vec2> land_pts;
	land_pts.reserve(land_path_.size());
	for (const auto &p : land_path_) {
		land_pts.emplace_back(p.x, p.y);
	}
	std::vector<MobileFortress::Schema::Vec2> sea_pts;
	sea_pts.reserve(sea_path_.size());
	for (const auto &p : sea_path_) {
		sea_pts.emplace_back(p.x, p.y);
	}
	auto state = CreateSimulationState(
			builder, land_resources_, sea_resources_, hq_hp_, hq_max_hp_, land_outpost_hp_, sea_outpost_hp_,
			land_outpost_max_, sea_outpost_max_, land_outpost_alive_, sea_outpost_alive_, enemies_killed_,
			units_placed_, in_combat_, combat_time_, current_wave_, build_phase_seconds_, victory_time_,
			income_acc_, next_raider_id_, next_defender_id_, builder.CreateVector(fbs_defenders),
			builder.CreateVector(fbs_raiders), builder.CreateVector(fbs_waves),
			builder.CreateVectorOfStructs(land_pts), builder.CreateVectorOfStructs(sea_pts), 1);
	builder.Finish(state);
	std::vector<uint8_t> out(builder.GetSize());
	std::memcpy(out.data(), builder.GetBufferPointer(), builder.GetSize());
	return out;
}

bool SimWorld::load_state(const uint8_t *data, size_t size) {
	using namespace MobileFortress::Schema;
	if (data == nullptr || size == 0) {
		return false;
	}
	flatbuffers::Verifier verifier(data, size);
	if (!VerifySimulationStateBuffer(verifier)) {
		return false;
	}
	const SimulationState *state = GetSimulationState(data);
	if (state == nullptr) {
		return false;
	}
	land_resources_ = state->land_resources();
	sea_resources_ = state->sea_resources();
	hq_hp_ = state->hq_hp();
	hq_max_hp_ = state->hq_max_hp();
	land_outpost_hp_ = state->land_outpost_hp();
	sea_outpost_hp_ = state->sea_outpost_hp();
	if (state->land_outpost_max() > 0) {
		land_outpost_max_ = state->land_outpost_max();
	}
	if (state->sea_outpost_max() > 0) {
		sea_outpost_max_ = state->sea_outpost_max();
	}
	land_outpost_alive_ = state->land_outpost_alive();
	sea_outpost_alive_ = state->sea_outpost_alive();
	enemies_killed_ = state->enemies_killed();
	units_placed_ = state->units_placed();
	in_combat_ = state->in_combat();
	combat_time_ = state->combat_time();
	current_wave_ = state->current_wave();
	if (state->build_phase_seconds() > 0.0f) {
		build_phase_seconds_ = state->build_phase_seconds();
	}
	if (state->victory_time() > 0.0f) {
		victory_time_ = state->victory_time();
	}
	income_acc_ = state->income_acc();
	next_raider_id_ = state->next_raider_id() > 0 ? state->next_raider_id() : 1;
	next_defender_id_ = state->next_defender_id() > 0 ? state->next_defender_id() : 10001;
	defenders_.clear();
	if (state->defenders()) {
		for (const auto *d : *state->defenders()) {
			if (d == nullptr) {
				continue;
			}
			Defender cd;
			cd.id = d->id();
			cd.front = d->front();
			cd.type = d->type() ? d->type()->str() : std::string();
			if (d->position()) {
				cd.position = Vec2(d->position()->x(), d->position()->y());
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
				cd.travel_from = Vec2(d->travel_from()->x(), d->travel_from()->y());
			}
			if (d->travel_to()) {
				cd.travel_to = Vec2(d->travel_to()->x(), d->travel_to()->y());
			}
			cd.travel_t = d->travel_t();
			cd.travel_duration = d->travel_duration() > 0.0f ? d->travel_duration() : 1.6f;
			cd.aura_radius = d->aura_radius();
			cd.aura_bonus = d->aura_bonus();
			cd.own_env_mult = d->own_env_mult();
			cd.cross_env_mult = d->cross_env_mult();
			defenders_.push_back(cd);
		}
	}
	raiders_.clear();
	if (state->raiders()) {
		for (const auto *r : *state->raiders()) {
			if (r == nullptr) {
				continue;
			}
			Raider cr;
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
				cr.position = Vec2(r->position()->x(), r->position()->y());
			}
			if (r->path()) {
				for (const auto *p : *r->path()) {
					if (p) {
						cr.path.push_back(Vec2(p->x(), p->y()));
					}
				}
			}
			raiders_.push_back(cr);
		}
	}
	waves_.clear();
	if (state->waves()) {
		for (const auto *w : *state->waves()) {
			if (w == nullptr) {
				continue;
			}
			waves_.push_back(Wave{w->delay(), w->land_count(), w->sea_count(), w->fired()});
		}
	}
	land_path_.clear();
	if (state->land_path()) {
		for (const auto *p : *state->land_path()) {
			if (p) {
				land_path_.push_back(Vec2(p->x(), p->y()));
			}
		}
	}
	sea_path_.clear();
	if (state->sea_path()) {
		for (const auto *p : *state->sea_path()) {
			if (p) {
				sea_path_.push_back(Vec2(p->x(), p->y()));
			}
		}
	}
	return true;
}

} // namespace mf
