class_name TowerPicker
extends Control
## Choix des tours au lancement d'un niveau, quand plus de tours sont débloquées que la
## difficulté n'en permet (Difficulty.TOWER_LIMITS) : une case par tour, on en coche
## jusqu'à `limit`, puis Jouer. Le survol d'une case affiche la fiche de la tour.
## Couvre tout l'écran : la partie ne commence pas avant le choix.

## Émis avec les tours cochées, dans l'ordre des cases.
signal confirmed(types: Array[TowerData])
signal menu_requested

const TOWER_INFO_PANEL := preload("res://scenes/ui/tower_info_panel.tscn")
const SLOT_SIZE := Vector2(112, 84)
const COLUMNS := 5

var limit := 1
var _buttons: Array[TowerShopButton] = []

var _count_label: Label
var _play_button: Button
var _info: TowerInfoPanel


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## `available` : les tours du niveau puis celles de l'arbre ; `selected` : celles déjà
## cochées (le dernier choix) ; `difficulty_name` pour l'explication.
func setup(available: Array[TowerData], tower_limit: int, selected: Array[TowerData], difficulty_name: String) -> void:
	limit = tower_limit
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var style := UiStyle.panel(UiStyle.ACCENT, 20.0, SIDE_TOP, Color(0.03, 0.06, 0.09, 0.97))
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	_add_label(column, "Choisir les tours", 28, Color(0.95, 0.85, 0.45))
	_add_label(column, "%s : %d tours différentes au plus dans ce niveau, sur les %d débloquées." % [
		difficulty_name, limit, available.size()], 16, Color(1, 1, 1, 0.75))
	var grid := GridContainer.new()
	grid.columns = mini(COLUMNS, available.size())
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(grid)
	for data in available:
		var button := TowerShopButton.new(data)
		button.custom_minimum_size = SLOT_SIZE
		button.button_pressed = selected.has(data)
		button.toggled.connect(func(_on: bool) -> void: _refresh())
		button.mouse_entered.connect(_show_info.bind(button))
		button.mouse_exited.connect(func() -> void: _info.close())
		grid.add_child(button)
		_buttons.append(button)
	_count_label = _add_label(column, "", 18, Color.WHITE)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	column.add_child(actions)
	var menu_button := Button.new()
	menu_button.text = "Menu"
	menu_button.custom_minimum_size = Vector2(140, 40)
	menu_button.pressed.connect(menu_requested.emit)
	actions.add_child(menu_button)
	_play_button = Button.new()
	_play_button.text = "Jouer"
	_play_button.custom_minimum_size = Vector2(180, 40)
	_play_button.add_theme_font_size_override("font_size", 20)
	_play_button.pressed.connect(confirm)
	actions.add_child(_play_button)

	_info = TOWER_INFO_PANEL.instantiate()
	add_child(_info)
	_refresh()


## Tours cochées, dans l'ordre des cases.
func get_selected() -> Array[TowerData]:
	var result: Array[TowerData] = []
	for button in _buttons:
		if button.button_pressed:
			result.append(button.data)
	return result


func get_button(data: TowerData) -> TowerShopButton:
	for button in _buttons:
		if button.data == data:
			return button
	return null


## Coche ou décoche une tour (sans effet au-delà de la limite).
func set_tower_selected(data: TowerData, value: bool) -> void:
	var button := get_button(data)
	if button and not (value and not button.button_pressed and get_selected().size() >= limit):
		button.button_pressed = value


func can_confirm() -> bool:
	var count := get_selected().size()
	return count >= 1 and count <= limit


func confirm() -> void:
	if can_confirm():
		confirmed.emit(get_selected())


func _refresh() -> void:
	var count := get_selected().size()
	# Limite atteinte : les autres cases sont grisées jusqu'à ce qu'on en décoche une.
	for button in _buttons:
		button.disabled = count >= limit and not button.button_pressed
		button.set_price(button.data.get_cost(), true)
		button.modulate.a = TowerShopButton.UNAFFORDABLE_ALPHA if button.disabled else 1.0
	_count_label.text = "%d / %d tours choisies" % [count, limit]
	_count_label.add_theme_color_override("font_color",
		Color(0.55, 0.95, 0.55) if count == limit else Color(1, 1, 1, 0.8))
	_play_button.disabled = not can_confirm()


func _show_info(button: TowerShopButton) -> void:
	_info.bounds = get_viewport_rect()
	_info.show_tower_type(button.data, 1 << 30, button.get_global_rect())


func _add_label(parent: Control, text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label
