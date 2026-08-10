class_name Raider
extends Node2D
## Enemy walking a front's lane path toward HQ.

var unit_id: String = ""
var def: Dictionary = {}
var front_id: String = "land"
var hp: float = 1.0
var max_hp: float = 1.0
var path: PackedVector2Array = []
var path_i: int = 0
var battle: Node = null
var _body: Polygon2D


func setup(p_id: String, p_front: String, p_path: PackedVector2Array, p_battle: Node) -> void:
	unit_id = p_id
	def = UnitDefs.get_def(p_id)
	front_id = p_front
	battle = p_battle
	path = p_path
	max_hp = float(def.get("hp", 25))
	hp = max_hp
	if path.size() > 0:
		global_position = path[0]
	_build_visual()


func _build_visual() -> void:
	_body = Polygon2D.new()
	if front_id == "sea":
		_body.polygon = PackedVector2Array([
			Vector2(-14, 0), Vector2(10, -8), Vector2(14, 0), Vector2(10, 8)
		])
	else:
		_body.polygon = PackedVector2Array([
			Vector2(-8, -12), Vector2(8, -12), Vector2(10, 12), Vector2(-10, 12)
		])
	_body.color = def.get("color", Color.DARK_RED)
	add_child(_body)
	var rim := Line2D.new()
	rim.width = 1.5
	rim.default_color = UnitDefs.PALETTE["paper"]
	for p in _body.polygon:
		rim.add_point(p)
	rim.add_point(_body.polygon[0])
	add_child(rim)


func _process(delta: float) -> void:
	if battle == null or not battle.is_combat_phase():
		return
	if path.is_empty():
		return
	var speed: float = float(def.get("speed", 50.0))
	if path_i >= path.size() - 1:
		_reach_hq()
		return
	var target: Vector2 = path[path_i + 1]
	var dir := target - global_position
	var dist := dir.length()
	var step := speed * delta
	if dist <= step:
		global_position = target
		path_i += 1
		if path_i >= path.size() - 1:
			_reach_hq()
	else:
		global_position += dir.normalized() * step


func take_damage(amount: float) -> void:
	hp -= amount
	modulate = Color(1, 0.6, 0.6)
	var t := create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.1)
	if hp <= 0.0:
		GameSession.enemies_killed += 1
		if battle:
			battle.on_raider_died(self)
		queue_free()


func _reach_hq() -> void:
	var dmg := int(def.get("damage", 8))
	GameSession.damage_hq(dmg)
	if battle:
		battle.on_raider_reached(self)
	queue_free()
