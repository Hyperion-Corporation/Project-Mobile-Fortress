extends Node2D
## Slice-0 G2: offline dual-front fortress defense.
## Presentation in GDScript; sim state prefers SimulationCore (GDExtension) when present.

const SAVE_PATH := "user://mobile_fortress_slice0.json"
const RESULTS_PATH := "user://last_run_results.json"
const LEVEL_PATH := "res://assets/levels/slice0_dual_front.json"
const GRID_ROWS := 3
const GRID_COLUMNS := 5
const CELL_SIZE := Vector2(88.0, 58.0)
const FRONT_ORIGINS := [Vector2(165.0, 260.0), Vector2(790.0, 260.0)]
const FRONT_NAMES := ["LAND FRONT", "SEA FRONT"]
const FRONT_COLORS := [Color("#c8845b"), Color("#4c9bb5")]
const UNIT_TYPES := ["garrison", "arquebusier", "support", "hero"]
const UNIT_LABELS := ["GARRISON", "ARQUEBUS", "SUPPORT", "COMMANDER"]
const UNIT_COSTS := [2, 3, 4, 5]

enum Phase { BUILD, COMBAT, VICTORY, DEFEAT }

var phase: int = Phase.BUILD
var selected_unit := 0
var units: Array[Dictionary] = []
var cells: Array[Dictionary] = []
## Fallback-only enemy list when C++ sim is missing.
var enemies_fallback: Array[Dictionary] = []

var message := "BUILD — place on land & sea, then hold both fronts"
var message_time := 0.0
var wave_number := 0
var combat_time := 0.0
var spawn_time := 0.0
var build_time_left := 40.0
var hero_active_cd := 0.0
var font: Font

var use_cpp := false
var sim: Node = null ## SimulationCore when available

## Level data
var level: Dictionary = {}
var waves: Array = []
var waves_fired: Dictionary = {}
var start_land := 14
var start_sea := 14
var build_phase_seconds := 40.0
var victory_time := 48.0


func _ready() -> void:
	font = ThemeDB.fallback_font
	_load_level()
	_init_sim()
	_build_cells()
	_set_message("Ming + Portuguese Slice-0 — defend land & sea (sim: %s)" % ("C++" if use_cpp else "GDScript"))
	queue_redraw()


