#ifndef MF_SIMULATION_CORE_H
#define MF_SIMULATION_CORE_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <entt/entt.hpp>
#include <vector>

namespace godot {

/// Headless dual-front sim slice for Slice-0 / G2.
/// Godot owns presentation; this node owns resources, HQ, outposts, and raider motion.
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

	struct RaiderData {
		int id = 0;
		int front = 0; // 0 land, 1 sea
		float hp = 55.0f;
		float max_hp = 55.0f;
		float speed = 25.0f;
		float damage = 6.0f;
		int path_i = 0;
		int outpost_path_i = -1; // path index that threatens the outpost
		bool struck_outpost = false;
		Vector2 position;
		PackedVector2Array path;
		bool alive = true;
	};

	std::vector<RaiderData> raiders;

	void damage_outpost(int front, int amount, Array &events);

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

	bool spend(int front, int amount);
	void gain(int front, int amount);
	void damage_hq(int amount);
	void set_outpost_alive(int front, bool alive);
	void note_unit_placed();

	/// Returns raider id, or -1 on failure.
	/// outpost_path_i: path index where this raider deals one outpost strike (-1 = mid path).
	int spawn_raider(int front, PackedVector2Array path, float hp, float speed, float damage, int outpost_path_i = -1);
	void damage_raider(int id, float amount);
	/// Advances raiders along paths. Returns events (income, outpost_*, hq_*).
	Array tick(double delta, bool income_enabled = true);
	Array get_raiders() const;
	int get_raider_count() const;

	void spawn_entity(const String &type, Vector2 position);
	void _process(double delta) override;
};

} // namespace godot

#endif // MF_SIMULATION_CORE_H
