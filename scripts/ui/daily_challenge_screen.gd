extends Control
## Défi du jour (depuis l'écran titre) : le niveau et les règles du jour, les tours
## imposées, le meilleur score du jour et ceux des derniers jours, et le bouton Jouer.

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"
const TITLE_COLOR := Color(0.95, 0.85, 0.45)
const SCORE_COLOR := Progress.ENDLESS_STAR_COLOR
const MUTED_COLOR := Color(0.75, 0.8, 0.75)
## Jours montrés dans l'historique des scores.
const HISTORY_DAYS := 7
const SHORT_MONTHS: Array[String] = ["janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.",
	"oct.", "nov.", "déc."]

## Défi affiché (celui d'aujourd'hui).
var challenge: DailyChallenge
var play_button: Button
var back_button: Button


func _ready() -> void:
	challenge = DailyChallenge.today()
	_build()
	Sound.play_music()
	play_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()


func go_back() -> void:
	get_tree().change_scene_to_file(TITLE_SCREEN)


func play() -> void:
	Level.open_challenge(get_tree(), challenge)


func _build() -> void:
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.06, 0.85)
	style.border_color = Color(SCORE_COLOR, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 44.0
	style.content_margin_right = 44.0
	style.content_margin_top = 28.0
	style.content_margin_bottom = 28.0
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size.x = 760.0
	panel.add_child(column)

	_add_label(column, "Défi du jour", 44, SCORE_COLOR, true)
	_add_label(column, _capitalized(challenge.get_date_text()),
		20, MUTED_COLOR, true)
	_add_label(column, challenge.get_level_title(), 28, TITLE_COLOR, true)

	# Tours imposées, avec leur image.
	var towers := HBoxContainer.new()
	towers.alignment = BoxContainer.ALIGNMENT_CENTER
	towers.add_theme_constant_override("separation", 20)
	column.add_child(towers)
	for data in challenge.get_towers():
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		var icon := TowerIcon.new()
		icon.data = data
		icon.custom_minimum_size = Vector2(56, 56)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(icon)
		var name_label := _add_label(box, data.display_name, 16, Color.WHITE, true)
		name_label.tooltip_text = data.description
		name_label.mouse_filter = Control.MOUSE_FILTER_STOP
		towers.add_child(box)

	var rules := RichTextLabel.new()
	rules.bbcode_enabled = true
	rules.fit_content = true
	rules.scroll_active = false
	rules.add_theme_font_size_override("normal_font_size", 18)
	rules.add_theme_font_size_override("bold_font_size", 18)
	var lines: Array[String] = []
	for rule in challenge.rules:
		var text := DailyChallenge.RULE_TEXTS[rule]
		lines.append("•  [b]%s[/b] : %s" % [DailyChallenge.RULE_NAMES[rule], text.left(1).to_lower() + text.substr(1)])
	lines.append("•  [b]Sans l'arbre des améliorations[/b] : tout le monde joue avec les mêmes tours et les mêmes prix.")
	rules.text = "\n".join(lines)
	column.add_child(rules)
	var score_rule := _add_label(column, DailyChallenge.describe_score(), 15, MUTED_COLOR, false)
	score_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	column.add_child(HSeparator.new())
	var best := Progress.get_daily_score(challenge.date_key)
	_add_label(column, "Meilleur score aujourd'hui : %d" % best if best >= 0 else "Pas encore joué aujourd'hui.",
		22, SCORE_COLOR, true)
	var history := get_history_text()
	if not history.is_empty():
		var history_label := _add_label(column, history, 15, MUTED_COLOR, true)
		history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	column.add_child(buttons)
	back_button = Button.new()
	back_button.text = "Retour"
	back_button.custom_minimum_size = Vector2(160, 48)
	back_button.pressed.connect(go_back)
	buttons.add_child(back_button)
	play_button = Button.new()
	play_button.text = "Jouer"
	play_button.custom_minimum_size = Vector2(220, 48)
	play_button.add_theme_font_size_override("font_size", 24)
	play_button.pressed.connect(play)
	buttons.add_child(play_button)


## Scores des derniers jours joués (avant aujourd'hui) et record de tous les défis, ou ""
## si aucun défi n'a encore été joué.
func get_history_text() -> String:
	var scores := Progress.get_daily_scores()
	if scores.is_empty():
		return ""
	var days := scores.keys()
	days.sort()
	days.reverse()
	var best_day: String = days[0]
	for day: String in days:
		if scores[day] > scores[best_day]:
			best_day = day
	var recent := PackedStringArray()
	for day: String in days:
		if day != challenge.date_key and recent.size() < HISTORY_DAYS:
			recent.append("%s : %d" % [_short_date(day), scores[day]])
	var text := "Record de tous les défis : %d (%s)  ·  %d défi%s joué%s" % [scores[best_day], _short_date(best_day),
		days.size(), "s" if days.size() > 1 else "", "s" if days.size() > 1 else ""]
	if not recent.is_empty():
		text += "\nDerniers jours : " + "   ".join(recent)
	return text


## « 6 oct. » pour « 2026-10-06 ».
static func _short_date(key: String) -> String:
	var parts := key.split("-")
	if parts.size() != 3:
		return key
	return "%d %s" % [parts[2].to_int(), SHORT_MONTHS[clampi(parts[1].to_int() - 1, 0, 11)]]


static func _capitalized(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)


func _add_label(parent: Control, text: String, font_size: int, color: Color, centered: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label
