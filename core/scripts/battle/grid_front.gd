class_name GridFront
extends Node2D
## One environment grid (land or sea): tiles, lane path, placement clicks.

signal cell_clicked(front_id: String, cell: Vector2i)

const ThemeTokensScript := preload("res://scripts/ui/theme_tokens.gd")

@export var front_id: String = "land" ## "land" | "sea"
@export var cols: int = 8
@export var rows: int = 5

var origin: Vector2 = Vector2.ZERO
var blocked: Dictionary = {} ## Vector2i -> true
var occupants: Dictionary = {} ## Vector2i -> defender_id (int)
var path_cells: Array[Vector2i] = []
var _tilemap: TileMap = null
var _label: Label
var _click_area: Control


func setup(p_origin: Vector2, p_front: String, p_cols: int = 8, p_rows: int = 5) -> void:
	origin = p_origin
	front_id = p_front
	cols = p_cols
	rows = p_rows
	position = origin
	_tilemap = get_parent().get_node_or_null("LandMap") if front_id == "land" else get_parent().get_node_or_null("SeaMap")
	_build_default_lane()
	_build_visuals()
	_ensure_click_layer()
	block_cell(Vector2i(4, 2))


func _build_default_lane() -> void:
	path_cells.clear()
	var mid := rows / 2
	for x in cols:
		path_cells.append(Vector2i(x, mid))


func _build_visuals() -> void:
	if _tilemap:
		_tilemap.clear()
		var path_tile := Vector2i(0, 1)
		for y in rows:
			for x in cols:
				var cell := Vector2i(x, y)
				if path_cells.has(cell):
					_tilemap.set_cell(0, cell, 0, path_tile)
				else:
					var tile := _get_environmental_tile(cell)
					_tilemap.set_cell(0, cell, 0, tile)
	if _label and is_instance_valid(_label):
		_label.queue_free()
	_label = Label.new()
	_label.text = "LAND — Ming Coast (🌾 糧倉)" if front_id == "land" else "SEA — Portuguese Waters (⛵ 港埠)"
	_label.position = Vector2(4, -32)
	_label.add_theme_color_override("font_color", ThemeTokensScript.INK)
	_label.add_theme_font_size_override("font_size", 15)
	add_child(_label)
	queue_redraw()


func _get_environmental_tile(cell: Vector2i) -> Vector2i:
	if cell == Vector2i(4, 2):
		return Vector2i(2, 1) if front_id == "land" else Vector2i(2, 0)
	var h: int = ((cell.x * 73856093) ^ (cell.y * 19349663)) & 0x7FFFFFFF
	var r := h % 10
	if front_id == "land":
		# Tidal marsh / wetland along coastal transition
		if cell.y >= rows - 2 and r < 3:
			return Vector2i(1, 1) # Tidal marsh / wetland
		# Bastion elevation ridge near fortification lines
		if cell.x >= cols - 2 and r < 2:
			return Vector2i(2, 1) # Elevation bastion masonry
		return Vector2i(0, 0) # Ming farmland / coastal earth
	else:
		# Shallow reef / shoals with wave foam along shoreline
		if cell.y <= 1 and r < 4:
			return Vector2i(2, 0) # Ocean shoal / shallow reef
		return Vector2i(1, 0) # Deep sea ocean waters


