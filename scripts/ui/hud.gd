class_name Hud
extends CanvasLayer
## Interface du niveau : or, vies et vague en haut ; barre d'achat des tours, pause,
## vitesse et menu Options en bas ; fiches des tours et écran de fin.
## Au survol, des fenêtres de détail : celle de la prochaine vague (sur son aperçu) et
## celle du monstre sous la souris. La vie des boss en jeu s'affiche en haut de la carte.
## Un bandeau annonce chaque succès débloqué, et l'écran de fin montre les statistiques
## de la partie.

## Émis quand le joueur choisit une tour à placer (null = aucune).
signal tower_selected(data: TowerData)
signal next_wave_requested
signal restart_requested
signal next_level_requested
signal menu_requested
## Émis quand le joueur demande l'amélioration de la tour affichée en détail.
signal upgrade_requested(tower: Tower)
## Émis quand le joueur demande la vente de la tour affichée en détail.
signal sell_requested(tower: Tower)
## Ctrl+Z (ou Retour arrière) : annuler la dernière pose.
signal undo_requested
## Émis quand le joueur ferme la fiche de la tour posée.
signal tower_details_closed
## Émis quand le joueur met le jeu en pause ou le relance (bouton ou Espace).
signal pause_toggled
## Émis quand le joueur choisit une vitesse de jeu (bouton, ou V pour passer à la suivante).
signal game_speed_selected(speed: float)
## Émis quand le menu Options s'ouvre (vrai) ou se ferme (faux) : la partie s'arrête pendant ce temps.
signal options_toggled(open: bool)
## Émis quand le joueur valide son choix de tours au lancement du niveau (TowerPicker).
signal towers_chosen(types: Array[TowerData])
## Émis quand le joueur choisit un pouvoir actif (bouton, ou touche A/Z/E en AZERTY).
signal power_selected(power: Power)
## Mode Conquête : émis quand le joueur recrute un ouvrier (bouton, ou touche R)…
signal recruit_requested
## … choisit un bâtiment à poser (-1 = aucun)…
signal building_selected(kind: int)
## … demande à démolir un bâtiment, ou ferme sa fiche…
signal demolish_requested(building: Building)
signal building_details_closed
## … lance une amélioration dans un Atelier…
signal research_requested(workshop: Building, id: StringName)
## … choisit tous les ouvriers (compteur des ouvriers, ou touche O), et envoie les
## ouvriers choisis au QG, les rend aux ordres automatiques ou les relâche.
signal workers_select_all
signal workers_sent_home
signal workers_released
signal workers_deselected
## Mode Expédition : émis avec le bonus choisi dans un coffre (ChestChoice).
signal chest_bonus_chosen(id: StringName)

## Durée de l'effet de perte de vies, en secondes réelles (indépendante de la vitesse de jeu).
const DAMAGE_FLASH_DURATION := 0.6
## Largeur en dessous de laquelle le nom du niveau n'est plus coupé (barre du haut).
const LEVEL_LABEL_MIN_WIDTH := 80.0
const LIVES_COLOR := Color(1, 0.5, 0.5)
const LIVES_HIT_COLOR := Color(1, 0.15, 0.15)
## Rappel des commandes à côté de la barre d'achat, à la souris et au tactile.
const MOUSE_HINT := "Clic gauche : poser la tour  ·  Maj + clic : en poser plusieurs  ·  Clic droit / Échap : annuler  ·  Clic sur une tour posée : détails, amélioration, vente et cible  ·  1 à 0 : choisir une tour  ·  Espace : pause  ·  V : vitesse"
const TOUCH_HINT := "Touchez une tour de la barre, puis deux fois une case libre pour la poser  ·  Touchez-la encore dans la barre pour annuler  ·  Touchez une tour posée pour sa fiche, un monstre pour le sien  ·  Un pouvoir visé se lance là où vous touchez"
## Mode Conquête : ce qui change, devant le rappel des commandes.
const GAMEPAD_HINT := "Stick gauche ou croix : viser  ·  A : poser, cliquer  ·  B : annuler  ·  LB / RB : choisir une tour  ·  Y : vague suivante  ·  X : vitesse  ·  Start : pause  ·  Select : options"
const CONQUEST_HINT := "Conquête : les tours coûtent aussi de la pierre et les ouvriers les bâtissent  ·  Clic sur un rocher ou un filon : y envoyer les mineurs  ·  Clic ou cadre sur des ouvriers, ou O : les choisir  ·  R : recruter un ouvrier  ·  B : bâtiments"
## Durée d'affichage du bandeau d'un succès débloqué, en secondes réelles.
const ACHIEVEMENT_TOAST_DURATION := 4.0
## Touches des pouvoirs, par position sur le clavier : Q, W, E, T en QWERTY (A, Z, E, T en
## AZERTY).
const POWER_KEYS: Array[Key] = [KEY_Q, KEY_W, KEY_E, KEY_T]

var _speed_group := ButtonGroup.new()
var _gold := 0
var _damage_tween: Tween
## Dernier contenu affiché dans l'aperçu de vague, pour ne le refaire que s'il change.
var _wave_preview_text := ""
## Choix des tours au lancement du niveau (null s'il n'y en a pas, ou une fois validé).
var tower_picker: TowerPicker
## Prochaine vague annoncée (null = plus de vague), son numéro et son bonus.
var _next_wave: WaveData
var _next_wave_number := 0
var _next_wave_bonus := 0
## Multiplicateur de la vitesse des monstres (difficulté), pour les fenêtres de détail.
var enemy_speed_multiplier := 1.0
## Fenêtre de détail de la prochaine vague, au survol de son aperçu.
var wave_details: DetailPopup
## Fenêtre de détail du monstre sous la souris.
var enemy_details: DetailPopup
## Monstre décrit par enemy_details, ou null.
var hovered_enemy: Enemy
## Au tactile : monstre touché du doigt, dont la fiche reste ouverte jusqu'au toucher suivant.
var touched_enemy: Enemy
## Vie des boss en jeu, en haut de la carte.
var boss_bar: BossBar
## Menu Options ouvert (null s'il est fermé).
var options_menu: OptionsMenu
## Statistiques de la partie, à droite de l'écran de fin (cachées jusqu'à la fin).
var end_stats: EndStats
## Bandeaux des succès débloqués en jeu, en bas de la carte.
var achievement_toasts: VBoxContainer
## Bonus des coffres gagnés dans la partie, en haut à gauche de la carte (créé au premier
## coffre ouvert).
var chest_panel: PanelContainer
var _chest_label: RichTextLabel
var _chest_levels := {}
## Mode Expédition : choix du bonus d'un coffre ouvert (null sinon).
var chest_choice: ChestChoice
## Boutons des pouvoirs actifs, en haut, à gauche du bouton de vague.
var power_bar: HBoxContainer
var power_buttons: Array[PowerButton] = []
## Défi du jour : score, dans la barre du haut (null hors défi)…
var score_label: Label
## « ✦ Mutateurs » dans la barre du haut (null sans mutateurs), règles en bulle d'aide.
var mutator_label: Label
## Panneau des mutateurs à montrer une fois les tours choisies (voir show_mutator_rules()).
var _pending_rules_panel := Callable()
## Étoiles des mutateurs de l'écran de fin, [gagnées, meilleur résultat d'avant] (vide sans
## mutateurs) : ajoutées au texte refait au changement de langue.
var _mutator_result: Array[int] = []
## Modes ouverts par la victoire (Unlocks.Feature), dits sur l'écran de fin.
var _unlocked_features: Array = []
## … et règles, au milieu de la carte jusqu'à la première vague.
var challenge_rules: PanelContainer
## Mode Conquête : pierre, ouvriers et bouton de recrutement, dans la barre du haut (null
## hors de ce mode).
var stone_label: Label
var essence_label: Label
var workers_label: Button
var recruit_button: Button
## … et barre des ouvriers choisis, au-dessus de la barre d'achat, à gauche.
var worker_bar: PanelContainer
var _worker_bar_label: Label
var _worker_bar_count := 0
## Derniers arguments de update_stats() et set_interest_rules(), pour
## réécrire leurs textes au changement de langue.
var _stats_args := []
## Mode Conquête suivi par le HUD (dernier appel de update_conquest()).
var _conquest: Conquest
var _interest_rules := []
var _score := 0
var _worker_cost := 0
## Prime pour lancer la prochaine vague en avance (dernier appel de show_next_wave()).
var _next_wave_early_bonus := 0
## Écran de fin affiché (sa fonction et ses arguments), refait au changement de langue.
var _end_screen := Callable()
## … bouton « Bâtiments » à droite de la barre d'achat, barre des bâtiments qu'il ouvre
## au-dessus, et fiche d'un bâtiment posé.
var buildings_button: Button
var building_shop: BuildingShop
var building_details: BuildingInfoPanel
## Tours au plus dans la barre d'achat pour que le rappel des commandes s'affiche à côté.
var _hint_max_towers := 7

