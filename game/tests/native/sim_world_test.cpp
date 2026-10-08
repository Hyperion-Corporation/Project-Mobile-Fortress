#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>

#include "sim_world.h"
#include <utility>

using mf::SimWorld;
using mf::Vec2;
using mf::Vec2i;

TEST_CASE("reset_run sets resource and HQ invariants") {
	SimWorld world;
	world.reset_run(10, 20, 88);
	CHECK(world.land_resources() == 10);
	CHECK(world.sea_resources() == 20);
	CHECK(world.hq_hp() == 88);
	CHECK(world.hq_max_hp() == 88);
	CHECK(world.hq_alive());
	CHECK(world.raider_count() == 0);
	CHECK(world.defender_count() == 0);
	CHECK(world.land_outpost_alive());
	CHECK(world.sea_outpost_alive());
	CHECK_FALSE(world.in_combat());
}

TEST_CASE("spend rejects overspend and negative amounts") {
	SimWorld world;
	world.reset_run(6, 4, 100);
	CHECK(world.spend(0, 4));
	CHECK(world.land_resources() == 2);
	CHECK_FALSE(world.spend(0, 3));
	CHECK(world.land_resources() == 2);
	CHECK_FALSE(world.spend(1, 5));
	CHECK(world.sea_resources() == 4);
	CHECK_FALSE(world.spend(0, -1));
	CHECK_FALSE(world.spend(2, 1));
}

TEST_CASE("raider spawn and damage_raider death accounting") {
	SimWorld world;
	world.reset_run(10, 10, 100);
	const int id = world.spawn_raider(0, {Vec2(0, 0), Vec2(10, 0)}, 12.0f, 20.0f, 7.0f);
	REQUIRE(id > 0);
	CHECK(world.raider_count() == 1);
	world.damage_raider(id, 5.0f);
	CHECK(world.raider_count() == 1);
	CHECK(world.enemies_killed() == 0);
	world.damage_raider(id, 7.0f);
	CHECK(world.raider_count() == 0);
	CHECK(world.enemies_killed() == 1);
}

TEST_CASE("save_state / load_state round-trip HQ and defender count") {
	SimWorld world;
	world.reset_run(33, 44, 88);
	const int did = world.spawn_defender(1, "arquebusier", Vec2(12, 24), 80.0f, 10.0f, 0.8f);
	REQUIRE(did > 0);
	world.spawn_raider(1, {Vec2(50, 0), Vec2(100, 0)}, 18.0f, 5.0f, 1.0f, 99);
	const auto blob = world.save_state();
	REQUIRE_FALSE(blob.empty());

	SimWorld restored;
	restored.reset_run(1, 2, 3);
	REQUIRE(restored.load_state(blob.data(), blob.size()));
	CHECK(restored.land_resources() == 33);
	CHECK(restored.sea_resources() == 44);
	CHECK(restored.hq_hp() == 88);
	CHECK(restored.defender_count() == 1);
	CHECK(restored.raider_count() == 1);
}

TEST_CASE("wave spawn uses empty path when flow is live even if lanes exist") {
	SimWorld world;
	world.reset_run(40, 40, 100);
	world.init_grids(8, 5);
	world.set_lane_path(0, {Vec2(0, 0), Vec2(40, 0), Vec2(80, 0)});
	world.set_lane_path(1, {Vec2(0, 0), Vec2(40, 0), Vec2(80, 0)});
	world.add_wave(0.0f, 1, 1);
	REQUIRE(world.flow_active());
	world.start_combat();
	world.tick(0.05, false);
	REQUIRE(world.current_wave() >= 1);
	REQUIRE(world.raider_count() >= 1);
	for (const auto &r : world.raiders()) {
		CHECK(r.path.empty());
	}
}

TEST_CASE("lane waves stay on waypoints when flow is inactive") {
	SimWorld world;
	world.reset_run(40, 40, 100);
	world.set_lane_path(0, {Vec2(0, 0), Vec2(40, 0), Vec2(80, 0)});
	world.add_wave(0.0f, 1, 0);
	CHECK_FALSE(world.flow_active());
	world.start_combat();
	world.tick(0.05, false);
	REQUIRE(world.raider_count() == 1);
	CHECK(world.raiders().front().path.size() == 3);
}

TEST_CASE("S7 fixed-dt replay is stable for HQ and raider count") {
	auto play = []() {
		SimWorld world;
		world.reset_run(10, 10, 100);
		world.init_grids(8, 5);
		world.spawn_raider(0, {}, 40.0f, 30.0f, 6.0f);
		for (int i = 0; i < 180; ++i) {
			world.tick(1.0 / 30.0, false);
		}
		return std::pair<int, int>{world.hq_hp(), world.raider_count()};
	};
	const auto a = play();
	const auto b = play();
	CHECK(a.first == b.first);
	CHECK(a.second == b.second);
	// Flow raider should have reached HQ (or still be en-route) deterministically.
	CHECK(a.first <= 100);
}

