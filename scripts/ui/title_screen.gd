extends Control
## Écran titre. « Jouer » ouvre le choix du mode : reprendre la campagne (la toute première
## fois, elle commence par le tutoriel), le tutoriel, la sélection des mondes et des niveaux, le défi du jour, le mode Conquête, les niveaux libres,
## l'Expédition ou l'éditeur de niveau. Les modes s'ouvrent au fil de la campagne (Unlocks) :
## un mode verrouillé affiche une bulle (LockBubble) qui dit comment le débloquer. Le menu
## principal ouvre aussi l'arbre des améliorations, le lexique (tours, monstres, mondes), les succès ou les options, ou quitte le jeu. Derrière le menu, une partie se
## joue toute seule (TitleDemo) ; le titre respire et les boutons réagissent au survol.
## Le code Konami (↑ ↑ ↓ ↓ ← → ← → B A) débloque tout : mondes, niveaux, modes infinis,
## améliorations et spécialisations.

const PERK_TREE_SCREEN := "res://scenes/ui/perk_tree_screen.tscn"
const WORLD_SELECT_SCREEN := "res://scenes/ui/world_select_screen.tscn"
const LEXICON_SCREEN := "res://scenes/ui/lexicon_screen.tscn"
const DAILY_CHALLENGE_SCREEN := "res://scenes/ui/daily_challenge_screen.tscn"
const LEVEL_EDITOR := "res://scenes/ui/level_editor.tscn"
const ACHIEVEMENTS_SCREEN := "res://scenes/ui/achievements_screen.tscn"

const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")
## Agrandissement d'un bouton survolé ou qui a le focus.
const BUTTON_HOVER_SCALE := 1.06
const BUTTON_HOVER_DURATION := 0.12
## Apparition du menu : le panneau, puis les boutons l'un après l'autre.
const INTRO_DURATION := 0.5
const INTRO_STAGGER := 0.06
const KONAMI_CODE: Array[Key] = [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT,
	KEY_B, KEY_A]
## Flèches du pavé numérique (sans Verr. Num.), comptées comme les flèches.
const KEYPAD_ARROWS := {KEY_KP_8: KEY_UP, KEY_KP_2: KEY_DOWN, KEY_KP_4: KEY_LEFT, KEY_KP_6: KEY_RIGHT}
## Le code en cours s'affiche (une pastille par touche) à partir de ce nombre de touches justes.
const KONAMI_SHOWN_FROM := 3
## Durée du message affiché quand le code Konami est entré, en secondes.
const KONAMI_MESSAGE_DURATION := 3.0

var _time := 0.0
## Touches du code Konami déjà entrées dans l'ordre.
var _konami_progress := 0
var _konami_label: Label
## Bulle des modes verrouillés.
var lock_bubble: LockBubble
## Mode de chaque bouton qui se débloque avec la progression (Unlocks.Feature).
var _locked_features := {}

@onready var play_button: Button = %PlayButton
## Reprendre la partie enregistrée entre deux vagues (SavedGame), s'il y en a une, et
## sous le bouton, son niveau et sa vague.
@onready var resume_button: Button = %ResumeButton
@onready var resume_info: Label = %ResumeInfo
@onready var campaign_button: Button = %CampaignButton
@onready var tutorial_button: Button = %TutorialButton
@onready var back_button: Button = %BackButton
@onready var subtitle: Label = %Subtitle
@onready var perks_button: Button = %PerksButton
@onready var worlds_button: Button = %WorldsButton
@onready var daily_button: Button = %DailyButton
@onready var conquest_button: Button = %ConquestButton
@onready var free_button: Button = %FreeButton
@onready var expedition_button: Button = %ExpeditionButton
@onready var editor_button: Button = %EditorButton
@onready var lexicon_button: Button = %LexiconButton
@onready var achievements_button: Button = %AchievementsButton
@onready var options_button: Button = %OptionsButton
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
	play_button.pressed.connect(show_play_menu.bind(true))
	resume_button.pressed.connect(func() -> void: SavedGame.resume(get_tree()))
	back_button.pressed.connect(show_play_menu.bind(false))
	campaign_button.pressed.connect(func() -> void: open_level(get_campaign_start()))
	tutorial_button.pressed.connect(func() -> void: open_level(Tutorial.LEVEL_PATH))
	worlds_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(WORLD_SELECT_SCREEN))
	perks_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(PERK_TREE_SCREEN))
	lock_bubble = LockBubble.new()
	add_child(lock_bubble)
	_connect_feature(daily_button, Unlocks.Feature.DAILY,
		func() -> void: get_tree().change_scene_to_file(DAILY_CHALLENGE_SCREEN))
	_connect_feature(conquest_button, Unlocks.Feature.CONQUEST,
		func() -> void: get_tree().change_scene_to_file(ConquestLevels.SELECT_SCREEN))
	_connect_feature(free_button, Unlocks.Feature.FREE_LEVELS,
		func() -> void: get_tree().change_scene_to_file(FreeLevels.SELECT_SCREEN))
	_connect_feature(expedition_button, Unlocks.Feature.EXPEDITION, start_expedition)
	_connect_feature(editor_button, Unlocks.Feature.EDITOR,
		func() -> void: get_tree().change_scene_to_file(LEVEL_EDITOR))
	lexicon_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(LEXICON_SCREEN))
	achievements_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(ACHIEVEMENTS_SCREEN))
	options_button.pressed.connect(open_options)
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
	for button in [resume_button, play_button, campaign_button, tutorial_button, worlds_button, daily_button, conquest_button, free_button,
			expedition_button, editor_button, back_button, perks_button, lexicon_button, achievements_button, options_button, quit_button]:
		_add_hover_effect(button)
	_play_intro()
	(resume_button if resume_button.visible else play_button).grab_focus()


