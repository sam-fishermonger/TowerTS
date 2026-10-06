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
## Les ennemis du groupe sont des élites (voir EnemyData.make_elite()).
@export var elite := false
## Multiplicateur de la vie et du bouclier des ennemis du groupe, en plus de celui de
## la vague (un boss plus coriace en fin de monde, par exemple).
@export var health_multiplier := 1.0


## Ennemi qui apparaît : celui du groupe, ou sa version élite.
func get_enemy() -> EnemyData:
	return enemy.make_elite() if elite else enemy
