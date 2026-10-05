class_name Explosion
extends Node2D
## Effet visuel bref : un cercle qui grandit et s'efface.

const DURATION := 0.25

var radius := 50.0
var color := Color.ORANGE

var _age := 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := clampf(_age / DURATION, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius * t, Color(color, 0.35 * (1.0 - t)))
	draw_arc(Vector2.ZERO, radius * t, 0.0, TAU, 32, Color(color, 1.0 - t), 2.0)
