class_name BeamTower
extends Tower
## Tour à rayon continu sur une seule cible. Chaque « tir » est une impulsion du
## rayon : beaucoup de petits coups, que l'armure réduit fortement. Plus le rayon
## reste sur la même cible, plus il fait mal (jusqu'à `beam_ramp_max` fois après
## `beam_ramp_time` secondes) ; changer de cible fait repartir de zéro.

## Identifiant de l'ennemi sur lequel le rayon chauffe (0 = aucun).
var _ramp_target_id := 0
var _ramp_time := 0.0


func _process(delta: float) -> void:
	super(delta)
	if _target and _target.get_instance_id() == _ramp_target_id:
		_ramp_time += delta
	else:
		_reset_ramp(_target)
	# Le rayon suit sa cible et disparaît avec elle : on redessine à chaque image.
	queue_redraw()


func _reset_ramp(new_target: Enemy) -> void:
	_ramp_target_id = new_target.get_instance_id() if new_target else 0
	_ramp_time = 0.0


## Multiplicateur de dégâts actuel, de 1 à beam_ramp_max.
func get_ramp_multiplier() -> float:
	if stats.beam_ramp_time <= 0.0:
		return stats.beam_ramp_max
	return lerpf(1.0, stats.beam_ramp_max, clampf(_ramp_time / stats.beam_ramp_time, 0.0, 1.0))


func _attack(enemy: Enemy) -> void:
	# Nouvelle cible choisie pendant cette image : le rayon repart de zéro avant de frapper.
	if enemy.get_instance_id() != _ramp_target_id:
		_reset_ramp(enemy)
	enemy.take_damage(stats.damage * get_ramp_multiplier())


func _draw_body() -> void:
	super()
	var heat := inverse_lerp(1.0, maxf(stats.beam_ramp_max, 1.001), get_ramp_multiplier())
	var core := data.color.lerp(Color.WHITE, 0.3 + 0.5 * heat)
	# Cristal en losange au centre du socle.
	var r := SIZE * 0.32
	draw_colored_polygon(PackedVector2Array([Vector2(0, -r), Vector2(r * 0.7, 0), Vector2(0, r), Vector2(-r * 0.7, 0)]), data.color)
	draw_circle(Vector2.ZERO, SIZE * 0.1, core)
	if is_instance_valid(_target) and _target.is_alive:
		var end := to_local(_target.global_position)
		var width := 2.0 + 4.0 * heat
		draw_line(Vector2.ZERO, end, Color(data.color, 0.5), width + 4.0)
		draw_line(Vector2.ZERO, end, core, width)
		draw_circle(end, width + 2.0, Color(core, 0.8))