func _load_level() -> void:
	if not FileAccess.file_exists(LEVEL_PATH):
		waves = [
			{"at": 2.0, "land": 2, "sea": 2},
			{"at": 10.0, "land": 3, "sea": 3},
			{"at": 20.0, "land": 4, "sea": 4},
			{"at": 32.0, "land": 5, "sea": 5},
		]
		return
	var f := FileAccess.open(LEVEL_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return
	level = parsed
	start_land = int(level.get("startingLandCurrency", 40))
	start_sea = int(level.get("startingSeaCurrency", 40))
	build_phase_seconds = float(level.get("buildPhaseSeconds", 40))
	build_time_left = build_phase_seconds
	waves.clear()
	for w in level.get("waves", []):
		if w is Dictionary:
			waves.append({
				"at": float(w.get("delaySeconds", 0.0)),
				"land": int(w.get("landCount", w.get("enemyCount", 2))),
				"sea": int(w.get("seaCount", 2)),
			})
	if waves.is_empty():
		waves = [{"at": 2.0, "land": 3, "sea": 2}, {"at": 14.0, "land": 4, "sea": 4}]


func _init_sim() -> void:
	use_cpp = ClassDB.class_exists("SimulationCore")
	if use_cpp:
		sim = ClassDB.instantiate("SimulationCore")
		add_child(sim)
		sim.reset_run(start_land, start_sea, int(level.get("hqMaxHp", 100)))
	else:
		sim = null


func _build_cells() -> void:
	cells.clear()
	for front in range(2):
		for row in range(GRID_ROWS):
			for column in range(GRID_COLUMNS):
				cells.append({
					"front": front,
					"row": row,
					"column": column,
					"occupied": -1,
					"position": _cell_position(front, row, column),
				})


func _cell_position(front: int, row: int, column: int) -> Vector2:
	var origin: Vector2 = FRONT_ORIGINS[front]
	var iso_x := (column - row) * CELL_SIZE.x * 0.5
	var iso_y := (column + row) * CELL_SIZE.y * 0.5
	return origin + Vector2(iso_x, iso_y)


func _lane_path(front: int) -> PackedVector2Array:
	## Naive path: approach along mid row, then down to HQ approach.
	var pts: PackedVector2Array = PackedVector2Array()
	var mid_row := 1
	pts.append(_cell_position(front, 0, 0) - Vector2(0, 70))
	for col in range(GRID_COLUMNS):
		pts.append(_cell_position(front, mid_row, col))
	pts.append(_cell_position(front, GRID_ROWS - 1, GRID_COLUMNS - 1) + Vector2(0, 70))
	return pts


func _land_res() -> int:
	return sim.get_land_resources() if use_cpp else _fb_land

func _sea_res() -> int:
	return sim.get_sea_resources() if use_cpp else _fb_sea

func _hq() -> int:
	return sim.get_hq_hp() if use_cpp else int(_fb_hq)

func _hq_max() -> int:
	return sim.get_hq_max_hp() if use_cpp else 100

func _kills() -> int:
	return sim.get_enemies_killed() if use_cpp else _fb_kills

func _placed() -> int:
	return sim.get_units_placed() if use_cpp else _fb_placed

func _land_out() -> bool:
	return sim.is_land_outpost_alive() if use_cpp else _fb_land_out

func _sea_out() -> bool:
	return sim.is_sea_outpost_alive() if use_cpp else _fb_sea_out

# Fallback state
var _fb_land := 14
var _fb_sea := 14
var _fb_hq := 100.0
var _fb_kills := 0
var _fb_placed := 0
var _fb_land_out := true
var _fb_sea_out := true
var _fb_income := 0.0


func _process(delta: float) -> void:
	if message_time > 0.0:
		message_time -= delta
	hero_active_cd = maxf(0.0, hero_active_cd - delta)
	_update_travel(delta)

	if phase == Phase.BUILD:
		build_time_left -= delta
		if build_time_left <= 0.0:
			_start_combat()

	if phase == Phase.COMBAT:
		combat_time += delta
		_process_waves()
		if use_cpp:
			var events: Array = sim.tick(delta, true)
			for ev in events:
				if not ev is Dictionary:
					continue
				var t: String = str(ev.get("type", ""))
				if t == "hq_destroyed":
					_defeat("DEFEAT — the Main HQ fell")
				elif t == "hq_hit" and int(ev.get("damage", 0)) > 0:
					pass
		else:
			_fallback_combat(delta)
		_update_units(delta)
		if combat_time >= victory_time and _raider_count() == 0 and wave_number >= waves.size():
			_victory("VICTORY — both fronts held")

	if phase == Phase.BUILD and Input.is_action_just_pressed("toggle_phase"):
		_start_combat()
	if Input.is_action_just_pressed("save_game"):
		_save_game()
		_set_message("Saved offline")
	if Input.is_action_just_pressed("load_game"):
		_load_game()
		_set_message("Loaded offline")
	if Input.is_action_just_pressed("select_unit_1"):
		selected_unit = 0
		_set_message("Garrison (land currency preferred)")
	if Input.is_action_just_pressed("select_unit_2"):
		selected_unit = 1
		_set_message("Arquebus (sea currency preferred)")
	if Input.is_action_just_pressed("select_unit_3"):
		selected_unit = 2
		_set_message("Support — strong cross-front, weak own-front")
	if Input.is_action_just_pressed("select_unit_4"):
		selected_unit = 3
		_set_message("Commander — aura; E ability; click empty cell to redeploy")
	if Input.is_action_just_pressed("hero_ability"):
		_try_hero_ability()
	queue_redraw()


func _process_waves() -> void:
	for i in waves.size():
		if waves_fired.has(i):
			continue
		var w: Dictionary = waves[i]
		if combat_time >= float(w["at"]):
			waves_fired[i] = true
			wave_number = i + 1
			for _j in int(w["land"]):
				_spawn_raider(0)
			for _j in int(w["sea"]):
				_spawn_raider(1)
			_set_message("Wave %d inbound!" % wave_number)


func _spawn_raider(front: int) -> void:
	var path := _lane_path(front)
	var hp := 55.0 + float(wave_number) * 3.0
	var speed := 28.0 + float(wave_number % 4) * 2.5
	var dmg := 6.0
	if use_cpp:
		if _raider_count() >= 40:
			return
		sim.spawn_raider(front, path, hp, speed, dmg)
	else:
		if enemies_fallback.size() >= 40:
			return
		enemies_fallback.append({
			"id": enemies_fallback.size() + 1,
			"front": front,
			"position": path[0],
			"hp": hp,
			"max_hp": hp,
			"speed": speed,
			"damage": dmg,
			"path": path,
			"path_i": 0,
		})


func _raider_count() -> int:
	if use_cpp:
		return sim.get_raider_count()
	return enemies_fallback.size()


func _raiders_snapshot() -> Array:
	if use_cpp:
		return sim.get_raiders()
	var out: Array = []
	for e in enemies_fallback:
		out.append(e)
	return out


func _fallback_combat(delta: float) -> void:
	_fb_income += delta
	if _fb_income >= 4.0:
		_fb_income = 0.0
		if _fb_land_out:
			_fb_land += 2
		if _fb_sea_out:
			_fb_sea += 2
	for enemy in enemies_fallback.duplicate():
		if float(enemy.hp) <= 0.0:
			enemies_fallback.erase(enemy)
			_fb_kills += 1
			continue
		var path: PackedVector2Array = enemy.path
		var pi: int = int(enemy.path_i)
		if pi >= path.size() - 1:
			_fb_hq -= float(enemy.damage)
			enemies_fallback.erase(enemy)
			if _fb_hq <= 0.0:
				_defeat("DEFEAT — the Main HQ fell")
			continue
		# Outpost threat near mid path
		if pi == path.size() / 2:
			if int(enemy.front) == 0 and _fb_land_out and randf() < 0.015:
				_fb_land_out = false
				_set_message("Resource Outpost lost (economic only)")
			elif int(enemy.front) == 1 and _fb_sea_out and randf() < 0.015:
				_fb_sea_out = false
				_set_message("Trading Outpost lost (economic only)")
		var target: Vector2 = path[pi + 1]
		enemy.position = enemy.position.move_toward(target, float(enemy.speed) * delta)
		if enemy.position.distance_to(target) < 4.0:
			enemy.path_i = pi + 1


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var click: Vector2 = mb.position
	if Rect2(1040, 24, 200, 48).has_point(click):
		if phase == Phase.BUILD:
			_start_combat()
		elif phase == Phase.COMBAT:
			# no mid-combat cancel — encourage full session
			_set_message("Hold the line — E for hero flare")
		elif phase == Phase.VICTORY or phase == Phase.DEFEAT:
			_reset_run()
		return
	if Rect2(40, 24, 210, 48).has_point(click):
		_save_game()
		_set_message("Saved offline")
		return
	for index in range(UNIT_TYPES.size()):
		if Rect2(280 + index * 150, 24, 138, 48).has_point(click):
			selected_unit = index
			_set_message("Selected %s (cost %d)" % [UNIT_LABELS[index], UNIT_COSTS[index]])
			return
	if phase == Phase.VICTORY or phase == Phase.DEFEAT:
		return
	for index in range(cells.size()):
		var cell: Dictionary = cells[index]
		if not _diamond_contains(click, cell.position, CELL_SIZE * 0.48):
			continue
		if int(cell.occupied) != -1:
			# Select hero for travel if clicking own hero
			var uidx: int = int(cell.occupied)
			if uidx >= 0 and uidx < units.size() and str(units[uidx].type) == "hero":
				_set_message("Commander selected — click empty cell to redeploy")
				selected_unit = 3
				_pending_hero_move = uidx
			return
		if phase == Phase.BUILD or phase == Phase.COMBAT:
			if _pending_hero_move >= 0:
				_start_hero_travel(_pending_hero_move, index)
				_pending_hero_move = -1
			else:
				_place_unit(index)
		return


var _pending_hero_move: int = -1


func _diamond_contains(point: Vector2, center: Vector2, radius: Vector2) -> bool:
	var normalized := (point - center) / radius
	return absf(normalized.x) + absf(normalized.y) <= 1.0


func _spend(front: int, amount: int) -> bool:
	if use_cpp:
		return sim.spend(front, amount)
	if front == 0:
		if _fb_land < amount:
			return false
		_fb_land -= amount
		return true
	if _fb_sea < amount:
		return false
	_fb_sea -= amount
	return true


func _place_unit(cell_index: int) -> void:
	var cell: Dictionary = cells[cell_index]
	if int(cell.occupied) != -1:
		return
	var front: int = int(cell.front)
	var utype: String = UNIT_TYPES[selected_unit]
	var prefer_land := utype == "garrison" or (utype != "arquebusier" and front == 0)
	var pay_front := 0 if prefer_land else 1
	var cost: int = UNIT_COSTS[selected_unit]
	if not _spend(pay_front, cost):
		_set_message("Not enough %s resources" % ("land" if pay_front == 0 else "sea"))
		return
	var unit := {
		"type": utype,
		"front": front,
		"cell": cell_index,
		"position": cell.position,
		"hp": 100.0,
		"cooldown": 0.0,
		"traveling": false,
		"travel_from": cell.position,
		"travel_to": cell.position,
		"travel_t": 0.0,
		"travel_target_cell": cell_index,
	}
	units.append(unit)
	cells[cell_index].occupied = units.size() - 1
	if use_cpp:
		sim.note_unit_placed()
	else:
		_fb_placed += 1
	_set_message("%s on %s" % [UNIT_LABELS[selected_unit], FRONT_NAMES[front]])


func _start_hero_travel(unit_index: int, target_cell: int) -> void:
	if unit_index < 0 or unit_index >= units.size():
		return
	var unit: Dictionary = units[unit_index]
	if str(unit.type) != "hero":
		return
	if bool(unit.get("traveling", false)):
		return
	var cell: Dictionary = cells[target_cell]
	if int(cell.occupied) != -1:
		return
	# Free old cell
	var old: int = int(unit.cell)
	if old >= 0 and old < cells.size():
		cells[old].occupied = -1
	unit.traveling = true
	unit.travel_from = unit.position
	unit.travel_to = cell.position
	unit.travel_t = 0.0
	unit.travel_target_cell = target_cell
	unit.front = int(cell.front)
	unit.cell = target_cell
	# No attacks while traveling (checked in _update_units)
	_set_message("Commander redeploying…")


func _update_travel(delta: float) -> void:
	for i in range(units.size()):
		var unit: Dictionary = units[i]
		if not bool(unit.get("traveling", false)):
			continue
		unit.travel_t = float(unit.travel_t) + delta / 1.6
		var t: float = clampf(float(unit.travel_t), 0.0, 1.0)
		unit.position = unit.travel_from.lerp(unit.travel_to, t)
		# Aura still applies during travel (position updates)
		if t >= 1.0:
			unit.traveling = false
			unit.position = unit.travel_to
			var tc: int = int(unit.travel_target_cell)
			cells[tc].occupied = i
			_set_message("Commander in position on %s" % FRONT_NAMES[int(unit.front)])


func _start_combat() -> void:
	if units.is_empty():
		_set_message("Deploy at least one unit first")
		return
	phase = Phase.COMBAT
	combat_time = 0.0
	spawn_time = 0.0
	wave_number = 0
	waves_fired.clear()
	if not use_cpp:
		enemies_fallback.clear()
	_set_message("COMBAT — waves on both fronts")


func _update_units(delta: float) -> void:
	if phase != Phase.COMBAT:
		return
	var raiders := _raiders_snapshot()
	for unit in units:
		if bool(unit.get("traveling", false)):
			continue
		unit.cooldown = maxf(0.0, float(unit.cooldown) - delta)
		if float(unit.cooldown) > 0.0:
			continue
		var target = _nearest_enemy(unit, raiders)
		if target == null:
			continue
		var damage := 18.0
		var atk_range := 150.0
		var own_mult := 1.0
		var cross_mult := 0.0
		match str(unit.type):
			"garrison":
				damage = 24.0
			"arquebusier":
				damage = 15.0
				atk_range = 235.0
				cross_mult = 0.25
			"support":
				damage = 12.0
				atk_range = 340.0
				own_mult = 0.55
				cross_mult = 1.2
			"hero":
				damage = 14.0
				atk_range = 260.0
				cross_mult = 0.45
		var same: bool = int(unit.front) == int(target.front)
		var mult: float = own_mult if same else cross_mult
		if mult <= 0.0:
			continue
		if unit.position.distance_to(target.position) <= atk_range:
			damage *= mult * (1.0 + _aura_bonus(unit.position))
			_damage_raider(target, damage)
			unit.cooldown = 0.75 if str(unit.type) != "hero" else 1.1
			if str(unit.type) == "hero":
				for ally in units:
					if ally.position.distance_to(unit.position) < 150.0:
						ally.hp = minf(100.0, float(ally.hp) + 2.0)


func _damage_raider(target: Dictionary, amount: float) -> void:
	if use_cpp:
		sim.damage_raider(int(target.id), amount)
	else:
		target.hp = float(target.hp) - amount
		if float(target.hp) <= 0.0:
			enemies_fallback.erase(target)
			_fb_kills += 1


func _aura_bonus(at: Vector2) -> float:
	var bonus := 0.0
	for unit in units:
		if str(unit.type) == "hero" and unit.position.distance_to(at) < 160.0:
			bonus += 0.2
	return bonus


func _nearest_enemy(unit: Dictionary, raiders: Array):
	var closest = null
	var best := INF
	for enemy in raiders:
		var same: bool = int(unit.front) == int(enemy.front)
		var ut := str(unit.type)
		if not same and ut != "support" and ut != "hero" and ut != "arquebusier":
			continue
		var d: float = unit.position.distance_to(enemy.position)
		if d < best:
			best = d
			closest = enemy
	return closest


func _try_hero_ability() -> void:
	if phase != Phase.COMBAT:
		return
	if hero_active_cd > 0.0:
		_set_message("Ability CD %.0fs" % hero_active_cd)
		return
	var heroes: Array = []
	for unit in units:
		if str(unit.type) == "hero" and not bool(unit.get("traveling", false)):
			heroes.append(unit)
	if heroes.is_empty():
		_set_message("No commander ready")
		return
	hero_active_cd = 8.0
	var raiders := _raiders_snapshot()
	for hero in heroes:
		for enemy in raiders:
			if hero.position.distance_to(enemy.position) < 200.0:
				_damage_raider(enemy, 28.0)
	_set_message("Commander signal flare!")


func _victory(reason: String) -> void:
	if phase == Phase.VICTORY or phase == Phase.DEFEAT:
		return
	phase = Phase.VICTORY
	message = reason
	_export_results(true, reason)
	_save_game()


func _defeat(reason: String) -> void:
	if phase == Phase.VICTORY or phase == Phase.DEFEAT:
		return
	phase = Phase.DEFEAT
	message = reason
	_export_results(false, reason)
	_save_game()


func _set_message(value: String) -> void:
	message = value
	message_time = 3.5


func _reset_run() -> void:
	phase = Phase.BUILD
	units.clear()
	enemies_fallback.clear()
	waves_fired.clear()
	wave_number = 0
	combat_time = 0.0
	build_time_left = build_phase_seconds
	hero_active_cd = 0.0
	_pending_hero_move = -1
	for cell in cells:
		cell.occupied = -1
	if use_cpp:
		sim.reset_run(start_land, start_sea, int(level.get("hqMaxHp", 100)))
	else:
		_fb_land = start_land
		_fb_sea = start_sea
		_fb_hq = 100.0
		_fb_kills = 0
		_fb_placed = 0
		_fb_land_out = true
		_fb_sea_out = true
	_set_message("New raid — fortify both fronts")


func _save_game() -> void:
	var saved_units: Array = []
	for unit in units:
		saved_units.append({
			"type": unit.type,
			"front": unit.front,
			"cell": unit.cell,
			"hp": unit.hp,
		})
	var payload := {
		"land": _land_res(),
		"sea": _sea_res(),
		"hq": _hq(),
		"units": saved_units,
		"use_cpp": use_cpp,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))


