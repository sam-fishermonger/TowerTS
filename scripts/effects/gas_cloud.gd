class_name GasCloud
extends Node2D
## Nuage laissé par une grenade (Pesticide, Lacrymogène) : pendant `stats.cloud_duration`
## secondes, il applique régulièrement les effets de la tour (poison, ralentissement,
## soins bloqués) aux ennemis qui sont dedans, sans dégâts directs.

## Les effets sont réappliqués à ce rythme, en secondes.
const TICK := 0.25
## Le nuage s'efface pendant ses dernières secondes.
const FADE := 0.6

var stats: TowerData

var _age := 0.0
var _tick_left := 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= stats.cloud_duration:
		queue_free()
		return
	_tick_left -= delta
	if _tick_left <= 0.0:
		_tick_left += TICK
		for enemy in Enemy.get_alive_in_radius(get_tree(), global_position, stats.cloud_radius):
			enemy.hit(0.0, stats)
	queue_redraw()


func _draw() -> void:
	var alpha := clampf((stats.cloud_duration - _age) / FADE, 0.0, 1.0) * clampf(_age / 0.15, 0.0, 1.0)
	var color := stats.color
	# Quelques volutes qui tournent lentement autour du centre.
	draw_circle(Vector2.ZERO, stats.cloud_radius, Color(color, 0.18 * alpha))
	for i in 5:
		var angle := TAU * i / 5.0 + _age * 0.6
		draw_circle(Vector2.from_angle(angle) * stats.cloud_radius * 0.45, stats.cloud_radius * 0.45,
			Color(color.lightened(0.2), 0.12 * alpha))
	draw_arc(Vector2.ZERO, stats.cloud_radius, 0.0, TAU, 40, Color(color, 0.4 * alpha), 2.0)