TEST_CASE("G3 wave spawn staggers flow entry rows") {
	SimWorld world;
	world.reset_run(40, 40, 100);
	world.init_grids(8, 5);
	world.add_wave(0.0f, 5, 0);
	world.start_combat();
	world.tick(0.05, false);
	REQUIRE(world.raider_count() == 5);
	int distinct = 0;
	bool seen[5] = {};
	for (const auto &r : world.raiders()) {
		REQUIRE(r.entry_row >= 0);
		REQUIRE(r.entry_row < 5);
		if (!seen[r.entry_row]) {
			seen[r.entry_row] = true;
			distinct += 1;
		}
	}
	CHECK(distinct >= 2);
}

TEST_CASE("G3 flow never steps into a solid cell and still reaches HQ") {
	SimWorld world;
	world.reset_run(10, 10, 100);
	world.init_grids(8, 5);
	for (int y = 1; y < 5; ++y) {
		world.set_cell_solid(0, mf::Vec2i(3, y), true);
	}
	for (int y = 0; y < 5; ++y) {
		for (int x = 0; x < 7; ++x) {
			const mf::Vec2i cell(x, y);
			if (world.is_cell_solid(0, cell)) {
				continue;
			}
			const mf::Vec2i step = world.flow_dir_at(0, cell);
			const mf::Vec2i dest(cell.x + step.x, cell.y + step.y);
			CHECK_FALSE(world.is_cell_solid(0, dest));
		}
	}
	const int id = world.spawn_raider(0, {}, 40.0f, 80.0f, 6.0f, -1, 4);
	REQUIRE(id > 0);
	bool hq_hit = false;
	for (int i = 0; i < 400; ++i) {
		const auto events = world.tick(0.05, false);
		for (const auto &r : world.raiders()) {
			const mf::Vec2i cell = world.map_cell(0, r.position);
			if (cell.x >= 0 && cell.y >= 0) {
				CHECK_FALSE(world.is_cell_solid(0, cell));
			}
		}
		for (const auto &e : events) {
			if (e.type == "hq_hit") {
				hq_hit = true;
			}
		}
		if (hq_hit) {
			break;
		}
	}
	CHECK(hq_hit);
}

TEST_CASE("G7 outpost income scales with remaining HP") {
	CHECK(SimWorld::outpost_income(40, 40, true) == 2);
	CHECK(SimWorld::outpost_income(20, 40, true) == 1);
	CHECK(SimWorld::outpost_income(1, 40, true) == 1);
	CHECK(SimWorld::outpost_income(0, 40, false) == 0);
	CHECK(SimWorld::outpost_income(40, 40, false) == 0);

	SimWorld world;
	world.reset_run(10, 10, 100);
	world.add_wave(99.0f, 0, 0);
	world.start_combat();
	world.tick(4.0, true);
	CHECK(world.land_resources() == 12);
	CHECK(world.sea_resources() == 12);

	world.set_outpost_alive(0, false);
	world.tick(4.0, true);
	CHECK(world.land_resources() == 12);
	CHECK(world.sea_resources() == 14);
}

TEST_CASE("G4 Capitão Dias salvo hits the opposite front only") {
	SimWorld world;
	world.reset_run(40, 40, 100);
	const int dias = world.spawn_defender(0, "hero_dias", Vec2(0, 0), 80.0f, 10.0f, 1.0f, 1.0f, 0.65f, 80.0f, 0.2f);
	REQUIRE(dias > 0);
	CHECK(world.spawn_defender(0, "hero_dias", Vec2(10, 0), 80.0f, 10.0f, 1.0f) == -1);

	const int same = world.spawn_raider(0, {Vec2(20, 0), Vec2(40, 0)}, 40.0f, 0.0f, 1.0f, 99);
	const int opp = world.spawn_raider(1, {Vec2(20, 400), Vec2(40, 400)}, 40.0f, 0.0f, 1.0f, 99);
	REQUIRE(same > 0);
	REQUIRE(opp > 0);

	const auto salvo = world.cast_hero_ability(dias);
	CHECK(salvo.success);
	CHECK(salvo.type == "salvo");
	CHECK(salvo.hits == 1);
	CHECK(world.raider_count() == 2);
	for (const auto &r : world.raiders()) {
		if (r.front == 1) {
			CHECK(r.hp == doctest::Approx(18.0f));
		} else {
			CHECK(r.hp == doctest::Approx(40.0f));
		}
	}
	const auto again = world.cast_hero_ability(dias);
	CHECK_FALSE(again.success);
	CHECK(again.reason == "on_cooldown");
}

