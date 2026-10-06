class_name Perk
extends Resource
## Amélioration permanente de l'arbre des améliorations (écran titre), achetée avec
## les étoiles gagnées sur les niveaux. Ses bonus s'appliquent à toutes les parties.
## Un champ laissé à sa valeur par défaut n'a aucun effet.

@export var id := ""
@export var display_name := "Amélioration"
@export_multiline var description := ""
## Prix en étoiles.
@export var cost := 1
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


## Tour débloquée par cette amélioration (TowerData), ou null. (Resource et pas
## TowerData pour la même raison : ce script ne doit pas dépendre de TowerData.)
func get_unlocked_tower() -> Resource:
	return load(unlocks_tower) if not unlocks_tower.is_empty() else null


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
