#ifndef MF_SIM_WORLD_H
#define MF_SIM_WORLD_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <string>
#include <vector>

namespace mf {

struct Vec2 {
	float x = 0.0f;
	float y = 0.0f;
	Vec2() = default;
	Vec2(float px, float py) : x(px), y(py) {}
	Vec2 operator+(const Vec2 &o) const { return {x + o.x, y + o.y}; }
	Vec2 operator-(const Vec2 &o) const { return {x - o.x, y - o.y}; }
	Vec2 operator*(float s) const { return {x * s, y * s}; }
	float length() const { return std::sqrt(x * x + y * y); }
	Vec2 normalized() const {
		const float l = length();
		return l > 0.001f ? Vec2{x / l, y / l} : Vec2{};
	}
	float distance_to(const Vec2 &o) const { return (*this - o).length(); }
	Vec2 lerp(const Vec2 &o, float t) const { return {x + (o.x - x) * t, y + (o.y - y) * t}; }
};

struct Vec2i {
	int x = 0;
	int y = 0;
	Vec2i() = default;
	Vec2i(int px, int py) : x(px), y(py) {}
	bool operator==(const Vec2i &o) const { return x == o.x && y == o.y; }
	Vec2i operator+(const Vec2i &o) const { return {x + o.x, y + o.y}; }
};

struct SimEvent {
	std::string type;
	int id = 0;
	int front = 0;
	float damage = 0.0f;
	int hq_hp = 0;
	int amount = 0;
	int hp = 0;
	int max_hp = 0;
	bool economic_only = false;
	bool alive = true;
	int index = 0;
	int land = 0;
	int sea = 0;
	int land_income = 0;
	int sea_income = 0;
	std::string reason;
};

struct HeroCast {
	bool success = false;
	std::string reason;
	std::string type;
	int hits = 0;
	float cooldown_left = 0.0f;
};

struct Raider {
	int id = 0;
	int front = 0;
	float hp = 55.0f;
	float max_hp = 55.0f;
	float speed = 25.0f;
	float damage = 6.0f;
	int path_i = 0;
	int outpost_path_i = -1;
	bool struck_outpost = false;
	Vec2 position;
	std::vector<Vec2> path;
	int entry_row = -1;
	bool alive = true;
};

struct Defender {
	int id = 0;
	int front = 0;
	std::string type;
	Vec2 position;
	float hp = 100.0f;
	float range_px = 150.0f;
	float damage = 10.0f;
	float cooldown = 1.0f;
	float cooldown_left = 0.0f;
	float ability_cooldown = 8.0f;
	float ability_cooldown_left = 0.0f;
	float own_env_mult = 1.0f;
	float cross_env_mult = 0.0f;
	float aura_radius = 0.0f;
	float aura_bonus = 0.0f;
	bool traveling = false;
	Vec2 travel_from;
	Vec2 travel_to;
	float travel_t = 0.0f;
	float travel_duration = 1.6f;
	bool alive = true;
};

struct Wave {
	float delay = 0.0f;
	int land_count = 0;
	int sea_count = 0;
	bool fired = false;
};

struct FlowCell {
	int cost = 9999;
	Vec2i dir{0, 0};
	bool solid = false;
};

/// Godot-free Slice-0 simulation (Q3/S7). SimulationCore is the GDExtension wrapper.
class SimWorld {
public:
	void reset_run(int start_land = 14, int start_sea = 14, int start_hq = 100);

	int land_resources() const { return land_resources_; }
	int sea_resources() const { return sea_resources_; }
	int hq_hp() const { return hq_hp_; }
	int hq_max_hp() const { return hq_max_hp_; }
	int enemies_killed() const { return enemies_killed_; }
	int units_placed() const { return units_placed_; }
	bool land_outpost_alive() const { return land_outpost_alive_; }
	bool sea_outpost_alive() const { return sea_outpost_alive_; }
	int land_outpost_hp() const { return land_outpost_hp_; }
	int sea_outpost_hp() const { return sea_outpost_hp_; }
	int land_outpost_max() const { return land_outpost_max_; }
	int sea_outpost_max() const { return sea_outpost_max_; }
	bool hq_alive() const { return hq_hp_ > 0; }
	bool in_combat() const { return in_combat_; }
	float combat_time() const { return combat_time_; }
	float build_phase_seconds() const { return build_phase_seconds_; }
	float victory_time() const { return victory_time_; }
	int current_wave() const { return current_wave_; }
	int wave_count() const { return static_cast<int>(waves_.size()); }
	bool flow_active() const;

	bool spend(int front, int amount);
	void gain(int front, int amount);
	/// Combat-tick payout for one outpost: 0 if dead, else 1–2 scaled by remaining HP.
	static int outpost_income(int hp, int max_hp, bool alive);
	static bool is_hero_type(const std::string &type);
	void damage_hq(int amount);
	void set_outpost_alive(int front, bool alive);
	void note_unit_placed() { units_placed_ += 1; }

