extends Node2D
## Slice-0 G2: offline dual-front (land + sea) fortress defense.
## Simulation state is plain dictionaries so an S0 godot-cpp extract stays easy.
## Isometric-readable cell layout; ukiyo-e-adjacent palette.

const SAVE_PATH := "user://mobile_fortress_slice0.json"
const RESULTS_PATH := "user://last_run_results.json"
const GRID_ROWS := 3
const GRID_COLUMNS := 5
const CELL_SIZE := Vector2(88.0, 58.0)
const FRONT_ORIGINS := [Vector2(165.0, 260.0), Vector2(790.0, 260.0)]
const FRONT_NAMES := ["LAND FRONT", "SEA FRONT"]
const FRONT_COLORS := [Color("#c8845b"), Color("#4c9bb5")]
## garrison=Ming spear, arquebusier=Portuguese, support=cross-front, hero=commander
const UNIT_TYPES := ["garrison", "arquebusier", "support", "hero"]
const UNIT_LABELS := ["GARRISON", "ARQUEBUS", "SUPPORT", "COMMANDER"]
const UNIT_COSTS := [2, 3, 4, 5]

enum Phase { BUILD, COMBAT, VICTORY, DEFEAT }

var phase: int = Phase.BUILD
var selected_unit := 0
var units: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var cells: Array[Dictionary] = []
var hq_hp := 100.0
var land_resources := 14
var sea_resources := 14
var land_outpost_alive := true
var sea_outpost_alive := true
var combat_time := 0.0
var spawn_time := 0.0
var income_time := 0.0
var message := "BUILD — pick a unit (1–4), click any land/sea cell to place"
var message_time := 0.0
var wave_number := 0
var enemies_killed := 0
var units_placed := 0
var hero_active_cd := 0.0
var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	_build_cells()
	_load_game()
	queue_redraw()


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


func _process(delta: float) -> void:
	if message_time > 0.0:
		message_time -= delta
	hero_active_cd = maxf(0.0, hero_active_cd - delta)

	if phase == Phase.COMBAT:
		combat_time += delta
		spawn_time += delta
		income_time += delta
		if income_time >= 4.0:
			income_time = 0.0
			if land_outpost_alive:
				land_resources += 2
			if sea_outpost_alive:
				sea_resources += 2
		if spawn_time >= 1.5 and enemies.size() < 40:
			spawn_time = 0.0
			_spawn_enemy(0 if wave_number % 2 == 0 else 1)
			if wave_number % 3 == 0:
				_spawn_enemy(1 if wave_number % 2 == 0 else 0)
			wave_number += 1
		_update_units(delta)
		_update_enemies(delta)
		if combat_time >= 45.0 and enemies.is_empty():
			phase = Phase.VICTORY
			message = "VICTORY — both fronts held"
			_export_results(true, message)
			_save_game()

	if phase == Phase.BUILD and Input.is_action_just_pressed("toggle_phase"):
		_start_combat()
	if Input.is_action_just_pressed("save_game"):
		_save_game()
		_set_message("Campaign state saved offline")
	if Input.is_action_just_pressed("load_game"):
		_load_game()
		_set_message("Campaign state loaded offline")
	if Input.is_action_just_pressed("select_unit_1"):
		selected_unit = 0
		_set_message("Selected GARRISON (land currency)")
	if Input.is_action_just_pressed("select_unit_2"):
		selected_unit = 1
		_set_message("Selected ARQUEBUS (sea currency)")
	if Input.is_action_just_pressed("select_unit_3"):
		selected_unit = 2
		_set_message("Selected SUPPORT — cross-front fire, weaker own-front")
	if Input.is_action_just_pressed("select_unit_4"):
		selected_unit = 3
		_set_message("Selected COMMANDER hero — aura + active [E]")
	if Input.is_action_just_pressed("hero_ability"):
		_try_hero_ability()
	queue_redraw()


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
			phase = Phase.BUILD
			enemies.clear()
			_set_message("BUILD PHASE — reinforce (enemies cleared for slice prototype)")
		elif phase == Phase.VICTORY or phase == Phase.DEFEAT:
			_reset_run()
		return
	if Rect2(40, 24, 210, 48).has_point(click):
		_save_game()
		_set_message("Campaign state saved offline")
		return
	for index in range(UNIT_TYPES.size()):
		if Rect2(280 + index * 150, 24, 138, 48).has_point(click):
			selected_unit = index
			_set_message("Selected %s — cost %d" % [UNIT_LABELS[index], UNIT_COSTS[index]])
			return
	if phase != Phase.BUILD:
		return
	# Place on whichever front's cell was clicked (dual-front SP control)
	for index in range(cells.size()):
		var cell: Dictionary = cells[index]
		if int(cell.occupied) != -1:
			continue
		if _diamond_contains(click, cell.position, CELL_SIZE * 0.48):
			_place_unit(index)
			return


