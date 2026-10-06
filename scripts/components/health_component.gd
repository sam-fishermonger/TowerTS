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
## Secondes pendant lesquelles le bouclier est brouillé : il ne se recharge pas.
var _jam_left := 0.0


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
	_jam_left = maxf(_jam_left - delta, 0.0)
	if shield < max_shield and shield_regen > 0.0 and _since_hit >= shield_regen_delay and not is_shield_jammed() \
			and not is_depleted():
		shield = minf(shield + shield_regen * delta, max_shield)
		shield_changed.emit(shield, max_shield)


func is_depleted() -> bool:
	return health <= 0.0


func is_shield_jammed() -> bool:
	return _jam_left > 0.0


## Brouille le bouclier : il ne se recharge plus pendant la durée donnée.
func jam_shield(duration: float) -> void:
	if max_shield > 0.0:
		_jam_left = maxf(_jam_left, duration)


## Applique un coup et renvoie les dégâts réellement subis. Le bouclier encaisse
## en premier, sans armure (`shield_multiplier` multiplie les dégâts qu'il reçoit) ;
## sur les points de vie, l'armure ne peut pas réduire un coup en dessous de 1 point
## de dégât, sauf si le coup l'ignore (`ignore_armor`).
func take_damage(amount: float, ignore_armor := false, shield_multiplier := 1.0) -> float:
	if is_depleted() or amount <= 0.0:
		return 0.0
	_since_hit = 0.0
	var absorbed := minf(amount * shield_multiplier, shield)
	if absorbed > 0.0:
		shield -= absorbed
		shield_changed.emit(shield, max_shield)
		amount -= absorbed / shield_multiplier
		# Marge pour les arrondis : un reste infime ne doit pas coûter 1 point de vie.
		if amount <= 0.0001:
			return absorbed
	var dealt := minf(amount if ignore_armor else maxf(amount - armor, 1.0), health)
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
