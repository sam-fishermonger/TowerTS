class_name LevelEditor
extends Control
## Éditeur de niveau : on trace le chemin des ennemis sur la grille, on pose des
## rochers, on compose les vagues, puis on joue. Les niveaux du joueur sont enregistrés
## avec la progression (CustomLevel) ; l'onglet Niveaux en crée, en ouvre, et les partage
## sous forme de code à copier-coller. Une partie finie ramène ici.

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"
const BASE_TEXTURE: Texture2D = preload("res://assets/sprites/map/base.svg")
const ROCK_TEXTURE: Texture2D = preload("res://assets/sprites/map/rock.svg")
const BAR_HEIGHT := 64.0
const BOTTOM_HEIGHT := 96.0
const ERROR_COLOR := Color(1.0, 0.55, 0.45)
const HINT_COLOR := Color(0.8, 0.85, 0.8)
const READY_COLOR := Color(0.55, 1.0, 0.6)
const START_COLOR := Color(0.45, 0.9, 0.5)

enum EditTool { PATH, ROCKS }
enum Tab { LEVELS, MAP, WAVES }

## Niveaux du joueur (voir CustomLevel), et le rang de celui qui est ouvert.
var levels: Array[Dictionary] = []
var current := 0
## Niveau ouvert (un élément de levels).
var data: Dictionary
var current_tab := Tab.MAP
var current_tool := EditTool.PATH
## Monstres proposés dans les vagues, dans l'ordre des listes.
var enemy_choices: Array[EnemyData] = []

var map_view: Control
var waves_view: ScrollContainer
var waves_list: VBoxContainer
var levels_view: VBoxContainer
var levels_list: VBoxContainer
var import_edit: LineEdit
var name_edit: LineEdit
var levels_tab: Button
var map_tab: Button
var waves_tab: Button
var path_tool_button: Button
var rocks_tool_button: Button
var clear_button: Button
var biome_option: OptionButton
var gold_spin: SpinBox
var lives_spin: SpinBox
var status_label: Label
var play_button: Button
var back_button: Button

## Rochers : le glisser pose (true) ou enlève (false), selon la première case.
var _painting_rocks := true
var _dragging := false
## Niveau dont la suppression attend une confirmation (deuxième clic), ou -1.
var _pending_delete := -1
## Message passager (code copié, import raté...) affiché en bas jusqu'à la prochaine action.
var _notice := ""
var _notice_is_error := false


func _ready() -> void:
	levels = CustomLevel.load_all()
	current = CustomLevel.load_current_index(levels.size())
	data = levels[current]
	enemy_choices = CustomLevel.get_enemy_choices()
	_build()
	_refresh()
	play_button.grab_focus()


func _exit_tree() -> void:
	_save()


func _save() -> void:
	CustomLevel.save_all(levels, current)


# --- Construction de l'écran ----------------------------------------------------

