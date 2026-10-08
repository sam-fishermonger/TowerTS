class_name ChestChoice
extends Control
## Mode Expédition : un coffre ouvert propose jusqu'à trois bonus (ChestBonus), et le
## joueur en garde un pour toute l'expédition. Couvre tout l'écran ; la partie est en pause
## jusqu'au choix (clic, ou touches 1, 2, 3).

## Émis avec l'identifiant du bonus choisi.
signal chosen(id: StringName)

const CARD_SIZE := Vector2(250, 150)

## Bonus proposés, dans l'ordre des cartes.
var choices: Array[StringName] = []
var _buttons: Array[Button] = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS


## `levels` : bonus déjà gagnés pendant l'expédition (exemplaires par identifiant).
func setup(bonus_ids: Array[StringName], levels: Dictionary) -> void:
	choices = bonus_ids.duplicate()
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel",
		UiStyle.panel(ChestBonus.COLOR, 20.0, SIDE_TOP, Color(0.03, 0.06, 0.09, 0.97)))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	panel.add_child(column)
	_add_label(column, tr("Coffre : choisissez un bonus"), 28, ChestBonus.COLOR)
	_add_label(column, tr("Il est gardé jusqu'à la fin de l'expédition."), 16, Color(1, 1, 1, 0.75))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 14)
	column.add_child(row)
	for i in choices.size():
		var button := _make_card(i, ChestBonus.get_definition(choices[i]), levels.get(choices[i], 0))
		row.add_child(button)
		_buttons.append(button)
	if not _buttons.is_empty():
		_buttons[0].grab_focus.call_deferred()


func get_buttons() -> Array[Button]:
	return _buttons


func choose(index: int) -> void:
	if index >= 0 and index < choices.size():
		chosen.emit(choices[index])


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	# Position physique : en AZERTY, la rangée 1, 2, 3 donne « & é " » sans Maj.
	var index := [KEY_1, KEY_2, KEY_3].find(key.physical_keycode)
	if index < 0:
		index = [KEY_KP_1, KEY_KP_2, KEY_KP_3].find(key.keycode)
	if index >= 0 and index < choices.size():
		get_viewport().set_input_as_handled()
		choose(index)


## Carte d'un bonus : touche, nom, effet, et exemplaires déjà gagnés.
func _make_card(index: int, definition: Dictionary, owned: int) -> Button:
	var color: Color = definition.color
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	UiStyle.style_button(button, color, 14.0, 14.0, false)
	button.pressed.connect(choose.bind(index))
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(column)
	_add_label(column, "%d" % (index + 1), 14, Color(1, 1, 1, 0.5))
	_add_label(column, tr(definition.name), 22, color)
	var description := _add_label(column, tr(definition.description), 15, UiStyle.TEXT_COLOR)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = CARD_SIZE.x - 28.0
	var total := tr("Déjà : %s") % ChestBonus.describe_total(definition.id, owned) if owned > 0 \
		else tr("Nouveau")
	_add_label(column, "%s  ·  %d / %d" % [total, owned + 1, definition.max], 13, Color(1, 1, 1, 0.6))
	return button


func _add_label(parent: Control, text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	parent.add_child(label)
	return label