@onready var level_label: Label = %LevelLabel
@onready var gold_label: Label = %GoldLabel
## Intérêts que rapporterait l'or gardé, sous l'or.
@onready var interest_label: Label = %InterestLabel
@onready var lives_label: Label = %LivesLabel
@onready var wave_label: Label = %WaveLabel
## Barre d'achat, en bas à gauche.
@onready var tower_shop: TowerShop = %TowerShop
## Rappel des commandes, à côté de la barre d'achat.
@onready var shop_hint: Label = %Hint
@onready var next_wave_button: Button = %NextWaveButton
@onready var end_panel: PanelContainer = %EndPanel
@onready var end_title: Label = %EndTitle
@onready var end_stars: Label = %EndStars
@onready var end_message: Label = %EndMessage
@onready var next_level_button: Button = %NextLevelButton
## Fiche affichée au survol d'un bouton de la barre d'achat.
@onready var shop_info: TowerInfoPanel = %ShopInfo
## Fiche de la tour posée sélectionnée sur la carte.
@onready var tower_details: TowerInfoPanel = %TowerDetails
@onready var pause_button: Button = %PauseButton
@onready var speed_buttons: HBoxContainer = %SpeedButtons
@onready var options_button: Button = %OptionsButton
@onready var top_bar: Control = %TopBar
@onready var bottom_bar: Control = %BottomBar
@onready var pause_overlay: ColorRect = %PauseOverlay
## Boutons de la pause qui abandonnent la partie en cours (un premier clic demande confirmation).
@onready var pause_restart_button: Button = %PauseRestartButton
@onready var pause_quit_button: Button = %PauseQuitButton
## Composition de la prochaine vague et bonus pour la lancer en avance.
@onready var wave_preview: PanelContainer = %WavePreview
@onready var wave_preview_label: RichTextLabel = %WavePreviewLabel
## Voile rouge affiché quand le joueur perd des vies.
@onready var damage_flash: ColorRect = %DamageFlash


func _ready() -> void:
	end_panel.visible = false
	level_label.clip_text = true
	level_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	level_label.mouse_filter = Control.MOUSE_FILTER_PASS
	top_bar.resized.connect(_fit_level_label)
	level_label.get_parent().minimum_size_changed.connect(_fit_level_label, CONNECT_DEFERRED)
	next_wave_button.pressed.connect(next_wave_requested.emit)
	%RestartButton.pressed.connect(restart_requested.emit)
	%NextLevelButton.pressed.connect(next_level_requested.emit)
	%MenuButton.pressed.connect(menu_requested.emit)
	tower_details.upgrade_requested.connect(upgrade_requested.emit)
	tower_details.sell_requested.connect(sell_requested.emit)
	tower_details.close_requested.connect(tower_details_closed.emit)
	pause_button.pressed.connect(pause_toggled.emit)
	_connect_confirmed(pause_restart_button, "Vraiment recommencer ?", restart_requested.emit)
	_connect_confirmed(pause_quit_button, "Vraiment quitter ?", menu_requested.emit)
	options_button.pressed.connect(open_options)
	lives_label.add_theme_color_override("font_color", LIVES_COLOR)
	boss_bar = BossBar.new()
	add_child(boss_bar)
	move_child(boss_bar, wave_preview.get_index())
	wave_details = DetailPopup.new(400.0)
	add_child(wave_details)
	enemy_details = DetailPopup.new(270.0)
	add_child(enemy_details)
	# Fond plus opaque que celui du thème : les statistiques se lisent mieux sans la carte derrière.
	var end_style := UiStyle.panel(Color(UiStyle.ACCENT, 0.6), 0.0, SIDE_TOP, Color(0.03, 0.06, 0.09, 0.95))
	end_panel.add_theme_stylebox_override(&"panel", end_style)
	end_stats = EndStats.new()
	end_stats.visible = false
	%EndPanel.get_node("Margin/Row").add_child(end_stats)
	achievement_toasts = VBoxContainer.new()
	achievement_toasts.alignment = BoxContainer.ALIGNMENT_END
	achievement_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	achievement_toasts.add_theme_constant_override(&"separation", 6)
	add_child(achievement_toasts)
	move_child(achievement_toasts, end_panel.get_index())
	# L'aperçu de vague prend la souris pour ouvrir sa fenêtre de détail.
	wave_preview.mouse_filter = Control.MOUSE_FILTER_STOP
	wave_preview.mouse_default_cursor_shape = Control.CURSOR_HELP
	wave_preview.mouse_entered.connect(show_wave_details)
	wave_preview.mouse_exited.connect(wave_details.close)


## Changement de langue (menu Options en jeu) : les textes composés sont refaits avec les
## derniers chiffres reçus ; les textes fixes se traduisent seuls.
func _notification(what: int) -> void:
	if what != NOTIFICATION_TRANSLATION_CHANGED or not is_node_ready():
		return
	for button: Button in speed_buttons.get_children():
		button.tooltip_text = _speed_tooltip(button.text)
	if not _interest_rules.is_empty():
		set_interest_rules.callv(_interest_rules)
	if not _stats_args.is_empty():
		update_stats.callv(_stats_args)
	if chest_panel:
		update_chest_bonuses(_chest_levels)
	if recruit_button:
		recruit_button.text = tr("Recruter · %d or (R)") % _worker_cost
		if is_instance_valid(_conquest):
			update_conquest(_conquest)
		show_worker_selection(_worker_bar_count)
	set_score(_score)
	if not end_panel.visible:
		# L'aperçu de vague ne se refait que si son texte change : on l'oublie.
		_wave_preview_text = ""
		show_next_wave(_next_wave, _next_wave_early_bonus, _next_wave_number, _next_wave_bonus)
	elif _end_screen.is_valid():
		_end_screen.call()
		if not _mutator_result.is_empty():
			show_mutator_result(_mutator_result[0], _mutator_result[1])
		if not _unlocked_features.is_empty():
			show_unlocked_features(_unlocked_features)
		if end_stats.visible:
			_center_end_panel.call_deferred()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo or end_panel.visible or tower_picker or options_menu \
			or chest_choice:
		return
	# Position physique des touches : en AZERTY, la rangée 1, 2, 3 donne « & é " » sans Maj.
	var code := key.physical_keycode
	var slot := TowerShop.slot_for_key(code)
	var power_index := POWER_KEYS.find(code)
	if (key.keycode == KEY_Z and key.is_command_or_control_pressed()) or code == KEY_BACKSPACE:
		undo_requested.emit()
	elif power_index >= 0 and power_index < power_buttons.size():
		power_selected.emit(power_buttons[power_index].power)
	elif code == KEY_SPACE or code == KEY_P:
		pause_toggled.emit()
	elif code == KEY_V:
		_select_next_speed()
	elif code == KEY_R and recruit_button:
		if not recruit_button.disabled:
			recruit_requested.emit()
	elif code == KEY_B and building_shop:
		set_building_shop_open(not building_shop.visible)
	elif code == KEY_O and workers_label:
		workers_select_all.emit()
	elif slot >= 0 and building_shop and building_shop.visible:
		building_shop.toggle_slot(slot)
	elif slot >= 0:
		tower_shop.toggle_slot(slot)
	else:
		return
	get_viewport().set_input_as_handled()


