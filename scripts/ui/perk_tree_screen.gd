extends Control
## Arbre des améliorations permanentes (depuis l'écran titre) : chaque branche est une
## colonne, et une amélioration se débloque quand celles qui la précèdent sont achetées.
## Les étoiles gagnées sur les niveaux paient les achats ; « Réinitialiser » les rend.

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"
const NODE_SIZE := Vector2(156, 62)
## Écart entre deux colonnes, et en plus entre deux branches.
const COLUMN_STEP := 172.0
const BRANCH_GAP := 48.0
const ROW_STEP := 96.0
## Haut du premier rang, sous le nom des branches.
const FIRST_ROW_Y := 44.0

const OWNED_COLOR := Color(0.95, 0.78, 0.3)
const BUYABLE_COLOR := Color(0.45, 0.85, 0.45)
const TOO_EXPENSIVE_COLOR := Color(0.85, 0.45, 0.4)
const LOCKED_COLOR := Color(0.45, 0.48, 0.45)
const BRANCH_COLORS: Array[Color] = [Color(0.55, 0.75, 1.0), Color(1.0, 0.82, 0.35), Color(1.0, 0.5, 0.5)]

## Amélioration affichée dans l'encadré du bas (survol ou dernier clic).
var shown_perk: Perk
var _buttons := {}

@onready var tree: Control = %Tree
@onready var stars_label: Label = %StarsLabel
@onready var info_name: Label = %InfoName
@onready var info_description: Label = %InfoDescription
@onready var info_status: Label = %InfoStatus
@onready var back_button: Button = %BackButton
@onready var refund_button: Button = %RefundButton


func _ready() -> void:
	back_button.pressed.connect(go_back)
	refund_button.pressed.connect(_on_refund_pressed)
	tree.draw.connect(_draw_links)
	_build_tree()
	_refresh()
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()


func go_back() -> void:
	get_tree().change_scene_to_file(TITLE_SCREEN)


## Achète l'amélioration si c'est possible. Renvoie true si elle a été achetée.
func buy(perk: Perk) -> bool:
	shown_perk = perk
	var bought := Perks.buy(perk)
	if bought:
		Sound.play(&"upgrade")
	_refresh()
	return bought


func get_button(perk: Perk) -> Button:
	return _buttons.get(perk.id)


## Centre du haut de la case d'une amélioration, dans le repère de `tree`.
func get_node_position(perk: Perk) -> Vector2:
	var branch := floori(perk.column / 2.0)
	return Vector2(perk.column * COLUMN_STEP + branch * BRANCH_GAP, FIRST_ROW_Y + perk.row * ROW_STEP)


func _build_tree() -> void:
	# On centre l'arbre : sa largeur va de la colonne 0 à la dernière, plus une case.
	var width := 0.0
	for perk in Perks.TREE.perks:
		width = maxf(width, get_node_position(perk).x)
	tree.position.x = (get_viewport_rect().size.x - width - NODE_SIZE.x) / 2.0 + NODE_SIZE.x / 2.0
	for i in Perks.TREE.branch_names.size():
		var header := Label.new()
		header.text = Perks.TREE.branch_names[i]
		header.add_theme_font_size_override("font_size", 22)
		header.add_theme_color_override("font_color", BRANCH_COLORS[i % BRANCH_COLORS.size()])
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.size = Vector2(COLUMN_STEP * 2.0, 30)
		header.position = Vector2(i * (2.0 * COLUMN_STEP + BRANCH_GAP) + COLUMN_STEP / 2.0 - COLUMN_STEP, 0)
		tree.add_child(header)
	for perk in Perks.TREE.perks:
		var button := Button.new()
		button.size = NODE_SIZE
		button.position = get_node_position(perk) - Vector2(NODE_SIZE.x / 2.0, 0)
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(buy.bind(perk))
		button.mouse_entered.connect(_show_info.bind(perk))
		button.focus_entered.connect(_show_info.bind(perk))
		tree.add_child(button)
		_buttons[perk.id] = button


