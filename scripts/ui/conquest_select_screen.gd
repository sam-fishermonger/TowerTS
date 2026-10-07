extends Control
## Choix d'un niveau du mode Conquête (depuis « Jouer », sur l'écran titre) : une carte
## par niveau (ConquestLevels), aux couleurs de son monde, avec ses étoiles et son bouton
## Jouer. Un niveau s'ouvre en gagnant le précédent. En bas, le choix de la difficulté,
## comme pour la campagne : chaque difficulté a ses propres étoiles.
## Les niveaux libres (free_select_screen.gd) reprennent cet écran avec leurs niveaux.

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"
const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")
const STARS_COLOR := Color(0.95, 0.85, 0.45)
const MUTED := Color(1, 1, 1, 0.6)
const LOCKED_ALPHA := 0.45
const CARD_WIDTH := 228.0

var back_button: Button
## Bouton Jouer de chaque niveau, dans l'ordre de ConquestLevels.LEVELS.
var play_buttons: Array[Button] = []

var _cards: HBoxContainer
var _difficulty_bar: HBoxContainer
var _difficulty_group := ButtonGroup.new()
var _hint: Label


func _ready() -> void:
	_build()
	_refresh()
	Sound.play_music()
	var first := play_buttons.filter(func(button: Button) -> bool: return not button.disabled)
	(first.back() if not first.is_empty() else back_button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()


func go_back() -> void:
	get_tree().change_scene_to_file(TITLE_SCREEN)


func open_level(index: int) -> void:
	if is_level_unlocked(index):
		Level.open(get_tree(), get_levels()[index])


# --- Ce qui change d'un mode à l'autre ------------------------------------------

func get_levels() -> Array[String]:
	return ConquestLevels.LEVELS


func get_level_info(index: int) -> Dictionary:
	return ConquestLevels.INFO[index]


func is_level_unlocked(index: int) -> bool:
	return ConquestLevels.is_unlocked(index)


func get_screen_title() -> String:
	return "Conquête"


func get_title_color() -> Color:
	return Conquest.STONE_COLOR


func get_intro() -> String:
	return ("Récoltez la pierre et l'essence avec vos ouvriers, bâtissez tours, dépôts, maisons, barricades "
		+ "et casernes, et protégez votre économie des Pillards. Les vagues partent seules.")


## Ligne propre au mode sous la présentation d'un niveau (vide : aucune).
func get_card_extra(index: int) -> Array:
	var world := CAMPAIGN.worlds[get_level_info(index).world]
	if world.raiders.is_empty():
		return []
	var raider: EnemyData = world.raiders[0]
	return [tr("Pillards : %s") % tr(raider.display_name), Enemy.RAID_COLOR]


func set_difficulty(difficulty: int) -> void:
	Difficulty.set_current(difficulty)
	_refresh()


func _build() -> void:
	var background := ColorRect.new()
	background.color = UiStyle.BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var title := Label.new()
	title.text = get_screen_title()
	title.theme_type_variation = UiStyle.TITLE_VARIATION
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 40)
	title.add_theme_color_override(&"font_color", get_title_color())
	add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 20.0

	var intro := Label.new()
	intro.text = get_intro()
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override(&"font_color", MUTED)
	add_child(intro)
	intro.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	intro.offset_left = 140.0
	intro.offset_right = -140.0
	intro.offset_top = 84.0

	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override(&"separation", 16)
	add_child(_cards)
	_cards.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cards.offset_top = 150.0
	_cards.offset_bottom = -190.0
	_cards.offset_left = 16.0
	_cards.offset_right = -16.0

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_color_override(&"font_color", MUTED)
	_hint.add_theme_font_size_override(&"font_size", 15)
	add_child(_hint)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_left = 120.0
	_hint.offset_right = -120.0
	_hint.offset_top = -176.0
	_hint.offset_bottom = -128.0

	_difficulty_bar = HBoxContainer.new()
	_difficulty_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_difficulty_bar.add_theme_constant_override(&"separation", 12)
	add_child(_difficulty_bar)
	_difficulty_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_difficulty_bar.offset_top = -116.0
	_difficulty_bar.offset_bottom = -76.0
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
		_difficulty_bar.add_child(button)

	back_button = Button.new()
	back_button.text = "Retour"
	back_button.custom_minimum_size = Vector2(180, 44)
	back_button.pressed.connect(go_back)
	add_child(back_button)
	back_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	back_button.offset_left = -90.0
	back_button.offset_right = 90.0
	back_button.offset_top = -64.0
	back_button.offset_bottom = -20.0


## Bouton d'une difficulté.
func get_difficulty_button(difficulty: int) -> Button:
	return _difficulty_bar.get_child(difficulty)


func _refresh() -> void:
	var difficulty := Difficulty.get_current()
	get_difficulty_button(difficulty).set_pressed_no_signal(true)
	var stars_rule := tr("Chaque difficulté a ses propres étoiles (3 par niveau), qui comptent aussi pour l'arbre des améliorations.")
	_hint.text = tr("%s : %s %s %s") % [tr(Difficulty.NAMES[difficulty]), Difficulty.describe(difficulty),
		Difficulty.describe_tower_limit(difficulty), stars_rule]
	for card in _cards.get_children():
		_cards.remove_child(card)
		card.queue_free()
	play_buttons.clear()
	for i in get_levels().size():
		_cards.add_child(_make_card(i, difficulty))


func _make_card(index: int, difficulty: int) -> PanelContainer:
	var info: Dictionary = get_level_info(index)
	var world := CAMPAIGN.worlds[info.world]
	var path := get_levels()[index]
	var unlocked := is_level_unlocked(index)
	var card := PanelContainer.new()
	# Avec beaucoup de niveaux, les cartes se resserrent pour tenir sur l'écran.
	var count := get_levels().size()
	card.custom_minimum_size.x = minf(CARD_WIDTH, (get_viewport_rect().size.x - 32.0 - 16.0 * (count - 1)) / count)
	card.add_theme_stylebox_override(&"panel", UiStyle.panel(world.color, 16.0, SIDE_TOP))
	card.modulate.a = 1.0 if unlocked else LOCKED_ALPHA
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	card.add_child(column)
	var number := _label(tr("Niveau %d  ·  %s") % [index + 1, tr(world.display_name)], 14, world.color.lightened(0.3))
	column.add_child(number)
	var name_label := _label(info.name, 24, Color.WHITE)
	name_label.theme_type_variation = UiStyle.TITLE_VARIATION
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(name_label)
	var description := _label(info.description, 15, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(description)
	var extra := get_card_extra(index)
	if not extra.is_empty():
		var extra_label := _label(extra[0], 14, extra[1])
		extra_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(extra_label)
	var stars := Progress.get_stars(path, difficulty)
	column.add_child(_label(Progress.star_text(stars), 30, STARS_COLOR))
	column.add_child(_label(tr("★ %d / %d (4 difficultés)") % [Progress.get_total_stars(path), Progress.MAX_LEVEL_STARS],
		14, MUTED))
	var play := Button.new()
	play.text = "Jouer" if unlocked else "Verrouillé"
	play.disabled = not unlocked
	play.custom_minimum_size = Vector2(0, 44)
	if not unlocked:
		play.tooltip_text = tr("Gagner « %s » pour l'ouvrir.") % tr(get_level_info(index - 1).name)
	play.pressed.connect(open_level.bind(index))
	column.add_child(play)
	play_buttons.append(play)
	return card


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label
