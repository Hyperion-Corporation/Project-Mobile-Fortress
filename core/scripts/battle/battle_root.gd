class_name BattleRoot
extends Node2D
## Modular dual-front view: presentation + input over SimulationCore (C++).
## Waves, combat victory, and unit combat live in C++; this scene renders and places.

enum Phase { BUILD, COMBAT, RESULT }

const DEFAULT_LEVEL_PATH := "res://assets/levels/slice0_dual_front.json"
const UnitTokenScript := preload("res://scripts/ui/unit_token.gd")
const SELECT_KEYS := {
	"select_unit_1": "spearman",
	"select_unit_2": "cannon",
	"select_unit_3": "hero_qi",
	"select_unit_4": "cross_support",
	"select_unit_5": "hero_dias",
}

@onready var land_host: Node2D = $LandHost
@onready var sea_host: Node2D = $SeaHost
@onready var units_root: Node2D = $Units
@onready var raiders_root: Node2D = $Raiders
@onready var hud: CanvasLayer = $HUD
@onready var sim: Node = $SimulationCore

var land_grid: GridFront
var sea_grid: GridFront
var phase: Phase = Phase.BUILD
var selected_unit_id: String = "spearman"
var build_time_left: float = 40.0
var combat_time: float = 0.0
var wave_index: int = 0
var run_over: bool = false
var status_message: String = ""

var visual_nodes: Dictionary = {} ## id -> Control
var cell_by_defender: Dictionary = {} ## defender_id -> {front, cell}
var pending_hero_id: int = -1
var selected_defender_id: int = -1

var start_land := 40
var start_sea := 40
var start_hq := 100
var victory_time := 55.0
var debug_click_spawn: String = "" ## DT3: if set, next grid click spawns this type for free


func _ready() -> void:
	if not _ensure_sim():
		push_error("BattleRoot requires SimulationCore GDExtension")
		return
	GameSession.reset_run()
	_setup_grids()
	sim.set_lane_path(0, land_grid.path_world_points())
	sim.set_lane_path(1, sea_grid.path_world_points())
	if sim.load_level_json(_level_path()):
		start_land = sim.get_land_resources()
		start_sea = sim.get_sea_resources()
		start_hq = sim.get_hq_max_hp()
		build_time_left = sim.get_build_phase_seconds()
		victory_time = sim.get_victory_time()
	else:
		sim.reset_run(start_land, start_sea, start_hq)
	_sync_session_from_sim()
	_wire_hud()
	_set_phase(Phase.BUILD)
	if hud.has_method("set_selected"):
		hud.set_selected(selected_unit_id)
	status_message = "Modular battle — C++ waves/combat; place both fronts · S/L snapshot"
	_update_hud()
	if GameSession.resume_snapshot_on_next_battle:
		GameSession.resume_snapshot_on_next_battle = false
		if load_snapshot():
			status_message = "Resumed offline FlatBuffers snapshot"
		else:
			status_message = "Resume failed — starting fresh build"


func _level_path() -> String:
	var path := str(GameSession.selected_level_path)
	if path != "" and FileAccess.file_exists(path):
		return path
	return DEFAULT_LEVEL_PATH


func _ensure_sim() -> bool:
	if sim != null and is_instance_valid(sim):
		return true
	if ClassDB.class_exists("SimulationCore"):
		sim = ClassDB.instantiate("SimulationCore")
		sim.name = "SimulationCore"
		add_child(sim)
		return true
	return false


func _setup_grids() -> void:
	land_grid = GridFront.new()
	land_grid.name = "LandGrid"
	land_host.add_child(land_grid)
	# TileMap lives under LandHost/LandMap (sibling of this grid), not BattleRoot.
	land_grid.setup(Vector2.ZERO, "land", 8, 5)
	land_grid.cell_clicked.connect(_on_cell_clicked)

	sea_grid = GridFront.new()
	sea_grid.name = "SeaGrid"
	sea_host.add_child(sea_grid)
	sea_grid.setup(Vector2.ZERO, "sea", 8, 5)
	sea_grid.cell_clicked.connect(_on_cell_clicked)

	# Optional S2 flow field (placement blocks recompute); waves still use lane paths.
	if sim.has_method("init_grids"):
		sim.init_grids(Vector2i(8, 5))
		sim.set_cell_solid(0, Vector2i(4, 2), true) # resource outpost
		sim.set_cell_solid(1, Vector2i(4, 2), true) # trading outpost


