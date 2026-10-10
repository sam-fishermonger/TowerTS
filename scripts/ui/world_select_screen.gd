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
## Le bouton Mutateurs ouvre le choix des mutateurs (Mutators) : des règles du défi du
## jour qui durcissent les niveaux déjà gagnés, contre des étoiles infinies.
## Le mode infini et les mutateurs s'ouvrent au fil de la campagne (Unlocks) : verrouillés,
## leur bouton montre une bulle (LockBubble) qui dit comment les débloquer.

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"
const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")
const LOCKED_ALPHA := 0.45
const STARS_COLOR := Color(0.95, 0.85, 0.45)
## Ligne « niveau libre » de la fenêtre de détail.
const FREE_COLOR := "#ffd27a"
const ENDLESS_COLOR := Progress.ENDLESS_STAR_COLOR
const LEVEL_BUTTON_WIDTH := 104.0
## Assez bas pour que les 7 niveaux d'un monde (4 rangées) tiennent sur la carte.
const LEVEL_BUTTON_HEIGHT := 46.0

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
## Bulle des boutons verrouillés (Mode infini, Mutateurs).
var lock_bubble: LockBubble

@onready var worlds_box: HBoxContainer = %Worlds
@onready var back_button: Button = %BackButton
@onready var mode_button: Button = %ModeButton
@onready var title_label: Label = %Title
## Règles du mode affiché, en bas de l'écran.
@onready var mode_hint: Label = %ModeHint
## Choix de la difficulté (caché en mode infini, qui se joue toujours en Moyen).
@onready var difficulty_bar: HBoxContainer = %DifficultyBar
## Ouvre le choix des mutateurs (caché en mode infini).
@onready var mutators_button: Button = %MutatorsButton

## Fenêtre du choix des mutateurs (null quand elle est fermée), et sa case de chaque
## mutateur, par règle.
var mutators_panel: Control
var _mutator_checks := {}


