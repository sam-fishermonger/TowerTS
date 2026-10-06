class_name PulseTower
extends Tower
## Tour sans projectile : à chaque tir, une onde frappe tous les ennemis à portée,
## avec les effets de ses statistiques (ralentissement du Givre, bouclier brouillé
## du Brouilleur, recul de l'Électroaimant, dont l'onde se resserre vers la tour).

const PULSE_DURATION := 0.35

var _pulse_time_left := 0.0


func _process(delta: float) -> void:
	super(delta)
	if _pulse_time_left > 0.0:
		_pulse_time_left = maxf(_pulse_time_left - delta, 0.0)
		queue_redraw()


func uses_target_mode() -> bool:
	return false


func _attack(_enemy: Enemy) -> void:
	for enemy in Enemy.get_alive_in_radius(get_tree(), global_position, stats.attack_range):
		enemy.hit(stats.damage, stats)
	_pulse_time_left = PULSE_DURATION


func _draw_shape() -> void:
	var light := data.color.lightened(0.4)
	for i in 3:
		var direction := Vector2.from_angle(i * PI / 3.0) * SIZE * 0.34
		draw_line(-direction, direction, light, 4.0)
	draw_circle(Vector2.ZERO, SIZE * 0.12, data.color)


func _draw_effects() -> void:
	var light := data.color.lightened(0.4)
	if _pulse_time_left > 0.0:
		var t := 1.0 - _pulse_time_left / PULSE_DURATION
		var radius := stats.attack_range * (1.0 - t if stats.knockback > 0.0 else t)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(light, 1.0 - t), 3.0)