## Manette (voir Gamepad) : Start met en pause, Select ouvre les Options, X change la
## vitesse, Y lance la vague, LB et RB passent d'une tour de la barre à l'autre.
func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventJoypadButton
	if button == null or not button.pressed or end_panel.visible or tower_picker or options_menu:
		return
	match button.button_index:
		JOY_BUTTON_START:
			pause_toggled.emit()
		JOY_BUTTON_BACK:
			open_options()
		JOY_BUTTON_X:
			_select_next_speed()
		JOY_BUTTON_Y:
			if next_wave_button.visible and not next_wave_button.disabled:
				next_wave_requested.emit()
		JOY_BUTTON_LEFT_SHOULDER:
			tower_shop.select_neighbour(-1)
		JOY_BUTTON_RIGHT_SHOULDER:
			tower_shop.select_neighbour(1)
		_:
			return
	get_viewport().set_input_as_handled()


func setup(level_name: String, tower_types: Array[TowerData], game_speeds: Array[float] = [1.0]) -> void:
	level_label.text = level_name
	for speed in game_speeds:
		var speed_button := Button.new()
		var speed_text := "x%s" % str(speed).trim_suffix(".0")
		speed_button.text = speed_text
		speed_button.toggle_mode = true
		speed_button.button_group = _speed_group
		speed_button.focus_mode = Control.FOCUS_NONE
		speed_button.custom_minimum_size = Vector2(36, 0)
		speed_button.set_meta("speed", speed)
		speed_button.tooltip_text = _speed_tooltip(speed_text)
		speed_button.pressed.connect(game_speed_selected.emit.bind(speed))
		speed_buttons.add_child(speed_button)
	set_tower_types(tower_types)
	tower_shop.tower_selected.connect(tower_selected.emit)
	tower_shop.tower_hovered.connect(_on_shop_button_hovered)
	tower_shop.hover_ended.connect(shop_info.close)


func _speed_tooltip(speed_text: String) -> String:
	return tr("Vitesse %s (V : vitesse suivante)") % speed_text


## Ajoute un bouton par pouvoir actif, en haut de l'écran, à gauche du bouton de vague.
func setup_powers(powers: Array[Power]) -> void:
	if power_bar == null:
		power_bar = HBoxContainer.new()
		power_bar.add_theme_constant_override("separation", 6)
		next_wave_button.get_parent().add_child(power_bar)
		next_wave_button.get_parent().move_child(power_bar, next_wave_button.get_index())
	for i in powers.size():
		var button := PowerButton.new()
		button.setup(powers[i], key_label(POWER_KEYS[i]) if i < POWER_KEYS.size() else "")
		button.pressed.connect(func() -> void: power_selected.emit(button.power))
		power_bar.add_child(button)
		power_buttons.append(button)
	power_bar.visible = not powers.is_empty()


## Lettre écrite sur la touche à cette position du clavier, dans la disposition du joueur.
static func key_label(physical: Key) -> String:
	# Sans fenêtre (tests), le clavier n'est pas connu : on garde la touche QWERTY.
	if DisplayServer.get_name() == "headless":
		return OS.get_keycode_string(physical)
	var keycode := DisplayServer.keyboard_get_keycode_from_physical(physical)
	var label := OS.get_keycode_string(keycode) if keycode != KEY_NONE else ""
	return label if not label.is_empty() else OS.get_keycode_string(physical)


## Recharge restante de chaque pouvoir, et ceux qu'on peut lancer maintenant.
func update_powers(cooldowns: Array[float], usable: Array[bool]) -> void:
	for i in mini(power_buttons.size(), cooldowns.size()):
		power_buttons[i].set_state(cooldowns[i], usable[i])


## Le bouton du pouvoir visé reste enfoncé (null = aucun).
func set_selected_power(power: Power) -> void:
	for button in power_buttons:
		button.set_pressed_no_signal(button.power == power)


## Bulle d'aide des intérêts : leur taux et leur plafond.
func set_interest_rules(rate: float, cap: int) -> void:
	_interest_rules = [rate, cap]
	interest_label.tooltip_text = tr("Chaque fois que la carte est vidée, l'or gardé rapporte %d %% d'intérêts (%d or au plus), avant le bonus de vague.") \
		% [roundi(rate * 100.0), cap]


## Point de l'écran où s'affichent les intérêts versés : sous l'or.
func get_interest_anchor() -> Vector2:
	var rect := interest_label.get_global_rect() if interest_label.visible else gold_label.get_global_rect()
	return Vector2(rect.get_center().x, rect.end.y + 14.0)


## Remplit la barre d'achat (après le choix des tours, s'il y en a un).
func set_tower_types(tower_types: Array[TowerData]) -> void:
	tower_shop.setup(tower_types)
	tower_shop.set_gold(_gold)
	# Avec les tours débloquées dans l'arbre, la barre d'achat prend la place du rappel des commandes.
	shop_hint.visible = tower_types.size() <= _hint_max_towers


## Ouvre le choix des tours, par-dessus tout le reste, jusqu'à ce que le joueur valide.
func show_tower_picker(available: Array[TowerData], limit: int, selected: Array[TowerData],
		difficulty_name: String) -> void:
	tower_picker = TowerPicker.new()
	add_child(tower_picker)
	tower_picker.setup(available, limit, selected, difficulty_name)
	tower_picker.confirmed.connect(_on_towers_chosen)
	tower_picker.menu_requested.connect(menu_requested.emit)


## Ouvre le menu Options par-dessus la partie, qui s'arrête jusqu'à sa fermeture.
func open_options() -> void:
	if options_menu:
		return
	options_menu = OptionsMenu.new()
	options_menu.closed.connect(func() -> void:
		options_menu = null
		options_toggled.emit(false))
	add_child(options_menu)
	options_toggled.emit(true)


func _on_towers_chosen(types: Array[TowerData]) -> void:
	tower_picker.queue_free()
	tower_picker = null
	towers_chosen.emit(types)


## Passe à la vitesse suivante (après la dernière, on revient à la première).
func _select_next_speed() -> void:
	var buttons := speed_buttons.get_children()
	if buttons.is_empty():
		return
	var current := buttons.find(_speed_group.get_pressed_button())
	(buttons[(current + 1) % buttons.size()] as Button).pressed.emit()


## `wave_count` négatif : mode infini, les vagues ne s'arrêtent pas.
## `interest` : or que rapporteraient les intérêts maintenant (négatif : pas d'intérêts).
## Le nom du niveau prend la place que lui laisse le reste de la barre du haut. Quand elle
## est pleine (Conquête et pouvoirs, textes anglais plus longs), les boutons des pouvoirs
## perdent leur nom, puis le nom du niveau finit par « … » (sa bulle d'aide le donne en entier).
func _fit_level_label() -> void:
	var row := level_label.get_parent() as HBoxContainer
	var margin := row.get_parent() as MarginContainer
	var available := top_bar.size.x - margin.get_theme_constant(&"margin_left") - margin.get_theme_constant(&"margin_right")
	var others := 0.0
	for child in row.get_children():
		if child != level_label and child is Control and child.visible:
			others += child.get_combined_minimum_size().x + row.get_theme_constant(&"separation")
	var font := level_label.get_theme_font(&"font")
	var text_width := font.get_string_size(level_label.atr(level_label.text), HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		level_label.get_theme_font_size(&"font_size")).x
	if available - others < text_width and power_buttons.any(func(b: PowerButton) -> bool: return not b.compact):
		# D'abord les pouvoirs perdent leur nom : la barre se recalcule ensuite.
		for button in power_buttons:
			button.set_compact(true)
		return
	var width := ceilf(clampf(available - others, LEVEL_LABEL_MIN_WIDTH, text_width))
	level_label.custom_minimum_size.x = width
	level_label.tooltip_text = level_label.text if width < text_width else ""