func _build() -> void:
	var background := ColorRect.new()
	background.color = Color(0.11, 0.15, 0.11)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var top := HBoxContainer.new()
	top.position = Vector2(16, 10)
	top.size = Vector2(1248, 44)
	top.add_theme_constant_override("separation", 10)
	add_child(top)
	# Le nom du niveau ouvert, qu'on modifie sur place.
	name_edit = LineEdit.new()
	name_edit.custom_minimum_size = Vector2(250, 0)
	name_edit.max_length = CustomLevel.MAX_NAME_LENGTH
	name_edit.tooltip_text = "Nom du niveau"
	name_edit.add_theme_font_size_override("font_size", 22)
	name_edit.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	name_edit.text_changed.connect(func(text: String) -> void: data.name = text)
	name_edit.text_submitted.connect(func(text: String) -> void:
		rename_level(text)
		name_edit.release_focus())
	name_edit.focus_exited.connect(func() -> void: rename_level(name_edit.text))
	top.add_child(name_edit)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var tabs := ButtonGroup.new()
	levels_tab = _make_toggle("Niveaux", tabs, top)
	levels_tab.pressed.connect(show_tab.bind(Tab.LEVELS))
	map_tab = _make_toggle("Carte", tabs, top)
	map_tab.button_pressed = true
	map_tab.pressed.connect(show_tab.bind(Tab.MAP))
	waves_tab = _make_toggle("Vagues", tabs, top)
	waves_tab.pressed.connect(show_tab.bind(Tab.WAVES))
	top.add_child(_make_label("  Monde"))
	biome_option = OptionButton.new()
	for name in CustomLevel.get_biome_names():
		biome_option.add_item(name)
	biome_option.item_selected.connect(func(index: int) -> void:
		data.biome = index
		_refresh())
	top.add_child(biome_option)
	top.add_child(_make_label("  Or"))
	gold_spin = _make_spin(CustomLevel.MIN_GOLD, CustomLevel.MAX_GOLD, 10, top)
	gold_spin.value_changed.connect(func(value: float) -> void: data.gold = int(value))
	top.add_child(_make_label("  Vies"))
	lives_spin = _make_spin(CustomLevel.MIN_LIVES, CustomLevel.MAX_LIVES, 1, top)
	lives_spin.value_changed.connect(func(value: float) -> void: data.lives = int(value))

	map_view = Control.new()
	map_view.position = Vector2(0, BAR_HEIGHT)
	map_view.size = Vector2(CustomLevel.COLUMNS, CustomLevel.ROWS) * CustomLevel.CELL_SIZE
	map_view.mouse_filter = Control.MOUSE_FILTER_STOP
	map_view.draw.connect(_draw_map)
	map_view.gui_input.connect(_on_map_input)
	add_child(map_view)

	waves_view = ScrollContainer.new()
	waves_view.position = Vector2(16, BAR_HEIGHT + 8)
	waves_view.size = Vector2(1248, map_view.size.y - 16)
	waves_view.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	waves_view.visible = false
	add_child(waves_view)
	waves_list = VBoxContainer.new()
	waves_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	waves_list.add_theme_constant_override("separation", 8)
	waves_view.add_child(waves_list)

	_build_levels_view()

	var bottom := HBoxContainer.new()
	bottom.position = Vector2(16, BAR_HEIGHT + map_view.size.y + 18)
	bottom.size = Vector2(1248, 60)
	bottom.add_theme_constant_override("separation", 12)
	add_child(bottom)
	back_button = Button.new()
	back_button.text = "Retour"
	back_button.custom_minimum_size = Vector2(140, 52)
	back_button.add_theme_font_size_override("font_size", 22)
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(TITLE_SCREEN))
	bottom.add_child(back_button)
	var tools := ButtonGroup.new()
	path_tool_button = _make_toggle("Chemin", tools, bottom)
	path_tool_button.button_pressed = true
	path_tool_button.pressed.connect(set_tool.bind(EditTool.PATH))
	rocks_tool_button = _make_toggle("Rochers", tools, bottom)
	rocks_tool_button.pressed.connect(set_tool.bind(EditTool.ROCKS))
	clear_button = Button.new()
	clear_button.custom_minimum_size = Vector2(0, 44)
	clear_button.pressed.connect(_on_clear_pressed)
	bottom.add_child(clear_button)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 16)
	bottom.add_child(status_label)
	play_button = Button.new()
	play_button.text = "Jouer"
	play_button.custom_minimum_size = Vector2(180, 52)
	play_button.add_theme_font_size_override("font_size", 26)
	play_button.pressed.connect(play)
	bottom.add_child(play_button)


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	return label