func _wire_hud() -> void:
	if hud.has_signal("start_combat_pressed"):
		hud.start_combat_pressed.connect(_start_combat)
	if hud.has_signal("unit_selected"):
		hud.unit_selected.connect(_on_unit_selected)
	if hud.has_signal("restart_pressed"):
		hud.restart_pressed.connect(_restart)
	if hud.has_signal("hero_ability_pressed"):
		hud.hero_ability_pressed.connect(_hero_ability)
	if hud.has_signal("save_pressed"):
		hud.save_pressed.connect(func(): save_snapshot())
	if hud.has_signal("load_pressed"):
		hud.load_pressed.connect(func(): load_snapshot())
	if hud.has_signal("resume_pressed"):
		hud.resume_pressed.connect(func(): GameSession.set_paused(false))
	if hud.has_signal("menu_pressed"):
		hud.menu_pressed.connect(_return_to_menu)


func _process(delta: float) -> void:
	if run_over:
		return
	if GameSession.is_paused:
		if GameSession.consume_step():
			_advance_sim(GameSession.STEP_DT)
		return
	_advance_sim(delta * GameSession.time_scale)


func _advance_sim(dt: float) -> void:
	match phase:
		Phase.BUILD:
			build_time_left -= dt
			_update_hud()
			if build_time_left <= 0.0:
				_start_combat()
		Phase.COMBAT:
			var t0 := Time.get_ticks_usec()
			var events: Array = sim.tick(dt, true)
			var elapsed := Time.get_ticks_usec() - t0
			combat_time = sim.get_combat_time()
			wave_index = sim.get_current_wave()
			_process_events(events)
			_sync_visuals()
			_sync_session_from_sim()
			_note_dev_stats(elapsed)
			_update_hud()


func _note_dev_stats(tick_usec: int) -> void:
	var land_n := 0
	var sea_n := 0
	for raider in sim.get_raiders():
		if int(raider.get("front", 0)) == 0:
			land_n += 1
		else:
			sea_n += 1
	GameSession.note_sim_frame(tick_usec, land_n, sea_n, sim.get_defender_count())


func _process_events(events: Array) -> void:
	for ev in events:
		if not ev is Dictionary:
			continue
		var type: String = str(ev.get("type", ""))
		match type:
			"hq_destroyed":
				_finish(false, "HQ Destroyed!")
			"victory":
				_finish(true, str(ev.get("reason", "Raid weathered — fortress holds")))
			"outpost_lost":
				var front: int = int(ev.get("front", 0))
				GameSession.outposts_lost += 1
				status_message = ("%s outpost lost — income cut (economic only)" %
					("Resource" if front == 0 else "Trading"))
			"raider_killed":
				_free_visual(int(ev.get("id", -1)))
			"hq_hit":
				_free_visual(int(ev.get("id", -1)))
			"wave_spawned":
				status_message = "Wave %d inbound!" % int(ev.get("wave", 0))
			"income":
				pass


func _sync_session_from_sim() -> void:
	GameSession.land_currency = sim.get_land_resources()
	GameSession.sea_currency = sim.get_sea_resources()
	GameSession.hq_hp = sim.get_hq_hp()
	GameSession.hq_max_hp = sim.get_hq_max_hp()
	GameSession.enemies_killed = sim.get_enemies_killed()
	GameSession.units_placed = sim.get_units_placed()
	GameSession.resources_changed.emit(GameSession.land_currency, GameSession.sea_currency)
	GameSession.hq_changed.emit(GameSession.hq_hp, GameSession.hq_max_hp)


