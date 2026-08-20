class_name ThemeTokens
extends RefCounted
## Shared UI & HUD Design Tokens for Mobile Fortress (U10)
## Centralizes Wōkòu-era cartographic colors, styleboxes, font sizes, and transition helpers.

# --- Color Palette (Ukiyo-e Cartography & Ming Historical) ---
const INK := Color("1a1a2e")             # Deep ink-wash charcoal
const INK_MUTED := Color("454558")       # Secondary text & subtle borders
const PAPER := Color("f4e9d8")           # Parchment background
const PAPER_CARD := Color("ede0cb")      # Elevated parchment panel
const PAPER_TRANSLUCENT := Color(0.95, 0.91, 0.84, 0.94)

const CINNABAR := Color("c23b22")        # Vermillion accent & threat
const CINNABAR_DEEP := Color("8b1e1e")   # Crimson danger / loss
const GOLD := Color("c9a227")            # Victory stars, hero aura
const OCHRE := Color("c4842d")           # Brass / cannon / warm accent

const MOSS_LAND := Color("3d5c45")       # Land front & 兩 currency
const MOSS_LAND_BRIGHT := Color("6b8f71")
const SEA_INDIGO := Color("1b3a4b")      # Sea front & 海關兩 currency
const SEA_INDIGO_BRIGHT := Color("3d5a80")

# --- Currency & Glyphs ---
const GLYPH_LAND_CURRENCY := "兩"
const GLYPH_SEA_CURRENCY := "海關兩"
const GLYPH_HQ := "🏰 HQ"
const GLYPH_OUTPOST_LAND := "🌾 糧倉"
const GLYPH_OUTPOST_SEA := "⛵ 港埠"
const GLYPH_THREAT_SKULL := "☠"
const GLYPH_STAR := "★"


# --- Reusable StyleBox Builders ---
static func make_panel_style(bg: Color = PAPER_TRANSLUCENT, border: Color = CINNABAR, radius: int = 4, pad: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = pad
	style.content_margin_top = pad
	style.content_margin_right = pad
	style.content_margin_bottom = pad
	return style


static func make_button_style(bg: Color = PAPER_CARD, border: Color = INK, radius: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	return style


# --- Transition Helpers (Modal Fade / Slide) ---
static func animate_fade_in(node: CanvasItem, duration: float = 0.25) -> void:
	if node == null or not node.is_inside_tree():
		return
	node.modulate = Color(1, 1, 1, 0)
	node.visible = true
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(node, "modulate:a", 1.0, duration)


static func animate_slide_fade_in(node: Control, from_offset_y: float = -20.0, duration: float = 0.3) -> void:
	if node == null or not node.is_inside_tree():
		return
	var orig_pos := node.position
	node.position = orig_pos + Vector2(0, from_offset_y)
	node.modulate = Color(1, 1, 1, 0)
	node.visible = true
	var tween := node.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "position", orig_pos, duration)
	tween.tween_property(node, "modulate:a", 1.0, duration)