TEST_CASE("DT1 economy debug APIs") {
	SimWorld world;
	world.reset_run(5, 5, 100);
	world.debug_set_resources(-1, 80);
	CHECK(world.land_resources() == 80);
	CHECK(world.sea_resources() == 80);
	world.debug_set_infinite_resources(0, true);
	CHECK(world.spend(0, 1000));
	CHECK(world.land_resources() == 80);
	CHECK_FALSE(world.spend(1, 1000));
	world.debug_apply_income();
	CHECK(world.land_resources() == 82);
	CHECK(world.sea_resources() == 82);
	world.reset_run(5, 5, 100);
	CHECK_FALSE(world.debug_infinite_resources(0));
}

TEST_CASE("DT2 combat debug APIs") {
	SimWorld world;
	world.reset_run(10, 10, 50);
	world.debug_set_invincible(true);
	world.damage_hq(40);
	CHECK(world.hq_hp() == 50);
	world.add_wave(0.0f, 2, 0);
	world.debug_set_waves_disabled(true);
	world.start_combat();
	world.tick(0.1, false);
	CHECK(world.raider_count() == 0);
	world.debug_set_waves_disabled(false);
	world.tick(0.1, false);
	CHECK(world.raider_count() >= 1);
	CHECK(world.debug_kill_all_raiders() >= 1);
	CHECK(world.raider_count() == 0);
}

TEST_CASE("DT3 jump wave skips earlier waves") {
	SimWorld world;
	world.reset_run(10, 10, 100);
	world.add_wave(0.0f, 1, 0);
	world.add_wave(10.0f, 3, 0);
	world.add_wave(20.0f, 1, 0);
	CHECK_FALSE(world.debug_jump_wave(-1));
	CHECK_FALSE(world.debug_jump_wave(3));
	CHECK(world.debug_jump_wave(1));
	CHECK(world.in_combat());
	CHECK(world.current_wave() == 1);
	world.tick(0.05, false);
	CHECK(world.current_wave() == 2);
	CHECK(world.raider_count() == 3);
}

TEST_CASE("DT3 spawn raider at cell") {
	SimWorld world;
	world.reset_run(10, 10, 100);
	world.init_grids(8, 5);
	const int id = world.debug_spawn_raider_at(0, Vec2i(2, 1), 40.0f, 20.0f, 6.0f);
	CHECK(id > 0);
	REQUIRE_FALSE(world.raiders().empty());
	CHECK(world.map_cell(0, world.raiders()[0].position) == Vec2i(2, 1));
}

namespace {

struct RunSnap {
	int hq = 0;
	int land = 0;
	int sea = 0;
	int killed = 0;
	int wave = 0;
	int raiders = 0;
	float intensity = 0.0f;
	std::vector<int> ids;
	std::vector<float> hp;
	std::vector<float> speed;
	std::vector<float> x;
};

bool near(float a, float b) {
	return std::fabs(a - b) < 0.001f;
}

RunSnap snap_of(const SimWorld &world) {
	RunSnap snap;
	snap.hq = world.hq_hp();
	snap.land = world.land_resources();
	snap.sea = world.sea_resources();
	snap.killed = world.enemies_killed();
	snap.wave = world.current_wave();
	snap.raiders = world.raider_count();
	snap.intensity = world.dda_intensity();
	for (const auto &r : world.raiders()) {
		snap.ids.push_back(r.id);
		snap.hp.push_back(r.hp);
		snap.speed.push_back(r.speed);
		snap.x.push_back(r.position.x);
	}
	return snap;
}

void check_same_run(const RunSnap &a, const RunSnap &b) {
	CHECK(a.hq == b.hq);
	CHECK(a.land == b.land);
	CHECK(a.sea == b.sea);
	CHECK(a.killed == b.killed);
	CHECK(a.wave == b.wave);
	CHECK(a.raiders == b.raiders);
	CHECK(a.intensity == doctest::Approx(b.intensity));
	CHECK(a.ids == b.ids);
	REQUIRE(a.hp.size() == b.hp.size());
	for (size_t i = 0; i < a.hp.size(); ++i) {
		CHECK(a.hp[i] == b.hp[i]);
		CHECK(a.speed[i] == b.speed[i]);
		CHECK(a.x[i] == b.x[i]);
	}
}

const std::vector<Vec2> kLongLane{Vec2(0.0f, 0.0f), Vec2(800.0f, 0.0f)};

} // namespace

