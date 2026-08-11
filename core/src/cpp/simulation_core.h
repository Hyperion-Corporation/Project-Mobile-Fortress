#ifndef MF_SIMULATION_CORE_H
#define MF_SIMULATION_CORE_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <entt/entt.hpp>
#include <vector>

namespace godot {

/// Headless dual-front sim for Slice-0.
/// Presentation (main.gd or battle_root) owns drawing; this owns state + motion + combat + waves.
class SimulationCore : public Node {
	GDCLASS(SimulationCore, Node)

private:
	entt::registry registry;

	int land_resources = 14;
	int sea_resources = 14;
	int hq_hp = 100;
	int hq_max_hp = 100;
	int enemies_killed = 0;
	int units_placed = 0;

	int land_outpost_hp = 40;
	int sea_outpost_hp = 40;
	int land_outpost_max = 40;
	int sea_outpost_max = 40;
	bool land_outpost_alive = true;
	bool sea_outpost_alive = true;

	float income_acc = 0.0f;
	int next_raider_id = 1;
	int next_defender_id = 10001;

	struct RaiderData {
		int id = 0;
		int front = 0;
		float hp = 55.0f;
		float max_hp = 55.0f;
		float speed = 25.0f;
		float damage = 6.0f;
		int path_i = 0;
		int outpost_path_i = -1;
		bool struck_outpost = false;
		Vector2 position;
		PackedVector2Array path;
		bool alive = true;
	};

	struct DefenderData {
		int id = 0;
		int front = 0;
		String type;
		Vector2 position;
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
		Vector2 travel_from;
		Vector2 travel_to;
		float travel_t = 0.0f;
		float travel_duration = 1.6f;
		bool alive = true;
	};

	struct WaveData {
		float delay = 0.0f;
		int land_count = 0;
		int sea_count = 0;
		bool fired = false;
	};

	std::vector<RaiderData> raiders;
	std::vector<DefenderData> defenders;
	std::vector<WaveData> waves;

	PackedVector2Array land_path;
	PackedVector2Array sea_path;

	int current_wave = 0;
	float combat_time = 0.0f;
	bool in_combat = false;
	float build_phase_seconds = 40.0f;
	float victory_time = 55.0f;

	void damage_outpost(int front, int amount, Array &events);
	void run_defender_combat(double delta, Array &events);
	void run_travel(double delta);
	void check_and_spawn_waves(Array &events);
	float total_aura_at(Vector2 pos) const;
	void spawn_wave_raiders(int front, int count, int wave_index);

protected:
	static void _bind_methods();

public:
	SimulationCore();
	~SimulationCore();

	void reset_run(int start_land = 14, int start_sea = 14, int start_hq = 100);

	int get_land_resources() const;
	int get_sea_resources() const;
	int get_hq_hp() const;
	int get_hq_max_hp() const;
	int get_enemies_killed() const;
	int get_units_placed() const;
	bool is_land_outpost_alive() const;
	bool is_sea_outpost_alive() const;
	int get_land_outpost_hp() const;
	int get_sea_outpost_hp() const;
	int get_land_outpost_max() const;
	int get_sea_outpost_max() const;
	bool is_hq_alive() const;
	bool get_in_combat() const;
	float get_combat_time() const;
	float get_build_phase_seconds() const;
	float get_victory_time() const;
	int get_current_wave() const;
	int get_wave_count() const;

	bool spend(int front, int amount);
	void gain(int front, int amount);
	void damage_hq(int amount);
	void set_outpost_alive(int front, bool alive);
	void note_unit_placed();

	/// Register lane paths used when C++ spawns wave raiders.
	void set_lane_path(int front, PackedVector2Array path);

	int spawn_raider(int front, PackedVector2Array path, float hp, float speed, float damage, int outpost_path_i = -1);
	void damage_raider(int id, float amount);

	int spawn_defender(int front, const String &type, Vector2 position, float range_px, float damage, float cooldown,
			float own_env_mult = 1.0f, float cross_env_mult = 0.0f, float aura_radius = 0.0f, float aura_bonus = 0.0f);
	bool start_defender_travel(int id, Vector2 to, int new_front, float duration = 1.6f);
	Dictionary cast_hero_ability(int id);

	Array tick(double delta, bool income_enabled = true);

	bool load_level_json(const String &path);
	void start_combat();

	PackedByteArray save_state() const;
	bool load_state(const PackedByteArray &data);

	Array get_raiders() const;
	Array get_defenders() const;
	int get_raider_count() const;
	int get_defender_count() const;

	void spawn_entity(const String &type, Vector2 position);
	void _process(double delta) override;
};

} // namespace godot

#endif // MF_SIMULATION_CORE_H
