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
## Mode Conquête : un clic sur un ouvrier le choisit (Maj + clic, ou un toucher, l'ajoute
## aux autres), un cadre tiré depuis une case vide choisit tous ceux qu'il entoure, et un
## clic sur un gisement, un chantier ou le QG y envoie les ouvriers choisis (un clic droit
## aussi). Un clic sur une case vide, ou Échap, les relâche.

## Émis quand la tour sélectionnée change (null = aucune).
signal selection_changed(data: TowerData)
## Émis quand la tour posée inspectée change (null = aucune).
signal inspection_changed(tower: Tower)
## Émis quand le pouvoir en train d'être visé change (null = aucun).
signal power_selection_changed(power: Power)
## Mode Conquête : émis quand le bâtiment à poser change (-1 = aucun)…
signal building_selection_changed(kind: int)
## … et quand le bâtiment posé inspecté change (null = aucun).
signal building_inspection_changed(building: Building)

## Niveau qui valide et effectue les placements.
var level: Level
var selected_tower: TowerData
## Tour posée dont la fiche est ouverte.
var inspected_tower: Tower
## Pouvoir en train d'être visé : le prochain clic sur la carte le lance.
var selected_power: Power
## Mode Conquête : bâtiment à poser (Building.Kind, -1 = aucun), et bâtiment posé dont
## la fiche est ouverte.
var selected_building := -1
var inspected_building: Building

var _hovered_tower: Tower
var _mouse_position := Vector2.ZERO
## Case touchée une première fois au tactile, en attente du second toucher (NO_CELL = aucune).
var touch_cell := NO_CELL
## « Touchez encore pour poser », au-dessus de l'aperçu, au tactile.
var touch_hint: Label
## Niveau libre : « Fermerait le passage », sous l'aperçu d'une tour qui murerait le QG.
var passage_hint: Label

const NO_CELL := Vector2i(-1000, -1000)
## Pixels à l'écran au-delà desquels un appui qui glisse devient un cadre de sélection.
const DRAG_THRESHOLD := 10.0
## Au tactile, un ouvrier se choisit d'un peu plus loin (le doigt cache la cible).
const TOUCH_PICK_RADIUS := 28.0
const SELECTION_COLOR := Color(0.45, 1.0, 0.55)

## Mode Conquête : cadre de sélection des ouvriers, de l'appui (à l'écran, Vector2.INF :
## aucun) au point actuel, et s'il ajoute aux ouvriers déjà choisis (Maj).
var _drag_from := Vector2.INF
var _drag_to := Vector2.ZERO
var _dragging := false
var _drag_adds := false
## Butin sous la souris, cerclé de blanc.
var _hovered_loot: Loot

@onready var preview: PlacementPreview = $PlacementPreview


func _ready() -> void:
	preview.visible = false
	touch_hint = _make_hint()
	passage_hint = _make_hint()
	passage_hint.text = "Fermerait le passage"
	passage_hint.add_theme_color_override(&"font_color", Color(1.0, 0.5, 0.5))


func _make_hint() -> Label:
	var hint := Label.new()
	hint.add_theme_font_size_override(&"font_size", 16)
	hint.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	hint.add_theme_constant_override(&"outline_size", 6)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.z_index = 10
	hint.visible = false
	add_child(hint)
	return hint


func select(data: TowerData) -> void:
	selected_tower = data
	_set_touch_cell(NO_CELL)
	if data:
		select_power(null)
		select_building(-1)
		inspect(null)
	selection_changed.emit(data)
	refresh()


## Mode Conquête : choisit le bâtiment à poser (-1 = aucun) ; la tour choisie est abandonnée.
func select_building(kind: int) -> void:
	if kind == selected_building:
		return
	selected_building = kind
	_set_touch_cell(NO_CELL)
	if kind >= 0:
		if selected_tower:
			select(null)
		select_power(null)
		inspect(null)
	building_selection_changed.emit(kind)
	refresh()


## Ouvre la fiche d'un bâtiment posé (null = la fermer).
func inspect_building(building: Building) -> void:
	if building == inspected_building:
		return
	inspected_building = building
	if building:
		inspect(null)
	building_inspection_changed.emit(building)


