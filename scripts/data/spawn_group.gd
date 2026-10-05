class_name SpawnGroup
extends Resource
## Groupe d'ennemis identiques apparaissant à intervalle régulier dans une vague.

@export var enemy: EnemyData
@export var count := 5
## Secondes entre deux apparitions.
@export var interval := 1.0
## Secondes à attendre après le début de la vague avant la première apparition.
@export var start_delay := 0.0
## Chemin emprunté, parmi ceux de la carte (0 = le premier).
@export var path_index := 0
