extends Control
## Page des succès (depuis l'écran titre) : une vignette par succès, avec son objectif,
## son avancement quand il est chiffré (monstres détruits, étoiles…) et la date de son
## déblocage. Les succès pas encore débloqués sont grisés.

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"
const TITLE_COLOR := Color(0.95, 0.85, 0.45)
const MUTED := Color(1, 1, 1, 0.6)
const LOCKED_COLOR := Color(0.55, 0.55, 0.55)
const COLUMNS := 3

## Vignettes, dans l'ordre de Achievements.LIST.
var cards: Array[PanelContainer] = []
var counter_label: Label
var back_button: Button


func _ready() -> void:
	# La progression a pu remplir des objectifs depuis la dernière partie (arbre, étoiles).
	Achievements.check_progress()
	_build()
	Sound.play_music()
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()


func go_back() -> void:
	get_tree().change_scene_to_file(TITLE_SCREEN)


func _build() -> void:
	var title := Label.new()
	title.text = "Succès"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 40)
	title.add_theme_color_override(&"font_color", TITLE_COLOR)
	UiStyle.style_title(title)
	add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 16.0

	var unlocked := Achievements.get_unlocked_count()
	var total := Achievements.LIST.size()
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override(&"separation", 16)
	add_child(header)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_top = 72.0
	header.offset_bottom = 100.0
	counter_label = _label("%d / %d débloqués" % [unlocked, total], 20, Achievements.COLOR)
	header.add_child(counter_label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(320, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.max_value = total
	bar.value = unlocked
	bar.add_theme_stylebox_override(&"fill", UiStyle.bar_fill(Achievements.COLOR))
	bar.add_theme_stylebox_override(&"background", UiStyle.bar_background(Achievements.COLOR))
	header.add_child(bar)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 24.0
	scroll.offset_right = -24.0
	scroll.offset_top = 116.0
	scroll.offset_bottom = -76.0
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override(&"h_separation", 12)
	grid.add_theme_constant_override(&"v_separation", 10)
	scroll.add_child(grid)
	for definition in Achievements.LIST:
		var card := _card(definition)
		cards.append(card)
		grid.add_child(card)

	back_button = Button.new()
	back_button.text = "Retour"
	back_button.custom_minimum_size = Vector2(180, 44)
	back_button.add_theme_font_size_override(&"font_size", 20)
	back_button.pressed.connect(go_back)
	add_child(back_button)
	back_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back_button.offset_left = 24.0
	back_button.offset_top = -64.0
	back_button.offset_right = 204.0
	back_button.offset_bottom = -20.0


## Vignette d'un succès : pastille avec son symbole, nom, objectif, puis son avancement
## ou la date de son déblocage.
func _card(definition: Dictionary) -> PanelContainer:
	var unlocked := Achievements.is_unlocked(definition.id)
	var color := Achievements.COLOR if unlocked else LOCKED_COLOR
	var card := PanelContainer.new()
	card.name = definition.id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.y = 84.0
	card.tooltip_text = definition.description
	var style := UiStyle.panel(Color(color, 0.9 if unlocked else 0.35), 10.0)
	if unlocked:
		style.bg_color = Color(0.1, 0.1, 0.07, 0.95)
	card.add_theme_stylebox_override(&"panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	card.add_child(row)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(56, 56)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(color, 0.22 if unlocked else 0.08)
	badge_style.border_color = color
	badge_style.set_border_width_all(2)
	badge.add_theme_stylebox_override(&"panel", badge_style)
	var icon := _label(definition.icon if unlocked else "?", 26, color)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(icon)
	row.add_child(badge)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", 2)
	row.add_child(column)
	column.add_child(_label(definition.name, 18, color if unlocked else Color(0.85, 0.85, 0.85)))
	var description := _label(definition.description, 14, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)
	var progress := Achievements.get_progress(definition)
	if unlocked:
		var date := Time.get_date_dict_from_unix_time(Achievements.get_unlock_time(definition.id))
		column.add_child(_label("Débloqué le %02d/%02d/%d" % [date.day, date.month, date.year], 13,
			Color(Achievements.COLOR, 0.8)))
	elif not progress.is_empty():
		column.add_child(_label("%s / %s" % [LevelStats.format_number(mini(progress[0], progress[1])),
			LevelStats.format_number(progress[1])], 13, Color(0.75, 0.85, 1.0)))
	return card


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label
