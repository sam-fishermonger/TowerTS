class_name OptionsMenu
extends Control
## Menu Options, ouvert depuis l'écran titre ou en jeu : langue, musique et sons (chacun
## avec sa case pour le couper et son curseur de volume), plein écran, vitesse de jeu au
## lancement d'un niveau, puis l'accessibilité : taille du texte, mode daltonien et
## vibrations (téléphone et manette). Chaque réglage s'applique et s'enregistre tout de suite
## (voir Sound et GameSettings). Couvre tout l'écran ; **Fermer** ou Échap le referme.

signal closed

const GOLD := Color(0.95, 0.85, 0.45)
const ROW_HEIGHT := 44.0

var music_check: CheckButton
var music_slider: HSlider
var sound_check: CheckButton
var sound_slider: HSlider
var fullscreen_check: CheckButton
## Un bouton par vitesse de GameSettings.DEFAULT_SPEEDS.
var speed_buttons: Array[Button] = []
## Un bouton par langue de GameSettings.LANGUAGES, dans le même ordre.
var language_buttons: Array[Button] = []
## Un bouton par taille de GameSettings.TEXT_SCALES.
var text_scale_buttons: Array[Button] = []
var colorblind_check: CheckButton
var vibration_check: CheckButton
var close_button: Button

var _music_value: Label
var _sound_value: Label
var _speed_group := ButtonGroup.new()
var _language_group := ButtonGroup.new()
var _text_scale_group := ButtonGroup.new()


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Utilisable pendant la pause (en jeu, le menu met la partie en pause).
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var style := UiStyle.panel(UiStyle.ACCENT, 28.0, SIDE_TOP, Color(0.03, 0.06, 0.09, 0.97))
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)

	var title := _label("Options", 32, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)

	# La langue d'abord : c'est la ligne que cherche celui qui ne lit pas le français.
	var language_label := _label("Langue", 20, Color.WHITE)
	language_label.custom_minimum_size.y = ROW_HEIGHT
	language_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var language_row := HBoxContainer.new()
	language_row.add_theme_constant_override("separation", 6)
	for code: String in GameSettings.LANGUAGES:
		var button := Button.new()
		button.text = GameSettings.LANGUAGES[code]
		# Chaque langue garde son propre nom, quelle que soit la langue choisie.
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.toggle_mode = true
		button.button_group = _language_group
		button.custom_minimum_size = Vector2(124, ROW_HEIGHT)
		button.add_theme_font_size_override(&"font_size", 20)
		button.pressed.connect(func() -> void:
			GameSettings.set_language(code)
			refresh())
		language_row.add_child(button)
		language_buttons.append(button)
	_add_row(grid, language_label, language_row, Control.new())

	music_check = _check("Musique", Sound.is_music_enabled())
	music_slider = _slider(Sound.get_music_volume())
	_music_value = _label("", 18, Color(1, 1, 1, 0.8))
	_add_row(grid, music_check, music_slider, _music_value)
	music_check.toggled.connect(func(on: bool) -> void:
		Sound.set_music_enabled(on)
		refresh())
	music_slider.value_changed.connect(func(value: float) -> void:
		Sound.set_music_volume(value / 100.0)
		refresh())

	sound_check = _check("Sons", Sound.is_sound_enabled())
	sound_slider = _slider(Sound.get_sound_volume())
	_sound_value = _label("", 18, Color(1, 1, 1, 0.8))
	_add_row(grid, sound_check, sound_slider, _sound_value)
	sound_check.toggled.connect(func(on: bool) -> void:
		Sound.set_sound_enabled(on)
		refresh())
	sound_slider.value_changed.connect(func(value: float) -> void:
		Sound.set_sound_volume(value / 100.0)
		# On entend tout de suite le volume choisi.
		Sound.play(&"coins")
		refresh())

	fullscreen_check = _check("Plein écran", GameSettings.is_fullscreen())
	fullscreen_check.tooltip_text = "F11 ou Alt + Entrée, à tout moment"
	var fullscreen_row: Array[Control] = [fullscreen_check, Control.new(), Control.new()]
	_add_row(grid, fullscreen_row[0], fullscreen_row[1], fullscreen_row[2])
	# Sur téléphone, le jeu occupe déjà tout l'écran : la ligne n'a pas lieu d'être.
	for cell in fullscreen_row:
		cell.visible = not OS.has_feature("mobile")
	fullscreen_check.toggled.connect(func(on: bool) -> void:
		GameSettings.set_fullscreen(on)
		# Le navigateur peut refuser : la case suit la fenêtre.
		refresh.call_deferred())

	var speed_label := _label("Vitesse au départ", 20, Color.WHITE)
	speed_label.custom_minimum_size.y = ROW_HEIGHT
	speed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 6)
	for speed in GameSettings.DEFAULT_SPEEDS:
		var button := Button.new()
		button.text = "x%s" % str(speed).trim_suffix(".0")
		button.toggle_mode = true
		button.button_group = _speed_group
		button.custom_minimum_size = Vector2(64, ROW_HEIGHT)
		button.add_theme_font_size_override(&"font_size", 20)
		button.pressed.connect(func() -> void:
			GameSettings.set_default_speed(speed)
			refresh())
		speed_row.add_child(button)
		speed_buttons.append(button)
	_add_row(grid, speed_label, speed_row, Control.new())

	var text_label := _label("Taille du texte", 20, Color.WHITE)
	text_label.custom_minimum_size.y = ROW_HEIGHT
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var text_row := HBoxContainer.new()
	text_row.add_theme_constant_override("separation", 6)
	for i in GameSettings.TEXT_SCALES.size():
		var scale := GameSettings.TEXT_SCALES[i]
		var button := Button.new()
		button.text = GameSettings.TEXT_SCALE_NAMES[i]
		button.toggle_mode = true
		button.button_group = _text_scale_group
		button.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		button.add_theme_font_size_override(&"font_size", 20)
		button.pressed.connect(func() -> void:
			GameSettings.set_text_scale(scale)
			refresh())
		text_row.add_child(button)
		text_scale_buttons.append(button)
	_add_row(grid, text_label, text_row, Control.new())

	colorblind_check = _check("Mode daltonien", GameSettings.is_colorblind())
	colorblind_check.tooltip_text = "Portées et auras en bleu et orange plutôt qu'en vert et rouge"
	_add_row(grid, colorblind_check, _label("Bleu et orange au lieu de vert et rouge", 16, Color(1, 1, 1, 0.6)),
		Control.new())
	colorblind_check.toggled.connect(func(on: bool) -> void:
		GameSettings.set_colorblind(on)
		refresh())

	vibration_check = _check("Vibrations", Gamepad.is_vibration_enabled())
	_add_row(grid, vibration_check, _label("Vie perdue et arrivée d'un boss (téléphone, manette)", 16,
		Color(1, 1, 1, 0.6)), Control.new())
	vibration_check.toggled.connect(func(on: bool) -> void:
		Gamepad.set_vibration_enabled(on)
		if on:
			Gamepad.rumble(&"life_lost")
		refresh())

	var hint := _label("Chaque niveau commence à la vitesse choisie.", 14, Color(1, 1, 1, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)

	close_button = Button.new()
	close_button.text = "Fermer"
	close_button.custom_minimum_size = Vector2(200, ROW_HEIGHT)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.add_theme_font_size_override(&"font_size", 22)
	close_button.pressed.connect(close)
	column.add_child(close_button)
	refresh()
	close_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	closed.emit()
	queue_free()


## Remet les commandes à jour d'après les réglages enregistrés.
func refresh() -> void:
	music_check.set_pressed_no_signal(Sound.is_music_enabled())
	sound_check.set_pressed_no_signal(Sound.is_sound_enabled())
	music_slider.set_value_no_signal(Sound.get_music_volume() * 100.0)
	sound_slider.set_value_no_signal(Sound.get_sound_volume() * 100.0)
	music_slider.editable = music_check.button_pressed
	sound_slider.editable = sound_check.button_pressed
	_music_value.text = "%d %%" % roundi(music_slider.value) if music_check.button_pressed else "coupée"
	_sound_value.text = "%d %%" % roundi(sound_slider.value) if sound_check.button_pressed else "coupés"
	fullscreen_check.set_pressed_no_signal(GameSettings.is_fullscreen())
	var languages := GameSettings.LANGUAGES.keys()
	for i in language_buttons.size():
		language_buttons[i].set_pressed_no_signal(languages[i] == GameSettings.get_language())
	colorblind_check.set_pressed_no_signal(GameSettings.is_colorblind())
	vibration_check.set_pressed_no_signal(Gamepad.is_vibration_enabled())
	var text_scale := GameSettings.get_text_scale()
	for i in text_scale_buttons.size():
		text_scale_buttons[i].set_pressed_no_signal(is_equal_approx(GameSettings.TEXT_SCALES[i], text_scale))
	var default_speed := GameSettings.get_default_speed()
	for i in speed_buttons.size():
		speed_buttons[i].set_pressed_no_signal(is_equal_approx(GameSettings.DEFAULT_SPEEDS[i], default_speed))


func _add_row(grid: GridContainer, first: Control, second: Control, third: Control) -> void:
	grid.add_child(first)
	grid.add_child(second)
	grid.add_child(third)


func _check(text_value: String, on: bool) -> CheckButton:
	var check := CheckButton.new()
	check.text = text_value
	check.button_pressed = on
	check.custom_minimum_size = Vector2(200, ROW_HEIGHT)
	check.add_theme_font_size_override(&"font_size", 20)
	return check


## Curseur de 0 à 100 (le volume en pourcentage), assez épais pour le doigt.
func _slider(volume: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 5.0
	slider.value = volume * 100.0
	slider.custom_minimum_size = Vector2(260, ROW_HEIGHT)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return slider


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.custom_minimum_size.x = 70.0 if text_value.is_empty() else 0.0
	return label
