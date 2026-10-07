class_name CustomLevel
extends RefCounted
## Niveau fait dans l'éditeur : un chemin tracé case par case, des rochers, des vagues
## et l'or et les vies de départ. Il est gardé sous forme de dictionnaire (les niveaux
## du joueur sont enregistrés avec la progression, voir load_all()) et joué dans la
## scène de niveau vide, que apply() remplit avant qu'elle soit prête. Un niveau se
## partage sous forme de code texte à copier-coller (encode() et decode()).
##
## Le dictionnaire :
## - name : nom du niveau ;
## - biome : indice du monde dont la carte prend les tuiles et les couleurs ;
## - path : cases du chemin (Vector2i), chacune alignée avec la précédente : le chemin
##   va en ligne droite de l'une à l'autre. La première est au bord de la carte ;
## - rocks : cases bloquées (Vector2i) ;
## - gold, lives : or et vies de départ ;
## - waves : une vague par élément, { groups = [{ enemy (chemin de l'EnemyData),
##   count, elite }] } ;
## - free (facultatif) : carte libre (GameMap.free_layout), sans chemin tracé : les
##   monstres partent des terriers `spawns` (cases du bord, 1 à MAX_SPAWNS) et vont au
##   QG `base` (Vector2i) en contournant rochers et tours. `path` est alors ignoré.

const CAMPAIGN_PATH := "res://resources/campaign.tres"
## Réglages (Progress) : la liste des niveaux du joueur et celui qui est ouvert.
const LEVELS_SETTING := "editor_levels"
const CURRENT_SETTING := "editor_current"
## Ancien réglage, qui ne gardait qu'un niveau : il devient le premier de la liste.
const LEGACY_SETTING := "editor_level"
const LEVEL_NAME := "Niveau perso"
const MAX_LEVELS := 30
const MAX_NAME_LENGTH := 28

## Code de partage : ce préfixe (avec la version du format), puis le niveau en JSON
## compressé et écrit en base64 (version URL, sans « + » ni « / »).
const CODE_PREFIX := "TTS1-"
## Taille maximale d'un code et de son contenu décompressé, pour ne pas se laisser
## noyer par un code trafiqué.
const MAX_CODE_LENGTH := 6000
const MAX_JSON_SIZE := 30000
const ENEMIES_DIR := "res://resources/enemies/"

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
## Carte libre : terriers au plus.
const MAX_SPAWNS := 3

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
		name = default_name(),
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


## Niveaux du joueur, dans l'ordre de la liste (au moins un : celui par défaut s'il
## n'y en a pas encore). Le niveau de l'ancien réglage, s'il y en a un, est repris.
static func load_all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var saved: Variant = Progress.get_setting(LEVELS_SETTING, false)
	if not saved is Array:
		saved = [Progress.get_setting(LEGACY_SETTING, {})]
	if saved is Array:
		for entry: Variant in saved:
			if entry is Dictionary and validate_shape(entry).is_empty():
				var level: Dictionary = entry.duplicate(true)
				level.name = clean_name(level.get("name", ""))
				result.append(level)
	if result.is_empty():
		result.append(create_default())
	return result


## Rang du niveau ouvert dans la liste.
static func load_current_index(count: int) -> int:
	return clampi(int(Progress.get_setting(CURRENT_SETTING, 0)), 0, maxi(count - 1, 0))


static func save_all(levels: Array[Dictionary], current: int) -> void:
	Progress.set_setting(LEVELS_SETTING, levels)
	Progress.set_setting(CURRENT_SETTING, current)


## Nom propre : sans espaces autour, raccourci, et celui par défaut s'il est vide.
static func clean_name(text: Variant) -> String:
	var result := str(text).strip_edges().left(MAX_NAME_LENGTH)
	return result if not result.is_empty() else default_name()


## Nom par défaut d'un niveau, dans la langue du jeu (il est enregistré tel quel).
static func default_name() -> String:
	return String(TranslationServer.translate(LEVEL_NAME))


## Nom libre dans la liste : « Nom », sinon « Nom (2) », « Nom (3) »...
static func unique_name(text: String, levels: Array[Dictionary], ignore := -1) -> String:
	var taken: Array[String] = []
	for i in levels.size():
		if i != ignore:
			taken.append(str(levels[i].get("name", "")))
	var base := clean_name(text)
	var result := base
	var number := 2
	while taken.has(result):
		var suffix := " (%d)" % number
		result = base.left(MAX_NAME_LENGTH - suffix.length()) + suffix
		number += 1
	return result


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
	var routes: int = data.spawns.size() if is_free(data) else 1
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
			# Carte libre : les groupes se partagent les terriers, à tour de rôle.
			group.path_index = (i + j) % maxi(routes, 1)
			wave.groups.append(group)
		wave.bonus_gold = 0 if i == waves.size() - 1 else WAVE_BONUS + i * WAVE_BONUS_STEP
		result.append(wave)
	return result


# --- Vérification et lancement -------------------------------------------------

