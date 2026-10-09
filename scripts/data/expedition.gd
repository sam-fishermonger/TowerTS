class_name Expedition
extends RefCounted
## Mode Expédition : cinq niveaux de la campagne tirés au sort, joués à la suite. Les vies
## restantes passent d'un niveau à l'autre (l'Infirmerie ne rend jamais plus que celles du
## départ), et les coffres y proposent trois bonus au choix, gardés pour toute
## l'expédition (ailleurs, un coffre donne un bonus au hasard pour le niveau seulement).
## Une défaite met fin à l'expédition. Elle ne donne pas d'étoiles : le record (étapes
## réussies) et les expéditions réussies sont enregistrés (Progress, section « expedition »).
##
## L'expédition en cours passe d'un niveau à l'autre en dictionnaire (to_dict()), dans une
## méta du moteur que le niveau lit et efface à son lancement (Level.open_expedition()).

const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")
## Niveaux d'une expédition.
const LEVEL_COUNT := 5
## Bonus proposés par un coffre.
const CHEST_CHOICES := 3
const COLOR := Color(0.55, 0.9, 0.75)
const SECTION := "expedition"

## Graine du tirage : les niveaux et les coffres en dépendent.
var rng_seed := 0
## Niveaux de l'expédition (chemins des scènes), dans l'ordre.
var levels: Array[String] = []
## Étape en cours (0 = premier niveau).
var index := 0
## Vies au début de l'étape en cours (-1 : celles du premier niveau, arbre compris).
var lives := -1
## Vies du départ de l'expédition : le maximum pour l'Infirmerie et les étoiles.
var max_lives := -1
## Bonus des coffres gagnés depuis le départ : exemplaires par identifiant (ChestBonus).
var chest_levels := {}


## Nouvelle expédition tirée au sort (graine au hasard si 0).
static func create(new_seed := 0) -> Expedition:
	var expedition := Expedition.new()
	expedition.rng_seed = new_seed if new_seed != 0 else randi() | 1
	expedition.levels = draw_levels(expedition.rng_seed, get_pool())
	return expedition


static func from_dict(data: Dictionary) -> Expedition:
	var expedition := Expedition.new()
	expedition.rng_seed = data.get("rng_seed", 1)
	expedition.levels.assign(data.get("levels", []))
	expedition.index = data.get("index", 0)
	expedition.lives = data.get("lives", -1)
	expedition.max_lives = data.get("max_lives", -1)
	expedition.chest_levels = (data.get("chest_levels", {}) as Dictionary).duplicate()
	return expedition


func to_dict() -> Dictionary:
	return {rng_seed = rng_seed, levels = levels.duplicate(), index = index, lives = lives, max_lives = max_lives,
		chest_levels = chest_levels.duplicate()}


## Niveaux qui peuvent tomber : ceux de la campagne déjà débloqués, dans l'ordre.
static func get_pool() -> Array[String]:
	var result: Array[String] = []
	var all := CAMPAIGN.levels
	for i in all.size():
		if Progress.is_unlocked(CAMPAIGN, i):
			result.append(all[i])
	return result


## Le mode s'ouvre avec la progression de la campagne (Unlocks), qui débloque assez de niveaux.
static func is_unlocked() -> bool:
	return Unlocks.is_unlocked(Unlocks.Feature.EXPEDITION) and get_pool().size() >= LEVEL_COUNT


## Tirage des niveaux : la liste (dans l'ordre de la campagne) est coupée en LEVEL_COUNT
## tranches, et un niveau est pris dans chacune. L'expédition devient de plus en plus dure.
static func draw_levels(draw_seed: int, pool: Array[String]) -> Array[String]:
	var rng := RandomNumberGenerator.new()
	rng.seed = draw_seed
	var result: Array[String] = []
	if pool.is_empty():
		return result
	for i in LEVEL_COUNT:
		var from := floori(float(i) * pool.size() / LEVEL_COUNT)
		var to := maxi(floori(float(i + 1) * pool.size() / LEVEL_COUNT), from + 1)
		result.append(pool[mini(rng.randi_range(from, to - 1), pool.size() - 1)])
	return result


func get_level() -> String:
	return levels[index] if index < levels.size() else ""


func is_last() -> bool:
	return index >= levels.size() - 1


## Bonus proposés par un coffre : jusqu'à CHEST_CHOICES différents parmi `available`, tirés
## avec `rng` (dans l'ordre de ChestBonus.DEFINITIONS).
static func pick_choices(available: Array[StringName], rng: RandomNumberGenerator) -> Array[StringName]:
	var pool := available.duplicate()
	var picked: Array[StringName] = []
	while not pool.is_empty() and picked.size() < CHEST_CHOICES:
		picked.append(pool.pop_at(rng.randi() % pool.size()))
	var result: Array[StringName] = []
	for id in available:
		if picked.has(id):
			result.append(id)
	return result


# --- Records ----------------------------------------------------------------

## Meilleur nombre d'étapes réussies dans une expédition.
static func get_best() -> int:
	return Progress.get_value(SECTION, "best", 0)


## Expéditions menées jusqu'au bout.
static func get_wins() -> int:
	return Progress.get_value(SECTION, "wins", 0)


## Fin d'une expédition après `cleared` étapes réussies : renvoie true si c'est un record.
static func record(cleared: int) -> bool:
	var best := get_best()
	if cleared >= LEVEL_COUNT:
		Progress.set_value(SECTION, "wins", get_wins() + 1)
	if cleared > best:
		Progress.set_value(SECTION, "best", cleared)
		return true
	return false