TEST_CASE("A4 DDA disabled matches an untouched baseline") {
	auto play = [](bool explicit_off) {
		SimWorld world;
		world.reset_run(14, 14, 100);
		if (explicit_off) {
			world.set_dda_enabled(false);
		}
		CHECK_FALSE(world.dda_enabled());
		world.damage_hq(40);
		world.set_outpost_alive(1, false);
		CHECK(world.dda_intensity() == doctest::Approx(1.0f));
		world.set_lane_path(0, kLongLane);
		world.set_lane_path(1, kLongLane);
		world.add_wave(0.0f, 3, 2);
		world.add_wave(1.0f, 4, 1);
		world.spawn_defender(0, "spearman", Vec2(120.0f, 0.0f), 90.0f, 12.0f, 0.35f);
		world.start_combat();
		for (int i = 0; i < 90; ++i) {
			world.tick(1.0 / 30.0, true);
		}
		auto snap = snap_of(world);
		CHECK(snap.intensity == doctest::Approx(1.0f));
		return snap;
	};
	check_same_run(play(false), play(true));

	SimWorld authored;
	authored.reset_run(14, 14, 100);
	authored.set_lane_path(0, kLongLane);
	authored.set_lane_path(1, kLongLane);
	authored.add_wave(0.0f, 3, 2);
	authored.start_combat();
	authored.tick(0.05, false);
	CHECK(authored.raider_count() == 5);
	for (const auto &r : authored.raiders()) {
		CHECK(r.hp == doctest::Approx(50.0f));
		CHECK(r.max_hp == doctest::Approx(50.0f));
		CHECK(r.speed == doctest::Approx(26.0f));
	}
}

TEST_CASE("A4 intensity drops when the player is losing and eases only later waves") {
	SimWorld world;
	world.reset_run(14, 14, 100);
	world.set_dda_enabled(true);
	CHECK(world.dda_enabled());
	CHECK(world.dda_intensity() == doctest::Approx(1.0f));
	world.set_lane_path(0, kLongLane);
	world.set_lane_path(1, kLongLane);
	world.add_wave(0.0f, 4, 0);
	world.add_wave(1.0f, 4, 4);
	world.start_combat();
	world.tick(0.05, false);
	REQUIRE(world.current_wave() == 1);
	REQUIRE(world.raider_count() == 4);
	for (const auto &r : world.raiders()) {
		CHECK(r.hp == doctest::Approx(50.0f));
		CHECK(r.speed == doctest::Approx(26.0f));
	}

	world.damage_hq(100);
	world.set_outpost_alive(0, false);
	world.set_outpost_alive(1, false);
	REQUIRE(world.spend(0, 14));
	REQUIRE(world.spend(1, 14));
	CHECK(world.dda_intensity() == SimWorld::DDA_INTENSITY_MIN);

	world.tick(0.05, false);
	CHECK(world.current_wave() == 1);
	CHECK(world.raider_count() == 4);
	for (const auto &r : world.raiders()) {
		CHECK(r.hp == doctest::Approx(50.0f));
	}
	// Authored delay is not pulled forward when intensity is at the floor.
	world.tick(0.80, false);
	CHECK(world.combat_time() == doctest::Approx(0.90f));
	CHECK(world.current_wave() == 1);
	CHECK(world.raider_count() == 4);

	world.tick(0.20, false);
	CHECK(world.current_wave() == 2);
	int authored_hp = 0;
	int eased = 0;
	for (const auto &r : world.raiders()) {
		if (near(r.hp, 50.0f)) {
			authored_hp += 1;
			CHECK(r.speed == doctest::Approx(26.0f));
		} else {
			eased += 1;
			CHECK(r.hp == doctest::Approx(53.0f * SimWorld::DDA_INTENSITY_MIN));
			CHECK(r.max_hp == doctest::Approx(53.0f * SimWorld::DDA_INTENSITY_MIN));
			CHECK(r.speed == doctest::Approx(28.0f));
		}
	}
	CHECK(authored_hp == 4);
	CHECK(eased == 6);

	const int manual = world.spawn_raider(0, kLongLane, 12.0f, 10.0f, 1.0f);
	REQUIRE(manual > 0);
	for (const auto &r : world.raiders()) {
		if (r.id == manual) {
			CHECK(r.hp == doctest::Approx(12.0f));
		}
	}
}

