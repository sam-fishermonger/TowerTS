class_name Enemy
extends PathFollow2D
## Ennemi qui avance le long du chemin (Path2D parent) jusqu'à la base du joueur.

signal died(enemy: Enemy)
signal reached_end(enemy: Enemy)

const GROUP := "enemies"

@export var data: EnemyData

var health := 0.0
var is_alive := true


func _ready() -> void:
	loop = false
	rotates = false
	health = data.max_health
	add_to_group(GROUP)


func _process(delta: float) -> void:
	progress += data.speed * delta
	if progress_ratio >= 1.0:
		_remove()
		reached_end.emit(self)


func take_damage(amount: float) -> void:
	if not is_alive:
		return
	health -= amount
	queue_redraw()
	if health <= 0.0:
		_remove()
		died.emit(self)


func _remove() -> void:
	is_alive = false
	remove_from_group(GROUP)
	set_process(false)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, data.radius, data.color)
	draw_arc(Vector2.ZERO, data.radius, 0.0, TAU, 24, data.color.darkened(0.5), 2.0)
	# Barre de vie, affichée seulement après le premier dégât.
	if health < data.max_health:
		var width := data.radius * 2.0
		var top_left := Vector2(-data.radius, -data.radius - 8.0)
		draw_rect(Rect2(top_left, Vector2(width, 4.0)), Color(0.15, 0.15, 0.15))
		draw_rect(Rect2(top_left, Vector2(width * health / data.max_health, 4.0)), Color(0.3, 0.9, 0.3))
