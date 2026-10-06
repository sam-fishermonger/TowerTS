class_name CustomLevel
extends RefCounted
## Niveau fait dans l'éditeur : un chemin tracé case par case, des rochers, des vagues
## et l'or et les vies de départ. Il est gardé sous forme de dictionnaire (enregistré
## avec la progression, voir LevelEditor) et joué dans la scène de niveau vide, que
## apply() remplit avant qu'elle soit prête.
##
## Le dictionnaire :
## - biome : indice du monde dont la carte prend les tuiles et les couleurs ;
## - path : cases du chemin (Vector2i), chacune alignée avec la précédente : le chemin
##   va en ligne droite de l'une à l'autre. La première est au bord de la carte ;
## - rocks : cases bloquées (Vector2i) ;
## - gold, lives : or et vies de départ ;
## - waves : une vague par élément, { groups = [{ enemy (chemin de l'EnemyData),
##   count, elite }] }.

const CAMPAIGN_PATH := "res://resources/campaign.tres"
## Réglage (Progress) qui garde le niveau en cours d'édition.
const SETTING := "editor_level"
const LEVEL_NAME := "Niveau perso"

## Grille de la carte (celle de GameMap).
const COLUMNS := 20
const ROWS := 10
const CELL_SIZE := 64
const GRID_ORIGIN := Vector2(0, 64)

const MIN_GOLD := 50
const MAX_GOLD := 2000
const MIN_LIVES := 1
const MAX_LIVES := 100
const MAX_WAVES := 15
const MAX_GROUPS := 4
const MAX_COUNT := 200

## Secondes entre deux ennemis d'un groupe : une distance de marche, entre ces bornes.
const SPAWN_SPACING := 60.0
const MIN_INTERVAL := 0.3
const MAX_INTERVAL := 1.5
## Secondes entre le départ de deux groupes d'une même vague.
const GROUP_DELAY := 4.0
## Or donné quand une vague est repoussée : de base, plus tant par vague.
const WAVE_BONUS := 20
const WAVE_BONUS_STEP := 5

## Tours de départ, comme dans les niveaux de la campagne (s'y ajoutent celles de l'arbre).
const BASE_TOWERS: Array[String] = [
	"res://resources/towers/cannon.tres", "res://resources/towers/gatling.tres",
	"res://resources/towers/sniper.tres", "res://resources/towers/mortar.tres",
	"res://resources/towers/frost.tres", "res://resources/towers/beam.tres",
]

## Couleurs de la carte de chaque biome (fond, sol, chemin, rochers), reprises du
## premier niveau de chaque monde.
const BIOME_COLORS: Array[Array] = [
	[Color(0.13, 0.17, 0.13), Color(0.2, 0.32, 0.2), Color(0.72, 0.6, 0.42), Color(0.42, 0.42, 0.45)],
	[Color(0.08, 0.09, 0.11), Color(0.24, 0.26, 0.29), Color(0.56, 0.5, 0.4), Color(0.5, 0.42, 0.36)],
	[Color(0.09, 0.11, 0.08), Color(0.27, 0.36, 0.22), Color(0.45, 0.45, 0.48), Color(0.6, 0.45, 0.38)],
	[Color(0.07, 0.07, 0.09), Color(0.3, 0.3, 0.33), Color(0.46, 0.42, 0.36), Color(0.58, 0.58, 0.62)],
]


## Niveau de départ de l'éditeur : un chemin en S et trois vagues de La Ruche.
static func create_default() -> Dictionary:
	return {
		biome = 0,
		path = [Vector2i(0, 2), Vector2i(8, 2), Vector2i(8, 7), Vector2i(15, 7), Vector2i(15, 3), Vector2i(19, 3)],
		rocks = [Vector2i(3, 5), Vector2i(12, 1), Vector2i(17, 8)],
		gold = 250,
		lives = 20,
		waves = [
			{groups = [{enemy = "res://resources/enemies/insectoid/larve.tres", count = 12, elite = false}]},
			{groups = [{enemy = "res://resources/enemies/insectoid/larve.tres", count = 15, elite = false},
				{enemy = "res://resources/enemies/insectoid/rodeur.tres", count = 8, elite = false}]},
			{groups = [{enemy = "res://resources/enemies/insectoid/scarabee.tres", count = 10, elite = false},
				{enemy = "res://resources/enemies/insectoid/reine.tres", count = 1, elite = false}]},
		],
	}


## Niveau en cours d'édition (celui par défaut s'il n'y en a pas encore).
static func load_saved() -> Dictionary:
	var data: Variant = Progress.get_setting(SETTING, {})
	if data is Dictionary and validate(data).is_empty():
		return data
	return create_default()


