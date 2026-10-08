class_name Research
extends RefCounted
## Mode Conquête : améliorations lancées dans un Atelier (Building.Kind.WORKSHOP) contre de
## l'or, de la pierre et de l'essence. Chacune a quelques niveaux, qui demandent un temps
## de recherche et valent pour le reste de la partie (pas au-delà : la progression
## d'une partie à l'autre reste l'arbre des améliorations). Un Atelier ne lance qu'une
## amélioration à la fois, et une même amélioration ne se cherche pas dans deux Ateliers
## en même temps. C'est le mode Conquête (Conquest) qui garde les niveaux atteints et
## applique leurs effets.

enum Category { WORKERS, TOWERS, WORLD }

## Nom de chaque catégorie, dans l'ordre de Category ; « Monde » regroupe les bonus de la
## carte en cours (or des monstres, bâtiments, filons).
const CATEGORY_NAMES: Array[String] = ["Ouvriers", "Tours", "Monde"]
const CATEGORY_COLORS: Array[Color] = [Color(1.0, 0.72, 0.25), Color(0.55, 0.8, 1.0), Color(0.6, 1.0, 0.6)]

const WORKER_SPEED := &"worker_speed"
const WORKER_CARRY := &"worker_carry"
const WORKER_TOOLS := &"worker_tools"
const TOWER_DAMAGE := &"tower_damage"
const TOWER_RANGE := &"tower_range"
const TOWER_FIRE_RATE := &"tower_fire_rate"
const WORLD_BOUNTY := &"world_bounty"
const WORLD_FORTIFY := &"world_fortify"
const WORLD_EXTRACTION := &"world_extraction"

## Secondes de recherche de chaque niveau (le premier, le deuxième…).
const TIMES: Array[float] = [15.0, 25.0, 35.0]

## Fiche de chaque amélioration : identifiant, catégorie, nom, effet, bonus par niveau
## et prix de chaque niveau ([or, pierre, essence]) ; leur nombre est le niveau maximum.
const DEFINITIONS: Array[Dictionary] = [
	{id = WORKER_SPEED, category = Category.WORKERS, name = "Bottes de marche", per_level = 0.15,
		description = "Ouvriers : +15 % de vitesse de marche par niveau.",
		costs = [[40, 20, 0], [70, 35, 2], [100, 50, 4]]},
	{id = WORKER_CARRY, category = Category.WORKERS, name = "Grandes hottes", per_level = 1.0,
		description = "Ouvriers : +1 pierre et +1 essence par voyage, par niveau.",
		costs = [[50, 25, 0], [90, 45, 3]]},
	{id = WORKER_TOOLS, category = Category.WORKERS, name = "Outils affûtés", per_level = 0.2,
		description = "Ouvriers : minage et construction +20 % par niveau.",
		costs = [[50, 25, 0], [80, 40, 2], [110, 55, 4]]},
	{id = TOWER_DAMAGE, category = Category.TOWERS, name = "Poudre raffinée", per_level = 0.08,
		description = "Tours : +8 % de dégâts par niveau.",
		costs = [[80, 30, 0], [130, 45, 3], [180, 60, 6]]},
	{id = TOWER_RANGE, category = Category.TOWERS, name = "Lunettes de visée", per_level = 0.06,
		description = "Tours : +6 % de portée par niveau.",
		costs = [[60, 25, 0], [100, 40, 2], [140, 55, 4]]},
	{id = TOWER_FIRE_RATE, category = Category.TOWERS, name = "Mécanismes huilés", per_level = 0.06,
		description = "Tours : +6 % de cadence de tir par niveau.",
		costs = [[70, 30, 0], [115, 45, 3], [160, 60, 5]]},
	{id = WORLD_BOUNTY, category = Category.WORLD, name = "Primes de chasse", per_level = 0.1,
		description = "Monstres : +10 % d'or par niveau.",
		costs = [[60, 20, 0], [100, 30, 2], [140, 40, 4]]},
	{id = WORLD_FORTIFY, category = Category.WORLD, name = "Fortifications", per_level = 0.3,
		description = "Bâtiments et Barricades : +30 % de vie par niveau.",
		costs = [[50, 40, 0], [90, 70, 3]]},
	{id = WORLD_EXTRACTION, category = Category.WORLD, name = "Forages profonds", per_level = 0.25,
		description = "Extracteurs : +25 % d'essence par niveau.",
		costs = [[60, 30, 2], [100, 50, 4]]},
]


static func get_definition(id: StringName) -> Dictionary:
	for definition in DEFINITIONS:
		if definition.id == id:
			return definition
	return {}


static func get_max_level(id: StringName) -> int:
	return get_definition(id).costs.size()


## Prix d'un niveau (1 = le premier) : {gold, stone, essence}.
static func get_cost(id: StringName, at_level: int) -> Dictionary:
	var cost: Array = get_definition(id).costs[clampi(at_level, 1, get_max_level(id)) - 1]
	return {gold = cost[0], stone = cost[1], essence = cost[2]}


## Secondes de recherche d'un niveau (1 = le premier).
static func get_time(at_level: int) -> float:
	return TIMES[clampi(at_level, 1, TIMES.size()) - 1]


## Prix sur une ligne : « 70 or · 35 p · 2 e ».
static func price_text(cost: Dictionary) -> String:
	if cost.essence > 0:
		return TranslationServer.translate("%d or · %d p · %d e") % [cost.gold, cost.stone, cost.essence]
	return TranslationServer.translate("%d or · %d p") % [cost.gold, cost.stone]
