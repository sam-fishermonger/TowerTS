class_name FlameTower
extends Tower
## Lance-flammes : à chaque tir, un jet de flammes frappe tous les ennemis dans un
## cône tourné vers la cible (ouverture `cone_angle`), et les fait brûler.

## Durée d'affichage d'un jet : les tirs se suivent assez vite pour un jet continu.
const FLAME_DURATION := 0.25
## Vue de trois quarts : langues de feu du jet, et boules de flamme dans chacune.
const TONGUES := 5
const PUFFS := 9
## Hauteur au-dessus du sol où le jet s'écrase (le corps des monstres).
const IMPACT_HEIGHT := 9.0
## Couches du jet, de l'extérieur au cœur : couleur, taille relative, jusqu'où elle va.
const FLAME_LAYERS: Array[Array] = [
	[Color(0.85, 0.2, 0.08, 0.5), 1.0, 1.0],
	[Color(1.0, 0.5, 0.12, 0.7), 0.72, 0.95],
	[Color(1.0, 0.85, 0.35, 0.85), 0.45, 0.75],
	[Color(1.0, 0.98, 0.8, 0.9), 0.22, 0.4],
]

var _flame_left := 0.0


func _process(delta: float) -> void:
	super(delta)
	if _flame_left > 0.0:
		_flame_left = maxf(_flame_left - delta, 0.0)
		if not Relief.headless:
			queue_redraw()


## Ennemis à portée dans le cône de flammes tourné vers `angle`.
func get_enemies_in_cone(angle: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var half_angle := deg_to_rad(stats.cone_angle) / 2.0
	for enemy in Enemy.get_alive_in_radius(get_tree(), global_position, stats.attack_range, stats):
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


## Vue de trois quarts : la zone touchée rougeoie au sol, sous la tour.
func _draw_ground_effects() -> void:
	if _flame_left <= 0.0:
		return
	var alpha := _flame_left / FLAME_DURATION
	var half_angle := deg_to_rad(stats.cone_angle) / 2.0
	for layer in [[1.0, Color(1.0, 0.4, 0.1, 0.16)], [0.65, Color(1.0, 0.7, 0.25, 0.14)]]:
		var points := PackedVector2Array()
		var length: float = stats.attack_range * layer[0]
		for i in 9:
			points.append(Vector2.from_angle(_aim_angle - half_angle + half_angle * 2.0 * i / 8.0) * length)
		for i in 5:
			points.append(Vector2.from_angle(_aim_angle + half_angle - half_angle * 2.0 * i / 4.0) * SIZE * 0.55)
		var color: Color = layer[1]
		draw_colored_polygon(points, Color(color, color.a * alpha))


func _draw_effects() -> void:
	if _flame_left <= 0.0:
		return
	var alpha := _flame_left / FLAME_DURATION
	if Relief.enabled:
		_draw_relief_flame(alpha)
		return
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


## Vue de trois quarts : le jet part de la lance, en haut du donjon, et s'abat en
## s'élargissant sur les monstres du cône. Il est fait de langues de feu qui ondulent,
## chacune une file de boules de flamme : rouge autour, cœur jaune puis blanc, et un peu
## de fumée au bout.
func _draw_relief_flame(alpha: float) -> void:
	# Les effets sont dessinés depuis le haut du donjon : on revient au pied de la tour.
	draw_set_transform(Vector2.ZERO)
	var nozzle := TowerRelief.flame_nozzle(_aim_angle, level - 1)
	var half_angle := deg_to_rad(stats.cone_angle) / 2.0
	var time := Time.get_ticks_msec() / 1000.0
	# Les langues du fond (plus haut sur l'écran) d'abord, celles du devant par-dessus.
	var tongues: Array[Dictionary] = []
	for k in TONGUES:
		var side := lerpf(-0.8, 0.8, float(k) / (TONGUES - 1))
		var angle := _aim_angle + half_angle * side + sin(time * 9.0 + k * 1.7) * 0.07
		var length := stats.attack_range * (1.0 - 0.18 * absf(side)) * (0.9 + 0.1 * sin(time * 13.0 + k * 2.3))
		tongues.append({"end": Vector2.from_angle(angle) * length - Vector2(0, IMPACT_HEIGHT), "seed": k * 1.3})
	tongues.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.end.y < b.end.y)
	for tongue in tongues:
		var end: Vector2 = tongue.end
		var smoke := nozzle.lerp(end, 1.08) + Vector2(0, -6.0 - 4.0 * sin(time * 7.0 + tongue.seed))
		draw_circle(smoke, 10.0, Color(0.22, 0.18, 0.17, 0.3 * alpha), true, -1.0, true)
	for layer in FLAME_LAYERS:
		var color: Color = layer[0]
		color.a *= alpha
		for tongue in tongues:
			var end: Vector2 = tongue.end
			for i in PUFFS:
				var t := (i + 0.5) / PUFFS
				if t > layer[2]:
					break
				# Le jet ondule un peu de part et d'autre de sa ligne.
				var wave := sin(time * 18.0 + i * 1.1 + tongue.seed) * 3.0 * t
				var at := nozzle.lerp(end, t) + (end - nozzle).normalized().orthogonal() * wave
				var radius := lerpf(3.5, 15.0, t) * (0.85 + 0.15 * sin(time * 23.0 + i * 1.9 + tongue.seed))
				draw_circle(at, radius * layer[1], color, true, -1.0, true)