## Boutons du menu principal (sans Reprendre, affiché seulement avec une partie
## enregistrée), et ceux du choix du mode (sous « Jouer »).
func get_main_buttons() -> Array[Button]:
	return [play_button, perks_button, lexicon_button, achievements_button, options_button, quit_button]


## Le tutoriel n'y est plus une fois fini ou passé (il revient si la progression est effacée).
func get_play_buttons() -> Array[Button]:
	var buttons: Array[Button] = [campaign_button, worlds_button, daily_button, editor_button, free_button,
		expedition_button, conquest_button, back_button]
	if not Tutorial.is_done():
		buttons.insert(1, tutorial_button)
	return buttons


## Le bouton ouvre son mode s'il est débloqué ; sinon, il montre seulement sa bulle.
func _connect_feature(button: Button, feature: Unlocks.Feature, open: Callable) -> void:
	_locked_features[button] = feature
	lock_bubble.watch(button, Unlocks.get_hint.bind(feature))
	button.pressed.connect(func() -> void:
		if Unlocks.is_unlocked(feature):
			open.call())


## Le mode du bouton est-il encore verrouillé ?
func is_locked(button: Button) -> bool:
	return _locked_features.has(button) and not Unlocks.is_unlocked(_locked_features[button])


func is_play_menu_open() -> bool:
	return campaign_button.visible


## Ouvre le choix du mode (Jouer) ou revient au menu principal (Retour, Échap).
func show_play_menu(open: bool) -> void:
	for button in get_main_buttons():
		button.visible = not open
	quit_button.visible = not open and not OS.has_feature("web")
	_refresh_resume(not open)
	tutorial_button.visible = false
	for button in get_play_buttons():
		button.visible = open
	subtitle.text = "Jouer" if open else "Tower Defense"
	(campaign_button if open else resume_button if resume_button.visible else play_button).grab_focus()


## Langue changée dans les Options : les textes fixes se traduisent seuls, les textes
## composés (étoiles, scores, niveau de la démo) sont refaits.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()
		if demo.level:
			_on_demo_level_started(demo.level)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_play_menu_open():
		show_play_menu(false)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_time += delta
	# Le titre respire doucement et se balance un peu.
	title.pivot_offset = title.size / 2.0
	title.scale = Vector2.ONE * (1.0 + 0.035 * sin(_time * 2.2))
	title.rotation = 0.025 * sin(_time * 1.1)


## Les flèches servent aussi à passer d'un bouton à l'autre : le code est guetté dans
## _input, avant le menu, sans bloquer les touches.
## Une lettre compte qu'on lise la touche selon la disposition du clavier (le A d'un
## clavier AZERTY) ou selon sa place (la touche A d'un clavier QWERTY, le Q en AZERTY).
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo:
		return
	var keycode: Key = KEYPAD_ARROWS.get(key.keycode, key.keycode)
	if keycode == KEY_NONE:
		keycode = key.physical_keycode
	var expected := KONAMI_CODE[_konami_progress]
	enter_konami_key(expected if key.physical_keycode == expected else keycode)


## Ajoute une touche au code Konami en cours ; débloque tout quand il est complet.
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
	_show_konami_progress()


## Pastilles du code en cours, en haut de l'écran : on voit que les touches sont prises.
func _show_konami_progress() -> void:
	if not _konami_label:
		_konami_label = Label.new()
		_konami_label.add_theme_font_size_override(&"font_size", 22)
		_konami_label.add_theme_color_override(&"font_color", Progress.ENDLESS_STAR_COLOR)
		_konami_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_konami_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_konami_label)
		_konami_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		_konami_label.offset_top = 24.0
	_konami_label.visible = _konami_progress >= KONAMI_SHOWN_FROM
	_konami_label.text = " ".join(PackedStringArray(range(KONAMI_CODE.size()).map(
		func(i: int) -> String: return "●" if i < _konami_progress else "·")))


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