func update_stats(gold: int, lives: int, wave: int, wave_count: int, interest := -1) -> void:
	_gold = gold
	_stats_args = [gold, lives, wave, wave_count, interest]
	gold_label.text = tr("Or : %d") % gold
	interest_label.visible = interest >= 0
	interest_label.text = tr("Intérêts : +%d") % maxi(interest, 0)
	lives_label.text = tr("Vies : %d") % lives
	wave_label.text = tr("Vague : %d / %s") % [wave, str(wave_count) if wave_count >= 0 else "∞"]
	tower_shop.set_gold(gold)
	shop_info.set_gold(gold)
	tower_details.set_gold(gold)
	_fit_level_label()


## Affiche la fiche d'une tour posée (null = la fermer).
func show_tower_details(tower: Tower) -> void:
	if tower:
		tower_details.bounds = get_play_area()
		tower_details.show_tower(tower, _gold)
	else:
		tower_details.close()


func set_selected_tower(data: TowerData) -> void:
	tower_shop.set_selected(data)


func set_next_wave_available(available: bool) -> void:
	next_wave_button.disabled = not available


## Affiche la composition de la prochaine vague (null = plus de vague) et, si elle
## est positive, la prime pour la lancer avant d'avoir vidé la carte. `wave_number`
## (à partir de 1) et `wave_bonus` (or versé quand elle est repoussée) servent à sa
## fenêtre de détail.
func show_next_wave(wave: WaveData, early_bonus := 0, wave_number := 0, wave_bonus := 0) -> void:
	var wave_changed := wave != _next_wave
	_next_wave = wave
	_next_wave_number = wave_number
	_next_wave_bonus = wave_bonus
	_next_wave_early_bonus = early_bonus
	if wave_changed and wave_details.visible:
		if wave:
			show_wave_details()
		else:
			wave_details.close()
	var text := ""
	if wave:
		var parts: Array[String] = []
		for entry in wave.get_summary():
			var enemy: EnemyData = entry.enemy
			var part := "[color=#%s]●[/color] %d %s" % [enemy.color.to_html(false), entry.count,
				EnemyData.plural(enemy.display_name, entry.count)]
			var tag := EnemyInfo.rank_tag(enemy, entry.elite)
			parts.append(part + (" " + tag if not tag.is_empty() else ""))
		text = "[color=#ffffff99]%s[/color]  " % tr("Prochaine vague :") + "   ".join(parts)
		if early_bonus > 0:
			text += "\n[color=#ffd54d]%s[/color]" % (tr("Lancer maintenant : +%d or") % early_bonus)
	if text == _wave_preview_text:
		return
	_wave_preview_text = text
	wave_preview_label.text = text
	wave_preview.visible = not text.is_empty()
	next_wave_button.tooltip_text = tr("Lancer maintenant rapporte %d or") % early_bonus if early_bonus > 0 else ""
	wave_preview.reset_size()
	# Le panneau, sous le bouton de vague, reste calé à droite de l'écran.
	wave_preview.position.x = get_viewport().get_visible_rect().size.x - 8.0 - wave_preview.size.x


func set_paused(paused: bool) -> void:
	pause_button.set_pressed_no_signal(paused)
	pause_button.text = "Reprendre" if paused else "Pause"
	pause_overlay.visible = paused
	for button in [pause_restart_button, pause_quit_button]:
		button.text = button.get_meta(&"text")


## Bouton qui fait perdre la partie en cours : le premier clic le change en demande de
## confirmation, le second lance l'action. La demande s'efface à la sortie de pause.
func _connect_confirmed(button: Button, confirm_text: String, action: Callable) -> void:
	button.set_meta(&"text", button.text)
	button.pressed.connect(func() -> void:
		if button.text == confirm_text:
			action.call()
		else:
			button.text = confirm_text)


func set_game_speed(speed: float) -> void:
	for button: Button in speed_buttons.get_children():
		button.set_pressed_no_signal(is_equal_approx(button.get_meta("speed"), speed))