func _ready() -> void:
	back_button.pressed.connect(go_back)
	level_details = DetailPopup.new(470.0)
	add_child(level_details)
	_build_difficulty_buttons()
	lock_bubble = LockBubble.new()
	add_child(lock_bubble)
	lock_bubble.watch(mode_button, Unlocks.get_hint.bind(Unlocks.Feature.ENDLESS), true)
	lock_bubble.watch(mutators_button, Unlocks.get_hint.bind(Unlocks.Feature.MUTATORS), true)
	mode_button.toggled.connect(set_endless_mode)
	mutators_button.pressed.connect(open_mutators)
	set_endless_mode(false)
	Sound.play_music()
	var next := get_level_button(Progress.get_next_to_play(CAMPAIGN))
	(next if next else back_button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if mutators_panel:
			close_mutators()
		else:
			go_back()


func go_back() -> void:
	get_tree().change_scene_to_file(TITLE_SCREEN)


func open_level(path: String) -> void:
	Level.open(get_tree(), path, endless_mode)


## Affiche les cartes du mode infini (true) ou de la campagne (false).
## Tant que le mode infini est verrouillé, le bouton ne fait que montrer sa bulle.
func set_endless_mode(value: bool) -> void:
	if value and not Unlocks.is_unlocked(Unlocks.Feature.ENDLESS):
		value = false
		lock_bubble.show_for(mode_button, Unlocks.get_hint(Unlocks.Feature.ENDLESS))
	endless_mode = value
	mode_button.set_pressed_no_signal(value)
	title_label.text = "Mode infini" if value else "Choisir un monde"
	title_label.add_theme_color_override(&"font_color", ENDLESS_COLOR if value else STARS_COLOR)
	difficulty_bar.visible = not value
	mutators_button.visible = not value
	if value and mutators_panel:
		close_mutators()
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
		mode_hint.text = tr("Les vagues ne s'arrêtent plus et durcissent sans fin. Un crâne ☠ toutes les %d vagues repoussées au-delà de celles du niveau (%d par niveau) : ils achètent les spécialisations des tours, dans Améliorations.") \
			% [Progress.ENDLESS_STAR_STEP, Progress.ENDLESS_MAX_STARS]
	else:
		mode_hint.text = tr("%s : %s %s Chaque difficulté a ses propres étoiles (3 par niveau). Gagner un niveau avec 3 étoiles ouvre son mode infini.") \
			% [tr(Difficulty.NAMES[difficulty]), Difficulty.describe(difficulty), Difficulty.describe_tower_limit(difficulty)]
		var mutators := Mutators.get_active()
		if not mutators.is_empty():
			mode_hint.text += "\n" + tr("✦ Mutateurs sur les niveaux déjà gagnés : %s (☠ %d par victoire).") \
				% [Mutators.names(mutators), Mutators.stars_for(mutators)]
	_refresh_mutators_button()
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


## Largeur du contenu d'une carte de monde : l'écran partagé entre les mondes, sans les
## marges.
func get_card_content_width() -> float:
	var worlds := maxi(CAMPAIGN.worlds.size(), 1)
	var separation := worlds_box.get_theme_constant(&"separation")
	return (get_viewport_rect().size.x - 48.0 - separation * (worlds - 1)) / worlds - 32.0


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
	var style := UiStyle.panel(world.color if unlocked else world.color.darkened(0.6), 16.0, SIDE_TOP)
	card.add_theme_stylebox_override(&"panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	card.add_child(column)

	var number := _label(tr("Monde %d") % (world_index + 1), 16, Color(1, 1, 1, 0.55))
	column.add_child(number)
	var title := _label(world.display_name, 30, world.color)
	title.name = "WorldName"
	column.add_child(title)
	var description := _label(world.description, 15, Color(0.85, 0.88, 0.85))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.y = 64
	column.add_child(description)

	# Les monstres du biome, avec leur nom en bulle d'aide.
	# Avec quatre mondes, les cartes sont plus étroites : les images des monstres
	# rapetissent pour tenir sur une ligne, et les niveaux passent sur deux colonnes.
	var content_width := get_card_content_width()
	var icon_size := clampf((content_width - 4.0 * (world.enemies.size() - 1)) / maxf(world.enemies.size(), 1.0),
		28.0, 48.0)
	var bestiary := HBoxContainer.new()
	bestiary.alignment = BoxContainer.ALIGNMENT_CENTER
	bestiary.add_theme_constant_override(&"separation", 4)
	for enemy in world.enemies:
		var icon := TextureRect.new()
		icon.texture = enemy.texture
		icon.custom_minimum_size = Vector2.ONE * icon_size
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text = enemy.display_name
		icon.modulate.a = 1.0 if unlocked else LOCKED_ALPHA
		bestiary.add_child(icon)
	column.add_child(bestiary)

	var stars: Label
	if endless_mode:
		stars = _label("%s %d / %d" % [Progress.SKULL, Progress.get_world_endless_stars(world),
			world.levels.size() * Progress.ENDLESS_MAX_STARS], 20, ENDLESS_COLOR)
	else:
		stars = _label("★ %d / %d" % [Progress.get_world_stars(world), world.levels.size() * Progress.MAX_LEVEL_STARS],
			20, STARS_COLOR)
		stars.tooltip_text = "Étoiles des 4 difficultés"
		stars.mouse_filter = Control.MOUSE_FILTER_PASS
	stars.name = "Stars"
	column.add_child(stars)

	var grid := GridContainer.new()
	grid.columns = 3 if content_width >= 3 * LEVEL_BUTTON_WIDTH + 16.0 else 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override(&"h_separation", 8)
	grid.add_theme_constant_override(&"v_separation", 6)
	var first := CAMPAIGN.first_level_index(world_index)
	for i in world.levels.size():
		var path := world.levels[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(LEVEL_BUTTON_WIDTH, LEVEL_BUTTON_HEIGHT)
		if endless_mode:
			_setup_endless_button(button, path, "%d-%d" % [world_index + 1, i + 1])
		else:
			button.disabled = not Progress.is_unlocked(CAMPAIGN, first + i)
			button.text = "%d-%d\n%s" % [world_index + 1, i + 1,
				tr("Verrouillé") if button.disabled else Progress.star_text(Progress.get_stars(path, Difficulty.get_current()))]
			if not button.disabled:
				button.tooltip_text = _level_tooltip(path)
			if Mutators.applies_to(CAMPAIGN, path) and not Mutators.get_active().is_empty():
				for color_name in [&"font_color", &"font_hover_color", &"font_focus_color"]:
					button.add_theme_color_override(color_name, Mutators.COLOR)
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
		var hint := _label(tr("Gagner le dernier niveau de %s pour débloquer ce monde.")
			% tr(CAMPAIGN.worlds[world_index - 1].display_name), 15, Color(1, 1, 1, 0.6))
		hint.name = "LockedHint"
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(hint)
	return card


## Étoiles d'un niveau dans chaque difficulté, une ligne par difficulté.
func _level_tooltip(path: String) -> String:
	var lines: Array[String] = []
	for d in Difficulty.COUNT:
		lines.append("%s  %s" % [Progress.star_text(Progress.get_stars(path, d)), tr(Difficulty.NAMES[d])])
	if Progress.get_stars(path) > 0:
		lines.append(tr("%s  Mutateurs") % Progress.skull_text(Progress.get_mutator_stars(path), Mutators.MAX_STARS))
	return "\n".join(lines)


## Bouton d'un niveau en mode infini : ouvert avec 3 étoiles sur le niveau, il montre
## les étoiles infinies obtenues et, en bulle d'aide, le record de vagues.
func _setup_endless_button(button: Button, path: String, number: String) -> void:
	button.disabled = not Progress.is_endless_unlocked(path)
	if button.disabled:
		button.text = "%s\n%s" % [number, tr("Verrouillé")]
		button.tooltip_text = "Gagner ce niveau avec 3 étoiles pour ouvrir son mode infini."
		return
	button.text = "%s  ∞\n%s" % [number, Progress.skull_text(Progress.get_endless_stars(path), Progress.ENDLESS_MAX_STARS)]
	var record := Progress.get_endless_waves(path)
	button.tooltip_text = (tr("Record : %d vagues") if record > 1 else tr("Record : %d vague")) % record if record > 0 \
		else "Pas encore joué"
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
	var mutators: Array[int] = []
	if not endless_mode and Mutators.applies_to(CAMPAIGN, path):
		mutators = Mutators.get_active()
	var key := "%s|%d|%s|%s" % [path, difficulty, endless_mode, mutators]
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
	lines.append("[b]%s[/b]   [color=#%s]%s[/color]" % [tr(level.level_name) if level.level_name.contains(number)
		else "%s  ·  %s" % [number, tr(level.level_name)], Difficulty.COLORS[difficulty].to_html(false),
		tr("Mode infini") if endless_mode else tr(Difficulty.NAMES[difficulty])])
	lines.append(tr("[color=%s]%d vagues  ·  Or de départ : %d  ·  Vies : %d[/color]") % [EnemyInfo.MUTED,
		spawner.get_wave_count(), level.starting_gold + bonuses.starting_gold_bonus,
		level.starting_lives + bonuses.lives_bonus])
	if not mutators.is_empty():
		lines.append(tr("[color=#%s]✦ Mutateurs : %s  ·  ☠ %d / %d[/color]") % [Mutators.COLOR.to_html(false),
			Mutators.names(mutators), Progress.get_mutator_stars(path), Mutators.MAX_STARS])
	if (level.get_node("Map") as GameMap).free_layout:
		lines.append(tr("[color=%s]Niveau libre : pas de chemin, vos tours font le labyrinthe.[/color]") % FREE_COLOR)
	for i in spawner.get_wave_count():
		lines.append(tr("[color=%s]V%d[/color]  %s") % [EnemyInfo.MUTED, i + 1, EnemyInfo.wave_line(spawner.waves[i], 18)])
	if endless_mode:
		lines.append(tr("[color=%s]Puis les %d dernières vagues en boucle, de plus en plus dures.[/color]")
			% [EnemyInfo.MUTED, WaveSpawner.ENDLESS_CYCLE])
	level.free()
	_details_cache[key] = "\n".join(lines)
	return _details_cache[key]


# --- Mutateurs ----------------------------------------------------------------

## Ouvre la fenêtre du choix des mutateurs, au milieu de l'écran.
func open_mutators() -> void:
	if mutators_panel or not Unlocks.is_unlocked(Unlocks.Feature.MUTATORS):
		return
	level_details.close()
	# Fond qui assombrit l'écran et prend les clics : rien ne se lance derrière la fenêtre.
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mutators_panel = shade
	var center := CenterContainer.new()
	shade.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	var style := UiStyle.panel(Mutators.COLOR, 24.0, SIDE_TOP)
	style.content_margin_left = 36.0
	style.content_margin_right = 36.0
	panel.add_theme_stylebox_override(&"panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	column.custom_minimum_size.x = 640.0
	panel.add_child(column)
	var title := _label("✦  Mutateurs", 36, Mutators.COLOR)
	UiStyle.style_title(title)
	column.add_child(title)
	var intro := _label(tr("Des règles du défi du jour pour rejouer les niveaux déjà gagnés, dans la difficulté choisie. Chaque mutateur actif rapporte un crâne ☠ à la victoire, %d au plus par niveau : ils achètent les spécialisations des tours, dans Améliorations.")
		% Mutators.MAX_STARS, 16, Color(0.85, 0.88, 0.85))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(intro)
	_mutator_checks.clear()
	var active := Mutators.get_active()
	for rule in Mutators.LIST:
		var check := CheckButton.new()
		check.text = DailyChallenge.describe_rule(rule)
		check.button_pressed = active.has(rule)
		check.add_theme_font_size_override(&"font_size", 18)
		check.toggled.connect(func(on: bool) -> void:
			Mutators.set_enabled(rule, on)
			_refresh())
		column.add_child(check)
		_mutator_checks[rule] = check
	var close := Button.new()
	close.text = "Fermer"
	close.custom_minimum_size = Vector2(180, 44)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(close_mutators)
	column.add_child(close)
	(_mutator_checks[Mutators.LIST[0]] as Control).grab_focus()


func close_mutators() -> void:
	if not mutators_panel:
		return
	mutators_panel.queue_free()
	mutators_panel = null
	_mutator_checks.clear()
	mutators_button.grab_focus()


## Case d'un mutateur dans la fenêtre ouverte (null sinon).
func get_mutator_check(rule: int) -> CheckButton:
	return _mutator_checks.get(rule)


func _refresh_mutators_button() -> void:
	var count := Mutators.get_active().size()
	mutators_button.text = tr("✦  Mutateurs") + ("  ·  %d" % count if count > 0 else "")
	mutators_button.tooltip_text = tr("Règles du défi du jour sur les niveaux déjà gagnés, contre des crânes.")
	var mutators_locked := not Unlocks.is_unlocked(Unlocks.Feature.MUTATORS)
	LockBubble.set_locked(mutators_button, mutators_locked)
	if mutators_locked:
		mutators_button.tooltip_text = ""
	mode_button.text = tr("∞  Mode infini")
	LockBubble.set_locked(mode_button, not Unlocks.is_unlocked(Unlocks.Feature.ENDLESS))


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label
