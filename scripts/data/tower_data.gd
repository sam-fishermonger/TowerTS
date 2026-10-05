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

@export_group("Améliorations")
## Améliorations achetables, dans l'ordre : la tour posée est au niveau 1,
## chaque amélioration la fait monter d'un niveau.
@export var upgrades: Array[TowerUpgrade] = []


## Niveau maximal d'une tour de ce type.
func get_max_level() -> int:
	return upgrades.size() + 1


## Prix pour passer du niveau donné au suivant, ou -1 si le niveau est maximal.
func get_upgrade_cost(level: int) -> int:
	return upgrades[level - 1].cost if level >= 1 and level < get_max_level() else -1


## Copie de ces statistiques avec les améliorations appliquées jusqu'au niveau donné.
func get_stats_at_level(level: int) -> TowerData:
	var stats: TowerData = duplicate()
	for i in clampi(level - 1, 0, upgrades.size()):
		upgrades[i].apply_to(stats)
	return stats


## Dégâts par seconde sur une cible.
func get_dps() -> float:
	return damage * fire_rate
