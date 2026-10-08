class_name Gamepad
extends CanvasLayer
## Manette : un pointeur mené au stick gauche fait tout ce que fait la souris (A clique
## là où il se trouve), la croix et A parcourent les menus comme le clavier, B annule ou
## revient en arrière. En partie, les autres boutons sont des raccourcis (voir Hud) et la
## croix déplace le pointeur d'une case. Les vibrations (vie perdue, boss) passent aussi
## par ici, sur la manette comme sur le téléphone.
##
## Le nœud est chargé au démarrage (autoload « Manette ») ; comme GameSettings, il
## s'utilise par ses fonctions statiques. Le pointeur n'apparaît qu'une fois le stick
## bougé, et disparaît dès que la souris bouge ou qu'on touche l'écran.

## Méta du moteur : vrai quand le dernier geste du joueur venait de la manette.
const ACTIVE_META := &"gamepad_active"
## Méta du moteur : position du pointeur (en pixels de l'écran de jeu), absente s'il est caché.
const CURSOR_META := &"gamepad_cursor"
## En dessous, le stick est au repos.
const DEADZONE := 0.22
## Vitesse du pointeur stick à fond, en pixels de l'écran de jeu par seconde.
const CURSOR_SPEED := 950.0
## Pas du pointeur à la croix, en partie (une case de la carte).
const DPAD_STEP := 64.0
## Croix maintenue : premier pas répété après ce délai, puis à ce rythme.
const DPAD_REPEAT_DELAY := 0.35
const DPAD_REPEAT_RATE := 0.09
const CURSOR_COLOR := Color(0.35, 0.85, 1.0)
## Vibrations : durée (s) et force (0 à 1) de chaque sorte.
const RUMBLES := {
	&"life_lost": [0.18, 0.55],
	&"boss": [0.6, 1.0],
}

var _cursor: Node2D
## Bouton A enfoncé sur le pointeur (le clic se relâche quand A se relâche).
var _a_held := false
## Croix maintenue (direction) et temps avant le prochain pas.
var _dpad := Vector2.ZERO
var _dpad_wait := 0.0
## Dernières positions où le pointeur a mis la souris (pixels de l'écran de jeu) : les
## mouvements de souris que le système renvoie alors (parfois une image plus tard) ne
## comptent pas comme une vraie souris.
var _warped_to: Array[Vector2] = []


func _ready() -> void:
	layer = 127
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_input_map()
	_cursor = Node2D.new()
	_cursor.visible = false
	_cursor.draw.connect(_draw_cursor)
	add_child(_cursor)


## A valide et B annule dans les menus ; le stick gauche ne sert plus qu'au pointeur
## (la croix suffit pour passer d'un bouton à l'autre).
static func setup_input_map() -> void:
	_add_joy_button(&"ui_accept", JOY_BUTTON_A)
	_add_joy_button(&"ui_cancel", JOY_BUTTON_B)
	for action: StringName in [&"ui_up", &"ui_down", &"ui_left", &"ui_right"]:
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion:
				InputMap.action_erase_event(action, event)


static func _add_joy_button(action: StringName, button: JoyButton) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.device = -1
	InputMap.action_add_event(action, event)


## Vrai quand le joueur se sert de la manette (le rappel des commandes en parle).
static func is_active() -> bool:
	return Engine.get_meta(ACTIVE_META, false)


static func set_active(enabled: bool) -> void:
	Engine.set_meta(ACTIVE_META, enabled)


## Vrai quand le pointeur de la manette est affiché.
static func has_cursor() -> bool:
	return Engine.has_meta(CURSOR_META)


static func get_cursor() -> Vector2:
	return Engine.get_meta(CURSOR_META, Vector2.ZERO)


# --- Vibrations ---------------------------------------------------------------

static func is_vibration_enabled() -> bool:
	return Progress.get_setting("vibration", true)


static func set_vibration_enabled(enabled: bool) -> void:
	Progress.set_setting("vibration", enabled)


## Fait vibrer le téléphone et les manettes branchées (voir RUMBLES), si les vibrations
## sont permises dans les Options. Renvoie vrai si une vibration a été demandée.
static func rumble(kind: StringName) -> bool:
	if not is_vibration_enabled() or not RUMBLES.has(kind):
		return false
	var duration: float = RUMBLES[kind][0]
	var strength: float = RUMBLES[kind][1]
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(roundi(duration * 1000.0), strength)
	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, strength * 0.6, strength, duration)
	return true


# --- Pointeur -----------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.device != InputEvent.DEVICE_ID_EMULATION and not _is_own_motion(event):
			_leave()
		return
	if event is InputEventScreenTouch or (event is InputEventKey and event.pressed):
		_leave()
		return
	var button := event as InputEventJoypadButton
	if button == null:
		if event is InputEventJoypadMotion and absf(event.axis_value) > DEADZONE:
			set_active(true)
		return
	set_active(true)
	if button.button_index == JOY_BUTTON_A and (has_cursor() or _a_held):
		# A clique sous le pointeur (et non sur le bouton qui a le focus).
		if button.pressed != _a_held:
			_a_held = button.pressed
			_send_click(button.pressed)
		get_viewport().set_input_as_handled()
	elif _is_dpad(button.button_index):
		var direction := _dpad_direction(button.button_index)
		if button.pressed and _steps_cursor():
			_dpad = direction
			_dpad_wait = DPAD_REPEAT_DELAY
			step_cursor(direction)
			get_viewport().set_input_as_handled()
		elif not button.pressed and _dpad == direction:
			_dpad = Vector2.ZERO
		elif button.pressed:
			# La croix parcourt le menu : le pointeur s'efface, A presse le bouton choisi.
			hide_cursor()


