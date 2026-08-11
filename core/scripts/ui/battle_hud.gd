extends CanvasLayer
## Slice-0 HUD: phase, resources, unit picker, result panel.

signal start_combat_pressed
signal unit_selected(id: String)
signal restart_pressed
signal hero_ability_pressed

@onready var phase_label: Label = $Root/TopBar/PhaseLabel
@onready var timer_label: Label = $Root/TopBar/TimerLabel
@onready var land_label: Label = $Root/TopBar/LandRes
@onready var sea_label: Label = $Root/TopBar/SeaRes
@onready var hq_label: Label = $Root/TopBar/HqLabel
@onready var selected_label: Label = $Root/SideBar/SelectedLabel
@onready var help_label: Label = $Root/SideBar/HelpLabel
@onready var result_panel: PanelContainer = $Root/ResultPanel
@onready var result_label: Label = $Root/ResultPanel/VBox/ResultText
@onready var restart_btn: Button = $Root/ResultPanel/VBox/RestartBtn
@onready var start_btn: Button = $Root/SideBar/StartCombatBtn
@onready var hero_btn: Button = $Root/SideBar/HeroAbilityBtn


func _ready() -> void:
	result_panel.visible = false
	GameSession.resources_changed.connect(_on_res)
	GameSession.hq_changed.connect(_on_hq)
	GameSession.phase_changed.connect(set_phase)
	start_btn.pressed.connect(func(): start_combat_pressed.emit())
	restart_btn.pressed.connect(func(): restart_pressed.emit())
	hero_btn.pressed.connect(func(): hero_ability_pressed.emit())
	_wire_unit_buttons()
	_on_res(GameSession.land_currency, GameSession.sea_currency)
	_on_hq(GameSession.hq_hp, GameSession.hq_max_hp)
	help_label.text = "1–4 units · click land/sea · Space combat · E flare\nS FlatBuffers save · L load snapshot · Esc pause"


func _wire_unit_buttons() -> void:
	var map := {
		"BtnSpear": "spearman",
		"BtnCannon": "cannon",
		"BtnArq": "arquebusier",
		"BtnJunk": "junk",
		"BtnHero": "hero_qi",
		"BtnCross": "cross_support",
	}
	for btn_name in map.keys():
		var path := "Root/SideBar/%s" % btn_name
		if has_node(path):
			var b: Button = get_node(path)
			var id: String = map[btn_name]
			b.pressed.connect(func(): unit_selected.emit(id))


func set_phase(phase: String) -> void:
	phase_label.text = "Phase: %s" % phase
	start_btn.disabled = phase != "BUILD"


func set_build_timer(t: float) -> void:
	timer_label.text = "Build: %.0fs" % maxf(0.0, t)


func set_combat_timer(t: float) -> void:
	timer_label.text = "Combat: %.0fs" % t


func set_selected(id: String) -> void:
	var def := UnitDefs.get_def(id)
	var n: String = str(def.get("name", id))
	var cost: int = int(def.get("cost", 0))
	var cur: String = str(def.get("currency", "?"))
	selected_label.text = "Selected: %s\nCost: %d %s" % [n, cost, cur]


func _on_res(land: int, sea: int) -> void:
	land_label.text = "Land 兩: %d" % land
	sea_label.text = "Sea 兩: %d" % sea


func _on_hq(hp: int, max_hp: int) -> void:
	hq_label.text = "HQ: %d/%d" % [hp, max_hp]


func show_result(victory: bool, reason: String, stats: Dictionary) -> void:
	result_panel.visible = true
	var title := "VICTORY" if victory else "DEFEAT"
	result_label.text = "%s\n%s\n\nKills: %s  Placed: %s  Outposts lost: %s" % [
		title,
		reason,
		str(stats.get("enemies_killed", 0)),
		str(stats.get("units_placed", 0)),
		str(stats.get("outposts_lost", 0)),
	]