## Effet de perte de vies : voile rouge sur l'écran et compteur de vies qui
## grossit en rouge. Plus la perte est grande, plus l'effet est marqué.
func play_damage_effect(lives_lost: int) -> void:
	if _damage_tween:
		_damage_tween.kill()
	var strength := clampf(0.55 + 0.15 * lives_lost, 0.0, 1.0)
	var vignette := damage_flash.material as ShaderMaterial
	lives_label.pivot_offset = lives_label.size / 2.0
	lives_label.scale = Vector2.ONE * 1.35
	lives_label.add_theme_color_override("font_color", LIVES_HIT_COLOR)
	# Temps réel : l'effet garde la même durée en x3 et pendant la pause de fin de partie.
	_damage_tween = create_tween().set_ignore_time_scale().set_parallel()
	_damage_tween.tween_method(func(value: float) -> void: vignette.set_shader_parameter("intensity", value),
		strength, 0.0, DAMAGE_FLASH_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_damage_tween.tween_property(lives_label, "scale", Vector2.ONE, DAMAGE_FLASH_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_damage_tween.tween_method(func(color: Color) -> void: lives_label.add_theme_color_override("font_color", color),
		LIVES_HIT_COLOR, LIVES_COLOR, DAMAGE_FLASH_DURATION)


## Écran de fin. Après une victoire, `stars` (1 à 3) s'affiche, avec « Nouveau record »
## si c'est le meilleur résultat obtenu sur ce niveau.
## `unlocked_world` : nom du monde qu'ouvre cette victoire (le niveau suivant est alors
## le premier d'un nouveau monde), "" sinon.
## Texte du bouton de l'écran de fin qui quitte la partie (« Menu principal »).
func set_menu_button_text(text: String) -> void:
	%MenuButton.text = text


func show_end_screen(victory: bool, can_continue := false, stars := 0, new_record := false,
		unlocked_world := "") -> void:
	end_title.text = "Victoire !" if victory else "Défaite"
	end_stars.visible = victory and stars > 0
	end_stars.text = Progress.star_text(stars)
	end_message.text = tr("Toutes les vagues ont été repoussées.") if victory \
		else tr("Les ennemis ont atteint votre base.")
	if new_record:
		end_message.text += "\n" + tr("Nouveau record !")
	if not unlocked_world.is_empty():
		end_message.text += "\n" + tr("Nouveau monde débloqué : %s") % tr(unlocked_world)
	next_level_button.text = "Monde suivant" if not unlocked_world.is_empty() else "Niveau suivant"
	next_level_button.visible = can_continue
	end_panel.visible = true
	set_paused(false)
	pause_button.disabled = true
	for button: Button in speed_buttons.get_children():
		button.disabled = true
	# Plus de tour à poser : la barre d'achat ne réagit plus (ni clic ni fiche au survol).
	tower_shop.lock()
	shop_info.close()
	wave_details.close()
	enemy_details.close()
	hovered_enemy = null
	tower_details.close()
	wave_preview.visible = false
	if can_continue:
		next_level_button.grab_focus()
	else:
		%RestartButton.grab_focus()
	_end_screen = show_end_screen.bind(victory, can_continue, stars, new_record, unlocked_world)


## Écran de fin du mode infini : vagues repoussées, étoiles infinies obtenues sur le
## niveau avec cette partie, et « Nouveau record » si le record de vagues est battu.
func show_endless_end_screen(waves: int, endless_stars: int, new_record := false) -> void:
	show_end_screen(false)
	end_title.text = "Fin de la partie"
	end_stars.visible = true
	end_stars.text = Progress.skull_text(endless_stars, Progress.ENDLESS_MAX_STARS)
	end_stars.add_theme_color_override("font_color", Progress.ENDLESS_STAR_COLOR)
	end_message.text = tr_n("%d vague repoussée.", "%d vagues repoussées.", LevelStats.plural_count(waves)) % waves
	if new_record:
		end_message.text += "\n" + tr("Nouveau record !")
	end_message.text += "\n" + tr("Un crâne toutes les %d vagues au-delà de celles du niveau.") \
		% Progress.ENDLESS_STAR_STEP
	_end_screen = show_endless_end_screen.bind(waves, endless_stars, new_record)


## Écran de fin d'une étape du mode Expédition. `cleared` : étapes réussies (celle-ci
## comprise après une victoire), sur `total`. Une victoire avant la dernière étape mène à
## la suivante ; sinon l'expédition est finie, et on peut en lancer une nouvelle.
func show_expedition_end_screen(victory: bool, cleared: int, total: int, lives: int, new_record := false) -> void:
	var finished := not victory or cleared >= total
	show_end_screen(victory, not finished)
	end_stars.visible = true
	end_stars.text = "%d / %d" % [cleared, total]
	end_stars.add_theme_color_override("font_color", Expedition.COLOR)
	if not finished:
		end_title.text = "Étape réussie !"
		end_message.text = tr("Étape %d sur %d franchie.") % [cleared, total] + "\n" \
			+ tr_n("Il vous reste %d vie pour la suite.", "Il vous reste %d vies pour la suite.",
				LevelStats.plural_count(lives)) % lives
		next_level_button.text = "Étape suivante"
	else:
		end_title.text = "Expédition réussie !" if victory else "Expédition terminée"
		end_message.text = tr("Les %d étapes sont franchies.") % total if victory \
			else tr("Étapes franchies : %d sur %d.") % [cleared, total]
		if new_record:
			end_message.text += "\n" + tr("Nouveau record !")
	%RestartButton.text = "Nouvelle expédition"
	%RestartButton.visible = finished
	_end_screen = show_expedition_end_screen.bind(victory, cleared, total, lives, new_record)


## Statistiques de la partie et succès débloqués, à droite de l'écran de fin (à appeler
## après show_end_screen ou show_endless_end_screen).
func show_end_stats(stats: LevelStats, achievement_ids: Array[String] = []) -> void:
	end_stats.setup(stats, achievement_ids)
	end_stats.visible = true
	# Les succès sont listés dans le panneau : les bandeaux s'effacent.
	for toast in achievement_toasts.get_children():
		toast.queue_free()
	_center_end_panel.call_deferred()


func _center_end_panel() -> void:
	end_panel.reset_size()
	end_panel.position = ((get_viewport().get_visible_rect().size - end_panel.size) / 2.0).round()


## Bandeau « Succès débloqué » en bas de la carte, qui s'efface tout seul.
func show_achievement(definition: Dictionary) -> void:
	if definition.is_empty():
		return
	_show_toast(Achievements.COLOR, "%s  %s" % [definition.icon, tr("Succès débloqué : %s") % tr(definition.name)],
		tr(definition.description))


## Bandeau en bas de la carte (succès, coffre ouvert) : un titre de la couleur donnée et
## une ligne d'explication. Il s'efface tout seul.
func _show_toast(color: Color, title: String, body: String) -> void:
	var toast := PanelContainer.new()
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiStyle.panel(color, 16.0, SIDE_LEFT, Color(0.08, 0.07, 0.04, 0.92))
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	toast.add_theme_stylebox_override(&"panel", style)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"normal_font_size", 16)
	label.add_theme_font_size_override(&"bold_font_size", 18)
	label.text = "[color=#%s][b]%s[/b][/color]\n[color=#ffffffb0]%s[/color]" % [color.to_html(false), title, body]
	toast.add_child(label)
	achievement_toasts.add_child(toast)
	_place_achievement_toasts.call_deferred()
	toast.modulate.a = 0.0
	# Temps réel : le bandeau dure autant en x3 et pendant la pause de fin de partie.
	var tween := toast.create_tween().set_ignore_time_scale()
	tween.tween_property(toast, "modulate:a", 1.0, 0.25)
	tween.tween_interval(ACHIEVEMENT_TOAST_DURATION)
	tween.tween_property(toast, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		toast.queue_free()
		_place_achievement_toasts.call_deferred())
	Sound.play(&"upgrade")


## Coffre ouvert : bandeau du bonus gagné (`count` : exemplaires de ce bonus, celui-ci compris).
func show_chest_bonus(definition: Dictionary, count: int) -> void:
	var body := tr(definition.description)
	if count > 1:
		body += "  " + tr("Au total : %s.") % ChestBonus.describe_total(definition.id, count)
	_show_toast(definition.color, tr("Coffre : %s") % tr(definition.name), body)


## Mode Expédition : propose les bonus d'un coffre ouvert, par-dessus la partie.
func show_chest_choice(choices: Array[StringName], levels: Dictionary) -> void:
	close_chest_choice()
	shop_info.close()
	wave_details.close()
	enemy_details.close()
	chest_choice = ChestChoice.new()
	add_child(chest_choice)
	chest_choice.setup(choices, levels)
	chest_choice.chosen.connect(chest_bonus_chosen.emit)
	Sound.play(&"upgrade")


func close_chest_choice() -> void:
	if chest_choice:
		chest_choice.queue_free()
		chest_choice = null


## Liste des bonus des coffres gagnés (`levels` : exemplaires par identifiant).
func update_chest_bonuses(levels: Dictionary) -> void:
	_chest_levels = levels.duplicate()
	if chest_panel == null:
		chest_panel = PanelContainer.new()
		chest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := UiStyle.panel(ChestBonus.COLOR, 10.0, SIDE_LEFT, Color(0.05, 0.06, 0.08, 0.82))
		style.content_margin_top = 6.0
		style.content_margin_bottom = 6.0
		chest_panel.add_theme_stylebox_override(&"panel", style)
		_chest_label = RichTextLabel.new()
		_chest_label.bbcode_enabled = true
		_chest_label.fit_content = true
		_chest_label.scroll_active = false
		_chest_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_chest_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_chest_label.add_theme_font_size_override(&"normal_font_size", 14)
		_chest_label.add_theme_font_size_override(&"bold_font_size", 14)
		chest_panel.add_child(_chest_label)
		add_child(chest_panel)
		move_child(chest_panel, wave_preview.get_index())
		wave_preview.resized.connect(_place_chest_panel)
		wave_preview.visibility_changed.connect(_place_chest_panel)
	var lines: Array[String] = ["[color=#%s][b]%s[/b][/color]" % [ChestBonus.COLOR.to_html(false), tr("Bonus des coffres")]]
	for id: StringName in _chest_levels:
		var definition := ChestBonus.get_definition(id)
		lines.append("[color=#%s]%s[/color]  [color=#ffffffc0]%s[/color]" % [(definition.color as Color).to_html(false),
			tr(definition.name), ChestBonus.describe_total(id, _chest_levels[id])])
	_chest_label.text = "\n".join(lines)
	chest_panel.visible = not _chest_levels.is_empty()
	_place_chest_panel.call_deferred()


## En haut à droite de la carte, sous l'aperçu de la prochaine vague (ou à sa place
## quand il n'y en a plus).
func _place_chest_panel() -> void:
	if not chest_panel or not is_inside_tree():
		return
	chest_panel.reset_size()
	var top := top_bar.get_global_rect().end.y
	if wave_preview.visible:
		top = wave_preview.get_global_rect().end.y
	chest_panel.position = Vector2(get_viewport().get_visible_rect().size.x - chest_panel.size.x - 8.0, top + 8.0).round()


## Les bandeaux sont centrés, juste au-dessus de la barre du bas.
func _place_achievement_toasts() -> void:
	if not is_inside_tree():
		return
	achievement_toasts.reset_size()
	var screen := get_viewport().get_visible_rect().size
	achievement_toasts.position = Vector2(((screen.x - achievement_toasts.size.x) / 2.0),
		bottom_bar.get_global_rect().position.y - 12.0 - achievement_toasts.size.y).round()


## Zone de la carte visible entre la barre du haut et celle du bas.
func get_play_area() -> Rect2:
	var screen := get_viewport().get_visible_rect()
	var top := top_bar.get_global_rect().end.y
	return Rect2(0.0, top, screen.size.x, bottom_bar.get_global_rect().position.y - top)


func _on_shop_button_hovered(button: TowerShopButton) -> void:
	# L'aperçu s'ouvre au-dessus de la barre d'achat, sur la carte.
	shop_info.bounds = get_play_area()
	shop_info.show_tower_type(button.data, _gold, button.get_global_rect())


# --- Mode Conquête ----------------------------------------------------------------

## Ajoute la pierre, l'essence, les ouvriers et le bouton de recrutement à la barre du
## haut, le prix en pierre aux cases de la barre d'achat (`stone_cost` : TowerData -> int),
## l'essence au bouton Améliorer des fiches (`essence_cost` : Tower -> int), et le
## bouton des bâtiments à droite de la barre d'achat. À appeler avant setup().
func setup_conquest(worker_cost: int, stone_cost: Callable, essence_cost: Callable) -> void:
	# Pierre et essence l'une sous l'autre, comme l'or et ses intérêts : la barre du haut
	# garde de la place pour les pouvoirs et le nom du niveau.
	var resources := VBoxContainer.new()
	resources.alignment = BoxContainer.ALIGNMENT_CENTER
	resources.add_theme_constant_override("separation", -4)
	wave_label.add_sibling(resources)
	stone_label = _add_resource_label(resources, Conquest.STONE_COLOR,
		"Pierre : minée par les ouvriers dans les rochers et rapportée au QG ou à un Dépôt.\n"
		+ "Chaque tour et chaque bâtiment en demande, en plus de l'or. Cliquez sur un rocher pour y envoyer les mineurs.")
	essence_label = _add_resource_label(resources, Conquest.ESSENCE_COLOR,
		"Essence : minée dans les filons de cristaux, ou tirée par un Extracteur posé dessus.\n"
		+ "Elle paie les améliorations à partir du niveau 3 et la Caserne.")
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	resources.add_sibling(box)
	# Le compteur des ouvriers est un bouton : il les choisit tous (au tactile surtout).
	workers_label = Button.new()
	workers_label.flat = true
	workers_label.focus_mode = Control.FOCUS_NONE
	for state in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		workers_label.add_theme_color_override(state, Worker.COLOR if state == &"font_color" else Worker.COLOR.lightened(0.35))
	workers_label.add_theme_font_size_override("font_size", 13)
	workers_label.add_theme_constant_override(&"h_separation", 0)
	for state in [&"normal", &"hover", &"pressed", &"focus"]:
		workers_label.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	workers_label.tooltip_text = tr("Ouvriers en jeu, sur le maximum : %d, et %d de plus par Maison bâtie (%d au plus).") \
		% [Conquest.BASE_WORKERS, Building.HOUSE_WORKERS, Conquest.MAX_WORKERS] \
		+ "\n" + tr("Cliquez ici (ou O) pour les choisir tous, puis désignez-leur une tâche sur la carte.")
	workers_label.pressed.connect(workers_select_all.emit)
	box.add_child(workers_label)
	recruit_button = Button.new()
	_worker_cost = worker_cost
	recruit_button.text = tr("Recruter · %d or (R)") % worker_cost
	recruit_button.tooltip_text = "Un ouvrier de plus, au QG : il mine la pierre et l'essence, et bâtit tours et bâtiments."
	recruit_button.focus_mode = Control.FOCUS_NONE
	recruit_button.add_theme_font_size_override("font_size", 13)
	# Bordure aux couleurs des ouvriers : le bouton se détache de la barre du haut.
	UiStyle.style_button(recruit_button, Worker.COLOR, 12.0, 12.0)
	recruit_button.pressed.connect(recruit_requested.emit)
	box.add_child(recruit_button)
	tower_shop.stone_cost = stone_cost
	# Le bouton des bâtiments prend une case dans la barre du bas.
	tower_shop.max_width = TowerShop.MAX_WIDTH - TowerShopButton.SLOT_SIZE.x - 22.0
	_hint_max_towers = 6
	tower_details.essence_cost = essence_cost
	next_wave_button.tooltip_text = "Les vagues partent seules à la fin du compte à rebours. " \
		+ "Les lancer avant rapporte la prime habituelle."
	_setup_buildings()


func _add_resource_label(box: VBoxContainer, color: Color, tooltip: String) -> Label:
	var label := Label.new()
	label.custom_minimum_size.x = 96.0
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 15)
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.tooltip_text = tooltip
	box.add_child(label)
	return label