	void init_grids(int width, int height);
	void set_cell_solid(int front, Vec2i cell, bool solid);
	bool is_cell_solid(int front, Vec2i cell) const;
	Vec2i flow_dir_at(int front, Vec2i cell) const;
	Vec2i map_cell(int front, Vec2 pos) const { return local_to_map(front, pos); }
	void set_lane_path(int front, const std::vector<Vec2> &path);

	int spawn_raider(int front, const std::vector<Vec2> &path, float hp, float speed, float damage, int outpost_path_i = -1,
			int entry_row = -1);
	void damage_raider(int id, float amount);
	int spawn_defender(int front, const std::string &type, Vec2 position, float range_px, float damage, float cooldown,
			float own_env_mult = 1.0f, float cross_env_mult = 0.0f, float aura_radius = 0.0f, float aura_bonus = 0.0f);
	bool upgrade_defender(int id);
	bool start_defender_travel(int id, Vec2 to, int new_front, float duration = 1.6f);
	HeroCast cast_hero_ability(int id);

	void start_combat();
	void clear_waves();
	void add_wave(float delay, int land_count, int sea_count);
	void set_build_phase_seconds(float seconds);
	void set_victory_time(float seconds);
	void spawn_wave_raiders(int front, int count, int wave_index);

	std::vector<SimEvent> tick(double delta, bool income_enabled = true);

	std::vector<uint8_t> save_state() const;
	bool load_state(const uint8_t *data, size_t size);

	const std::vector<Raider> &raiders() const { return raiders_; }
	const std::vector<Defender> &defenders() const { return defenders_; }
	int raider_count() const;
	int defender_count() const;

	void debug_set_resources(int front, int amount);
	void debug_set_infinite_resources(int front, bool enabled);
	bool debug_infinite_resources(int front) const;
	void debug_apply_income();
	void debug_set_invincible(bool enabled);
	bool debug_invincible() const { return invincible_; }
	void debug_set_waves_disabled(bool disabled);
	bool debug_waves_disabled() const { return waves_disabled_; }
	int debug_kill_all_raiders();
	/// Skip to 0-based `wave_index` so the next tick fires only that wave. Starts combat. No RNG.
	bool debug_jump_wave(int wave_index);
	/// Reuses `spawn_raider`, then places the raider on `cell` (flow from there, or lane starting there).
	int debug_spawn_raider_at(int front, Vec2i cell, float hp = 50.0f, float speed = 26.0f, float damage = 6.0f);

private:
	void update_flow_field(int front, Vec2i target);
	Vec2 map_to_local(int front, Vec2i cell) const;
	Vec2i local_to_map(int front, Vec2 pos) const;
	void advance_raider_along_path(Raider &r, double delta, std::vector<SimEvent> &events);
	void advance_raider_along_flow(Raider &r, double delta, std::vector<SimEvent> &events);
	void damage_outpost(int front, int amount, std::vector<SimEvent> &events);
	void run_defender_combat(double delta, std::vector<SimEvent> &events);
	void run_travel(double delta);
	void check_and_spawn_waves(std::vector<SimEvent> &events);
	float total_aura_at(Vec2 pos) const;
	std::vector<Vec2> default_lane_path(int front) const;
	int pick_entry_row(int front, int preferred) const;
	Vec2i pick_flow_step(int front, Vec2i cell) const;

	int land_resources_ = 14;
	int sea_resources_ = 14;
	int hq_hp_ = 100;
	int hq_max_hp_ = 100;
	int enemies_killed_ = 0;
	int units_placed_ = 0;
	int land_outpost_hp_ = 40;
	int sea_outpost_hp_ = 40;
	int land_outpost_max_ = 40;
	int sea_outpost_max_ = 40;
	bool land_outpost_alive_ = true;
	bool sea_outpost_alive_ = true;
	float income_acc_ = 0.0f;
	int next_raider_id_ = 1;
	int next_defender_id_ = 10001;

	std::vector<Raider> raiders_;
	std::vector<Defender> defenders_;
	std::vector<Wave> waves_;
	std::vector<FlowCell> land_flow_;
	std::vector<FlowCell> sea_flow_;
	Vec2i grid_size_;
	std::vector<Vec2> land_path_;
	std::vector<Vec2> sea_path_;

	int current_wave_ = 0;
	float combat_time_ = 0.0f;
	bool in_combat_ = false;
	float build_phase_seconds_ = 40.0f;
	float victory_time_ = 55.0f;
	bool infinite_land_ = false;
	bool infinite_sea_ = false;
	bool invincible_ = false;
	bool waves_disabled_ = false;
};

} // namespace mf

#endif // MF_SIM_WORLD_H