func _update_hud() -> void:
	if phase == Phase.BUILD and hud.has_method("set_build_timer"):
		hud.set_build_timer(build_time_left)
	elif phase == Phase.COMBAT and hud.has_method("set_combat_timer"):
		hud.set_combat_timer(combat_time)
	if hud.has_method("set_outposts"):
		hud.set_outposts(
			int(sim.get_land_outpost_hp()),
			int(sim.get_land_outpost_max()),
			bool(sim.is_land_outpost_alive()),
			int(sim.get_sea_outpost_hp()),
			int(sim.get_sea_outpost_max()),
			bool(sim.is_sea_outpost_alive()),
		)
	if hud.has_method("set_wave"):
		hud.set_wave(wave_index)
	if hud.has_method("set_hero_cooldown"):
		var max_cd := 0.0
		var has_hero := false
		for d in sim.get_defenders():
			var utype := str(d.get("type", ""))
			if UnitDefs.is_hero(utype) or utype == "hero":
				has_hero = true
				max_cd = maxf(max_cd, float(d.get("ability_cooldown_left", 0.0)))
		if has_hero:
			hud.set_hero_cooldown(max_cd)
	if hud.has_method("set_status") and status_message != "":
		hud.set_status(status_message)


func _start_combat() -> void:
	if GameSession.is_paused or run_over:
		return
	if phase != Phase.BUILD:
		return
	if sim.get_defender_count() <= 0:
		status_message = "Place at least one unit before combat"
		_update_hud()
		return
	sim.set_lane_path(0, land_grid.path_world_points())
	sim.set_lane_path(1, sea_grid.path_world_points())
	sim.start_combat()
	_set_phase(Phase.COMBAT)
	combat_time = 0.0
	wave_index = 0
	status_message = "COMBAT — C++ waves on both fronts"


func _set_phase(p: Phase) -> void:
	phase = p
	var name_s := "BUILD" if p == Phase.BUILD else ("COMBAT" if p == Phase.COMBAT else "RESULT")
	GameSession.phase_changed.emit(name_s)
	if hud.has_method("set_phase"):
		hud.set_phase(name_s)


func _on_unit_selected(id: String) -> void:
	selected_unit_id = id
	pending_hero_id = -1
	if hud.has_method("set_selected"):
		hud.set_selected(id)


