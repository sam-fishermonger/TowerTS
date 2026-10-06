class_name TowerShopButton
extends Button
## Case de la barre d'achat : image de la tour, nom et prix. Toutes les cases ont la
## même taille, quel que soit le nom. Enfoncée quand la tour est choisie pour être posée.

const SLOT_SIZE := Vector2(92, 80)
const ICON_SIZE := 40.0
## Transparence d'une case dont la tour est trop chère.
const UNAFFORDABLE_ALPHA := 0.45

var data: TowerData

var _price_label: Label


func _init(tower_data: TowerData = null) -> void:
	data = tower_data
	custom_minimum_size = SLOT_SIZE
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	clip_contents = true


func _ready() -> void:
	_apply_styles()
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
	column.add_theme_constant_override("separation", 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	var icon_view := TowerIcon.new()
	icon_view.data = data
	icon_view.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icon_view)
	var name_label := _add_label(column, data.display_name, 13, data.color.lightened(0.35))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_price_label = _add_label(column, "", 12, TowerInfoPanel.PRICE_COLOR)
	set_price(data.get_cost(), true)


## Affiche le prix, en rouge et la case grisée s'il dépasse l'or disponible.
func set_price(cost: int, affordable: bool) -> void:
	if _price_label == null:
		return
	_price_label.text = "%d or" % cost
	_price_label.add_theme_color_override("font_color", TowerInfoPanel.PRICE_COLOR if affordable else TowerInfoPanel.TOO_EXPENSIVE_COLOR)
	modulate.a = 1.0 if affordable or button_pressed else UNAFFORDABLE_ALPHA


func _add_label(parent: Control, text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


## Fond sombre ; bordure de la couleur de la tour au survol, épaisse quand elle est choisie.
func _apply_styles() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.11, 0.12, 0.15)
	normal.set_border_width_all(2)
	normal.border_color = Color(1, 1, 1, 0.12)
	normal.set_corner_radius_all(6)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.15, 0.16, 0.2)
	hover.border_color = data.color
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = data.color.darkened(0.6)
	pressed.set_border_width_all(3)
	pressed.border_color = data.color.lightened(0.3)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("hover_pressed", pressed)
	add_theme_stylebox_override("disabled", normal)