## Bouton « Bâtiments » (case de la barre d'achat), barre des bâtiments et fiche d'un
## bâtiment posé.
func _setup_buildings() -> void:
	buildings_button = Button.new()
	buildings_button.custom_minimum_size = TowerShopButton.SLOT_SIZE
	buildings_button.toggle_mode = true
	buildings_button.focus_mode = Control.FOCUS_NONE
	buildings_button.tooltip_text = "Dépôt, Maison, Extracteur, Barricade, Caserne et Atelier : posés comme les tours, bâtis par les ouvriers."
	UiStyle.apply_styles(buildings_button, UiStyle.slot_styles(Conquest.STONE_COLOR))
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 2)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buildings_button.add_child(column)
	var icon := BuildingShop.BuildingIcon.new()
	icon.kind = Building.Kind.HOUSE
	icon.custom_minimum_size = Vector2.ONE * BuildingShop.ICON_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	var title := Label.new()
	title.text = "Bâtiments"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 13)
	title.add_theme_color_override(&"font_color", Conquest.STONE_COLOR)
	column.add_child(title)
	var key := Label.new()
	key.text = "B"
	key.add_theme_font_size_override(&"font_size", 11)
	key.add_theme_color_override(&"font_color", Color(1, 1, 1, 0.55))
	key.position = Vector2(5, 1)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buildings_button.add_child(key)
	buildings_button.toggled.connect(set_building_shop_open)
	tower_shop.add_sibling(buildings_button)
	building_shop = BuildingShop.new()
	building_shop.visible = false
	add_child(building_shop)
	move_child(building_shop, bottom_bar.get_index() + 1)
	building_shop.building_selected.connect(building_selected.emit)
	building_details = BuildingInfoPanel.new()
	add_child(building_details)
	move_child(building_details, tower_details.get_index() + 1)
	building_details.demolish_requested.connect(demolish_requested.emit)
	building_details.close_requested.connect(building_details_closed.emit)
	building_details.research_requested.connect(research_requested.emit)
	_setup_worker_bar()


