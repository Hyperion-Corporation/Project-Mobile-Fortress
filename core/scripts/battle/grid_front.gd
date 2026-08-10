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
		c.queue_free()

	var pal := UnitDefs.PALETTE
	var base_col: Color = pal["land"] if front_id == "land" else pal["sea"]
	var deep: Color = pal["land_deep"] if front_id == "land" else pal["sea_deep"]

	_bg = ColorRect.new()
	_bg.size = Vector2(cols * CELL, rows * CELL)
	_bg.color = base_col.darkened(0.15)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_bg.gui_input.connect(_on_bg_input)
	add_child(_bg)

	# Cell grid lines + checker
	for y in rows:
		for x in cols:
			var cell := ColorRect.new()
			cell.size = Vector2(CELL - 2, CELL - 2)
			cell.position = Vector2(x * CELL + 1, y * CELL + 1)
			var tint := 0.0 if (x + y) % 2 == 0 else 0.08
			cell.color = base_col.lightened(tint)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(cell)

	# Lane highlight
	for p in path_cells:
		var lane := ColorRect.new()
		lane.size = Vector2(CELL - 8, CELL - 8)
		lane.position = Vector2(p.x * CELL + 4, p.y * CELL + 4)
		lane.color = deep.lightened(0.35)
		lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lane.z_index = 1
		add_child(lane)

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
	var local := global_pos - global_position
	var cx := int(floor(local.x / CELL))
	var cy := int(floor(local.y / CELL))
	return Vector2i(cx, cy)


func cell_to_local_center(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * CELL, (cell.y + 0.5) * CELL)


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
