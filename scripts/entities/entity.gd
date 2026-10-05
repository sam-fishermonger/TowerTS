class_name Entity
extends Node2D
## Base de tout objet de jeu posé sur la carte : ennemis, tours et projectiles.
## Gère le cycle de vie commun : une entité est « vivante » jusqu'à son retrait.

## Émis une seule fois, quand l'entité quitte le jeu (juste avant d'être libérée).
signal despawned(entity: Entity)

var is_alive := true


## Retire l'entité du jeu : elle quitte ses groupes, arrête de se mettre à jour
## et sera libérée à la fin de l'image. Sans effet si elle est déjà retirée.
func despawn() -> void:
	if not is_alive:
		return
	is_alive = false
	for group in get_groups():
		# Les groupes internes de Godot commencent par « _ ».
		if not String(group).begins_with("_"):
			remove_from_group(group)
	set_process(false)
	set_physics_process(false)
	despawned.emit(self)
	queue_free()
