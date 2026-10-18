class_name UiMotion
extends Node
## Mouvement de l'interface : ce qui la rend vivante sans toucher à son style (UiStyle).
## - Chaque bouton grossit un peu au survol ou au focus (clavier, manette) et s'enfonce
##   quand on appuie dessus.
## - À chaque changement d'écran, un voile sombre se lève et les panneaux de l'écran
##   apparaissent l'un après l'autre (sauf si l'écran a sa propre apparition, OWN_INTRO_META).
## - Des effets à appeler : pop() (une valeur qui change, un panneau qui s'ouvre).
##
## Le nœud est chargé au démarrage (autoload « Animations »). Les effets jouent en temps
## réel : ils gardent la même durée en x3 et pendant la pause.

## Méta d'un bouton : agrandissement au survol (float), à la place de HOVER_SCALE.
const HOVER_SCALE_META := &"ui_hover_scale"
## Méta d'un écran qui joue lui-même son apparition (l'écran titre) : seul le voile se lève.
const OWN_INTRO_META := &"ui_own_intro"
## Méta posée sur les boutons déjà branchés (un nœud déplacé repasse par node_added).
const HOOKED_META := &"ui_motion_hooked"

const HOVER_SCALE := 1.04
const HOVER_DURATION := 0.12
const PRESS_SCALE := 0.94
const PRESS_DURATION := 0.06
const RELEASE_DURATION := 0.3
## Voile du changement d'écran.
const CURTAIN_COLOR := Color(0.01, 0.03, 0.05)
const CURTAIN_DURATION := 0.3
## Apparition des panneaux d'un écran : durée, décalage entre deux panneaux, taille de départ.
const ENTRANCE_DURATION := 0.38
const ENTRANCE_STAGGER := 0.06
const ENTRANCE_SCALE := 0.96

var _curtain: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	# Sous le pointeur de la manette (127), au-dessus de tout le reste.
	layer.layer = 126
	add_child(layer)
	_curtain = ColorRect.new()
	_curtain.color = CURTAIN_COLOR
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_curtain.visible = false
	layer.add_child(_curtain)
	get_tree().node_added.connect(_on_node_added)
	get_tree().scene_changed.connect(_on_scene_changed)


func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.has_meta(HOOKED_META):
		_hook_button(node)


func _hook_button(button: BaseButton) -> void:
	button.set_meta(HOOKED_META, true)
	button.mouse_entered.connect(_on_button_hovered.bind(button, true))
	button.focus_entered.connect(_on_button_hovered.bind(button, true))
	button.mouse_exited.connect(_on_button_hovered.bind(button, false))
	button.focus_exited.connect(_on_button_hovered.bind(button, false))
	button.button_down.connect(_on_button_down.bind(button))
	button.button_up.connect(_on_button_up.bind(button))


static func _rest_scale(button: BaseButton) -> float:
	var hovered := button.is_hovered() or button.has_focus()
	return float(button.get_meta(HOVER_SCALE_META, HOVER_SCALE)) if hovered and not button.disabled else 1.0


func _on_button_hovered(button: BaseButton, entered: bool) -> void:
	if entered and button.disabled:
		return
	# Le survol peut finir après la sortie de la souris (focus) : on recalcule l'état réel.
	_scale_to(button, _rest_scale(button) if not entered else float(button.get_meta(HOVER_SCALE_META, HOVER_SCALE)),
		HOVER_DURATION, Tween.TRANS_QUAD)


func _on_button_down(button: BaseButton) -> void:
	_scale_to(button, PRESS_SCALE, PRESS_DURATION, Tween.TRANS_QUAD)


func _on_button_up(button: BaseButton) -> void:
	_scale_to(button, _rest_scale(button), RELEASE_DURATION, Tween.TRANS_BACK)


static func _scale_to(control: Control, target: float, duration: float, transition: Tween.TransitionType) -> void:
	if not control.is_inside_tree():
		return
	control.pivot_offset = control.size / 2.0
	var tween := _real_time_tween(control, &"_ui_scale_tween")
	tween.tween_property(control, "scale", Vector2.ONE * target, duration) \
		.set_trans(transition).set_ease(Tween.EASE_OUT)


## Tween en temps réel, qui joue aussi pendant la pause. Le précédent tween du même nom
## sur ce nœud est arrêté (deux effets du même genre ne se battent pas).
static func _real_time_tween(node: Node, slot: StringName) -> Tween:
	var previous: Tween = node.get_meta(slot) if node.has_meta(slot) else null
	if previous and previous.is_valid():
		previous.kill()
	var tween := node.create_tween().set_ignore_time_scale().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	node.set_meta(slot, tween)
	return tween


## Petit bond : le nœud grossit d'un coup puis revient à sa taille (une valeur qui change).
## `tint` colore le nœud le temps du bond (blanc = sans couleur).
static func pop(control: Control, strength := 1.2, duration := 0.35, tint := Color.WHITE) -> void:
	if not control.is_inside_tree():
		return
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2.ONE * strength
	var tween := _real_time_tween(control, &"_ui_scale_tween").set_parallel()
	tween.tween_property(control, "scale", Vector2.ONE, duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if tint != Color.WHITE:
		control.self_modulate = tint
		tween.tween_property(control, "self_modulate", Color.WHITE, duration)


## Apparition d'un panneau : il grandit un peu en devenant opaque. `delay` en secondes.
static func appear(control: Control, delay := 0.0, duration := ENTRANCE_DURATION, from_scale := ENTRANCE_SCALE) -> void:
	if not control.is_inside_tree():
		return
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2.ONE * from_scale
	control.modulate.a = 0.0
	var tween := _real_time_tween(control, &"_ui_appear_tween").set_parallel()
	tween.tween_property(control, "scale", Vector2.ONE, duration).set_delay(delay) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, duration * 0.7).set_delay(delay)


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	_curtain.visible = true
	_curtain.modulate.a = 1.0
	var tween := _real_time_tween(_curtain, &"_ui_curtain_tween")
	tween.tween_property(_curtain, "modulate:a", 0.0, CURTAIN_DURATION).set_ease(Tween.EASE_IN)
	tween.tween_callback(_curtain.hide)
	if scene is Control and not scene.has_meta(OWN_INTRO_META):
		# Une image plus tard : les conteneurs ont placé leurs enfants (pivot au bon centre).
		await get_tree().process_frame
		if is_instance_valid(scene):
			_play_entrance(scene)


## Les panneaux de l'écran apparaissent l'un après l'autre, de haut en bas puis de gauche
## à droite. Le fond reste en place ; un conteneur aussi large que l'écran laisse
## apparaître ses enfants un par un.
func _play_entrance(screen: Control) -> void:
	var parts: Array[Control] = []
	_collect_parts(screen, screen.size.x * 0.98, 3, parts)
	parts.sort_custom(func(a: Control, b: Control) -> bool:
		var pa := a.global_position.snapped(Vector2(1, 40))
		var pb := b.global_position.snapped(Vector2(1, 40))
		return pa.y < pb.y or (pa.y == pb.y and pa.x < pb.x))
	for i in parts.size():
		appear(parts[i], i * ENTRANCE_STAGGER)


static func _collect_parts(parent: Node, full_width: float, depth: int, parts: Array[Control]) -> void:
	for child in parent.get_children():
		var control := child as Control
		if control == null or not control.visible or control is UiBackdrop or control is SubViewportContainer:
			continue
		if control.size.x < full_width:
			parts.append(control)
		elif depth > 0 and not (control is ColorRect or control is TextureRect):
			_collect_parts(control, full_width, depth - 1, parts)
