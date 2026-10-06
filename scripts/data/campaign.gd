class_name Campaign
extends Resource
## Les mondes du jeu, dans l'ordre, chacun avec ses niveaux. L'écran de sélection en
## fait ses cartes et ses boutons, et chaque niveau y trouve le suivant : on finit
## un monde pour ouvrir le suivant. Ajouter un niveau = l'ajouter à son monde ici.

@export var worlds: Array[World] = []

## Tous les niveaux, monde après monde.
var levels: Array[String]:
	get:
		var result: Array[String] = []
		for world in worlds:
			result.append_array(world.levels)
		return result


func size() -> int:
	return levels.size()


## Position du niveau dans la campagne, ou -1 s'il n'en fait pas partie.
func index_of(level_path: String) -> int:
	return levels.find(level_path)


## Niveau qui suit celui donné (le premier du monde suivant pour le dernier d'un
## monde), ou "" pour le tout dernier niveau (ou un niveau hors campagne).
func get_next(level_path: String) -> String:
	var all := levels
	var index := all.find(level_path)
	return all[index + 1] if index >= 0 and index + 1 < all.size() else ""


## Index du monde qui contient le niveau, ou -1.
func world_index_of(level_path: String) -> int:
	for i in worlds.size():
		if worlds[i].levels.has(level_path):
			return i
	return -1


## Index du premier niveau d'un monde dans la campagne.
func first_level_index(world_index: int) -> int:
	var index := 0
	for i in world_index:
		index += worlds[i].levels.size()
	return index