TEST_CASE("A4 intensity rises when the player is dominating and clamps") {
	SimWorld world;
	world.reset_run(14, 14, 100);
	world.set_dda_enabled(true);
	world.gain(0, 100);
	world.gain(1, 100);
	const float stockpiled = world.dda_intensity();
	CHECK(stockpiled > 1.0f);
	CHECK(stockpiled < SimWorld::DDA_INTENSITY_MAX);

	world.set_lane_path(0, kLongLane);
	world.set_lane_path(1, kLongLane);
	world.add_wave(0.0f, 2, 0);
	world.add_wave(3.0f, 4, 4);
	world.start_combat();
	world.tick(0.05, false);
	REQUIRE(world.raider_count() == 2);
	for (const auto &r : world.raiders()) {
		CHECK(r.hp == doctest::Approx(50.0f * stockpiled));
		CHECK(r.hp > 50.0f);
	}
	CHECK(world.debug_kill_all_raiders() == 2);
	world.tick(0.05, false);
	CHECK(world.raider_count() == 0);
	CHECK(world.dda_intensity() == SimWorld::DDA_INTENSITY_MAX);

	world.tick(3.0, false);
	CHECK(world.current_wave() == 2);
	CHECK(world.raider_count() == 10);
	for (const auto &r : world.raiders()) {
		CHECK(r.hp == doctest::Approx(53.0f * SimWorld::DDA_INTENSITY_MAX));
		CHECK(r.speed == doctest::Approx(28.0f));
	}

	// Preference survives a new raid; the clear sample does not.
	world.reset_run(14, 14, 100);
	CHECK(world.dda_enabled());
	CHECK(world.dda_intensity() == doctest::Approx(1.0f));
}

TEST_CASE("A4 two identical runs stay deterministic and load keeps DDA inputs") {
	auto play = []() {
		SimWorld world;
		world.reset_run(14, 14, 100);
		world.set_dda_enabled(true);
		world.gain(0, 100);
		world.gain(1, 100);
		world.damage_hq(10);
		world.set_lane_path(0, kLongLane);
		world.set_lane_path(1, kLongLane);
		world.add_wave(0.0f, 3, 2);
		world.add_wave(1.5f, 4, 4);
		world.spawn_defender(0, "spearman", Vec2(200.0f, 0.0f), 100.0f, 8.0f, 0.5f);
		world.start_combat();
		world.tick(0.05, false);
		world.debug_kill_all_raiders();
		world.tick(0.05, false);
		for (int i = 0; i < 60; ++i) {
			world.tick(1.0 / 30.0, false);
		}
		return world;
	};
	const SimWorld first = play();
	const SimWorld second = play();
	check_same_run(snap_of(first), snap_of(second));
	CHECK(first.dda_intensity() <= SimWorld::DDA_INTENSITY_MAX);
	CHECK(first.dda_intensity() >= SimWorld::DDA_INTENSITY_MIN);

	const auto blob = first.save_state();
	REQUIRE_FALSE(blob.empty());
	SimWorld restored = first;
	REQUIRE(restored.load_state(blob.data(), blob.size()));
	CHECK(restored.dda_enabled());
	CHECK(restored.hq_hp() == first.hq_hp());
	CHECK(restored.land_resources() == first.land_resources());
	// Schema v2 keeps the clear sample and the purse baseline, so intensity
	// matches the run that was saved. HQ damage still comes from the snapshot.
	CHECK(first.dda_intensity() > 1.0f);
	CHECK(restored.dda_intensity() == doctest::Approx(first.dda_intensity()));

	SimWorld fresh;
	CHECK_FALSE(fresh.dda_enabled());
	REQUIRE(fresh.load_state(blob.data(), blob.size()));
	CHECK(fresh.dda_enabled());
	CHECK(fresh.dda_intensity() == doctest::Approx(first.dda_intensity()));
}

TEST_CASE("A4 combined purse does not overflow valid per-front balances") {
	SimWorld world;
	world.reset_run(1500000000, 1500000000, 100);
	CHECK(world.dda_intensity() == 1.0f);
	world.set_dda_enabled(true);
	CHECK(world.dda_intensity() == doctest::Approx(1.0f));
	REQUIRE(world.spend(0, 250000000));
	REQUIRE(world.spend(1, 250000000));
	CHECK(world.dda_intensity() == doctest::Approx(1.0f - SimWorld::DDA_PURSE_WEIGHT / 6.0f));
	const auto blob = world.save_state();
	REQUIRE(world.load_state(blob.data(), blob.size()));
	CHECK(world.dda_intensity() == doctest::Approx(1.0f - SimWorld::DDA_PURSE_WEIGHT / 6.0f));
}

