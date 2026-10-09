extends Control
## Main menu — Wōkòu-era coastal theme (U1) over Slice-0 entry.

const SettingsDialogScript := preload("res://scripts/ui/settings_dialog.gd")
const ThemeTokensScript := preload("res://scripts/ui/theme_tokens.gd")
const LevelCatalogScript := preload("res://scripts/data/level_catalog.gd")
const ProgressionScript := preload("res://scripts/data/progression.gd")

@onready var start_btn: Button = $Center/VBox/StartBtn
@onready var classic_btn: Button = $Center/VBox/ClassicBtn
@onready var quit_btn: Button = $Center/VBox/QuitBtn
@onready var blurb: Label = $Center/VBox/Blurb

const PAPER := ThemeTokensScript.PAPER
const DUSK := ThemeTokensScript.INK
const INDIGO := ThemeTokensScript.SEA_INDIGO
const CINNABAR := ThemeTokensScript.CINNABAR

var _resume_btn: Button
var _last_run_label: Label
var _campaign_rank_label: Label


func _ready() -> void:
	_apply_coastal_theme()
	var has_cpp := ClassDB.class_exists("SimulationCore")
	blurb.text = (
		"1540s–1560s · East Asian coast · Ming garrison + Portuguese support\n"
		+ "Defend outposts and sea lanes against Wōkòu raids.\n"
		+ "Sim: %s · offline · dual-front"
		% ("C++ SimulationCore" if has_cpp else "GDScript fallback (classic only)")
	)
	start_btn.pressed.connect(func():
		GameSession.resume_snapshot_on_next_battle = false
		get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")
	)
	classic_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://main.tscn"))
	quit_btn.pressed.connect(func(): get_tree().quit())
	if not has_cpp:
		start_btn.disabled = true
		start_btn.text = "Defend the Coast (needs GDExtension)"
	else:
		start_btn.text = "Defend the Coast"
	classic_btn.text = "Classic prototype"
	for b in [start_btn, classic_btn, quit_btn]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	_ensure_level_select()
	_ensure_resume_and_history_ui(has_cpp)
	_ensure_campaign_rank_label()
	_ensure_version_label()
	_refresh_last_run()
	_refresh_campaign_rank()
	_apply_density_sizes()
	_apply_large_text()
	_setup_focus_traversal()
	call_deferred("_set_initial_focus")
	var center: Control = get_node_or_null("Center")
	if center:
		ThemeTokensScript.animate_fade_in(center, 0.25)
	# Re-apply density minimum sizes whenever the window is resized.
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _apply_coastal_theme() -> void:
	var bg: ColorRect = get_node_or_null("Bg")
	if bg:
		bg.color = PAPER
	if get_node_or_null("Horizon") == null:
		var horizon := ColorRect.new()
		horizon.name = "Horizon"
		horizon.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		horizon.offset_top = -220
		horizon.color = INDIGO
		horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(horizon)
		move_child(horizon, 1)
	if get_node_or_null("InkBand") == null:
		var band := ColorRect.new()
		band.name = "InkBand"
		band.set_anchors_preset(Control.PRESET_TOP_WIDE)
		band.offset_bottom = 8
		band.color = CINNABAR
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(band)
		move_child(band, 2)
	var title: Label = get_node_or_null("Center/VBox/Title")
	if title:
		title.add_theme_font_size_override("font_size", 36)
		title.add_theme_color_override("font_color", DUSK)
	var subtitle: Label = get_node_or_null("Center/VBox/Subtitle")
	if subtitle:
		subtitle.text = "倭寇 Dual-Front Defense"
		subtitle.add_theme_color_override("font_color", CINNABAR)


func _window_size_for_density() -> Vector2:
	var tree := get_tree()
	var ws := ThemeTokensScript.CANVAS_DESIGN_SIZE
	if tree and tree.root and tree.root.size.x >= 200 and tree.root.size.y >= 200:
		ws = Vector2(tree.root.size)
	else:
		var ds_size := DisplayServer.window_get_size()
		if ds_size.x >= 200 and ds_size.y >= 200:
			ws = Vector2(ds_size)
	return ws


