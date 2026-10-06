class_name RailTower
extends Tower
## Perforateur : un tir instantané qui traverse tout sur sa ligne, jusqu'au bout de
## la portée, et touche chaque ennemi qu'il croise.

## Demi-largeur du tir : un ennemi est touché si son bord est à moins de ça de la ligne.
const LINE_HALF_WIDTH := 6.0
const TRAIL_DURATION := 0.3

var _trail_left := 0.0
var _trail_end := Vector2.ZERO


func _process(delta: float) -> void:
	super(delta)
	if _trail_left > 0.0:
		_trail_left = maxf(_trail_left - delta, 0.0)
		queue_redraw()


## Ennemis traversés par un tir vers `angle`, du plus proche au plus lointain.
func get_enemies_on_line(angle: float) -> Array[Enemy]:
	var end := global_position + Vector2.from_angle(angle) * stats.attack_range
	var result: Array[Enemy] = []
	for enemy in Enemy.get_alive_in_radius(get_tree(), global_position, stats.attack_range + 30.0):
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, global_position, end)
		if closest.distance_to(enemy.global_position) <= enemy.data.radius + LINE_HALF_WIDTH:
			result.append(enemy)
	result.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	return result


func _attack(enemy: Enemy) -> void:
	var angle := global_position.angle_to_point(enemy.global_position)
	for target in get_enemies_on_line(angle):
		target.hit(stats.damage, stats)
	_trail_end = Vector2.from_angle(angle) * stats.attack_range
	_trail_left = TRAIL_DURATION


func _draw_shape() -> void:
	draw_circle(Vector2.ZERO, SIZE * 0.3, data.color)
	draw_line(Vector2.ZERO, Vector2.from_angle(_aim_angle) * SIZE * 0.6, data.color.lightened(0.3), 6.0)


func _draw_effects() -> void:
	if _trail_left <= 0.0:
		return
	var alpha := _trail_left / TRAIL_DURATION
	var start := _trail_end.normalized() * SIZE * 0.5
	draw_line(start, _trail_end, Color(data.color, 0.5 * alpha), 8.0 * alpha + 2.0)
	draw_line(start, _trail_end, Color(1, 1, 1, alpha), 2.0)