## Vise un pouvoir (null = arrêter de viser) : la tour choisie est abandonnée.
func select_power(power: Power) -> void:
	if power == selected_power:
		return
	selected_power = power
	if power and selected_tower:
		select(null)
	if power:
		select_building(-1)
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
	if tower:
		inspect_building(null)
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
		if _drag_from != Vector2.INF and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_drag_to = event.position
			if not _dragging and _drag_to.distance_to(_drag_from) > DRAG_THRESHOLD:
				_dragging = true
			if _dragging:
				queue_redraw()
				get_viewport().set_input_as_handled()
		refresh()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and _drag_from != Vector2.INF:
		_finish_drag(event.position)
		get_viewport().set_input_as_handled()
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
		elif event.button_index == MOUSE_BUTTON_LEFT and _pick_loot(event, touch):
			# Un butin au sol (Loot) se ramasse avant tout le reste.
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and selected_building >= 0 and touch and cell != touch_cell:
			_set_touch_cell(cell if level.map.is_cell_in_grid(cell) else NO_CELL)
			_update_hover(_to_world(event.position))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and selected_building >= 0:
			_set_touch_cell(NO_CELL)
			var built := level.conquest.place_building(cell, selected_building)
			if built and not event.shift_pressed:
				select_building(-1)
			else:
				refresh()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected_building >= 0:
			select_building(-1)
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
		elif event.button_index == MOUSE_BUTTON_LEFT and level.conquest and _pick_worker(event, touch):
			get_viewport().set_input_as_handled()
		elif (event.button_index == MOUSE_BUTTON_LEFT or (event.button_index == MOUSE_BUTTON_RIGHT and selected_tower == null)) \
				and level.conquest and level.conquest.order_selected(cell):
			# Mode Conquête : les ouvriers choisis vont au gisement, au chantier ou au QG.
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected_tower == null and _has_selected_workers():
			level.conquest.clear_selection()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and level.map.get_occupant(cell) is Building:
			inspect_building(level.map.get_occupant(cell))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and level.conquest and level.conquest.has_resource(cell):
			# Mode Conquête : un clic sur un rocher ou un filon y envoie les mineurs.
			level.conquest.set_preferred_rock(cell)
			inspect(null)
			inspect_building(null)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and level.map.get_occupant(cell) is Tower:
			inspect(level.map.get_occupant(cell))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and level.conquest and level.map.is_cell_in_grid(cell) \
				and level.map.get_occupant(cell) == null:
			# Mode Conquête : un appui sur une case vide commence peut-être un cadre de
			# sélection ; relâché sans glisser, il relâche les ouvriers choisis.
			_drag_from = event.position
			_drag_to = event.position
			_dragging = false
			_drag_adds = event.shift_pressed
			if touch:
				inspect(null)
				inspect_building(null)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and touch and (inspected_tower or inspected_building):
			inspect(null)
			inspect_building(null)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected_tower:
			select(null)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and (selected_tower or selected_power or inspected_tower
			or selected_building >= 0 or inspected_building or _has_selected_workers()):
		if selected_power:
			select_power(null)
		elif selected_tower:
			select(null)
		elif selected_building >= 0:
			select_building(-1)
		elif inspected_building:
			inspect_building(null)
		elif inspected_tower:
			inspect(null)
		else:
			level.conquest.clear_selection()
		get_viewport().set_input_as_handled()


## Ramasse le butin sous le clic (ou le toucher). Renvoie false s'il n'y en a pas.
func _pick_loot(event: InputEventMouseButton, touch: bool) -> bool:
	var loot := level.find_loot_at(_to_world(event.position), Loot.TOUCH_PICK_RADIUS if touch else Loot.PICK_RADIUS)
	if loot == null:
		return false
	level.collect_loot(loot)
	_set_touch_cell(NO_CELL)
	return true


func _has_selected_workers() -> bool:
	return level.conquest != null and not level.conquest.get_selected_workers().is_empty()


