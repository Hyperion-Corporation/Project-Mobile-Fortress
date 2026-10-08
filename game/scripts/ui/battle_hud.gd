extends CanvasLayer
## Slice-0 HUD: phase, outposts, dual currency, pause overlay, save/load, phone-scale targets (U2/U4/U8/IOS2).

const ProgressionScript := preload("res://scripts/data/progression.gd")
const ThemeTokensScript := preload("res://scripts/ui/theme_tokens.gd")
const CooldownRingScript := preload("res://scripts/ui/cooldown_ring.gd")

signal start_combat_pressed
signal unit_selected(id: String)
signal restart_pressed
signal hero_ability_pressed
signal save_pressed
signal load_pressed
signal resume_pressed
signal menu_pressed
signal pause_pressed
signal speed_pressed

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
var _pause_btn: Button
var _speed_btn: Button
var _pause_overlay: ColorRect
var _pause_title: Label
var _resume_btn: Button
var _pause_save_btn: Button
var _pause_menu_btn: Button
var _outpost_label: Label
var _status_label: Label
var _wave_label: Label
var _cooldown_ring: Control


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
	ThemeTokensScript.apply_accessible_button(start_btn)
	ThemeTokensScript.set_a11y_metadata(start_btn, "Start Combat", "Commence raid combat (Space)")
	ThemeTokensScript.apply_accessible_button(hero_btn)
	ThemeTokensScript.set_a11y_metadata(hero_btn, "Hero Ability", "Activate hero commander active ability (E)")
	ThemeTokensScript.apply_accessible_button(restart_btn)
	ThemeTokensScript.set_a11y_metadata(restart_btn, "Play Again", "Restart the coastal defense mission")

	_restructure_sidebar()
	_wire_unit_buttons()
	_ensure_persistence_buttons()
	_ensure_status_strip()
	_ensure_pause_overlay()
	_ensure_sidebar_controls()
	_ensure_cooldown_ring()
	_on_res(GameSession.land_currency, GameSession.sea_currency)
	_on_hq(GameSession.hq_hp, GameSession.hq_max_hp)
	set_outposts(40, 40, true, 40, 40, true)
	set_wave(0)
	if help_label != null:
		help_label.text = (
			"1–5 units · click land/sea · Space combat\n"
			+ "E hero actives · S save · L load · Esc pause"
		)

	var vp := get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)

	_apply_density_sizes()
	_on_pause_changed(GameSession.is_paused)


func _restructure_sidebar() -> void:
	var root_ctrl: Control = $Root
	var old_sb: Control = root_ctrl.get_node_or_null("SideBar")
	if old_sb == null or old_sb is GridContainer:
		return

	var grid := GridContainer.new()
	grid.name = "SideBar"
	grid.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)

	# Extract SelectedLabel and HelpLabel so they aren't grid cells
	if selected_label != null and selected_label.get_parent() == old_sb:
		old_sb.remove_child(selected_label)
		root_ctrl.add_child(selected_label)
		selected_label.add_theme_color_override("font_color", ThemeTokensScript.INK)

	if help_label != null and help_label.get_parent() == old_sb:
		old_sb.remove_child(help_label)
		root_ctrl.add_child(help_label)
		help_label.add_theme_color_override("font_color", ThemeTokensScript.INK_MUTED)

	var children := old_sb.get_children()
	for child in children:
		old_sb.remove_child(child)
		grid.add_child(child)

	old_sb.name = "OldSideBar"
	old_sb.queue_free()
	root_ctrl.add_child(grid)


func _ensure_persistence_buttons() -> void:
	var sidebar: Control = $Root/SideBar
	if sidebar.get_node_or_null("SaveBtn") == null:
		_save_btn = Button.new()
		_save_btn.name = "SaveBtn"
		_save_btn.text = "Save snapshot (S)"
		sidebar.add_child(_save_btn)
	else:
		_save_btn = sidebar.get_node("SaveBtn")
	if sidebar.get_node_or_null("LoadBtn") == null:
		_load_btn = Button.new()
		_load_btn.name = "LoadBtn"
		_load_btn.text = "Load snapshot (L)"
		sidebar.add_child(_load_btn)
	else:
		_load_btn = sidebar.get_node("LoadBtn")

	ThemeTokensScript.apply_accessible_button(_save_btn)
	ThemeTokensScript.set_a11y_metadata(_save_btn, "Save Snapshot", "Persist current battle state to disk")
	ThemeTokensScript.apply_accessible_button(_load_btn)
	ThemeTokensScript.set_a11y_metadata(_load_btn, "Load Snapshot", "Restore saved battle state from disk")

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
	ThemeTokensScript.apply_accessible_button(_menu_btn)
	ThemeTokensScript.set_a11y_metadata(_menu_btn, "Main Menu", "Return to main menu")
	_menu_btn.pressed.connect(func(): menu_pressed.emit())


