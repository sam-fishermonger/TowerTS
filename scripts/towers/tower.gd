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
## Taille de la tourelle par rapport au socle : elle déborde un peu.
const TURRET_SCALE := 1.3
## Part de ce que la tour a coûté (pose et améliorations) rendue à la vente,
## sans compter l'arbre des améliorations.
const SELL_RATIO := 0.7
## Tirs au plus par image : une tour très rapide (ou un jeu qui rame en x3) peut devoir
## tirer plusieurs fois dans la même image pour tenir sa cadence.
const MAX_SHOTS_PER_FRAME := 4

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
## Bonus de dégâts et de cadence donnés par la Bobine la plus forte à portée (0 = aucun).
## Le niveau les recalcule quand une tour est posée, améliorée ou vendue.
var boost_damage := 0.0
var boost_fire_rate := 0.0

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
	stats = get_stats_at_level(level)


## Statistiques de la tour à un niveau donné, avec le bonus de Bobine qu'elle reçoit.
func get_stats_at_level(at_level: int) -> TowerData:
	var result := data.get_stats_at_level(at_level)
	result.damage *= 1.0 + boost_damage
	result.dot_damage *= 1.0 + boost_damage
	result.fire_rate *= 1.0 + boost_fire_rate
	return result


## Change le bonus reçu d'une Bobine (0 et 0 = aucun) et recalcule les statistiques.
func set_boost(damage_bonus: float, fire_rate_bonus: float) -> void:
	if is_equal_approx(damage_bonus, boost_damage) and is_equal_approx(fire_rate_bonus, boost_fire_rate):
		return
	boost_damage = damage_bonus
	boost_fire_rate = fire_rate_bonus
	stats = get_stats_at_level(level)
	queue_redraw()


func is_boosted() -> bool:
	return boost_damage > 0.0 or boost_fire_rate > 0.0


## La cible est gardée tant qu'elle reste à portée, sauf pour le Franc-tireur, qui la
## lâche au moment de tirer si un soigneur est passé à portée entre-temps.
func _process(delta: float) -> void:
	_cooldown -= delta
	if not _is_valid_target(_target) or (_cooldown <= 0.0 and _should_switch_to_healer()):
		_target = find_target()
	if _target == null:
		# Sans cible, la tour reste prête à tirer mais n'accumule pas de tirs d'avance.
		_cooldown = maxf(_cooldown, 0.0)
		return
	_aim_angle = global_position.angle_to_point(_target.global_position)
	queue_redraw()
	# On garde le temps écoulé en trop, et on tire plusieurs fois si l'image a duré plus
	# d'un tir : la cadence ne dépend ni des FPS ni de la vitesse de jeu.
	var shots := 0
	while _cooldown <= 0.0 and shots < MAX_SHOTS_PER_FRAME and _is_valid_target(_target):
		_attack(_target)
		_cooldown += 1.0 / stats.fire_rate
		shots += 1
	if shots > 0:
		Sound.play_stream(data.attack_sound)


func can_upgrade() -> bool:
	return level < data.get_max_level()


## Prix de la prochaine amélioration, ou -1 si la tour est au niveau maximal.
func get_upgrade_cost() -> int:
	return data.get_upgrade_cost(level)


## Total payé pour la tour : sa pose et les améliorations achetées.
func get_total_cost() -> int:
	var total := data.get_cost()
	for i in level - 1:
		total += data.get_upgrade_cost(i + 1)
	return total


## Or rendu si la tour est vendue.
func get_sell_value() -> int:
	return roundi(get_total_cost() * (SELL_RATIO + Perks.get_bonuses().sell_ratio_bonus))


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
	stats = get_stats_at_level(level)
	queue_redraw()
	upgraded.emit(self)
	return true


## Ennemi à portée qui correspond le mieux à la règle de ciblage, ou null.
func find_target() -> Enemy:
	var best: Enemy = null
	var best_score := -INF
	for enemy in Enemy.get_alive_in_radius(get_tree(), global_position, stats.attack_range):
		var score := _target_score(enemy)
		if score > best_score:
			best = enemy
			best_score = score
	return best


func _should_switch_to_healer() -> bool:
	return stats.prefers_healers and _target != null and _target.data.heal_amount <= 0.0


## Plus le score est grand, plus l'ennemi est prioritaire.
func _target_score(enemy: Enemy) -> float:
	# Le Franc-tireur abat les soigneurs avant tout le reste.
	var bonus := 1e12 if stats.prefers_healers and enemy.data.heal_amount > 0.0 else 0.0
	return bonus + _mode_score(enemy)


func _mode_score(enemy: Enemy) -> float:
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
		# La tourelle grossit un peu à chaque amélioration.
		draw_sprite(self, data, Vector2.ZERO, SIZE, TURRET_SCALE + 0.1 * (level - 1), _aim_angle)
	else:
		draw_rect(Rect2(-half, -half, SIZE, SIZE), data.color.darkened(0.35))
		_draw_shape()
	# Un losange par amélioration achetée, en bas du socle.
	for i in level - 1:
		var center := Vector2(-half + 7.0 + i * 10.0, half - 7.0)
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -4), center + Vector2(4, 0),
			center + Vector2(0, 4), center + Vector2(-4, 0)]), Color(1, 0.85, 0.3))
	_draw_effects()


## Dessine le socle et la tourelle d'un type de tour (qui doit avoir une image) sur
## `canvas`, centrés sur `center` : tour posée, aperçu de pose, barre d'achat.
## La tourelle est tournée de `aim_angle` (vers le haut par défaut) si elle pivote.
static func draw_sprite(canvas: CanvasItem, tower_data: TowerData, center: Vector2, base_size: float,
		turret_scale := TURRET_SCALE, aim_angle := -PI / 2.0, tint := Color.WHITE) -> void:
	canvas.draw_texture_rect(BASE_TEXTURE, Rect2(center - Vector2.ONE * base_size / 2.0, Vector2.ONE * base_size),
		false, tint)
	var turret_size := base_size * turret_scale
	canvas.draw_set_transform(center, aim_angle if tower_data.turret_rotates else 0.0)
	canvas.draw_texture_rect(tower_data.turret_texture,
		Rect2(-Vector2.ONE * turret_size / 2.0, Vector2.ONE * turret_size), false, tint)
	canvas.draw_set_transform(Vector2.ZERO)


## Tourelle dessinée en code, quand le type de tour n'a pas d'image. À redéfinir.
func _draw_shape() -> void:
	pass


## Effets dessinés par-dessus la tour (onde, rayon...). À redéfinir.
func _draw_effects() -> void:
	pass
