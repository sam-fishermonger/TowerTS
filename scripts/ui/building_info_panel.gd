class_name BuildingInfoPanel
extends PanelContainer
## Mode Conquête : fiche d'un bâtiment posé, à côté de lui sur la carte. Son nom, ce qu'il
## fait, son chantier ou sa vie (tenus à jour), et le bouton Démolir, qui rend une part
## de son prix (tout pour un chantier). Un Atelier bâti montre en plus ses améliorations
## (Research), par catégorie, chacune avec son niveau et le bouton qui la lance.

signal demolish_requested(building: Building)
signal close_requested
## Atelier : le joueur lance une amélioration.
signal research_requested(workshop: Building, id: StringName)

const WIDTH := 300.0
## Largeur de la fiche d'un Atelier, avec ses améliorations.
const WORKSHOP_WIDTH := 470.0
const RESEARCH_BUTTON_WIDTH := 124.0
const GAP := 8.0

## Zone de l'écran où la fiche doit rester (la carte).
var bounds := Rect2()
var building: Building
var conquest: Conquest

var _name_label: Label
var _description_label: Label
var _status_label: Label
var _demolish_button: Button
## Atelier : la recherche en cours, et les améliorations (une ligne chacune : id, nom,
## bouton).
var _research_box: VBoxContainer
var _research_status: Label
var _research_rows: Array[Dictionary] = []


func _ready() -> void:
	visible = false
	custom_minimum_size.x = WIDTH
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 6)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override(&"font_size", 18)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_name_label)
	var close_button := Button.new()
	close_button.text = "✕"
	close_button.flat = true
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close_requested.emit)
	header.add_child(close_button)
	_description_label = Label.new()
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.add_theme_font_size_override(&"font_size", 13)
	_description_label.add_theme_color_override(&"font_color", Color(1, 1, 1, 0.75))
	column.add_child(_description_label)
	_status_label = Label.new()
	_status_label.add_theme_font_size_override(&"font_size", 14)
	column.add_child(_status_label)
	_setup_research(column)
	_demolish_button = Button.new()
	_demolish_button.focus_mode = Control.FOCUS_NONE
	UiStyle.style_button(_demolish_button, Color(1.0, 0.5, 0.4))
	_demolish_button.pressed.connect(func() -> void: demolish_requested.emit(building))
	column.add_child(_demolish_button)


## Atelier : la recherche en cours, puis une ligne par amélioration, sous le titre de
## sa catégorie.
func _setup_research(column: VBoxContainer) -> void:
	_research_box = VBoxContainer.new()
	_research_box.add_theme_constant_override(&"separation", 3)
	_research_box.visible = false
	column.add_child(_research_box)
	_research_status = Label.new()
	_research_status.add_theme_font_size_override(&"font_size", 14)
	_research_status.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.45))
	_research_box.add_child(_research_status)
	for category in Research.CATEGORY_NAMES.size():
		var header := Label.new()
		header.text = Research.CATEGORY_NAMES[category]
		header.add_theme_font_size_override(&"font_size", 13)
		header.add_theme_color_override(&"font_color", Research.CATEGORY_COLORS[category])
		_research_box.add_child(header)
		for definition in Research.DEFINITIONS:
			if definition.category == category:
				_research_box.add_child(_make_research_row(definition))


