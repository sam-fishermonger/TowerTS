class_name PlacementPreview
extends Node2D
## Aperçu de la tour (ou du bâtiment, en mode Conquête) à placer : vert si
## l'emplacement est valide, rouge sinon.

var tower_data: TowerData
## Bâtiment à placer (Building.Kind), -1 pour une tour.
var building_kind := -1
var is_valid := false


func show_at(world_position: Vector2, data: TowerData, valid: bool) -> void:
	global_position = world_position
	tower_data = data
	building_kind = -1
	is_valid = valid
	visible = true
	queue_redraw()


func show_building_at(world_position: Vector2, kind: int, valid: bool) -> void:
	global_position = world_position
	tower_data = null
	building_kind = kind
	is_valid = valid
	visible = true
	queue_redraw()


func _draw() -> void:
	var tint := Color(0.3, 1.0, 0.4) if is_valid else Color(1.0, 0.3, 0.3)
	if building_kind >= 0:
		var half_size := Building.SIZE / 2.0
		var cell_rect := Rect2(-half_size, -half_size, Building.SIZE, Building.SIZE)
		if Relief.enabled:
			draw_rect(cell_rect, Color(tint, 0.25))
			draw_rect(cell_rect, tint, false, 2.0)
			BuildingRelief.draw(self, building_kind, Vector2.ZERO, Color(1, 1, 1, 0.7))
			return
		Building.draw_icon(self, building_kind, Vector2.ZERO, Building.SIZE, Color(1, 1, 1, 0.7))
		draw_rect(cell_rect, tint, false, 2.0)
		return
	if tower_data == null:
		return
	draw_circle(Vector2.ZERO, tower_data.attack_range, Color(tint, 0.1))
	draw_arc(Vector2.ZERO, tower_data.attack_range, 0.0, TAU, 64, Color(tint, 0.6), 1.5)
	var half := Tower.SIZE / 2.0
	var rect := Rect2(-half, -half, Tower.SIZE, Tower.SIZE)
	if Relief.enabled:
		draw_rect(rect, Color(tint, 0.25))
		draw_rect(rect, tint, false, 2.0)
		Tower.draw_relief(self, tower_data, Vector2.ZERO, PI * 0.2, Color(1, 1, 1, 0.7))
		return
	if tower_data.turret_texture:
		Tower.draw_sprite(self, tower_data, Vector2.ZERO, Tower.SIZE, Tower.TURRET_SCALE, -PI / 2.0, Color(1, 1, 1, 0.65))
	else:
		draw_rect(rect, Color(tower_data.color, 0.6))
	draw_rect(rect, tint, false, 2.0)
