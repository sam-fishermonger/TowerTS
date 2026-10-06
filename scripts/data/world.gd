class_name World
extends Resource
## Un monde de la campagne : un biome, ses monstres et ses niveaux, dans l'ordre.

@export var display_name := "Monde"
## Le biome en quelques mots, affiché sur la carte du monde.
@export_multiline var description := ""
## Couleur du monde dans les menus.
@export var color := Color.WHITE
## Monstres du biome, montrés sur la carte du monde.
@export var enemies: Array[EnemyData] = []
@export_file("*.tscn") var levels: Array[String] = []