## Ouvre le menu Options par-dessus l'écran titre.
func open_options() -> OptionsMenu:
	var options := OptionsMenu.new()
	options.closed.connect(options_button.grab_focus)
	add_child(options)
	return options


## Niveau ouvert par Campagne (ou Continuer) : le tutoriel pour une toute première partie
## (rien de gagné, tutoriel ni fini ni passé), sinon le prochain niveau à jouer.
func get_campaign_start() -> String:
	if Perks.get_earned_stars() == 0 and not Tutorial.is_done():
		return Tutorial.LEVEL_PATH
	return Progress.get_next_to_play(CAMPAIGN)


## Lance une nouvelle expédition (cinq niveaux débloqués tirés au sort, voir Expedition).
func start_expedition() -> void:
	if Expedition.is_unlocked():
		Level.open_expedition(get_tree(), Expedition.create())


func open_level(path: String) -> void:
	get_tree().change_scene_to_file(path)


## Boutons qui dépendent de la progression : Campagne ou Continuer, étoiles gagnées et
## à dépenser, effacement.
func _refresh() -> void:
	var earned := Perks.get_earned_stars()
	var any_won := earned > 0
	campaign_button.text = "Continuer" if any_won else "Campagne"
	worlds_button.text = tr("Mondes")
	if any_won:
		worlds_button.text += "  ·  ★ %d / %d" % [earned, CAMPAIGN.size() * Progress.MAX_LEVEL_STARS]
	# Les étoiles non dépensées sont signalées sur le bouton de l'arbre.
	var available := Perks.get_available_stars()
	var endless_available := Perks.get_available_stars(true)
	perks_button.text = tr("Améliorations")
	if available > 0:
		perks_button.text += "  ·  ★ %d" % available
	if endless_available > 0:
		perks_button.text += "  ·  %s %d" % [Progress.SKULL, endless_available]
	reset_button.visible = any_won
	_refresh_resume(not is_play_menu_open())
	# Le bouton du tutoriel n'est montré que tant qu'il n'est ni fini ni passé : il est alors conseillé.
	tutorial_button.text = tr("Tutoriel  ·  conseillé")
	# Le meilleur score du défi du jour, s'il a déjà été joué aujourd'hui.
	var daily_score := Progress.get_daily_score(DailyChallenge.today_key())
	daily_button.text = tr("Défi du jour")
	if daily_score >= 0:
		daily_button.text += "  ·  %d" % daily_score
	# Le record de l'Expédition.
	expedition_button.text = tr("Expédition")
	if Expedition.get_best() > 0:
		expedition_button.text += "  ·  %d / %d" % [Expedition.get_best(), Expedition.LEVEL_COUNT]
	conquest_button.text = tr("Conquête")
	free_button.text = tr("Niveaux libres")
	editor_button.text = tr("Éditeur de niveau")
	# Les modes pas encore débloqués : assombris, marqués, et leur bulle remplace l'infobulle.
	for button: Button in _locked_features:
		var locked := is_locked(button)
		LockBubble.set_locked(button, locked)
		if not button.has_meta(&"tooltip"):
			button.set_meta(&"tooltip", button.tooltip_text)
		button.tooltip_text = "" if locked else String(button.get_meta(&"tooltip"))
	if lock_bubble.button and not is_locked(lock_bubble.button):
		lock_bubble.hide_for(lock_bubble.button)
	# Les objectifs remplis par la progression (arbre, étoiles, code Konami) se débloquent ici.
	Achievements.check_progress()
	var unlocked := Achievements.get_unlocked_count()
	achievements_button.text = tr("Succès")
	if unlocked > 0:
		achievements_button.text += "  ·  %d / %d" % [unlocked, Achievements.LIST.size()]

## Bouton Reprendre : seulement dans le menu principal, et s'il y a une partie enregistrée.
func _refresh_resume(shown: bool) -> void:
	var saved := SavedGame.load_data()
	resume_button.visible = shown and not saved.is_empty()
	resume_info.visible = resume_button.visible
	if not saved.is_empty():
		resume_info.text = SavedGame.describe(saved)


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
	demo_label.text = "▶  %s  ·  %s  ·  %s" % [tr("Démo"), tr(world_name), tr(level.level_name)]


func _on_reset_confirmed() -> void:
	Progress.reset_campaign()
	# Toute la progression repart de zéro : le tutoriel est de nouveau proposé.
	Progress.set_setting(Tutorial.DONE_SETTING, false)
	SavedGame.clear()
	_refresh()
	show_play_menu(false)
