class_name Perks
extends RefCounted
## Améliorations permanentes achetées par le joueur, enregistrées avec la progression.
## Les étoiles gagnées sur les niveaux sont la monnaie, et les étoiles infinies du mode
## infini celle des spécialisations : celles dépensées dans l'arbre peuvent être
## récupérées à tout moment (Réinitialiser l'arbre).

const TREE: PerkTree = preload("res://resources/perk_tree.tres")
const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")
## Méta du moteur qui garde la liste des améliorations achetées : les bonus sont lus
## à chaque prix ou statistique de tour, le fichier n'est relu qu'après un changement
## de la progression. (Une liste et pas un objet : Godot signalerait une fuite.)
const OWNED_META := &"perks_owned"
## Méta du moteur posée pendant un défi du jour : l'arbre ne compte plus (ni bonus, ni
## tours débloquées, ni spécialisations), tout le monde joue avec les mêmes tours.
const DISABLED_META := &"perks_disabled"


static func get_owned_ids() -> PackedStringArray:
	if Engine.has_meta(DISABLED_META):
		return PackedStringArray()
	if not Engine.has_meta(OWNED_META):
		Engine.set_meta(OWNED_META, Progress.get_value("perks", "owned", PackedStringArray()))
	return Engine.get_meta(OWNED_META).duplicate()


static func is_owned(perk: Perk) -> bool:
	return get_owned_ids().has(perk.id)


## Son monde est débloqué, et toutes les améliorations demandées par celle-ci sont achetées.
static func is_unlocked(perk: Perk) -> bool:
	if not is_world_unlocked(perk):
		return false
	var owned := get_owned_ids()
	for required in perk.requires:
		if not owned.has(required.id):
			return false
	return true


## Le monde demandé par l'amélioration (s'il y en a un) est débloqué.
static func is_world_unlocked(perk: Perk) -> bool:
	return perk.required_world < 0 or Progress.is_world_unlocked(CAMPAIGN, perk.required_world)


## Nom du monde demandé par l'amélioration, ou "".
static func get_required_world_name(perk: Perk) -> String:
	return CAMPAIGN.worlds[perk.required_world].display_name if perk.required_world >= 0 else ""


## Tours (TowerData) débloquées par les améliorations achetées, dans l'ordre de l'arbre.
static func get_unlocked_towers() -> Array[Resource]:
	var owned := get_owned_ids()
	var result: Array[Resource] = []
	for perk in TREE.perks:
		if not perk.unlocks_tower.is_empty() and owned.has(perk.id):
			result.append(perk.get_unlocked_tower())
	return result


## Pouvoirs actifs (Power) débloqués par les améliorations achetées, dans l'ordre de
## l'arbre, avec les renforts achetés : des copies, qu'on peut modifier.
static func get_powers() -> Array[Resource]:
	var owned := get_owned_ids()
	var result: Array[Resource] = []
	for perk in TREE.perks:
		if perk.unlocks_power.is_empty() or not owned.has(perk.id):
			continue
		var power: Resource = load(perk.unlocks_power).duplicate()
		for upgrade in TREE.perks:
			if upgrade.improves_power == perk.unlocks_power and owned.has(upgrade.id):
				upgrade.apply_to_power(power)
		result.append(power)
	return result


## Spécialisations et croisements achetés pour une tour (chemin de sa TowerData), dans
## l'ordre de l'arbre. Pour la seconde tour d'un croisement, c'est son effet
## (partner_effect) qui est dans la liste.
static func get_specializations(tower_path: String) -> Array[Perk]:
	var owned := get_owned_ids()
	var result: Array[Perk] = []
	if tower_path.is_empty():
		return result
	for perk in TREE.perks:
		if not owned.has(perk.id):
			continue
		if perk.specializes_tower == tower_path:
			result.append(perk)
		elif perk.get_partner_tower_path() == tower_path:
			result.append(perk.partner_effect)
	return result


## Étoiles gagnées sur tous les niveaux de la campagne (meilleur résultat de chacun
## dans chaque difficulté), ou
## avec `endless`, étoiles infinies gagnées en mode infini.
static func get_earned_stars(endless := false) -> int:
	var total := 0
	for path in CAMPAIGN.levels:
		total += Progress.get_endless_stars(path) if endless else Progress.get_total_stars(path)
	return total


## Étoiles (ou étoiles infinies) dépensées dans l'arbre.
static func get_spent_stars(endless := false) -> int:
	var total := 0
	for id in get_owned_ids():
		var perk := TREE.get_perk(id)
		if perk and perk.paid_with_endless_stars == endless:
			total += perk.cost
	return total


static func get_available_stars(endless := false) -> int:
	return get_earned_stars(endless) - get_spent_stars(endless)


static func can_buy(perk: Perk) -> bool:
	return not is_owned(perk) and is_unlocked(perk) \
		and get_available_stars(perk.paid_with_endless_stars) >= perk.cost


## Achète l'amélioration si c'est possible. Renvoie true si elle a été achetée.
static func buy(perk: Perk) -> bool:
	if not can_buy(perk):
		return false
	var owned := get_owned_ids()
	owned.append(perk.id)
	Progress.set_value("perks", "owned", owned)
	return true


## Code Konami : tous les niveaux gagnés avec 3 étoiles, tous les mondes et modes infinis
## ouverts avec toutes leurs étoiles infinies, et toutes les améliorations achetées.
static func unlock_everything() -> void:
	var ids := PackedStringArray()
	for perk in TREE.perks:
		ids.append(perk.id)
	Progress.unlock_all(CAMPAIGN.levels, ids)


## Rend toutes les étoiles dépensées.
static func refund_all() -> void:
	Progress.set_value("perks", "owned", PackedStringArray())


## Total des bonus des améliorations achetées, sous la forme d'une seule amélioration.
static func get_bonuses() -> Perk:
	var total := Perk.new()
	for id in get_owned_ids():
		var perk := TREE.get_perk(id)
		# Les bonus d'une spécialisation ne valent que pour sa tour (TowerData).
		if perk and not perk.is_specialization():
			perk.add_to(total)
	return total


## À appeler quand la progression change : la liste sera relue.
static func clear_cache() -> void:
	if Engine.has_meta(OWNED_META):
		Engine.remove_meta(OWNED_META)
