extends CanvasLayer
## Slice-0 HUD: phase, outposts, dual currency, pause overlay, save/load (U2/U4).

const ProgressionScript := preload("res://scripts/data/progression.gd")
const ThemeTokensScript := preload("res://scripts/ui/theme_tokens.gd")

signal start_combat_pressed
signal unit_selected(id: String)
signal restart_pressed
signal hero_ability_pressed
signal save_pressed
signal load_pressed
signal resume_pressed
signal menu_pressed

const INK := Color(0.10, 0.09, 0.12, 1)
const CINNABAR := Color(0.72, 0.20, 0.14, 1)
const SEA := Color(0.16, 0.28, 0.42, 1)
const MOSS := Color(0.24, 0.38, 0.28, 1)

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

var _save_btn: Button
var _load_btn: Button
var _menu_btn: Button
var _pause_overlay: ColorRect
var _pause_title: Label
var _resume_btn: Button
var _pause_save_btn: Button
var _pause_menu_btn: Button
var _outpost_label: Label
var _status_label: Label
var _wave_label: Label


func _ready() -> void:
	result_panel.visible = false
	GameSession.resources_changed.connect(_on_res)
	GameSession.hq_changed.connect(_on_hq)
	GameSession.phase_changed.connect(set_phase)
	if not GameSession.pause_changed.is_connected(_on_pause_changed):
		GameSession.pause_changed.connect(_on_pause_changed)
	start_btn.pressed.connect(func(): start_combat_pressed.emit())
	restart_btn.pressed.connect(func(): restart_pressed.emit())
	hero_btn.pressed.connect(func(): hero_ability_pressed.emit())
	_wire_unit_buttons()
	_ensure_persistence_buttons()
	_ensure_status_strip()
	_ensure_pause_overlay()
	_on_res(GameSession.land_currency, GameSession.sea_currency)
	_on_hq(GameSession.hq_hp, GameSession.hq_max_hp)
	set_outposts(40, 40, true, 40, 40, true)
	set_wave(0)
	help_label.text = (
		"1–5 units · click land/sea · Space combat · E hero actives · U upgrade\n"
		+ "S snapshot · L load · Esc pause"
	)
	_on_pause_changed(GameSession.is_paused)


func _ensure_persistence_buttons() -> void:
	var sidebar: VBoxContainer = $Root/SideBar
	if sidebar.get_node_or_null("SaveBtn") == null:
		_save_btn = Button.new()
		_save_btn.name = "SaveBtn"
		_save_btn.text = "Save snapshot (S)"
		sidebar.add_child(_save_btn)
		sidebar.move_child(_save_btn, hero_btn.get_index() + 1)
	else:
		_save_btn = sidebar.get_node("SaveBtn")
	if sidebar.get_node_or_null("LoadBtn") == null:
		_load_btn = Button.new()
		_load_btn.name = "LoadBtn"
		_load_btn.text = "Load snapshot (L)"
		sidebar.add_child(_load_btn)
		sidebar.move_child(_load_btn, _save_btn.get_index() + 1)
	else:
		_load_btn = sidebar.get_node("LoadBtn")
	_save_btn.pressed.connect(func(): save_pressed.emit())
	_load_btn.pressed.connect(func(): load_pressed.emit())
	# Result panel: back to menu
	var vbox: VBoxContainer = $Root/ResultPanel/VBox
	if vbox.get_node_or_null("MenuBtn") == null:
		_menu_btn = Button.new()
		_menu_btn.name = "MenuBtn"
		_menu_btn.text = "Main Menu"
		vbox.add_child(_menu_btn)
	else:
		_menu_btn = vbox.get_node("MenuBtn")
	_menu_btn.pressed.connect(func(): menu_pressed.emit())


func _ensure_status_strip() -> void:
	var top: HBoxContainer = $Root/TopBar
	if top.get_node_or_null("OutpostLabel") == null:
		_outpost_label = Label.new()
		_outpost_label.name = "OutpostLabel"
		_outpost_label.add_theme_color_override("font_color", INK)
		_outpost_label.add_theme_font_size_override("font_size", 14)
		top.add_child(_outpost_label)
	else:
		_outpost_label = top.get_node("OutpostLabel")
	if top.get_node_or_null("WaveLabel") == null:
		_wave_label = Label.new()
		_wave_label.name = "WaveLabel"
		_wave_label.add_theme_color_override("font_color", CINNABAR)
		_wave_label.add_theme_font_size_override("font_size", 14)
		top.add_child(_wave_label)
	else:
		_wave_label = top.get_node("WaveLabel")
	var root_ctrl: Control = $Root
	if root_ctrl.get_node_or_null("StatusLabel") == null:
		_status_label = Label.new()
		_status_label.name = "StatusLabel"
		_status_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_status_label.offset_left = 12
		_status_label.offset_top = -28
		_status_label.offset_right = -300
		_status_label.offset_bottom = -8
		_status_label.add_theme_color_override("font_color", INK)
		_status_label.add_theme_font_size_override("font_size", 13)
		root_ctrl.add_child(_status_label)
	else:
		_status_label = root_ctrl.get_node("StatusLabel")


