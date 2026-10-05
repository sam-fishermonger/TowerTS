class_name Tower
extends Entity
## Base des tours : choisit une cible à portée et attaque selon sa cadence.
## Les sous-classes définissent l'attaque (_attack) et l'apparence (_draw_body).
## Les statistiques en jeu sont celles de `stats` : celles du type de tour (`data`)
## avec les améliorations achetées appliquées.

const SIZE := 44.0

## Émis quand la tour monte de niveau.
signal upgraded(tower: Tower)

@export var data: TowerData
## Niveau d'amélioration : 1 à la pose, jusqu'à data.get_max_level().
var level := 1
## Statistiques effectives au niveau actuel.
var stats: TowerData

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


func _ready() -> void:
	stats = data.get_stats_at_level(level)


func _process(delta: float) -> void:
	_cooldown -= delta
	if not _is_valid_target(_target):
		_target = find_target()
	if _target == null:
		# Sans cible, la tour reste prête à tirer mais n'accumule pas de tirs d'avance.
		_cooldown = maxf(_cooldown, 0.0)
		return
	_aim_angle = global_position.angle_to_point(_target.global_position)
	queue_redraw()
	if _cooldown <= 0.0:
		_attack(_target)
		# On garde le temps écoulé en trop : la cadence ne dépend ni des FPS ni de la vitesse de jeu.
		_cooldown += 1.0 / stats.fire_rate


func can_upgrade() -> bool:
	return level < data.get_max_level()


## Prix de la prochaine amélioration, ou -1 si la tour est au niveau maximal.
func get_upgrade_cost() -> int:
	return data.get_upgrade_cost(level)


## Passe au niveau suivant (sans payer : c'est le rôle du niveau de jeu).
## Renvoie false si la tour est déjà au niveau maximal.
func upgrade() -> bool:
	if not can_upgrade():
		return false
	level += 1
	stats = data.get_stats_at_level(level)
	queue_redraw()
	upgraded.emit(self)
	return true


## Ennemi à portée le plus proche de la base, ou null.
func find_target() -> Enemy:
	var best: Enemy = null
	for enemy in Enemy.get_alive_in_radius(get_tree(), global_position, stats.attack_range):
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
		and global_position.distance_to(enemy.global_position) <= stats.attack_range


func _draw() -> void:
	if show_range:
		draw_circle(Vector2.ZERO, stats.attack_range, Color(1, 1, 1, 0.08))
		draw_arc(Vector2.ZERO, stats.attack_range, 0.0, TAU, 64, Color(1, 1, 1, 0.4), 1.5)
	_draw_body()


## Socle carré commun à toutes les tours.
func _draw_body() -> void:
	var half := SIZE / 2.0
	draw_rect(Rect2(-half, -half, SIZE, SIZE), data.color.darkened(0.35))
	# Un losange par amélioration achetée, en bas du socle.
	for i in level - 1:
		var center := Vector2(-half + 7.0 + i * 10.0, half - 7.0)
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -4), center + Vector2(4, 0),
			center + Vector2(0, 4), center + Vector2(-4, 0)]), Color(1, 0.85, 0.3))