func _on_cell_clicked(front_id: String, cell: Vector2i) -> void:
	if debug_click_spawn != "" and phase != Phase.RESULT and not run_over:
		var front_i := 0 if front_id == "land" else 1
		debug_spawn_at_cell(debug_click_spawn, front_i, cell)
		return
	if run_over or GameSession.is_paused or phase == Phase.RESULT:
		return
	var grid: GridFront = land_grid if front_id == "land" else sea_grid

	if pending_hero_id >= 0 and grid.is_placeable(cell):
		var to: Vector2 = grid.cell_to_global_center(cell)
		var new_front: int = 0 if front_id == "land" else 1
		if sim.start_defender_travel(pending_hero_id, to, new_front, 1.6):
			if cell_by_defender.has(pending_hero_id):
				var old: Dictionary = cell_by_defender[pending_hero_id]
				var og: GridFront = land_grid if str(old.front) == "land" else sea_grid
				og.clear_occupant(old.cell)
				sim.set_cell_solid(0 if str(old.front) == "land" else 1, old.cell, false)
			grid.set_occupant(cell, pending_hero_id)
			sim.set_cell_solid(new_front, cell, true)
			cell_by_defender[pending_hero_id] = {"front": front_id, "cell": cell}
			status_message = "Commander redeploying…"
			pending_hero_id = -1
		return

	if grid.occupants.has(cell):
		var did: int = int(grid.occupants[cell])
		for d in sim.get_defenders():
			if int(d.get("id", -1)) == did and UnitDefs.is_hero(str(d.get("type", ""))):
				selected_defender_id = did
				pending_hero_id = did
				status_message = "Commander selected — click empty cell to redeploy"
				return
		selected_defender_id = did
		status_message = "Unit selected — press U to upgrade"
		return

	if phase != Phase.BUILD and phase != Phase.COMBAT:
		return
	if not grid.is_placeable(cell):
		return

	var def: Dictionary = UnitDefs.get_def(selected_unit_id)
	if def.is_empty():
		return
	var allowed: int = int(def.get("front", UnitDefs.Front.LAND))
	if allowed == UnitDefs.Front.LAND and front_id != "land":
		status_message = "That unit is land-only"
		return
	if allowed == UnitDefs.Front.SEA and front_id != "sea":
		status_message = "That unit is sea-only"
		return

	var currency: String = str(def.get("currency", "land"))
	var cost: int = int(def.get("cost", 10))
	var sim_front: int = 0 if currency == "land" else 1
	if not sim.spend(sim_front, cost):
		var alt: int = 0 if front_id == "land" else 1
		if alt == sim_front or not sim.spend(alt, cost):
			status_message = "Not enough resources"
			return

	var pos: Vector2 = grid.cell_to_global_center(cell)
	var range_px: float = float(def.get("range", 1.5)) * 48.0
	var damage: float = float(def.get("damage", 10))
	var cooldown: float = float(def.get("cooldown", 1.0))
	var own_m: float = float(def.get("own_env_mult", 1.0))
	var cross_m: float = float(def.get("cross_env_mult", 0.0))
	var aura_r: float = float(def.get("aura_radius", 0.0)) * 48.0
	var aura_b: float = float(def.get("aura_damage_bonus", 0.0))
	var front_id_int := 0 if front_id == "land" else 1
	var did2: int = sim.spawn_defender(
		front_id_int, selected_unit_id, pos, range_px, damage, cooldown, own_m, cross_m, aura_r, aura_b
	)
	if did2 < 0:
		sim.gain(sim_front, cost)
		status_message = "Cannot place another %s" % str(def.get("name", selected_unit_id))
		return

	# Stationary units block flow; heroes travel and must not brick a cell.
	if int(def.get("kind", UnitDefs.Kind.DEFENDER)) != UnitDefs.Kind.HERO:
		sim.set_cell_solid(front_id_int, cell, true)

	grid.set_occupant(cell, did2)
	cell_by_defender[did2] = {"front": front_id, "cell": cell}
	_sync_session_from_sim()
	status_message = "%s deployed on %s" % [str(def.get("name", selected_unit_id)), front_id]
	_sync_visuals()


func _sync_visuals() -> void:
	var live_ids: Dictionary = {}
	live_ids["outpost_0"] = true
	live_ids["outpost_1"] = true

	for r in sim.get_raiders():
		var id: int = int(r["id"])
		live_ids[id] = true
		var front_num := int(r.get("front", 0))
		if not visual_nodes.has(id):
			var token: Node2D = UnitTokenScript.new()
			token.setup_raider(front_num)
			raiders_root.add_child(token)
			visual_nodes[id] = token
		visual_nodes[id].global_position = r["position"]

	for d in sim.get_defenders():
		var id: int = int(d["id"])
		live_ids[id] = true
		var utype: String = str(d.get("type", "spearman"))
		var udef: Dictionary = UnitDefs.get_def(utype)
		if not visual_nodes.has(id):
			var token: Node2D = UnitTokenScript.new()
			token.setup_defender(utype, udef)
			units_root.add_child(token)
			visual_nodes[id] = token
		var node: Node2D = visual_nodes[id]
		node.global_position = d["position"]
		if node.has_method("set_traveling"):
			node.set_traveling(bool(d.get("traveling", false)))
		if node.has_method("set_selected"):
			node.set_selected(id == selected_defender_id)

	for id in visual_nodes.keys():
		if not live_ids.has(id):
			_free_visual(id)

	# Sync Outposts
	_sync_outpost(0, sim.get_land_outpost_hp(), sim.is_land_outpost_alive(), land_grid)
	_sync_outpost(1, sim.get_sea_outpost_hp(), sim.is_sea_outpost_alive(), sea_grid)


