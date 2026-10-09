class_name LockBubble
extends PanelContainer
## Bulle d'information à côté d'un bouton verrouillé : elle dit comment le débloquer
## (Unlocks.get_hint()). Elle s'affiche au survol, au focus (clavier, manette) et quand on
## appuie sur le bouton (écran tactile), et se cache quand on le quitte. Un écran en a une
## seule, partagée par ses boutons (watch()).

const COLOR := Color(1.0, 0.75, 0.2)
## Écart entre le bouton et la bulle, et marge au bord de l'écran.
const GAP := 14.0
const WIDTH := 320.0
## Assombrissement d'un bouton verrouillé (self_modulate : l'apparition des menus joue sur modulate).
const LOCKED_TINT := Color(0.65, 0.65, 0.65, 0.85)

var label: Label
## Bouton dont la bulle est affichée (null quand elle est cachée).
var button: Control
## La bulle de ce bouton s'ouvre en dessous plutôt qu'à côté.
var _below := {}


func _init() -> void:
	name = "LockBubble"
	top_level = true
	visible = false
	z_index = 20
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override(&"panel", UiStyle.panel(COLOR, 12.0, SIDE_LEFT, Color(UiStyle.PANEL_COLOR, 1.0)))
	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = WIDTH
	label.add_theme_font_size_override(&"font_size", 18)
	label.add_theme_color_override(&"font_color", UiStyle.TEXT_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


## Le bouton montre la bulle tant que `get_hint` renvoie un texte (le mode est verrouillé) :
## à côté, ou en dessous avec `below` (un bouton en haut de l'écran).
func watch(target: BaseButton, get_hint: Callable, below := false) -> void:
	if below:
		_below[target] = true
	var show_hint := func() -> void:
		var hint: String = get_hint.call()
		if not hint.is_empty():
			show_for(target, hint)
	target.mouse_entered.connect(show_hint)
	target.focus_entered.connect(show_hint)
	target.pressed.connect(show_hint)
	target.mouse_exited.connect(func() -> void:
		if not target.has_focus():
			hide_for(target))
	target.focus_exited.connect(hide_for.bind(target))
	target.visibility_changed.connect(func() -> void:
		if not target.is_visible_in_tree():
			hide_for(target))


func show_for(target: Control, text: String) -> void:
	button = target
	label.text = text
	visible = true
	reset_size()
	_place()


func hide_for(target: Control) -> void:
	if button == target:
		button = null
		visible = false


## Bouton assombri et marqué « Verrouillé » (sans être désactivé : il garde le focus et
## montre sa bulle quand on appuie dessus).
static func set_locked(target: Button, locked: bool) -> void:
	target.self_modulate = LOCKED_TINT if locked else Color.WHITE
	if locked:
		target.text += "  ·  " + target.tr("Verrouillé")


func _process(_delta: float) -> void:
	if visible:
		if not is_instance_valid(button) or not button.is_visible_in_tree():
			button = null
			visible = false
		else:
			_place()


## À droite du bouton (à gauche s'il n'y a pas la place) ou en dessous, sans sortir de l'écran.
func _place() -> void:
	var screen := get_viewport_rect().size
	var rect := button.get_global_rect()
	size = get_combined_minimum_size()
	var x := rect.end.x + GAP
	var y := rect.get_center().y - size.y / 2.0
	if _below.has(button):
		x = rect.get_center().x - size.x / 2.0
		y = rect.end.y + GAP
	elif x + size.x > screen.x - GAP:
		x = rect.position.x - GAP - size.x
	global_position = Vector2(clampf(x, GAP, maxf(GAP, screen.x - size.x - GAP)),
		clampf(y, GAP, maxf(GAP, screen.y - size.y - GAP)))
