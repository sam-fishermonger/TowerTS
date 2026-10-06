class_name WaveData
extends Resource
## Une vague : plusieurs groupes d'ennemis qui apparaissent en parallèle.

@export var groups: Array[SpawnGroup] = []
## Or donné au joueur une fois tous les ennemis de la vague éliminés.
@export var bonus_gold := 25
## Multiplicateur de la vie et du bouclier des ennemis de la vague (le mode infini
## le fait monter de vague en vague).
@export var health_multiplier := 1.0
