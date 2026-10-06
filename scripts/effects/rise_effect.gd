class_name RiseEffect
extends Node2D
## Ennemi tombé qui va se relever (EnemyData.revive_count) : une tache sombre qui
## grandit et des volutes violettes qui montent, puis `risen` quand il se relève.

signal risen

const COLOR := Color(0.6, 0.4, 0.95)

var radius := 12.0
## Secondes avant de se relever.
var duration := 1.5

var _age := 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= duration:
		risen.emit()
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_age / duration, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius * (0.6 + 0.6 * t), Color(0.08, 0.04, 0.12, 0.55))
	draw_arc(Vector2.ZERO, radius * (0.6 + 0.6 * t), 0.0, TAU, 32, Color(COLOR, 0.4 + 0.5 * t), 2.0)
	# Volutes qui montent du sol, de plus en plus vite.
	for i in 5:
		var phase := fposmod(t * 2.0 + i / 5.0, 1.0)
		var x := sin(i * 2.4 + t * 6.0) * radius * 0.7
		draw_circle(Vector2(x, -phase * radius * 1.8), 2.0 + 2.0 * (1.0 - phase), Color(COLOR, 0.7 * (1.0 - phase)))