namespace {

void expect_flow_and_raiders_match(const SimWorld &a, const SimWorld &b) {
	check_same_run(snap_of(a), snap_of(b));
	CHECK(a.dda_enabled() == b.dda_enabled());
	CHECK(a.flow_active() == b.flow_active());
	REQUIRE(a.raiders().size() == b.raiders().size());
	for (size_t i = 0; i < a.raiders().size(); ++i) {
		CHECK(a.raiders()[i].entry_row == b.raiders()[i].entry_row);
		CHECK(a.raiders()[i].position.x == doctest::Approx(b.raiders()[i].position.x));
		CHECK(a.raiders()[i].position.y == doctest::Approx(b.raiders()[i].position.y));
		CHECK(a.raiders()[i].hp == doctest::Approx(b.raiders()[i].hp));
	}
	CHECK(a.defender_count() == b.defender_count());
	if (!a.flow_active()) {
		return;
	}
	for (int front = 0; front < 2; ++front) {
		for (int y = 0; y < 5; ++y) {
			for (int x = 0; x < 8; ++x) {
				const Vec2i cell(x, y);
				CHECK(a.is_cell_solid(front, cell) == b.is_cell_solid(front, cell));
				CHECK(a.flow_dir_at(front, cell) == b.flow_dir_at(front, cell));
			}
		}
	}
}

SimWorld mid_combat_flow_world() {
	SimWorld world;
	world.reset_run(40, 18, 100);
	world.gain(0, 20);
	world.damage_hq(10);
	world.init_grids(8, 5);
	world.set_cell_solid(0, Vec2i(1, 0), true);
	world.set_cell_solid(1, Vec2i(4, 2), true);
	world.set_lane_path(0, kLongLane);
	world.set_lane_path(1, kLongLane);
	world.set_victory_time(300.0f);
	world.set_dda_enabled(true);
	world.add_wave(0.0f, 2, 1);
	world.add_wave(1.2f, 3, 2);
	world.spawn_defender(0, "spearman", Vec2(-500.0f, -500.0f), 10.0f, 4.0f, 0.5f);
	world.start_combat();
	world.tick(0.05, false);
	world.debug_kill_all_raiders();
	world.tick(0.05, false);
	const int id = world.spawn_raider(0, {}, 36.0f, 28.0f, 6.0f, -1, 4);
	REQUIRE(id > 0);
	REQUIRE_FALSE(world.raiders().empty());
	CHECK(world.raiders().back().entry_row == 4);
	CHECK(world.dda_intensity() > 1.0f);
	return world;
}

} // namespace

TEST_CASE("schema v2 save/load then N ticks matches uninterrupted flow combat with DDA on") {
	SimWorld live = mid_combat_flow_world();
	const auto blob = live.save_state();
	REQUIRE_FALSE(blob.empty());

	SimWorld resumed;
	CHECK_FALSE(resumed.flow_active());
	CHECK_FALSE(resumed.dda_enabled());
	REQUIRE(resumed.load_state(blob.data(), blob.size()));
	expect_flow_and_raiders_match(live, resumed);
	CHECK(resumed.is_cell_solid(0, Vec2i(1, 0)));
	CHECK(resumed.is_cell_solid(1, Vec2i(4, 2)));
	CHECK_FALSE(resumed.is_cell_solid(0, Vec2i(0, 0)));
	REQUIRE_FALSE(resumed.raiders().empty());
	CHECK(resumed.raiders().back().entry_row == 4);

	SimWorld cheated = live;
	cheated.debug_set_infinite_resources(0, true);
	cheated.debug_set_infinite_resources(1, true);
	cheated.debug_set_invincible(true);
	cheated.debug_set_waves_disabled(true);
	const auto cheat_blob = cheated.save_state();
	REQUIRE(cheated.load_state(cheat_blob.data(), cheat_blob.size()));
	CHECK_FALSE(cheated.debug_infinite_resources(0));
	CHECK_FALSE(cheated.debug_infinite_resources(1));
	CHECK_FALSE(cheated.debug_invincible());
	CHECK_FALSE(cheated.debug_waves_disabled());
	CHECK(cheated.dda_enabled());
	CHECK(cheated.flow_active());
	CHECK(cheated.is_cell_solid(0, Vec2i(1, 0)));

	constexpr int kTicks = 130;
	constexpr double kDt = 1.0 / 30.0;
	for (int i = 0; i < kTicks; ++i) {
		live.tick(kDt, true);
		resumed.tick(kDt, true);
	}
	expect_flow_and_raiders_match(live, resumed);
	CHECK(live.current_wave() >= 2);
	CHECK(live.raider_count() > 1);
}

#include "fixtures/s4_v1_midcombat.inc"

