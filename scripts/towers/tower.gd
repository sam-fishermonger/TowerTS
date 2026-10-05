class_name Tower
extends Entity
## Base des tours : choisit une cible à portée et attaque selon sa cadence.
## Les sous-classes définissent l'attaque (_attack) et l'apparence (_draw_body).

const SIZE := 44.0

@export var data: TowerData

## Nœud qui reçoit ce que la tour crée en jeu (projectiles, effets). Par défaut, son parent.
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
		_target = find_target()
	if _target == null:
		return
	_aim_angle = global_position.angle_to_point(_target.global_position)
	queue_redraw()
	if _cooldown <= 0.0:
		_attack(_target)
		_cooldown = 1.0 / data.fire_rate


## Ennemi à portée le plus proche de la base, ou null.
func find_target() -> Enemy:
	var best: Enemy = null
	for enemy in Enemy.get_alive_in_radius(get_tree(), global_position, data.attack_range):
		if best == null or enemy.distance_to_end() < best.distance_to_end():
			best = enemy
	return best


## Attaque la cible. À redéfinir dans les sous-classes.
func _attack(_enemy: Enemy) -> void:
	pass


func _get_container() -> Node:
	return projectile_container if projectile_container else get_parent()


## Non typé : la cible peut avoir été libérée depuis la dernière image.
func _is_valid_target(enemy: Variant) -> bool:
	return is_instance_valid(enemy) and enemy.is_alive \
		and global_position.distance_to(enemy.global_position) <= data.attack_range


func _draw() -> void:
	if show_range:
		draw_circle(Vector2.ZERO, data.attack_range, Color(1, 1, 1, 0.08))
		draw_arc(Vector2.ZERO, data.attack_range, 0.0, TAU, 64, Color(1, 1, 1, 0.4), 1.5)
	_draw_body()


## Socle carré commun à toutes les tours.
func _draw_body() -> void:
	var half := SIZE / 2.0
	draw_rect(Rect2(-half, -half, SIZE, SIZE), data.color.darkened(0.35))