func _diamond_contains(point: Vector2, center: Vector2, radius: Vector2) -> bool:
	var normalized := (point - center) / radius
	return absf(normalized.x) + absf(normalized.y) <= 1.0


func _place_unit(cell_index: int) -> void:
	var cell: Dictionary = cells[cell_index]
	var front: int = int(cell.front)
	var utype: String = UNIT_TYPES[selected_unit]
	# Garrison prefers land currency; arquebus prefers sea; others flexible
	var prefer_land := utype == "garrison" or (utype != "arquebusier" and front == 0)
	var cost: int = UNIT_COSTS[selected_unit]
	if prefer_land:
		if land_resources < cost:
			_set_message("Not enough land resources")
			return
		land_resources -= cost
	else:
		if sea_resources < cost:
			_set_message("Not enough sea resources")
			return
		sea_resources -= cost

	var unit := {
		"type": utype,
		"front": front,
		"cell": cell_index,
		"position": cell.position,
		"hp": 100.0,
		"cooldown": 0.0,
	}
	units.append(unit)
	cells[cell_index].occupied = units.size() - 1
	units_placed += 1
	_set_message("%s deployed on %s" % [UNIT_LABELS[selected_unit], FRONT_NAMES[front]])


func _start_combat() -> void:
	if units.is_empty():
		_set_message("Deploy at least one unit before combat")
		return
	phase = Phase.COMBAT
	combat_time = 0.0
	spawn_time = 0.0
	income_time = 0.0
	wave_number = 0
	_set_message("COMBAT — defend land and sea lanes")


func _spawn_enemy(front: int) -> void:
	var path_start := _cell_position(front, 0, 0) - Vector2(0, 90)
	enemies.append({
		"front": front,
		"position": path_start,
		"hp": 55.0,
		"speed": 25.0 + float(wave_number % 4) * 3.0,
		"damage": 6.0,
	})


func _update_units(delta: float) -> void:
	for unit in units:
		unit.cooldown = maxf(0.0, float(unit.cooldown) - delta)
		if float(unit.cooldown) > 0.0:
			continue
		var target = _nearest_enemy(unit)
		if target == null:
			continue
		var damage := 18.0
		var atk_range := 150.0
		var own_mult := 1.0
		var cross_mult := 0.0
		match str(unit.type):
			"garrison":
				damage = 24.0
				own_mult = 1.0
				cross_mult = 0.0
			"arquebusier":
				damage = 15.0
				atk_range = 235.0
				own_mult = 1.0
				cross_mult = 0.2
			"support":
				# Cross-front specialist: weak own env, strong other env
				damage = 12.0
				atk_range = 340.0
				own_mult = 0.55
				cross_mult = 1.2
			"hero":
				damage = 14.0
				atk_range = 260.0
				own_mult = 1.0
				cross_mult = 0.45
		var same: bool = int(unit.front) == int(target.front)
		var mult: float = own_mult if same else cross_mult
		if mult <= 0.0:
			continue
		if unit.position.distance_to(target.position) <= atk_range:
			# Hero aura damage bonus
			damage *= mult * (1.0 + _aura_bonus(unit.position))
			target.hp -= damage
			unit.cooldown = 0.75 if str(unit.type) != "hero" else 1.1
			if str(unit.type) == "hero":
				for ally in units:
					if ally.position.distance_to(unit.position) < 150.0:
						ally.hp = minf(100.0, float(ally.hp) + 2.0)
			if float(target.hp) <= 0.0:
				enemies.erase(target)
				enemies_killed += 1


func _aura_bonus(at: Vector2) -> float:
	var bonus := 0.0
	for unit in units:
		if str(unit.type) == "hero" and unit.position.distance_to(at) < 160.0:
			bonus += 0.2
	return bonus


func _try_hero_ability() -> void:
	if phase != Phase.COMBAT:
		return
	if hero_active_cd > 0.0:
		_set_message("Hero ability cooling down (%.0fs)" % hero_active_cd)
		return
	var heroes: Array = []
	for unit in units:
		if str(unit.type) == "hero":
			heroes.append(unit)
	if heroes.is_empty():
		_set_message("No commander on the field")
		return
	hero_active_cd = 8.0
	for hero in heroes:
		for enemy in enemies.duplicate():
			if hero.position.distance_to(enemy.position) < 200.0:
				enemy.hp -= 28.0
				if float(enemy.hp) <= 0.0:
					enemies.erase(enemy)
					enemies_killed += 1
	_set_message("Commander signal flare — nearby raiders scorched")


