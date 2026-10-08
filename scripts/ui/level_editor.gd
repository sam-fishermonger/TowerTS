class_name LevelEditor
extends Control
## Éditeur de niveau : on trace le chemin des ennemis sur la grille (ou, sur une carte
## libre, on pose les terriers et le QG : les tours feront le labyrinthe), on pose des
## rochers, on compose les vagues, puis on joue. Les niveaux du joueur sont enregistrés
## avec la progression (CustomLevel) ; l'onglet Niveaux en crée, en ouvre, et les partage
## sous forme de code à copier-coller. Une partie finie ramène ici.

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"
const GROUND_SHADER: Shader = preload("res://scripts/map/relief_ground.gdshader")
const BAR_HEIGHT := 64.0
const BOTTOM_HEIGHT := 96.0
const ERROR_COLOR := Color(1.0, 0.55, 0.45)
const HINT_COLOR := Color(0.8, 0.85, 0.8)
const READY_COLOR := Color(0.55, 1.0, 0.6)
const START_COLOR := Color(0.45, 0.9, 0.5)

enum EditTool { PATH, ROCKS, SPAWNS, BASE }
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
## Sol peint de l'aperçu (le shader de la carte en vue de trois quarts).
var map_ground: ColorRect
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
var spawns_tool_button: Button
var base_tool_button: Button
var free_button: CheckButton
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
## Habillage du monde choisi (BiomeTheme), et touffes d'herbe semées sur l'aperçu.
var _theme: Dictionary = {}
var _theme_biome := -1
var _tufts: Array[Vector3] = []


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
	top.add_child(_make_label("  " + tr("Monde")))
	biome_option = OptionButton.new()
	for name in CustomLevel.get_biome_names():
		biome_option.add_item(name)
	biome_option.item_selected.connect(func(index: int) -> void:
		data.biome = index
		_refresh())
	top.add_child(biome_option)
	top.add_child(_make_label("  " + tr("Or")))
	gold_spin = _make_spin(CustomLevel.MIN_GOLD, CustomLevel.MAX_GOLD, 10, top)
	gold_spin.value_changed.connect(func(value: float) -> void: data.gold = int(value))
	top.add_child(_make_label("  " + tr("Vies")))
	lives_spin = _make_spin(CustomLevel.MIN_LIVES, CustomLevel.MAX_LIVES, 1, top)
	lives_spin.value_changed.connect(func(value: float) -> void: data.lives = int(value))

	map_view = Control.new()
	map_view.position = Vector2(0, BAR_HEIGHT)
	map_view.size = Vector2(CustomLevel.COLUMNS, CustomLevel.ROWS) * CustomLevel.CELL_SIZE
	map_view.mouse_filter = Control.MOUSE_FILTER_STOP
	map_view.draw.connect(_draw_map)
	map_view.gui_input.connect(_on_map_input)
	add_child(map_view)
	map_ground = ColorRect.new()
	map_ground.size = map_view.size
	map_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_ground.show_behind_parent = true
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("size", map_view.size)
	material.set_shader_parameter("seed", 0.37)
	map_ground.material = material
	map_view.add_child(map_ground)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in CustomLevel.COLUMNS * CustomLevel.ROWS * 2:
		_tufts.append(Vector3(rng.randf() * map_view.size.x, rng.randf() * map_view.size.y, rng.randf()))

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
	back_button.custom_minimum_size = Vector2(110, 52)
	back_button.add_theme_font_size_override("font_size", 22)
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(TITLE_SCREEN))
	bottom.add_child(back_button)
	free_button = CheckButton.new()
	free_button.text = "Carte libre"
	free_button.tooltip_text = "Pas de chemin tracé : les monstres partent des terriers et contournent vos tours jusqu'au QG."
	free_button.add_theme_font_size_override("font_size", 18)
	free_button.toggled.connect(set_free)
	bottom.add_child(free_button)
	var tools := ButtonGroup.new()
	path_tool_button = _make_toggle("Chemin", tools, bottom)
	path_tool_button.button_pressed = true
	path_tool_button.pressed.connect(set_tool.bind(EditTool.PATH))
	rocks_tool_button = _make_toggle("Rochers", tools, bottom)
	rocks_tool_button.pressed.connect(set_tool.bind(EditTool.ROCKS))
	spawns_tool_button = _make_toggle("Terriers", tools, bottom)
	spawns_tool_button.pressed.connect(set_tool.bind(EditTool.SPAWNS))
	base_tool_button = _make_toggle("QG", tools, bottom)
	base_tool_button.pressed.connect(set_tool.bind(EditTool.BASE))
	# Boutons d'outils à la taille de leur texte : la carte libre en ajoute deux.
	for button: Button in [path_tool_button, rocks_tool_button, spawns_tool_button, base_tool_button]:
		button.custom_minimum_size.x = 0
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
	play_button.custom_minimum_size = Vector2(150, 52)
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