func _ensure_sidebar_controls() -> void:
	var sidebar: Control = $Root/SideBar
	if sidebar == null:
		return
	if sidebar.get_node_or_null("PauseBtn") == null:
		_pause_btn = Button.new()
		_pause_btn.name = "PauseBtn"
		_pause_btn.text = "⏸ Pause"
		ThemeTokensScript.apply_accessible_button(_pause_btn)
		ThemeTokensScript.set_a11y_metadata(_pause_btn, "Pause Game", "Pause or resume the battle simulation")
		_pause_btn.pressed.connect(_on_pause_btn_pressed)
		sidebar.add_child(_pause_btn)
	else:
		_pause_btn = sidebar.get_node("PauseBtn")

	if sidebar.get_node_or_null("SpeedBtn") == null:
		_speed_btn = Button.new()
		_speed_btn.name = "SpeedBtn"
		_speed_btn.text = "⏩ 1x"
		ThemeTokensScript.apply_accessible_button(_speed_btn)
		ThemeTokensScript.set_a11y_metadata(_speed_btn, "Sim Speed", "Toggle simulation speed between 1x, 2x, and 3x")
		_speed_btn.pressed.connect(_on_speed_btn_pressed)
		sidebar.add_child(_speed_btn)
	else:
		_speed_btn = sidebar.get_node("SpeedBtn")


func _on_pause_btn_pressed() -> void:
	pause_pressed.emit()
	GameSession.toggle_paused()


func _on_speed_btn_pressed() -> void:
	var s: float = GameSession.time_scale
	var next_s: float = 1.0
	if s <= 1.05:
		next_s = 2.0
	elif s <= 2.05:
		next_s = 3.0
	else:
		next_s = 1.0
	GameSession.set_time_scale(next_s)
	_speed_btn.text = "⏩ %.0fx" % next_s
	speed_pressed.emit()


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
		ThemeTokensScript.apply_accessible_button(_resume_btn)
		ThemeTokensScript.set_a11y_metadata(_resume_btn, "Resume Battle", "Resume coastal defense simulation")
		vbox.add_child(_resume_btn)
		_pause_save_btn = Button.new()
		_pause_save_btn.name = "PauseSaveBtn"
		_pause_save_btn.text = "Save snapshot"
		ThemeTokensScript.apply_accessible_button(_pause_save_btn)
		ThemeTokensScript.set_a11y_metadata(_pause_save_btn, "Save Snapshot", "Persist current battle snapshot to disk")
		vbox.add_child(_pause_save_btn)
		_pause_menu_btn = Button.new()
		_pause_menu_btn.name = "PauseMenuBtn"
		_pause_menu_btn.text = "Main Menu"
		ThemeTokensScript.apply_accessible_button(_pause_menu_btn)
		ThemeTokensScript.set_a11y_metadata(_pause_menu_btn, "Main Menu", "Exit to main menu")
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


func _ensure_cooldown_ring() -> void:
	if hero_btn == null:
		return
	_cooldown_ring = hero_btn.get_node_or_null("CooldownRing") as Control
	if _cooldown_ring == null:
		_cooldown_ring = CooldownRingScript.new()
		_cooldown_ring.name = "CooldownRing"
		_cooldown_ring.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		_cooldown_ring.offset_left = -32
		_cooldown_ring.offset_top = -14
		_cooldown_ring.offset_right = -4
		_cooldown_ring.offset_bottom = 14
		hero_btn.add_child(_cooldown_ring)


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
		_apply_density_sizes()
		ThemeTokensScript.animate_fade_in(_pause_overlay, 0.2)
	elif not should_show:
		_pause_overlay.visible = false


