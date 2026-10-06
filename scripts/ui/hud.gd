class_name Hud
extends CanvasLayer
## Interface du niveau : or, vies et vague en haut ; barre d'achat des tours, pause,
## vitesse et menu Options en bas ; fiches des tours et écran de fin.
## Au survol, des fenêtres de détail : celle de la prochaine vague (sur son aperçu) et
## celle du monstre sous la souris. La vie des boss en jeu s'affiche en haut de la carte.

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

## Durée de l'effet de perte de vies, en secondes réelles (indépendante de la vitesse de jeu).
const DAMAGE_FLASH_DURATION := 0.6
const LIVES_COLOR := Color(1, 0.5, 0.5)
const LIVES_HIT_COLOR := Color(1, 0.15, 0.15)
## Rappel des commandes à côté de la barre d'achat, à la souris et au tactile.
const MOUSE_HINT := "Clic gauche : poser la tour  ·  Maj + clic : en poser plusieurs  ·  Clic droit / Échap : annuler  ·  Clic sur une tour posée : détails, amélioration, vente et cible  ·  1 à 0 : choisir une tour  ·  Espace : pause  ·  V : vitesse"
const TOUCH_HINT := "Touchez une tour de la barre, puis deux fois une case libre pour la poser  ·  Touchez-la encore dans la barre pour annuler  ·  Touchez une tour posée pour sa fiche, un monstre pour le sien  ·  Un pouvoir visé se lance là où vous touchez"
## Touches des pouvoirs, par position sur le clavier : Q, W, E en QWERTY (A, Z, E en AZERTY).
const POWER_KEYS: Array[Key] = [KEY_Q, KEY_W, KEY_E]

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
## Boutons des pouvoirs actifs, en haut, à gauche du bouton de vague.
var power_bar: HBoxContainer
var power_buttons: Array[PowerButton] = []

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
## Composition de la prochaine vague et bonus pour la lancer en avance.
@onready var wave_preview: PanelContainer = %WavePreview
@onready var wave_preview_label: RichTextLabel = %WavePreviewLabel
## Voile rouge affiché quand le joueur perd des vies.
@onready var damage_flash: ColorRect = %DamageFlash


func _ready() -> void:
	end_panel.visible = false
	next_wave_button.pressed.connect(next_wave_requested.emit)
	%RestartButton.pressed.connect(restart_requested.emit)
	%NextLevelButton.pressed.connect(next_level_requested.emit)
	%MenuButton.pressed.connect(menu_requested.emit)
	tower_details.upgrade_requested.connect(upgrade_requested.emit)
	tower_details.sell_requested.connect(sell_requested.emit)
	tower_details.close_requested.connect(tower_details_closed.emit)
	pause_button.pressed.connect(pause_toggled.emit)
	options_button.pressed.connect(open_options)
	lives_label.add_theme_color_override("font_color", LIVES_COLOR)
	boss_bar = BossBar.new()
	add_child(boss_bar)
	move_child(boss_bar, wave_preview.get_index())
	wave_details = DetailPopup.new(400.0)
	add_child(wave_details)
	enemy_details = DetailPopup.new(270.0)
	add_child(enemy_details)
	# L'aperçu de vague prend la souris pour ouvrir sa fenêtre de détail.
	wave_preview.mouse_filter = Control.MOUSE_FILTER_STOP
	wave_preview.mouse_default_cursor_shape = Control.CURSOR_HELP
	wave_preview.mouse_entered.connect(show_wave_details)
	wave_preview.mouse_exited.connect(wave_details.close)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo or end_panel.visible or tower_picker or options_menu:
		return
	# Position physique des touches : en AZERTY, la rangée 1, 2, 3 donne « & é " » sans Maj.
	var code := key.physical_keycode
	var slot := TowerShop.slot_for_key(code)
	var power_index := POWER_KEYS.find(code)
	if power_index >= 0 and power_index < power_buttons.size():
		power_selected.emit(power_buttons[power_index].power)
	elif code == KEY_SPACE or code == KEY_P:
		pause_toggled.emit()
	elif code == KEY_V:
		_select_next_speed()
	elif slot >= 0:
		tower_shop.toggle_slot(slot)
	else:
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
		speed_button.tooltip_text = "Vitesse %s (V : vitesse suivante)" % speed_text
		speed_button.pressed.connect(game_speed_selected.emit.bind(speed))
		speed_buttons.add_child(speed_button)
	set_tower_types(tower_types)
	tower_shop.tower_selected.connect(tower_selected.emit)
	tower_shop.tower_hovered.connect(_on_shop_button_hovered)
	tower_shop.hover_ended.connect(shop_info.close)


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
	interest_label.tooltip_text = ("Chaque fois que la carte est vidée, l'or gardé rapporte %d %% d'intérêts "
		+ "(%d or au plus), avant le bonus de vague.") % [roundi(rate * 100.0), cap]


## Point de l'écran où s'affichent les intérêts versés : sous l'or.
func get_interest_anchor() -> Vector2:
	var rect := interest_label.get_global_rect() if interest_label.visible else gold_label.get_global_rect()
	return Vector2(rect.get_center().x, rect.end.y + 14.0)


