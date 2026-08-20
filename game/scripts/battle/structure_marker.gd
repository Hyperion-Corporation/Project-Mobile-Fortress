class_name StructureMarker
extends Node2D
## HQ or outpost marker (ukiyo-e readable blocks).

enum Kind { HQ, RESOURCE_OUTPOST, TRADING_OUTPOST }

var kind: Kind = Kind.HQ
var front_id: String = "land"
var hp: float = 50.0
var max_hp: float = 50.0
var alive: bool = true
var battle: Node = null


func setup(p_kind: Kind, p_front: String, p_battle: Node) -> void:
	kind = p_kind
	front_id = p_front
	battle = p_battle
	match kind:
		Kind.HQ:
			max_hp = 100.0
		_:
			max_hp = 40.0
	hp = max_hp
	_build()


func _build() -> void:
	var col: Color
	var size := Vector2(36, 36)
	match kind:
		Kind.HQ:
			col = UnitDefs.PALETTE["hq"]
			size = Vector2(44, 44)
		Kind.RESOURCE_OUTPOST:
			col = UnitDefs.PALETTE["outpost"]
		Kind.TRADING_OUTPOST:
			col = UnitDefs.PALETTE["gold"]
	var body := ColorRect.new()
	body.size = size
	body.position = -size * 0.5
	body.color = col
	add_child(body)
	var edge := Line2D.new()
	edge.width = 2.0
	edge.default_color = UnitDefs.PALETTE["ink"]
	var half := size * 0.5
	edge.points = PackedVector2Array([
		-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y), -half
	])
	add_child(edge)
	var lbl := Label.new()
	match kind:
		Kind.HQ:
			lbl.text = "HQ"
		Kind.RESOURCE_OUTPOST:
			lbl.text = "Res"
		Kind.TRADING_OUTPOST:
			lbl.text = "Trade"
	lbl.position = Vector2(-14, -8)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", UnitDefs.PALETTE["paper"])
	add_child(lbl)


func take_damage(amount: float) -> void:
	if not alive:
		return
	if kind == Kind.HQ:
		GameSession.damage_hq(int(amount))
		return
	hp -= amount
	if hp <= 0.0:
		alive = false
		modulate = Color(0.4, 0.4, 0.4, 0.7)
		GameSession.outposts_lost += 1
		# Economic only — income drops, no instant loss
		if battle and battle.has_method("on_outpost_lost"):
			battle.on_outpost_lost(self)