## Returns the logical-unit minimum height required for ≥48dp window pixels at the current window.
func _density_min_h() -> float:
	return ThemeTokensScript.compute_density_min_size(_window_size_for_density())


## Resolves an action control from VBox or the compact ActionGrid (T77).
func _find_action(action_name: String) -> Control:
	var vbox: VBoxContainer = get_node_or_null("Center/VBox")
	if vbox == null:
		return null
	var grid: Node = vbox.get_node_or_null("ActionGrid")
	if grid != null and grid.has_node(action_name):
		return grid.get_node(action_name) as Control
	return vbox.get_node_or_null(action_name) as Control


func _apply_action_layout(is_compact_landscape: bool) -> void:
	var vbox: VBoxContainer = get_node_or_null("Center/VBox")
	if vbox == null:
		return
	var grid: GridContainer = vbox.get_node_or_null("ActionGrid")
	if grid == null:
		grid = GridContainer.new()
		grid.name = "ActionGrid"
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(grid)
	var action_names: Array[String] = [
		"LevelSelect", "StartBtn", "ResumeBtn", "ClassicBtn", "SettingsBtn", "QuitBtn"
	]
	var actions: Array[Control] = []
	for action_name in action_names:
		var node: Control = _find_action(action_name)
		if node:
			actions.append(node)
	if is_compact_landscape:
		grid.visible = true
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 2)
		for node in actions:
			if node.get_parent() != grid:
				node.reparent(grid)
		var compact_order: Array[String] = [
			"Title", "Subtitle", "Blurb", "CampaignRankLabel", "LastRunLabel", "ActionGrid"
		]
		var compact_idx := 0
		for node_name in compact_order:
			var node: Node = vbox.get_node_or_null(node_name)
			if node:
				vbox.move_child(node, compact_idx)
				compact_idx += 1
	else:
		for node in actions:
			if node.get_parent() != vbox:
				node.reparent(vbox)
		grid.visible = false
		var desktop_order: Array[String] = [
			"Title", "Subtitle", "Blurb", "CampaignRankLabel",
			"LevelSelect", "StartBtn", "ResumeBtn", "LastRunLabel",
			"ClassicBtn", "SettingsBtn", "QuitBtn"
		]
		var desktop_idx := 0
		for node_name in desktop_order:
			var node: Node = vbox.get_node_or_null(node_name)
			if node:
				vbox.move_child(node, desktop_idx)
				desktop_idx += 1
		vbox.move_child(grid, desktop_idx)


