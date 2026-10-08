class_name DailyChallenge
extends RefCounted
## Défi du jour : un niveau de la campagne avec des règles imposées (tours, monstres plus
## rapides, or serré…) et un score. Tout est tiré au sort à partir de la date : le défi
## change chaque jour, et il est le même toute la journée (et pour tout le monde). L'arbre
## des améliorations ne compte pas : chacun joue avec les mêmes tours et les mêmes prix.
## Le meilleur score de chaque jour est enregistré (Progress, section « daily »).

## Règles qui peuvent s'ajouter aux tours imposées.
enum { RAPIDES, CORIACES, NOMBREUX, OR_SERRE, VIES_COMPTEES, SANS_AMELIORATION, DEUX_TOURS }

const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")
const TOWERS_DIR := "res://resources/towers/"
## Méta du moteur : tours qui peuvent être imposées (voir get_tower_pool()).
const TOWER_POOL_META := &"daily_tower_pool"
## Nom et description de chaque règle, dans l'ordre de l'enum.
const RULE_NAMES: Array[String] = ["Monstres rapides", "Monstres coriaces", "Hordes", "Bourse serrée",
	"Vies comptées", "Sans amélioration", "Deux tours seulement"]
const RULE_TEXTS: Array[String] = [
	"Les monstres vont 30 % plus vite.",
	"Les monstres ont 35 % de vie (et de bouclier) en plus.",
	"40 % de monstres en plus dans chaque groupe.",
	"30 % d'or en moins au départ.",
	"5 vies seulement.",
	"Les tours ne s'améliorent pas.",
	"Deux tours imposées au lieu de quatre.",
]
## Règles tirées en plus des tours imposées (Deux tours seulement est tirée à part).
const EXTRA_RULES := 2
## Chance que le défi impose deux tours seulement.
const TWO_TOWERS_CHANCE := 0.35
## Nombre de tours imposées.
const TOWER_COUNT := 4
const FEW_TOWER_COUNT := 2
## Tours qui renforcent ou repoussent au plus dans un défi (voir get_tower_pool()).
const UTILITY_TOWERS_MAX := 1
const SPEED_MULTIPLIER := 1.3
const HEALTH_MULTIPLIER := 1.35
const COUNT_MULTIPLIER := 1.4
const GOLD_MULTIPLIER := 0.7
const COUNTED_LIVES := 5
## Score : points par or que rapporte un monstre détruit, par vague repoussée, et par vie
## gardée à la victoire.
const POINTS_PER_GOLD := 10
const POINTS_PER_WAVE := 100
const POINTS_PER_LIFE := 50
const MONTHS: Array[String] = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
	"septembre", "octobre", "novembre", "décembre"]
const WEEKDAYS: Array[String] = ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"]

## Jour du défi : « 2026-10-06 ».
var date_key := ""
## Niveau joué (chemin de sa scène).
var level_path := ""
## Tours imposées (chemins des TowerData).
var tower_paths: Array[String] = []
## Règles du défi, en plus des tours imposées.
var rules: Array[int] = []


## Défi d'aujourd'hui (date de l'ordinateur).
static func today() -> DailyChallenge:
	return for_date(today_key())


## Jour d'aujourd'hui (« 2026-10-06 »), sans tirer le défi (l'écran titre n'a besoin que
## de la date pour montrer le meilleur score).
static func today_key() -> String:
	var date := Time.get_date_dict_from_system()
	return date_key_of(date.year, date.month, date.day)


static func date_key_of(year: int, month: int, day: int) -> String:
	return "%04d-%02d-%02d" % [year, month, day]


## Défi d'un jour donné (« 2026-10-06 ») : le même à chaque fois.
static func for_date(key: String) -> DailyChallenge:
	var challenge := DailyChallenge.new()
	challenge.date_key = key
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("Défi du jour " + key)
	var levels := CAMPAIGN.levels
	challenge.level_path = levels[rng.randi_range(0, levels.size() - 1)]
	var extra: Array[int] = [RAPIDES, CORIACES, NOMBREUX, OR_SERRE, VIES_COMPTEES, SANS_AMELIORATION]
	for i in EXTRA_RULES:
		challenge.rules.append(extra.pop_at(rng.randi_range(0, extra.size() - 1)))
	if rng.randf() < TWO_TOWERS_CHANCE:
		challenge.rules.append(DEUX_TOURS)
	challenge.rules.sort()
	# Surtout des tours qui font des dégâts : au plus une qui renforce ou repousse, et
	# aucune avec deux tours seulement.
	var few := challenge.has_rule(DEUX_TOURS)
	var pools := get_tower_pool()
	var damage: Array[String] = pools[0]
	var utility: Array[String] = pools[1]
	var count := FEW_TOWER_COUNT if few else TOWER_COUNT
	var utility_count := 0 if few or utility.is_empty() else rng.randi_range(0, UTILITY_TOWERS_MAX)
	for i in mini(count - utility_count, damage.size()):
		challenge.tower_paths.append(damage.pop_at(rng.randi_range(0, damage.size() - 1)))
	for i in utility_count:
		challenge.tower_paths.append(utility.pop_at(rng.randi_range(0, utility.size() - 1)))
	# Les tours sont chargées une fois, pas à chaque comparaison du tri.
	var costs := {}
	for path in challenge.tower_paths:
		costs[path] = (load(path) as TowerData).cost
	challenge.tower_paths.sort_custom(func(a: String, b: String) -> bool: return costs[a] < costs[b])
	return challenge


