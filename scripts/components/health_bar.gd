class_name HealthBar
extends Node2D
## Barre de vie au-dessus d'une entité, affichée seulement après le premier dégât.

@export var health: HealthComponent
@export var width := 24.0


func _ready() -> void:
	health.health_changed.connect(func(_health: float, _max: float) -> void: queue_redraw())


func _draw() -> void:
	if health.health >= health.max_health or health.max_health <= 0.0:
		return
	var top_left := Vector2(-width / 2.0, 0.0)
	draw_rect(Rect2(top_left, Vector2(width, 4.0)), Color(0.15, 0.15, 0.15))
	var ratio := health.health / health.max_health
	draw_rect(Rect2(top_left, Vector2(width * ratio, 4.0)), Color(0.3, 0.9, 0.3))
	if health.armor > 0.0:
		draw_rect(Rect2(top_left, Vector2(width, 4.0)), Color(0.75, 0.8, 0.9), false, 1.0)
