class_name BuildingInfoPanel
extends PanelContainer
## Mode Conquête : fiche d'un bâtiment posé, à côté de lui sur la carte. Son nom, ce qu'il
## fait, son chantier ou sa vie (tenus à jour), et le bouton Démolir, qui rend une part
## de son prix (tout pour un chantier).

signal demolish_requested(building: Building)
signal close_requested

const WIDTH := 300.0
const GAP := 8.0

## Zone de l'écran où la fiche doit rester (la carte).
var bounds := Rect2()
var building: Building
var conquest: Conquest

var _name_label: Label
var _description_label: Label
var _status_label: Label
var _demolish_button: Button


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
	_demolish_button = Button.new()
	_demolish_button.focus_mode = Control.FOCUS_NONE
	UiStyle.style_button(_demolish_button, Color(1.0, 0.5, 0.4))
	_demolish_button.pressed.connect(func() -> void: demolish_requested.emit(building))
	column.add_child(_demolish_button)


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
	_refresh()
	visible = true
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
		_status_label.text = "Vie : %d / %d" % [ceili(maxf(building.health, 0.0)), roundi(building.max_health)]
	else:
		_status_label.text = "En construction : %d %%" % floori(building.build_progress * 100.0)
	var refund := conquest.get_building_refund(building)
	_demolish_button.text = "Démolir  ·  +%d or" % refund.gold
	_demolish_button.disabled = conquest.level.is_over


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
