extends Control
## Sélection du monde et du niveau (depuis l'écran titre) : une carte par monde de la
## campagne, avec son biome, ses monstres, ses étoiles et un bouton par niveau. Un monde
## se débloque en gagnant le dernier niveau du monde précédent.
## Le bouton Mode infini fait passer les cartes au mode infini : chaque niveau gagné avec
## 3 étoiles s'y joue sans fin, et y gagne des étoiles infinies (records et étoiles en bleu).
## En bas, le choix de la difficulté (Difficulty) : les boutons des niveaux montrent les
## étoiles obtenues dans celle-ci, et les cartes celles de toutes les difficultés.
## Survoler un niveau (ou lui donner le focus) ouvre sa fenêtre de détail : ses vagues,
## avec leurs monstres, élites et boss, dans la difficulté choisie.

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"
const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")
const LOCKED_ALPHA := 0.45
const STARS_COLOR := Color(0.95, 0.85, 0.45)
const ENDLESS_COLOR := Progress.ENDLESS_STAR_COLOR

## Cartes du mode infini plutôt que de la campagne.
var endless_mode := false

## Bouton de chaque niveau, par chemin de scène.
var _level_buttons := {}
var _difficulty_group := ButtonGroup.new()
## Fenêtre de détail du niveau survolé.
var level_details: DetailPopup
## Texte de la fenêtre de détail de chaque niveau, par « chemin|difficulté|infini » :
## chaque niveau n'est ouvert qu'une fois pour lire ses vagues.
var _details_cache := {}

@onready var worlds_box: HBoxContainer = %Worlds
@onready var back_button: Button = %BackButton
@onready var mode_button: Button = %ModeButton
@onready var title_label: Label = %Title
## Règles du mode affiché, en bas de l'écran.
@onready var mode_hint: Label = %ModeHint
## Choix de la difficulté (caché en mode infini, qui se joue toujours en Moyen).
@onready var difficulty_bar: HBoxContainer = %DifficultyBar