static func save(data: Dictionary) -> void:
	Progress.set_setting(SETTING, data)


## Monstres qu'on peut mettre dans les vagues : ceux de chaque monde, puis ses boss.
static func get_enemy_choices() -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	var campaign: Campaign = load(CAMPAIGN_PATH)
	for world in campaign.worlds:
		for enemy in world.enemies + world.bosses:
			if not result.has(enemy):
				result.append(enemy)
	return result


static func get_biome_names() -> Array[String]:
	var result: Array[String] = []
	var campaign: Campaign = load(CAMPAIGN_PATH)
	for world in campaign.worlds:
		result.append(world.display_name)
	return result


# --- Chemin ------------------------------------------------------------------

static func is_in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < COLUMNS and cell.y < ROWS


static func is_on_edge(cell: Vector2i) -> bool:
	return is_in_grid(cell) and (cell.x == 0 or cell.y == 0 or cell.x == COLUMNS - 1 or cell.y == ROWS - 1)


## Toutes les cases traversées par le chemin, dans l'ordre (sans répéter les coins).
static func expand_path(path: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for i in path.size():
		var cell: Vector2i = path[i]
		if i == 0:
			result.append(cell)
			continue
		var from: Vector2i = path[i - 1]
		var step := (cell - from).sign()
		if step == Vector2i.ZERO or (step.x != 0 and step.y != 0):
			continue
		var current := from
		while current != cell:
			current += step
			result.append(current)
	return result


## Ajoute une case au bout du chemin. Une case qui n'est pas alignée avec la dernière
## passe par un coin (d'abord à l'horizontale), et une case dans le prolongement de
## la dernière ligne droite la rallonge. Une case déjà sur le chemin le coupe juste
## après elle. Renvoie le nouveau chemin, ou le même si la case ne va pas.
static func extend_path(path: Array, cell: Vector2i) -> Array:
	if not is_in_grid(cell):
		return path
	var result := path.duplicate()
	if result.is_empty():
		return [cell] if is_on_edge(cell) else path
	var cells := expand_path(result)
	var index := cells.find(cell)
	if index >= 0:
		return truncate_path(result, cell)
	var last: Vector2i = result[-1]
	if cell.x != last.x and cell.y != last.y:
		var corner := Vector2i(cell.x, last.y)
		if cells.has(corner):
			corner = Vector2i(last.x, cell.y)
			if cells.has(corner):
				return path
		if _segment_hits(cells, last, corner) or _segment_hits(cells, corner, cell):
			return path
		_append_point(result, corner)
	elif _segment_hits(cells, last, cell):
		return path
	_append_point(result, cell)
	return result


## Coupe le chemin juste après la case donnée (qui doit être sur le chemin).
static func truncate_path(path: Array, cell: Vector2i) -> Array:
	var result := []
	for i in path.size():
		var point: Vector2i = path[i]
		if i > 0:
			var from: Vector2i = path[i - 1]
			var segment := expand_path([from, point])
			var index := segment.find(cell)
			if index > 0:
				result.append(cell)
				return result
		result.append(point)
		if point == cell:
			return result
	return result


## Le segment de from (exclu) à to passe-t-il par une case déjà prise ?
static func _segment_hits(cells: Array[Vector2i], from: Vector2i, to: Vector2i) -> bool:
	for cell in expand_path([from, to]).slice(1):
		if cells.has(cell):
			return true
	return false


## Ajoute un point : s'il prolonge la dernière ligne droite, il remplace son bout.
static func _append_point(path: Array, cell: Vector2i) -> void:
	if path.size() >= 2:
		var a: Vector2i = path[-2]
		var b: Vector2i = path[-1]
		if (b - a).sign() == (cell - b).sign():
			path[-1] = cell
			return
	path.append(cell)


## Points du chemin en pixels : du bord de l'écran (une demi-case dehors, d'où
## viennent les ennemis) jusqu'à la base, dehors aussi si le chemin finit au bord.
static func get_path_points(path: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for cell: Vector2i in path:
		points.append(cell_center(cell))
	if path.size() >= 2:
		points.insert(0, points[0] + _outward(path[0], path[1]) * CELL_SIZE)
		var last: Vector2i = path[-1]
		if is_on_edge(last):
			points.append(points[-1] + _outward(last, path[-2]) * CELL_SIZE)
	return points


static func cell_center(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE


## Direction qui sort de la carte depuis une case du bord (en s'éloignant de la case
## voisine sur le chemin quand elle est dans un coin).
static func _outward(cell: Vector2i, neighbour: Vector2i) -> Vector2:
	var away := Vector2(cell - neighbour).sign()
	var options: Array[Vector2] = []
	if cell.x == 0:
		options.append(Vector2.LEFT)
	if cell.x == COLUMNS - 1:
		options.append(Vector2.RIGHT)
	if cell.y == 0:
		options.append(Vector2.UP)
	if cell.y == ROWS - 1:
		options.append(Vector2.DOWN)
	for option in options:
		if option == away or (option.x != 0 and option.x == away.x) or (option.y != 0 and option.y == away.y):
			return option
	return options[0] if not options.is_empty() else away


# --- Vagues --------------------------------------------------------------------

## Secondes entre deux ennemis d'un groupe : les rapides se suivent de plus près.
static func get_interval(enemy: EnemyData) -> float:
	return clampf(SPAWN_SPACING / enemy.speed, MIN_INTERVAL, MAX_INTERVAL)


static func build_waves(data: Dictionary) -> Array[WaveData]:
	var result: Array[WaveData] = []
	var waves: Array = data.waves
	for i in waves.size():
		var wave := WaveData.new()
		var groups: Array = waves[i].groups
		for j in groups.size():
			var entry: Dictionary = groups[j]
			var enemy: EnemyData = load(entry.enemy)
			var group := SpawnGroup.new()
			group.enemy = enemy
			group.count = 1 if enemy.is_boss else int(entry.count)
			group.elite = bool(entry.get("elite", false)) and not enemy.is_boss
			group.interval = get_interval(enemy)
			group.start_delay = j * GROUP_DELAY
			wave.groups.append(group)
		wave.bonus_gold = 0 if i == waves.size() - 1 else WAVE_BONUS + i * WAVE_BONUS_STEP
		result.append(wave)
	return result


# --- Vérification et lancement -------------------------------------------------

## Ce qui empêche de jouer le niveau, en une phrase ("" s'il est jouable).
static func validate(data: Dictionary) -> String:
	for key in ["biome", "path", "rocks", "gold", "lives", "waves"]:
		if not data.has(key):
			return "Niveau incomplet."
	var path: Array = data.path
	if path.size() < 2:
		return "Tracez le chemin : il part du bord de la carte et va jusqu'à la base."
	if not is_on_edge(path[0]):
		return "Le chemin doit partir du bord de la carte."
	for i in range(1, path.size()):
		var a: Vector2i = path[i - 1]
		var b: Vector2i = path[i]
		if a == b or (a.x != b.x and a.y != b.y) or not is_in_grid(b):
			return "Le chemin est mal formé."
	var cells := expand_path(path)
	for cell in cells:
		if cells.count(cell) > 1:
			return "Le chemin ne doit pas se croiser."
	var waves: Array = data.waves
	if waves.is_empty():
		return "Ajoutez au moins une vague."
	for i in waves.size():
		var groups: Array = waves[i].get("groups", [])
		if groups.is_empty():
			return "La vague %d est vide." % (i + 1)
		for entry: Dictionary in groups:
			if not ResourceLoader.exists(entry.get("enemy", "")) or int(entry.get("count", 0)) <= 0:
				return "Un groupe de la vague %d n'a pas de monstre." % (i + 1)
	return ""


## Remplit la scène de niveau vide avec le niveau : à appeler avant qu'elle soit
## prête (Level._enter_tree), pour que la carte trouve son chemin en se préparant.
static func apply(level: Level, data: Dictionary) -> void:
	var biome := clampi(int(data.biome), 0, BIOME_COLORS.size() - 1)
	level.level_name = LEVEL_NAME
	level.starting_gold = clampi(int(data.gold), MIN_GOLD, MAX_GOLD)
	level.starting_lives = clampi(int(data.lives), MIN_LIVES, MAX_LIVES)
	var towers: Array[TowerData] = []
	for tower_path in BASE_TOWERS:
		towers.append(load(tower_path))
	level.tower_types = towers
	var map: GameMap = level.get_node("Map")
	var colors: Array = BIOME_COLORS[biome]
	map.background_color = colors[0]
	map.ground_color = colors[1]
	map.path_color = colors[2]
	map.rock_color = colors[3]
	var campaign: Campaign = load(CAMPAIGN_PATH)
	if biome < campaign.worlds.size():
		map.tileset = campaign.worlds[biome].tileset
	var cells := expand_path(data.path)
	var rocks: Array[Vector2i] = []
	for cell: Vector2i in data.rocks:
		if is_in_grid(cell) and not cells.has(cell):
			rocks.append(cell)
	map.blocked_cells = rocks
	var path := Path2D.new()
	path.name = "Path0"
	path.curve = Curve2D.new()
	for point in get_path_points(data.path):
		path.curve.add_point(point)
	map.add_child(path)
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = build_waves(data)