## Remplit la barre d'achat (après le choix des tours, s'il y en a un).
func set_tower_types(tower_types: Array[TowerData]) -> void:
	tower_shop.setup(tower_types)
	tower_shop.set_gold(_gold)
	# Avec les tours débloquées dans l'arbre, la barre d'achat prend la place du rappel des commandes.
	shop_hint.visible = tower_types.size() <= 7


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
func update_stats(gold: int, lives: int, wave: int, wave_count: int, interest := -1) -> void:
	_gold = gold
	gold_label.text = "Or : %d" % gold
	interest_label.visible = interest >= 0
	interest_label.text = "Intérêts : +%d" % maxi(interest, 0)
	lives_label.text = "Vies : %d" % lives
	wave_label.text = "Vague : %d / %s" % [wave, str(wave_count) if wave_count >= 0 else "∞"]
	tower_shop.set_gold(gold)
	shop_info.set_gold(gold)
	tower_details.set_gold(gold)


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
		text = "[color=#ffffff99]Prochaine vague :[/color]  " + "   ".join(parts)
		if early_bonus > 0:
			text += "\n[color=#ffd54d]Lancer maintenant : +%d or[/color]" % early_bonus
	if text == _wave_preview_text:
		return
	_wave_preview_text = text
	wave_preview_label.text = text
	wave_preview.visible = not text.is_empty()
	next_wave_button.tooltip_text = "Lancer maintenant rapporte %d or" % early_bonus if early_bonus > 0 else ""
	wave_preview.reset_size()
	# Le panneau, sous le bouton de vague, reste calé à droite de l'écran.
	wave_preview.position.x = get_viewport().get_visible_rect().size.x - 8.0 - wave_preview.size.x


func set_paused(paused: bool) -> void:
	pause_button.set_pressed_no_signal(paused)
	pause_button.text = "Reprendre" if paused else "Pause"
	pause_overlay.visible = paused


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
func show_end_screen(victory: bool, can_continue := false, stars := 0, new_record := false,
		unlocked_world := "") -> void:
	end_title.text = "Victoire !" if victory else "Défaite"
	end_stars.visible = victory and stars > 0
	end_stars.text = Progress.star_text(stars)
	end_message.text = "Toutes les vagues ont été repoussées." if victory \
		else "Les ennemis ont atteint votre base."
	if new_record:
		end_message.text += "\nNouveau record !"
	if not unlocked_world.is_empty():
		end_message.text += "\nNouveau monde débloqué : %s" % unlocked_world
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


## Écran de fin du mode infini : vagues repoussées, étoiles infinies obtenues sur le
## niveau avec cette partie, et « Nouveau record » si le record de vagues est battu.
func show_endless_end_screen(waves: int, endless_stars: int, new_record := false) -> void:
	show_end_screen(false)
	end_title.text = "Fin de la partie"
	end_stars.visible = true
	end_stars.text = Progress.star_text(endless_stars, Progress.ENDLESS_MAX_STARS)
	end_stars.add_theme_color_override("font_color", Progress.ENDLESS_STAR_COLOR)
	end_message.text = "%d vague%s repoussée%s." % [waves, "s" if waves > 1 else "", "s" if waves > 1 else ""]
	if new_record:
		end_message.text += "\nNouveau record !"
	end_message.text += "\nUne étoile infinie toutes les %d vagues au-delà de celles du niveau." \
		% Progress.ENDLESS_STAR_STEP


## Zone de la carte visible entre la barre du haut et celle du bas.
func get_play_area() -> Rect2:
	var screen := get_viewport().get_visible_rect()
	var top := top_bar.get_global_rect().end.y
	return Rect2(0.0, top, screen.size.x, bottom_bar.get_global_rect().position.y - top)


func _on_shop_button_hovered(button: TowerShopButton) -> void:
	# L'aperçu s'ouvre au-dessus de la barre d'achat, sur la carte.
	shop_info.bounds = get_play_area()
	shop_info.show_tower_type(button.data, _gold, button.get_global_rect())


# --- Fenêtres de détail -------------------------------------------------------

## Fenêtre de détail de la prochaine vague, sous son aperçu : chaque sorte de monstre
## avec sa vie (difficulté comprise), sa vitesse, son or et ses capacités.
func show_wave_details() -> void:
	if not _next_wave or end_panel.visible:
		wave_details.close()
		return
	var lines: Array[String] = []
	lines.append("[b]Vague %d[/b]   [color=%s]Bonus : +%d or[/color]" % [_next_wave_number, EnemyInfo.GOLD_HEX,
		_next_wave_bonus])
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
	var hint := TOUCH_HINT if GameSettings.is_touch_mode() else MOUSE_HINT
	if shop_hint.text != hint:
		shop_hint.text = hint


## Au tactile, toucher un monstre ouvre sa fiche (il n'y a pas de survol) ; toucher
## ailleurs la ferme. `_input` : le toucher continue vers la carte (pose des tours).
func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch and touch.pressed:
		touched_enemy = find_enemy_at(touch.position)


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
	enemy_details.bounds = get_play_area()
	var border := EnemyData.BOSS_COLOR if enemy.data.is_boss \
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