## Passe le niveau ouvert en carte libre (terriers et QG, sans chemin) ou le ramène au
## chemin tracé. Le chemin est gardé tel quel pendant ce temps.
func set_free(free: bool) -> void:
	if free == CustomLevel.is_free(data):
		return
	if free:
		CustomLevel.make_free(data)
		data.rocks = data.rocks.filter(func(rock: Vector2i) -> bool:
			return not data.spawns.has(rock) and rock != data.base)
		current_tool = EditTool.SPAWNS if data.spawns.is_empty() else EditTool.ROCKS
	else:
		data.free = false
		current_tool = EditTool.PATH
		_set_path(data.path)
	_refresh()


## Outils proposés pour le niveau ouvert : le chemin, ou les terriers et le QG.
func _tools_for_mode() -> Array[EditTool]:
	if CustomLevel.is_free(data):
		return [EditTool.SPAWNS, EditTool.BASE, EditTool.ROCKS]
	return [EditTool.PATH, EditTool.ROCKS]


func show_tab(tab: Tab) -> void:
	current_tab = tab
	[levels_tab, map_tab, waves_tab][tab].button_pressed = true
	map_view.visible = tab == Tab.MAP
	waves_view.visible = tab == Tab.WAVES
	levels_view.visible = tab == Tab.LEVELS
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
	_apply_theme()
	gold_spin.set_value_no_signal(int(data.gold))
	lives_spin.set_value_no_signal(int(data.lives))
	var tools := _tools_for_mode()
	if not tools.has(current_tool):
		current_tool = tools[0]
	var on_map := current_tab == Tab.MAP
	var tool_buttons := [path_tool_button, rocks_tool_button, spawns_tool_button, base_tool_button]
	for edit_tool: EditTool in EditTool.values():
		tool_buttons[edit_tool].visible = on_map and tools.has(edit_tool)
	tool_buttons[current_tool].set_pressed_no_signal(true)
	free_button.visible = on_map
	free_button.set_pressed_no_signal(CustomLevel.is_free(data))
	clear_button.visible = on_map
	clear_button.text = ["Effacer le chemin", "Enlever les rochers", "Enlever les terriers", "Enlever le QG"][current_tool]
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
		return tr("Prêt à jouer.")
	if current_tool == EditTool.PATH:
		return tr("Cliquez ou glissez pour prolonger le chemin, clic droit pour reculer.")
	if current_tool == EditTool.SPAWNS:
		return tr("Cliquez sur une case du bord pour poser ou enlever un terrier.")
	if current_tool == EditTool.BASE:
		return tr("Cliquez sur une case pour y mettre le QG. Vos tours feront le labyrinthe.")
	return tr("Cliquez ou glissez pour poser ou enlever des rochers.")


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
			match current_tool:
				EditTool.PATH:
					undo_path()
				EditTool.ROCKS:
					set_rock(cell, false)
				EditTool.SPAWNS:
					remove_spawn(cell)
				EditTool.BASE:
					if data.base == cell:
						data.base = CustomLevel.NO_BASE
						_refresh()
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
	if current_tool == EditTool.SPAWNS:
		if data.spawns.has(cell):
			remove_spawn(cell)
		else:
			add_spawn(cell)
		return
	if current_tool == EditTool.BASE:
		set_base(cell)
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
	elif current_tool == EditTool.PATH and not data.path.is_empty() \
			and not CustomLevel.expand_path(data.path).has(cell):
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


## Carte libre : pose un terrier sur une case du bord (le rocher qui y était disparaît).
func add_spawn(cell: Vector2i) -> void:
	if not CustomLevel.is_on_edge(cell):
		_show_notice(tr("Les terriers sont sur le bord de la carte, un par case."), true)
		return
	if data.spawns.size() >= CustomLevel.MAX_SPAWNS:
		_show_notice(tr("Pas plus de %d terriers.") % CustomLevel.MAX_SPAWNS, true)
		return
	if data.spawns.has(cell) or cell == data.base:
		return
	data.spawns.append(cell)
	data.rocks.erase(cell)
	_refresh()


func remove_spawn(cell: Vector2i) -> void:
	if data.spawns.has(cell):
		data.spawns.erase(cell)
		_refresh()


