class_name MeteorStrike
extends Node2D
## Pouvoir Météores : des météores tombent l'un après l'autre sur une zone. Chacun met
## FALL_TIME à tomber (son ombre grandit au sol), puis explose et blesse tous les
## ennemis à portée de son explosion.

## Temps de chute d'un météore, et écart entre deux météores.
const FALL_TIME := 0.45
const INTERVAL := 0.16
## D'où arrive un météore, par rapport à son point d'impact.
const FALL_FROM := Vector2(-110, -260)
const ROCK_RADIUS := 9.0

## Statistiques du pouvoir (Power) : nombre, dégâts, zone et explosion.
var power: Power
var _meteors: Array[Dictionary] = []
var _age := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Le tirage dépend du point visé : le même lancer donne la même pluie.
	_rng.seed = hash(Vector2i(global_position))
	for i in power.count:
		# Le premier tombe au centre, les autres au hasard dans la zone.
		var offset := Vector2.ZERO
		if i > 0:
			offset = Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * power.radius
		_meteors.append({ at = offset, lands_at = FALL_TIME + i * INTERVAL, done = false })


func _process(delta: float) -> void:
	_age += delta
	var finished := true
	for meteor in _meteors:
		if not meteor.done and _age >= meteor.lands_at:
			meteor.done = true
			_impact(meteor.at)
		finished = finished and meteor.done
	queue_redraw()
	if finished:
		queue_free()


## Fin de la pluie (secondes après le lancer).
func get_duration() -> float:
	return FALL_TIME + maxi(power.count - 1, 0) * INTERVAL


func _impact(offset: Vector2) -> void:
	var at := global_position + offset
	for enemy in Enemy.get_alive_in_radius(get_tree(), at, power.splash_radius):
		enemy.take_damage(power.damage)
	var explosion := Explosion.new()
	explosion.radius = power.splash_radius
	explosion.color = power.color
	get_parent().add_child(explosion)
	explosion.global_position = at
	Sound.play(&"explosion", -4.0)


func _draw() -> void:
	# Zone visée, tant que des météores tombent.
	draw_arc(Vector2.ZERO, power.radius, 0.0, TAU, 48, Color(power.color, 0.35), 2.0)
	for meteor in _meteors:
		if meteor.done:
			continue
		var t: float = clampf(1.0 - (meteor.lands_at - _age) / FALL_TIME, 0.0, 1.0)
		if t <= 0.0:
			continue
		var at: Vector2 = meteor.at
		# Ombre au sol qui grandit, puis le météore et sa traînée.
		draw_circle(at, power.splash_radius * 0.5 * t, Color(0, 0, 0, 0.25 * t))
		var rock := at + FALL_FROM * (1.0 - t)
		draw_line(rock + FALL_FROM.normalized() * 34.0, rock, Color(power.color, 0.6), ROCK_RADIUS * 1.2)
		draw_circle(rock, ROCK_RADIUS, power.color)
		draw_circle(rock + Vector2(-2, -2), ROCK_RADIUS * 0.5, Color(1, 0.9, 0.6))
