class_name Tower
extends Node2D
## Tour qui vise l'ennemi le plus avancé à sa portée et lui tire dessus.

const PROJECTILE_SCENE := preload("res://scenes/towers/projectile.tscn")
const SIZE := 44.0

@export var data: TowerData

## Nœud qui reçoit les projectiles tirés (par défaut, le parent de la tour).
var projectile_container: Node
## Affiche le cercle de portée (survol de la souris).
var show_range := false:
	set(value):
		show_range = value
		queue_redraw()

var _cooldown := 0.0
var _target: Enemy
var _aim_angle := -PI / 2.0


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not _is_valid_target(_target):
		_target = _find_target()
	if _target == null:
		return
	_aim_angle = global_position.angle_to_point(_target.global_position)
	queue_redraw()
	if _cooldown <= 0.0:
		_shoot()
		_cooldown = 1.0 / data.fire_rate


## Non typé : la cible peut avoir été libérée depuis la dernière image.
func _is_valid_target(enemy: Variant) -> bool:
	return is_instance_valid(enemy) and enemy.is_alive \
		and global_position.distance_to(enemy.global_position) <= data.attack_range


## Cible l'ennemi à portée le plus proche de la fin du chemin.
func _find_target() -> Enemy:
	var best: Enemy = null
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if _is_valid_target(enemy) and (best == null or enemy.progress > best.progress):
			best = enemy
	return best


func _shoot() -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.setup(_target, data.damage, data.projectile_speed, data.color.lightened(0.4))
	var container := projectile_container if projectile_container else get_parent()
	container.add_child(projectile)
	projectile.global_position = global_position + Vector2.from_angle(_aim_angle) * SIZE * 0.5


func _draw() -> void:
	if show_range:
		draw_circle(Vector2.ZERO, data.attack_range, Color(1, 1, 1, 0.08))
		draw_arc(Vector2.ZERO, data.attack_range, 0.0, TAU, 64, Color(1, 1, 1, 0.4), 1.5)
	var half := SIZE / 2.0
	draw_rect(Rect2(-half, -half, SIZE, SIZE), data.color.darkened(0.35))
	draw_circle(Vector2.ZERO, SIZE * 0.32, data.color)
	draw_line(Vector2.ZERO, Vector2.from_angle(_aim_angle) * SIZE * 0.55, data.color.lightened(0.3), 7.0)
