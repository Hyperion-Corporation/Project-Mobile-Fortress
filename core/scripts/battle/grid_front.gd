class_name GridFront
extends Node2D
## One environment grid (land or sea): tiles, lane path, placement clicks.

signal cell_clicked(front_id: String, cell: Vector2i)

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


func _build_default_lane() -> void:
	path_cells.clear()
	var mid := rows / 2
	for x in cols:
		path_cells.append(Vector2i(x, mid))


func _build_visuals() -> void:
	if _tilemap:
		_tilemap.clear()
		var base_tile := Vector2i(0, 0) if front_id == "land" else Vector2i(1, 0)
		var path_tile := Vector2i(0, 1)
		for y in rows:
			for x in cols:
				var cell := Vector2i(x, y)
				if path_cells.has(cell):
					_tilemap.set_cell(0, cell, 0, path_tile)
				else:
					_tilemap.set_cell(0, cell, 0, base_tile)
	if _label and is_instance_valid(_label):
		_label.queue_free()
	_label = Label.new()
	_label.text = "LAND — Ming coast" if front_id == "land" else "SEA — Portuguese guns"
	_label.position = Vector2(4, -32)
	_label.add_theme_color_override("font_color", UnitDefs.PALETTE["ink"])
	_label.add_theme_font_size_override("font_size", 16)
	add_child(_label)


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