## Barre des ouvriers choisis : combien, ce qu'on peut leur désigner, et les boutons
## « Au QG », « Automatique » et ✕ (les relâcher).
func _setup_worker_bar() -> void:
	worker_bar = PanelContainer.new()
	worker_bar.visible = false
	worker_bar.add_theme_stylebox_override(&"panel", UiStyle.panel(Worker.SELECTED_COLOR, 8.0, SIDE_LEFT))
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	worker_bar.add_child(row)
	_worker_bar_label = Label.new()
	_worker_bar_label.add_theme_font_size_override(&"font_size", 13)
	_worker_bar_label.add_theme_color_override(&"font_color", Worker.SELECTED_COLOR)
	_worker_bar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_worker_bar_label)
	for item in [["Au QG", "Les ouvriers choisis rentrent au QG et y restent, à l'abri.", workers_sent_home],
			["Automatique", "Les ouvriers choisis reprennent les tâches que le jeu leur donne.", workers_released],
			["✕", "Relâcher les ouvriers choisis (Échap).", workers_deselected]]:
		var button := Button.new()
		button.text = item[0]
		button.tooltip_text = item[1]
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override(&"font_size", 13)
		UiStyle.style_button(button, Worker.SELECTED_COLOR, 10.0, 6.0)
		button.pressed.connect((item[2] as Signal).emit)
		row.add_child(button)
	add_child(worker_bar)
	move_child(worker_bar, bottom_bar.get_index() + 1)


## Ouvriers choisis (0 = aucun : la barre se cache).
func show_worker_selection(count: int) -> void:
	if worker_bar == null:
		return
	_worker_bar_count = count
	worker_bar.visible = count > 0 and not end_panel.visible
	if not worker_bar.visible:
		return
	_worker_bar_label.text = tr_n("%d ouvrier choisi", "%d ouvriers choisis", count) % count + "  ·  " \
		+ tr("Désignez un rocher, un filon, un chantier ou le QG")
	worker_bar.reset_size()
	_place_worker_bar.call_deferred()


func _place_worker_bar() -> void:
	worker_bar.reset_size()
	worker_bar.position = Vector2(8.0, bottom_bar.get_global_rect().position.y - worker_bar.size.y - 6.0)


## Ouvre ou ferme la barre des bâtiments, au-dessus du bouton « Bâtiments ». La fermer
## abandonne le bâtiment choisi.
func set_building_shop_open(open: bool) -> void:
	if building_shop == null or (open and end_panel.visible):
		return
	buildings_button.set_pressed_no_signal(open)
	if open == building_shop.visible:
		return
	building_shop.visible = open
	if open:
		building_shop.reset_size()
		_place_building_shop.call_deferred()
	else:
		building_selected.emit(-1)


func _place_building_shop() -> void:
	var anchor := buildings_button.get_global_rect()
	var screen := get_viewport().get_visible_rect()
	building_shop.reset_size()
	var x := clampf(anchor.end.x - building_shop.size.x, 8.0, screen.size.x - building_shop.size.x - 8.0)
	building_shop.position = Vector2(x, bottom_bar.get_global_rect().position.y - building_shop.size.y - 6.0)


## Bâtiment choisi (-1 = aucun) : sa case enfoncée. Quand le choix est abandonné (posé
## ou annulé), la barre des bâtiments se referme et les chiffres reviennent aux tours.
func set_selected_building(kind: int) -> void:
	if building_shop == null:
		return
	building_shop.set_selected(kind)
	if kind < 0 and building_shop.visible:
		buildings_button.set_pressed_no_signal(false)
		building_shop.visible = false


## Fiche d'un bâtiment posé (null = la fermer).
func show_building_details(building: Building) -> void:
	if building_details == null:
		return
	if building:
		building_details.bounds = get_play_area()
		building_details.conquest = building.conquest
		building_details.show_building(building)
	else:
		building_details.close()


## Pierre, essence, ouvriers (sur le maximum), compte à rebours de la prochaine vague et
## bâtiments qu'on peut payer.
func update_conquest(conquest: Conquest) -> void:
	_conquest = conquest
	stone_label.text = tr("Pierre : %d") % conquest.stone
	essence_label.text = tr("Essence : %d") % conquest.essence
	workers_label.text = tr("Ouvriers : %d / %d") % [conquest.get_workers().size(), conquest.get_max_workers()]
	recruit_button.disabled = not conquest.can_recruit() or end_panel.visible
	var countdown := conquest.wave_countdown
	next_wave_button.text = "Lancer la vague" if countdown < 0.0 else tr("Vague dans %d s") % ceili(countdown)
	tower_shop.set_stone(conquest.stone)
	tower_details.set_essence(conquest.essence)
	building_shop.refresh(conquest.level.gold, conquest.stone, conquest.essence)
	if end_panel.visible:
		set_building_shop_open(false)
		buildings_button.disabled = true
		worker_bar.visible = false
	_fit_level_label()


# --- Défi du jour -------------------------------------------------------------

## Affiche les règles du défi au milieu de la carte (jusqu'à la première vague) et le
## score dans la barre du haut, avec les règles en bulle d'aide.
func show_challenge_rules(rules: Array[String]) -> void:
	score_label = Label.new()
	score_label.add_theme_color_override("font_color", Progress.ENDLESS_STAR_COLOR)
	score_label.mouse_filter = Control.MOUSE_FILTER_STOP
	score_label.tooltip_text = "\n".join(rules) + "\n" + DailyChallenge.describe_score()
	wave_label.add_sibling(score_label)
	set_score(0)
	_show_rules_panel(tr("Défi du jour"), Progress.ENDLESS_STAR_COLOR, rules, DailyChallenge.describe_score())


## Mutateurs (voir Mutators) : leurs règles au milieu de la carte jusqu'à la première
## vague (pas tant que le choix des tours est ouvert : `with_panel` à false, puis
## show_rules_panel_later()), et « ✦ Mutateurs » dans la barre du haut, avec les règles
## en bulle d'aide. `stars` : étoiles infinies de la victoire ; `best` : déjà obtenues.
func show_mutator_rules(rules: Array[String], stars: int, best: int, with_panel := true) -> void:
	var footer := tr("Victoire : ☠ %d (meilleur résultat sur ce niveau : %d / %d).") % [stars, best, Mutators.MAX_STARS]
	mutator_label = Label.new()
	mutator_label.text = tr("✦ Mutateurs")
	mutator_label.add_theme_color_override("font_color", Mutators.COLOR)
	mutator_label.mouse_filter = Control.MOUSE_FILTER_STOP
	mutator_label.tooltip_text = "\n".join(rules) + "\n" + footer
	wave_label.add_sibling(mutator_label)
	_pending_rules_panel = _show_rules_panel.bind(tr("Mutateurs"), Mutators.COLOR, rules, footer)
	if with_panel:
		show_rules_panel_later()


## Affiche le panneau des mutateurs gardé par show_mutator_rules(with_panel = false).
func show_rules_panel_later() -> void:
	if _pending_rules_panel.is_valid():
		_pending_rules_panel.call()
		_pending_rules_panel = Callable()


## Panneau de règles au milieu de la carte (défi du jour, mutateurs), effacé au
## lancement de la première vague (hide_challenge_rules()).
func _show_rules_panel(title: String, color: Color, rules: Array[String], footer_text: String) -> void:
	challenge_rules = PanelContainer.new()
	var style := UiStyle.panel(color, 18.0, SIDE_TOP)
	challenge_rules.add_theme_stylebox_override("panel", style)
	challenge_rules.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	challenge_rules.add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 26)
	heading.add_theme_color_override("font_color", color)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	for rule in rules:
		var line := Label.new()
		line.text = "•  " + rule
		column.add_child(line)
	var footer := Label.new()
	footer.text = footer_text
	footer.add_theme_color_override("font_color", Color(0.75, 0.8, 0.75))
	footer.add_theme_font_size_override("font_size", 14)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.custom_minimum_size.x = 520.0
	column.add_child(footer)
	add_child(challenge_rules)
	move_child(challenge_rules, wave_preview.get_index())
	_place_challenge_rules.call_deferred()


func _place_challenge_rules() -> void:
	if not challenge_rules:
		return
	challenge_rules.reset_size()
	# Au milieu de l'écran (les barres ne sont pas encore placées au lancement).
	challenge_rules.position = (get_viewport().get_visible_rect().size - challenge_rules.size) / 2.0


