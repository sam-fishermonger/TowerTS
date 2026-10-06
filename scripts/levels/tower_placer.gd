class_name TowerPlacer
extends Node2D
## Interaction du joueur avec la carte : choix de la tour, aperçu du placement,
## pose à la souris, affichage de la portée des tours survolées et sélection
## d'une tour posée pour voir sa fiche. Vise aussi les pouvoirs qui se lancent sur la
## carte (Météores, Renforts) : leur zone suit la souris jusqu'au clic.
## Au tactile (GameSettings.is_touch_mode), rien ne se survole : le premier toucher sur
## une case montre l'aperçu de la tour (et si elle peut s'y poser), un second toucher sur
## la même case la pose. Un pouvoir visé se lance là où l'on touche. Toucher la carte
## hors d'une tour ferme la fiche ouverte.

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
## Case touchée une première fois au tactile, en attente du second toucher (NO_CELL = aucune).
var touch_cell := NO_CELL
## « Touchez encore pour poser », au-dessus de l'aperçu, au tactile.
var touch_hint: Label

const NO_CELL := Vector2i(-1000, -1000)

@onready var preview: PlacementPreview = $PlacementPreview


func _ready() -> void:
	preview.visible = false
	touch_hint = Label.new()
	touch_hint.add_theme_font_size_override(&"font_size", 16)
	touch_hint.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	touch_hint.add_theme_constant_override(&"outline_size", 6)
	touch_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	touch_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_hint.z_index = 10
	touch_hint.visible = false
	add_child(touch_hint)


func select(data: TowerData) -> void:
	selected_tower = data
	_set_touch_cell(NO_CELL)
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
		var touch := GameSettings.is_touch_mode() or event.device == InputEvent.DEVICE_ID_EMULATION
		if selected_power and event.button_index == MOUSE_BUTTON_LEFT:
			if level.map.is_cell_in_grid(cell):
				level.use_power(selected_power, _to_world(event.position))
			get_viewport().set_input_as_handled()
		elif selected_power and event.button_index == MOUSE_BUTTON_RIGHT:
			select_power(null)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and selected_tower and touch and cell != touch_cell:
			# Premier toucher : l'aperçu se cale sur la case, sans rien poser.
			_set_touch_cell(cell if level.map.is_cell_in_grid(cell) else NO_CELL)
			_update_hover(_to_world(event.position))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and selected_tower:
			_set_touch_cell(NO_CELL)
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
		elif event.button_index == MOUSE_BUTTON_LEFT and touch and inspected_tower:
			inspect(null)
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


## Arme (ou désarme, avec NO_CELL) le second toucher, et place son rappel.
func _set_touch_cell(cell: Vector2i) -> void:
	touch_cell = cell
	touch_hint.visible = cell != NO_CELL and selected_tower != null
	if not touch_hint.visible:
		return
	var can_place := level.can_place_tower(cell, selected_tower)
	touch_hint.text = "Touchez encore pour poser" if can_place else "Impossible ici"
	touch_hint.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.65) if can_place else Color(1.0, 0.5, 0.5))
	touch_hint.reset_size()
	var center := level.map.cell_to_world(cell)
	touch_hint.global_position = center - Vector2(touch_hint.size.x / 2.0, Tower.SIZE / 2.0 + touch_hint.size.y + 4.0)


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
