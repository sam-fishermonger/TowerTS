class_name FloatingText
extends Node2D
## Texte bref qui monte et s'efface : dégâts infligés, or gagné.

const DURATION := 0.8
## Distance parcourue vers le haut pendant toute la durée, en pixels.
const RISE := 28.0

var text := ""
var color := Color.WHITE
var font_size := 14

var _age := 0.0
var _start := Vector2.ZERO


func _ready() -> void:
	_start = position


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	var t := _age / DURATION
	# Monte vite puis ralentit.
	position = _start + Vector2(0, -RISE * (1.0 - pow(1.0 - t, 2.0)))
	# Reste net pendant la première moitié, puis s'efface (le texte n'est dessiné qu'une fois).
	modulate.a = 1.0 - maxf(t - 0.5, 0.0) * 2.0


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := Vector2(-width / 2.0, 0)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 0.8))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
