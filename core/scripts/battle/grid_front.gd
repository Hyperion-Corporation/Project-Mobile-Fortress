class_name GridFront
extends Node2D
## One environment grid (land or sea) with cells, placement, and lane path.

signal cell_clicked(front_id: String, cell: Vector2i)

const CELL := 48.0

@export var front_id: String = "land" ## "land" | "sea"
@export var cols: int = 10
@export var rows: int = 6

var origin: Vector2 = Vector2.ZERO
var blocked: Dictionary = {} ## Vector2i -> true (structures)
var occupants: Dictionary = {} ## Vector2i -> Node
var path_cells: Array[Vector2i] = []

var _bg: ColorRect
var _label: Label


func setup(p_origin: Vector2, p_front: String, p_cols: int = 10, p_rows: int = 6) -> void:
	origin = p_origin
	front_id = p_front
	cols = p_cols
	rows = p_rows
	position = origin
	_build_visuals()
	_build_default_lane()


func _build_visuals() -> void:
	for c in get_children():
		if c is ColorRect:
			c.queue_free()

	var pal := UnitDefs.PALETTE
	var tm: TileMap = get_parent().get_node_or_null("LandMap") if front_id == "land" else get_parent().get_node_or_null("SeaMap")
	if tm:
		tm.clear()
		# Grass: (0,0), Water: (1,0), Path/Blocked: (0,1)
		var base_tile = Vector2i(0, 0) if front_id == "land" else Vector2i(1, 0)
		var path_tile = Vector2i(0, 1)

		for y in rows:
			for x in cols:
				var cell = Vector2i(x, y)
				if path_cells.has(cell):
					tm.set_cell(0, cell, 0, path_tile)
				else:
					tm.set_cell(0, cell, 0, base_tile)

	_label = Label.new()
	_label.text = "LAND — Ming coast" if front_id == "land" else "SEA — Portuguese guns"
	_label.position = Vector2(4, -28)
	_label.add_theme_color_override("font_color", pal["ink"])
	_label.add_theme_font_size_override("font_size", 16)
	add_child(_label)


func _build_default_lane() -> void:
	path_cells.clear()
	# Spawn from left, walk right along mid row toward HQ edge (right side)
	var mid := rows / 2
	for x in cols:
		path_cells.append(Vector2i(x, mid))
	# Rebuild visuals so lane shows
	if is_inside_tree():
		_build_visuals()


func world_to_cell(global_pos: Vector2) -> Vector2i:
	var tm: TileMap = get_parent().get_node_or_null("LandMap") if front_id == "land" else get_parent().get_node_or_null("SeaMap")
	if tm:
		var local = tm.to_local(global_pos)
		return tm.local_to_map(local)
	return Vector2i.ZERO


func cell_to_local_center(cell: Vector2i) -> Vector2:
	var tm: TileMap = get_parent().get_node_or_null("LandMap") if front_id == "land" else get_parent().get_node_or_null("SeaMap")
	if tm:
		return tm.map_to_local(cell)
	return Vector2.ZERO


func cell_to_global_center(cell: Vector2i) -> Vector2:
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
	# Keep lane mostly clear except last cells near HQ (defensive line)
	if path_cells.has(cell) and cell.x < cols - 3:
		return false
	return true


func block_cell(cell: Vector2i) -> void:
	blocked[cell] = true


func set_occupant(cell: Vector2i, node: Node) -> void:
	occupants[cell] = node


func clear_occupant(cell: Vector2i) -> void:
	occupants.erase(cell)


func path_world_points() -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for c in path_cells:
		pts.append(cell_to_global_center(c))
	return pts


func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var cell := world_to_cell(get_global_mouse_position())
			if in_bounds(cell):
				cell_clicked.emit(front_id, cell)
