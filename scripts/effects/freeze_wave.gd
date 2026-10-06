class_name FreezeWave
extends Node2D
## Pouvoir Gel : un voile bleu glacé qui couvre la zone de jeu puis s'efface.

const DURATION := 0.7

var area := Rect2()
var color := Color(0.55, 0.85, 1.0)

var _age := 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := clampf(_age / DURATION, 0.0, 1.0)
	draw_rect(area, Color(color, 0.35 * (1.0 - t)))
	draw_rect(area.grow(-6.0 * t), Color(Color.WHITE, 0.6 * (1.0 - t)), false, 6.0)