func _make_toggle(text: String, group: ButtonGroup, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_group = group
	button.custom_minimum_size = Vector2(110, 44)
	button.add_theme_font_size_override("font_size", 18)
	parent.add_child(button)
	return button


func _make_spin(minimum: int, maximum: int, step: int, parent: Control) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step
	spin.custom_minimum_size = Vector2(100, 0)
	parent.add_child(spin)
	return spin


func set_tool(edit_tool: EditTool) -> void:
	current_tool = edit_tool
	_refresh()


func show_tab(tab: Tab) -> void:
	current_tab = tab
	[levels_tab, map_tab, waves_tab][tab].button_pressed = true
	map_view.visible = tab == Tab.MAP
	waves_view.visible = tab == Tab.WAVES
	levels_view.visible = tab == Tab.LEVELS
	path_tool_button.visible = tab == Tab.MAP
	rocks_tool_button.visible = tab == Tab.MAP
	clear_button.visible = tab == Tab.MAP
	_pending_delete = -1
	_notice = ""
	if tab == Tab.WAVES:
		_rebuild_waves()
	elif tab == Tab.LEVELS:
		_rebuild_levels()
	_refresh()


# --- État ----------------------------------------------------------------------

## Met à jour les réglages, les boutons et le message du bas, et redessine la carte.
func _refresh() -> void:
	if not name_edit.has_focus():
		name_edit.text = str(data.get("name", ""))
	biome_option.select(int(data.biome))
	gold_spin.set_value_no_signal(int(data.gold))
	lives_spin.set_value_no_signal(int(data.lives))
	clear_button.text = "Effacer le chemin" if current_tool == EditTool.PATH else "Enlever les rochers"
	var problem := CustomLevel.validate(data)
	play_button.disabled = not problem.is_empty()
	if not _notice.is_empty():
		status_label.text = _notice
		status_label.add_theme_color_override("font_color", ERROR_COLOR if _notice_is_error else READY_COLOR)
	elif not problem.is_empty():
		status_label.text = problem
		status_label.add_theme_color_override("font_color", ERROR_COLOR)
	else:
		status_label.text = "%s  ·  %s" % [_describe_waves(data), _tool_hint()]
		status_label.add_theme_color_override("font_color", HINT_COLOR)
	map_view.queue_redraw()


## Message passager en bas de l'écran (jusqu'à la prochaine action).
func _show_notice(text: String, is_error := false) -> void:
	_notice = text
	_notice_is_error = is_error
	_refresh()
	_notice = ""


func _tool_hint() -> String:
	if current_tab == Tab.LEVELS:
		return tr("Copiez le code d'un niveau pour le partager.")
	if current_tab == Tab.WAVES:
		return "Prêt à jouer."
	if current_tool == EditTool.PATH:
		return "Cliquez ou glissez pour prolonger le chemin, clic droit pour reculer."
	return "Cliquez ou glissez pour poser ou enlever des rochers."


func _describe_waves(level: Dictionary) -> String:
	var waves: Array = level.waves
	var monsters := 0
	for wave: Dictionary in waves:
		for group: Dictionary in wave.groups:
			monsters += 1 if load(group.enemy).is_boss else int(group.count)
	return tr_n("%d vague", "%d vagues", waves.size()) % waves.size() + ", " \
		+ tr_n("%d monstre", "%d monstres", monsters) % monsters


## Joue le niveau, s'il est jouable.
func play() -> bool:
	if not CustomLevel.validate(data).is_empty():
		return false
	_save()
	Level.open_custom(get_tree(), data)
	return true


# --- Carte ----------------------------------------------------------------------

func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var cell := _cell_at(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = true
			_painting_rocks = not data.rocks.has(cell)
			click_cell(cell)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if current_tool == EditTool.PATH:
				undo_path()
			else:
				set_rock(cell, false)
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		drag_cell(_cell_at(event.position))


func _cell_at(at: Vector2) -> Vector2i:
	return Vector2i((at / CustomLevel.CELL_SIZE).floor())


## Clic sur une case avec l'outil choisi.
func click_cell(cell: Vector2i) -> void:
	if not CustomLevel.is_in_grid(cell):
		return
	if current_tool == EditTool.ROCKS:
		set_rock(cell, _painting_rocks)
		return
	var path: Array = data.path
	if path.is_empty() and not CustomLevel.is_on_edge(cell):
		status_label.text = "Le chemin part du bord de la carte : cliquez sur une case du bord."
		status_label.add_theme_color_override("font_color", ERROR_COLOR)
		return
	_set_path(CustomLevel.extend_path(path, cell))


## Case survolée en glissant : prolonge le chemin (sans le couper) ou peint les rochers.
func drag_cell(cell: Vector2i) -> void:
	if not CustomLevel.is_in_grid(cell):
		return
	if current_tool == EditTool.ROCKS:
		set_rock(cell, _painting_rocks)
	elif not data.path.is_empty() and not CustomLevel.expand_path(data.path).has(cell):
		_set_path(CustomLevel.extend_path(data.path, cell))


func _set_path(path: Array) -> void:
	data.path = path
	# Un rocher sous le chemin disparaît.
	var cells := CustomLevel.expand_path(path)
	data.rocks = data.rocks.filter(func(rock: Vector2i) -> bool: return not cells.has(rock))
	_refresh()


## Recule le chemin d'une case.
func undo_path() -> void:
	var cells := CustomLevel.expand_path(data.path)
	if cells.size() <= 1:
		_set_path([])
	else:
		_set_path(CustomLevel.truncate_path(data.path, cells[-2]))


func set_rock(cell: Vector2i, present: bool) -> void:
	if CustomLevel.expand_path(data.path).has(cell) or data.rocks.has(cell) == present:
		return
	if present:
		data.rocks.append(cell)
	else:
		data.rocks.erase(cell)
	_refresh()


func _on_clear_pressed() -> void:
	if current_tool == EditTool.PATH:
		_set_path([])
	else:
		data.rocks = []
		_refresh()


func _draw_map() -> void:
	var colors: Array = CustomLevel.BIOME_COLORS[int(data.biome)]
	var size := CustomLevel.CELL_SIZE
	map_view.draw_rect(Rect2(Vector2.ZERO, map_view.size), colors[1])
	for x in CustomLevel.COLUMNS + 1:
		map_view.draw_line(Vector2(x * size, 0), Vector2(x * size, map_view.size.y), Color(0, 0, 0, 0.18))
	for y in CustomLevel.ROWS + 1:
		map_view.draw_line(Vector2(0, y * size), Vector2(map_view.size.x, y * size), Color(0, 0, 0, 0.18))
	for rock: Vector2i in data.rocks:
		map_view.draw_texture_rect(ROCK_TEXTURE, Rect2(Vector2(rock) * size + Vector2.ONE * size * 0.05,
			Vector2.ONE * size * 0.9), false, Color(colors[3]).lightened(0.45))
	var path: Array = data.path
	if path.is_empty():
		# Les cases du bord, où le chemin peut commencer.
		for cell in _edge_cells():
			map_view.draw_rect(Rect2(Vector2(cell) * size, Vector2.ONE * size).grow(-4), Color(START_COLOR, 0.18))
		return
	var points := CustomLevel.get_path_points(path)
	for i in points.size():
		points[i] -= CustomLevel.GRID_ORIGIN
	if points.size() == 1:
		map_view.draw_circle(points[0], 24.0, colors[2])
	else:
		map_view.draw_polyline(points, colors[2], 48.0)
		for point in points:
			map_view.draw_circle(point, 24.0, colors[2])
		_draw_arrows(points)
	var start := CustomLevel.cell_center(path[0]) - CustomLevel.GRID_ORIGIN
	map_view.draw_circle(start, 12.0, START_COLOR)
	if path.size() >= 2:
		var base := CustomLevel.cell_center(path[-1]) - CustomLevel.GRID_ORIGIN
		map_view.draw_texture_rect(BASE_TEXTURE, Rect2(base - Vector2(32, 48), Vector2(64, 96)), false)


## Petites flèches dans le sens de la marche, au milieu de chaque ligne droite.
func _draw_arrows(points: PackedVector2Array) -> void:
	for i in range(1, points.size()):
		var from := points[i - 1]
		var to := points[i]
		var direction := (to - from).normalized()
		var middle := (from + to) / 2.0
		var side := direction.orthogonal() * 9.0
		map_view.draw_colored_polygon(PackedVector2Array([middle + direction * 10.0, middle - direction * 6.0 + side,
			middle - direction * 6.0 - side]), Color(1, 1, 1, 0.55))


func _edge_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in CustomLevel.COLUMNS:
		for y in CustomLevel.ROWS:
			if CustomLevel.is_on_edge(Vector2i(x, y)) and not data.rocks.has(Vector2i(x, y)):
				result.append(Vector2i(x, y))
	return result


# --- Vagues ---------------------------------------------------------------------

func add_wave() -> void:
	if data.waves.size() >= CustomLevel.MAX_WAVES:
		return
	var last: Dictionary = data.waves[-1] if not data.waves.is_empty() else {}
	# La nouvelle vague reprend la précédente, avec un peu plus de monstres.
	var groups := []
	for group: Dictionary in last.get("groups", []):
		var copy := group.duplicate()
		copy.count = mini(int(ceil(group.count * 1.25)), CustomLevel.MAX_COUNT)
		groups.append(copy)
	if groups.is_empty():
		groups.append(_new_group())
	data.waves.append({groups = groups})
	_rebuild_waves()
	_refresh()


func remove_wave(index: int) -> void:
	data.waves.remove_at(index)
	_rebuild_waves()
	_refresh()


func add_group(wave: int) -> void:
	var groups: Array = data.waves[wave].groups
	if groups.size() >= CustomLevel.MAX_GROUPS:
		return
	groups.append(_new_group())
	_rebuild_waves()
	_refresh()


func remove_group(wave: int, group: int) -> void:
	data.waves[wave].groups.remove_at(group)
	_rebuild_waves()
	_refresh()


## Groupe ajouté : le premier monstre du monde choisi.
func _new_group() -> Dictionary:
	var campaign: Campaign = load(CustomLevel.CAMPAIGN_PATH)
	var world: World = campaign.worlds[int(data.biome)]
	return {enemy = world.enemies[0].resource_path, count = 10, elite = false}


func _rebuild_waves() -> void:
	for child in waves_list.get_children():
		waves_list.remove_child(child)
		child.queue_free()
	var waves: Array = data.waves
	for i in waves.size():
		waves_list.add_child(_make_wave_row(i))
	var add := Button.new()
	add.text = "+ Ajouter une vague"
	add.custom_minimum_size = Vector2(240, 44)
	add.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add.disabled = waves.size() >= CustomLevel.MAX_WAVES
	add.pressed.connect(add_wave)
	waves_list.add_child(add)


func _make_wave_row(index: int) -> Control:
	var panel := PanelContainer.new()
	var style := UiStyle.panel(Color(UiStyle.ACCENT, 0.35), 10.0)
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var label := _make_label(tr("Vague %d") % (index + 1))
	label.custom_minimum_size = Vector2(90, 0)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	row.add_child(label)
	var groups_box := VBoxContainer.new()
	groups_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(groups_box)
	var groups: Array = data.waves[index].groups
	for j in groups.size():
		groups_box.add_child(_make_group_row(index, j))
	var add := Button.new()
	add.text = "+ Groupe"
	add.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add.disabled = groups.size() >= CustomLevel.MAX_GROUPS
	add.pressed.connect(add_group.bind(index))
	groups_box.add_child(add)
	var remove := Button.new()
	remove.text = "Supprimer la vague"
	remove.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	remove.disabled = data.waves.size() <= 1
	remove.pressed.connect(remove_wave.bind(index))
	row.add_child(remove)
	return panel


func _make_group_row(wave: int, index: int) -> Control:
	var group: Dictionary = data.waves[wave].groups[index]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(260, 0)
	var campaign: Campaign = load(CustomLevel.CAMPAIGN_PATH)
	var previous_world := -1
	for i in enemy_choices.size():
		var enemy := enemy_choices[i]
		var world := _world_of(campaign, enemy)
		if world != previous_world:
			option.add_separator(campaign.worlds[world].display_name)
			previous_world = world
		option.add_item(enemy.display_name + ("  (boss)" if enemy.is_boss else ""), i)
		if enemy.resource_path == group.enemy:
			option.select(option.get_item_count() - 1)
	row.add_child(option)
	var count := _make_spin(1, CustomLevel.MAX_COUNT, 1, row)
	var elite := CheckButton.new()
	elite.text = "Élite"
	row.add_child(elite)
	var update := func() -> void:
		var boss: bool = load(group.enemy).is_boss
		count.editable = not boss
		count.set_value_no_signal(1 if boss else int(group.count))
		elite.disabled = boss
		elite.set_pressed_no_signal(bool(group.elite) and not boss)
	update.call()
	option.item_selected.connect(func(item: int) -> void:
		group.enemy = enemy_choices[option.get_item_id(item)].resource_path
		update.call()
		_refresh())
	count.value_changed.connect(func(value: float) -> void:
		group.count = int(value)
		_refresh())
	elite.toggled.connect(func(pressed: bool) -> void: group.elite = pressed)
	var remove := Button.new()
	remove.text = "✕"
	remove.tooltip_text = "Retirer le groupe"
	remove.disabled = data.waves[wave].groups.size() <= 1
	remove.pressed.connect(remove_group.bind(wave, index))
	row.add_child(remove)
	return row


func _world_of(campaign: Campaign, enemy: EnemyData) -> int:
	for i in campaign.worlds.size():
		if campaign.worlds[i].enemies.has(enemy) or campaign.worlds[i].bosses.has(enemy):
			return i
	return 0


# --- Niveaux et partage -----------------------------------------------------------

func _build_levels_view() -> void:
	levels_view = VBoxContainer.new()
	levels_view.position = Vector2(16, BAR_HEIGHT + 8)
	levels_view.size = Vector2(1248, map_view.size.y - 16)
	levels_view.add_theme_constant_override("separation", 10)
	levels_view.visible = false
	add_child(levels_view)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	levels_view.add_child(actions)
	var new_button := Button.new()
	new_button.text = "+ Nouveau niveau"
	new_button.custom_minimum_size = Vector2(220, 44)
	new_button.pressed.connect(new_level)
	actions.add_child(new_button)
	actions.add_child(_make_label("   Code reçu"))
	import_edit = LineEdit.new()
	import_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_edit.placeholder_text = "Collez ici le code d'un niveau partagé (%s...)" % CustomLevel.CODE_PREFIX
	import_edit.text_submitted.connect(func(text: String) -> void: import_code(text))
	actions.add_child(import_edit)
	var import_button := Button.new()
	import_button.text = "Importer"
	import_button.custom_minimum_size = Vector2(140, 44)
	import_button.pressed.connect(func() -> void: import_code(import_edit.text))
	actions.add_child(import_button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	levels_view.add_child(scroll)
	levels_list = VBoxContainer.new()
	levels_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levels_list.add_theme_constant_override("separation", 8)
	scroll.add_child(levels_list)


func _rebuild_levels() -> void:
	for child in levels_list.get_children():
		levels_list.remove_child(child)
		child.queue_free()
	for i in levels.size():
		levels_list.add_child(_make_level_row(i))


func _make_level_row(index: int) -> Control:
	var level := levels[index]
	var is_open := index == current
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		UiStyle.panel(UiStyle.ACCENT if is_open else Color(UiStyle.ACCENT, 0.25), 10.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 0)
	row.add_child(texts)
	var name_label := _make_label(CustomLevel.clean_name(level.get("name", "")))
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35) if is_open else UiStyle.TEXT_COLOR)
	texts.add_child(name_label)
	var biome_names := CustomLevel.get_biome_names()
	var problem := CustomLevel.validate(level)
	var summary := _make_label("%s  ·  %s  ·  %s" % [biome_names[int(level.biome)], _describe_waves(level),
		tr("Jouable") if problem.is_empty() else tr("À finir")])
	summary.add_theme_font_size_override("font_size", 16)
	summary.add_theme_color_override("font_color", HINT_COLOR if problem.is_empty() else ERROR_COLOR)
	texts.add_child(summary)
	var open := _make_row_button("Ouvert" if is_open else "Ouvrir", row)
	open.disabled = is_open
	open.pressed.connect(open_level.bind(index))
	var copy := _make_row_button("Dupliquer", row)
	copy.disabled = levels.size() >= CustomLevel.MAX_LEVELS
	copy.pressed.connect(duplicate_level.bind(index))
	var share := _make_row_button("Copier le code", row)
	share.disabled = not problem.is_empty()
	share.tooltip_text = "Met le code du niveau dans le presse-papiers, pour le partager."
	share.pressed.connect(copy_code.bind(index))
	var delete := _make_row_button("Confirmer ?" if _pending_delete == index else "Supprimer", row)
	delete.disabled = levels.size() <= 1
	if _pending_delete == index:
		delete.add_theme_color_override("font_color", ERROR_COLOR)
	delete.pressed.connect(delete_level.bind(index))
	return panel


func _make_row_button(text: String, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 44)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(button)
	return button


## Ouvre un niveau de la liste dans l'éditeur, sur l'onglet Carte.
func open_level(index: int) -> void:
	rename_level(name_edit.text)
	current = clampi(index, 0, levels.size() - 1)
	data = levels[current]
	_save()
	show_tab(Tab.MAP)


## Ajoute un niveau (avec le chemin et les vagues de départ) et l'ouvre.
func new_level() -> bool:
	return _add_level(CustomLevel.create_default())


func duplicate_level(index: int) -> bool:
	var copy := levels[index].duplicate(true)
	copy.name = tr("Copie de %s") % CustomLevel.clean_name(copy.get("name", ""))
	return _add_level(copy)


func _add_level(level: Dictionary) -> bool:
	if levels.size() >= CustomLevel.MAX_LEVELS:
		_show_notice(tr("Pas plus de %d niveaux : supprimez-en un d'abord.") % CustomLevel.MAX_LEVELS, true)
		return false
	level.name = CustomLevel.unique_name(level.get("name", ""), levels)
	levels.append(level)
	open_level(levels.size() - 1)
	return true


## Supprime un niveau au deuxième clic (le premier demande confirmation).
func delete_level(index: int) -> void:
	if levels.size() <= 1:
		return
	if _pending_delete != index:
		_pending_delete = index
		_rebuild_levels()
		return
	_pending_delete = -1
	var removed := CustomLevel.clean_name(levels[index].get("name", ""))
	levels.remove_at(index)
	if current > index or current >= levels.size():
		current = maxi(current - 1, 0)
	data = levels[current]
	_save()
	_rebuild_levels()
	_show_notice(tr("« %s » est supprimé.") % removed)


## Renomme le niveau ouvert (le nom vide redevient celui par défaut, un nom déjà pris
## reçoit un numéro).
func rename_level(text: String) -> void:
	var name := CustomLevel.unique_name(text, levels, current)
	var changed: bool = name != levels[current].get("name")
	data.name = name
	if name_edit.text != name:
		name_edit.text = name
	# Seulement si le nom change : la liste refaite perdrait le clic en cours.
	if changed and current_tab == Tab.LEVELS:
		_rebuild_levels()


## Met le code de partage du niveau dans le presse-papiers et le renvoie.
func copy_code(index: int) -> String:
	if not CustomLevel.validate(levels[index]).is_empty():
		return ""
	var code := CustomLevel.encode(levels[index])
	DisplayServer.clipboard_set(code)
	_show_notice(tr("Code de « %s » copié : collez-le à qui vous voulez, il l'importe dans son éditeur.")
		% CustomLevel.clean_name(levels[index].get("name", "")))
	return code


## Ajoute le niveau d'un code de partage et l'ouvre. Renvoie false si le code ne va pas.
func import_code(code: String) -> bool:
	if code.strip_edges().is_empty():
		_show_notice(tr("Collez d'abord un code dans le champ."), true)
		return false
	var level := CustomLevel.decode(code)
	if level.is_empty():
		_show_notice(tr("Ce code n'est pas un niveau valide : vérifiez qu'il est copié en entier."), true)
		return false
	if not _add_level(level):
		return false
	import_edit.clear()
	_show_notice(tr("« %s » est importé.") % data.name)
	return true
