class_name BattleRoot
extends Node2D
## Modular dual-front view: presentation + input over SimulationCore (C++).
## Waves, combat victory, and unit combat live in C++; this scene renders and places.

enum Phase { BUILD, COMBAT, RESULT }

const LEVEL_PATH := "res://assets/levels/slice0_dual_front.json"
const SELECT_KEYS := {
	"select_unit_1": "spearman",
	"select_unit_2": "cannon",
	"select_unit_3": "hero_qi",
	"select_unit_4": "cross_support",
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


func _ready() -> void:
	if not _ensure_sim():
		push_error("BattleRoot requires SimulationCore GDExtension")
		return
	GameSession.reset_run()
	_setup_grids()
	sim.set_lane_path(0, land_grid.path_world_points())
	sim.set_lane_path(1, sea_grid.path_world_points())
	if sim.load_level_json(LEVEL_PATH):
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
	if run_over or GameSession.is_paused:
		return
	match phase:
		Phase.BUILD:
			build_time_left -= delta
			_update_hud()
			if build_time_left <= 0.0:
				_start_combat()
		Phase.COMBAT:
			var events: Array = sim.tick(delta, true)
			combat_time = sim.get_combat_time()
			wave_index = sim.get_current_wave()
			_process_events(events)
			_sync_visuals()
			_sync_session_from_sim()
			_update_hud()


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
			if int(d.get("id", -1)) == did and str(d.get("type", "")) == "hero_qi":
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
		if not visual_nodes.has(id):
			var sprite := ColorRect.new()
			sprite.size = Vector2(16, 16)
			sprite.color = UnitDefs.PALETTE["wokou"] if int(r.get("front", 0)) == 0 else UnitDefs.PALETTE["wokou_sail"]
			raiders_root.add_child(sprite)
			visual_nodes[id] = sprite
		visual_nodes[id].global_position = r["position"] - Vector2(8, 8)
	for d in sim.get_defenders():
		var id: int = int(d["id"])
		live_ids[id] = true
		var utype: String = str(d.get("type", "spearman"))
		var udef: Dictionary = UnitDefs.get_def(utype)
		var col: Color = udef.get("color", Color.CORNFLOWER_BLUE) if not udef.is_empty() else Color.CORNFLOWER_BLUE
		if not visual_nodes.has(id):
			var sprite := ColorRect.new()
			var sz := 22.0 if utype != "hero_qi" else 28.0
			sprite.size = Vector2(sz, sz)
			sprite.color = col
			units_root.add_child(sprite)
			visual_nodes[id] = sprite
		var node: ColorRect = visual_nodes[id]
		node.global_position = d["position"] - node.size * 0.5
		node.modulate = Color(0.7, 0.7, 0.7) if bool(d.get("traveling", false)) else Color.WHITE
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
		var sprite := ColorRect.new()
		sprite.size = Vector2(32, 32)
		sprite.color = Color.GOLD if front_id == 0 else Color.LIGHT_CYAN
		units_root.add_child(sprite)
		visual_nodes[id_key] = sprite
	var node: ColorRect = visual_nodes[id_key]
	var cell := Vector2i(4, 2)
	node.global_position = grid.cell_to_global_center(cell) - node.size * 0.5
	var max_hp: float = 40.0
	if front_id == 0 and sim.has_method("get_land_outpost_max"):
		max_hp = float(sim.get_land_outpost_max())
	elif front_id == 1 and sim.has_method("get_sea_outpost_max"):
		max_hp = float(sim.get_sea_outpost_max())
	var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.15, 1.0)
	node.modulate = Color(1.0, ratio, ratio)

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
	for d in sim.get_defenders():
		var type := str(d.get("type", ""))
		if type == "hero_qi" or type == "hero":
			var result: Dictionary = sim.cast_hero_ability(int(d.get("id", -1)))
			if result.get("success", false):
				status_message = "Commander signal flare! (%d hits)" % int(result.get("hits", 0))
				cast_happened = true
			elif result.get("reason", "") == "on_cooldown":
				status_message = "Hero ability CD %.1fs" % float(result.get("cooldown_left", 0.0))
				return
	if not cast_happened and not status_message.begins_with("Hero ability CD"):
		status_message = "No commander on field or no targets in range"
	if cast_happened:
		_sync_visuals()


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
			if utype != "hero_qi" and utype != "hero":
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


func _return_to_menu() -> void:
	GameSession.set_paused(false)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
