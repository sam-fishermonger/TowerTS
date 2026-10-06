class_name HealthBar
extends Node2D
## Barre de vie au-dessus d'une entité, affichée seulement tant qu'elle est blessée
## (vie ou bouclier entamés), avec au-dessus la barre du bouclier d'énergie s'il y en a un.

const SHIELD_COLOR := Color(0.4, 0.85, 1.0)

@export var health: HealthComponent
@export var width := 24.0


func _ready() -> void:
	health.health_changed.connect(func(_health: float, _max: float) -> void: queue_redraw())
	health.shield_changed.connect(func(_shield: float, _max: float) -> void: queue_redraw())


func _draw() -> void:
	if health.max_health <= 0.0:
		return
	var hurt := health.health < health.max_health
	var shield_hit := health.max_shield > 0.0 and health.shield < health.max_shield
	if not hurt and not shield_hit:
		return
	var top_left := Vector2(-width / 2.0, 0.0)
	draw_rect(Rect2(top_left, Vector2(width, 4.0)), Color(0.15, 0.15, 0.15))
	var ratio := health.health / health.max_health
	draw_rect(Rect2(top_left, Vector2(width * ratio, 4.0)), Color(0.3, 0.9, 0.3))
	if health.armor > 0.0:
		draw_rect(Rect2(top_left, Vector2(width, 4.0)), Color(0.75, 0.8, 0.9), false, 1.0)
	if health.max_shield > 0.0:
		var shield_top := top_left - Vector2(0.0, 4.0)
		draw_rect(Rect2(shield_top, Vector2(width, 3.0)), Color(0.1, 0.15, 0.2))
		draw_rect(Rect2(shield_top, Vector2(width * health.shield / health.max_shield, 3.0)), SHIELD_COLOR)