func _sync_outpost(front_id: int, hp: float, alive: bool, grid: GridFront) -> void:
	var id_key := "outpost_" + str(front_id)
	if not alive:
		_free_visual(id_key)
		return
	if not visual_nodes.has(id_key):
		var token: Node2D = UnitTokenScript.new()
		token.setup_outpost(front_id)
		units_root.add_child(token)
		visual_nodes[id_key] = token
	var node: Node2D = visual_nodes[id_key]
	var cell := Vector2i(4, 2)
	node.global_position = grid.cell_to_global_center(cell)
	var max_hp: float = 40.0
	if front_id == 0 and sim.has_method("get_land_outpost_max"):
		max_hp = float(sim.get_land_outpost_max())
	elif front_id == 1 and sim.has_method("get_sea_outpost_max"):
		max_hp = float(sim.get_sea_outpost_max())
	var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	if node.has_method("set_hp_ratio"):
		node.set_hp_ratio(ratio)


func _free_visual(id: Variant) -> void:
	if visual_nodes.has(id):
		var n: Node = visual_nodes[id]
		if is_instance_valid(n):
			n.queue_free()
		visual_nodes.erase(id)


func _hero_ability() -> void:
	if GameSession.is_paused or phase != Phase.COMBAT or run_over:
		return
	var cast_happened := false
	var cooldown_left := -1.0
	for d in sim.get_defenders():
		var type := str(d.get("type", ""))
		if UnitDefs.is_hero(type) or type == "hero":
			var result: Dictionary = sim.cast_hero_ability(int(d.get("id", -1)))
			if result.get("success", false):
				var kind := str(result.get("type", "pulse"))
				if kind == "salvo":
					status_message = "Dias cross-front salvo! (%d hits)" % int(result.get("hits", 0))
				else:
					status_message = "Commander signal flare! (%d hits)" % int(result.get("hits", 0))
				cast_happened = true
			elif result.get("reason", "") == "on_cooldown":
				cooldown_left = maxf(cooldown_left, float(result.get("cooldown_left", 0.0)))
	if cast_happened:
		_sync_visuals()
	elif cooldown_left >= 0.0:
		status_message = "Hero ability CD %.1fs" % cooldown_left
	else:
		status_message = "No commander on field or no targets in range"


func _upgrade_selected() -> void:
	if GameSession.is_paused or phase != Phase.BUILD or run_over or selected_defender_id < 0:
		return
	var front := 0
	for defender in sim.get_defenders():
		if int(defender.get("id", -1)) == selected_defender_id:
			front = int(defender.get("front", 0))
			break
	var cost := 12
	if not sim.spend(front, cost):
		status_message = "Not enough resources to upgrade"
		return
	if sim.upgrade_defender(selected_defender_id):
		status_message = "Unit upgraded (+25% damage, +range)"
		_sync_session_from_sim()
	else:
		sim.gain(front, cost)
		status_message = "Unit cannot be upgraded while traveling"


func _finish(victory: bool, reason: String) -> void:
	if run_over:
		return
	run_over = true
	_set_phase(Phase.RESULT)
	_sync_session_from_sim()
	# Mid-run snapshot for resume; results JSON + history via GameSession.
	save_snapshot()
	GameSession.end_run(victory, reason, {
		"sim": "cpp",
		"path": "modular",
		"level_id": GameSession.selected_level_id,
		"combat_time": combat_time,
		"wave": wave_index,
		"land_outpost_alive": sim.is_land_outpost_alive(),
		"sea_outpost_alive": sim.is_sea_outpost_alive(),
		"land_outpost_hp": sim.get_land_outpost_hp(),
		"sea_outpost_hp": sim.get_sea_outpost_hp(),
		"results_path": OfflinePersistence.RESULTS_PATH,
		"snapshot_path": OfflinePersistence.SNAPSHOT_PATH,
	})
	if hud.has_method("show_result"):
		hud.show_result(victory, reason, GameSession.last_result)


func _restart() -> void:
	get_tree().reload_current_scene()


func save_snapshot() -> bool:
	if sim == null or not sim.has_method("save_state"):
		status_message = "Snapshot save unavailable"
		return false
	var bytes: PackedByteArray = sim.save_state()
	if not OfflinePersistence.write_snapshot(bytes):
		status_message = "Could not write snapshot"
		return false
	status_message = "Snapshot saved (%d bytes → %s)" % [bytes.size(), OfflinePersistence.SNAPSHOT_PATH]
	_update_hud()
	return true


