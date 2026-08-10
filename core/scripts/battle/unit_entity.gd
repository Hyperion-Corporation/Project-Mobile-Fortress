class_name UnitEntity
extends Node2D
## Placed defender / hero / cross-support.

var unit_id: String = ""
var def: Dictionary = {}
var front_id: String = "land"
var cell: Vector2i = Vector2i.ZERO
var hp: float = 1.0
var max_hp: float = 1.0
var _cd: float = 0.0
var _active_cd: float = 0.0
var _body: Polygon2D
var _aura_ring: Polygon2D
var battle: Node = null ## BattleRoot


func setup(p_id: String, p_front: String, p_cell: Vector2i, p_battle: Node) -> void:
	unit_id = p_id
	def = UnitDefs.get_def(p_id)
	front_id = p_front
	cell = p_cell
	battle = p_battle
	max_hp = float(def.get("hp", 30))
	hp = max_hp
	_build_visual()


func _build_visual() -> void:
	for c in get_children():
		c.queue_free()
	var col: Color = def.get("color", Color.WHITE)
	_body = Polygon2D.new()
	match int(def.get("kind", UnitDefs.Kind.DEFENDER)):
		UnitDefs.Kind.HERO:
			_body.polygon = PackedVector2Array([
				Vector2(0, -16), Vector2(14, 10), Vector2(0, 6), Vector2(-14, 10)
			])
			_aura_ring = Polygon2D.new()
			_aura_ring.color = Color(col.r, col.g, col.b, 0.12)
			var r: float = float(def.get("aura_radius", 2.0)) * GridFront.CELL * 0.45
			var pts: PackedVector2Array = []
			for i in 16:
				var a := TAU * float(i) / 16.0
				pts.append(Vector2(cos(a), sin(a)) * r)
			_aura_ring.polygon = pts
			add_child(_aura_ring)
		UnitDefs.Kind.CROSS_SUPPORT:
			_body.polygon = PackedVector2Array([
				Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12), Vector2(-12, 12)
			])
		_:
			_body.polygon = PackedVector2Array([
				Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)
			])
	_body.color = col
	add_child(_body)

	var rim := Line2D.new()
	rim.width = 2.0
	rim.default_color = UnitDefs.PALETTE["ink"]
	for p in _body.polygon:
		rim.add_point(p)
	if _body.polygon.size() > 0:
		rim.add_point(_body.polygon[0])
	add_child(rim)


func _process(delta: float) -> void:
	if battle == null or not battle.is_combat_phase():
		return
	_cd = maxf(0.0, _cd - delta)
	_active_cd = maxf(0.0, _active_cd - delta)
	if _cd <= 0.0:
		_try_attack()
		_cd = float(def.get("cooldown", 1.0))


func aura_multiplier_at(world_pos: Vector2) -> float:
	if int(def.get("kind", -1)) != UnitDefs.Kind.HERO:
		return 0.0
	var r: float = float(def.get("aura_radius", 2.0)) * GridFront.CELL
	if global_position.distance_to(world_pos) <= r:
		return float(def.get("aura_damage_bonus", 0.2))
	return 0.0


func try_active_ability() -> bool:
	if int(def.get("kind", -1)) != UnitDefs.Kind.HERO:
		return false
	if _active_cd > 0.0:
		return false
	_active_cd = float(def.get("active_cooldown", 8.0))
	if battle and battle.has_method("hero_pulse"):
		battle.hero_pulse(self, float(def.get("active_damage", 20.0)))
	return true


func _try_attack() -> void:
	if battle == null:
		return
	var target = battle.find_target_for(self)
	if target == null:
		return
	var dmg := float(def.get("damage", 5))
	var same_front: bool = target.front_id == front_id
	var mult: float = float(def.get("own_env_mult", 1.0)) if same_front else float(def.get("cross_env_mult", 0.0))
	if mult <= 0.0:
		return
	dmg *= mult
	dmg *= 1.0 + battle.total_aura_bonus(global_position)
	target.take_damage(dmg)


func take_damage(amount: float) -> void:
	hp -= amount
	modulate = Color(1, 0.5, 0.5)
	var t := create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.15)
	if hp <= 0.0:
		if battle:
			battle.on_unit_died(self)
		queue_free()
