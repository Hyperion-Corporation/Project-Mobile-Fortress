class_name BattleRoot
extends Node2D
## Refactored to act as a pure renderer/view for the C++ SimulationCore.

enum Phase { BUILD, COMBAT, RESULT }
const SELECTABLE := ["spearman", "cannon", "arquebusier", "junk", "hero_qi", "cross_support"]

@onready var land_host: Node2D = $LandHost
@onready var sea_host: Node2D = $SeaHost
@onready var units_root: Node2D = $Units
@onready var raiders_root: Node2D = $Raiders
@onready var hud: CanvasLayer = $HUD
@onready var sim = $SimulationCore

var land_grid: GridFront
var sea_grid: GridFront
var phase: Phase = Phase.BUILD
var selected_unit_id: String = "spearman"
var build_time_left: float = 45.0
var combat_time: float = 0.0
var wave_index: int = 0
var run_over: bool = false

var waves: Array = [
	{"at": 2.0, "land": 3, "sea": 2},
	{"at": 12.0, "land": 4, "sea": 4},
	{"at": 24.0, "land": 6, "sea": 5},
	{"at": 38.0, "land": 5, "sea": 6},
]
var waves_fired: Dictionary = {}
var visual_nodes: Dictionary = {}

func _ready() -> void:
	GameSession.reset_run()
	sim.reset_run(40, 40, 100)
	_setup_grids()
	_wire_hud()
	_set_phase(Phase.BUILD)
	if hud.has_method("set_selected"):
		hud.set_selected(selected_unit_id)

func _setup_grids() -> void:
	land_grid = GridFront.new()
	land_grid.name = "LandGrid"
	land_host.add_child(land_grid)
	land_grid.setup(Vector2(40, 80), "land", 10, 6)
	land_grid.cell_clicked.connect(_on_cell_clicked)

	sea_grid = GridFront.new()
	sea_grid.name = "SeaGrid"
	sea_host.add_child(sea_grid)
	sea_grid.setup(Vector2(40, 80), "sea", 10, 6)
	sea_grid.cell_clicked.connect(_on_cell_clicked)

func _wire_hud() -> void:
	if hud.has_signal("start_combat_pressed"): hud.start_combat_pressed.connect(_start_combat)
	if hud.has_signal("unit_selected"): hud.unit_selected.connect(_on_unit_selected)
	if hud.has_signal("restart_pressed"): hud.restart_pressed.connect(_restart)

func _process(delta: float) -> void:
	if run_over or GameSession.is_paused: return
	match phase:
		Phase.BUILD:
			build_time_left -= delta
			_update_hud()
			if build_time_left <= 0.0: _start_combat()
		Phase.COMBAT:
			combat_time += delta
			_process_waves()
			
			var events = sim.tick(delta, true)
			_process_events(events)
			_sync_visuals()
			_update_hud()
			
			if combat_time > 55.0 and sim.get_raider_count() == 0 and wave_index >= waves.size():
				_finish(true, "Raid weathered — fortress holds")

func _process_events(events: Array) -> void:
	for ev in events:
		var type = ev.get("type", "")
		if type == "hq_destroyed":
			_finish(false, "HQ Destroyed!")
		elif type == "raider_killed" or type == "hq_hit":
			var id = ev.get("id", -1)
			if visual_nodes.has(id):
				visual_nodes[id].queue_free()
				visual_nodes.erase(id)

func _update_hud() -> void:
	if hud.has_method("set_build_timer"): hud.set_build_timer(build_time_left)
	if hud.has_method("set_combat_timer"): hud.set_combat_timer(combat_time)
	
	if hud.has_node("Root/TopBar/LandRes"):
		hud.get_node("Root/TopBar/LandRes").text = "Land 兩: %d" % sim.get_land_resources()
	if hud.has_node("Root/TopBar/SeaRes"):
		hud.get_node("Root/TopBar/SeaRes").text = "Sea 兩: %d" % sim.get_sea_resources()
	if hud.has_node("Root/TopBar/HqLabel"):
		hud.get_node("Root/TopBar/HqLabel").text = "HQ: %d/%d" % [sim.get_hq_hp(), sim.get_hq_max_hp()]

func _process_waves() -> void:
	for i in waves.size():
		if waves_fired.has(i): continue
		var w: Dictionary = waves[i]
		if combat_time >= float(w["at"]):
			waves_fired[i] = true
			wave_index = i + 1
			_spawn_wave(int(w["land"]), int(w["sea"]))

func _spawn_wave(land_n: int, sea_n: int) -> void:
	for i in land_n: _spawn_raider(0, float(i) * 0.35)
	for i in sea_n: _spawn_raider(1, float(i) * 0.35)

func _spawn_raider(front_id: int, delay: float) -> void:
	var grid = land_grid if front_id == 0 else sea_grid
	var path = grid.path_world_points()
	if path.size() > 0:
		path[0] = path[0] + Vector2(-40.0 - delay * 20.0, 0)
	sim.spawn_raider(front_id, path, 55.0, 25.0, 6.0)

func _start_combat() -> void:
	if phase != Phase.BUILD: return
	_set_phase(Phase.COMBAT)
	combat_time = 0.0
	wave_index = 0
	waves_fired.clear()

func _set_phase(p: Phase) -> void:
	phase = p
	var name_s := "BUILD" if p == Phase.BUILD else ("COMBAT" if p == Phase.COMBAT else "RESULT")
	GameSession.phase_changed.emit(name_s)
	if hud.has_method("set_phase"): hud.set_phase(name_s)

func _on_unit_selected(id: String) -> void:
	selected_unit_id = id
	if hud.has_method("set_selected"): hud.set_selected(id)

func _on_cell_clicked(front_id: String, cell: Vector2i) -> void:
	if phase != Phase.BUILD or run_over: return
	var grid = land_grid if front_id == "land" else sea_grid
	if not grid.is_placeable(cell): return
	
	var cost = 10
	var sim_front = 0 if front_id == "land" else 1
	if not sim.spend(sim_front, cost): return
	
	var pos = grid.cell_to_global_center(cell)
	sim.spawn_defender(sim_front, selected_unit_id, pos, 150.0, 10.0, 1.0)
	grid.block_cell(cell)

func _sync_visuals() -> void:
	# Map Raiders from C++ state to Godot Sprites
	var raiders = sim.get_raiders()
	for r in raiders:
		var id = r["id"]
		if not visual_nodes.has(id):
			var sprite = ColorRect.new()
			sprite.size = Vector2(16, 16)
			sprite.color = Color.CRIMSON
			raiders_root.add_child(sprite)
			visual_nodes[id] = sprite
		visual_nodes[id].global_position = r["position"] - Vector2(8, 8)
		
	# Map Defenders from C++ state to Godot Sprites
	var defenders = sim.get_defenders()
	for d in defenders:
		var id = d["id"]
		if not visual_nodes.has(id):
			var sprite = ColorRect.new()
			sprite.size = Vector2(24, 24)
			sprite.color = Color.CORNFLOWER_BLUE
			units_root.add_child(sprite)
			visual_nodes[id] = sprite
		visual_nodes[id].global_position = d["position"] - Vector2(12, 12)

func _finish(victory: bool, reason: String) -> void:
	if run_over: return
	run_over = true
	_set_phase(Phase.RESULT)
	if hud.has_method("show_result"):
		hud.show_result(victory, reason, GameSession.last_result)

func _restart() -> void:
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_combat"): _start_combat()
	elif event.is_action_pressed("select_spearman"): _on_unit_selected("spearman")
	elif event.is_action_pressed("pause_game"): GameSession.is_paused = not GameSession.is_paused