## Mode Conquête : un clic sur un ouvrier le choisit seul ; Maj + clic, ou un toucher,
## l'ajoute aux ouvriers choisis (ou l'en retire). Renvoie false s'il n'y a pas d'ouvrier là.
func _pick_worker(event: InputEventMouseButton, touch: bool) -> bool:
	var worker := level.conquest.worker_at(_to_world(event.position), TOUCH_PICK_RADIUS if touch else Worker.PICK_RADIUS)
	if worker == null:
		return false
	if touch or event.shift_pressed:
		level.conquest.toggle_worker(worker)
	else:
		level.conquest.select_workers([worker])
	inspect(null)
	inspect_building(null)
	return true


## Fin d'un appui sur une case vide : un cadre choisit les ouvriers qu'il entoure, un
## simple clic relâche les ouvriers choisis (sauf avec Maj).
func _finish_drag(screen_position: Vector2) -> void:
	if _dragging:
		var from := _to_world(_drag_from)
		var rect := Rect2(from, Vector2.ZERO).expand(_to_world(screen_position))
		level.conquest.select_workers(level.conquest.workers_in_rect(rect), _drag_adds)
	elif not _drag_adds:
		level.conquest.clear_selection()
	_drag_from = Vector2.INF
	_dragging = false
	queue_redraw()


## Arme (ou désarme, avec NO_CELL) le second toucher, et place son rappel.
func _set_touch_cell(cell: Vector2i) -> void:
	touch_cell = cell
	touch_hint.visible = cell != NO_CELL and (selected_tower != null or selected_building >= 0)
	if not touch_hint.visible:
		return
	var can_place := level.conquest.can_place_building(cell, selected_building) if selected_building >= 0 \
		else level.can_place_tower(cell, selected_tower)
	touch_hint.text = "Touchez encore pour poser" if can_place else \
		"Fermerait le passage" if selected_tower and level.blocks_passage(cell) else "Impossible ici"
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
	var loot := level.find_loot_at(world_position)
	if loot != _hovered_loot:
		if is_instance_valid(_hovered_loot):
			_hovered_loot.highlighted = false
		_hovered_loot = loot
		if loot:
			loot.highlighted = true
	var cell := map.world_to_cell(world_position)
	var hovered := map.get_occupant(cell) as Tower
	if hovered != _hovered_tower:
		var previous := _hovered_tower
		_hovered_tower = hovered
		_refresh_range(previous)
		_refresh_range(hovered)
	_update_passage_preview(cell if selected_tower and map.is_cell_buildable(cell) else NO_CELL)
	if selected_tower and map.is_cell_in_grid(cell):
		preview.show_at(map.cell_to_world(cell), selected_tower, level.can_place_tower(cell, selected_tower))
	elif selected_building >= 0 and map.is_cell_in_grid(cell):
		preview.show_building_at(map.cell_to_world(cell), selected_building,
			level.conquest.can_place_building(cell, selected_building))
	else:
		preview.visible = false


## Niveau libre : chemin qu'auraient les monstres avec la tour sur cette case (NO_CELL :
## aucun), et avertissement si elle fermerait le passage.
func _update_passage_preview(cell: Vector2i) -> void:
	if not level.map.free_layout:
		return
	var path_preview := level.get_node_or_null("PathPreview") as PathPreview
	if path_preview:
		path_preview.show_candidate(cell)
	# Au tactile, le rappel du second toucher le dit déjà.
	passage_hint.visible = cell != NO_CELL and not touch_hint.visible and level.blocks_passage(cell)
	if passage_hint.visible:
		passage_hint.reset_size()
		var center := level.map.cell_to_world(cell)
		# Au-dessus de l'aperçu, sauf sur la première rangée (sous la barre du haut).
		var below := cell.y == 0
		passage_hint.global_position = center + Vector2(-passage_hint.size.x / 2.0,
			Tower.SIZE / 2.0 + 4.0 if below else -Tower.SIZE / 2.0 - passage_hint.size.y - 4.0)


## Cadre de sélection des ouvriers (mode Conquête), et zone du pouvoir visé, sous la
## souris : celle où tombent les météores, ou l'endroit du chemin où les soldats
## prendront position.
func _draw() -> void:
	if _dragging and level:
		var rect := Rect2(to_local(_to_world(_drag_from)), Vector2.ZERO).expand(to_local(_to_world(_drag_to)))
		draw_rect(rect, Color(SELECTION_COLOR, 0.12))
		draw_rect(rect, Color(SELECTION_COLOR, 0.85), false, 1.5)
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