func load_snapshot() -> bool:
	if sim == null or not sim.has_method("load_state"):
		status_message = "Snapshot load unavailable"
		return false
	var bytes: PackedByteArray = OfflinePersistence.read_snapshot()
	if bytes.is_empty():
		status_message = "No snapshot file"
		return false
	if not sim.load_state(bytes):
		status_message = "Snapshot load failed (verify)"
		return false
	# Rebuild presentation from C++ state
	for id in visual_nodes.keys():
		_free_visual(id)
	_clear_grid_occupants()
	cell_by_defender.clear()
	pending_hero_id = -1
	run_over = false
	if sim.get_in_combat():
		_set_phase(Phase.COMBAT)
		combat_time = sim.get_combat_time()
		wave_index = sim.get_current_wave()
	else:
		_set_phase(Phase.BUILD)
		build_time_left = sim.get_build_phase_seconds()
	_rebuild_placement_from_sim()
	_sync_visuals()
	_sync_session_from_sim()
	status_message = "Snapshot loaded (%d bytes)" % bytes.size()
	_update_hud()
	return true


func _clear_grid_occupants() -> void:
	if land_grid:
		for cell in land_grid.occupants.keys():
			land_grid.clear_occupant(cell)
	if sea_grid:
		for cell in sea_grid.occupants.keys():
			sea_grid.clear_occupant(cell)