## Le dictionnaire a-t-il tout ce qu'il faut, avec les bons types ("" si oui) ? Un
## niveau bien formé peut encore être injouable (voir validate()) : il s'édite.
static func validate_shape(data: Dictionary) -> String:
	for key in ["biome", "path", "rocks", "gold", "lives", "waves"]:
		if not data.has(key):
			return "Niveau incomplet."
	if not (data.path is Array and data.rocks is Array and data.waves is Array):
		return "Niveau incomplet."
	if int(data.biome) < 0 or int(data.biome) >= BIOME_COLORS.size():
		return "Niveau incomplet."
	for cell: Variant in data.path + data.rocks:
		if not cell is Vector2i:
			return "Niveau incomplet."
	for wave: Variant in data.waves:
		if not wave is Dictionary or not wave.get("groups") is Array:
			return "Niveau incomplet."
		for group: Variant in wave.groups:
			if not group is Dictionary or not group.get("enemy") is String:
				return "Niveau incomplet."
	if data.get("free", false):
		if not data.get("spawns") is Array or not data.get("base") is Vector2i:
			return "Niveau incomplet."
		for cell: Variant in data.spawns:
			if not cell is Vector2i:
				return "Niveau incomplet."
	return ""


## Carte libre : la carte n'a pas de chemin tracé.
static func is_free(data: Dictionary) -> bool:
	return bool(data.get("free", false))


## Carte libre : niveau sans terrier ni QG encore (celui qu'on obtient en passant en carte libre).
static func make_free(data: Dictionary) -> void:
	data.free = true
	if not data.get("spawns") is Array:
		data.spawns = []
	if not data.get("base") is Vector2i:
		data.base = NO_BASE


## Carte libre sans QG posé.
const NO_BASE := Vector2i(-1, -1)


## Carte libre : les cases d'où l'on atteint le QG en marchant (entre les rochers).
static func reachable_from_base(data: Dictionary) -> Dictionary:
	var reached := {}
	var base: Vector2i = data.base
	if not is_in_grid(base) or data.rocks.has(base):
		return reached
	reached[base] = true
	var open: Array[Vector2i] = [base]
	while not open.is_empty():
		var cell: Vector2i = open.pop_back()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if is_in_grid(next) and not reached.has(next) and not data.rocks.has(next):
				reached[next] = true
				open.append(next)
	return reached


## Ce qui empêche de jouer le niveau, en une phrase ("" s'il est jouable).
static func validate(data: Dictionary) -> String:
	var shape := validate_shape(data)
	if not shape.is_empty():
		return shape
	if is_free(data):
		return _validate_free(data)
	return _validate_path(data)


static func _validate_free(data: Dictionary) -> String:
	var spawns: Array = data.spawns
	if spawns.is_empty():
		return "Posez au moins un terrier, sur une case du bord de la carte."
	if spawns.size() > MAX_SPAWNS:
		return String(TranslationServer.translate("Pas plus de %d terriers.")) % MAX_SPAWNS
	for cell: Vector2i in spawns:
		if not is_on_edge(cell) or spawns.count(cell) > 1:
			return "Les terriers sont sur le bord de la carte, un par case."
	if not is_in_grid(data.base):
		return "Posez le QG des monstres à atteindre."
	if spawns.has(data.base):
		return "Le QG ne peut pas être sur un terrier."
	var reached := reachable_from_base(data)
	for cell: Vector2i in spawns:
		if not reached.has(cell):
			return "Un terrier n'a pas de passage jusqu'au QG : enlevez des rochers."
	return _validate_waves(data)


static func _validate_path(data: Dictionary) -> String:
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
	return _validate_waves(data)


static func _validate_waves(data: Dictionary) -> String:
	var waves: Array = data.waves
	if waves.is_empty():
		return "Ajoutez au moins une vague."
	for i in waves.size():
		var groups: Array = waves[i].get("groups", [])
		if groups.is_empty():
			return String(TranslationServer.translate("La vague %d est vide.")) % (i + 1)
		for entry: Dictionary in groups:
			if not ResourceLoader.exists(entry.get("enemy", "")) or int(entry.get("count", 0)) <= 0:
				return String(TranslationServer.translate("Un groupe de la vague %d n'a pas de monstre.")) % (i + 1)
	return ""


## Remplit la scène de niveau vide avec le niveau : à appeler avant qu'elle soit
## prête (Level._enter_tree), pour que la carte trouve son chemin en se préparant.
static func apply(level: Level, data: Dictionary) -> void:
	var biome := clampi(int(data.biome), 0, BIOME_COLORS.size() - 1)
	level.level_name = clean_name(data.get("name", ""))
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
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.waves = build_waves(data)
	if is_free(data):
		var spawns: Array[Vector2i] = []
		spawns.assign(data.spawns)
		map.free_layout = true
		map.spawn_cells = spawns
		map.base_cell = data.base
		map.blocked_cells = _rocks_without(data.rocks, spawns + [data.base])
		return
	map.blocked_cells = _rocks_without(data.rocks, expand_path(data.path))
	var path := Path2D.new()
	path.name = "Path0"
	path.curve = Curve2D.new()
	for point in get_path_points(data.path):
		path.curve.add_point(point)
	map.add_child(path)


