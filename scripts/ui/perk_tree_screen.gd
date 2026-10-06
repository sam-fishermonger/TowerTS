extends Control
## Arbre des améliorations permanentes (depuis l'écran titre) : chaque branche est une
## colonne, et une amélioration se débloque quand celles qui la précèdent sont achetées.
## Les branches sont réparties en pages, avec un onglet par page : les bonus, puis les
## tours des mondes, dont chaque branche s'ouvre avec son monde, puis les spécialisations
## des tours.
## Les étoiles gagnées sur les niveaux paient les achats, et les étoiles infinies (mode
## infini) les spécialisations ; « Réinitialiser » les rend toutes.

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"
const NODE_SIZE := Vector2(156, 62)
## Écart entre deux colonnes, et en plus entre deux branches.
const COLUMN_STEP := 172.0
const BRANCH_GAP := 48.0
const ROW_STEP := 96.0
## Haut du premier rang, sous le nom des branches.
const FIRST_ROW_Y := 56.0
## Image de la tour dans la case d'une amélioration qui débloque une tour.
const TOWER_ICON_SIZE := 40.0
## Case plus large pour une tour : son image et son nom.
const TOWER_NODE_WIDTH := 200.0

const OWNED_COLOR := Color(0.95, 0.78, 0.3)
const BUYABLE_COLOR := Color(0.45, 0.85, 0.45)
const TOO_EXPENSIVE_COLOR := Color(0.85, 0.45, 0.4)
const LOCKED_COLOR := Color(0.45, 0.48, 0.45)
const ENDLESS_COLOR := Progress.ENDLESS_STAR_COLOR
const STARS_COLOR := Color(0.95, 0.85, 0.45)

## Amélioration affichée dans l'encadré du bas (survol ou dernier clic).
var shown_perk: Perk
## Page affichée (onglet).
var page := 0
var _buttons := {}
## Un conteneur par page, enfant de `tree`.
var _pages: Array[Control] = []
var _tabs: Array[Button] = []
var _lock_labels := {}

@onready var tree: Control = %Tree
@onready var tabs: HBoxContainer = %Tabs
@onready var stars_label: Label = %StarsLabel
@onready var info_name: Label = %InfoName
@onready var info_description: Label = %InfoDescription
@onready var info_status: Label = %InfoStatus
@onready var back_button: Button = %BackButton
@onready var refund_button: Button = %RefundButton


func _ready() -> void:
	back_button.pressed.connect(go_back)
	refund_button.pressed.connect(_on_refund_pressed)
	_build_tree()
	show_page(0)
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


## Affiche une page de l'arbre (onglet).
func show_page(index: int) -> void:
	page = clampi(index, 0, maxi(_pages.size() - 1, 0))
	for i in _pages.size():
		_pages[i].visible = i == page
		_tabs[i].set_pressed_no_signal(i == page)
	if shown_perk and Perks.TREE.get_page(shown_perk) != page:
		shown_perk = null
	_refresh()


## Centre du haut de la case d'une amélioration, dans le repère de sa page.
func get_node_position(perk: Perk) -> Vector2:
	var branch := Perks.TREE.get_branch(perk)
	var local_branch := Perks.TREE.get_page_branches(Perks.TREE.get_page(perk)).find(branch)
	var local_column := perk.column - 2.0 * (branch - local_branch)
	return Vector2(local_column * COLUMN_STEP + local_branch * BRANCH_GAP, FIRST_ROW_Y + perk.row * ROW_STEP)


func _build_tree() -> void:
	var tab_group := ButtonGroup.new()
	for page_index in maxi(Perks.TREE.page_names.size(), 1):
		var root := Control.new()
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tree.add_child(root)
		root.draw.connect(_draw_links.bind(root, page_index))
		_pages.append(root)
		_build_page(root, page_index)
		var tab := Button.new()
		tab.text = Perks.TREE.page_names[page_index] if page_index < Perks.TREE.page_names.size() else "Améliorations"
		tab.toggle_mode = true
		tab.button_group = tab_group
		tab.custom_minimum_size = Vector2(200, 36)
		tab.add_theme_font_size_override("font_size", 18)
		tab.pressed.connect(show_page.bind(page_index))
		tabs.add_child(tab)
		_tabs.append(tab)
	tabs.visible = _tabs.size() > 1


