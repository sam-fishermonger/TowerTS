class_name PerkTree
extends Resource
## Arbre des améliorations permanentes : chaque branche est une colonne, et une
## amélioration se débloque quand celles qu'elle demande (`requires`) sont achetées.

## Nom de chaque branche, dans l'ordre des colonnes.
@export var branch_names: Array[String] = []
@export var perks: Array[Perk] = []


func get_perk(id: String) -> Perk:
	for perk in perks:
		if perk.id == id:
			return perk
	return null


## Prix total de l'arbre, en étoiles.
func get_total_cost() -> int:
	var total := 0
	for perk in perks:
		total += perk.cost
	return total
