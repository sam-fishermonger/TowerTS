class_name Perk
extends Resource
## Amélioration permanente de l'arbre des améliorations (écran titre), achetée avec
## les étoiles gagnées sur les niveaux, ou, pour les spécialisations, avec les étoiles
## infinies du mode infini. Ses bonus s'appliquent à toutes les parties.
## Un champ laissé à sa valeur par défaut n'a aucun effet.

## Dossier des icônes des améliorations (voir get_icon()).
const ICON_DIR := "res://assets/icons/ameliorations/"

@export var id := ""
@export var display_name := "Amélioration"
@export_multiline var description := ""
## Prix en étoiles.
@export var cost := 1
## Payée en étoiles infinies (gagnées en mode infini) au lieu des étoiles des niveaux.
@export var paid_with_endless_stars := false
## Améliorations (Perk) à posséder avant de pouvoir acheter celle-ci (toutes).
## (Array[Resource] : un Array[Perk] dans Perk empêcherait Godot de libérer le script.)
@export var requires: Array[Resource] = []
## Monde à avoir débloqué avant de pouvoir l'acheter (index dans la campagne, -1 = aucun).
@export var required_world := -1
## Place dans l'arbre : colonne (deux par branche, 0.5 pour centrer) et rang (profondeur).
@export var column := 0.0
@export var row := 0

@export_group("Tours")
## Nouvelle tour (TowerData) ajoutée à la barre d'achat de tous les niveaux.
## (Un chemin et pas la ressource : TowerData lit l'arbre pour ses prix, la charger
## ici ferait une boucle de chargement.)
@export_file("*.tres") var unlocks_tower := ""
@export var damage_multiplier := 1.0
@export var range_multiplier := 1.0
@export var fire_rate_multiplier := 1.0
## Secondes de ralentissement ajoutées aux tours qui ralentissent.
@export var slow_duration_bonus := 0.0
## Multiplicateur du prix des tours et de leurs améliorations.
@export var tower_cost_multiplier := 1.0
## Part du prix rendue en plus à la vente.
@export var sell_ratio_bonus := 0.0

@export_group("Or")
@export var starting_gold_bonus := 0
## Multiplicateur de l'or gagné par ennemi détruit.
@export var reward_multiplier := 1.0
## Multiplicateur du bonus de fin de vague.
@export var wave_bonus_multiplier := 1.0

@export_group("Vies")
@export var lives_bonus := 0
## Vies rendues à chaque vague repoussée, sans dépasser les vies de départ.
@export var lives_per_wave := 0

@export_group("Conquête")
## Bonus du mode Conquête seulement (page Logistique de l'arbre) : ouvriers au départ,
## ouvriers au plus, pierre au départ.
@export var conquest_workers_bonus := 0
@export var conquest_max_workers_bonus := 0
@export var conquest_stone_bonus := 0
## Pierre et essence que les Voleurs ne peuvent pas prendre (réserve du Dépôt).
@export var conquest_vault_stone := 0
@export var conquest_vault_essence := 0
## Les Dépôts bâtis abritent et soignent les ouvriers, comme le QG.
@export var conquest_depot_shelter := false
## Multiplicateurs de la vie des bâtiments, de la vitesse des chantiers et de la pierre
## des tours.
@export var conquest_building_health_multiplier := 1.0
@export var conquest_build_speed_multiplier := 1.0
@export var conquest_stone_cost_multiplier := 1.0

@export_group("Spécialisation")
## Spécialisation d'une tour (chemin de sa TowerData) : les bonus de tour de cette
## amélioration (dégâts, portée, cadence, durée du ralentissement, et ceux de ce
## groupe) ne s'appliquent qu'à elle, après ses améliorations.
@export_file("*.tres") var specializes_tower := ""
@export var splash_radius_multiplier := 1.0
## Multiplicateur du facteur de ralentissement : plus petit, les ennemis vont moins vite.
@export var slow_factor_multiplier := 1.0
## Brûlure ou poison ajouté aux coups : dégâts par seconde et secondes en plus.
@export var dot_damage_bonus := 0.0
@export var dot_duration_bonus := 0.0
## La brûlure ajoutée est un poison (nom affiché dans la fiche de la tour).
@export var dot_is_poison := false
## Les coups ignorent l'armure.
@export var armor_piercing := false
## Multiplicateur de la montée en puissance du Rayon.
@export var beam_ramp_multiplier := 1.0
@export var cloud_radius_multiplier := 1.0
@export var cloud_duration_bonus := 0.0
## Secondes ajoutées au brouillage des boucliers.
@export var shield_jam_bonus := 0.0
## Ralentissement donné à une tour qui ne ralentit pas (1 = aucun) et sa durée.
@export_range(0.1, 1.0) var added_slow_factor := 1.0
@export var added_slow_duration := 0.0
## Secondes ajoutées au blocage des soins.
@export var heal_block_bonus := 0.0

@export_group("Croisement")
## Croisement de deux tours : `specializes_tower` reçoit les effets de cette amélioration,
## et la seconde tour ceux de `partner_effect` (une autre amélioration, dont
## `specializes_tower` est la seconde tour). Chacune prend un effet de l'autre.
## (Resource et pas Perk : un Perk dans Perk empêcherait Godot de libérer le script.)
@export var partner_effect: Resource
## Effet d'un croisement (la fiche de la tour l'appelle « Croisement » et pas « Spécialisation »).
@export var crossing := false