func _build_page(root: Control, page_index: int) -> void:
	var perks := Perks.TREE.get_page_perks(page_index)
	# On centre la page : sa largeur va de sa première colonne à la dernière, plus une case.
	var width := 0.0
	var node_width := 0.0
	for perk in perks:
		width = maxf(width, get_node_position(perk).x)
		node_width = maxf(node_width, _get_node_width(perk))
	root.position.x = (get_viewport_rect().size.x - width - node_width) / 2.0 + node_width / 2.0
	var branches := Perks.TREE.get_page_branches(page_index)
	for i in branches.size():
		var branch := branches[i]
		var x := i * (2.0 * COLUMN_STEP + BRANCH_GAP) + COLUMN_STEP / 2.0 - COLUMN_STEP
		var color := Perks.TREE.branch_colors[branch] if branch < Perks.TREE.branch_colors.size() else Color.WHITE
		var header := _add_label(root, Perks.TREE.branch_names[branch], 22, color, Vector2(x, 0))
		header.size = Vector2(COLUMN_STEP * 2.0, 30)
		# Sous le nom d'une branche liée à un monde : ce qu'il faut pour l'ouvrir.
		var lock := _add_label(root, "", 14, LOCKED_COLOR.lightened(0.3), Vector2(x, 28))
		lock.size = Vector2(COLUMN_STEP * 2.0, 20)
		_lock_labels[branch] = lock
	for perk in perks:
		var button := Button.new()
		button.size = Vector2(_get_node_width(perk), NODE_SIZE.y)
		button.position = get_node_position(perk) - Vector2(button.size.x / 2.0, 0)
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(buy.bind(perk))
		button.mouse_entered.connect(_show_info.bind(perk))
		button.focus_entered.connect(_show_info.bind(perk))
		if not perk.get_tower_path().is_empty():
			var icon := TowerIcon.new()
			icon.data = load(perk.get_tower_path())
			icon.size = Vector2.ONE * TOWER_ICON_SIZE
			icon.position = Vector2(8.0, (NODE_SIZE.y - TOWER_ICON_SIZE) / 2.0)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(icon)
		root.add_child(button)
		_buttons[perk.id] = button


func _add_label(parent: Control, text_value: String, font_size: int, color: Color, at: Vector2) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = at
	parent.add_child(label)
	return label


## La page se paie en étoiles infinies (spécialisations).
func is_endless_page(page_index: int) -> bool:
	for perk in Perks.TREE.get_page_perks(page_index):
		if perk.paid_with_endless_stars:
			return true
	return false


func _refresh() -> void:
	var endless := is_endless_page(page)
	var available := Perks.get_available_stars(endless)
	var spent := Perks.get_spent_stars(endless)
	stars_label.text = "%s★ %d à dépenser   ·   %d dépensée%s   ·   %s : %d" % [
		"∞ " if endless else "", available, spent, "s" if spent > 1 else "",
		"toutes les spécialisations" if endless else "arbre complet", Perks.TREE.get_total_cost(endless)]
	stars_label.add_theme_color_override("font_color", ENDLESS_COLOR if endless else STARS_COLOR)
	refund_button.disabled = Perks.get_owned_ids().is_empty()
	for perk in Perks.TREE.perks:
		_style_button(get_button(perk), perk)
	for branch in _lock_labels:
		_lock_labels[branch].text = _get_branch_lock_text(branch)
	_show_info(shown_perk)
	for root in _pages:
		root.queue_redraw()


## Les cases d'une tour (débloquée ou spécialisée) sont plus larges : elles montrent son image.
func _get_node_width(perk: Perk) -> float:
	return TOWER_NODE_WIDTH if not perk.get_tower_path().is_empty() else NODE_SIZE.x


## « Finir La Ruche pour l'ouvrir » si la branche attend un monde pas encore débloqué.
func _get_branch_lock_text(branch: int) -> String:
	for perk in Perks.TREE.perks:
		if Perks.TREE.get_branch(perk) == branch and not Perks.is_world_unlocked(perk):
			return "Finir %s pour l'ouvrir" % Perks.CAMPAIGN.worlds[perk.required_world - 1].display_name
	return ""


## Prix d'une amélioration : « ★ 3 », ou « ∞ ★ 3 » en étoiles infinies.
func _price_text(perk: Perk) -> String:
	return "%s★ %d" % ["∞ " if perk.paid_with_endless_stars else "", perk.cost]


