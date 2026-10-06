class_name Achievements
extends RefCounted
## Succès : des objectifs à remplir en jouant (finir un niveau sans perdre de vie, vaincre
## un boss avec 3 tours…), enregistrés avec la progression. Ils se débloquent en jeu, au
## moment où l'objectif est rempli (un bandeau l'annonce), ou en regardant la progression
## (étoiles, mondes terminés, arbre des améliorations). La page Succès, depuis l'écran
## titre, les montre tous.
##
## Chaque succès est un dictionnaire de LIST :
## - id, name, description, icon (un caractère dessiné dans sa vignette) ;
## - selon son objectif, une seule de ces clés :
##   - win : condition vérifiée à la fin d'une partie gagnée (voir _is_win_met) ;
##   - boss : chemin du boss à vaincre ;
##   - world : indice du monde dont il faut gagner tous les niveaux ;
##   - counter + goal : compteur cumulé sur toutes les parties (voir add_counters) ;
##   - stars : étoiles à obtenir ; perks : améliorations à acheter dans l'arbre ;
##   - aucune : débloqué par le niveau à un moment précis (commando, impatient, infatigable).
## Les identifiants sont enregistrés dans la sauvegarde : ne pas les renommer.

## Section du fichier : identifiant -> date du déblocage (secondes Unix).
const SECTION := "achievements"
## Section des compteurs cumulés (monstres, élites détruits).
const COUNTERS_SECTION := "achievement_counters"
const CAMPAIGN_PATH := "res://resources/campaign.tres"
const COLOR := Color(1.0, 0.78, 0.3)

## Seuils des succès débloqués en cours de partie.
const COMMANDO_MAX_TOWERS := 3
const MINIMALIST_MAX_TOWERS := 5
const IMPATIENT_EARLY_CALLS := 5
const TREASURE_GOLD := 1000
const TIRELESS_WAVES := 30

const LIST: Array[Dictionary] = [
	{id = "premier_pas", name = "Premier pas", icon = "★",
		description = "Gagner un niveau.", win = "any"},
	{id = "sans_egratignure", name = "Sans une égratignure", icon = "♥",
		description = "Gagner un niveau sans perdre de vie.", win = "no_lives_lost"},
	{id = "sur_le_fil", name = "Sur le fil", icon = "!",
		description = "Gagner un niveau avec une seule vie restante.", win = "one_life"},
	{id = "ruche", name = "La Ruche nettoyée", icon = "1",
		description = "Gagner les niveaux de La Ruche.", world = 0},
	{id = "fonderie", name = "La Fonderie éteinte", icon = "2",
		description = "Gagner les niveaux de La Fonderie.", world = 1},
	{id = "cite", name = "La Cité libérée", icon = "3",
		description = "Gagner les niveaux de La Cité.", world = 2},
	{id = "regicide", name = "Régicide", icon = "♛",
		description = "Vaincre la Reine de la Ruche.", boss = "res://resources/enemies/insectoid/reine.tres"},
	{id = "demolition", name = "Démolition", icon = "⚙",
		description = "Vaincre le Béhémoth.", boss = "res://resources/enemies/mecha/behemoth.tres"},
	{id = "coup_d_etat", name = "Coup d'État", icon = "✪",
		description = "Vaincre le Général.", boss = "res://resources/enemies/humanoid/general.tres"},
	{id = "commando", name = "Commando", icon = "✠",
		description = "Vaincre un boss avec 3 tours ou moins sur la carte."},
	{id = "minimaliste", name = "Minimaliste", icon = "5",
		description = "Gagner un niveau en posant 5 tours au plus.", win = "minimalist"},
	{id = "brut_de_pose", name = "Brut de pose", icon = "▲",
		description = "Gagner un niveau sans améliorer aucune tour.", win = "no_upgrade"},
	{id = "monoculture", name = "Monoculture", icon = "◆",
		description = "Gagner un niveau avec un seul type de tour.", win = "one_type"},
	{id = "impatient", name = "Impatient", icon = "»",
		description = "Lancer 5 vagues en avance dans une même partie."},
	{id = "tresor", name = "Trésor de guerre", icon = "¤",
		description = "Gagner un niveau avec 1000 pièces d'or en poche.", win = "treasure"},
	{id = "cauchemar", name = "Cauchemar vaincu", icon = "☠",
		description = "Gagner un niveau en Cauchemar.", win = "nightmare"},
	{id = "infatigable", name = "Infatigable", icon = "∞",
		description = "Repousser 30 vagues dans une partie du mode infini."},
	{id = "chasseur", name = "Chasseur d'élites", icon = "◎",
		description = "Détruire 50 monstres élites.", counter = "elite_kills", goal = 50},
	{id = "exterminateur", name = "Exterminateur", icon = "✖",
		description = "Détruire 5000 monstres.", counter = "kills", goal = 5000},
	{id = "constellation", name = "Constellation", icon = "✦",
		description = "Obtenir 100 étoiles.", stars = 100},
	{id = "jardinier", name = "Jardinier", icon = "❦",
		description = "Acheter 15 améliorations dans l'arbre.", perks = 15},
]


