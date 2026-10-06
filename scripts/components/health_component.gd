class_name HealthComponent
extends Node
## Points de vie, armure et bouclier d'énergie d'une entité.

signal health_changed(health: float, max_health: float)
signal shield_changed(shield: float, max_shield: float)
## Émis une seule fois, quand les points de vie tombent à 0.
signal depleted

@export var max_health := 50.0
## Réduction fixe appliquée à chaque coup reçu.
@export var armor := 0.0
## Bouclier d'énergie : il encaisse les coups avant les points de vie, sans armure,
## et se recharge quand l'entité n'est plus touchée.
@export var max_shield := 0.0
## Points de bouclier rechargés par seconde.
@export var shield_regen := 0.0
## Secondes sans être touché avant que le bouclier ne se recharge.
@export var shield_regen_delay := 2.0

var health := 0.0
var shield := 0.0

var _since_hit := 0.0


func _ready() -> void:
	health = max_health
	shield = max_shield


func setup(new_max_health: float, new_armor: float, new_max_shield := 0.0, new_shield_regen := 0.0) -> void:
	max_health = new_max_health
	armor = new_armor
	health = max_health
	max_shield = new_max_shield
	shield_regen = new_shield_regen
	shield = max_shield
	health_changed.emit(health, max_health)
	shield_changed.emit(shield, max_shield)


func _process(delta: float) -> void:
	_since_hit += delta
	if shield < max_shield and shield_regen > 0.0 and _since_hit >= shield_regen_delay and not is_depleted():
		shield = minf(shield + shield_regen * delta, max_shield)
		shield_changed.emit(shield, max_shield)


func is_depleted() -> bool:
	return health <= 0.0


## Applique un coup et renvoie les dégâts réellement subis. Le bouclier encaisse
## en premier, sans armure ; sur les points de vie, l'armure ne peut pas réduire
## un coup en dessous de 1 point de dégât.
func take_damage(amount: float) -> float:
	if is_depleted() or amount <= 0.0:
		return 0.0
	_since_hit = 0.0
	var absorbed := minf(amount, shield)
	if absorbed > 0.0:
		shield -= absorbed
		shield_changed.emit(shield, max_shield)
		amount -= absorbed
		if amount <= 0.0:
			return absorbed
	var dealt := minf(maxf(amount - armor, 1.0), health)
	health -= dealt
	health_changed.emit(health, max_health)
	if is_depleted():
		depleted.emit()
	return absorbed + dealt


## Rend des points de vie, sans dépasser le maximum. Renvoie les points rendus.
func heal(amount: float) -> float:
	if is_depleted() or amount <= 0.0:
		return 0.0
	var healed := minf(amount, max_health - health)
	if healed > 0.0:
		health += healed
		health_changed.emit(health, max_health)
	return healed