func _wire_unit_buttons() -> void:
	var map := {
		"BtnSpear": {"id": "spearman", "desc": "Ming Spearmen (Land front)"},
		"BtnCannon": {"id": "cannon", "desc": "Fo-lang-ji Swivel Cannon (Land, cross support)"},
		"BtnArq": {"id": "arquebusier", "desc": "Portuguese Arquebusiers (Sea front)"},
		"BtnJunk": {"id": "junk", "desc": "War Junk (Sea naval defense)"},
		"BtnHero": {"id": "hero_qi", "desc": "General Qi Jiguang (Either front)"},
		"BtnHeroDias": {"id": "hero_dias", "desc": "Capitão Dias (Either front, cross-salvo)"},
		"BtnCross": {"id": "cross_support", "desc": "Signal Battery (Cross-front artillery)"},
	}
	var sidebar: Control = $Root/SideBar
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
			var data: Dictionary = map[btn_name]
			var id: String = str(data["id"])
			ThemeTokensScript.apply_accessible_button(b)
			ThemeTokensScript.set_a11y_metadata(b, b.text, str(data["desc"]))
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
		if wave <= 0:
			_wave_label.text = "Wave —"
			return
		var threat_roman := "Ⅰ (Scouts)"
		var threat_color := ThemeTokensScript.GOLD
		if wave >= 3:
			threat_roman = "Ⅲ (War Fleet)"
			threat_color = ThemeTokensScript.CINNABAR
		elif wave == 2:
			threat_roman = "Ⅱ (Raiders)"
			threat_color = ThemeTokensScript.OCHRE
		_wave_label.add_theme_color_override("font_color", threat_color)
		_wave_label.text = "Wave %d · %s %s" % [wave, ThemeTokensScript.GLYPH_THREAT_SKULL, threat_roman]


func set_hero_cooldown(cooldown_left: float, max_cooldown: float = 10.0) -> void:
	if hero_btn == null:
		return
	if _cooldown_ring == null:
		_ensure_cooldown_ring()
	if _cooldown_ring != null and _cooldown_ring.has_method("set_cooldown"):
		_cooldown_ring.set_cooldown(cooldown_left, max_cooldown)
	if cooldown_left <= 0.0:
		hero_btn.text = "E · Hero Ability (Ready) "
		hero_btn.add_theme_color_override("font_color", ThemeTokensScript.GOLD)
	else:
		hero_btn.text = "E · Hero Ability (⌛ %.1fs) " % cooldown_left
		hero_btn.add_theme_color_override("font_color", ThemeTokensScript.INK_MUTED)


func set_selected(id: String) -> void:
	var def := UnitDefs.get_def(id)
	var n: String = str(def.get("name", id))
	var cost: int = int(def.get("cost", 0))
	var cur: String = str(def.get("currency", "?"))
	var glyph := ThemeTokensScript.GLYPH_LAND_CURRENCY if cur == "land" else ThemeTokensScript.GLYPH_SEA_CURRENCY
	if selected_label != null:
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

	var total_p := int(stats.get("total_prestige", ProgressionScript.total_prestige()))
	var tier_info := ProgressionScript.get_prestige_tier(total_p)
	var next_info := ProgressionScript.get_next_prestige_tier(total_p)
	var rank_title: String = str(tier_info.get("title", "Citadel"))
	var rank_hist: String = str(tier_info.get("historical_title", ""))
	var rank_display := "%s (%s)" % [rank_title, rank_hist] if not rank_hist.is_empty() else rank_title

	var progress_line := ""
	if bool(next_info.get("max_rank_reached", false)):
		progress_line = "Rank: %s · Max Rank" % rank_display
	else:
		var pct := int(roundf(float(next_info.get("progress_ratio", 0.0)) * 100.0))
		var rem := int(next_info.get("remaining_prestige", 0))
		var next_title := str(next_info.get("next_title", ""))
		progress_line = "Rank: %s · %d%% to %s (%d needed)" % [
			rank_display, pct, next_title, rem
		]

	var stars_line := ""
	if stats.has("stars"):
		stars_line = "Stars: %s  Prestige: +%s (HQ %s)\n%s\n" % [
			ProgressionScript.format_stars(int(stats.get("stars", 0))),
			str(stats.get("prestige_earned", 0)),
			str(total_p),
			progress_line,
		]
	else:
		stars_line = "%s\n" % progress_line

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
	_apply_density_sizes()
	ThemeTokensScript.animate_slide_fade_in(result_panel, -24.0, 0.35)


