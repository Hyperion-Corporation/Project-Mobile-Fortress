#ifndef MF_SIMULATION_CORE_H
#define MF_SIMULATION_CORE_H

#include "sim_world.h"

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <entt/entt.hpp>

namespace godot {

/// GDExtension façade over Godot-free `mf::SimWorld`.
class SimulationCore : public Node {
	GDCLASS(SimulationCore, Node)

private:
	mf::SimWorld world;
	entt::registry registry;

	static Vector2 to_gd(mf::Vec2 v);
	static mf::Vec2 from_gd(Vector2 v);
	static PackedVector2Array to_gd_path(const std::vector<mf::Vec2> &path);
	static std::vector<mf::Vec2> from_gd_path(const PackedVector2Array &path);
	static Dictionary to_gd_hero(const mf::HeroCast &cast);
	static Array to_gd_events(const std::vector<mf::SimEvent> &events);

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

	void init_grids(Vector2i size);
	void set_cell_solid(int front, Vector2i cell, bool solid);
	bool flow_active() const;

	void set_lane_path(int front, PackedVector2Array path);

	int spawn_raider(int front, PackedVector2Array path, float hp, float speed, float damage, int outpost_path_i = -1,
			int entry_row = -1);
	void damage_raider(int id, float amount);

	int spawn_defender(int front, const String &type, Vector2 position, float range_px, float damage, float cooldown,
			float own_env_mult = 1.0f, float cross_env_mult = 0.0f, float aura_radius = 0.0f, float aura_bonus = 0.0f);
	bool upgrade_defender(int id);
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

	void debug_set_resources(int front, int amount);
	void debug_set_infinite_resources(int front, bool enabled);
	bool debug_infinite_resources(int front) const;
	void debug_apply_income();
	void debug_set_invincible(bool enabled);
	bool debug_invincible() const;
	void debug_set_waves_disabled(bool disabled);
	bool debug_waves_disabled() const;
	int debug_kill_all_raiders();
};

} // namespace godot

#endif // MF_SIMULATION_CORE_H