func _draw() -> void:
	if _tilemap == null or _tilemap.tile_set == null:
		return
	var ts: Vector2 = Vector2(_tilemap.tile_set.tile_size)
	var half_w: float = ts.x * 0.5
	var half_h: float = ts.y * 0.5

	# 1. Subtle isometric tile grid lines for cartographic precision
	var grid_col := Color(ThemeTokensScript.INK.r, ThemeTokensScript.INK.g, ThemeTokensScript.INK.b, 0.08)
	for y in rows:
		for x in cols:
			var cell := Vector2i(x, y)
			var local_center := cell_to_local_center(cell)
			var pts := PackedVector2Array([
				local_center + Vector2(0, -half_h),
				local_center + Vector2(half_w, 0),
				local_center + Vector2(0, half_h),
				local_center + Vector2(-half_w, 0),
				local_center + Vector2(0, -half_h),
			])
			draw_polyline(pts, grid_col, 1.0)

	# 2. Outpost perimeter bastion highlight (cell (4,2))
	var op_cell := Vector2i(4, 2)
	var op_center := cell_to_local_center(op_cell)
	var op_pts := PackedVector2Array([
		op_center + Vector2(0, -half_h - 2),
		op_center + Vector2(half_w + 4, 0),
		op_center + Vector2(0, half_h + 2),
		op_center + Vector2(-half_w - 4, 0),
		op_center + Vector2(0, -half_h - 2),
	])
	var op_color := ThemeTokensScript.GOLD if front_id == "land" else ThemeTokensScript.SEA_INDIGO_BRIGHT
	draw_polyline(op_pts, Color(op_color.r, op_color.g, op_color.b, 0.4), 2.0)

	# 3. Ukiyo-e wave foam & elevation contours
	if front_id == "sea":
		var wave_col := Color(ThemeTokensScript.PAPER.r, ThemeTokensScript.PAPER.g, ThemeTokensScript.PAPER.b, 0.3)
		for x in range(0, cols, 2):
			var c1 := cell_to_local_center(Vector2i(x, 0))
			draw_arc(c1 + Vector2(0, -6), 10.0, 0.1, PI - 0.1, 8, wave_col, 1.5)
	else:
		var grass_col := Color(ThemeTokensScript.MOSS_LAND_BRIGHT.r, ThemeTokensScript.MOSS_LAND_BRIGHT.g, ThemeTokensScript.MOSS_LAND_BRIGHT.b, 0.25)
		for x in range(1, cols, 2):
			var c1 := cell_to_local_center(Vector2i(x, rows - 1))
			draw_line(c1 + Vector2(-6, 3), c1 + Vector2(0, -5), grass_col, 1.5)
			draw_line(c1 + Vector2(0, -5), c1 + Vector2(6, 3), grass_col, 1.5)



func _ensure_click_layer() -> void:
	if _click_area and is_instance_valid(_click_area):
		_click_area.queue_free()
	_click_area = Control.new()
	# Approximate orthographic bounds covering the tilemap footprint
	var tile_w := 64.0
	var tile_h := 32.0
	if _tilemap and _tilemap.tile_set:
		var ts: Vector2i = _tilemap.tile_set.tile_size
		tile_w = float(ts.x)
		tile_h = float(ts.y)
	_click_area.position = Vector2(-tile_w, -tile_h)
	_click_area.size = Vector2(cols * tile_w * 0.85 + tile_w, rows * tile_h * 0.85 + tile_h * 2.0)
	_click_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_click_area.gui_input.connect(_on_click_input)
	add_child(_click_area)


func _on_click_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var cell := world_to_cell(get_global_mouse_position())
			if in_bounds(cell):
				cell_clicked.emit(front_id, cell)


func world_to_cell(global_pos: Vector2) -> Vector2i:
	if _tilemap:
		var local: Vector2 = _tilemap.to_local(global_pos)
		return _tilemap.local_to_map(local)
	return Vector2i(-1, -1)


func cell_to_local_center(cell: Vector2i) -> Vector2:
	if _tilemap:
		return _tilemap.map_to_local(cell)
	return Vector2(cell.x * 48.0, cell.y * 48.0)


func cell_to_global_center(cell: Vector2i) -> Vector2:
	if _tilemap:
		return _tilemap.to_global(cell_to_local_center(cell))
	return global_position + cell_to_local_center(cell)


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < cols and cell.y < rows


func is_placeable(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return false
	if blocked.has(cell):
		return false
	if occupants.has(cell):
		return false
	# Keep mid-lane clear except last few cells (defensive line)
	if path_cells.has(cell) and cell.x < cols - 3:
		return false
	return true


func block_cell(cell: Vector2i) -> void:
	blocked[cell] = true


func set_occupant(cell: Vector2i, defender_id: int) -> void:
	occupants[cell] = defender_id


func clear_occupant(cell: Vector2i) -> void:
	occupants.erase(cell)


func path_world_points() -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	# Spawn slightly off-map left of first path cell
	if path_cells.size() > 0:
		var first: Vector2 = cell_to_global_center(path_cells[0])
		pts.append(first + Vector2(-48, 0))
	for c in path_cells:
		pts.append(cell_to_global_center(c))
	# HQ approach past last cell
	if path_cells.size() > 0:
		var last: Vector2 = cell_to_global_center(path_cells[path_cells.size() - 1])
		pts.append(last + Vector2(64, 0))
	return pts
