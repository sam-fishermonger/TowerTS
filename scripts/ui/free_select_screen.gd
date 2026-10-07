extends "res://scripts/ui/conquest_select_screen.gd"
## Choix d'un niveau libre (depuis « Jouer », sur l'écran titre) : le même écran que la
## Conquête, avec les niveaux de FreeLevels.

const FREE_COLOR := Color(0.55, 0.9, 0.7)


func get_levels() -> Array[String]:
	return FreeLevels.LEVELS


func get_level_info(index: int) -> Dictionary:
	return FreeLevels.INFO[index]


func is_level_unlocked(index: int) -> bool:
	return FreeLevels.is_unlocked(index)


func get_screen_title() -> String:
	return "Niveaux libres"


func get_title_color() -> Color:
	return FREE_COLOR


func get_intro() -> String:
	return ("Pas de chemin tracé : les monstres partent de leurs terriers et vont au QG par le plus court. "
		+ "Vos tours sont des murs : bâtissez un labyrinthe sans jamais fermer le passage. Les volants passent au-dessus.")


func get_card_extra(index: int) -> Array:
	return [tr("Entrées des monstres : %d") % get_level_info(index).spawns, FREE_COLOR]