## Returns the logical-unit minimum height required for ≥48dp window pixels at current window.
func _density_min_h() -> float:
	var tree := get_tree()
	var ws := ThemeTokensScript.CANVAS_DESIGN_SIZE
	if tree and tree.root and tree.root.size.x >= 200 and tree.root.size.y >= 200:
		ws = Vector2(tree.root.size)
	else:
		var ds_size := DisplayServer.window_get_size()
		if ds_size.x >= 200 and ds_size.y >= 200:
			ws = Vector2(ds_size)
	return ThemeTokensScript.compute_density_min_size(ws)


func _on_viewport_size_changed() -> void:
	_apply_density_sizes()


func _apply_density_sizes() -> void:
	var settings: Dictionary = OfflinePersistence.read_settings()
	var is_large_text: bool = bool(settings.get("large_text", false))
	var min_d: float = _density_min_h()
	if is_large_text:
		min_d = ceilf(min_d * ThemeTokensScript.LARGE_TEXT_SCALE)

	var tree := get_tree()
	var ws := ThemeTokensScript.CANVAS_DESIGN_SIZE
	if tree and tree.root and tree.root.size.x >= 200 and tree.root.size.y >= 200:
		ws = Vector2(tree.root.size)

	var vp := get_viewport()
	var vp_w: float = vp.get_visible_rect().size.x if vp else ws.x
	var vp_h: float = vp.get_visible_rect().size.y if vp else ws.y
	var is_compact_landscape: bool = vp_h <= 720.0 and vp_w > 1300.0

	# 1. SideBar buttons (unit buttons + action/control buttons)
	var sidebar: Control = get_node_or_null("Root/SideBar")
	var topbar: HBoxContainer = get_node_or_null("Root/TopBar")
	if sidebar != null:
		var btn_w: float = maxf(min_d, 140.0)
		for child in sidebar.get_children():
			if child is Button:
				var b := child as Button
				b.clip_text = true
				b.custom_minimum_size = Vector2(btn_w, min_d)

		if sidebar is GridContainer:
			var grid := sidebar as GridContainer
			grid.columns = 3 if is_compact_landscape else 2
			var g_min := grid.get_combined_minimum_size()

			grid.offset_left = -g_min.x - 12.0
			grid.offset_right = -12.0
			grid.offset_top = 36.0
			grid.offset_bottom = 36.0 + g_min.y

			if selected_label != null:
				selected_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
				selected_label.offset_left = -g_min.x - 12.0
				selected_label.offset_top = 8.0
				selected_label.offset_right = -12.0
				selected_label.offset_bottom = 32.0

			if help_label != null:
				help_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
				help_label.offset_left = -g_min.x - 12.0
				help_label.offset_top = grid.offset_bottom + 6.0
				help_label.offset_right = -12.0
				help_label.offset_bottom = grid.offset_bottom + 42.0

			if topbar != null:
				topbar.offset_left = 12.0
				topbar.offset_right = -g_min.x - 24.0
				topbar.offset_top = 8.0
				topbar.offset_bottom = 40.0

	# 3. PauseOverlay & PausePanel
	if _pause_overlay != null:
		var pause_panel: PanelContainer = _pause_overlay.get_node_or_null("PausePanel")
		if pause_panel != null:
			var p_w: float = maxf(320.0, min_d * 2.2)
			var p_h: float = maxf(240.0, min_d * 3.5 + 80.0)
			pause_panel.offset_left = -p_w * 0.5
			pause_panel.offset_right = p_w * 0.5
			pause_panel.offset_top = -p_h * 0.5
			pause_panel.offset_bottom = p_h * 0.5

		for b in [_resume_btn, _pause_save_btn, _pause_menu_btn]:
			if b != null:
				b.clip_text = true
				b.custom_minimum_size = Vector2(maxf(min_d, 160.0), min_d)

	# 4. ResultPanel
	if result_panel != null:
		var r_w: float = maxf(360.0, min_d * 2.2)
		var r_h: float = maxf(280.0, min_d * 2.5 + 180.0)
		result_panel.offset_left = -r_w * 0.5
		result_panel.offset_right = r_w * 0.5
		result_panel.offset_top = -r_h * 0.5
		result_panel.offset_bottom = r_h * 0.5

		for b in [restart_btn, _menu_btn]:
			if b != null:
				b.clip_text = true
				b.custom_minimum_size = Vector2(maxf(min_d, 160.0), min_d)
