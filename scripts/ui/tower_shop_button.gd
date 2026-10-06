class_name TowerShopButton
extends Button
## Case de la barre d'achat : image de la tour, nom et prix. Toutes les cases ont la
## même taille, quel que soit le nom. Enfoncée quand la tour est choisie pour être posée.
## Le chiffre de sa touche (voir TowerShop) est rappelé en haut à gauche.

const SLOT_SIZE := Vector2(92, 80)
const ICON_SIZE := 40.0
## Transparence d'une case dont la tour est trop chère.
const UNAFFORDABLE_ALPHA := 0.45

var data: TowerData
## Touche qui choisit la case ("" = aucune).
var hotkey := ""

var _name_label: Label
var _price_label: Label
## Prix affiché, en or et en pierre (négatif : pas de pierre), refait au changement de langue.
var _cost := 0
var _stone := -1


func _init(tower_data: TowerData = null) -> void:
	data = tower_data
	custom_minimum_size = SLOT_SIZE
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	clip_contents = true


func _ready() -> void:
	_apply_styles()
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 2)
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
	_name_label = _add_label(column, data.display_name, _fit_font_size(tr(data.display_name), 13),
		data.color.lightened(0.35))
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_price_label = _add_label(column, "", 12, TowerInfoPanel.PRICE_COLOR)
	set_price(data.get_cost(), true)
	if not hotkey.is_empty():
		var key_label := _add_label(self, hotkey, 11, Color(1, 1, 1, 0.55))
		key_label.position = Vector2(5, 1)


## Taille de police (au plus `max_size`) pour que le nom tienne dans une case étroite
## (beaucoup de tours dans la barre) ; en dessous de 9, il est coupé.
func _fit_font_size(text_value: String, max_size: int) -> int:
	var font := get_theme_default_font()
	var width := custom_minimum_size.x - 6.0
	var font_size := max_size
	while font_size > 9 and font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		font_size -= 1
	return font_size


## Affiche le prix, en rouge et la case grisée s'il dépasse l'or disponible (ou la
## pierre, en mode Conquête : `stone` positif).
func set_price(cost: int, affordable: bool, stone := -1) -> void:
	_cost = cost
	_stone = stone
	if _price_label == null:
		return
	_refresh_price_text()
	_price_label.add_theme_color_override("font_color", TowerInfoPanel.PRICE_COLOR if affordable else TowerInfoPanel.TOO_EXPENSIVE_COLOR)
	modulate.a = 1.0 if affordable or button_pressed else UNAFFORDABLE_ALPHA


func _refresh_price_text() -> void:
	_price_label.text = tr("%d or") % _cost if _stone < 0 else tr("%d or · %d p") % [_cost, _stone]


## Changement de langue : le nom (traduit seul) peut demander une autre taille, et le prix se réécrit.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_name_label.add_theme_font_size_override("font_size", _fit_font_size(tr(data.display_name), 13))
		_refresh_price_text()


func _add_label(parent: Control, text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


## Case droite au liseré de la couleur de la tour (voir UiStyle.slot_styles()).
func _apply_styles() -> void:
	var styles := UiStyle.slot_styles(data.color)
	# Grisée faute d'or, la case garde son cadre (c'est son contenu qui pâlit).
	styles[&"disabled"] = styles[&"normal"]
	UiStyle.apply_styles(self, styles)
