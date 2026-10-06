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


## Applique l'amélioration aux statistiques données (modifiées sur place).
func apply_to(stats: TowerData) -> void:
	stats.damage *= damage_multiplier
	stats.dot_damage *= damage_multiplier
	stats.attack_range *= range_multiplier
	stats.fire_rate *= fire_rate_multiplier
	stats.splash_radius *= splash_radius_multiplier
	stats.cloud_radius *= cloud_radius_multiplier
	if stats.slow_factor < 1.0:
		stats.slow_duration += slow_duration_bonus