TEST_CASE("schema v1 snapshot still loads and does not invent flow or DDA") {
	REQUIRE(s4_v1_midcombat_len > 16);
	SimWorld fresh;
	REQUIRE(fresh.load_state(s4_v1_midcombat, s4_v1_midcombat_len));
	CHECK(fresh.land_resources() == 21);
	CHECK(fresh.sea_resources() == 22);
	CHECK(fresh.hq_hp() == 77);
	CHECK(fresh.defender_count() == 1);
	CHECK(fresh.raider_count() == 1);
	REQUIRE_FALSE(fresh.raiders().empty());
	CHECK(fresh.raiders()[0].entry_row == -1);
	CHECK_FALSE(fresh.flow_active());
	CHECK_FALSE(fresh.dda_enabled());
	CHECK(fresh.dda_intensity() == doctest::Approx(1.0f));
	CHECK_FALSE(fresh.debug_infinite_resources(0));
	CHECK_FALSE(fresh.debug_invincible());
	CHECK_FALSE(fresh.debug_waves_disabled());

	SimWorld primed;
	primed.init_grids(8, 5);
	primed.set_cell_solid(0, Vec2i(3, 1), true);
	primed.set_dda_enabled(true);
	primed.gain(0, 50);
	primed.debug_set_infinite_resources(0, true);
	primed.debug_set_invincible(true);
	primed.debug_set_waves_disabled(true);
	REQUIRE(primed.load_state(s4_v1_midcombat, s4_v1_midcombat_len));
	CHECK(primed.flow_active());
	CHECK(primed.is_cell_solid(0, Vec2i(3, 1)));
	CHECK(primed.dda_enabled());
	CHECK(primed.land_resources() == 21);
	REQUIRE_FALSE(primed.raiders().empty());
	CHECK(primed.raiders()[0].entry_row == -1);
	CHECK_FALSE(primed.debug_infinite_resources(0));
	CHECK_FALSE(primed.debug_invincible());
	CHECK_FALSE(primed.debug_waves_disabled());
	// v1 rebases the purse to the loaded wallets and drops the clear sample.
	CHECK(primed.dda_intensity() == doctest::Approx(1.0f));
}

namespace {

/// Test-only generator. SimWorld itself has no RNG.
struct XorShift32 {
	uint32_t state;
	explicit XorShift32(uint32_t seed) : state(seed) {}
	uint32_t next() {
		uint32_t x = state;
		x ^= x << 13;
		x ^= x >> 17;
		x ^= x << 5;
		state = x;
		return x;
	}
};

constexpr int kFlowUnreachable = 9999;

void check_flow_field(const SimWorld &world, int front, int width, int height) {
	const Vec2i goal(width - 1, height / 2);
	CHECK(world.flow_cost_at(front, goal) == 0);
	CHECK(world.flow_dir_at(front, goal) == Vec2i(0, 0));
	for (int y = 0; y < height; ++y) {
		for (int x = 0; x < width; ++x) {
			const Vec2i cell(x, y);
			const int cost = world.flow_cost_at(front, cell);
			const Vec2i dir = world.flow_dir_at(front, cell);
			const bool solid = world.is_cell_solid(front, cell);
			if (dir != Vec2i(0, 0)) {
				const Vec2i next = cell + dir;
				CHECK(next.x >= 0);
				CHECK(next.y >= 0);
				CHECK(next.x < width);
				CHECK(next.y < height);
				CHECK_FALSE(world.is_cell_solid(front, next));
				CHECK(world.flow_cost_at(front, next) < cost);
			}
			if (solid && cell != goal) {
				CHECK(cost == kFlowUnreachable);
				CHECK(dir == Vec2i(0, 0));
			}
			if (!solid && cell != goal && cost < kFlowUnreachable) {
				CHECK(dir != Vec2i(0, 0));
			}
			if (!solid && cost >= kFlowUnreachable) {
				CHECK(dir == Vec2i(0, 0));
			}
		}
	}
}

bool restore_one_cell(SimWorld &world, int front, int width, int height) {
	const Vec2i goal(width - 1, height / 2);
	Vec2i toggle(-1, -1);
	for (int y = 0; y < height && toggle.x < 0; ++y) {
		for (int x = 0; x < width; ++x) {
			const Vec2i cell(x, y);
			if (cell == goal || world.is_cell_solid(front, cell)) {
				continue;
			}
			toggle = cell;
			break;
		}
	}
	if (toggle.x < 0) {
		return false;
	}
	std::vector<int> costs;
	std::vector<Vec2i> dirs;
	std::vector<int> solids;
	costs.reserve(static_cast<size_t>(width * height));
	for (int y = 0; y < height; ++y) {
		for (int x = 0; x < width; ++x) {
			const Vec2i cell(x, y);
			costs.push_back(world.flow_cost_at(front, cell));
			dirs.push_back(world.flow_dir_at(front, cell));
			solids.push_back(world.is_cell_solid(front, cell) ? 1 : 0);
		}
	}
	world.set_cell_solid(front, toggle, true);
	CHECK(world.is_cell_solid(front, toggle));
	CHECK(world.flow_cost_at(front, toggle) == kFlowUnreachable);
	world.set_cell_solid(front, toggle, false);
	size_t i = 0;
	for (int y = 0; y < height; ++y) {
		for (int x = 0; x < width; ++x) {
			const Vec2i cell(x, y);
			CHECK(world.flow_cost_at(front, cell) == costs[i]);
			CHECK(world.flow_dir_at(front, cell) == dirs[i]);
			CHECK((world.is_cell_solid(front, cell) ? 1 : 0) == solids[i]);
			i += 1;
		}
	}
	return true;
}

Vec2i first_cutoff(const SimWorld &world, int front, int width, int height) {
	const Vec2i goal(width - 1, height / 2);
	for (int y = 0; y < height; ++y) {
		for (int x = 0; x < width; ++x) {
			const Vec2i cell(x, y);
			if (cell == goal || world.is_cell_solid(front, cell)) {
				continue;
			}
			if (world.flow_cost_at(front, cell) >= kFlowUnreachable) {
				return cell;
			}
		}
	}
	return Vec2i(-1, -1);
}

void raider_avoids_solids(SimWorld &world, int front, Vec2i start) {
	const int id = world.debug_spawn_raider_at(front, start, 80.0f, 30.0f, 6.0f);
	REQUIRE(id > 0);
	REQUIRE_FALSE(world.raiders().empty());
	CHECK(world.map_cell(front, world.raiders().back().position) == start);
	for (int step = 0; step < 25; ++step) {
		world.tick(1.0 / 30.0, false);
		for (const auto &raider : world.raiders()) {
			if (raider.id != id || !raider.alive) {
				continue;
			}
			const Vec2i cell = world.map_cell(front, raider.position);
			if (cell.x < 0 || cell.y < 0) {
				continue;
			}
			CHECK_FALSE(world.is_cell_solid(front, cell));
		}
	}
}

} // namespace

