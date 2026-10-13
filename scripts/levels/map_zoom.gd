class_name MapZoom
extends Node
## Zoom et déplacement de la vue sur la carte, en partie. La molette zoome vers la souris,
## deux doigts pincent (et font glisser) la carte au tactile, + et - zooment au clavier,
## les gâchettes à la manette. Une fois zoomé, on fait glisser la carte : clic gauche
## maintenu là où il ne pose ni ne choisit rien (ou un doigt, au tactile), clic du milieu,
## flèches du clavier, ou stick droit de la manette.
##
## Le zoom ne descend jamais sous la vue de la carte entière (le niveau par défaut), et la
## vue reste dans la zone de jeu, entre la barre du haut et celle du bas. Il passe par la
## transformation du canevas de la fenêtre : tout ce qui lit la souris dans le monde
## (pose des tours, pouvoirs, ouvriers) reste juste. Le HUD, dans son propre calque,
## ne bouge pas.

const MIN_ZOOM := 1.0
const MAX_ZOOM := 3.0
## Facteur de zoom d'un cran de molette, et de zoom par seconde au clavier ou aux gâchettes.
const WHEEL_STEP := 1.15
const ZOOM_SPEED := 2.2
## Vitesse du déplacement aux flèches et au stick droit, en pixels de l'écran par seconde.
const PAN_SPEED := 900.0
## Pixels à l'écran au-delà desquels un appui qui glisse déplace la carte.
const DRAG_THRESHOLD := 10.0
const STICK_DEADZONE := 0.22
const TRIGGER_DEADZONE := 0.15

var level: Level
## Zoom actuel (1 = la carte entière) et décalage de la vue, en pixels de l'écran.
var zoom := MIN_ZOOM
var offset := Vector2.ZERO

## Glisser au clic gauche (ou au doigt) : point d'appui (Vector2.INF : aucun) et s'il a
## assez bougé pour déplacer la carte.
var _drag_from := Vector2.INF
var _dragging := false
## Clic du milieu maintenu : la carte suit la souris.
var _middle_drag := false
## Doigts posés sur l'écran (index -> position), pour le pincement à deux doigts.
var _touches := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _exit_tree() -> void:
	# La transformation appartient à la fenêtre : les écrans suivants la retrouvent intacte.
	if is_inside_tree():
		get_viewport().canvas_transform = Transform2D.IDENTITY


## Zoome (factor > 1 : rapproche) en gardant immobile le point de l'écran donné.
func zoom_at(screen_point: Vector2, factor: float) -> void:
	var target := clampf(zoom * factor, MIN_ZOOM, MAX_ZOOM)
	if is_equal_approx(target, zoom):
		return
	var world := (screen_point - offset) / zoom
	zoom = target
	offset = screen_point - world * zoom
	_apply()


## Déplace la vue (la carte suit le geste : un glisser vers la droite montre la gauche).
func pan(screen_delta: Vector2) -> void:
	offset += screen_delta
	_apply()


## Revient à la vue de la carte entière.
func reset() -> void:
	zoom = MIN_ZOOM
	offset = Vector2.ZERO
	_apply()


func is_zoomed() -> bool:
	return zoom > MIN_ZOOM + 0.001


## Position dans le monde d'un point de l'écran.
func to_world(screen_point: Vector2) -> Vector2:
	return (screen_point - offset) / zoom


func _play_area() -> Rect2:
	if level and level.hud:
		return level.hud.get_play_area()
	return get_viewport().get_visible_rect()


## Garde la zone de jeu de l'écran sur la carte, puis applique la vue.
func _apply() -> void:
	var area := _play_area()
	offset.x = clampf(offset.x, area.end.x * (1.0 - zoom), area.position.x * (1.0 - zoom))
	offset.y = clampf(offset.y, area.end.y * (1.0 - zoom), area.position.y * (1.0 - zoom))
	get_viewport().canvas_transform = Transform2D(0.0, Vector2(zoom, zoom), 0.0, offset)
	# Ce qui est sous la souris a changé : l'aperçu de la tour suit.
	if level and level.placer:
		level.placer.refresh()


## Les doigts se suivent ici, avant l'interface : un doigt levé sur une barre compte aussi.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)


## Appelé après le TowerPlacer (ce nœud est le premier enfant du niveau) : un clic qu'il a
## pris (poser, choisir, viser) ne déplace pas la carte.
func _unhandled_input(event: InputEvent) -> void:
	if level == null or level.hud.end_panel.visible:
		return
	if event is InputEventScreenDrag:
		_on_touch_drag(event)
	elif event is InputEventMagnifyGesture:
		# Pincement du pavé tactile (ou du téléphone, si le système le traduit lui-même).
		if _touches.size() < 2:
			zoom_at(event.position, event.factor)
			get_viewport().set_input_as_handled()
	elif event is InputEventPanGesture:
		if _touches.size() < 2:
			pan(-event.delta * 8.0)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event)
	elif event is InputEventKey and event.pressed:
		_on_key(event)


