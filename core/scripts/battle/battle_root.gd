class_name BattleRoot
extends Node2D
## Modular dual-front view: presentation + input over SimulationCore (C++).

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
var hero_ability_cd: float = 0.0

var waves: Array = []
var waves_fired: Dictionary = {}
var visual_nodes: Dictionary = {} ## id -> Control
var cell_by_defender: Dictionary = {} ## defender_id -> {front, cell}
var pending_hero_id: int = -1

var start_land := 40
var start_sea := 40
var start_hq := 100
var victory_time := 55.0


func _ready() -> void:
	if not _ensure_sim():
		push_error("BattleRoot requires SimulationCore GDExtension")
		return
	_load_level()
	GameSession.reset_run()
	sim.reset_run(start_land, start_sea, start_hq)
	_sync_session_from_sim()
	_setup_grids()
	_wire_hud()
	_set_phase(Phase.BUILD)
	if hud.has_method("set_selected"):
		hud.set_selected(selected_unit_id)
	status_message = "Modular battle — place on land & sea (C++ sim)"


func _ensure_sim() -> bool:
	if sim != null and is_instance_valid(sim):
		return true
	if ClassDB.class_exists("SimulationCore"):
		sim = ClassDB.instantiate("SimulationCore")
		sim.name = "SimulationCore"
		add_child(sim)
		return true
	return false


