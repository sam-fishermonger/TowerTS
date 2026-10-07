class_name ConquestLevels
extends RefCounted
## Niveaux du mode Conquête, dans l'ordre : chacun s'ouvre quand le précédent a été
## gagné (dans n'importe quelle difficulté). Leurs étoiles s'enregistrent comme celles de
## la campagne (Progress) et comptent pour l'arbre des améliorations.

const SELECT_SCREEN := "res://scenes/ui/conquest_select_screen.tscn"
const LEVELS: Array[String] = [
	"res://scenes/levels/conquest_01.tscn",
	"res://scenes/levels/conquest_02.tscn",
	"res://scenes/levels/conquest_03.tscn",
	"res://scenes/levels/conquest_04.tscn",
	"res://scenes/levels/conquest_05.tscn",
	"res://scenes/levels/conquest_06.tscn",
]
## Nom, monde de la campagne (son biome et ses Pillards) et présentation de chaque niveau.
const INFO: Array[Dictionary] = [
	{name = "La Carrière", world = 0,
		description = "Une carrière pleine de rochers, un seul chemin : de quoi apprendre à miner et à bâtir."},
	{name = "La Mine de fer", world = 1,
		description = "Le chemin serpente sur toute la carte : chaque gisement se mine sous le feu des machines."},
	{name = "Les Faubourgs", world = 2,
		description = "Des maisons à bâtir loin du QG, et des Maraudeurs rapides pour les incendier."},
	{name = "Les Catacombes", world = 3,
		description = "Deux chemins de morts-vivants et des Pilleurs de tombes dès la première vague."},
	{name = "Le Nid de la Reine", world = 0,
		description = "Dix vagues, un long chemin en spirale autour du QG, et la Reine au bout."},
	{name = "Le Dédale", world = 0,
		description = "Pas de chemin : vos tours et vos bâtiments font le labyrinthe, et chaque rocher miné ouvre un passage."},
]


static func size() -> int:
	return LEVELS.size()


## Niveau qui suit un niveau de Conquête ("" pour le dernier, ou hors de la liste).
static func get_next(path: String) -> String:
	var index := LEVELS.find(path)
	return LEVELS[index + 1] if index >= 0 and index + 1 < LEVELS.size() else ""


static func is_unlocked(index: int) -> bool:
	return index == 0 or (index > 0 and index < LEVELS.size() and Progress.get_stars(LEVELS[index - 1]) > 0)


## Étoiles obtenues sur tous les niveaux de Conquête, toutes difficultés confondues.
static func get_total_stars() -> int:
	var total := 0
	for path in LEVELS:
		total += Progress.get_total_stars(path)
	return total
