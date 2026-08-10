class_name BattleRoot
extends Node2D
## Dual-front Slice-0 loop: BUILD then COMBAT, land + sea grids, shared HQ.

enum Phase { BUILD, COMBAT, RESULT }

const SELECTABLE := ["spearman", "cannon", "arquebusier", "junk", "hero_qi", "cross_support"]

@onready var land_host: Node2D = $LandHost
@onready var sea_host: Node2D = $SeaHost
@onready var units_root: Node2D = $Units
@onready var raiders_root: Node2D = $Raiders
@onready var hud: CanvasLayer = $HUD

var land_grid: GridFront
var sea_grid: GridFront
var phase: Phase = Phase.BUILD
var selected_unit_id: String = "spearman"
var build_time_left: float = 45.0
var combat_time: float = 0.0
var wave_index: int = 0
var spawn_acc: float = 0.0
var run_over: bool = false

var resource_outpost: StructureMarker
var trading_outpost: StructureMarker
var hq_marker: StructureMarker

var _land_income_alive: bool = true
var _sea_income_alive: bool = true
var _income_acc: float = 0.0

## Wave table (Slice-0 hardcoded; later from JSON G5)
var waves: Array = [
	{"at": 2.0, "land": 3, "sea": 2},
	{"at": 12.0, "land": 4, "sea": 4},
	{"at": 24.0, "land": 6, "sea": 5},
	{"at": 38.0, "land": 5, "sea": 6},
]
var waves_fired: Dictionary = {}


func _ready() -> void:
	GameSession.reset_run()
	GameSession.run_ended.connect(_on_run_ended)
	_setup_grids()
	_setup_structures()
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


func _setup_structures() -> void:
	# HQ shared at right of both grids (visual on land row + sea row bridge)
	hq_marker = StructureMarker.new()
	add_child(hq_marker)
	hq_marker.setup(StructureMarker.Kind.HQ, "land", self)
	hq_marker.global_position = Vector2(620, 360)

	resource_outpost = StructureMarker.new()
	land_host.add_child(resource_outpost)
	resource_outpost.setup(StructureMarker.Kind.RESOURCE_OUTPOST, "land", self)
	var ro_cell := Vector2i(8, 1)
	resource_outpost.position = land_grid.cell_to_local_center(ro_cell)
	land_grid.block_cell(ro_cell)

	trading_outpost = StructureMarker.new()
	sea_host.add_child(trading_outpost)
	trading_outpost.setup(StructureMarker.Kind.TRADING_OUTPOST, "sea", self)
	var to_cell := Vector2i(8, 4)
	trading_outpost.position = sea_grid.cell_to_local_center(to_cell)
	sea_grid.block_cell(to_cell)

	# Block HQ approach cells on both grids
	for y in range(2, 4):
		land_grid.block_cell(Vector2i(9, y))
		sea_grid.block_cell(Vector2i(9, y))


func _wire_hud() -> void:
	if hud.has_signal("start_combat_pressed"):
		hud.start_combat_pressed.connect(_start_combat)
	if hud.has_signal("unit_selected"):
		hud.unit_selected.connect(_on_unit_selected)
	if hud.has_signal("restart_pressed"):
		hud.restart_pressed.connect(_restart)
	if hud.has_signal("hero_ability_pressed"):
		hud.hero_ability_pressed.connect(_activate_any_hero)


func _process(delta: float) -> void:
	if run_over or GameSession.is_paused:
		return
	match phase:
		Phase.BUILD:
			build_time_left -= delta
			if hud.has_method("set_build_timer"):
				hud.set_build_timer(build_time_left)
			if build_time_left <= 0.0:
				_start_combat()
		Phase.COMBAT:
			combat_time += delta
			_income_acc += delta
			if _income_acc >= 3.0:
				_income_acc = 0.0
				if _land_income_alive:
					GameSession.gain("land", 3)
				if _sea_income_alive:
					GameSession.gain("sea", 3)
			_process_waves()
			if hud.has_method("set_combat_timer"):
				hud.set_combat_timer(combat_time)
			# Win: all waves fired and no raiders left after last wave window
			if combat_time > 55.0 and raiders_root.get_child_count() == 0 and wave_index >= waves.size():
				_finish(true, "Raid weathered — fortress holds")


func _process_waves() -> void:
	for i in waves.size():
		if waves_fired.has(i):
			continue
		var w: Dictionary = waves[i]
		if combat_time >= float(w["at"]):
			waves_fired[i] = true
			wave_index = i + 1
			_spawn_wave(int(w["land"]), int(w["sea"]))


func _spawn_wave(land_n: int, sea_n: int) -> void:
	for i in land_n:
		_spawn_raider("land", "raider_land", float(i) * 0.35)
	for i in sea_n:
		_spawn_raider("sea", "raider_sea", float(i) * 0.35)