## Re-applies density-aware minimum heights to all interactive controls.
## Safe to call at any time; uses the viewport's current size.
func _apply_density_sizes() -> void:
	var min_h: float = _density_min_h()
	var vbox: VBoxContainer = get_node_or_null("Center/VBox")
	var vp: Viewport = get_viewport()
	var vp_h: float = vp.get_visible_rect().size.y if vp else ThemeTokensScript.CANVAS_DESIGN_SIZE.y
	var vp_w: float = vp.get_visible_rect().size.x if vp else ThemeTokensScript.CANVAS_DESIGN_SIZE.x
	var is_compact_landscape: bool = vp_h <= 720.0 and vp_w > 1280.0
	if vbox:
		vbox.add_theme_constant_override("separation", 2 if is_compact_landscape else 6)
		var box_w: float = clampf(vp_w * 0.55, 480.0, 720.0) if is_compact_landscape else clampf(vp_w * 0.45, 280.0, 480.0)
		vbox.custom_minimum_size = Vector2(box_w, 0)

		var title: Label = vbox.get_node_or_null("Title")
		if title:
			title.add_theme_font_size_override("font_size", 24 if is_compact_landscape else 36)
		var sub: Label = vbox.get_node_or_null("Subtitle")
		if sub:
			sub.add_theme_font_size_override("font_size", 12 if is_compact_landscape else 18)
		var blurb: Label = vbox.get_node_or_null("Blurb")
		if blurb:
			# Keep returning-player actions and campaign rank on compact screens.
			blurb.visible = not is_compact_landscape
			blurb.add_theme_font_size_override("font_size", 11 if is_compact_landscape else 14)
			blurb.custom_minimum_size = Vector2(box_w, 0)
		var rank: Label = vbox.get_node_or_null("CampaignRankLabel")
		if rank:
			rank.add_theme_font_size_override("font_size", 11 if is_compact_landscape else 13)
			rank.custom_minimum_size = Vector2(box_w, 0)
		var last_run: Label = vbox.get_node_or_null("LastRunLabel")
		if last_run:
			last_run.add_theme_font_size_override("font_size", 11 if is_compact_landscape else 13)
			last_run.custom_minimum_size = Vector2(box_w, 0)

		_apply_action_layout(is_compact_landscape)
		_apply_min_height_to_actions(vbox, min_h)
	var ver: Control = get_node_or_null("VersionLabel")
	if ver:
		ver.custom_minimum_size = Vector2(160, min_h)
		ver.offset_top = -(min_h + 8.0)
		ver.offset_bottom = -8.0


func _apply_min_height_to_actions(vbox: VBoxContainer, min_h: float) -> void:
	for child in vbox.get_children():
		if child is GridContainer:
			for gchild in child.get_children():
				if gchild is Button or gchild is OptionButton:
					var grid_ctrl := gchild as Control
					grid_ctrl.custom_minimum_size = Vector2(0, min_h)
					grid_ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		elif child is Button or child is OptionButton:
			var ctrl := child as Control
			ctrl.custom_minimum_size = Vector2(0, min_h)
			ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _on_viewport_size_changed() -> void:
	_apply_density_sizes()
	_apply_large_text()
	_setup_focus_traversal()
	var center: Control = get_node_or_null("Center")
	if center:
		center.pivot_offset = center.size / 2.0