func _make_research_row(definition: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override(&"separation", -2)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(texts)
	var name_label := Label.new()
	name_label.add_theme_font_size_override(&"font_size", 13)
	texts.add_child(name_label)
	var description := Label.new()
	description.text = definition.description
	description.add_theme_font_size_override(&"font_size", 11)
	description.add_theme_color_override(&"font_color", Color(1, 1, 1, 0.6))
	texts.add_child(description)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(RESEARCH_BUTTON_WIDTH, 0)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override(&"font_size", 12)
	UiStyle.style_button(button, Research.CATEGORY_COLORS[definition.category], 8.0, 8.0)
	var id: StringName = definition.id
	button.pressed.connect(func() -> void: research_requested.emit(building, id))
	row.add_child(button)
	_research_rows.append({id = id, name_label = name_label, button = button})
	return row


## Bouton d'une amélioration, pour les tests et les captures.
func get_research_button(id: StringName) -> Button:
	for row in _research_rows:
		if row.id == id:
			return row.button
	return null


func show_building(target: Building) -> void:
	building = target
	var definition := Building.get_definition(building.kind)
	var style := UiStyle.panel(definition.color, 12.0, SIDE_TOP, Color(0.03, 0.06, 0.09, 0.95))
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 6
	add_theme_stylebox_override(&"panel", style)
	_name_label.text = definition.name
	_name_label.add_theme_color_override(&"font_color", definition.color.lightened(0.3))
	_description_label.text = definition.description
	_description_label.visible = not _research_box.visible
	custom_minimum_size.x = WORKSHOP_WIDTH if building.kind == Building.Kind.WORKSHOP else WIDTH
	_refresh()
	visible = true
	size = Vector2.ZERO
	reset_size()
	_reposition()
	_reposition.call_deferred()


func close() -> void:
	building = null
	visible = false


func _process(_delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(building) or not building.is_alive:
		close()
		return
	_refresh()


## Chantier ou vie, et ce que rendrait la démolition.
func _refresh() -> void:
	if building.is_built():
		_status_label.text = tr("Vie : %d / %d") % [ceili(maxf(building.health, 0.0)), roundi(building.max_health)]
	else:
		_status_label.text = tr("En construction : %d %%") % floori(building.build_progress * 100.0)
	var refund := conquest.get_building_refund(building)
	_demolish_button.text = tr("Démolir  ·  +%d or") % refund.gold
	_demolish_button.disabled = conquest.level.is_over
	var shows_research := building.kind == Building.Kind.WORKSHOP and building.is_built()
	if shows_research != _research_box.visible:
		# Les améliorations disent ce que fait l'Atelier : sa description laisse la place.
		_research_box.visible = shows_research
		_description_label.visible = not shows_research
		_fit.call_deferred()
	if shows_research:
		_refresh_research()


## Atelier : recherche en cours, niveau de chaque amélioration et ce que coûte le suivant.
func _refresh_research() -> void:
	if building.research_id != &"":
		_research_status.text = tr("Recherche : %s, niveau %d  ·  %d s") % [
			tr(Research.get_definition(building.research_id).name), building.research_level, ceili(building.research_left)]
	else:
		_research_status.text = tr("Choisissez une amélioration à lancer.")
	for row in _research_rows:
		var id: StringName = row.id
		var level := conquest.get_research_level(id)
		var max_level := Research.get_max_level(id)
		var name_label: Label = row.name_label
		name_label.text = "%s  %s%s" % [tr(Research.get_definition(id).name), "●".repeat(level), "○".repeat(max_level - level)]
		var button: Button = row.button
		var blocker := conquest.research_blocker(building, id)
		var researching := conquest.get_researching_workshop(id)
		if level >= max_level:
			button.text = tr("Niveau max")
		elif researching:
			button.text = tr("En cours · %d s") % ceili(researching.research_left)
		else:
			button.text = Research.price_text(Research.get_cost(id, level + 1))
		button.disabled = blocker != ""
		button.tooltip_text = tr(blocker) if blocker != "" else ""


## Reprend sa taille la plus petite (le contenu a changé) et se replace.
func _fit() -> void:
	size = Vector2.ZERO
	reset_size()
	_reposition()


## À droite du bâtiment, ou à gauche s'il n'y a pas la place, dans la carte.
func _reposition() -> void:
	if not is_instance_valid(building):
		return
	var center := building.get_global_transform_with_canvas().origin
	var half := Building.SIZE / 2.0
	var at := Vector2(center.x + half + GAP, center.y - size.y / 2.0)
	if bounds.has_area() and at.x + size.x > bounds.end.x:
		at.x = center.x - half - GAP - size.x
	if bounds.has_area():
		at.y = clampf(at.y, bounds.position.y + GAP, maxf(bounds.end.y - size.y - GAP, bounds.position.y + GAP))
	position = at
