class_name CooldownRing
extends Control
## Procedural Radial Cooldown Ring (U10)
## Draws a circular progress ring and status indicator for hero abilities and actions.

const ThemeTokensScript := preload("res://scripts/ui/theme_tokens.gd")

var cooldown_left: float = 0.0
var max_cooldown: float = 10.0
var ring_radius: float = 11.0
var ring_width: float = 2.5


func _init() -> void:
	custom_minimum_size = Vector2(28, 28)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_cooldown(left: float, total: float = 10.0) -> void:
	cooldown_left = maxf(0.0, left)
	max_cooldown = maxf(0.1, total)
	queue_redraw()


func is_ready() -> bool:
	return cooldown_left <= 0.0


func _draw() -> void:
	var center := size * 0.5
	if center == Vector2.ZERO:
		center = Vector2(14, 14)

	var is_act_ready := is_ready()
	var ratio := 1.0 - clampf(cooldown_left / max_cooldown, 0.0, 1.0)

	if is_act_ready:
		# Full ready ring with golden glow
		draw_circle(center, ring_radius + 2.0, Color(ThemeTokensScript.GOLD.r, ThemeTokensScript.GOLD.g, ThemeTokensScript.GOLD.b, 0.2))
		draw_arc(center, ring_radius, 0.0, TAU, 28, ThemeTokensScript.GOLD, ring_width)
		draw_circle(center, 3.0, ThemeTokensScript.GOLD)
	else:
		# Background dark track
		draw_arc(center, ring_radius, 0.0, TAU, 24, Color(ThemeTokensScript.INK.r, ThemeTokensScript.INK.g, ThemeTokensScript.INK.b, 0.35), ring_width)
		# Active progress sweep arc (starts at 12 o'clock / -PI/2)
		if ratio > 0.01:
			var start_angle := -PI * 0.5
			var sweep_angle := TAU * ratio
			draw_arc(center, ring_radius, start_angle, start_angle + sweep_angle, 28, ThemeTokensScript.CINNABAR.lerp(ThemeTokensScript.GOLD, ratio), ring_width)
		# Center hourglass dot
		draw_circle(center, 2.0, ThemeTokensScript.INK_MUTED)