func _ready() -> void:
	back_button.pressed.connect(go_back)
	level_details = DetailPopup.new(470.0)
	add_child(level_details)
	_build_difficulty_buttons()
	mode_button.toggled.connect(set_endless_mode)
	set_endless_mode(false)
	Sound.play_music()
	var next := get_level_button(Progress.get_next_to_play(CAMPAIGN))
	(next if next else back_button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()


func go_back() -> void:
	get_tree().change_scene_to_file(TITLE_SCREEN)


func open_level(path: String) -> void:
	Level.open(get_tree(), path, endless_mode)


## Affiche les cartes du mode infini (true) ou de la campagne (false).
func set_endless_mode(value: bool) -> void:
	endless_mode = value
	mode_button.set_pressed_no_signal(value)
	title_label.text = "Mode infini" if value else "Choisir un monde"
	title_label.add_theme_color_override(&"font_color", ENDLESS_COLOR if value else STARS_COLOR)
	difficulty_bar.visible = not value
	_refresh()


## Choisit la difficulté des prochaines parties (enregistrée) et met les boutons à jour.
func set_difficulty(difficulty: int) -> void:
	Difficulty.set_current(difficulty)
	_refresh()


## Bouton d'une difficulté.
func get_difficulty_button(difficulty: int) -> Button:
	return difficulty_bar.get_child(difficulty + 1)


func _build_difficulty_buttons() -> void:
	for d in Difficulty.COUNT:
		var button := Button.new()
		button.text = Difficulty.NAMES[d]
		button.toggle_mode = true
		button.button_group = _difficulty_group
		button.custom_minimum_size = Vector2(132, 40)
		button.add_theme_font_size_override(&"font_size", 18)
		for color_name in [&"font_pressed_color", &"font_hover_pressed_color"]:
			button.add_theme_color_override(color_name, Difficulty.COLORS[d])
		button.tooltip_text = "%s %s" % [Difficulty.describe(d), Difficulty.describe_tower_limit(d)]
		button.pressed.connect(set_difficulty.bind(d))
		difficulty_bar.add_child(button)


func _refresh() -> void:
	var difficulty := Difficulty.get_current()
	get_difficulty_button(difficulty).set_pressed_no_signal(true)
	if endless_mode:
		mode_hint.text = ("Les vagues ne s'arrêtent plus et durcissent sans fin. Une étoile infinie toutes les %d "
			+ "vagues repoussées au-delà de celles du niveau (%d par niveau) : elles achètent les "
			+ "spécialisations des tours, dans Améliorations.") % [Progress.ENDLESS_STAR_STEP, Progress.ENDLESS_MAX_STARS]
	else:
		mode_hint.text = ("%s : %s %s Chaque difficulté a ses propres étoiles (3 par niveau). Gagner un niveau "
			+ "avec 3 étoiles ouvre son mode infini.") % [Difficulty.NAMES[difficulty], Difficulty.describe(difficulty),
			Difficulty.describe_tower_limit(difficulty)]
	for card in worlds_box.get_children():
		worlds_box.remove_child(card)
		card.queue_free()
	_level_buttons.clear()
	_build_cards()


## Carte d'un monde (dans l'ordre de la campagne).
func get_card(world_index: int) -> Control:
	return worlds_box.get_child(world_index)


## Bouton d'un niveau, ou null s'il n'est pas dans la campagne.
func get_level_button(level_path: String) -> Button:
	return _level_buttons.get(level_path)


func _build_cards() -> void:
	for i in CAMPAIGN.worlds.size():
		worlds_box.add_child(_make_card(i))


func _make_card(world_index: int) -> Control:
	var world := CAMPAIGN.worlds[world_index]
	var unlocked := Progress.is_world_unlocked(CAMPAIGN, world_index)
	var card := PanelContainer.new()
	card.name = "World%d" % (world_index + 1)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.09, 0.08, 0.92)
	style.border_color = world.color if unlocked else world.color.darkened(0.6)
	style.set_border_width_all(2)
	style.border_width_top = 6
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	card.add_theme_stylebox_override(&"panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	card.add_child(column)

	var number := _label("Monde %d" % (world_index + 1), 16, Color(1, 1, 1, 0.55))
	column.add_child(number)
	var title := _label(world.display_name, 30, world.color)
	title.name = "WorldName"
	column.add_child(title)
	var description := _label(world.description, 15, Color(0.85, 0.88, 0.85))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.y = 64
	column.add_child(description)

	# Les monstres du biome, avec leur nom en bulle d'aide.
	var bestiary := HBoxContainer.new()
	bestiary.alignment = BoxContainer.ALIGNMENT_CENTER
	bestiary.add_theme_constant_override(&"separation", 4)
	for enemy in world.enemies:
		var icon := TextureRect.new()
		icon.texture = enemy.texture
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text = enemy.display_name
		icon.modulate.a = 1.0 if unlocked else LOCKED_ALPHA
		bestiary.add_child(icon)
	column.add_child(bestiary)

	var stars: Label
	if endless_mode:
		stars = _label("∞  ★ %d / %d" % [Progress.get_world_endless_stars(world),
			world.levels.size() * Progress.ENDLESS_MAX_STARS], 20, ENDLESS_COLOR)
	else:
		stars = _label("★ %d / %d" % [Progress.get_world_stars(world), world.levels.size() * Progress.MAX_LEVEL_STARS],
			20, STARS_COLOR)
		stars.tooltip_text = "Étoiles des 4 difficultés"
		stars.mouse_filter = Control.MOUSE_FILTER_PASS
	stars.name = "Stars"
	column.add_child(stars)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override(&"h_separation", 8)
	grid.add_theme_constant_override(&"v_separation", 8)
	var first := CAMPAIGN.first_level_index(world_index)
	for i in world.levels.size():
		var path := world.levels[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(104, 60)
		if endless_mode:
			_setup_endless_button(button, path, "%d-%d" % [world_index + 1, i + 1])
		else:
			button.disabled = not Progress.is_unlocked(CAMPAIGN, first + i)
			button.text = "%d-%d\n%s" % [world_index + 1, i + 1,
				"Verrouillé" if button.disabled else Progress.star_text(Progress.get_stars(path, Difficulty.get_current()))]
			if not button.disabled:
				button.tooltip_text = _level_tooltip(path)
		_level_buttons[path] = button
		# Au tactile, le premier toucher ouvre la fenêtre de détail, le second le niveau.
		button.pressed.connect(func() -> void:
			if GameSettings.confirm_touch(button):
				open_level(path))
		button.mouse_entered.connect(show_level_details.bind(path))
		button.focus_entered.connect(show_level_details.bind(path))
		button.mouse_exited.connect(level_details.close)
		button.focus_exited.connect(level_details.close)
		grid.add_child(button)
	column.add_child(grid)

	if not unlocked:
		var hint := _label("Gagner le dernier niveau de %s pour débloquer ce monde."
			% CAMPAIGN.worlds[world_index - 1].display_name, 15, Color(1, 1, 1, 0.6))
		hint.name = "LockedHint"
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(hint)
	return card


## Étoiles d'un niveau dans chaque difficulté, une ligne par difficulté.
func _level_tooltip(path: String) -> String:
	var lines: Array[String] = []
	for d in Difficulty.COUNT:
		lines.append("%s  %s" % [Progress.star_text(Progress.get_stars(path, d)), Difficulty.NAMES[d]])
	return "\n".join(lines)


## Bouton d'un niveau en mode infini : ouvert avec 3 étoiles sur le niveau, il montre
## les étoiles infinies obtenues et, en bulle d'aide, le record de vagues.
func _setup_endless_button(button: Button, path: String, number: String) -> void:
	button.disabled = not Progress.is_endless_unlocked(path)
	if button.disabled:
		button.text = "%s\nVerrouillé" % number
		button.tooltip_text = "Gagner ce niveau avec 3 étoiles pour ouvrir son mode infini."
		return
	button.text = "%s  ∞\n%s" % [number, Progress.star_text(Progress.get_endless_stars(path), Progress.ENDLESS_MAX_STARS)]
	var record := Progress.get_endless_waves(path)
	button.tooltip_text = "Record : %d vague%s" % [record, "s" if record > 1 else ""] if record > 0 else "Pas encore joué"
	for color_name in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color"]:
		button.add_theme_color_override(color_name, ENDLESS_COLOR)


## Fenêtre de détail d'un niveau, à côté de son bouton : une ligne par vague.
func show_level_details(path: String) -> void:
	var button := get_level_button(path)
	if not button:
		return
	var world := CAMPAIGN.world_index_of(path)
	level_details.show_text(get_level_details(path), button.get_global_rect(), CAMPAIGN.worlds[world].color)


## Texte de la fenêtre de détail d'un niveau : nom, difficulté, or et vies de départ,
## puis la composition de chaque vague (élites et boss signalés).
func get_level_details(path: String) -> String:
	var difficulty := Difficulty.DEFAULT if endless_mode else Difficulty.get_current()
	var key := "%s|%d|%s" % [path, difficulty, endless_mode]
	if _details_cache.has(key):
		return _details_cache[key]
	var level: Level = load(path).instantiate()
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	if difficulty != Difficulty.MOYEN:
		spawner.apply_difficulty(difficulty)
	var world := CAMPAIGN.world_index_of(path)
	var number := "%d-%d" % [world + 1, CAMPAIGN.worlds[world].levels.find(path) + 1]
	var bonuses := Perks.get_bonuses()
	var lines: Array[String] = []
	lines.append("[b]%s[/b]   [color=#%s]%s[/color]" % [level.level_name if level.level_name.contains(number)
		else "%s  ·  %s" % [number, level.level_name], Difficulty.COLORS[difficulty].to_html(false),
		"Mode infini" if endless_mode else Difficulty.NAMES[difficulty]])
	lines.append("[color=%s]%d vagues  ·  Or de départ : %d  ·  Vies : %d[/color]" % [EnemyInfo.MUTED,
		spawner.get_wave_count(), level.starting_gold + bonuses.starting_gold_bonus,
		level.starting_lives + bonuses.lives_bonus])
	for i in spawner.get_wave_count():
		lines.append("[color=%s]V%d[/color]  %s" % [EnemyInfo.MUTED, i + 1, EnemyInfo.wave_line(spawner.waves[i], 18)])
	if endless_mode:
		lines.append("[color=%s]Puis les %d dernières vagues en boucle, de plus en plus dures.[/color]"
			% [EnemyInfo.MUTED, WaveSpawner.ENDLESS_CYCLE])
	level.free()
	_details_cache[key] = "\n".join(lines)
	return _details_cache[key]


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label