func _nearest_enemy(unit: Dictionary):
	var closest = null
	var best_distance := INF
	for enemy in enemies:
		var same: bool = int(unit.front) == int(enemy.front)
		var ut := str(unit.type)
		if not same and ut != "support" and ut != "hero" and ut != "arquebusier":
			continue
		var distance: float = unit.position.distance_to(enemy.position)
		if distance < best_distance:
			best_distance = distance
			closest = enemy
	return closest


func _update_enemies(delta: float) -> void:
	for enemy in enemies.duplicate():
		if float(enemy.hp) <= 0.0:
			enemies.erase(enemy)
			enemies_killed += 1
			continue
		var front: int = int(enemy.front)
		var target := _cell_position(front, GRID_ROWS - 1, GRID_COLUMNS - 1) + Vector2(0, 75)
		# Threaten outpost when passing mid cell
		var mid := _cell_position(front, 1, 2)
		if enemy.position.distance_to(mid) < 28.0:
			if front == 0 and land_outpost_alive and randf() < 0.02:
				land_outpost_alive = false
				_set_message("Resource Outpost lost — land income reduced (economic only)")
			elif front == 1 and sea_outpost_alive and randf() < 0.02:
				sea_outpost_alive = false
				_set_message("Trading Outpost lost — sea income reduced (economic only)")
		enemy.position = enemy.position.move_toward(target, float(enemy.speed) * delta)
		if enemy.position.distance_to(target) < 10.0:
			hq_hp -= float(enemy.get("damage", 6.0))
			enemies.erase(enemy)
			if hq_hp <= 0.0:
				phase = Phase.DEFEAT
				message = "DEFEAT — the Main HQ fell"
				_export_results(false, message)
				_save_game()


func _set_message(value: String) -> void:
	message = value
	message_time = 3.5


func _reset_run() -> void:
	phase = Phase.BUILD
	units.clear()
	enemies.clear()
	hq_hp = 100.0
	land_resources = 14
	sea_resources = 14
	land_outpost_alive = true
	sea_outpost_alive = true
	combat_time = 0.0
	enemies_killed = 0
	units_placed = 0
	hero_active_cd = 0.0
	for cell in cells:
		cell.occupied = -1
	_set_message("New raid — rebuild the dual front")


func _save_game() -> void:
	var saved_units: Array = []
	for unit in units:
		saved_units.append({
			"type": unit.type,
			"front": unit.front,
			"cell": unit.cell,
			"hp": unit.hp,
			"cooldown": unit.cooldown,
		})
	var payload := {
		"phase": int(phase),
		"selected_unit": selected_unit,
		"hq_hp": hq_hp,
		"land_resources": land_resources,
		"sea_resources": sea_resources,
		"land_outpost_alive": land_outpost_alive,
		"sea_outpost_alive": sea_outpost_alive,
		"units": saved_units,
		"units_placed": units_placed,
		"enemies_killed": enemies_killed,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))


