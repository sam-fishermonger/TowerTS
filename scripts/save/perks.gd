class_name Perks
extends RefCounted
## Améliorations permanentes achetées par le joueur, enregistrées avec la progression.
## Les étoiles gagnées sur les niveaux sont la monnaie : celles dépensées dans l'arbre
## peuvent être récupérées à tout moment (Réinitialiser l'arbre).

const TREE: PerkTree = preload("res://resources/perk_tree.tres")
const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")
## Méta du moteur qui garde la liste des améliorations achetées : les bonus sont lus
## à chaque prix ou statistique de tour, le fichier n'est relu qu'après un changement
## de la progression. (Une liste et pas un objet : Godot signalerait une fuite.)
const OWNED_META := &"perks_owned"


static func get_owned_ids() -> PackedStringArray:
	if not Engine.has_meta(OWNED_META):
		Engine.set_meta(OWNED_META, Progress.get_value("perks", "owned", PackedStringArray()))
	return Engine.get_meta(OWNED_META).duplicate()


static func is_owned(perk: Perk) -> bool:
	return get_owned_ids().has(perk.id)


## Toutes les améliorations demandées par celle-ci sont achetées.
static func is_unlocked(perk: Perk) -> bool:
	var owned := get_owned_ids()
	for required in perk.requires:
		if not owned.has(required.id):
			return false
	return true


## Étoiles gagnées sur tous les niveaux de la campagne (meilleur résultat de chacun).
static func get_earned_stars() -> int:
	var total := 0
	for path in CAMPAIGN.levels:
		total += Progress.get_stars(path)
	return total


static func get_spent_stars() -> int:
	var total := 0
	for id in get_owned_ids():
		var perk := TREE.get_perk(id)
		if perk:
			total += perk.cost
	return total


static func get_available_stars() -> int:
	return get_earned_stars() - get_spent_stars()


static func can_buy(perk: Perk) -> bool:
	return not is_owned(perk) and is_unlocked(perk) and get_available_stars() >= perk.cost


## Achète l'amélioration si c'est possible. Renvoie true si elle a été achetée.
static func buy(perk: Perk) -> bool:
	if not can_buy(perk):
		return false
	var owned := get_owned_ids()
	owned.append(perk.id)
	Progress.set_value("perks", "owned", owned)
	return true


## Rend toutes les étoiles dépensées.
static func refund_all() -> void:
	Progress.set_value("perks", "owned", PackedStringArray())


## Total des bonus des améliorations achetées, sous la forme d'une seule amélioration.
static func get_bonuses() -> Perk:
	var total := Perk.new()
	for id in get_owned_ids():
		var perk := TREE.get_perk(id)
		if perk:
			perk.add_to(total)
	return total


## À appeler quand la progression change : la liste sera relue.
static func clear_cache() -> void:
	if Engine.has_meta(OWNED_META):
		Engine.remove_meta(OWNED_META)
