class_name Hud
extends CanvasLayer
## Interface du niveau : or, vies et vague en haut ; barre d'achat des tours, pause,
## vitesse et réglages du son en bas ; fiches des tours et écran de fin.

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

## Durée de l'effet de perte de vies, en secondes réelles (indépendante de la vitesse de jeu).
const DAMAGE_FLASH_DURATION := 0.6
const LIVES_COLOR := Color(1, 0.5, 0.5)
const LIVES_HIT_COLOR := Color(1, 0.15, 0.15)

var _speed_group := ButtonGroup.new()
var _gold := 0
var _damage_tween: Tween
## Dernier contenu affiché dans l'aperçu de vague, pour ne le refaire que s'il change.
var _wave_preview_text := ""

@onready var level_label: Label = %LevelLabel
@onready var gold_label: Label = %GoldLabel
@onready var lives_label: Label = %LivesLabel
@onready var wave_label: Label = %WaveLabel
## Barre d'achat, en bas à gauche.
@onready var tower_shop: TowerShop = %TowerShop
## Rappel des commandes, à côté de la barre d'achat.
@onready var shop_hint: Label = $BottomBar/Margin/Row/Hint
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
@onready var audio_toggles: AudioToggles = %AudioToggles
@onready var top_bar: Control = $TopBar
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
	lives_label.add_theme_color_override("font_color", LIVES_COLOR)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo or end_panel.visible:
		return
	# Position physique des touches : en AZERTY, la rangée 1, 2, 3 donne « & é " » sans Maj.
	var code := key.physical_keycode
	var slot := TowerShop.slot_for_key(code)
	if code == KEY_SPACE or code == KEY_P:
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
		speed_button.text = "x%s" % str(speed).trim_suffix(".0")
		speed_button.toggle_mode = true
		speed_button.button_group = _speed_group
		speed_button.focus_mode = Control.FOCUS_NONE
		speed_button.custom_minimum_size = Vector2(36, 0)
		speed_button.set_meta("speed", speed)
		speed_button.tooltip_text = "Vitesse x%s (V : vitesse suivante)" % str(speed).trim_suffix(".0")
		speed_button.pressed.connect(game_speed_selected.emit.bind(speed))
		speed_buttons.add_child(speed_button)
	tower_shop.setup(tower_types)
	# Avec les tours débloquées dans l'arbre, la barre d'achat prend la place du rappel des commandes.
	shop_hint.visible = tower_types.size() <= 7
	tower_shop.tower_selected.connect(tower_selected.emit)
	tower_shop.tower_hovered.connect(_on_shop_button_hovered)
	tower_shop.hover_ended.connect(shop_info.close)


## Passe à la vitesse suivante (après la dernière, on revient à la première).
func _select_next_speed() -> void:
	var buttons := speed_buttons.get_children()
	if buttons.is_empty():
		return
	var current := buttons.find(_speed_group.get_pressed_button())
	(buttons[(current + 1) % buttons.size()] as Button).pressed.emit()


func update_stats(gold: int, lives: int, wave: int, wave_count: int) -> void:
	_gold = gold
	gold_label.text = "Or : %d" % gold
	lives_label.text = "Vies : %d" % lives
	wave_label.text = "Vague : %d / %d" % [wave, wave_count]
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
## est positive, la prime pour la lancer avant d'avoir vidé la carte.
func show_next_wave(wave: WaveData, early_bonus := 0) -> void:
	var text := ""
	if wave:
		var counts := {}
		for group in wave.groups:
			counts[group.enemy] = counts.get(group.enemy, 0) + group.count
		var parts: Array[String] = []
		for enemy: EnemyData in counts:
			parts.append("[color=#%s]●[/color] %d %s" % [enemy.color.to_html(false), counts[enemy], enemy.display_name])
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
	shop_info.close()
	tower_details.close()
	wave_preview.visible = false
	if can_continue:
		next_level_button.grab_focus()
	else:
		%RestartButton.grab_focus()


## Zone de la carte visible entre la barre du haut et celle du bas.
func get_play_area() -> Rect2:
	var screen := get_viewport().get_visible_rect()
	var top := top_bar.get_global_rect().end.y
	return Rect2(0.0, top, screen.size.x, bottom_bar.get_global_rect().position.y - top)


func _on_shop_button_hovered(button: TowerShopButton) -> void:
	# L'aperçu s'ouvre au-dessus de la barre d'achat, sur la carte.
	shop_info.bounds = get_play_area()
	shop_info.show_tower_type(button.data, _gold, button.get_global_rect())
