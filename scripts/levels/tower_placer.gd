class_name TowerPlacer
extends Node2D
## Interaction du joueur avec la carte : choix de la tour, aperçu du placement,
## pose à la souris, affichage de la portée des tours survolées et sélection
## d'une tour posée pour voir sa fiche. Vise aussi les pouvoirs qui se lancent sur la
## carte (Météores, Renforts) : leur zone suit la souris jusqu'au clic.

## Émis quand la tour sélectionnée change (null = aucune).
signal selection_changed(data: TowerData)
## Émis quand la tour posée inspectée change (null = aucune).
signal inspection_changed(tower: Tower)
## Émis quand le pouvoir en train d'être visé change (null = aucun).
signal power_selection_changed(power: Power)

## Niveau qui valide et effectue les placements.
var level: Level
var selected_tower: TowerData
## Tour posée dont la fiche est ouverte.
var inspected_tower: Tower
## Pouvoir en train d'être visé : le prochain clic sur la carte le lance.
var selected_power: Power

var _hovered_tower: Tower
var _mouse_position := Vector2.ZERO

@onready var preview: PlacementPreview = $PlacementPreview


func _ready() -> void:
	preview.visible = false


func select(data: TowerData) -> void:
	selected_tower = data
	if data:
		select_power(null)
		inspect(null)
	selection_changed.emit(data)
	refresh()


## Vise un pouvoir (null = arrêter de viser) : la tour choisie est abandonnée.
func select_power(power: Power) -> void:
	if power == selected_power:
		return
	selected_power = power
	if power and selected_tower:
		select(null)
	if power:
		inspect(null)
	power_selection_changed.emit(power)
	refresh()
	queue_redraw()


## Ouvre la fiche d'une tour posée (null = la fermer).
func inspect(tower: Tower) -> void:
	if tower == inspected_tower:
		return
	var previous := inspected_tower
	inspected_tower = tower
	_refresh_range(previous)
	_refresh_range(tower)
	inspection_changed.emit(tower)


## Met à jour l'aperçu et le survol à la position actuelle de la souris.
func refresh() -> void:
	_update_hover(get_global_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if level == null or level.is_over:
		return
	if event is InputEventMouseMotion:
		refresh()
	elif event is InputEventMouseButton and event.pressed:
		var cell := level.map.world_to_cell(_to_world(event.position))
		if selected_power and event.button_index == MOUSE_BUTTON_LEFT:
			if level.map.is_cell_in_grid(cell):
				level.use_power(selected_power, _to_world(event.position))
			get_viewport().set_input_as_handled()
		elif selected_power and event.button_index == MOUSE_BUTTON_RIGHT:
			select_power(null)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and selected_tower:
			var placed := level.place_tower(cell, selected_tower)
			# Maj + clic garde la tour sélectionnée pour en poser plusieurs.
			if placed and not event.shift_pressed:
				select(null)
			else:
				refresh()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and level.map.get_occupant(cell) is Tower:
			inspect(level.map.get_occupant(cell))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected_tower:
			select(null)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and (selected_tower or selected_power or inspected_tower):
		if selected_power:
			select_power(null)
		elif selected_tower:
			select(null)
		else:
			inspect(null)
		get_viewport().set_input_as_handled()


## Position dans le monde d'un point de l'écran.
func _to_world(screen_position: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_position


## La portée d'une tour s'affiche quand elle est survolée ou inspectée.
func _refresh_range(tower: Tower) -> void:
	if is_instance_valid(tower):
		tower.show_range = tower == _hovered_tower or tower == inspected_tower


func _update_hover(world_position: Vector2) -> void:
	if level == null:
		return
	var map := level.map
	_mouse_position = world_position
	if selected_power:
		queue_redraw()
	var cell := map.world_to_cell(world_position)
	var hovered := map.get_occupant(cell) as Tower
	if hovered != _hovered_tower:
		var previous := _hovered_tower
		_hovered_tower = hovered
		_refresh_range(previous)
		_refresh_range(hovered)
	if selected_tower and map.is_cell_in_grid(cell):
		preview.show_at(map.cell_to_world(cell), selected_tower, level.can_place_tower(cell, selected_tower))
	else:
		preview.visible = false


## Zone du pouvoir visé, sous la souris : celle où tombent les météores, ou l'endroit du
## chemin où les soldats prendront position.
func _draw() -> void:
	if selected_power == null or level == null:
		return
	var color := selected_power.color
	if not level.map.is_cell_in_grid(level.map.world_to_cell(_mouse_position)):
		color = Color(1, 0.35, 0.3)
	var at := to_local(_mouse_position)
	if selected_power.kind == Power.Kind.REINFORCEMENTS:
		var post := to_local(level.map.get_closest_path_point(_mouse_position))
		draw_dashed_line(at, post, Color(color, 0.6), 2.0, 6.0)
		draw_circle(post, selected_power.radius, Color(color, 0.18))
		draw_arc(post, selected_power.radius, 0.0, TAU, 40, Color(color, 0.8), 2.0)
		for i in selected_power.count:
			var spread := 0.0 if selected_power.count == 1 else 16.0
			draw_circle(post + Vector2.from_angle(TAU * i / selected_power.count - PI / 2.0) * spread,
				Soldier.BODY_RADIUS, Color(color, 0.6))
		return
	draw_circle(at, selected_power.radius, Color(color, 0.18))
	draw_arc(at, selected_power.radius, 0.0, TAU, 48, Color(color, 0.85), 2.0)
	draw_arc(at, selected_power.radius + selected_power.splash_radius * 0.5, 0.0, TAU, 48, Color(color, 0.3), 1.0)