func _on_mouse_button(event: InputEventMouseButton) -> void:
	var in_area := _play_area().has_point(event.position)
	if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and in_area:
		var notches := event.factor if event.factor > 0.0 else 1.0
		var step := pow(WHEEL_STEP, notches)
		zoom_at(event.position, step if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / step)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		_middle_drag = event.pressed and in_area
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed and in_area and _touches.size() < 2:
		# Personne n'a pris ce clic : s'il glisse, il déplace la carte.
		_drag_from = event.position
		_dragging = false
	elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_drag_from = Vector2.INF
		_dragging = false


func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	if _middle_drag and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		pan(event.relative)
		get_viewport().set_input_as_handled()
		return
	_middle_drag = false
	if _drag_from == Vector2.INF or not event.button_mask & MOUSE_BUTTON_MASK_LEFT or _touches.size() >= 2:
		return
	if not _dragging and event.position.distance_to(_drag_from) > DRAG_THRESHOLD:
		_dragging = true
		pan(event.position - _drag_from)
	elif _dragging:
		pan(event.relative)
	if _dragging:
		get_viewport().set_input_as_handled()


func _on_key(event: InputEventKey) -> void:
	if _menu_has_focus():
		return
	# + et - de la rangée du haut ou du pavé numérique, quelle que soit la disposition.
	var zoom_in := event.keycode in [KEY_PLUS, KEY_EQUAL, KEY_KP_ADD] or event.physical_keycode == KEY_EQUAL
	var zoom_out := event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT] or event.physical_keycode == KEY_MINUS
	if zoom_in or zoom_out:
		zoom_at(_play_area().get_center(), WHEEL_STEP if zoom_in else 1.0 / WHEEL_STEP)
		get_viewport().set_input_as_handled()


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touches[event.index] = event.position
	else:
		_touches.erase(event.index)
	if _touches.size() >= 2:
		# Le second doigt arrive : le glisser à un doigt cède la place au pincement.
		_drag_from = Vector2.INF
		_dragging = false


## Deux doigts : l'écart entre eux zoome, leur milieu fait glisser la carte.
func _on_touch_drag(event: InputEventScreenDrag) -> void:
	var indexes := _touches.keys().slice(0, 2)
	if _touches.size() < 2 or not indexes.has(event.index):
		_touches[event.index] = event.position
		return
	var other: int = indexes[0] if indexes[0] != event.index else indexes[1]
	var before: Vector2 = _touches[event.index]
	var anchor: Vector2 = _touches[other]
	_touches[event.index] = event.position
	var old_middle := (before + anchor) / 2.0
	var new_middle := (event.position + anchor) / 2.0
	var old_gap := before.distance_to(anchor)
	if old_gap > 1.0:
		zoom_at(old_middle, event.position.distance_to(anchor) / old_gap)
	pan(new_middle - old_middle)
	get_viewport().set_input_as_handled()


## Flèches du clavier, stick droit et gâchettes de la manette, tant qu'ils sont tenus.
func _process(delta: float) -> void:
	if level == null or level.hud.end_panel.visible or _menu_has_focus():
		return
	# Temps réel : la vue bouge pareil en pause et à vitesse x2 ou x3.
	delta = delta / maxf(Engine.time_scale, 0.001)
	var direction := Vector2.ZERO
	if _keyboard_free():
		direction = Vector2(float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT)),
			float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP)))
	var triggers := 0.0
	for device in Input.get_connected_joypads():
		var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_RIGHT_X), Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y))
		if stick.length() > STICK_DEADZONE:
			direction += stick
		for axis: JoyAxis in [JOY_AXIS_TRIGGER_RIGHT, JOY_AXIS_TRIGGER_LEFT]:
			var pressure := Input.get_joy_axis(device, axis)
			if pressure > TRIGGER_DEADZONE:
				triggers += pressure if axis == JOY_AXIS_TRIGGER_RIGHT else -pressure
	if direction != Vector2.ZERO:
		# Les flèches montrent ce qui est dans leur direction : la carte part à l'opposé.
		pan(-direction.limit_length(1.0) * PAN_SPEED * delta)
	if triggers != 0.0:
		var center := Gamepad.get_cursor() if Gamepad.has_cursor() else _play_area().get_center()
		zoom_at(center, pow(ZOOM_SPEED, clampf(triggers, -1.0, 1.0) * delta))


## Un menu (options, choix des tours...) a le focus : flèches et manette sont à lui.
func _menu_has_focus() -> bool:
	var focused := get_viewport().gui_get_focus_owner()
	return focused != null and focused.is_visible_in_tree()


## Les flèches ne bougent pas la carte pendant qu'on écrit ou qu'un menu les utilise.
func _keyboard_free() -> bool:
	return get_window().has_focus() or DisplayServer.get_name() == "headless"