func _load_level() -> void:
	if not FileAccess.file_exists(LEVEL_PATH):
		waves = [
			{"at": 2.0, "land": 2, "sea": 2},
			{"at": 12.0, "land": 3, "sea": 3},
			{"at": 24.0, "land": 4, "sea": 4},
			{"at": 38.0, "land": 5, "sea": 5},
		]
		return
	var f := FileAccess.open(LEVEL_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return
	var level: Dictionary = parsed
	start_land = int(level.get("startingLandCurrency", 40))
	start_sea = int(level.get("startingSeaCurrency", 40))
	start_hq = int(level.get("hqMaxHp", 100))
	build_time_left = float(level.get("buildPhaseSeconds", 40))
	waves.clear()
	for w in level.get("waves", []):
		if w is Dictionary:
			waves.append({
				"at": float(w.get("delaySeconds", 0.0)),
				"land": int(w.get("landCount", 2)),
				"sea": int(w.get("seaCount", 2)),
			})
	if waves.is_empty():
		waves = [{"at": 2.0, "land": 3, "sea": 2}]


func _setup_grids() -> void:
	land_grid = GridFront.new()
	land_grid.name = "LandGrid"
	land_host.add_child(land_grid)
	land_grid.setup(Vector2.ZERO, "land", 8, 5)
	land_grid.cell_clicked.connect(_on_cell_clicked)

	sea_grid = GridFront.new()
	sea_grid.name = "SeaGrid"
	sea_host.add_child(sea_grid)
	sea_grid.setup(Vector2.ZERO, "sea", 8, 5)
	sea_grid.cell_clicked.connect(_on_cell_clicked)


func _wire_hud() -> void:
	if hud.has_signal("start_combat_pressed"):
		hud.start_combat_pressed.connect(_start_combat)
	if hud.has_signal("unit_selected"):
		hud.unit_selected.connect(_on_unit_selected)
	if hud.has_signal("restart_pressed"):
		hud.restart_pressed.connect(_restart)
	if hud.has_signal("hero_ability_pressed"):
		hud.hero_ability_pressed.connect(_hero_ability)


func _process(delta: float) -> void:
	if run_over or GameSession.is_paused:
		return
	hero_ability_cd = maxf(0.0, hero_ability_cd - delta)
	match phase:
		Phase.BUILD:
			build_time_left -= delta
			_update_hud()
			if build_time_left <= 0.0:
				_start_combat()
		Phase.COMBAT:
			combat_time += delta
			_process_waves()
			var events: Array = sim.tick(delta, true)
			_process_events(events)
			_sync_visuals()
			_sync_session_from_sim()
			_update_hud()
			if combat_time > victory_time and sim.get_raider_count() == 0 and wave_index >= waves.size():
				_finish(true, "Raid weathered — fortress holds")


func _process_events(events: Array) -> void:
	for ev in events:
		if not ev is Dictionary:
			continue
		var type: String = str(ev.get("type", ""))
		match type:
			"hq_destroyed":
				_finish(false, "HQ Destroyed!")
			"outpost_lost":
				var front: int = int(ev.get("front", 0))
				GameSession.outposts_lost += 1
				status_message = ("%s outpost lost — income cut (economic only)" %
					("Resource" if front == 0 else "Trading"))
			"raider_killed":
				var id: int = int(ev.get("id", -1))
				_free_visual(id)
			"hq_hit":
				var rid: int = int(ev.get("id", -1))
				_free_visual(rid)
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
	if hud.has_node("Root/TopBar/LandRes"):
		var land_hp: int = int(sim.get_land_outpost_hp())
		var land_alive: bool = sim.is_land_outpost_alive()
		hud.get_node("Root/TopBar/LandRes").text = "Land 兩: %d  OP:%s" % [
			sim.get_land_resources(),
			str(land_hp) if land_alive else "LOST",
		]
	if hud.has_node("Root/TopBar/SeaRes"):
		var sea_hp: int = int(sim.get_sea_outpost_hp())
		var sea_alive: bool = sim.is_sea_outpost_alive()
		hud.get_node("Root/TopBar/SeaRes").text = "Sea 兩: %d  OP:%s" % [
			sim.get_sea_resources(),
			str(sea_hp) if sea_alive else "LOST",
		]
	if hud.has_node("Root/TopBar/HqLabel"):
		hud.get_node("Root/TopBar/HqLabel").text = "HQ: %d/%d" % [sim.get_hq_hp(), sim.get_hq_max_hp()]
	if hud.has_node("Root/SideBar/HelpLabel") and status_message != "":
		hud.get_node("Root/SideBar/HelpLabel").text = status_message


func _process_waves() -> void:
	for i in waves.size():
		if waves_fired.has(i):
			continue
		var w: Dictionary = waves[i]
		if combat_time >= float(w["at"]):
			waves_fired[i] = true
			wave_index = i + 1
			_spawn_wave(int(w["land"]), int(w["sea"]))
			status_message = "Wave %d inbound!" % wave_index


func _spawn_wave(land_n: int, sea_n: int) -> void:
	for i in land_n:
		_spawn_raider(0, float(i) * 0.3)
	for i in sea_n:
		_spawn_raider(1, float(i) * 0.3)


func _spawn_raider(front_id: int, delay: float) -> void:
	var grid: GridFront = land_grid if front_id == 0 else sea_grid
	var path: PackedVector2Array = grid.path_world_points()
	if path.size() == 0:
		return
	if path.size() > 0:
		path[0] = path[0] + Vector2(-delay * 18.0, 0)
	var outpost_i: int = maxi(1, path.size() / 2)
	var hp := 50.0 + float(wave_index) * 3.0
	var speed := 26.0 + float(wave_index % 4) * 2.0
	sim.spawn_raider(front_id, path, hp, speed, 6.0, outpost_i)


func _start_combat() -> void:
	if phase != Phase.BUILD:
		return
	if sim.get_defender_count() <= 0:
		status_message = "Place at least one unit before combat"
		_update_hud()
		return
	_set_phase(Phase.COMBAT)
	combat_time = 0.0
	wave_index = 0
	waves_fired.clear()
	status_message = "COMBAT — hold both fronts"


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
	if run_over:
		return
	if phase == Phase.RESULT:
		return
	var grid: GridFront = land_grid if front_id == "land" else sea_grid

	# Hero redeploy: second click on empty cell
	if pending_hero_id >= 0 and grid.is_placeable(cell):
		var to: Vector2 = grid.cell_to_global_center(cell)
		var new_front: int = 0 if front_id == "land" else 1
		if sim.start_defender_travel(pending_hero_id, to, new_front, 1.6):
			# free old cell
			if cell_by_defender.has(pending_hero_id):
				var old: Dictionary = cell_by_defender[pending_hero_id]
				var og: GridFront = land_grid if str(old.front) == "land" else sea_grid
				og.clear_occupant(old.cell)
			grid.set_occupant(cell, pending_hero_id)
			cell_by_defender[pending_hero_id] = {"front": front_id, "cell": cell}
			status_message = "Commander redeploying…"
			pending_hero_id = -1
		return

	# Select existing hero on occupied cell
	if grid.occupants.has(cell):
		var did: int = int(grid.occupants[cell])
		for d in sim.get_defenders():
			if int(d.get("id", -1)) == did and str(d.get("type", "")) == "hero_qi":
				pending_hero_id = did
				status_message = "Commander selected — click empty cell to redeploy"
				return
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
	# Prefer spending matching front currency; fallback to placement front
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
	var place_front: int = 0 if front_id == "land" else 1
	var did2: int = sim.spawn_defender(
		place_front, selected_unit_id, pos, range_px, damage, cooldown, own_m, cross_m, aura_r, aura_b
	)
	if did2 < 0:
		return
	grid.set_occupant(cell, did2)
	cell_by_defender[did2] = {"front": front_id, "cell": cell}
	_sync_session_from_sim()
	status_message = "%s deployed on %s" % [str(def.get("name", selected_unit_id)), front_id]
	_sync_visuals()


func _sync_visuals() -> void:
	var live_ids: Dictionary = {}
	# Raiders
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
	# Defenders
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
	# Prune dead
	for id in visual_nodes.keys():
		if not live_ids.has(id):
			_free_visual(id)


func _free_visual(id: int) -> void:
	if visual_nodes.has(id):
		var n: Node = visual_nodes[id]
		if is_instance_valid(n):
			n.queue_free()
		visual_nodes.erase(id)


func _hero_ability() -> void:
	if phase != Phase.COMBAT or run_over:
		return
	if hero_ability_cd > 0.0:
		status_message = "Hero ability CD %.0fs" % hero_ability_cd
		return
	var hits: int = sim.hero_pulse(200.0, 28.0)
	if hits <= 0:
		status_message = "No commander on field or no targets in range"
		return
	hero_ability_cd = 8.0
	status_message = "Commander signal flare! (%d hits)" % hits
	_sync_visuals()


func _finish(victory: bool, reason: String) -> void:
	if run_over:
		return
	run_over = true
	_set_phase(Phase.RESULT)
	_sync_session_from_sim()
	GameSession.end_run(victory, reason)
	if hud.has_method("show_result"):
		hud.show_result(victory, reason, GameSession.last_result)


func _restart() -> void:
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_phase") or event.is_action_pressed("start_combat"):
		_start_combat()
	elif event.is_action_pressed("hero_ability"):
		_hero_ability()
	elif event.is_action_pressed("pause_game"):
		GameSession.is_paused = not GameSession.is_paused
	for action in SELECT_KEYS.keys():
		if event.is_action_pressed(action):
			_on_unit_selected(SELECT_KEYS[action])
			return
