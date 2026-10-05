class_name HealthComponent
extends Node
## Points de vie et armure d'une entité.

signal health_changed(health: float, max_health: float)
## Émis une seule fois, quand les points de vie tombent à 0.
signal depleted

@export var max_health := 50.0
## Réduction fixe appliquée à chaque coup reçu.
@export var armor := 0.0

var health := 0.0


func _ready() -> void:
	health = max_health


func setup(new_max_health: float, new_armor: float) -> void:
	max_health = new_max_health
	armor = new_armor
	health = max_health
	health_changed.emit(health, max_health)


func is_depleted() -> bool:
	return health <= 0.0


## Applique un coup et renvoie les dégâts réellement subis. L'armure ne peut
## pas réduire un coup en dessous de 1 point de dégât.
func take_damage(amount: float) -> float:
	if is_depleted() or amount <= 0.0:
		return 0.0
	var dealt := minf(maxf(amount - armor, 1.0), health)
	health -= dealt
	health_changed.emit(health, max_health)
	if is_depleted():
		depleted.emit()
	return dealt
