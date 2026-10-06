class_name WaveData
extends Resource
## Une vague : plusieurs groupes d'ennemis qui apparaissent en parallèle.

@export var groups: Array[SpawnGroup] = []
## Or donné au joueur une fois tous les ennemis de la vague éliminés.
@export var bonus_gold := 25
## Multiplicateur de la vie et du bouclier des ennemis de la vague (le mode infini
## le fait monter de vague en vague).
@export var health_multiplier := 1.0


## Composition de la vague, un élément par sorte d'ennemi dans l'ordre d'apparition
## des groupes : { enemy (EnemyData), elite, count, health (multiplicateur de vie) }.
## Les élites sont comptés à part des ennemis normaux du même type.
func get_summary() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for group in groups:
		var health := health_multiplier * group.health_multiplier
		var found := false
		for entry in result:
			if entry.enemy == group.enemy and entry.elite == group.elite:
				entry.count += group.count
				entry.health = maxf(entry.health, health)
				found = true
				break
		if not found:
			result.append({ enemy = group.enemy, elite = group.elite, count = group.count, health = health })
	return result