TEST_CASE("flow field properties on fixed-seed solid layouts") {
	// 6 sizes × 24 layouts × 2 fronts = 288 fields. Seed is part of the contract.
	constexpr uint32_t kSeed = 0x54464C57u;
	constexpr int kPerSize = 24;
	const Vec2i sizes[] = {Vec2i(8, 5), Vec2i(6, 4), Vec2i(5, 5), Vec2i(12, 7), Vec2i(16, 9), Vec2i(7, 3)};
	XorShift32 rng(kSeed);
	int layouts = 0;
	int restored = 0;
	int cutoff_raids = 0;
	INFO("seed 0x54464C57; 6 sizes x 24 layouts x 2 fronts = 288 fields");
	for (const Vec2i size : sizes) {
		for (int n = 0; n < kPerSize; ++n) {
			SimWorld world;
			world.init_grids(size.x, size.y);
			const Vec2i goal(size.x - 1, size.y / 2);
			for (int y = 0; y < size.y; ++y) {
				for (int x = 0; x < size.x; ++x) {
					const Vec2i cell(x, y);
					if (cell == goal) {
						continue;
					}
					if ((rng.next() % 100u) < 35u) {
						world.set_cell_solid(0, cell, true);
						world.set_cell_solid(1, cell, true);
					}
				}
			}
			for (int front = 0; front < 2; ++front) {
				check_flow_field(world, front, size.x, size.y);
				if (restore_one_cell(world, front, size.x, size.y)) {
					restored += 1;
				}
			}
			const Vec2i cutoff = first_cutoff(world, 0, size.x, size.y);
			if (cutoff.x >= 0) {
				raider_avoids_solids(world, 0, cutoff);
				cutoff_raids += 1;
			}
			layouts += 1;
		}
	}
	CHECK(layouts == 6 * kPerSize);
	CHECK(restored > 0);
	CHECK(cutoff_raids > 0);
}

TEST_CASE("a raider boxed in by solids does not step onto one") {
	for (int front = 0; front < 2; ++front) {
		SimWorld world;
		world.init_grids(5, 5);
		const Vec2i goal(4, 2);
		const Vec2i pocket(0, 0);
		for (int y = 0; y < 5; ++y) {
			for (int x = 0; x < 5; ++x) {
				const Vec2i cell(x, y);
				if (cell == goal || cell == pocket) {
					continue;
				}
				world.set_cell_solid(front, cell, true);
			}
		}
		CHECK(world.flow_cost_at(front, pocket) == kFlowUnreachable);
		CHECK(world.flow_dir_at(front, pocket) == Vec2i(0, 0));
		const int id = world.debug_spawn_raider_at(front, pocket, 40.0f, 40.0f, 6.0f);
		REQUIRE(id > 0);
		for (int step = 0; step < 30; ++step) {
			world.tick(1.0 / 30.0, false);
		}
		REQUIRE_FALSE(world.raiders().empty());
		const auto &raider = world.raiders().back();
		CHECK(raider.alive);
		CHECK(world.map_cell(front, raider.position) == pocket);
		CHECK_FALSE(world.is_cell_solid(front, pocket));
	}
}