@export_group("Pouvoirs")
## Pouvoir actif (chemin de sa ressource Power) débloqué en jeu.
@export_file("*.tres") var unlocks_power := ""
## Pouvoir (chemin de sa ressource Power) que cette amélioration renforce, avec les
## champs de ce groupe.
@export_file("*.tres") var improves_power := ""
## Multiplicateur des dégâts du pouvoir (et de la vie de ses soldats).
@export var power_strength_multiplier := 1.0
@export var power_cooldown_multiplier := 1.0
## Secondes ajoutées à la durée du pouvoir (gel, soldats).
@export var power_duration_bonus := 0.0
## Météores ou soldats en plus.
@export var power_count_bonus := 0
## Dégâts subis en plus par un ennemi gelé (0.3 = +30 %).
@export var power_vulnerability_bonus := 0.0


## Tour débloquée par cette amélioration (TowerData), ou null. (Resource et pas
## TowerData pour la même raison : ce script ne doit pas dépendre de TowerData.)
func get_unlocked_tower() -> Resource:
	return load(unlocks_tower) if not unlocks_tower.is_empty() else null


func is_specialization() -> bool:
	return not specializes_tower.is_empty()


## Croisement de deux tours (voir partner_effect).
func is_crossing() -> bool:
	return crossing


## Chemin de la seconde tour d'un croisement, ou "".
func get_partner_tower_path() -> String:
	return partner_effect.specializes_tower if partner_effect else ""


## Chemin du pouvoir montré dans la case de l'amélioration (débloqué ou renforcé), ou "".
func get_power_path() -> String:
	return unlocks_power if not unlocks_power.is_empty() else improves_power


## Renforce un pouvoir (Power, modifié sur place ; pas de type pour ne pas dépendre de Power).
func apply_to_power(power) -> void:
	power.damage *= power_strength_multiplier
	power.health *= power_strength_multiplier
	power.cooldown *= power_cooldown_multiplier
	power.duration += power_duration_bonus
	power.count += power_count_bonus
	power.vulnerability += power_vulnerability_bonus


## Icône de la case (game-icons.net, voir assets/icons/LICENCES.md) : le fichier qui porte
## l'identifiant de l'amélioration, s'il existe. Les cases à tour ou à pouvoir n'en ont pas.
func get_icon() -> Texture2D:
	var path := ICON_DIR + id + ".svg"
	return load(path) if ResourceLoader.exists(path) else null


## Chemin de la tour montrée dans la case de l'amélioration (débloquée ou spécialisée), ou "".
func get_tower_path() -> String:
	return unlocks_tower if not unlocks_tower.is_empty() else specializes_tower


## Applique la spécialisation aux statistiques d'une tour (TowerData, modifiées sur
## place ; pas de type pour ne pas dépendre de TowerData).
func apply_specialization(stats) -> void:
	stats.scale_stats(damage_multiplier, range_multiplier, fire_rate_multiplier, slow_duration_bonus)
	stats.splash_radius *= splash_radius_multiplier
	if stats.slow_factor < 1.0:
		stats.slow_factor = clampf(stats.slow_factor * slow_factor_multiplier, 0.1, 1.0)
	if dot_damage_bonus > 0.0:
		stats.dot_damage += dot_damage_bonus
		stats.dot_duration = maxf(stats.dot_duration, 0.0) + dot_duration_bonus
		stats.dot_is_poison = stats.dot_is_poison or dot_is_poison
	stats.armor_piercing = stats.armor_piercing or armor_piercing
	stats.beam_ramp_max *= beam_ramp_multiplier
	stats.cloud_radius *= cloud_radius_multiplier
	stats.cloud_duration += cloud_duration_bonus
	stats.shield_jam_duration += shield_jam_bonus
	if added_slow_factor < 1.0:
		stats.slow_factor = minf(stats.slow_factor, added_slow_factor)
		stats.slow_duration = maxf(stats.slow_duration, added_slow_duration)
	stats.heal_block_duration += heal_block_bonus


## Ajoute les bonus de cette amélioration à `total` (modifié sur place) : les
## multiplicateurs se multiplient, les bonus s'additionnent.
func add_to(total: Perk) -> void:
	total.damage_multiplier *= damage_multiplier
	total.range_multiplier *= range_multiplier
	total.fire_rate_multiplier *= fire_rate_multiplier
	total.slow_duration_bonus += slow_duration_bonus
	total.tower_cost_multiplier *= tower_cost_multiplier
	total.sell_ratio_bonus += sell_ratio_bonus
	total.starting_gold_bonus += starting_gold_bonus
	total.reward_multiplier *= reward_multiplier
	total.wave_bonus_multiplier *= wave_bonus_multiplier
	total.lives_bonus += lives_bonus
	total.lives_per_wave += lives_per_wave
	total.conquest_workers_bonus += conquest_workers_bonus
	total.conquest_max_workers_bonus += conquest_max_workers_bonus
	total.conquest_stone_bonus += conquest_stone_bonus
	total.conquest_vault_stone += conquest_vault_stone
	total.conquest_vault_essence += conquest_vault_essence
	total.conquest_depot_shelter = total.conquest_depot_shelter or conquest_depot_shelter
	total.conquest_building_health_multiplier *= conquest_building_health_multiplier
	total.conquest_build_speed_multiplier *= conquest_build_speed_multiplier
	total.conquest_stone_cost_multiplier *= conquest_stone_cost_multiplier
