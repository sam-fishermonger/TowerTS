class_name FreeLevels
extends RefCounted
## Niveaux libres, dans l'ordre : pas de chemin tracé, seulement des points d'apparition
## et le QG ; les tours posées servent de murs et les monstres passent au plus court
## (GameMap.free_layout). Chacun s'ouvre quand le précédent a été gagné (dans n'importe
## quelle difficulté). Leurs étoiles s'enregistrent comme celles de la campagne
## (Progress) et comptent pour l'arbre des améliorations.

const SELECT_SCREEN := "res://scenes/ui/free_select_screen.tscn"
const LEVELS: Array[String] = [
	"res://scenes/levels/free_01.tscn",
	"res://scenes/levels/free_02.tscn",
	"res://scenes/levels/free_03.tscn",
	"res://scenes/levels/free_04.tscn",
]
## Nom, monde de la campagne (son biome), nombre de points d'apparition et présentation de chaque niveau.
const INFO: Array[Dictionary] = [
	{name = "La Clairière", world = 0, spawns = 1,
		description = "Un seul terrier, le QG en face et presque rien entre les deux : à vous de tracer le chemin."},
	{name = "La Cour de l'usine", world = 1, spawns = 2,
		description = "Deux portes crachent des machines blindées. Un même labyrinthe doit les ralentir toutes."},
	{name = "La Grand-Place", world = 2, spawns = 2,
		description = "Le QG est dans un coin, les rues arrivent de deux côtés et les Aviateurs survolent vos murs."},
	{name = "Le Cimetière", world = 3, spawns = 3,
		description = "Trois entrées et des morts qui se relèvent : il faut un labyrinthe qui tienne la distance."},
]


static func size() -> int:
	return LEVELS.size()


static func has(path: String) -> bool:
	return LEVELS.has(path)


## Niveau libre qui suit celui-ci ("" pour le dernier, ou hors de la liste).
static func get_next(path: String) -> String:
	var index := LEVELS.find(path)
	return LEVELS[index + 1] if index >= 0 and index + 1 < LEVELS.size() else ""


static func is_unlocked(index: int) -> bool:
	return index == 0 or (index > 0 and index < LEVELS.size() and Progress.get_stars(LEVELS[index - 1]) > 0)


## Étoiles obtenues sur tous les niveaux libres, toutes difficultés confondues.
static func get_total_stars() -> int:
	var total := 0
	for path in LEVELS:
		total += Progress.get_total_stars(path)
	return total