func _style_button(button: Button, perk: Perk) -> void:
	var color := _state_color(perk)
	var owned := Perks.is_owned(perk)
	var status: String
	if owned:
		status = "Acquis"
	elif Perks.is_unlocked(perk):
		status = _price_text(perk)
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
		# Place pour l'image de la tour à gauche.
		if not perk.get_tower_path().is_empty():
			style.content_margin_left = TOWER_ICON_SIZE + 12.0
		button.add_theme_stylebox_override(style_name, style)
	for icon in button.get_children():
		icon.modulate.a = 1.0 if owned or Perks.is_unlocked(perk) else 0.4
	button.add_theme_color_override("font_color", color.lightened(0.35))
	button.add_theme_color_override("font_hover_color", color.lightened(0.5))
	button.add_theme_color_override("font_focus_color", color.lightened(0.35))
	button.add_theme_color_override("font_pressed_color", color.lightened(0.35))


func _state_color(perk: Perk) -> Color:
	var available := Perks.get_available_stars(perk.paid_with_endless_stars)
	if Perks.is_owned(perk):
		return OWNED_COLOR
	if not Perks.is_unlocked(perk):
		return LOCKED_COLOR
	return BUYABLE_COLOR if available >= perk.cost else TOO_EXPENSIVE_COLOR


func _show_info(perk: Perk) -> void:
	shown_perk = perk
	if perk == null and is_endless_page(page):
		info_name.text = "Spécialisations"
		info_description.text = ("Les étoiles infinies, gagnées en mode infini (ouvert sur chaque niveau gagné avec "
			+ "3 étoiles), donnent à une tour un atout de plus, dans toutes les parties.")
		info_status.text = "Survoler une spécialisation pour la voir, cliquer pour l'acheter."
		info_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
		return
	if perk == null:
		info_name.text = "Améliorations permanentes"
		info_description.text = "Les étoiles gagnées sur les niveaux achètent des bonus pour toutes les parties."
		info_status.text = "Survoler une amélioration pour la voir, cliquer pour l'acheter."
		info_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
		return
	info_name.text = perk.display_name
	info_description.text = perk.description
	var available := Perks.get_available_stars(perk.paid_with_endless_stars)
	var missing_count := perk.cost - available
	var unit := "étoile" + ("s" if missing_count > 1 else "")
	if perk.paid_with_endless_stars:
		unit += " infinie" + ("s" if missing_count > 1 else "")
	if Perks.is_owned(perk):
		info_status.text = "Acquis"
	elif not Perks.is_world_unlocked(perk):
		info_status.text = "Verrouillé : finir %s pour ouvrir %s" % [
			Perks.CAMPAIGN.worlds[perk.required_world - 1].display_name, Perks.get_required_world_name(perk)]
	elif not Perks.is_unlocked(perk):
		var missing: Array[String] = []
		for required in perk.requires:
			if not Perks.is_owned(required):
				missing.append(required.display_name)
		info_status.text = "Verrouillé : demande %s" % " et ".join(missing)
	elif available >= perk.cost:
		info_status.text = "Cliquer pour acheter  ·  %s" % _price_text(perk)
	else:
		info_status.text = "%s  ·  il manque %d %s" % [_price_text(perk), missing_count, unit]
	info_status.add_theme_color_override("font_color", _state_color(perk))


## Un trait de chaque amélioration vers celles qu'elle débloque, doré une fois acquise.
func _draw_links(root: Control, page_index: int) -> void:
	for perk in Perks.TREE.get_page_perks(page_index):
		var to := get_node_position(perk)
		for required in perk.requires:
			# Une tour à débloquer sur une autre page : pas de trait, la fiche le dit.
			if Perks.TREE.get_page(required) != page_index:
				continue
			var from := get_node_position(required) + Vector2(0, NODE_SIZE.y)
			var color := OWNED_COLOR if Perks.is_owned(required) else LOCKED_COLOR.darkened(0.3)
			var middle_y := (from.y + to.y) / 2.0
			root.draw_polyline(PackedVector2Array([from, Vector2(from.x, middle_y), Vector2(to.x, middle_y), to]),
				color, 3.0)


func _on_refund_pressed() -> void:
	Perks.refund_all()
	Sound.play(&"sell")
	_refresh()