## Carte libre : met le QG des monstres sur la case (pas sur un terrier).
func set_base(cell: Vector2i) -> void:
	if data.spawns.has(cell):
		return
	data.base = cell
	data.rocks.erase(cell)
	_refresh()


func set_rock(cell: Vector2i, present: bool) -> void:
	if data.rocks.has(cell) == present:
		return
	if CustomLevel.is_free(data):
		if data.spawns.has(cell) or data.base == cell:
			return
	elif CustomLevel.expand_path(data.path).has(cell):
		return
	if present:
		data.rocks.append(cell)
	else:
		data.rocks.erase(cell)
	_refresh()


func _on_clear_pressed() -> void:
	match current_tool:
		EditTool.PATH:
			_set_path([])
			return
		EditTool.ROCKS:
			data.rocks = []
		EditTool.SPAWNS:
			data.spawns = []
		EditTool.BASE:
			data.base = CustomLevel.NO_BASE
	_refresh()


## Couleurs du sol et du chemin du monde choisi, comme en jeu.
func _apply_theme() -> void:
	if _theme_biome == int(data.biome):
		return
	_theme_biome = int(data.biome)
	_theme = CustomLevel.get_biome_theme(_theme_biome)
	var material := map_ground.material as ShaderMaterial
	material.set_shader_parameter("grass_dark", _theme.grass[0])
	material.set_shader_parameter("grass", _theme.grass[1])
	material.set_shader_parameter("grass_light", _theme.grass[2])


## Aperçu de la carte en vue de trois quarts, comme en jeu : sol peint et touffes du
## monde, chemin de terre (ou pavé…) cerné, rochers et QG debout, triés en profondeur.
## Le quadrillage reste visible pour tracer.
func _draw_map() -> void:
	var size := CustomLevel.CELL_SIZE
	var free := CustomLevel.is_free(data)
	var path: Array = data.path
	var cells := {}
	for cell: Vector2i in CustomLevel.expand_path(path) if not free and path.size() >= 2 else path:
		cells[cell] = true
	_draw_tufts(cells)
	var line := Color(0, 0, 0, 0.12)
	for x in range(1, CustomLevel.COLUMNS):
		map_view.draw_line(Vector2(x * size, 0), Vector2(x * size, map_view.size.y), line)
	for y in range(1, CustomLevel.ROWS):
		map_view.draw_line(Vector2(0, y * size), Vector2(map_view.size.x, y * size), line)
	# Ce qui se tient debout (rochers, QG), dessiné du fond vers le devant.
	var standing: Array[Array] = []
	for rock: Vector2i in data.rocks:
		standing.append([CustomLevel.cell_center(rock) - CustomLevel.GRID_ORIGIN + Vector2(0, 10), rock])
	if free:
		_draw_free_map(standing)
	elif path.is_empty():
		# Les cases du bord, où le chemin peut commencer.
		for cell in _edge_cells():
			map_view.draw_rect(Rect2(Vector2(cell) * size, Vector2.ONE * size).grow(-4), Color(START_COLOR, 0.25))
	else:
		var points := CustomLevel.get_path_points(path)
		for i in points.size():
			points[i] -= CustomLevel.GRID_ORIGIN
		_draw_path(points)
		if points.size() >= 2:
			_draw_arrows(points)
		var start := points[0]
		map_view.draw_circle(start, 13.0, Relief.OUTLINE, true, -1.0, true)
		map_view.draw_circle(start, 11.0, START_COLOR, true, -1.0, true)
		if path.size() >= 2:
			standing.append([CustomLevel.cell_center(path[-1]) - CustomLevel.GRID_ORIGIN, null])
	standing.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	var rock_color: Color = Color(CustomLevel.BIOME_COLORS[int(data.biome)][3]).lightened(0.3)
	for item in standing:
		if item[1] == null:
			GameMap.draw_relief_base(map_view, item[0])
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(item[1])
		DecorItem.draw_rock(map_view, item[0], rng, 1.0, rock_color)


## Touffes d'herbe et fleurs du monde (boulons à la Fonderie), hors du chemin.
func _draw_tufts(path_cells: Dictionary) -> void:
	var color: Color = _theme.tuft_color
	for tuft in _tufts:
		var at := Vector2(tuft.x, tuft.y)
		if path_cells.has(Vector2i(at / CustomLevel.CELL_SIZE)):
			continue
		if tuft.z < _theme.flowers:
			for i in 3:
				map_view.draw_circle(at + Vector2.from_angle(TAU * i / 3.0) * 2.5, 2.2, _theme.flower_color)
			map_view.draw_circle(at, 1.6, Color(1.0, 0.75, 0.2))
		elif _theme.tufts == "bolts":
			map_view.draw_circle(at, 2.2, Color(0.55, 0.55, 0.58), true, -1.0, true)
			map_view.draw_circle(at, 0.9, Color(0.25, 0.25, 0.27), true, -1.0, true)
		else:
			for i in 3:
				var x := (i - 1) * 3.0
				map_view.draw_line(at + Vector2(x, 0), at + Vector2(x * 1.6, -6.0 + absf(x) * 0.5), color, 1.5, true)