func _process(delta: float) -> void:
	var stick := Vector2.ZERO
	for device in Input.get_connected_joypads():
		stick += Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
	move_cursor(stick, delta)
	if _dpad != Vector2.ZERO:
		_dpad_wait -= delta
		if _dpad_wait <= 0.0:
			_dpad_wait = DPAD_REPEAT_RATE
			step_cursor(_dpad)


## Déplace le pointeur selon l'inclinaison du stick (lent près du centre, vif à fond).
func move_cursor(stick: Vector2, delta: float) -> void:
	var tilt := minf(stick.length(), 1.0)
	if tilt < DEADZONE:
		return
	var speed := CURSOR_SPEED * pow((tilt - DEADZONE) / (1.0 - DEADZONE), 1.6)
	var from := get_cursor() if has_cursor() else _start_position()
	set_cursor(from + stick.normalized() * speed * delta)


## Un pas de pointeur (la croix, en partie).
func step_cursor(direction: Vector2) -> void:
	var from := get_cursor() if has_cursor() else _start_position()
	set_cursor(from + direction * DPAD_STEP)


## Met le pointeur à cette position (pixels de l'écran de jeu) et la souris avec lui.
func set_cursor(at: Vector2) -> void:
	var screen := get_viewport().get_visible_rect()
	at = at.clamp(screen.position, screen.end - Vector2.ONE)
	Engine.set_meta(CURSOR_META, at)
	set_active(true)
	_cursor.position = at
	_cursor.visible = true
	_cursor.queue_redraw()
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var window_at := _to_window(at)
	# Le mouvement passe par Input : survols, aperçu de la tour, cadre de sélection
	# (A enfoncé) le voient comme celui d'une souris.
	var motion := InputEventMouseMotion.new()
	motion.position = window_at
	motion.global_position = window_at
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT if _a_held else 0
	_warped_to.append(at)
	if _warped_to.size() > 8:
		_warped_to.pop_front()
	Input.parse_input_event(motion)
	# Sur ordinateur, la vraie souris suit : le jeu lit sa position pour les survols.
	if DisplayServer.has_feature(DisplayServer.FEATURE_MOUSE_WARP) and DisplayServer.get_name() != "headless":
		Input.warp_mouse(window_at)


func hide_cursor() -> void:
	Engine.remove_meta(CURSOR_META)
	_cursor.visible = false
	if _a_held:
		_a_held = false
		_send_click(false)
	if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## La souris ou l'écran tactile reprend la main.
func _leave() -> void:
	set_active(false)
	if has_cursor():
		hide_cursor()


func _send_click(pressed: bool) -> void:
	var at := _to_window(get_cursor())
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = pressed
	click.position = at
	click.global_position = at
	click.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(click)
	if not pressed and _in_level():
		# En partie, le bouton cliqué (pause, vitesse...) ne garde pas le focus : la croix
		# continue de mener le pointeur.
		var focused := get_viewport().gui_get_focus_owner()
		if focused and focused.get_global_rect().has_point(get_cursor()):
			focused.release_focus()


func _is_own_motion(event: InputEventMouseMotion) -> bool:
	for at in _warped_to:
		if event.position.distance_to(at) < 2.0:
			return true
	return false


## En partie et sans menu ouvert (rien n'a le focus), la croix mène le pointeur.
func _steps_cursor() -> bool:
	if not _in_level():
		return false
	var focused := get_viewport().gui_get_focus_owner()
	return focused == null or not focused.is_visible_in_tree()


func _in_level() -> bool:
	return get_tree().current_scene is Level


func _start_position() -> Vector2:
	var focused := get_viewport().gui_get_focus_owner()
	if focused and focused.is_visible_in_tree():
		return focused.get_global_rect().get_center()
	return get_viewport().get_visible_rect().get_center()


func _to_window(at: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * at


static func _is_dpad(index: JoyButton) -> bool:
	return index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]


static func _dpad_direction(index: JoyButton) -> Vector2:
	match index:
		JOY_BUTTON_DPAD_UP:
			return Vector2.UP
		JOY_BUTTON_DPAD_DOWN:
			return Vector2.DOWN
		JOY_BUTTON_DPAD_LEFT:
			return Vector2.LEFT
	return Vector2.RIGHT


## Flèche au liseré cyan, la pointe sur la position du pointeur.
func _draw_cursor() -> void:
	var points := PackedVector2Array([Vector2(0, 0), Vector2(0, 24), Vector2(6, 18.5),
		Vector2(10.5, 27), Vector2(14.5, 25), Vector2(10.5, 17), Vector2(18, 16.5)])
	var outline := points.duplicate()
	outline.append(points[0])
	_cursor.draw_colored_polygon(points, Color(0.03, 0.06, 0.09, 0.92))
	_cursor.draw_polyline(outline, CURSOR_COLOR, 2.0, true)
	_cursor.draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 24, Color(CURSOR_COLOR, 0.45), 1.5, true)