func _spawn_raider(front: String, id: String, delay: float) -> void:
	var r := Raider.new()
	raiders_root.add_child(r)
	var grid: GridFront = land_grid if front == "land" else sea_grid
	var path := grid.path_world_points()
	# Stagger spawn slightly behind start
	if path.size() > 0:
		path[0] = path[0] + Vector2(-40.0 - delay * 20.0, 0)
	r.setup(id, front, path, self)
	if delay > 0.0:
		r.set_process(false)
		await get_tree().create_timer(delay).timeout
		if is_instance_valid(r):
			r.set_process(true)


func _set_phase(p: Phase) -> void:
	phase = p
	var name_s := "BUILD" if p == Phase.BUILD else ("COMBAT" if p == Phase.COMBAT else "RESULT")
	GameSession.phase_changed.emit(name_s)
	if hud.has_method("set_phase"):
		hud.set_phase(name_s)


func _start_combat() -> void:
	if phase != Phase.BUILD:
		return
	_set_phase(Phase.COMBAT)
	combat_time = 0.0
	wave_index = 0
	waves_fired.clear()


func _on_unit_selected(id: String) -> void:
	selected_unit_id = id
	if hud.has_method("set_selected"):
		hud.set_selected(id)


func _on_cell_clicked(front_id: String, cell: Vector2i) -> void:
	if phase != Phase.BUILD or run_over:
		return
	var def := UnitDefs.get_def(selected_unit_id)
	if def.is_empty():
		return
	var allowed_front: int = int(def.get("front", UnitDefs.Front.LAND))
	if allowed_front == UnitDefs.Front.LAND and front_id != "land":
		return
	if allowed_front == UnitDefs.Front.SEA and front_id != "sea":
		return
	# BOTH can place on either
	var grid: GridFront = land_grid if front_id == "land" else sea_grid
	if not grid.is_placeable(cell):
		return
	var currency: String = str(def.get("currency", "land"))
	var cost: int = int(def.get("cost", 10))
	if not GameSession.spend(currency, cost):
		return
	var u := UnitEntity.new()
	units_root.add_child(u)
	u.global_position = grid.cell_to_global_center(cell)
	u.setup(selected_unit_id, front_id, cell, self)
	grid.set_occupant(cell, u)
	GameSession.units_placed += 1


func is_combat_phase() -> bool:
	return phase == Phase.COMBAT and not run_over


func find_target_for(unit: UnitEntity) -> Raider:
	var best: Raider = null
	var best_d := INF
	var range_px: float = float(unit.def.get("range", 1.5)) * GridFront.CELL
	for c in raiders_root.get_children():
		if not c is Raider:
			continue
		var r := c as Raider
		var d := unit.global_position.distance_to(r.global_position)
		if d > range_px:
			continue
		# Prefer same front, but allow cross if mult > 0
		var same := r.front_id == unit.front_id
		var mult: float = float(unit.def.get("own_env_mult", 1.0)) if same else float(unit.def.get("cross_env_mult", 0.0))
		if mult <= 0.0:
			continue
		if d < best_d:
			best_d = d
			best = r
	return best


func total_aura_bonus(at: Vector2) -> float:
	var bonus := 0.0
	for c in units_root.get_children():
		if c is UnitEntity:
			bonus += (c as UnitEntity).aura_multiplier_at(at)
	return bonus


func hero_pulse(hero: UnitEntity, damage: float) -> void:
	var r: float = float(hero.def.get("aura_radius", 2.0)) * GridFront.CELL * 1.2
	for c in raiders_root.get_children():
		if c is Raider:
			var ra := c as Raider
			if hero.global_position.distance_to(ra.global_position) <= r:
				ra.take_damage(damage)


func _activate_any_hero() -> void:
	for c in units_root.get_children():
		if c is UnitEntity:
			var u := c as UnitEntity
			if u.try_active_ability():
				return


func on_unit_died(u: UnitEntity) -> void:
	var grid: GridFront = land_grid if u.front_id == "land" else sea_grid
	grid.clear_occupant(u.cell)


func on_raider_died(_r: Raider) -> void:
	pass


func on_raider_reached(_r: Raider) -> void:
	pass


func on_outpost_lost(s: StructureMarker) -> void:
	if s.kind == StructureMarker.Kind.RESOURCE_OUTPOST:
		_land_income_alive = false
	elif s.kind == StructureMarker.Kind.TRADING_OUTPOST:
		_sea_income_alive = false


func _on_run_ended(victory: bool, reason: String) -> void:
	run_over = true
	_set_phase(Phase.RESULT)
	if hud.has_method("show_result"):
		hud.show_result(victory, reason, GameSession.last_result)


func _finish(victory: bool, reason: String) -> void:
	if run_over:
		return
	GameSession.end_run(victory, reason)


func _restart() -> void:
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_combat"):
		_start_combat()
	elif event.is_action_pressed("select_spearman"):
		_on_unit_selected("spearman")
	elif event.is_action_pressed("select_cannon"):
		_on_unit_selected("cannon")
	elif event.is_action_pressed("select_hero"):
		_on_unit_selected("hero_qi")
	elif event.is_action_pressed("select_cross_support"):
		_on_unit_selected("cross_support")
	elif event.is_action_pressed("pause_game"):
		GameSession.is_paused = not GameSession.is_paused
