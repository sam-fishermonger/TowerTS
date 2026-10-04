class_name Projectile
extends Node2D
## Projectile à tête chercheuse. Si la cible disparaît, il finit sa course
## jusqu'à sa dernière position connue puis disparaît.

var target: Enemy
var damage := 0.0
var speed := 500.0
var color := Color.WHITE

var _destination := Vector2.ZERO


func setup(new_target: Enemy, new_damage: float, new_speed: float, new_color: Color) -> void:
	target = new_target
	damage = new_damage
	speed = new_speed
	color = new_color
	_destination = target.global_position


func _process(delta: float) -> void:
	var target_alive := is_instance_valid(target) and target.is_alive
	if target_alive:
		_destination = target.global_position
	var to_destination := _destination - global_position
	var step := speed * delta
	if to_destination.length() <= step:
		if target_alive:
			target.take_damage(damage)
		queue_free()
		return
	global_position += to_destination.normalized() * step


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, color)
