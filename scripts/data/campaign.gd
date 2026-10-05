class_name Campaign
extends Resource
## Liste ordonnée des niveaux du jeu : l'écran titre en fait ses boutons, et chaque
## niveau y trouve le suivant. Ajouter un niveau = l'ajouter ici, et nulle part ailleurs.

@export_file("*.tscn") var levels: Array[String] = []


func size() -> int:
	return levels.size()


## Position du niveau dans la campagne, ou -1 s'il n'en fait pas partie.
func index_of(level_path: String) -> int:
	return levels.find(level_path)


## Niveau qui suit celui donné, ou "" pour le dernier (ou un niveau hors campagne).
func get_next(level_path: String) -> String:
	var index := index_of(level_path)
	return levels[index + 1] if index >= 0 and index + 1 < levels.size() else ""