static func get_definition(id: String) -> Dictionary:
	for definition in LIST:
		if definition.id == id:
			return definition
	return {}


static func is_unlocked(id: String) -> bool:
	return Progress.get_value(SECTION, id, 0) > 0


static func get_unlocked_count() -> int:
	var count := 0
	for definition in LIST:
		if is_unlocked(definition.id):
			count += 1
	return count


## Date du déblocage (secondes Unix), 0 s'il n'est pas débloqué.
static func get_unlock_time(id: String) -> int:
	return Progress.get_value(SECTION, id, 0)


## Débloque un succès. Renvoie true s'il ne l'était pas encore.
static func unlock(id: String) -> bool:
	if get_definition(id).is_empty() or is_unlocked(id):
		return false
	Progress.set_value(SECTION, id, maxi(int(Time.get_unix_time_from_system()), 1))
	return true


## Débloque ceux de la liste qui ne l'étaient pas, et renvoie leurs identifiants.
static func unlock_all(ids: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for id in ids:
		if unlock(id):
			result.append(id)
	return result


static func get_counter(key: String) -> int:
	return Progress.get_value(COUNTERS_SECTION, key, 0)


## Ajoute aux compteurs cumulés (clé -> quantité) et débloque les succès dont l'objectif
## est atteint. Renvoie les identifiants débloqués.
static func add_counters(amounts: Dictionary) -> Array[String]:
	var changed := false
	for key: String in amounts:
		if amounts[key] > 0:
			Progress.set_value(COUNTERS_SECTION, key, get_counter(key) + amounts[key])
			changed = true
	if not changed:
		return []
	return check_progress()


## Avancement d'un succès à objectif chiffré : [fait, objectif], ou [] s'il n'en a pas.
static func get_progress(definition: Dictionary) -> Array[int]:
	if definition.has("counter"):
		return [get_counter(definition.counter), definition.goal]
	if definition.has("stars"):
		return [Perks.get_earned_stars(), definition.stars]
	if definition.has("perks"):
		return [Perks.get_owned_ids().size(), definition.perks]
	if definition.has("world"):
		var campaign: Campaign = load(CAMPAIGN_PATH)
		if definition.world >= campaign.worlds.size():
			return []
		var levels := campaign.worlds[definition.world].levels
		return [levels.filter(func(path: String) -> bool: return Progress.get_stars(path) > 0).size(), levels.size()]
	return []


## Débloque les succès que la progression a remplis (compteurs, étoiles, mondes,
## arbre). Renvoie les identifiants débloqués.
static func check_progress() -> Array[String]:
	var ids: Array[String] = []
	for definition in LIST:
		var progress := get_progress(definition)
		if not progress.is_empty() and progress[0] >= progress[1] and not is_unlocked(definition.id):
			ids.append(definition.id)
	return unlock_all(ids)


## Succès d'une partie gagnée : ceux dont la condition `win` est remplie, puis ceux de
## la progression (le niveau vient d'être enregistré). Renvoie les identifiants débloqués.
static func on_victory(stats: LevelStats, lives: int, gold: int, difficulty: int) -> Array[String]:
	var ids: Array[String] = []
	for definition in LIST:
		if definition.has("win") and _is_win_met(definition.win, stats, lives, gold, difficulty):
			ids.append(definition.id)
	var result := unlock_all(ids)
	result.append_array(check_progress())
	return result


## Boss vaincu, avec `towers` tours sur la carte. Renvoie les identifiants débloqués.
static func on_boss_killed(boss: EnemyData, towers: int) -> Array[String]:
	var ids: Array[String] = []
	for definition in LIST:
		if definition.get("boss", "") == boss.resource_path:
			ids.append(definition.id)
	if towers <= COMMANDO_MAX_TOWERS:
		ids.append("commando")
	return unlock_all(ids)


static func _is_win_met(condition: String, stats: LevelStats, lives: int, gold: int, difficulty: int) -> bool:
	match condition:
		"any":
			return true
		"no_lives_lost":
			return stats.lives_lost == 0
		"one_life":
			return lives == 1
		"minimalist":
			return stats.towers_built <= MINIMALIST_MAX_TOWERS
		"no_upgrade":
			return stats.upgrades_bought == 0 and stats.towers_built > 0
		"one_type":
			return stats.get_type_count() == 1
		"treasure":
			return gold >= TREASURE_GOLD
		"nightmare":
			return difficulty == Difficulty.CAUCHEMAR
	return false