func _rebuild_placement_from_sim() -> void:
	## Best-effort: map defender world positions back onto grid cells for placement locks.
	for d in sim.get_defenders():
		var id: int = int(d.get("id", -1))
		if id < 0:
			continue
		var front: int = int(d.get("front", 0))
		var pos: Vector2 = d.get("position", Vector2.ZERO)
		var grid: GridFront = land_grid if front == 0 else sea_grid
		if grid == null:
			continue
		var cell: Vector2i = grid.world_to_cell(pos)
		if not grid.in_bounds(cell):
			continue
		var front_id := "land" if front == 0 else "sea"
		grid.set_occupant(cell, id)
		cell_by_defender[id] = {"front": front_id, "cell": cell}
		if sim.has_method("set_cell_solid") and not bool(d.get("traveling", false)):
			var utype: String = str(d.get("type", ""))
			if not UnitDefs.is_hero(utype) and utype != "hero":
				sim.set_cell_solid(front, cell, true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if not run_over:
			GameSession.toggle_paused()
		return
	if GameSession.is_paused or run_over:
		return
	if event.is_action_pressed("toggle_phase") or event.is_action_pressed("start_combat"):
		_start_combat()
	elif event.is_action_pressed("hero_ability"):
		_hero_ability()
	elif event.is_action_pressed("save_game"):
		save_snapshot()
	elif event.is_action_pressed("load_game"):
		load_snapshot()
	elif event.is_action_pressed("upgrade_unit"):
		_upgrade_selected()
	for action in SELECT_KEYS.keys():
		if event.is_action_pressed(action):
			_on_unit_selected(SELECT_KEYS[action])
			return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_5:
			_on_unit_selected("hero_dias")


func _return_to_menu() -> void:
	GameSession.set_paused(false)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func debug_resolve_front(type_id: String, front: int) -> int:
	if front == 0 or front == 1:
		return front
	var def: Dictionary = UnitDefs.get_def(type_id)
	if type_id == "raider_sea" or int(def.get("front", UnitDefs.Front.LAND)) == UnitDefs.Front.SEA:
		return 1
	return 0


func debug_spawn_at_cell(type_id: String, front: int, cell: Vector2i) -> int:
	if sim == null or run_over or phase == Phase.RESULT:
		return -1
	var def: Dictionary = UnitDefs.get_def(type_id)
	if def.is_empty():
		return -1
	front = debug_resolve_front(type_id, front)
	var grid: GridFront = land_grid if front == 0 else sea_grid
	if grid == null or not grid.in_bounds(cell):
		return -1
	var kind: int = int(def.get("kind", UnitDefs.Kind.DEFENDER))
	if kind == UnitDefs.Kind.RAIDER:
		var hp: float = float(def.get("hp", 50))
		var speed: float = float(def.get("speed", 26))
		var dmg: float = float(def.get("damage", 6))
		var rid := -1
		if sim.has_method("debug_spawn_raider_at"):
			rid = int(sim.debug_spawn_raider_at(front, cell, hp, speed, dmg))
		else:
			rid = int(sim.spawn_raider(front, PackedVector2Array(), hp, speed, dmg, -1, cell.y))
		if rid >= 0:
			status_message = "DT3 spawned %s on %s %s" % [type_id, "land" if front == 0 else "sea", str(cell)]
			_sync_visuals()
		return rid
	if grid.occupants.has(cell):
		status_message = "DT3 cell occupied"
		return -1
	var pos: Vector2 = grid.cell_to_global_center(cell)
	var range_px: float = float(def.get("range", 1.5)) * 48.0
	var damage: float = float(def.get("damage", 10))
	var cooldown: float = float(def.get("cooldown", 1.0))
	var own_m: float = float(def.get("own_env_mult", 1.0))
	var cross_m: float = float(def.get("cross_env_mult", 0.0))
	var aura_r: float = float(def.get("aura_radius", 0.0)) * 48.0
	var aura_b: float = float(def.get("aura_damage_bonus", 0.0))
	var did: int = sim.spawn_defender(
		front, type_id, pos, range_px, damage, cooldown, own_m, cross_m, aura_r, aura_b
	)
	if did < 0:
		status_message = "DT3 could not spawn %s" % type_id
		return -1
	if kind != UnitDefs.Kind.HERO:
		sim.set_cell_solid(front, cell, true)
	grid.set_occupant(cell, did)
	cell_by_defender[did] = {"front": "land" if front == 0 else "sea", "cell": cell}
	status_message = "DT3 spawned %s on %s %s" % [type_id, "land" if front == 0 else "sea", str(cell)]
	_sync_session_from_sim()
	_sync_visuals()
	return did


func debug_jump_wave(wave_number: int) -> bool:
	if sim == null or not sim.has_method("debug_jump_wave") or run_over or phase == Phase.RESULT:
		return false
	if phase == Phase.BUILD:
		if land_grid:
			sim.set_lane_path(0, land_grid.path_world_points())
		if sea_grid:
			sim.set_lane_path(1, sea_grid.path_world_points())
		if not bool(sim.get_in_combat()):
			sim.start_combat()
		_set_phase(Phase.COMBAT)
	var ok: bool = bool(sim.debug_jump_wave(wave_number - 1))
	wave_index = sim.get_current_wave()
	combat_time = sim.get_combat_time()
	status_message = ("DT3 jump to wave %d" % wave_number) if ok else ("DT3 jump failed (wave %d)" % wave_number)
	_update_hud()
	return ok


func debug_load_level(path: String = "") -> bool:
	if sim == null:
		return false
	if path != "":
		GameSession.set_selected_level(path)
	GameSession.reset_run()
	run_over = false
	pending_hero_id = -1
	selected_defender_id = -1
	debug_click_spawn = ""
	for id in visual_nodes.keys():
		_free_visual(id)
	_clear_grid_occupants()
	cell_by_defender.clear()
	if sim.has_method("init_grids"):
		sim.init_grids(Vector2i(8, 5))
		sim.set_cell_solid(0, Vector2i(4, 2), true)
		sim.set_cell_solid(1, Vector2i(4, 2), true)
	if land_grid:
		sim.set_lane_path(0, land_grid.path_world_points())
	if sea_grid:
		sim.set_lane_path(1, sea_grid.path_world_points())
	if not sim.load_level_json(_level_path()):
		status_message = "DT6 load failed"
		_update_hud()
		return false
	start_land = sim.get_land_resources()
	start_sea = sim.get_sea_resources()
	start_hq = sim.get_hq_max_hp()
	build_time_left = sim.get_build_phase_seconds()
	victory_time = sim.get_victory_time()
	combat_time = 0.0
	wave_index = 0
	_set_phase(Phase.BUILD)
	_sync_visuals()
	_sync_session_from_sim()
	status_message = "DT6 loaded %s" % GameSession.selected_level_id
	_update_hud()
	return true


func debug_reload_level() -> void:
	_restart()