func _ensure_pause_overlay() -> void:
	var root_ctrl: Control = $Root
	_pause_overlay = root_ctrl.get_node_or_null("PauseOverlay") as ColorRect
	if _pause_overlay == null:
		_pause_overlay = ColorRect.new()
		_pause_overlay.name = "PauseOverlay"
		_pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_pause_overlay.color = Color(0.06, 0.05, 0.07, 0.62)
		_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		root_ctrl.add_child(_pause_overlay)
		var panel := PanelContainer.new()
		panel.name = "PausePanel"
		panel.set_anchors_preset(Control.PRESET_CENTER)
		panel.offset_left = -160
		panel.offset_top = -110
		panel.offset_right = 160
		panel.offset_bottom = 130
		panel.add_theme_stylebox_override("panel", ThemeTokensScript.make_panel_style(ThemeTokensScript.PAPER_CARD, ThemeTokensScript.CINNABAR, 6, 14))
		_pause_overlay.add_child(panel)
		var vbox := VBoxContainer.new()
		vbox.name = "VBox"
		vbox.add_theme_constant_override("separation", 10)
		panel.add_child(vbox)
		_pause_title = Label.new()
		_pause_title.name = "PauseTitle"
		_pause_title.text = "PAUSED"
		_pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pause_title.add_theme_font_size_override("font_size", 24)
		_pause_title.add_theme_color_override("font_color", ThemeTokensScript.CINNABAR)
		vbox.add_child(_pause_title)
		var hint := Label.new()
		hint.name = "PauseHint"
		hint.text = "Esc resumes · fortress holds"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 13)
		vbox.add_child(hint)
		_resume_btn = Button.new()
		_resume_btn.name = "ResumeBtn"
		_resume_btn.text = "Resume"
		vbox.add_child(_resume_btn)
		_pause_save_btn = Button.new()
		_pause_save_btn.name = "PauseSaveBtn"
		_pause_save_btn.text = "Save snapshot"
		vbox.add_child(_pause_save_btn)
		_pause_menu_btn = Button.new()
		_pause_menu_btn.name = "PauseMenuBtn"
		_pause_menu_btn.text = "Main Menu"
		vbox.add_child(_pause_menu_btn)
	else:
		_pause_title = _pause_overlay.get_node("PausePanel/VBox/PauseTitle")
		_resume_btn = _pause_overlay.get_node("PausePanel/VBox/ResumeBtn")
		_pause_save_btn = _pause_overlay.get_node("PausePanel/VBox/PauseSaveBtn")
		_pause_menu_btn = _pause_overlay.get_node("PausePanel/VBox/PauseMenuBtn")
	if not _resume_btn.pressed.is_connected(_emit_resume):
		_resume_btn.pressed.connect(_emit_resume)
	if not _pause_save_btn.pressed.is_connected(_emit_save):
		_pause_save_btn.pressed.connect(_emit_save)
	if not _pause_menu_btn.pressed.is_connected(_emit_menu):
		_pause_menu_btn.pressed.connect(_emit_menu)
	_pause_overlay.visible = false


func _emit_resume() -> void:
	resume_pressed.emit()


func _emit_save() -> void:
	save_pressed.emit()


func _emit_menu() -> void:
	menu_pressed.emit()


func _on_pause_changed(paused: bool) -> void:
	if _pause_overlay == null:
		return
	var should_show := paused and not result_panel.visible
	if should_show and not _pause_overlay.visible:
		ThemeTokensScript.animate_fade_in(_pause_overlay, 0.2)
	elif not should_show:
		_pause_overlay.visible = false


