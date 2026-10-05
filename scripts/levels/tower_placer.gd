class_name TowerPlacer
extends Node2D
## Interaction du joueur avec la carte : choix de la tour, aperçu du placement,
## pose à la souris et affichage de la portée des tours survolées.

## Émis quand la tour sélectionnée change (null = aucune).
signal selection_changed(data: TowerData)

## Niveau qui valide et effectue les placements.
var level: Level
var selected_tower: TowerData

var _hovered_tower: Tower

@onready var preview: PlacementPreview = $PlacementPreview


func _ready() -> void:
	preview.visible = false


func select(data: TowerData) -> void:
	selected_tower = data
	selection_changed.emit(data)
	refresh()


## Met à jour l'aperçu et le survol à la position actuelle de la souris.
func refresh() -> void:
	_update_hover(get_global_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if level == null or level.is_over:
		return
	if event is InputEventMouseMotion:
		refresh()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and selected_tower:
			var cell := level.map.world_to_cell(get_global_mouse_position())
			var placed := level.place_tower(cell, selected_tower)
			# Maj + clic garde la tour sélectionnée pour en poser plusieurs.
			if placed and not event.shift_pressed:
				select(null)
			else:
				refresh()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected_tower:
			select(null)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and selected_tower:
		select(null)
		get_viewport().set_input_as_handled()


func _update_hover(world_position: Vector2) -> void:
	if level == null:
		return
	var map := level.map
	var cell := map.world_to_cell(world_position)
	var hovered := map.get_occupant(cell) as Tower
	if hovered != _hovered_tower:
		if is_instance_valid(_hovered_tower):
			_hovered_tower.show_range = false
		_hovered_tower = hovered
		if hovered:
			hovered.show_range = true
	if selected_tower and map.is_cell_in_grid(cell):
		preview.show_at(map.cell_to_world(cell), selected_tower, level.can_place_tower(cell, selected_tower))
	else:
		preview.visible = false
