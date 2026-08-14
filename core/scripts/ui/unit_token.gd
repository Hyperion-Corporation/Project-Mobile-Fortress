class_name UnitToken
extends Node2D
## 2.5D Isometric Unit & Outpost Token Renderer (U9 / U10)
## Procedural vector silhouettes matching Wōkòu-era ukiyo-e cartography.

const PALETTE := {
	"ink": Color("1a1a2e"),
	"paper": Color("f4e9d8"),
	"land": Color("6b8f71"),
	"land_deep": Color("3d5c45"),
	"sea": Color("3d5a80"),
	"sea_deep": Color("1b3a4b"),
	"vermillion": Color("c23b22"),
	"gold": Color("c9a227"),
	"ochre": Color("c4842d"),
	"wokou": Color("2b2b2b"),
	"wokou_sail": Color("8b1e1e"),
	"hq": Color("5c4033"),
	"outpost": Color("a67c52"),
}

var unit_type: String = "spearman"
var is_raider: bool = false
var front_id: int = 0
var is_hero: bool = false
var is_traveling: bool = false
var is_selected: bool = false
var hp_ratio: float = 1.0
var size_radius: float = 14.0

var primary_color: Color = Color.CORNFLOWER_BLUE
var accent_color: Color = Color.WHITE


func setup_defender(utype: String, udef: Dictionary) -> void:
	unit_type = utype
	is_raider = false
	is_hero = UnitDefs.is_hero(utype)
	front_id = int(udef.get("front", 0))
	primary_color = udef.get("color", PALETTE["vermillion"])
	accent_color = PALETTE["gold"] if is_hero else PALETTE["paper"]
	size_radius = 18.0 if is_hero else 13.0
	queue_redraw()


func setup_raider(front: int) -> void:
	front_id = front
	is_raider = true
	is_hero = false
	unit_type = "raider_land" if front == 0 else "raider_sea"
	primary_color = PALETTE["wokou"] if front == 0 else PALETTE["wokou_sail"]
	accent_color = PALETTE["vermillion"] if front == 0 else PALETTE["gold"]
	size_radius = 10.0
	queue_redraw()


func setup_outpost(front: int) -> void:
	front_id = front
	is_raider = false
	is_hero = false
	unit_type = "outpost"
	primary_color = PALETTE["gold"] if front == 0 else Color(0.2, 0.7, 0.85, 1)
	accent_color = PALETTE["paper"]
	size_radius = 20.0
	queue_redraw()


func set_traveling(traveling: bool) -> void:
	if is_traveling != traveling:
		is_traveling = traveling
		queue_redraw()


func set_selected(selected: bool) -> void:
	if is_selected != selected:
		is_selected = selected
		queue_redraw()


func set_hp_ratio(ratio: float) -> void:
	var r := clampf(ratio, 0.0, 1.0)
	if abs(hp_ratio - r) > 0.05:
		hp_ratio = r
		queue_redraw()


func _draw() -> void:
	# 1. Base drop shadow on ground
	draw_circle(Vector2(0, 4), size_radius * 0.9, Color(0, 0, 0, 0.35))

	if is_raider:
		_draw_raider()
	elif unit_type == "outpost":
		_draw_outpost()
	else:
		_draw_defender()


