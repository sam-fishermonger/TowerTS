class_name PerkTree
extends Resource
## Arbre des améliorations permanentes : chaque branche occupe deux colonnes, et une
## amélioration se débloque quand celles qu'elle demande (`requires`) sont achetées.
## Les branches sont réparties en pages (onglets de l'écran de l'arbre).

## Nom de chaque branche, dans l'ordre des colonnes.
@export var branch_names: Array[String] = []
## Couleur du nom de chaque branche.
@export var branch_colors: Array[Color] = []
## Page de chaque branche (index dans page_names).
@export var branch_pages: Array[int] = []
## Nom de chaque page.
@export var page_names: Array[String] = []
@export var perks: Array[Perk] = []


func get_perk(id: String) -> Perk:
	for perk in perks:
		if perk.id == id:
			return perk
	return null


## Prix total de l'arbre, en étoiles (ou en étoiles infinies pour les spécialisations).
func get_total_cost(endless := false) -> int:
	var total := 0
	for perk in perks:
		if perk.paid_with_endless_stars == endless:
			total += perk.cost
	return total


## Branche d'une amélioration (deux colonnes par branche).
func get_branch(perk: Perk) -> int:
	return floori(perk.column / 2.0)


func get_page(perk: Perk) -> int:
	var branch := get_branch(perk)
	return branch_pages[branch] if branch < branch_pages.size() else 0


## Branches d'une page, dans l'ordre.
func get_page_branches(page: int) -> Array[int]:
	var result: Array[int] = []
	for branch in branch_names.size():
		if (branch_pages[branch] if branch < branch_pages.size() else 0) == page:
			result.append(branch)
	return result


func get_page_perks(page: int) -> Array[Perk]:
	var result: Array[Perk] = []
	for perk in perks:
		if get_page(perk) == page:
			result.append(perk)
	return result
