class_name FlameTower
extends Tower
## Lance-flammes : à chaque tir, un jet de flammes frappe tous les ennemis dans un
## cône tourné vers la cible (ouverture `cone_angle`), et les fait brûler.

## Durée d'affichage d'un jet : les tirs se suivent assez vite pour un jet continu.
const FLAME_DURATION := 0.25

var _flame_left := 0.0


func _process(delta: float) -> void:
	super(delta)
	if _flame_left > 0.0:
		_flame_left = maxf(_flame_left - delta, 0.0)
		queue_redraw()


## Ennemis à portée dans le cône de flammes tourné vers `angle`.
func get_enemies_in_cone(angle: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var half_angle := deg_to_rad(stats.cone_angle) / 2.0
	for enemy in Enemy.get_alive_in_radius(get_tree(), global_position, stats.attack_range):
		var to_enemy := enemy.global_position - global_position
		# Un ennemi sur la tour elle-même est toujours touché.
		if to_enemy.length() < 1.0 or absf(angle_difference(angle, to_enemy.angle())) <= half_angle:
			result.append(enemy)
	return result


func _attack(enemy: Enemy) -> void:
	var angle := global_position.angle_to_point(enemy.global_position)
	for target in get_enemies_in_cone(angle):
		target.hit(stats.damage, stats)
	_flame_left = FLAME_DURATION


func _draw_shape() -> void:
	draw_circle(Vector2.ZERO, SIZE * 0.3, data.color)
	draw_line(Vector2.ZERO, Vector2.from_angle(_aim_angle) * SIZE * 0.5, data.color.darkened(0.3), 8.0)


func _draw_effects() -> void:
	if _flame_left <= 0.0:
		return
	var alpha := _flame_left / FLAME_DURATION
	var half_angle := deg_to_rad(stats.cone_angle) / 2.0
	var start := Vector2.from_angle(_aim_angle) * SIZE * 0.45
	# Deux cônes : le jet orangé, puis son cœur jaune, plus court et plus étroit.
	for layer in [[1.0, 1.0, Color(data.color, 0.45)], [0.6, 0.55, Color(1.0, 0.9, 0.4, 0.6)]]:
		var length: float = stats.attack_range * layer[0]
		var spread: float = half_angle * layer[1]
		var points := PackedVector2Array([start])
		for i in 7:
			points.append(Vector2.from_angle(_aim_angle - spread + spread * 2.0 * i / 6.0) * length)
		var color: Color = layer[2]
		draw_colored_polygon(points, Color(color, color.a * alpha))