## Chemin comme en jeu : des ronds de terre dont le rayon ondule, avec leur ombre, un
## bord sombre et une bande plus claire au milieu.
func _draw_path(points: PackedVector2Array) -> void:
	var dirt: Color = _theme.dirt
	var stamps := PackedVector3Array()
	var noise := FastNoiseLite.new()
	noise.seed = 3
	noise.frequency = 0.04
	var walked := 0.0
	for i in points.size():
		var from := points[i]
		var to := points[i + 1] if i + 1 < points.size() else from
		var length := from.distance_to(to)
		var step := 0.0
		while true:
			var at := from.lerp(to, step / length) if length > 0.0 else from
			stamps.append(Vector3(at.x, at.y, 28.0 + noise.get_noise_1d(walked + step) * 6.0))
			step += 6.0
			if step >= length:
				break
		walked += length
	for layer in [[Vector2(0, 3), 4.0, Color(0.1, 0.16, 0.05, 0.3)], [Vector2.ZERO, 2.0, dirt.darkened(0.42)],
			[Vector2.ZERO, 0.0, dirt]]:
		for stamp in stamps:
			map_view.draw_circle(Vector2(stamp.x, stamp.y) + layer[0], stamp.z + layer[1], layer[2], true, -1.0, true)
	for stamp in stamps:
		map_view.draw_circle(Vector2(stamp.x - 2.0, stamp.y - 3.0), stamp.z * 0.55, dirt.lightened(0.1), true, -1.0, true)


## Carte libre : les terriers (et, à l'outil Terriers, les cases du bord où en poser),
## le QG (ajouté à `standing`, dessiné avec les rochers), et un voile sur les cases que
## les rochers coupent du QG.
func _draw_free_map(standing: Array[Array]) -> void:
	var size := CustomLevel.CELL_SIZE
	if current_tool == EditTool.SPAWNS and data.spawns.size() < CustomLevel.MAX_SPAWNS:
		for cell in _edge_cells():
			if not data.spawns.has(cell) and cell != data.base:
				map_view.draw_rect(Rect2(Vector2(cell) * size, Vector2.ONE * size).grow(-4), Color(START_COLOR, 0.25))
	var base: Vector2i = data.base
	if CustomLevel.is_in_grid(base):
		var reached := CustomLevel.reachable_from_base(data)
		for x in CustomLevel.COLUMNS:
			for y in CustomLevel.ROWS:
				var cell := Vector2i(x, y)
				if not reached.has(cell) and not data.rocks.has(cell):
					map_view.draw_rect(Rect2(Vector2(cell) * size, Vector2.ONE * size), Color(0, 0, 0, 0.3))
	for cell: Vector2i in data.spawns:
		GameMap.draw_spawn_gate(map_view, CustomLevel.cell_center(cell) - CustomLevel.GRID_ORIGIN)
	if CustomLevel.is_in_grid(base):
		standing.append([CustomLevel.cell_center(base) - CustomLevel.GRID_ORIGIN, null])


## Petites flèches dans le sens de la marche, au milieu de chaque ligne droite.
func _draw_arrows(points: PackedVector2Array) -> void:
	for i in range(1, points.size()):
		var from := points[i - 1]
		var to := points[i]
		var direction := (to - from).normalized()
		var middle := (from + to) / 2.0
		var side := direction.orthogonal() * 9.0
		map_view.draw_colored_polygon(PackedVector2Array([middle + direction * 10.0, middle - direction * 6.0 + side,
			middle - direction * 6.0 - side]), Color(Color(_theme.dirt).darkened(0.55), 0.75))


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
			option.add_separator(tr(campaign.worlds[world].display_name))
			previous_world = world
		option.add_item(tr(enemy.display_name) + ("  (boss)" if enemy.is_boss else ""), i)
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
	actions.add_child(_make_label("   " + tr("Code reçu")))
	import_edit = LineEdit.new()
	import_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_edit.placeholder_text = tr("Collez ici le code d'un niveau partagé (%s...)") % CustomLevel.CODE_PREFIX
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
	var summary := _make_label("%s  ·  %s  ·  %s" % [tr(biome_names[int(level.biome)]), _describe_waves(level),
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