func _export_results(victory: bool, reason: String) -> void:
	var payload := {
		"victory": victory,
		"reason": reason,
		"enemies_killed": enemies_killed,
		"units_placed": units_placed,
		"land_outpost_alive": land_outpost_alive,
		"sea_outpost_alive": sea_outpost_alive,
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
	phase = int(parsed.get("phase", Phase.BUILD))
	if phase == Phase.COMBAT:
		phase = Phase.BUILD # reload into build for safety
	selected_unit = int(parsed.get("selected_unit", 0))
	hq_hp = float(parsed.get("hq_hp", 100.0))
	land_resources = int(parsed.get("land_resources", 14))
	sea_resources = int(parsed.get("sea_resources", 14))
	land_outpost_alive = bool(parsed.get("land_outpost_alive", true))
	sea_outpost_alive = bool(parsed.get("sea_outpost_alive", true))
	units_placed = int(parsed.get("units_placed", 0))
	enemies_killed = int(parsed.get("enemies_killed", 0))
	units.clear()
	enemies.clear()
	for cell in cells:
		cell.occupied = -1
	for saved_unit in parsed.get("units", []):
		if saved_unit is Dictionary:
			var loaded_unit: Dictionary = (saved_unit as Dictionary).duplicate()
			var loaded_cell: int = int(loaded_unit.get("cell", -1))
			if loaded_cell >= 0 and loaded_cell < cells.size():
				loaded_unit["position"] = cells[loaded_cell].position
				cells[loaded_cell].occupied = units.size()
				units.append(loaded_unit)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("#171b25"))
	draw_string(font, Vector2(40, 105), "MOBILE FORTRESS", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#f4dfb7"))
	draw_string(font, Vector2(40, 132), "WŌKÒU COAST • MING + PORTUGUESE • SLICE-0 DUAL-FRONT", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#bdc7d9"))
	_draw_button(Rect2(40, 24, 210, 48), "SAVE  [S]", Color("#34465e"))
	for index in range(UNIT_TYPES.size()):
		var color := Color("#b98252") if index == selected_unit else Color("#293244")
		_draw_button(Rect2(280 + index * 150, 24, 138, 48), "%s [%d]" % [UNIT_LABELS[index], index + 1], color)
	var phase_btn := "START COMBAT  [SPACE]"
	if phase == Phase.COMBAT:
		phase_btn = "TO BUILD (clear raid)"
	elif phase == Phase.VICTORY or phase == Phase.DEFEAT:
		phase_btn = "PLAY AGAIN"
	_draw_button(Rect2(1040, 24, 200, 48), phase_btn, Color("#8e493c"))
	_draw_front(0)
	_draw_front(1)
	_draw_hud()


func _draw_front(front: int) -> void:
	draw_string(font, FRONT_ORIGINS[front] + Vector2(-110, -72), FRONT_NAMES[front], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, FRONT_COLORS[front].lightened(0.35))
	var outpost_txt := "ONLINE" if (land_outpost_alive if front == 0 else sea_outpost_alive) else "LOST (econ)"
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
		if int(cell.occupied) == -1 and phase == Phase.BUILD:
			cell_color = cell_color.lightened(0.16)
		draw_colored_polygon(points, cell_color)
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), FRONT_COLORS[front].darkened(0.2), 2.0)
	for unit in units:
		if int(unit.front) == front:
			_draw_unit(unit)
	for enemy in enemies:
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
	draw_circle(unit.position, radius, color)
	draw_arc(unit.position, radius + 3.0, 0, TAU, 24, Color("#f7e7bd"), 2.0)
	var tag := "H" if str(unit.type) == "hero" else ("S" if str(unit.type) == "support" else "U")
	draw_string(font, unit.position + Vector2(-12, 5), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#17202b"))
	draw_rect(Rect2(unit.position + Vector2(-18, radius + 7), Vector2(36, 4)), Color("#4a2028"))
	draw_rect(Rect2(unit.position + Vector2(-18, radius + 7), Vector2(36.0 * float(unit.hp) / 100.0, 4)), Color("#6fc287"))


func _draw_enemy(enemy: Dictionary) -> void:
	draw_circle(enemy.position, 13.0, Color("#b74845"))
	draw_circle(enemy.position, 5.0, Color("#f0c27b"))
	draw_rect(Rect2(enemy.position + Vector2(-14, 18), Vector2(28, 3)), Color("#401c29"))
	draw_rect(Rect2(enemy.position + Vector2(-14, 18), Vector2(28.0 * float(enemy.hp) / 55.0, 3)), Color("#e1775d"))


func _draw_hud() -> void:
	var phase_labels: PackedStringArray = PackedStringArray([
		"BUILD / POSITION", "COMBAT / RESOURCES", "VICTORY", "DEFEAT"
	])
	var phase_label: String = phase_labels[clampi(phase, 0, phase_labels.size() - 1)]
	draw_rect(Rect2(0, 590, 1280, 130), Color("#11151d"))
	draw_string(font, Vector2(40, 625), "PHASE: %s" % phase_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#f4dfb7"))
	draw_string(font, Vector2(40, 654), message, HORIZONTAL_ALIGNMENT_LEFT, 840, 15, Color("#cbd6e9"))
	draw_string(font, Vector2(40, 684), "1–4 units  •  click land OR sea cell  •  SPACE combat  •  E hero ability  •  S/L save load", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#8493ab"))
	draw_string(font, Vector2(930, 625), "MAIN HQ", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bdc7d9"))
	draw_rect(Rect2(930, 638, 220, 12), Color("#46232c"))
	draw_rect(Rect2(930, 638, 220.0 * hq_hp / 100.0, 12), Color("#d27b62"))
	draw_string(font, Vector2(930, 679), "LAND %02d   SEA %02d   ENEMIES %02d   KILLS %02d" % [land_resources, sea_resources, enemies.size(), enemies_killed], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#d6dfed"))


func _draw_button(rect: Rect2, label: String, color: Color) -> void:
	draw_rect(rect, color)
	draw_rect(rect, color.lightened(0.25), false, 2.0)
	draw_string(font, rect.position + Vector2(12, 30), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 13, Color("#f4ead3"))
