class_name Progress
extends RefCounted
## Progression du joueur, enregistrée sur le disque : étoiles obtenues sur chaque
## niveau (0 = pas encore gagné) et réglages. Un niveau est débloqué quand le
## précédent de la campagne a été gagné.

const DEFAULT_SAVE_PATH := "user://progress.cfg"
## Méta du moteur qui remplace le fichier de sauvegarde : les tests l'utilisent pour ne
## pas toucher à la vraie progression. (Pas de `static var` : Godot ne libère pas
## proprement les scripts qui en ont à la fermeture.)
const SAVE_PATH_META := &"progress_save_path"


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


## Meilleur nombre d'étoiles obtenu sur un niveau (0 s'il n'a jamais été gagné).
static func get_stars(level_path: String) -> int:
	return _load().get_value("stars", level_path, 0)


## Enregistre une victoire. Seul le meilleur résultat est gardé ; renvoie true s'il est battu.
static func record_victory(level_path: String, stars: int) -> bool:
	var config := _load()
	if stars <= config.get_value("stars", level_path, 0):
		return false
	config.set_value("stars", level_path, stars)
	_save(config)
	return true


static func is_unlocked(campaign: Campaign, index: int) -> bool:
	return index == 0 or (index > 0 and index < campaign.size() and get_stars(campaign.levels[index - 1]) > 0)


## Premier niveau débloqué pas encore gagné (ou le dernier si tout est gagné).
static func get_next_to_play(campaign: Campaign) -> String:
	for i in campaign.size():
		if is_unlocked(campaign, i) and get_stars(campaign.levels[i]) == 0:
			return campaign.levels[i]
	return campaign.levels[campaign.size() - 1]


static func get_setting(key: String, default: Variant) -> Variant:
	return _load().get_value("settings", key, default)


static func set_setting(key: String, value: Variant) -> void:
	var config := _load()
	config.set_value("settings", key, value)
	_save(config)


## Efface les étoiles (les réglages sont gardés).
static func reset_campaign() -> void:
	var config := _load()
	if config.has_section("stars"):
		config.erase_section("stars")
	_save(config)


## Le fichier est relu à chaque fois : il est minuscule et lu rarement (écran titre, fin de partie).
static func _load() -> ConfigFile:
	var config := ConfigFile.new()
	# Pas de fichier au premier lancement : on part d'une progression vide.
	config.load(get_save_path())
	return config


static func _save(config: ConfigFile) -> void:
	var error := config.save(get_save_path())
	if error != OK:
		push_warning("Progression non enregistrée (%s) : %s" % [get_save_path(), error_string(error)])
