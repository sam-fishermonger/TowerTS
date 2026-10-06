class_name Projectile
extends Entity
## Projectile à tête chercheuse tiré par une tour. Si la cible disparaît, il
## finit sa course jusqu'à sa dernière position connue puis disparaît.

var target: Enemy
var damage := 0.0
var speed := 500.0
var color := Color.WHITE
## Statistiques de la tour qui a tiré : effets du coup (ralentissement, brûlure...).
var stats: TowerData

var _destination := Vector2.ZERO


func setup(new_target: Enemy, data: TowerData) -> void:
	target = new_target
	damage = data.damage
	speed = data.projectile_speed
	color = data.color.lightened(0.4)
	stats = data
	_destination = target.global_position


func _process(delta: float) -> void:
	var target_alive := is_instance_valid(target) and target.is_alive
	if target_alive:
		_destination = target.global_position
	var to_destination := _destination - global_position
	var step := speed * delta
	if to_destination.length() <= step:
		global_position = _destination
		_impact(target if target_alive else null)
		despawn()
		return
	global_position += to_destination.normalized() * step


## Effet à l'arrivée. `hit` est la cible si elle est encore en jeu, sinon null.
func _impact(hit: Enemy) -> void:
	if hit:
		_hit_enemy(hit)


func _hit_enemy(enemy: Enemy) -> void:
	enemy.hit(damage, stats)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, color)
