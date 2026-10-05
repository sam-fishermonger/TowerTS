class_name Tower
extends Entity
## Base des tours : choisit une cible à portée et attaque selon sa cadence.
## Les sous-classes définissent l'attaque (_attack), leurs effets (_draw_effects)
## et une apparence de remplacement si le type de tour n'a pas d'image (_draw_shape).
## Les statistiques en jeu sont celles de `stats` : celles du type de tour (`data`)
## avec les améliorations achetées appliquées.

const SIZE := 44.0
## Socle de pierre commun, sous la tourelle de chaque type de tour.
const BASE_TEXTURE: Texture2D = preload("res://assets/sprites/towers/base.svg")
## Part de ce que la tour a coûté (pose et améliorations) rendue à la vente.
const SELL_RATIO := 0.7

## Ennemi visé en priorité parmi ceux à portée.
enum TargetMode { FIRST, LAST, STRONGEST, CLOSEST }
const TARGET_MODE_NAMES: Array[String] = ["Premier", "Dernier", "Le plus fort", "Le plus proche"]

## Émis quand la tour monte de niveau.
signal upgraded(tower: Tower)

@export var data: TowerData
## Niveau d'amélioration : 1 à la pose, jusqu'à data.get_max_level().
var level := 1
## Statistiques effectives au niveau actuel.
var stats: TowerData
## Case de la carte occupée par la tour.
var cell := Vector2i.ZERO
var target_mode := TargetMode.FIRST

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
		Sound.play_stream(data.attack_sound)
		# On garde le temps écoulé en trop : la cadence ne dépend ni des FPS ni de la vitesse de jeu.
		_cooldown += 1.0 / stats.fire_rate


func can_upgrade() -> bool:
	return level < data.get_max_level()


## Prix de la prochaine amélioration, ou -1 si la tour est au niveau maximal.
func get_upgrade_cost() -> int:
	return data.get_upgrade_cost(level)


## Total payé pour la tour : sa pose et les améliorations achetées.
func get_total_cost() -> int:
	var total := data.cost
	for i in level - 1:
		total += data.get_upgrade_cost(i + 1)
	return total


## Or rendu si la tour est vendue.
func get_sell_value() -> int:
	return roundi(get_total_cost() * SELL_RATIO)


## false pour les tours qui frappent tout ce qui est à portée (le choix de cible ne sert à rien).
func uses_target_mode() -> bool:
	return true


func set_target_mode(mode: TargetMode) -> void:
	target_mode = mode
	# La nouvelle règle s'applique tout de suite, sans attendre la fin de la cible actuelle.
	_target = null


## Passe à la règle de ciblage suivante (dans l'ordre de TargetMode).
func cycle_target_mode() -> void:
	set_target_mode(((target_mode + 1) % TargetMode.size()) as TargetMode)


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


## Ennemi à portée qui correspond le mieux à la règle de ciblage, ou null.
## La cible est gardée tant qu'elle reste à portée.
func find_target() -> Enemy:
	var best: Enemy = null
	var best_score := -INF
	for enemy in Enemy.get_alive_in_radius(get_tree(), global_position, stats.attack_range):
		var score := _target_score(enemy)
		if score > best_score:
			best = enemy
			best_score = score
	return best


## Plus le score est grand, plus l'ennemi est prioritaire.
func _target_score(enemy: Enemy) -> float:
	match target_mode:
		TargetMode.LAST:
			return enemy.distance_to_end()
		TargetMode.STRONGEST:
			# À vie égale, le plus avancé d'abord.
			return enemy.health.health * 100000.0 - enemy.distance_to_end()
		TargetMode.CLOSEST:
			return -global_position.distance_squared_to(enemy.global_position)
		_:
			return -enemy.distance_to_end()


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


## Socle et tourelle (images de TowerData, ou formes de remplacement), puis
## les effets propres au type de tour.
func _draw_body() -> void:
	var half := SIZE / 2.0
	if data.turret_texture:
		draw_texture_rect(BASE_TEXTURE, Rect2(-half, -half, SIZE, SIZE), false)
		# La tourelle grossit un peu à chaque amélioration.
		var turret_size := SIZE * (1.3 + 0.1 * (level - 1))
		if data.turret_rotates:
			draw_set_transform(Vector2.ZERO, _aim_angle)
		draw_texture_rect(data.turret_texture, Rect2(-turret_size / 2.0, -turret_size / 2.0, turret_size, turret_size), false)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_rect(Rect2(-half, -half, SIZE, SIZE), data.color.darkened(0.35))
		_draw_shape()
	# Un losange par amélioration achetée, en bas du socle.
	for i in level - 1:
		var center := Vector2(-half + 7.0 + i * 10.0, half - 7.0)
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -4), center + Vector2(4, 0),
			center + Vector2(0, 4), center + Vector2(-4, 0)]), Color(1, 0.85, 0.3))
	_draw_effects()


## Tourelle dessinée en code, quand le type de tour n'a pas d'image. À redéfinir.
func _draw_shape() -> void:
	pass


## Effets dessinés par-dessus la tour (onde, rayon...). À redéfinir.
func _draw_effects() -> void:
	pass