func _ensure_level_select() -> void:
	var vbox: VBoxContainer = $Center/VBox
	var select: OptionButton = vbox.get_node_or_null("LevelSelect")
	if select == null:
		select = OptionButton.new()
		select.name = "LevelSelect"
		select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select.custom_minimum_size = Vector2(0, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
		vbox.add_child(select)
		vbox.move_child(select, start_btn.get_index())
	else:
		select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select.custom_minimum_size = Vector2(0, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	select.clear()
	var levels: Array = LevelCatalogScript.list_levels()
	var current := str(GameSession.selected_level_path)
	var picked := 0
	for i in levels.size():
		var entry: Dictionary = levels[i]
		select.add_item(str(entry.get("displayName", entry.get("id", "level"))), i)
		select.set_item_metadata(i, entry)
		if str(entry.get("path", "")) == current:
			picked = i
	if levels.is_empty():
		return
	select.select(picked)
	_apply_level_entry(levels[picked])
	ThemeTokensScript.set_a11y_metadata(select, "Scenario Selection", "Select tactical scenario or map")
	if not select.item_selected.is_connected(_on_level_selected):
		select.item_selected.connect(_on_level_selected)


func _on_level_selected(index: int) -> void:
	var select: OptionButton = _find_action("LevelSelect") as OptionButton
	if select == null:
		return
	var entry: Variant = select.get_item_metadata(index)
	if entry is Dictionary:
		_apply_level_entry(entry)


func _apply_level_entry(entry: Dictionary) -> void:
	GameSession.set_selected_level(str(entry.get("path", "")), str(entry.get("id", "")))


func _ensure_resume_and_history_ui(has_cpp: bool) -> void:
	var vbox: VBoxContainer = $Center/VBox
	if vbox.get_node_or_null("ResumeBtn") == null:
		_resume_btn = Button.new()
		_resume_btn.name = "ResumeBtn"
		_resume_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_resume_btn.custom_minimum_size = Vector2(0, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
		vbox.add_child(_resume_btn)
		vbox.move_child(_resume_btn, start_btn.get_index() + 1)
	else:
		_resume_btn = vbox.get_node("ResumeBtn")
		_resume_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_resume_btn.custom_minimum_size = Vector2(0, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	_resume_btn.text = "Resume last snapshot"
	_resume_btn.visible = has_cpp and OfflinePersistence.has_snapshot()
	_resume_btn.disabled = not _resume_btn.visible
	_resume_btn.pressed.connect(func():
		GameSession.resume_snapshot_on_next_battle = true
		get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")
	)

	var settings_btn: Button = vbox.get_node_or_null("SettingsBtn")
	if settings_btn == null:
		settings_btn = Button.new()
		settings_btn.name = "SettingsBtn"
		settings_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		settings_btn.custom_minimum_size = Vector2(0, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
		settings_btn.text = "Settings · 設置"
		settings_btn.pressed.connect(_open_settings)
		vbox.add_child(settings_btn)
		vbox.move_child(settings_btn, quit_btn.get_index())
	else:
		settings_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		settings_btn.custom_minimum_size = Vector2(0, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)

	ThemeTokensScript.set_a11y_metadata(start_btn, "Defend the Coast", "Start dual-front battle in modular view")
	ThemeTokensScript.set_a11y_metadata(_resume_btn, "Resume Last Snapshot", "Resume previous combat save from disk")
	ThemeTokensScript.set_a11y_metadata(classic_btn, "Classic Prototype", "Launch single-file canvas prototype")
	ThemeTokensScript.set_a11y_metadata(settings_btn, "Settings", "Configure audio, controls, accessibility, and privacy")
	ThemeTokensScript.set_a11y_metadata(quit_btn, "Quit", "Exit Mobile Fortress")

	if vbox.get_node_or_null("LastRunLabel") == null:
		_last_run_label = Label.new()
		_last_run_label.name = "LastRunLabel"
		_last_run_label.custom_minimum_size = Vector2(480, 0)
		_last_run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_last_run_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_last_run_label.add_theme_color_override("font_color", ThemeTokensScript.INK_MUTED)
		_last_run_label.add_theme_font_size_override("font_size", 13)
		vbox.add_child(_last_run_label)
		vbox.move_child(_last_run_label, classic_btn.get_index())
	else:
		_last_run_label = vbox.get_node("LastRunLabel")


func _ensure_campaign_rank_label() -> void:
	var vbox: VBoxContainer = $Center/VBox
	if vbox.get_node_or_null("CampaignRankLabel") == null:
		_campaign_rank_label = Label.new()
		_campaign_rank_label.name = "CampaignRankLabel"
		_campaign_rank_label.custom_minimum_size = Vector2(480, 0)
		_campaign_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_campaign_rank_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_campaign_rank_label.add_theme_color_override("font_color", ThemeTokensScript.INK)
		_campaign_rank_label.add_theme_font_size_override("font_size", 13)
		_campaign_rank_label.focus_mode = Control.FOCUS_NONE
		vbox.add_child(_campaign_rank_label)
		var blurb_node: Node = vbox.get_node_or_null("Blurb")
		if blurb_node:
			vbox.move_child(_campaign_rank_label, blurb_node.get_index() + 1)
	else:
		_campaign_rank_label = vbox.get_node("CampaignRankLabel")
	ThemeTokensScript.set_a11y_metadata(
		_campaign_rank_label,
		"Citadel rank",
		"Current citadel rank, progress to the next rank, and campaign star total"
	)


func _refresh_campaign_rank() -> void:
	if _campaign_rank_label == null:
		return
	var prestige := ProgressionScript.total_prestige()
	var tier: Dictionary = ProgressionScript.get_prestige_tier(prestige)
	var nxt: Dictionary = ProgressionScript.get_next_prestige_tier(prestige)
	var stars := ProgressionScript.total_stars()
	var title := str(tier.get("title", "Coastal Beacon"))
	if bool(nxt.get("max_rank_reached", false)):
		_campaign_rank_label.text = "Citadel · %s · max rank · campaign ★ %d" % [title, stars]
		return
	_campaign_rank_label.text = "Citadel · %s · %d/%d to %s · campaign ★ %d" % [
		title,
		prestige,
		int(nxt.get("next_prestige_required", 0)),
		str(nxt.get("next_title", "")),
		stars,
	]


func _ensure_version_label() -> void:
	if get_node_or_null("VersionLabel") != null:
		return
	var version := Label.new()
	version.name = "VersionLabel"
	version.text = "Slice-0 · DT8"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -220
	version.offset_top = -52
	version.offset_right = -16
	version.offset_bottom = -4
	version.custom_minimum_size = Vector2(160, ThemeTokensScript.MIN_TOUCH_TARGET_SIZE)
	version.add_theme_color_override("font_color", ThemeTokensScript.PAPER)
	version.add_theme_font_size_override("font_size", 12)
	version.mouse_filter = Control.MOUSE_FILTER_STOP
	version.gui_input.connect(_on_version_gui_input)
	ThemeTokensScript.set_a11y_metadata(version, "Build Version", "Shows game slice and dev version")
	add_child(version)


func _on_version_gui_input(event: InputEvent) -> void:
	var tapped := false
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		tapped = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		tapped = (event as InputEventScreenTouch).pressed
	if tapped:
		var session := get_tree().root.get_node_or_null("GameSession")
		if session:
			session.register_dev_tap()


func _open_settings() -> void:
	if get_node_or_null("SettingsDialog") != null:
		return
	var settings_btn: Button = _find_action("SettingsBtn") as Button
	var dlg := SettingsDialogScript.new()
	dlg.name = "SettingsDialog"
	dlg.opener_control = settings_btn
	_set_menu_focus_enabled(false)
	dlg.closed.connect(func():
		_set_menu_focus_enabled(true)
		_apply_large_text()
		_setup_focus_traversal()
		if is_instance_valid(settings_btn):
			settings_btn.call_deferred("grab_focus")
	)
	add_child(dlg)


func _set_menu_focus_enabled(enabled: bool) -> void:
	var mode := Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	for action_name in ["LevelSelect", "StartBtn", "ResumeBtn", "ClassicBtn", "SettingsBtn", "QuitBtn"]:
		var child: Control = _find_action(action_name)
		if child is BaseButton:
			(child as BaseButton).focus_mode = mode


func _apply_large_text() -> void:
	var settings: Dictionary = OfflinePersistence.read_settings()
	var is_large: bool = bool(settings.get("large_text", false))
	var center: Control = get_node_or_null("Center")
	var vbox: VBoxContainer = center.get_node_or_null("VBox") if center else null
	var vp: Viewport = get_viewport()
	var vp_size: Vector2 = vp.get_visible_rect().size if vp else ThemeTokensScript.CANVAS_DESIGN_SIZE
	var is_compact_landscape: bool = vp_size.y <= 720.0 and vp_size.x > 1280.0
	if vbox:
		vbox.scale = Vector2.ONE
		vbox.pivot_offset = vbox.size / 2.0
	if center:
		# Never scale the full-rect Center: 1.15× from the viewport center clips Title and Quit
		# on compact landscape when font metrics exceed the measured vbox height (CI 844×390).
		center.pivot_offset = center.size / 2.0
		if is_large and not is_compact_landscape:
			center.scale = Vector2.ONE * ThemeTokensScript.LARGE_TEXT_SCALE
		else:
			center.scale = Vector2.ONE
		if not center.resized.is_connected(_on_center_resized):
			center.resized.connect(_on_center_resized)
	if is_large and is_compact_landscape:
		call_deferred("_fit_compact_large_text")


func _fit_compact_large_text() -> void:
	var settings: Dictionary = OfflinePersistence.read_settings()
	if not bool(settings.get("large_text", false)):
		return
	var center: Control = get_node_or_null("Center")
	var vbox: VBoxContainer = center.get_node_or_null("VBox") if center else null
	var vp: Viewport = get_viewport()
	if vbox == null or vp == null:
		return
	var vp_size: Vector2 = vp.get_visible_rect().size
	if vp_size.y > 720.0 or vp_size.x <= 1280.0:
		return
	var vbox_h: float = maxf(vbox.size.y, vbox.get_combined_minimum_size().y)
	var s: float = ThemeTokensScript.LARGE_TEXT_SCALE
	if vbox_h > 0.0:
		s = minf(s, (vp_size.y - 16.0) / vbox_h)
	var canvas_scale: float = ThemeTokensScript.get_window_canvas_scale(_window_size_for_density())
	var rendered_at_one: float = _density_min_h() * canvas_scale
	if rendered_at_one > 0.0:
		s = maxf(s, ThemeTokensScript.MIN_DP_TARGET / rendered_at_one)
	s = clampf(s, 0.01, ThemeTokensScript.LARGE_TEXT_SCALE)
	vbox.pivot_offset = vbox.size / 2.0
	vbox.scale = Vector2(s, s)


func _on_center_resized() -> void:
	var center: Control = get_node_or_null("Center")
	if center:
		center.pivot_offset = center.size / 2.0


func _setup_focus_traversal() -> void:
	var controls: Array[Control] = []
	var select: OptionButton = _find_action("LevelSelect") as OptionButton
	if select and select.visible and not select.disabled:
		controls.append(select)
	if start_btn and start_btn.visible and not start_btn.disabled:
		controls.append(start_btn)
	if _resume_btn and _resume_btn.visible and not _resume_btn.disabled:
		controls.append(_resume_btn)
	if classic_btn and classic_btn.visible and not classic_btn.disabled:
		controls.append(classic_btn)
	var settings_btn: Button = _find_action("SettingsBtn") as Button
	if settings_btn and settings_btn.visible and not settings_btn.disabled:
		controls.append(settings_btn)
	if quit_btn and quit_btn.visible and not quit_btn.disabled:
		controls.append(quit_btn)

	for i in range(controls.size()):
		var ctrl := controls[i]
		if ctrl is Button:
			ThemeTokensScript.apply_accessible_button(ctrl)
		else:
			ThemeTokensScript.apply_accessible_focus(ctrl)
		var next_ctrl := controls[(i + 1) % controls.size()]
		var prev_ctrl := controls[(i - 1 + controls.size()) % controls.size()]
		ctrl.focus_next = next_ctrl.get_path()
		ctrl.focus_previous = prev_ctrl.get_path()
		ctrl.focus_neighbor_bottom = next_ctrl.get_path()
		ctrl.focus_neighbor_top = prev_ctrl.get_path()
		ctrl.focus_neighbor_left = ctrl.get_path()
		ctrl.focus_neighbor_right = ctrl.get_path()


func _set_initial_focus() -> void:
	if _resume_btn and _resume_btn.visible and not _resume_btn.disabled:
		_resume_btn.grab_focus()
	elif start_btn and not start_btn.disabled:
		start_btn.grab_focus()
	elif classic_btn:
		classic_btn.grab_focus()


func _refresh_last_run() -> void:
	if _last_run_label == null:
		return
	var result: Dictionary = OfflinePersistence.read_results()
	var history: Array = OfflinePersistence.read_history()
	var summary := OfflinePersistence.format_results_summary(result)
	if history.size() > 0:
		summary += "\n(%d run(s) in offline history)" % history.size()
	_last_run_label.text = summary