func _wire_unit_buttons() -> void:
	var map := {
		"BtnSpear": "spearman",
		"BtnCannon": "cannon",
		"BtnArq": "arquebusier",
		"BtnJunk": "junk",
		"BtnHero": "hero_qi",
		"BtnHeroDias": "hero_dias",
		"BtnCross": "cross_support",
	}
	var sidebar: VBoxContainer = $Root/SideBar
	if sidebar.get_node_or_null("BtnHeroDias") == null and sidebar.get_node_or_null("BtnHero") != null:
		var dias_btn := Button.new()
		dias_btn.name = "BtnHeroDias"
		dias_btn.text = "Capitão Dias (Either)"
		sidebar.add_child(dias_btn)
		sidebar.move_child(dias_btn, sidebar.get_node("BtnHero").get_index() + 1)
	for btn_name in map.keys():
		var path := "Root/SideBar/%s" % btn_name
		if has_node(path):
			var b: Button = get_node(path)
			var id: String = map[btn_name]
			b.pressed.connect(func(): unit_selected.emit(id))


func set_phase(phase: String) -> void:
	var pretty := phase
	match phase:
		"BUILD":
			pretty = "BUILD · Place defenders"
		"COMBAT":
			pretty = "COMBAT · Hold the coast"
		"RESULT":
			pretty = "RESULT"
	phase_label.text = pretty
	start_btn.disabled = phase != "BUILD"


func set_build_timer(t: float) -> void:
	timer_label.text = "Build  %.0fs" % maxf(0.0, t)


func set_combat_timer(t: float) -> void:
	timer_label.text = "Raid  %.0fs" % t


func set_outposts(land_hp: int, land_max: int, land_alive: bool, sea_hp: int, sea_max: int, sea_alive: bool) -> void:
	if _outpost_label == null:
		return
	var land_s := "lost" if not land_alive else "%d/%d" % [land_hp, land_max]
	var sea_s := "lost" if not sea_alive else "%d/%d" % [sea_hp, sea_max]
	_outpost_label.text = "%s %s · %s %s" % [
		ThemeTokensScript.GLYPH_OUTPOST_LAND, land_s,
		ThemeTokensScript.GLYPH_OUTPOST_SEA, sea_s
	]


func set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


func set_wave(wave: int) -> void:
	if _wave_label != null:
		_wave_label.text = "Wave %d" % wave if wave > 0 else "Wave —"


func set_selected(id: String) -> void:
	var def := UnitDefs.get_def(id)
	var n: String = str(def.get("name", id))
	var cost: int = int(def.get("cost", 0))
	var cur: String = str(def.get("currency", "?"))
	var glyph := ThemeTokensScript.GLYPH_LAND_CURRENCY if cur == "land" else ThemeTokensScript.GLYPH_SEA_CURRENCY
	selected_label.text = "Selected: %s\nCost: %d %s" % [n, cost, glyph]


func _on_res(land: int, sea: int) -> void:
	land_label.add_theme_color_override("font_color", ThemeTokensScript.MOSS_LAND)
	sea_label.add_theme_color_override("font_color", ThemeTokensScript.SEA_INDIGO)
	land_label.text = "Land %s  %d" % [ThemeTokensScript.GLYPH_LAND_CURRENCY, land]
	sea_label.text = "Sea %s  %d" % [ThemeTokensScript.GLYPH_SEA_CURRENCY, sea]


func _on_hq(hp: int, max_hp: int) -> void:
	hq_label.add_theme_color_override("font_color", ThemeTokensScript.CINNABAR)
	hq_label.text = "HQ  %d/%d" % [hp, max_hp]


func show_result(victory: bool, reason: String, stats: Dictionary) -> void:
	result_panel.add_theme_stylebox_override("panel", ThemeTokensScript.make_panel_style(ThemeTokensScript.PAPER_CARD, ThemeTokensScript.CINNABAR if not victory else ThemeTokensScript.GOLD, 8, 16))
	if _pause_overlay != null:
		_pause_overlay.visible = false
	var title := "VICTORY" if victory else "DEFEAT"
	var stars_line := ""
	if stats.has("stars"):
		stars_line = "Stars: %s  Prestige: +%s (HQ %s)\n" % [
			ProgressionScript.format_stars(int(stats.get("stars", 0))),
			str(stats.get("prestige_earned", 0)),
			str(stats.get("total_prestige", 0)),
		]
	result_label.text = (
		"%s\n%s\n\n%sKills: %s  Placed: %s  Outposts lost: %s\n"
		+ "Combat: %.0fs  Wave: %s\n\nExported: %s\nHistory: %s"
	) % [
		title,
		reason,
		stars_line,
		str(stats.get("enemies_killed", 0)),
		str(stats.get("units_placed", 0)),
		str(stats.get("outposts_lost", 0)),
		float(stats.get("combat_time", 0.0)),
		str(stats.get("wave", 0)),
		str(stats.get("results_path", OfflinePersistence.RESULTS_PATH)),
		OfflinePersistence.HISTORY_PATH,
	]
	ThemeTokensScript.animate_slide_fade_in(result_panel, -24.0, 0.35)
