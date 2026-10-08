class_name Progress
extends RefCounted
## Progression du joueur, enregistrée sur le disque : étoiles obtenues sur chaque
## niveau dans chaque difficulté (0 = pas encore gagné), records du mode infini,
## améliorations permanentes (voir Perks) et réglages. Un niveau est débloqué quand le
## précédent de la campagne a été gagné, dans n'importe quelle difficulté : le premier
## niveau d'un monde s'ouvre en gagnant le dernier du monde précédent.

const DEFAULT_SAVE_PATH := "user://progress.cfg"
## Méta du moteur qui remplace le fichier de sauvegarde : les tests l'utilisent pour ne
## pas toucher à la vraie progression. (Pas de `static var` : Godot ne libère pas
## proprement les scripts qui en ont à la fermeture.)
const SAVE_PATH_META := &"progress_save_path"
## Méta du moteur qui garde le contenu du fichier en mémoire, en simples dictionnaires :
## { "path": fichier, "data": { section: { clé: valeur } } } (voir _read()).
const CACHE_META := &"progress_cache"
## Étoiles qu'un niveau peut rapporter : 3 par difficulté.
const MAX_LEVEL_STARS := 3 * Difficulty.COUNT
## Étoiles à obtenir sur un niveau (dans une même difficulté) pour ouvrir son mode infini.
const ENDLESS_UNLOCK_STARS := 3
## Mode infini : une étoile infinie toutes les ENDLESS_STAR_STEP vagues repoussées
## au-delà de celles du niveau, jusqu'à ENDLESS_MAX_STARS par niveau.
const ENDLESS_STAR_STEP := 5
const ENDLESS_MAX_STARS := 5
## Couleur des étoiles infinies dans les menus et en jeu.
const ENDLESS_STAR_COLOR := Color(0.45, 0.85, 1.0)


static func get_save_path() -> String:
	return Engine.get_meta(SAVE_PATH_META, DEFAULT_SAVE_PATH)


## Étoiles gagnées pour une partie gagnée avec ces vies : 3 sans perte, 2 avec
## au moins la moitié des vies, 1 sinon.
static func stars_for(lives: int, starting_lives: int) -> int:
	if lives >= starting_lives:
		return 3
	return 2 if lives * 2 >= starting_lives else 1


## Étoiles pleines et vides : « ★★☆ ».
static func star_text(stars: int, total := 3) -> String:
	return "★".repeat(stars) + "☆".repeat(maxi(total - stars, 0))


## Section du fichier qui garde les étoiles d'une difficulté. Moyen garde « stars »,
## celle d'avant les difficultés : les étoiles déjà gagnées comptent en Moyen.
static func stars_section(difficulty: int) -> String:
	return "stars" if difficulty == Difficulty.MOYEN else "stars_" + Difficulty.NAMES[difficulty].to_lower()


## Meilleur nombre d'étoiles obtenu sur un niveau dans une difficulté, ou sans
## difficulté (-1), dans la meilleure (0 s'il n'a jamais été gagné).
static func get_stars(level_path: String, difficulty := -1) -> int:
	if difficulty >= 0:
		return _read(stars_section(difficulty), level_path, 0)
	var best := 0
	for d in Difficulty.COUNT:
		best = maxi(best, _read(stars_section(d), level_path, 0))
	return best


## Étoiles obtenues sur un niveau, toutes difficultés confondues (MAX_LEVEL_STARS au plus).
static func get_total_stars(level_path: String) -> int:
	var total := 0
	for d in Difficulty.COUNT:
		total += _read(stars_section(d), level_path, 0)
	return total


## Enregistre une victoire dans une difficulté. Seul le meilleur résultat de chaque
## difficulté est gardé ; renvoie true s'il est battu.
static func record_victory(level_path: String, stars: int, difficulty := Difficulty.MOYEN) -> bool:
	var config := _load()
	var section := stars_section(difficulty)
	if stars <= config.get_value(section, level_path, 0):
		return false
	config.set_value(section, level_path, stars)
	_save(config)
	return true


## Étoiles infinies méritées en repoussant `extra_waves` vagues de plus que celles du niveau.
static func endless_stars_for(extra_waves: int) -> int:
	return clampi(floori(extra_waves / float(ENDLESS_STAR_STEP)), 0, ENDLESS_MAX_STARS)


## Le mode infini d'un niveau s'ouvre quand il a été gagné avec 3 étoiles (dans
## n'importe quelle difficulté).
static func is_endless_unlocked(level_path: String) -> bool:
	return get_stars(level_path) >= ENDLESS_UNLOCK_STARS


## Record de vagues repoussées en mode infini sur un niveau (0 = jamais joué).
static func get_endless_waves(level_path: String) -> int:
	return _read("endless_waves", level_path, 0)


## Étoiles infinies obtenues sur un niveau (meilleur résultat).
static func get_endless_stars(level_path: String) -> int:
	return _read("endless_stars", level_path, 0)


## Enregistre une partie du mode infini (appelé à chaque vague repoussée). Seuls les
## meilleurs résultats sont gardés ; renvoie true si le record de vagues est battu.
static func record_endless(level_path: String, waves: int, stars: int) -> bool:
	var config := _load()
	var new_record: bool = waves > config.get_value("endless_waves", level_path, 0)
	var more_stars: bool = stars > config.get_value("endless_stars", level_path, 0)
	if not new_record and not more_stars:
		return false
	if new_record:
		config.set_value("endless_waves", level_path, waves)
	if more_stars:
		config.set_value("endless_stars", level_path, stars)
	_save(config)
	return new_record


