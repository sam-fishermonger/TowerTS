extends Control
## Sélection du monde et du niveau (depuis l'écran titre) : une carte par monde de la
## campagne, avec son biome, ses monstres, ses étoiles et un bouton par niveau. Un monde
## se débloque en gagnant le dernier niveau du monde précédent.

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"
const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")
const LOCKED_ALPHA := 0.45

## Bouton de chaque niveau, par chemin de scène.
var _level_buttons := {}

@onready var worlds_box: HBoxContainer = %Worlds
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(go_back)
	_build_cards()
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
	get_tree().change_scene_to_file(path)


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

	var max_stars := world.levels.size() * 3
	var stars := _label("★ %d / %d" % [Progress.get_world_stars(world), max_stars], 20, Color(0.95, 0.85, 0.45))
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
		button.disabled = not Progress.is_unlocked(CAMPAIGN, first + i)
		button.text = "%d-%d\n%s" % [world_index + 1, i + 1,
			"Verrouillé" if button.disabled else Progress.star_text(Progress.get_stars(path))]
		_level_buttons[path] = button
		button.pressed.connect(open_level.bind(path))
		grid.add_child(button)
	column.add_child(grid)

	if not unlocked:
		var hint := _label("Gagner le dernier niveau de %s pour débloquer ce monde."
			% CAMPAIGN.worlds[world_index - 1].display_name, 15, Color(1, 1, 1, 0.6))
		hint.name = "LockedHint"
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(hint)
	return card


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label
