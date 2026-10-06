class_name BuildingShop
extends PanelContainer
## Mode Conquête : barre des bâtiments, ouverte au-dessus de la barre d'achat par le
## bouton « Bâtiments » (ou la touche B). Une case par bâtiment (Building) : son dessin,
## son nom et son prix ; une seule peut être enfoncée (le bâtiment à poser), et celles
## qu'on ne peut pas payer sont grisées. Tant qu'elle est ouverte, les touches 1 à 5
## choisissent ses cases.

## Émis quand le joueur choisit un bâtiment à poser (-1 = aucun).
signal building_selected(kind: int)

const ICON_SIZE := 38.0

var _group := ButtonGroup.new()
var _buttons: Array[Button] = []
var _price_labels: Array[Label] = []


func _ready() -> void:
	_group.allow_unpress = true
	add_theme_stylebox_override(&"panel", UiStyle.panel(Color(Conquest.STONE_COLOR, 0.6), 6.0, SIDE_TOP))
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	add_child(row)
	for kind in Building.DEFINITIONS.size():
		row.add_child(_make_button(kind))


func _make_button(kind: int) -> Button:
	var definition := Building.get_definition(kind)
	var button := Button.new()
	button.custom_minimum_size = TowerShopButton.SLOT_SIZE
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.button_group = _group
	button.clip_contents = true
	button.tooltip_text = "%s\n%s" % [definition.name, definition.description]
	var styles := UiStyle.slot_styles(definition.color)
	styles[&"disabled"] = styles[&"normal"]
	UiStyle.apply_styles(button, styles)
	button.pressed.connect(_on_button_pressed)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 2)
	column.add_theme_constant_override(&"separation", 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(column)
	var icon := BuildingIcon.new()
	icon.kind = kind
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	_add_label(column, definition.name, 13, definition.color.lightened(0.35))
	_price_labels.append(_add_label(column, _price_text(definition), 11, TowerInfoPanel.PRICE_COLOR))
	var key := _add_label(button, str(kind + 1), 11, Color(1, 1, 1, 0.55))
	key.position = Vector2(5, 1)
	_buttons.append(button)
	return button


## Prix d'un bâtiment, sur une ligne : « 90 or · 40 p · 4 e ».
static func _price_text(definition: Dictionary) -> String:
	if definition.essence > 0:
		return "%d or · %d p · %d e" % [definition.gold, definition.stone, definition.essence]
	return "%d or · %d p" % [definition.gold, definition.stone]


func _add_label(parent: Control, text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


## Grise les bâtiments qu'on ne peut pas payer (sauf celui choisi).
func refresh(gold: int, stone: int, essence: int) -> void:
	for kind in _buttons.size():
		var definition := Building.get_definition(kind)
		var affordable: bool = gold >= definition.gold and stone >= definition.stone and essence >= definition.essence
		var button := _buttons[kind]
		button.disabled = not affordable and not button.button_pressed
		button.modulate.a = 1.0 if affordable or button.button_pressed else TowerShopButton.UNAFFORDABLE_ALPHA
		_price_labels[kind].add_theme_color_override(&"font_color",
			TowerInfoPanel.PRICE_COLOR if affordable else TowerInfoPanel.TOO_EXPENSIVE_COLOR)


## Enfonce la case du bâtiment donné (-1 = aucune), sans émettre building_selected.
func set_selected(kind: int) -> void:
	for i in _buttons.size():
		_buttons[i].set_pressed_no_signal(i == kind)


## Choisit le bâtiment de la case donnée, ou le repose s'il était déjà choisi.
func toggle_slot(index: int) -> void:
	if index < 0 or index >= _buttons.size() or _buttons[index].disabled:
		return
	building_selected.emit(-1 if _buttons[index].button_pressed else index)


func get_button(kind: int) -> Button:
	return _buttons[kind]


func _on_button_pressed() -> void:
	var pressed := _group.get_pressed_button()
	building_selected.emit(_buttons.find(pressed) if pressed else -1)


## Dessin d'un bâtiment dans une case (Building.draw_icon).
class BuildingIcon:
	extends Control

	var kind := 0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		Building.draw_icon(self, kind, size / 2.0, minf(size.x, size.y))