## Étoiles infinies obtenues sur les niveaux d'un monde.
static func get_world_endless_stars(world: World) -> int:
	var total := 0
	for path in world.levels:
		total += get_endless_stars(path)
	return total


## Défi du jour : meilleur score d'un jour (« 2026-10-06 »), -1 s'il n'a pas été joué.
static func get_daily_score(date_key: String) -> int:
	return _read("daily", date_key, -1)


## Enregistre un score du défi du jour. Seul le meilleur est gardé ; renvoie true s'il
## est battu (ou si c'est le premier).
static func record_daily(date_key: String, score: int) -> bool:
	var config := _load()
	if score <= config.get_value("daily", date_key, -1):
		return false
	config.set_value("daily", date_key, score)
	_save(config)
	return true


## Défi du jour : meilleurs scores de chaque jour joué, { date: score }.
static func get_daily_scores() -> Dictionary:
	return (_get_data().get("daily", {}) as Dictionary).duplicate(true)


## Code Konami : tous les niveaux gagnés avec 3 étoiles dans toutes les difficultés (mondes et modes infinis
## ouverts), toutes les étoiles infinies, et toutes les améliorations données.
## Les meilleurs résultats déjà obtenus sont gardés.
static func unlock_all(levels: Array[String], perk_ids: PackedStringArray) -> void:
	var config := _load()
	for path in levels:
		for d in Difficulty.COUNT:
			config.set_value(stars_section(d), path, 3)
		config.set_value("endless_stars", path, ENDLESS_MAX_STARS)
	config.set_value("perks", "owned", perk_ids)
	_save(config)


static func is_unlocked(campaign: Campaign, index: int) -> bool:
	return index == 0 or (index > 0 and index < campaign.size() and get_stars(campaign.levels[index - 1]) > 0)


## Un monde est débloqué quand son premier niveau l'est.
static func is_world_unlocked(campaign: Campaign, world_index: int) -> bool:
	return is_unlocked(campaign, campaign.first_level_index(world_index))


## Étoiles obtenues sur les niveaux d'un monde, toutes difficultés confondues.
static func get_world_stars(world: World) -> int:
	var total := 0
	for path in world.levels:
		total += get_total_stars(path)
	return total


## Premier niveau débloqué pas encore gagné (ou le dernier si tout est gagné).
static func get_next_to_play(campaign: Campaign) -> String:
	var levels := campaign.levels
	for i in levels.size():
		if is_unlocked(campaign, i) and get_stars(levels[i]) == 0:
			return levels[i]
	return levels[levels.size() - 1]


static func get_setting(key: String, default: Variant) -> Variant:
	return get_value("settings", key, default)


static func set_setting(key: String, value: Variant) -> void:
	set_value("settings", key, value)


static func get_value(section: String, key: String, default: Variant) -> Variant:
	return _read(section, key, default)


static func set_value(section: String, key: String, value: Variant) -> void:
	var config := _load()
	config.set_value(section, key, value)
	_save(config)


## Efface les étoiles, les records du mode infini, du défi du jour et des expéditions, et les
## améliorations achetées avec (les réglages sont gardés).
static func reset_campaign() -> void:
	var config := _load()
	var sections := ["endless_waves", "endless_stars", "perks", "daily", "expedition"]
	for d in Difficulty.COUNT:
		sections.append(stars_section(d))
	for section in sections:
		if config.has_section(section):
			config.erase_section(section)
	_save(config)


## Valeur lue dans la copie en mémoire du fichier. Le fichier n'est lu qu'une fois : les
## menus demandent les étoiles de chaque niveau des centaines de fois (l'arbre des
## améliorations, à chaque case), et relire le fichier à chaque fois ralentissait
## nettement les changements d'écran sur téléphone et sur le web.
## Les tableaux et dictionnaires sont rendus en copie : les modifier ne touche pas la copie
## en mémoire.
static func _read(section: String, key: String, default: Variant) -> Variant:
	var value: Variant = (_get_data().get(section, {}) as Dictionary).get(key, default)
	if value is Array or value is Dictionary:
		return value.duplicate(true)
	if typeof(value) >= TYPE_PACKED_BYTE_ARRAY:
		return value.duplicate()
	return value


## Contenu du fichier en mémoire, { section: { clé: valeur } }, lu au premier besoin (ou
## quand le fichier de sauvegarde change, voir SAVE_PATH_META).
static func _get_data() -> Dictionary:
	var path := get_save_path()
	var cache: Dictionary = Engine.get_meta(CACHE_META, {})
	if cache.get("path") != path:
		cache = _cache_of(_load())
		Engine.set_meta(CACHE_META, cache)
	return cache.data


static func _cache_of(config: ConfigFile) -> Dictionary:
	var data := {}
	for section in config.get_sections():
		var values := {}
		for key in config.get_section_keys(section):
			values[key] = config.get_value(section, key)
		data[section] = values
	return {"path": get_save_path(), "data": data}


## Oublie la copie en mémoire : le fichier sera relu (il a été effacé ou changé hors du jeu).
static func clear_cache() -> void:
	Engine.remove_meta(CACHE_META)
	Perks.clear_cache()


## Lecture du fichier, pour l'écrire ensuite (les lectures passent par _read()).
static func _load() -> ConfigFile:
	var config := ConfigFile.new()
	# Pas de fichier au premier lancement : on part d'une progression vide.
	config.load(get_save_path())
	return config


static func _save(config: ConfigFile) -> void:
	Perks.clear_cache()
	Engine.set_meta(CACHE_META, _cache_of(config))
	var error := config.save(get_save_path())
	if error != OK:
		push_warning("Progression non enregistrée (%s) : %s" % [get_save_path(), error_string(error)])
