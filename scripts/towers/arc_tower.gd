class_name ArcTower
extends Tower
## Arc électrique : un éclair instantané frappe la cible, puis rebondit sur l'ennemi le
## plus proche qu'il n'a pas encore touché, `stats.chain_count` fois au plus, en perdant
## un peu de sa force à chaque rebond (`stats.chain_falloff`).

const FLASH_DURATION := 0.18
## Écart des zigzags de l'éclair, de part et d'autre de la ligne droite.
const JAGGEDNESS := 7.0

var _flash_left := 0.0
## Points touchés par le dernier éclair (positions globales), de la tour à la dernière cible.
var _flash_points := PackedVector2Array()


func _process(delta: float) -> void:
	super(delta)
	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
		queue_redraw()


## Ennemis touchés par un éclair qui part sur `first`, dans l'ordre des rebonds.
func get_chain(first: Enemy) -> Array[Enemy]:
	var chain: Array[Enemy] = [first]
	var current := first
	for i in stats.chain_count:
		var next: Enemy = null
		var best := INF
		for enemy in Enemy.get_alive_in_radius(get_tree(), current.global_position, stats.chain_range, stats):
			var distance := current.global_position.distance_squared_to(enemy.global_position)
			if not chain.has(enemy) and distance < best:
				next = enemy
				best = distance
		if next == null:
			break
		chain.append(next)
		current = next
	return chain


func _attack(enemy: Enemy) -> void:
	var amount := stats.damage
	_flash_points = PackedVector2Array([global_position])
	for target in get_chain(enemy):
		_flash_points.append(target.global_position)
		target.hit(amount, stats)
		amount *= stats.chain_falloff
	_flash_left = FLASH_DURATION


func _draw_shape() -> void:
	draw_circle(Vector2.ZERO, SIZE * 0.3, data.color.darkened(0.2))
	draw_circle(Vector2.ZERO, SIZE * 0.14, data.color.lightened(0.5))


func _draw_effects() -> void:
	if _flash_left <= 0.0 or _flash_points.size() < 2:
		return
	var alpha := _flash_left / FLASH_DURATION
	# L'éclair change de forme à chaque image : il crépite.
	var rng := RandomNumberGenerator.new()
	rng.seed = Engine.get_process_frames()
	for i in _flash_points.size() - 1:
		var from := to_local(_flash_points[i])
		var to := to_local(_flash_points[i + 1])
		if i == 0:
			from += from.direction_to(to) * SIZE * 0.4
		var points := PackedVector2Array([from])
		var normal := from.direction_to(to).orthogonal()
		for step in range(1, 5):
			points.append(from.lerp(to, step / 5.0) + normal * rng.randf_range(-JAGGEDNESS, JAGGEDNESS))
		points.append(to)
		draw_polyline(points, Color(data.color, 0.45 * alpha), 6.0)
		draw_polyline(points, Color(1, 1, 1, alpha), 2.0)
		draw_circle(to, 5.0 * alpha + 2.0, Color(data.color.lightened(0.4), alpha))