## Les règles s'effacent au lancement de la première vague (elles restent sur le score).
func hide_challenge_rules() -> void:
	_pending_rules_panel = Callable()
	if not challenge_rules:
		return
	var panel := challenge_rules
	challenge_rules = null
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(panel.queue_free)


func set_score(score: int) -> void:
	_score = score
	if score_label:
		score_label.text = tr("Score : %d") % score


## Écran de fin du défi du jour : score de la partie, meilleur score du jour,
## « Nouveau record » s'il est battu, et la série de jours réussis d'affilée.
func show_challenge_end_screen(victory: bool, score: int, best: int, new_record := false, streak := 0) -> void:
	show_end_screen(victory)
	hide_challenge_rules()
	end_title.text = "Défi réussi !" if victory else "Défi perdu"
	end_stars.visible = true
	end_stars.text = tr("%d points") % score
	end_stars.add_theme_color_override("font_color", Progress.ENDLESS_STAR_COLOR)
	end_message.text += "\n" + tr("Meilleur score du jour : %d") % best
	if new_record:
		end_message.text += "\n" + tr("Nouveau record !")
	if streak > 1:
		end_message.text += "\n" + tr("Série : %d jours réussis d'affilée !") % streak
	end_message.text += "\n" + tr("Un nouveau défi demain.")
	_end_screen = show_challenge_end_screen.bind(victory, score, best, new_record, streak)


## Écran de fin d'une victoire avec des mutateurs (après show_end_screen()) : étoiles
## infinies gagnées, et celles qui s'ajoutent au meilleur résultat du niveau.
func show_mutator_result(stars: int, best_before: int) -> void:
	hide_challenge_rules()
	end_message.text += "\n" + tr("Mutateurs : ☠ %d / %d") % [stars, Mutators.MAX_STARS]
	if stars > best_before:
		end_message.text += "\n" + tr("+%d crânes à dépenser dans Améliorations.") % (stars - best_before) \
			if stars - best_before > 1 else "\n" + tr("+1 crâne à dépenser dans Améliorations.")
	_mutator_result = [stars, best_before]


## Une ligne par mode que la victoire vient de débloquer (Unlocks).
func show_unlocked_features(features: Array) -> void:
	for feature: int in features:
		end_message.text += "\n" + tr("Vous avez débloqué %s !") % tr(Unlocks.NAMES[feature])
	_unlocked_features = features


# --- Fenêtres de détail -------------------------------------------------------

## Fenêtre de détail de la prochaine vague, sous son aperçu : chaque sorte de monstre
## avec sa vie (difficulté comprise), sa vitesse, son or et ses capacités.
func show_wave_details() -> void:
	if not _next_wave or end_panel.visible:
		wave_details.close()
		return
	var lines: Array[String] = []
	lines.append("[b]%s[/b]   [color=%s]%s[/color]" % [tr("Vague %d") % _next_wave_number, EnemyInfo.GOLD_HEX,
		tr("Bonus : +%d or") % _next_wave_bonus])
	for entry in _next_wave.get_summary():
		var data: EnemyData = entry.enemy.make_elite() if entry.elite else entry.enemy
		lines.append("")
		lines.append("%s  %s  [color=%s]x %d[/color]" % [EnemyInfo.icon(data, 32), EnemyInfo.title(data),
			EnemyInfo.MUTED, entry.count])
		lines.append(EnemyInfo.summary_line(data, entry.health, enemy_speed_multiplier))
		for ability in data.get_abilities():
			lines.append("[color=#c8e6c8]• %s[/color]" % ability)
	wave_details.bounds = get_play_area()
	wave_details.show_text("\n".join(lines), wave_preview.get_global_rect(), Color(0.95, 0.85, 0.45),
		DetailPopup.Side.BELOW)


func _process(_delta: float) -> void:
	_update_hovered_enemy()
	var hint := tr(TOUCH_HINT) if GameSettings.is_touch_mode() \
		else tr(GAMEPAD_HINT) if Gamepad.is_active() else tr(MOUSE_HINT)
	if recruit_button:
		hint = tr(CONQUEST_HINT) + "  ·  " + hint
	if shop_hint.text != hint:
		shop_hint.text = hint


## Au tactile, toucher un monstre ouvre sa fiche (il n'y a pas de survol) ; toucher
## ailleurs la ferme. `_input` : le toucher continue vers la carte (pose des tours).
## La fiche d'une tour posée se ferme avec Échap, ou avec un clic n'importe où en dehors
## d'elle (le clic sert quand même : une autre tour, la barre d'achat…).
func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch and touch.pressed:
		touched_enemy = find_enemy_at(touch.position)
	if not tower_details.visible or tower_details.tower == null or tower_picker or options_menu or chest_choice:
		return
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT] \
			and not tower_details.get_global_rect().has_point(click.position):
		tower_details_closed.emit()
	elif event.is_action_pressed(&"ui_cancel"):
		tower_details_closed.emit()
		get_viewport().set_input_as_handled()


## Monstre sous la souris (ou touché) : sa fenêtre de détail le suit, avec sa vie restante.
func _update_hovered_enemy() -> void:
	if not visible or end_panel.visible:
		show_enemy_details(null)
	elif GameSettings.is_touch_mode():
		show_enemy_details(touched_enemy if is_instance_valid(touched_enemy) else null)
	else:
		show_enemy_details(find_enemy_at(get_viewport().get_mouse_position()))


## Fenêtre de détail d'un monstre en jeu, à côté de lui (null = la fermer).
func show_enemy_details(enemy: Enemy) -> void:
	hovered_enemy = enemy
	if not is_instance_valid(enemy) or not enemy.is_alive:
		hovered_enemy = null
		enemy_details.close()
		return
	var center := enemy.get_global_transform_with_canvas().origin
	var radius := enemy.data.radius * 1.3
	var text := "%s  %s\n%s" % [EnemyInfo.icon(enemy.data, 32), EnemyInfo.title(enemy.data),
		EnemyInfo.stats(enemy.data, enemy.health_multiplier, enemy.speed_multiplier, enemy.health.health,
		enemy.health.shield)]
	if enemy.carried >= 0:
		text += "\n[color=#%s]%s[/color]" % [Enemy.CARRIER_COLOR.to_html(false),
			tr("Porteur : lâche un coffre à sa mort.") if enemy.carried == Loot.Kind.CHEST
			else tr("Porteur : lâche du butin à sa mort.")]
	enemy_details.bounds = get_play_area()
	var border := EnemyData.boss_color() if enemy.data.is_boss \
		else EnemyData.ELITE_COLOR if enemy.data.is_elite else enemy.data.color
	enemy_details.show_text(text, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), border)


## Monstre en jeu le plus proche de ce point de l'écran, s'il est dessus (sur la carte).
func find_enemy_at(mouse: Vector2) -> Enemy:
	if not get_play_area().has_point(mouse) or wave_preview.get_global_rect().has_point(mouse):
		return null
	var best: Enemy = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if not enemy or not enemy.is_alive or not enemy.is_node_ready():
			continue
		var distance := enemy.get_global_transform_with_canvas().origin.distance_to(mouse)
		if distance <= enemy.data.radius * 1.3 + 4.0 and distance < best_distance:
			best = enemy
			best_distance = distance
	return best


## Suit un boss qui vient d'apparaître : sa vie s'affiche en haut de la carte.
func track_boss(enemy: Enemy) -> void:
	boss_bar.track(enemy)
	_place_boss_bar.call_deferred()


func _place_boss_bar() -> void:
	boss_bar.reset_size()
	var screen := get_viewport().get_visible_rect().size
	boss_bar.position = Vector2((screen.x - boss_bar.size.x) / 2.0, top_bar.get_global_rect().end.y + 8.0)
