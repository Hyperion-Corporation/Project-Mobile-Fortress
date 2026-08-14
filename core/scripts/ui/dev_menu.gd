extends CanvasLayer
## DT8 stub overlay — cheats (DT1–DT4) and diagnostics (DT5/DT7) land later.

const INK := Color(0.10, 0.09, 0.12, 1)
const PAPER := Color(0.93, 0.86, 0.74, 0.94)
const CINNABAR := Color(0.72, 0.20, 0.14, 1)

var _panel: PanelContainer
var _status: Label


func _ready() -> void:
	layer = 128
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	name = "DevMenu"
	_build()


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_panel.offset_left = -340
	_panel.offset_top = 12
	_panel.offset_right = -12
	_panel.offset_bottom = 168
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = CINNABAR
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", style)
	root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	var title := Label.new()
	title.name = "Title"
	title.text = "DEVELOPER MODE · DT8"
	title.add_theme_color_override("font_color", CINNABAR)
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	_status = Label.new()
	_status.name = "Status"
	_status.text = "Unlocked. Cheats (DT1–DT4) and overlay (DT5) are not wired yet."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(300, 0)
	_status.add_theme_color_override("font_color", INK)
	_status.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_status)

	var hint := Label.new()
	hint.text = "~ / F12 close · Settings → Developer Mode"
	hint.add_theme_color_override("font_color", Color(0.3, 0.28, 0.26, 1))
	hint.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hint)

	var close_btn := Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "Close"
	close_btn.pressed.connect(func():
		var session := get_tree().root.get_node_or_null("GameSession")
		if session:
			session.set_dev_menu_open(false)
	)
	vbox.add_child(close_btn)
