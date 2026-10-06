class_name TowerUpgrade
extends Resource
## Amélioration d'une tour : son prix et les bonus qu'elle apporte.
## Les multiplicateurs s'appliquent aux statistiques du niveau précédent ; celui des
## dégâts compte aussi pour la brûlure ou le poison.

@export var cost := 50
@export var damage_multiplier := 1.0
@export var range_multiplier := 1.0
@export var fire_rate_multiplier := 1.0
@export var splash_radius_multiplier := 1.0
## Secondes de ralentissement ajoutées.
@export var slow_duration_bonus := 0.0
## Rayon du nuage multiplié.
@export var cloud_radius_multiplier := 1.0
## Rebonds ajoutés (Arc électrique).
@export var chain_count_bonus := 0
## Ajouté aux bonus de dégâts et de cadence donnés aux tours voisines (Bobine).
@export var boost_bonus := 0.0
@export var knockback_multiplier := 1.0


## Applique l'amélioration aux statistiques données (modifiées sur place).
func apply_to(stats: TowerData) -> void:
	stats.scale_stats(damage_multiplier, range_multiplier, fire_rate_multiplier, slow_duration_bonus)
	stats.splash_radius *= splash_radius_multiplier
	stats.cloud_radius *= cloud_radius_multiplier
	stats.chain_count += chain_count_bonus
	if stats.boost_damage > 0.0:
		stats.boost_damage += boost_bonus
	if stats.boost_fire_rate > 0.0:
		stats.boost_fire_rate += boost_bonus
	stats.knockback *= knockback_multiplier
