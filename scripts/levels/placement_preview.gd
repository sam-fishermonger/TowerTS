class_name PlacementPreview
extends Node2D
## Aperçu de la tour à placer : vert si l'emplacement est valide, rouge sinon.

var tower_data: TowerData
var is_valid := false


func show_at(world_position: Vector2, data: TowerData, valid: bool) -> void:
	global_position = world_position
	tower_data = data
	is_valid = valid
	visible = true
	queue_redraw()


func _draw() -> void:
	if tower_data == null:
		return
	var tint := Color(0.3, 1.0, 0.4) if is_valid else Color(1.0, 0.3, 0.3)
	draw_circle(Vector2.ZERO, tower_data.attack_range, Color(tint, 0.1))
	draw_arc(Vector2.ZERO, tower_data.attack_range, 0.0, TAU, 64, Color(tint, 0.6), 1.5)
	var half := Tower.SIZE / 2.0
	draw_rect(Rect2(-half, -half, Tower.SIZE, Tower.SIZE), Color(tower_data.color, 0.6))
	draw_rect(Rect2(-half, -half, Tower.SIZE, Tower.SIZE), tint, false, 2.0)