func _export_results(victory: bool, reason: String) -> void:
	var payload := {
		"victory": victory,
		"reason": reason,
		"enemies_killed": _kills(),
		"units_placed": _placed(),
		"land_outpost_alive": _land_out(),
		"sea_outpost_alive": _sea_out(),
		"sim": "cpp" if use_cpp else "gdscript",
		"civs": ["Ming", "Portuguese"],
	}
	var file := FileAccess.open(RESULTS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "\t"))


func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	_reset_run()
	# Restore units only (resources reset for fairness on load into build)
	for saved_unit in parsed.get("units", []):
		if saved_unit is Dictionary:
			var cell_i: int = int(saved_unit.get("cell", -1))
			if cell_i < 0 or cell_i >= cells.size():
				continue
			if int(cells[cell_i].occupied) != -1:
				continue
			var unit := {
				"type": str(saved_unit.get("type", "garrison")),
				"front": int(saved_unit.get("front", 0)),
				"cell": cell_i,
				"position": cells[cell_i].position,
				"hp": float(saved_unit.get("hp", 100.0)),
				"cooldown": 0.0,
				"traveling": false,
				"travel_from": cells[cell_i].position,
				"travel_to": cells[cell_i].position,
				"travel_t": 0.0,
				"travel_target_cell": cell_i,
			}
			units.append(unit)
			cells[cell_i].occupied = units.size() - 1
			if use_cpp:
				sim.note_unit_placed()
			else:
				_fb_placed += 1


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("#171b25"))
	draw_string(font, Vector2(40, 105), "MOBILE FORTRESS", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#f4dfb7"))
	var sub := "WŌKÒU COAST • MING + PORTUGUESE • SIM: %s" % ("C++ EnTT" if use_cpp else "GDSCRIPT")
	draw_string(font, Vector2(40, 132), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#bdc7d9"))
	_draw_button(Rect2(40, 24, 210, 48), "SAVE  [S]", Color("#34465e"))
	for index in range(UNIT_TYPES.size()):
		var color := Color("#b98252") if index == selected_unit else Color("#293244")
		_draw_button(Rect2(280 + index * 150, 24, 138, 48), "%s [%d]" % [UNIT_LABELS[index], index + 1], color)
	var phase_btn := "START COMBAT  [SPACE]"
	if phase == Phase.COMBAT:
		phase_btn = "HOLD THE LINE"
	elif phase == Phase.VICTORY or phase == Phase.DEFEAT:
		phase_btn = "PLAY AGAIN"
	_draw_button(Rect2(1040, 24, 200, 48), phase_btn, Color("#8e493c"))
	_draw_front(0)
	_draw_front(1)
	_draw_paths()
	_draw_hud()


func _draw_paths() -> void:
	for front in range(2):
		var path: PackedVector2Array = _lane_path(front)
		if path.size() < 2:
			continue
		var col: Color = FRONT_COLORS[front].darkened(0.1)
		col.a = 0.35
		for i in range(path.size() - 1):
			draw_line(path[i], path[i + 1], col, 3.0)


func _draw_front(front: int) -> void:
	draw_string(font, FRONT_ORIGINS[front] + Vector2(-110, -72), FRONT_NAMES[front], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, FRONT_COLORS[front].lightened(0.35))
	var outpost_txt := "ONLINE" if (_land_out() if front == 0 else _sea_out()) else "LOST (econ)"
	draw_string(font, FRONT_ORIGINS[front] + Vector2(-110, -48), "%s OUTPOST: %s" % ["RESOURCE" if front == 0 else "TRADING", outpost_txt], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#aab5c9"))
	for cell in cells:
		if int(cell.front) != front:
			continue
		var center: Vector2 = cell.position
		var points := PackedVector2Array([
			center + Vector2(0, -CELL_SIZE.y * 0.48),
			center + Vector2(CELL_SIZE.x * 0.48, 0),
			center + Vector2(0, CELL_SIZE.y * 0.48),
			center - Vector2(CELL_SIZE.x * 0.48, 0),
		])
		var cell_color := Color("#283e43") if front == 1 else Color("#44382f")
		if int(cell.occupied) == -1 and (phase == Phase.BUILD or phase == Phase.COMBAT):
			cell_color = cell_color.lightened(0.16)
		draw_colored_polygon(points, cell_color)
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), FRONT_COLORS[front].darkened(0.2), 2.0)
	for unit in units:
		if int(unit.front) == front or bool(unit.get("traveling", false)):
			_draw_unit(unit)
	for enemy in _raiders_snapshot():
		if int(enemy.front) == front:
			_draw_enemy(enemy)


func _draw_unit(unit: Dictionary) -> void:
	var color := Color("#ead09a")
	var radius := 18.0
	match str(unit.type):
		"garrison":
			color = Color("#d6a06a")
		"arquebusier":
			color = Color("#d5d9e5")
		"support":
			color = Color("#77c3b0")
		"hero":
			color = Color("#e4b84f")
			radius = 22.0
			draw_arc(unit.position, 48.0, 0, TAU, 28, Color(0.89, 0.72, 0.31, 0.25), 2.0)
	if bool(unit.get("traveling", false)):
		color = color.darkened(0.25)
		draw_line(unit.travel_from, unit.travel_to, Color(1, 1, 1, 0.25), 2.0)
	draw_circle(unit.position, radius, color)
	draw_arc(unit.position, radius + 3.0, 0, TAU, 24, Color("#f7e7bd"), 2.0)
	var tag := "H" if str(unit.type) == "hero" else ("S" if str(unit.type) == "support" else "U")
	draw_string(font, unit.position + Vector2(-12, 5), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#17202b"))
	draw_rect(Rect2(unit.position + Vector2(-18, radius + 7), Vector2(36, 4)), Color("#4a2028"))
	draw_rect(Rect2(unit.position + Vector2(-18, radius + 7), Vector2(36.0 * float(unit.hp) / 100.0, 4)), Color("#6fc287"))


func _draw_enemy(enemy: Dictionary) -> void:
	var pos: Vector2 = enemy.position
	var hp: float = float(enemy.hp)
	var max_hp: float = float(enemy.get("max_hp", 55.0))
	draw_circle(pos, 13.0, Color("#b74845"))
	draw_circle(pos, 5.0, Color("#f0c27b"))
	draw_rect(Rect2(pos + Vector2(-14, 18), Vector2(28, 3)), Color("#401c29"))
	draw_rect(Rect2(pos + Vector2(-14, 18), Vector2(28.0 * hp / max_hp, 3)), Color("#e1775d"))


func _draw_hud() -> void:
	var phase_labels: PackedStringArray = PackedStringArray([
		"BUILD / POSITION", "COMBAT / RESOURCES", "VICTORY", "DEFEAT"
	])
	var phase_label: String = phase_labels[clampi(phase, 0, phase_labels.size() - 1)]
	draw_rect(Rect2(0, 590, 1280, 130), Color("#11151d"))
	draw_string(font, Vector2(40, 625), "PHASE: %s" % phase_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#f4dfb7"))
	draw_string(font, Vector2(40, 654), message, HORIZONTAL_ALIGNMENT_LEFT, 840, 15, Color("#cbd6e9"))
	var help := "1–4 units • click land/sea • SPACE combat • E flare • hero click→click redeploy • S save"
	if phase == Phase.BUILD:
		help = "Build timer: %.0fs — place both fronts then combat  |  %s" % [maxf(0.0, build_time_left), help]
	draw_string(font, Vector2(40, 684), help, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#8493ab"))
	draw_string(font, Vector2(930, 625), "MAIN HQ", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bdc7d9"))
	draw_rect(Rect2(930, 638, 220, 12), Color("#46232c"))
	draw_rect(Rect2(930, 638, 220.0 * float(_hq()) / float(_hq_max()), 12), Color("#d27b62"))
	draw_string(font, Vector2(930, 679), "LAND %02d  SEA %02d  FOE %02d  KILLS %02d  WAVE %d" % [
		_land_res(), _sea_res(), _raider_count(), _kills(), wave_number
	], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#d6dfed"))


func _draw_button(rect: Rect2, label: String, color: Color) -> void:
	draw_rect(rect, color)
	draw_rect(rect, color.lightened(0.25), false, 2.0)
	draw_string(font, rect.position + Vector2(12, 30), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 13, Color("#f4ead3"))
