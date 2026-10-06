class_name Projectile
extends Entity
## Projectile à tête chercheuse tiré par une tour. Si la cible disparaît, il
## finit sa course jusqu'à sa dernière position connue puis disparaît.

var target: Enemy
var color := Color.WHITE
## Statistiques de la tour qui a tiré (au niveau de la tour) : dégâts, vitesse et effets
## du coup (zone, ralentissement, brûlure...).
var stats: TowerData

var _destination := Vector2.ZERO


func setup(new_target: Enemy, tower_stats: TowerData) -> void:
	target = new_target
	stats = tower_stats
	color = tower_stats.color.lightened(0.4)
	_destination = target.global_position


func _process(delta: float) -> void:
	var target_alive := is_instance_valid(target) and target.is_alive
	if target_alive:
		_destination = target.global_position
	var to_destination := _destination - global_position
	var step := stats.projectile_speed * delta
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
	enemy.hit(stats.damage, stats)


## Touche tous les ennemis dans le rayon, autour du point d'impact (obus, grenades).
func _hit_all_in_radius(radius: float) -> void:
	for enemy in Enemy.get_alive_in_radius(get_tree(), global_position, radius, stats):
		_hit_enemy(enemy)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, color)