func _draw_defender() -> void:
	# Outer selection ring
	if is_selected:
		draw_arc(Vector2.ZERO, size_radius + 6, 0, TAU, 24, PALETTE["gold"], 2.5)

	# Hero Aura Glow
	if is_hero:
		draw_circle(Vector2.ZERO, size_radius + 4, Color(primary_color.r, primary_color.g, primary_color.b, 0.25))
		draw_arc(Vector2.ZERO, size_radius + 3, 0, TAU, 32, accent_color, 1.8)

	# Base Token Octagon / Circle
	var base_col := primary_color
	if is_traveling:
		base_col = base_col.lerp(Color(0.5, 0.5, 0.5, 1), 0.5)

	draw_circle(Vector2.ZERO, size_radius, base_col)
	draw_arc(Vector2.ZERO, size_radius, 0, TAU, 24, PALETTE["ink"], 1.5)

	# Inner Emblem / Silhouette glyph
	match unit_type:
		"hero_qi":
			# Commander Qi: Golden Plum Blossom & Command Star
			_draw_star(Vector2.ZERO, 5, 8.0, 4.0, PALETTE["gold"])
			draw_circle(Vector2.ZERO, 3.0, PALETTE["vermillion"])
		"hero_dias":
			# Capitão Dias: Azure Naval Cross & Anchor
			draw_line(Vector2(0, -7), Vector2(0, 7), PALETTE["gold"], 2.5)
			draw_line(Vector2(-6, -2), Vector2(6, -2), PALETTE["gold"], 2.5)
			draw_arc(Vector2(0, 4), 5.0, 0.2, PI - 0.2, 12, PALETTE["gold"], 2.0)
		"spearman":
			# Diamond pike crest
			var pts := PackedVector2Array([Vector2(0, -8), Vector2(6, 0), Vector2(0, 8), Vector2(-6, 0)])
			draw_colored_polygon(pts, PALETTE["paper"])
			draw_line(Vector2(0, -9), Vector2(0, 9), PALETTE["ink"], 1.5)
		"cannon":
			# Swivel cannon barrel & carriage ring
			draw_circle(Vector2.ZERO, 6.0, PALETTE["ink"])
			draw_circle(Vector2.ZERO, 3.5, PALETTE["gold"])
			draw_line(Vector2.ZERO, Vector2(9, -5), PALETTE["ink"], 3.0)
		"arquebusier":
			# Matchlock chevron
			draw_line(Vector2(-7, 4), Vector2(0, -5), PALETTE["paper"], 2.5)
			draw_line(Vector2(7, 4), Vector2(0, -5), PALETTE["paper"], 2.5)
		"junk":
			# War Junk sail wedge
			var sail := PackedVector2Array([Vector2(-6, 6), Vector2(0, -8), Vector2(6, 6)])
			draw_colored_polygon(sail, PALETTE["paper"])
		"cross_support":
			# Signal Battery Beacon
			draw_arc(Vector2.ZERO, 6.0, 0, TAU, 16, PALETTE["gold"], 2.0)
			draw_circle(Vector2.ZERO, 3.0, PALETTE["vermillion"])
		_:
			draw_circle(Vector2.ZERO, 4.0, PALETTE["paper"])


func _draw_raider() -> void:
	# Raider diamond base
	var pts := PackedVector2Array([
		Vector2(0, -size_radius),
		Vector2(size_radius, 0),
		Vector2(0, size_radius),
		Vector2(-size_radius, 0),
	])
	draw_colored_polygon(pts, primary_color)
	draw_polyline(pts, PALETTE["ink"], 1.5)

	# Inner Wōkòu Raider Crest
	if front_id == 0:
		# Nodachi blade slash
		draw_line(Vector2(-5, 5), Vector2(5, -5), PALETTE["vermillion"], 2.0)
	else:
		# Pirate Sail triangle
		var sail := PackedVector2Array([Vector2(-4, 4), Vector2(0, -6), Vector2(4, 4)])
		draw_colored_polygon(sail, PALETTE["gold"])


func _draw_outpost() -> void:
	# Outpost Fortress Bastion (Square Stone Wall)
	var sz := size_radius * 0.9
	var rect := Rect2(-sz, -sz, sz * 2, sz * 2)
	draw_rect(rect, primary_color)
	draw_rect(rect, PALETTE["ink"], false, 2.0)

	# Parapet crenellations (corner battlements)
	draw_rect(Rect2(-sz - 2, -sz - 2, 7, 7), PALETTE["ink"])
	draw_rect(Rect2(sz - 5, -sz - 2, 7, 7), PALETTE["ink"])
	draw_rect(Rect2(-sz - 2, sz - 5, 7, 7), PALETTE["ink"])
	draw_rect(Rect2(sz - 5, sz - 5, 7, 7), PALETTE["ink"])

	# Inner Core Emblem
	draw_circle(Vector2.ZERO, 6.0, PALETTE["paper"])
	draw_circle(Vector2.ZERO, 3.0, primary_color)

	# Health bar above outpost
	var bar_w := sz * 2.2
	var bar_rect := Rect2(-bar_w * 0.5, -sz - 12, bar_w, 4)
	draw_rect(bar_rect, Color(0, 0, 0, 0.6))
	var fill_rect := Rect2(-bar_w * 0.5, -sz - 12, bar_w * hp_ratio, 4)
	var hp_col := PALETTE["land"].lerp(PALETTE["vermillion"], 1.0 - hp_ratio)
	draw_rect(fill_rect, hp_col)


func _draw_star(center: Vector2, rays: int, r_outer: float, r_inner: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var step := TAU / float(rays * 2)
	for i in range(rays * 2):
		var r := r_outer if i % 2 == 0 else r_inner
		var angle := float(i) * step - (PI * 0.5)
		pts.append(center + Vector2(cos(angle) * r, sin(angle) * r))
	draw_colored_polygon(pts, color)
