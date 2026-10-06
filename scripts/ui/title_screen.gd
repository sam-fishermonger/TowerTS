extends Control
## Écran titre : reprend la campagne, ouvre la sélection des mondes et des niveaux,
## ouvre l'arbre des améliorations, ou quitte le jeu. Derrière le menu, une partie se
## joue toute seule (TitleDemo) ; le titre respire et les boutons réagissent au survol.
## Le code Konami (↑ ↑ ↓ ↓ ← → ← → B A) débloque tout : mondes, niveaux, modes infinis,
## améliorations et spécialisations.

const PERK_TREE_SCREEN := "res://scenes/ui/perk_tree_screen.tscn"
const WORLD_SELECT_SCREEN := "res://scenes/ui/world_select_screen.tscn"

const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")
## Agrandissement d'un bouton survolé ou qui a le focus.
const BUTTON_HOVER_SCALE := 1.06
const BUTTON_HOVER_DURATION := 0.12
## Apparition du menu : le panneau, puis les boutons l'un après l'autre.
const INTRO_DURATION := 0.5
const INTRO_STAGGER := 0.06
const KONAMI_CODE: Array[Key] = [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT,
	KEY_B, KEY_A]
## Durée du message affiché quand le code Konami est entré, en secondes.
const KONAMI_MESSAGE_DURATION := 3.0

var _time := 0.0
## Touches du code Konami déjà entrées dans l'ordre.
var _konami_progress := 0

@onready var play_button: Button = %PlayButton
@onready var perks_button: Button = %PerksButton
@onready var worlds_button: Button = %WorldsButton
@onready var quit_button: Button = %QuitButton
@onready var reset_button: Button = %ResetButton
@onready var reset_dialog: ConfirmationDialog = %ResetDialog
@onready var title: Label = %Title
@onready var panel: PanelContainer = %Panel
@onready var menu: VBoxContainer = %Menu
@onready var demo: TitleDemo = %Demo
## Niveau joué en fond.
@onready var demo_label: Label = %DemoLabel


func _ready() -> void:
	play_button.pressed.connect(func() -> void: open_level(Progress.get_next_to_play(CAMPAIGN)))
	worlds_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(WORLD_SELECT_SCREEN))
	perks_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(PERK_TREE_SCREEN))
	quit_button.pressed.connect(get_tree().quit)
	# Quitter n'a pas de sens dans un navigateur.
	quit_button.visible = not OS.has_feature("web")
	reset_button.pressed.connect(reset_dialog.popup_centered)
	reset_dialog.confirmed.connect(_on_reset_confirmed)
	_refresh()
	Sound.play_music()
	demo.level_started.connect(_on_demo_level_started)
	if demo.level:
		_on_demo_level_started(demo.level)
	for button in [play_button, worlds_button, perks_button, quit_button]:
		_add_hover_effect(button)
	_play_intro()
	play_button.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	# Le titre respire doucement et se balance un peu.
	title.pivot_offset = title.size / 2.0
	title.scale = Vector2.ONE * (1.0 + 0.035 * sin(_time * 2.2))
	title.rotation = 0.025 * sin(_time * 1.1)


## Les flèches servent aussi à passer d'un bouton à l'autre : le code est guetté dans
## _input, avant le menu, sans bloquer les touches.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		enter_konami_key(key.keycode if key.keycode != KEY_NONE else key.physical_keycode)


## Ajoute une touche au code Konami en cours ; débloque tout quand il est complet.
## Les lettres sont lues selon la disposition du clavier (le A d'un clavier AZERTY).
func enter_konami_key(keycode: Key) -> void:
	if keycode == KONAMI_CODE[_konami_progress]:
		_konami_progress += 1
	elif keycode == KEY_UP:
		# ↑ ↑ ↑ : les deux dernières flèches peuvent encore commencer le code.
		_konami_progress = 2 if _konami_progress == 2 else 1
	else:
		_konami_progress = 0
	if _konami_progress == KONAMI_CODE.size():
		_konami_progress = 0
		unlock_everything()


## Code Konami : tout est débloqué, les boutons se mettent à jour et un message le dit.
func unlock_everything() -> void:
	Perks.unlock_everything()
	_refresh()
	Sound.play(&"victory")
	var message := Label.new()
	message.text = "Code Konami : tout est débloqué !"
	message.add_theme_font_size_override(&"font_size", 28)
	message.add_theme_color_override(&"font_color", Progress.ENDLESS_STAR_COLOR)
	message.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.7))
	message.add_theme_constant_override(&"shadow_offset_x", 2)
	message.add_theme_constant_override(&"shadow_offset_y", 2)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(message)
	message.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	message.offset_top = 64.0
	var tween := message.create_tween()
	tween.tween_interval(KONAMI_MESSAGE_DURATION)
	tween.tween_property(message, "modulate:a", 0.0, 0.6)
	tween.tween_callback(message.queue_free)


func open_level(path: String) -> void:
	get_tree().change_scene_to_file(path)


## Boutons qui dépendent de la progression : Jouer ou Continuer, étoiles gagnées et
## à dépenser, effacement.
func _refresh() -> void:
	var earned := Perks.get_earned_stars()
	var any_won := earned > 0
	play_button.text = "Continuer" if any_won else "Jouer"
	worlds_button.text = "Mondes  ·  ★ %d / %d" % [earned, CAMPAIGN.size() * 3] if any_won else "Mondes"
	# Les étoiles non dépensées sont signalées sur le bouton de l'arbre.
	var available := Perks.get_available_stars()
	var endless_available := Perks.get_available_stars(true)
	perks_button.text = "Améliorations"
	if available > 0:
		perks_button.text += "  ·  ★ %d" % available
	if endless_available > 0:
		perks_button.text += "  ·  ∞ %d" % endless_available
	reset_button.visible = any_won


## Le panneau grandit en apparaissant, puis les lignes du menu s'affichent en cascade.
func _play_intro() -> void:
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2.ONE * 0.9
	panel.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(panel, "scale", Vector2.ONE, INTRO_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, INTRO_DURATION * 0.6)
	var rows := menu.get_children()
	for i in rows.size():
		var row := rows[i] as CanvasItem
		row.modulate.a = 0.0
		tween.tween_property(row, "modulate:a", 1.0, INTRO_DURATION * 0.6) \
			.set_delay(INTRO_DURATION * 0.3 + i * INTRO_STAGGER)


## Le bouton grossit un peu quand la souris le survole ou qu'il a le focus (clavier, manette).
func _add_hover_effect(button: Button) -> void:
	var grow := func(target_scale: float) -> void:
		button.pivot_offset = button.size / 2.0
		button.create_tween().tween_property(button, "scale", Vector2.ONE * target_scale,
			BUTTON_HOVER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	button.mouse_entered.connect(grow.bind(BUTTON_HOVER_SCALE))
	button.focus_entered.connect(grow.bind(BUTTON_HOVER_SCALE))
	button.mouse_exited.connect(func() -> void: grow.call(BUTTON_HOVER_SCALE if button.has_focus() else 1.0))
	button.focus_exited.connect(grow.bind(1.0))


func _on_demo_level_started(level: Level) -> void:
	var world := CAMPAIGN.world_index_of(level.scene_file_path)
	var world_name := CAMPAIGN.worlds[world].display_name if world >= 0 else ""
	demo_label.text = "▶  Démo  ·  %s  ·  %s" % [world_name, level.level_name]


func _on_reset_confirmed() -> void:
	Progress.reset_campaign()
	_refresh()
	play_button.grab_focus()