static func _rocks_without(rocks: Array, kept: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in rocks:
		if is_in_grid(cell) and not kept.has(cell):
			result.append(cell)
	return result


# --- Partage ---------------------------------------------------------------------

## Code de partage du niveau : une ligne de texte à copier-coller.
static func encode(data: Dictionary) -> String:
	var path := []
	for cell: Vector2i in data.path:
		path.append_array([cell.x, cell.y])
	var rocks := []
	for cell: Vector2i in data.rocks:
		rocks.append_array([cell.x, cell.y])
	var waves := []
	for wave: Dictionary in data.waves:
		var groups := []
		for group: Dictionary in wave.groups:
			groups.append([_enemy_id(group.enemy), int(group.count), 1 if group.get("elite", false) else 0])
		waves.append(groups)
	var compact := {
		n = clean_name(data.get("name", "")), b = int(data.biome), g = int(data.gold), l = int(data.lives),
		p = path, r = rocks, w = waves,
	}
	if is_free(data):
		var spawns := []
		for cell: Vector2i in data.spawns:
			spawns.append_array([cell.x, cell.y])
		compact.f = 1
		compact.s = spawns
		compact.h = [data.base.x, data.base.y]
	var bytes := JSON.stringify(compact).to_utf8_buffer()
	var packed := bytes.compress(FileAccess.COMPRESSION_DEFLATE)
	return CODE_PREFIX + Marshalls.raw_to_base64(packed).replace("+", "-").replace("/", "_").trim_suffix("=").trim_suffix("=")


## Niveau lu dans un code de partage, ou {} si le code n'en est pas un. Le code vient
## d'ailleurs : tout est vérifié et borné, et les monstres ne peuvent être que ceux
## proposés par l'éditeur.
static func decode(code: String) -> Dictionary:
	for blank in [" ", "\n", "\r", "\t"]:
		code = code.replace(blank, "")
	if not code.begins_with(CODE_PREFIX) or code.length() > MAX_CODE_LENGTH:
		return {}
	var text := code.substr(CODE_PREFIX.length()).replace("-", "+").replace("_", "/")
	while text.length() % 4 != 0:
		text += "="
	var packed := Marshalls.base64_to_raw(text)
	if packed.is_empty():
		return {}
	var bytes := packed.decompress_dynamic(MAX_JSON_SIZE, FileAccess.COMPRESSION_DEFLATE)
	var json := JSON.new()
	if json.parse(bytes.get_string_from_utf8()) != OK or not json.data is Dictionary:
		return {}
	var compact: Dictionary = json.data
	var enemies := {}
	for enemy in get_enemy_choices():
		enemies[_enemy_id(enemy.resource_path)] = enemy
	var data := {
		name = clean_name(compact.get("n", "")),
		biome = clampi(_to_int(compact.get("b")), 0, BIOME_COLORS.size() - 1),
		gold = clampi(_to_int(compact.get("g")), MIN_GOLD, MAX_GOLD),
		lives = clampi(_to_int(compact.get("l")), MIN_LIVES, MAX_LIVES),
		path = _read_cells(compact.get("p"), COLUMNS * ROWS),
		rocks = _read_cells(compact.get("r"), COLUMNS * ROWS),
		waves = [],
	}
	var waves: Variant = compact.get("w")
	if not waves is Array or waves.size() > MAX_WAVES:
		return {}
	for groups: Variant in waves:
		if not groups is Array or groups.is_empty() or groups.size() > MAX_GROUPS:
			return {}
		var wave := {groups = []}
		for group: Variant in groups:
			if not group is Array or group.size() != 3 or not enemies.has(group[0]):
				return {}
			var enemy: EnemyData = enemies[group[0]]
			wave.groups.append({enemy = enemy.resource_path, count = clampi(_to_int(group[1]), 1, MAX_COUNT),
				elite = _to_int(group[2]) == 1})
		data.waves.append(wave)
	if _to_int(compact.get("f")) == 1:
		var spawns: Variant = _read_cells(compact.get("s"), MAX_SPAWNS)
		var base: Variant = _read_cells(compact.get("h"), 1)
		if spawns == null or base == null or base.size() != 1:
			return {}
		data.free = true
		data.spawns = spawns
		data.base = base[0]
	if data.path == null or data.rocks == null:
		return {}
	if not validate(data).is_empty():
		return {}
	return data


## Nom court d'un monstre dans un code : son dossier et son fichier (« mecha/drone »).
static func _enemy_id(path: String) -> String:
	return path.trim_prefix(ENEMIES_DIR).trim_suffix(".tres")


static func _to_int(value: Variant) -> int:
	return int(value) if value is float or value is int else 0


## Cases lues dans une liste de nombres (x, y, x, y...), ou null si elle est mal formée.
static func _read_cells(values: Variant, limit: int) -> Variant:
	if not values is Array or values.size() % 2 != 0 or values.size() > limit * 2:
		return null
	var result := []
	for i in range(0, values.size(), 2):
		var cell := Vector2i(_to_int(values[i]), _to_int(values[i + 1]))
		if not is_in_grid(cell):
			return null
		result.append(cell)
	return result