func _refresh() -> void:
	var available := Perks.get_available_stars()
	var spent := Perks.get_spent_stars()
	stars_label.text = "★ %d à dépenser   ·   %d dépensée%s   ·   arbre complet : %d" % [
		available, spent, "s" if spent > 1 else "", Perks.TREE.get_total_cost()]
	refund_button.disabled = spent == 0
	for perk in Perks.TREE.perks:
		_style_button(get_button(perk), perk, available)
	_show_info(shown_perk)
	tree.queue_redraw()


func _style_button(button: Button, perk: Perk, available: int) -> void:
	var color := _state_color(perk, available)
	var owned := Perks.is_owned(perk)
	var status: String
	if owned:
		status = "Acquis"
	elif Perks.is_unlocked(perk):
		status = "★ %d" % perk.cost
	else:
		status = "Verrouillé"
	button.text = "%s\n%s" % [perk.display_name, status]
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color.darkened(0.55 if owned else 0.8)
		if style_name == "hover":
			style.bg_color = style.bg_color.lightened(0.12)
		style.border_color = color if style_name != "focus" else Color.WHITE
		style.set_border_width_all(3 if owned or style_name == "focus" else 2)
		style.set_corner_radius_all(8)
		style.draw_center = style_name != "focus"
		button.add_theme_stylebox_override(style_name, style)
	button.add_theme_color_override("font_color", color.lightened(0.35))
	button.add_theme_color_override("font_hover_color", color.lightened(0.5))
	button.add_theme_color_override("font_focus_color", color.lightened(0.35))
	button.add_theme_color_override("font_pressed_color", color.lightened(0.35))


func _state_color(perk: Perk, available: int) -> Color:
	if Perks.is_owned(perk):
		return OWNED_COLOR
	if not Perks.is_unlocked(perk):
		return LOCKED_COLOR
	return BUYABLE_COLOR if available >= perk.cost else TOO_EXPENSIVE_COLOR


func _show_info(perk: Perk) -> void:
	shown_perk = perk
	if perk == null:
		info_name.text = "Améliorations permanentes"
		info_description.text = "Les étoiles gagnées sur les niveaux achètent des bonus pour toutes les parties."
		info_status.text = "Survoler une amélioration pour la voir, cliquer pour l'acheter."
		info_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
		return
	info_name.text = perk.display_name
	info_description.text = perk.description
	var available := Perks.get_available_stars()
	if Perks.is_owned(perk):
		info_status.text = "Acquis"
	elif not Perks.is_unlocked(perk):
		var missing: Array[String] = []
		for required in perk.requires:
			if not Perks.is_owned(required):
				missing.append(required.display_name)
		info_status.text = "Verrouillé : demande %s" % " et ".join(missing)
	elif available >= perk.cost:
		info_status.text = "Cliquer pour acheter  ·  ★ %d" % perk.cost
	else:
		info_status.text = "★ %d  ·  il manque %d étoile%s" % [perk.cost, perk.cost - available, "s" if perk.cost - available > 1 else ""]
	info_status.add_theme_color_override("font_color", _state_color(perk, available))


## Un trait de chaque amélioration vers celles qu'elle débloque, doré une fois acquise.
func _draw_links() -> void:
	for perk in Perks.TREE.perks:
		var to := get_node_position(perk)
		for required in perk.requires:
			var from := get_node_position(required) + Vector2(0, NODE_SIZE.y)
			var color := OWNED_COLOR if Perks.is_owned(required) else LOCKED_COLOR.darkened(0.3)
			var middle_y := (from.y + to.y) / 2.0
			tree.draw_polyline(PackedVector2Array([from, Vector2(from.x, middle_y), Vector2(to.x, middle_y), to]),
				color, 3.0)


func _on_refund_pressed() -> void:
	Perks.refund_all()
	Sound.play(&"sell")
	_refresh()
