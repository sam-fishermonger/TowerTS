class_name TowerData
extends Resource
## Statistiques d'un type de tour.

@export var display_name := "Tour"
## Courte présentation affichée dans la fiche de la tour.
@export_multiline var description := ""
@export var cost := 50
## Scène de la tour (une scène dont la racine hérite de Tower).
@export var scene: PackedScene
## Portée de tir, en pixels.
@export var attack_range := 150.0
@export var damage := 20.0
## Nombre de tirs par seconde.
@export var fire_rate := 1.0
@export var color := Color.STEEL_BLUE
## Tourelle posée sur le socle (dessin de remplacement en code si vide).
@export var turret_texture: Texture2D
## La tourelle pivote vers sa cible (faux pour le Givre, qui frappe tout autour).
@export var turret_rotates := true
## Son joué à chaque tir.
@export var attack_sound: AudioStream

@export_group("Projectile")
## Scène du projectile tiré (tours à projectiles seulement).
@export var projectile_scene: PackedScene
## Vitesse des projectiles, en pixels par seconde.
@export var projectile_speed := 500.0
## Rayon de l'explosion à l'impact (0 = un seul ennemi touché).
@export var splash_radius := 0.0

@export_group("Ralentissement")
## Multiplicateur de vitesse appliqué aux ennemis touchés (1 = aucun effet).
@export_range(0.1, 1.0) var slow_factor := 1.0
## Durée du ralentissement, en secondes.
@export var slow_duration := 0.0

@export_group("Rayon")
## Multiplicateur de dégâts atteint en restant sur la même cible (1 = pas de montée).
@export var beam_ramp_max := 1.0
## Secondes sur la même cible pour atteindre beam_ramp_max.
@export var beam_ramp_time := 2.0

@export_group("Effets spéciaux")
## Dégâts par seconde d'une brûlure ou d'un poison laissé sur les ennemis touchés.
## Ils passent sous l'armure (0 = aucun).
@export var dot_damage := 0.0
## Durée de la brûlure ou du poison, en secondes.
@export var dot_duration := 0.0
## C'est un poison et pas une brûlure (nom affiché dans la fiche ; les tours à nuage
## empoisonnent toujours).
@export var dot_is_poison := false
## Les coups ignorent l'armure.
@export var armor_piercing := false
## Multiplicateur des dégâts infligés aux boucliers d'énergie.
@export var shield_damage_multiplier := 1.0
## Secondes pendant lesquelles un bouclier touché ne se recharge plus.
@export var shield_jam_duration := 0.0
## Secondes pendant lesquelles un ennemi touché ne peut ni être soigné ni soigner.
@export var heal_block_duration := 0.0
## Vise d'abord les soigneurs à portée, quelle que soit la règle de ciblage.
@export var prefers_healers := false

@export_group("Nuage")
## Rayon du nuage laissé à l'impact (tours à projectile de nuage).
@export var cloud_radius := 0.0
## Durée du nuage, en secondes.
@export var cloud_duration := 0.0

@export_group("Flammes")
## Ouverture du cône de flammes, en degrés (Lance-flammes).
@export var cone_angle := 50.0

@export_group("Arc")
## Rebonds de l'arc électrique après la première cible (Arc électrique).
@export var chain_count := 0
## Distance maximale d'un rebond, d'un ennemi au suivant.
@export var chain_range := 110.0
## Multiplicateur des dégâts à chaque rebond.
@export_range(0.1, 1.0) var chain_falloff := 0.8

@export_group("Soutien")
## Bonus de dégâts donné aux tours à portée (Bobine) : 0.25 = +25 %.
@export var boost_damage := 0.0
## Bonus de cadence donné aux tours à portée (Bobine).
@export var boost_fire_rate := 0.0

@export_group("Recul")
## Pixels dont les ennemis touchés reculent sur leur chemin (Électroaimant). Les gros
## ennemis reculent moins (voir Enemy.push_back).
@export var knockback := 0.0

@export_group("Améliorations")
## Améliorations achetables, dans l'ordre : la tour posée est au niveau 1,
## chaque amélioration la fait monter d'un niveau.
@export var upgrades: Array[TowerUpgrade] = []


## Niveau maximal d'une tour de ce type.
func get_max_level() -> int:
	return upgrades.size() + 1


## Prix de pose, réductions de l'arbre des améliorations (Perks) comprises.
func get_cost() -> int:
	return roundi(cost * Perks.get_bonuses().tower_cost_multiplier)


## Prix pour passer du niveau donné au suivant, ou -1 si le niveau est maximal.
func get_upgrade_cost(level: int) -> int:
	if level < 1 or level >= get_max_level():
		return -1
	return roundi(upgrades[level - 1].cost * Perks.get_bonuses().tower_cost_multiplier)


## Copie de ces statistiques avec les améliorations appliquées jusqu'au niveau donné,
## puis les bonus de l'arbre des améliorations (Perks) et les spécialisations achetées
## pour cette tour.
func get_stats_at_level(level: int) -> TowerData:
	var stats: TowerData = duplicate()
	for i in clampi(level - 1, 0, upgrades.size()):
		upgrades[i].apply_to(stats)
	var bonuses := Perks.get_bonuses()
	stats.scale_stats(bonuses.damage_multiplier, bonuses.range_multiplier, bonuses.fire_rate_multiplier,
		bonuses.slow_duration_bonus)
	for specialization in get_specializations():
		specialization.apply_specialization(stats)
	return stats


## Spécialisations achetées pour cette tour dans l'arbre des améliorations (Perk).
func get_specializations() -> Array[Perk]:
	return Perks.get_specializations(resource_path)


## Bonus communs aux améliorations et à l'arbre des améliorations (modifiés sur place) :
## les dégâts comptent aussi pour la brûlure ou le poison, et le ralentissement ne
## s'allonge que pour les tours qui ralentissent.
func scale_stats(damage_multiplier: float, range_multiplier: float, fire_rate_multiplier: float,
		slow_duration_bonus: float) -> void:
	damage *= damage_multiplier
	dot_damage *= damage_multiplier
	attack_range *= range_multiplier
	fire_rate *= fire_rate_multiplier
	if slow_factor < 1.0:
		slow_duration += slow_duration_bonus


## Tour de soutien : elle renforce les tours voisines (Bobine).
func is_support() -> bool:
	return boost_damage > 0.0 or boost_fire_rate > 0.0


## Dégâts directs par seconde sur une cible (sans la brûlure ou le poison, la montée
## en puissance du Rayon ni les cibles multiples).
func get_dps() -> float:
	return damage * fire_rate
