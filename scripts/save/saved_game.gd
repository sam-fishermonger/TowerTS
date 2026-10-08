class_name SavedGame
extends RefCounted
## Partie en cours enregistrée entre deux vagues, pour la reprendre plus tard (le
## téléphone ferme parfois le jeu) : une seule à la fois, dans son propre fichier, à côté
## de la progression. Le niveau l'écrit (Level.save_game()) chaque fois que la carte est
## vidée, quand le joueur construit entre deux vagues, et quand le jeu passe en arrière-plan
## ou se ferme ; il l'efface à la fin de la partie. L'écran titre propose de la reprendre.
## Le contenu est un dictionnaire de valeurs simples (voir Level.to_saved_game()).

## Version du contenu : une partie enregistrée par une autre version est ignorée.
const VERSION := 1


## Fichier de la partie : celui de la progression, suffixé (les tests ont donc le leur).
static func get_path() -> String:
	return Progress.get_save_path().get_basename() + "_partie.cfg"


## Partie enregistrée, ou un dictionnaire vide s'il n'y en a pas (ou si elle n'est plus
## jouable : autre version, niveau disparu).
static func load_data() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(get_path()) != OK:
		return {}
	var data: Variant = config.get_value("partie", "data", {})
	if not data is Dictionary or data.get("version", 0) != VERSION:
		return {}
	var path: String = data.get("path", "")
	if (data.get("custom", {}) as Dictionary).is_empty() and not ResourceLoader.exists(path):
		return {}
	return data


static func exists() -> bool:
	return not load_data().is_empty()


static func store(data: Dictionary) -> void:
	var config := ConfigFile.new()
	config.set_value("partie", "data", data)
	var error := config.save(get_path())
	if error != OK:
		push_warning("Partie non enregistrée (%s) : %s" % [get_path(), error_string(error)])


static func clear() -> void:
	if FileAccess.file_exists(get_path()):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(get_path()))


## Texte du bouton Reprendre : le niveau, le mode et la vague (traduits).
static func describe(data: Dictionary) -> String:
	var name := TranslationServer.translate(data.get("level_name", ""))
	var mode := ""
	if not (data.get("expedition", {}) as Dictionary).is_empty():
		mode = TranslationServer.translate("Expédition")
	elif not (data.get("challenge", "") as String).is_empty():
		mode = TranslationServer.translate("Défi du jour")
	elif data.get("endless", false):
		mode = TranslationServer.translate("Mode infini")
	elif not (data.get("custom", {}) as Dictionary).is_empty():
		mode = TranslationServer.translate("Éditeur de niveau")
	else:
		mode = TranslationServer.translate(Difficulty.NAMES[clampi(data.get("difficulty", Difficulty.MOYEN), 0,
			Difficulty.COUNT - 1)])
	var next_wave: int = data.get("wave", -1) + 2
	var wave_count: int = data.get("wave_count", -1)
	var wave := TranslationServer.translate("vague %d") % next_wave if wave_count < 0 \
		else TranslationServer.translate("vague %d / %d") % [next_wave, wave_count]
	return "%s  ·  %s  ·  %s" % [name, mode, wave]


## Rouvre la partie enregistrée (son niveau, dans son mode). Renvoie false s'il n'y en a pas.
static func resume(tree: SceneTree) -> bool:
	var data := load_data()
	if data.is_empty():
		return false
	Engine.set_meta(Level.RESUME_META, data)
	var custom: Dictionary = data.get("custom", {})
	var expedition: Dictionary = data.get("expedition", {})
	if not expedition.is_empty():
		Level.open_expedition(tree, Expedition.from_dict(expedition))
	elif not custom.is_empty():
		Level.open_custom(tree, custom)
	elif not (data.get("challenge", "") as String).is_empty():
		Engine.set_meta(Level.CHALLENGE_META, data.challenge)
		tree.change_scene_to_file(data.path)
	else:
		Level.open(tree, data.path, data.get("endless", false))
	return true