## Tours qui peuvent être imposées : toutes celles du jeu, en deux listes : celles qui
## font des dégâts, et celles qui servent surtout à autre chose (Bobine, Électroaimant).
## Un défi impose au plus UTILITY_TOWERS_MAX de ces dernières, et aucune avec deux tours.
## Les deux listes sont gardées (méta du moteur, en chemins) : les établir charge toutes
## les tours du jeu.
static func get_tower_pool() -> Array:
	if Engine.has_meta(TOWER_POOL_META):
		var cached: Array = Engine.get_meta(TOWER_POOL_META)
		return [(cached[0] as Array[String]).duplicate(), (cached[1] as Array[String]).duplicate()]
	var damage: Array[String] = []
	var utility: Array[String] = []
	var files := Array(ResourceLoader.list_directory(TOWERS_DIR))
	files.sort()
	for file: String in files:
		var data := load(TOWERS_DIR + file) as TowerData if file.ends_with(".tres") else null
		if data:
			(utility if data.is_support() or data.knockback > 0.0 else damage).append(TOWERS_DIR + file)
	Engine.set_meta(TOWER_POOL_META, [damage.duplicate(), utility.duplicate()])
	return [damage, utility]


func has_rule(rule: int) -> bool:
	return rules.has(rule)


func get_towers() -> Array[TowerData]:
	var result: Array[TowerData] = []
	for path in tower_paths:
		result.append(load(path))
	return result


func get_speed_multiplier() -> float:
	return speed_multiplier_of(rules)


func get_health_multiplier() -> float:
	return health_multiplier_of(rules)


func get_count_multiplier() -> float:
	return count_multiplier_of(rules)


## Or de départ du niveau avec les règles du défi.
func get_starting_gold(level_gold: int) -> int:
	return starting_gold_of(rules, level_gold)


## Vies de départ du niveau avec les règles du défi.
func get_starting_lives(level_lives: int) -> int:
	return starting_lives_of(rules, level_lives)


func allows_upgrades() -> bool:
	return allows_upgrades_of(rules)


# Effets d'une liste de règles : ceux du défi, et ceux des mutateurs (Mutators), qui
# reprennent ses règles sur les niveaux déjà gagnés.

static func speed_multiplier_of(rule_list: Array[int]) -> float:
	return SPEED_MULTIPLIER if rule_list.has(RAPIDES) else 1.0


static func health_multiplier_of(rule_list: Array[int]) -> float:
	return HEALTH_MULTIPLIER if rule_list.has(CORIACES) else 1.0


static func count_multiplier_of(rule_list: Array[int]) -> float:
	return COUNT_MULTIPLIER if rule_list.has(NOMBREUX) else 1.0


static func starting_gold_of(rule_list: Array[int], level_gold: int) -> int:
	return roundi(level_gold * GOLD_MULTIPLIER) if rule_list.has(OR_SERRE) else level_gold


static func starting_lives_of(rule_list: Array[int], level_lives: int) -> int:
	return mini(level_lives, COUNTED_LIVES) if rule_list.has(VIES_COMPTEES) else level_lives


static func allows_upgrades_of(rule_list: Array[int]) -> bool:
	return not rule_list.has(SANS_AMELIORATION)


## « Monstres rapides : les monstres vont 30 % plus vite. » (traduit).
static func describe_rule(rule: int) -> String:
	var text := TranslationServer.translate(RULE_TEXTS[rule])
	return TranslationServer.translate("%s : %s") % [TranslationServer.translate(RULE_NAMES[rule]),
		text.left(1).to_lower() + text.substr(1)]


## « Niveau 2-4 · La Fonderie ».
func get_level_title() -> String:
	var world := CAMPAIGN.world_index_of(level_path)
	if world < 0:
		return level_path.get_file().get_basename()
	var number := CAMPAIGN.worlds[world].levels.find(level_path) + 1
	return tr("Niveau %d-%d  ·  %s") % [world + 1, number, tr(CAMPAIGN.worlds[world].display_name)]


## « mardi 6 octobre 2026 » (l'anglais change l'ordre : des noms plutôt que des %).
func get_date_text() -> String:
	var parts := date_key.split("-")
	if parts.size() != 3:
		return date_key
	var unix := Time.get_unix_time_from_datetime_string(date_key)
	var weekday: int = Time.get_date_dict_from_unix_time(unix).weekday
	return tr("{weekday} {day} {month} {year}").format({weekday = tr(WEEKDAYS[weekday]), day = parts[2].to_int(),
		month = tr(MONTHS[clampi(parts[1].to_int() - 1, 0, 11)]), year = parts[0]})


## Règles, une ligne chacune : tours imposées d'abord.
func describe_rules() -> Array[String]:
	var names := PackedStringArray()
	for data in get_towers():
		names.append(tr(data.display_name))
	var towers := ", ".join(names.slice(0, -1)) + tr(" et ") + names[-1] if names.size() > 1 else ", ".join(names)
	var result: Array[String] = [(tr("Deux tours seulement : %s.") if has_rule(DEUX_TOURS) else tr("Tours imposées : %s."))
		% towers]
	for rule in rules:
		if rule != DEUX_TOURS:
			result.append(describe_rule(rule))
	result.append(tr("Sans l'arbre des améliorations : tout le monde joue avec les mêmes tours."))
	return result


## Comment se calcule le score, en une phrase.
static func describe_score() -> String:
	return TranslationServer.translate("Score : %d points par pièce d'or que rapporte un monstre détruit, %d par vague repoussée, %d par vie gardée à la victoire.") \
		% [POINTS_PER_GOLD, POINTS_PER_WAVE, POINTS_PER_LIFE]
