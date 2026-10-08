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
## Boss du biome, au bout de certains niveaux (lexique et sélection des mondes).
@export var bosses: Array[EnemyData] = []
## Pillards du biome, qui ne viennent que dans les niveaux du mode Conquête (lexique).
@export var raiders: Array[EnemyData] = []
## Voleurs du biome, qui ne viennent que dans les niveaux du mode Conquête (lexique).
@export var thieves: Array[EnemyData] = []
@export_file("*.tscn") var levels: Array[String] = []
## Tuiles du biome (sol, détails, obstacles), posées sur les cartes de ses niveaux
## (voir GameMap.tileset).
@export var tileset: TileSet
