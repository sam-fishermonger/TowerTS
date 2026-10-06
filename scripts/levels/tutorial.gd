class_name Tutorial
extends CanvasLayer
## Tutoriel de première partie : sur le niveau du tutoriel (Level.is_tutorial), une bulle
## guide le joueur pas à pas (poser une tour, lancer une vague, l'or et les intérêts, la
## fiche d'une tour, les volants, les furtifs, un pouvoir) et un cadre clignotant montre
## où regarder ou cliquer.
##
## Chaque étape a sa condition : la bulle montre toujours la première étape qui n'est pas
## remplie. Le joueur peut donc prendre de l'avance (les étapes déjà faites sont sautées),
## et une étape « réversible » revient si sa condition cesse d'être vraie (la tour choisie
## est reposée avant d'être posée). Les étapes sans action ont un bouton Suivant, et
## s'effacent aussi dès qu'une étape d'après est remplie.
##
## Les textes passent par tr() : ils se traduisent comme le reste du jeu.

## Réglage (Progress) : le tutoriel a été fini ou passé.
const DONE_SETTING := "tutorial_done"
const LEVEL_PATH := "res://scenes/levels/tutorial.tscn"
const CANNON: TowerData = preload("res://resources/towers/cannon.tres")
const GATLING: TowerData = preload("res://resources/towers/gatling.tres")
const SNIPER: TowerData = preload("res://resources/towers/sniper.tres")
## Pouvoir prêté pour la dernière vague : l'arbre des améliorations ne compte pas ici.
const FREEZE: Power = preload("res://resources/powers/freeze.tres")
## Cases conseillées pour chaque tour (une case libre près du chemin, à bonne portée).
const CANNON_CELL := Vector2i(5, 4)
const GATLING_CELL := Vector2i(12, 6)
const SNIPER_CELL := Vector2i(7, 6)
## Largeur de la bulle, et écart avec ce qu'elle montre.
const BUBBLE_WIDTH := 400.0
const BUBBLE_GAP := 18.0
## Couche au-dessus du HUD (mais la bulle se cache derrière les menus, voir _process).
const LAYER := 5

var level: Level
## Étapes, dans l'ordre : { text, touch_text (facultatif), done: Callable -> bool,
## target: Callable -> Rect2 (vide = rien à montrer), next (bouton Suivant),
## revertible, on_enter: Callable (facultatif) }.
var steps: Array[Dictionary] = []
## Index de l'étape affichée (-1 = aucune, steps.size() = tutoriel fini).
var current := -1
## Étapes déjà remplies une fois (elles ne reviennent pas, sauf les réversibles).
var _completed := {}
var _time := 0.0

var bubble: PanelContainer
var _counter: Label
var _text: RichTextLabel
var _next_button: Button
var _skip_button: Button
## Cadre clignotant autour de la cible, dessiné par-dessus le jeu.
var _overlay: Control
var _target := Rect2()


## Le tutoriel a déjà été fini ou passé.
static func is_done() -> bool:
	return Progress.get_setting(DONE_SETTING, false)


static func mark_done() -> void:
	Progress.set_setting(DONE_SETTING, true)


func setup(tutorial_level: Level) -> void:
	level = tutorial_level
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_steps()
	_build_ui()
	level.game_over.connect(_on_game_over)
	_update()


# --- Étapes -----------------------------------------------------------------

func _build_steps() -> void:
	var power_key := Hud.key_label(Hud.POWER_KEYS[0])
	steps = [
		{
			text = tr("Bienvenue ! Les monstres entrent à gauche et suivent le chemin jusqu'à votre [b]base[/b], à droite. Chacun qui l'atteint vous coûte des vies : à 0, la partie est perdue."),
			target = func() -> Rect2: return _world_rect(level.map.get_base_position(), level.map.cell_size * 1.4),
			next = true,
		},
		{
			text = tr("Pour les arrêter, il faut des tours. Choisissez le [b]Canon[/b] dans la barre d'achat (ou touche 1). Survoler une case montre la fiche de la tour."),
			touch_text = tr("Pour les arrêter, il faut des tours. Touchez le [b]Canon[/b] dans la barre d'achat."),
			done = func() -> bool: return level.placer.selected_tower == CANNON or _count_towers(CANNON) > 0,
			target = func() -> Rect2: return _shop_rect(CANNON),
			revertible = true,
		},
		{
			text = tr("Posez-le sur une case libre près du chemin, par exemple celle qui clignote. Le cercle montre sa portée. Clic droit ou Échap pour annuler."),
			touch_text = tr("Touchez une case libre près du chemin, par exemple celle qui clignote, puis touchez-la encore pour poser la tour."),
			done = func() -> bool: return _count_towers(CANNON) > 0,
			target = func() -> Rect2: return _cell_rect(CANNON_CELL),
		},
		{
			text = tr("En haut, votre [b]or[/b] et vos [b]vies[/b]. L'encadré sous « Lancer la vague » annonce les monstres qui arrivent : survolez-le pour le détail de chacun."),
			target = func() -> Rect2: return level.hud.wave_preview.get_global_rect() if level.hud.wave_preview.visible else Rect2(),
			next = true,
		},
		{
			text = tr("Prêt ? Cliquez sur [b]Lancer la vague[/b]."),
			touch_text = tr("Prêt ? Touchez [b]Lancer la vague[/b]."),
			done = func() -> bool: return level.spawner.current_wave >= 0,
			target = func() -> Rect2: return level.hud.next_wave_button.get_global_rect(),
		},
		{
			text = tr("Chaque monstre détruit rapporte de l'or. Survolez un monstre pour voir sa fiche. On peut poser des tours pendant la vague aussi."),
			touch_text = tr("Chaque monstre détruit rapporte de l'or. Touchez un monstre pour voir sa fiche. On peut poser des tours pendant la vague aussi."),
			done = func() -> bool: return level.get_waves_cleared() >= 1,
		},
		{
			text = tr("Vague repoussée ! Elle rapporte un bonus, et l'or gardé rapporte des [b]intérêts[/b] chaque fois que la carte est vidée : %d %%, %d or au plus. Épargner un peu paie.") % [
				roundi(level.interest_rate * 100.0), level.interest_cap],
			target = func() -> Rect2: return level.hud.interest_label.get_global_rect(),
			next = true,
		},
		{
			text = tr("Cliquez sur votre Canon pour ouvrir sa [b]fiche[/b]."),
			touch_text = tr("Touchez votre Canon pour ouvrir sa [b]fiche[/b]."),
			done = func() -> bool: return level.placer.inspected_tower != null or _is_any_upgraded(),
			target = func() -> Rect2: return _tower_rect(_first_tower(CANNON)),
			revertible = true,
		},
		{
			text = tr("[b]Améliorez-le[/b] : les gains s'affichent en vert avant l'achat. Chaque tour a deux améliorations."),
			done = _is_any_upgraded,
			target = func() -> Rect2: return _visible_rect(level.hud.tower_details.upgrade_button),
		},
		{
			text = tr("Le bouton [b]Cible[/b] choisit l'ennemi visé en priorité : le premier, le dernier, le plus fort ou le plus proche. [b]Vendre[/b] rend 70 % de ce que la tour a coûté."),
			target = func() -> Rect2: return _visible_rect(level.hud.tower_details.target_button),
			next = true,
		},
		{
			text = tr("La prochaine vague amène des [b]Frelons[/b] : ces volants survolent le chemin en coupant les virages, et certaines tours ne tirent pas en l'air. Posez une [b]Mitrailleuse[/b] (touche 2) près de la sortie."),
			touch_text = tr("La prochaine vague amène des [b]Frelons[/b] : ces volants survolent le chemin en coupant les virages, et certaines tours ne tirent pas en l'air. Posez une [b]Mitrailleuse[/b] près de la sortie."),
			done = func() -> bool: return _count_towers(GATLING) > 0,
			target = func() -> Rect2: return _cell_rect(GATLING_CELL) if level.placer.selected_tower == GATLING \
				else _shop_rect(GATLING),
		},
		{
			text = tr("Lancez la vague suivante. Astuce : la lancer avant que la carte soit vide rapporte une prime, affichée sous l'encadré."),
			done = func() -> bool: return level.spawner.current_wave >= 1,
			target = func() -> Rect2: return level.hud.next_wave_button.get_global_rect(),
		},
		{
			text = tr("Pendant une vague, [b]Pause[/b] (Espace) fige le jeu sans vous empêcher de construire, et [b]x2[/b], [b]x3[/b] (touche V) l'accélèrent."),
			touch_text = tr("Pendant une vague, [b]Pause[/b] fige le jeu sans vous empêcher de construire, et [b]x2[/b], [b]x3[/b] l'accélèrent."),
			done = func() -> bool: return level.get_waves_cleared() >= 2,
			target = func() -> Rect2: return level.hud.pause_button.get_global_rect().merge(
				level.hud.speed_buttons.get_global_rect()),
		},
		{
			text = tr("Attention, des [b]Mantes[/b] arrivent ! Ces furtives sont invisibles pour les tours, sauf à portée d'une tour qui détecte, comme le [b]Sniper[/b] (l'œil violet et le cercle en pointillés). Posez-en un (touche 3)."),
			touch_text = tr("Attention, des [b]Mantes[/b] arrivent ! Ces furtives sont invisibles pour les tours, sauf à portée d'une tour qui détecte, comme le [b]Sniper[/b] (l'œil violet et le cercle en pointillés). Posez-en un."),
			done = func() -> bool: return _count_towers(SNIPER) > 0,
			target = func() -> Rect2: return _cell_rect(SNIPER_CELL) if level.placer.selected_tower == SNIPER \
				else _shop_rect(SNIPER),
		},
		{
			text = tr("Lancez la vague. Une Mante repérée par le Sniper devient visible pour toutes les tours."),
			done = func() -> bool: return level.spawner.current_wave >= 2,
			target = func() -> Rect2: return level.hud.next_wave_button.get_global_rect(),
		},
		{
			text = tr("Les Mantes sont aussi blindées : chaque coup perd un peu de dégâts. Les gros coups du Sniper passent bien mieux l'armure."),
			done = func() -> bool: return level.get_waves_cleared() >= 3,
		},
		{
			text = tr("Dernière vague, la plus grosse, avec un [b]élite[/b] (aura dorée) ! Pour la tenir, voici un [b]pouvoir[/b] : le Gel. Dans la campagne, les pouvoirs s'achètent avec les étoiles, dans l'arbre des améliorations. Dépensez votre or (améliorations, nouvelles tours), puis lancez la vague."),
			done = func() -> bool: return level.spawner.current_wave >= 3,
			target = func() -> Rect2: return level.hud.next_wave_button.get_global_rect(),
			on_enter = _lend_freeze,
		},
		{
			text = tr("Quand les monstres s'approchent, cliquez sur [b]Gel[/b] (touche %s) : il fige tous les monstres un moment. Ensuite, il se recharge.") % power_key,
			touch_text = tr("Quand les monstres s'approchent, touchez [b]Gel[/b] : il fige tous les monstres un moment. Ensuite, il se recharge."),
			done = func() -> bool: return level.get_power_cooldown(FREEZE) > 0.0,
			target = func() -> Rect2: return _power_rect(),
			on_enter = _lend_freeze,
		},
		{
			text = tr("Bien joué ! Tenez jusqu'au bout pour finir le tutoriel. Vous pouvez encore améliorer vos tours ou en poser d'autres."),
			done = func() -> bool: return level.is_over,
		},
	]


## La première étape qui n'est pas remplie, et sa bulle.
func _update() -> void:
	_skip_passed_info_steps()
	var index := 0
	while index < steps.size() and _is_step_done(index):
		index += 1
	if index != current:
		current = index
		if current < steps.size():
			var step := steps[current]
			if step.has("on_enter"):
				(step.on_enter as Callable).call()
			_show_step(step)
		else:
			bubble.visible = false
	_target = _get_target()


## Une étape à bouton Suivant est sautée dès que le joueur remplit une étape d'après
## (il a lancé la vague sans lire la bulle) : elle ne reste pas bloquée à l'écran.
func _skip_passed_info_steps() -> void:
	var later_done := false
	for index in range(steps.size() - 1, -1, -1):
		var step := steps[index]
		if step.has("done"):
			later_done = later_done or _completed.has(index) or (step.done as Callable).call()
		elif later_done and step.get("next", false):
			_completed[index] = true


func _is_step_done(index: int) -> bool:
	if _completed.has(index):
		return true
	var step := steps[index]
	if not step.has("done"):
		return false
	var done: bool = (step.done as Callable).call()
	if done and not step.get("revertible", false):
		_completed[index] = true
	return done


## Le bouton Suivant d'une étape sans action.
func next_step() -> void:
	if current >= 0 and current < steps.size():
		_completed[current] = true
		_update()


## Passer le tutoriel : il ne sera plus proposé, et la campagne commence.
func skip() -> void:
	mark_done()
	var next := level.get_next_level()
	level.get_tree().paused = false
	if next.is_empty():
		queue_free()
	else:
		level.get_tree().change_scene_to_file(next)


func _lend_freeze() -> void:
	if level.powers.has(FREEZE):
		return
	level.powers.append(FREEZE)
	level.power_cooldowns.append(0.0)
	var lent: Array[Power] = [FREEZE]
	level.hud.setup_powers(lent)


func _on_game_over(victory: bool) -> void:
	bubble.visible = false
	_target = Rect2()
	current = steps.size()
	if not victory:
		return
	mark_done()
	level.hud.end_message.text = tr("Tutoriel terminé : vous connaissez l'essentiel.\nLa campagne vous attend !")
	level.hud.next_level_button.text = tr("Commencer la campagne")


# --- Cibles -------------------------------------------------------------------

func _count_towers(data: TowerData) -> int:
	return level.get_towers().filter(func(tower: Tower) -> bool: return tower.data == data).size()


func _first_tower(data: TowerData) -> Tower:
	for tower in level.get_towers():
		if tower.data == data:
			return tower
	return null


func _is_any_upgraded() -> bool:
	return level.get_towers().any(func(tower: Tower) -> bool: return tower.level >= 2)


## Rectangle à l'écran d'un point de la carte, de la taille donnée.
func _world_rect(world_position: Vector2, size: float) -> Rect2:
	var center := level.get_viewport().get_canvas_transform() * world_position
	return Rect2(center - Vector2.ONE * size / 2.0, Vector2.ONE * size)


func _cell_rect(cell: Vector2i) -> Rect2:
	if not level.map.is_cell_buildable(cell):
		return Rect2()
	return _world_rect(level.map.cell_to_world(cell), level.map.cell_size)


func _tower_rect(tower: Tower) -> Rect2:
	return _world_rect(tower.global_position, Tower.SIZE + 8.0) if tower else Rect2()


func _shop_rect(data: TowerData) -> Rect2:
	for button: TowerShopButton in level.hud.tower_shop.get_children():
		if button.data == data:
			return button.get_global_rect()
	return Rect2()


func _power_rect() -> Rect2:
	for button in level.hud.power_buttons:
		if button.power == FREEZE:
			return button.get_global_rect()
	return Rect2()


func _visible_rect(control: Control) -> Rect2:
	return control.get_global_rect() if control.is_visible_in_tree() else Rect2()


func _get_target() -> Rect2:
	if current < 0 or current >= steps.size() or not steps[current].has("target"):
		return Rect2()
	return (steps[current].target as Callable).call()


# --- Bulle ------------------------------------------------------------------

func _build_ui() -> void:
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_draw_highlight)
	add_child(_overlay)
	bubble = PanelContainer.new()
	bubble.add_theme_stylebox_override(&"panel", UiStyle.panel(UiStyle.ACCENT, 14.0, SIDE_LEFT,
		Color(0.03, 0.06, 0.09, 0.96)))
	bubble.custom_minimum_size.x = BUBBLE_WIDTH
	add_child(bubble)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	bubble.add_child(column)
	_counter = Label.new()
	_counter.add_theme_font_size_override(&"font_size", 13)
	_counter.add_theme_color_override(&"font_color", UiStyle.ACCENT)
	column.add_child(_counter)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override(&"normal_font_size", 17)
	_text.add_theme_font_size_override(&"bold_font_size", 17)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_text)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 10)
	column.add_child(buttons)
	_skip_button = Button.new()
	_skip_button.text = tr("Passer le tutoriel")
	_skip_button.focus_mode = Control.FOCUS_NONE
	_skip_button.add_theme_font_size_override(&"font_size", 14)
	UiStyle.style_button(_skip_button, UiStyle.TEXT_DISABLED_COLOR, 12.0, 12.0)
	_skip_button.pressed.connect(skip)
	buttons.add_child(_skip_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)
	_next_button = Button.new()
	_next_button.text = tr("Suivant")
	_next_button.focus_mode = Control.FOCUS_NONE
	_next_button.custom_minimum_size.x = 110.0
	UiStyle.style_button(_next_button)
	_next_button.pressed.connect(next_step)
	buttons.add_child(_next_button)


func _show_step(step: Dictionary) -> void:
	_show_step_texts(step)
	_next_button.visible = step.get("next", false)
	bubble.visible = true
	bubble.reset_size()
	# La bulle apparaît en glissant un peu.
	bubble.modulate.a = 0.0
	var tween := bubble.create_tween().set_ignore_time_scale()
	tween.tween_property(bubble, "modulate:a", 1.0, 0.25)
	Sound.play(&"upgrade", -8.0)


func _show_step_texts(step: Dictionary) -> void:
	var touch := GameSettings.is_touch_mode() and step.has("touch_text")
	_text.text = step.touch_text if touch else step.text
	_counter.text = tr("TUTORIEL  ·  %d / %d") % [current + 1, steps.size()]


## Langue changée dans les Options (ouvertes en jeu) : les textes des étapes et de la
## bulle sont refaits dans la nouvelle langue.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and bubble != null:
		_build_steps()
		_skip_button.text = tr("Passer le tutoriel")
		_next_button.text = tr("Suivant")
		if current >= 0 and current < steps.size():
			_show_step_texts(steps[current])


func _process(delta: float) -> void:
	if level == null or level.is_over:
		return
	_time += delta / maxf(Engine.time_scale, 0.01)
	_update()
	# Derrière le menu Options et le choix des tours, la bulle s'efface.
	visible = level.hud.options_menu == null and level.hud.tower_picker == null
	if current < steps.size():
		_place_bubble()
	_overlay.queue_redraw()


## La bulle se met à côté de sa cible (au-dessus si la cible est en bas de l'écran, en
## dessous sinon), sans sortir de l'écran ; sans cible, en haut de la carte.
func _place_bubble() -> void:
	bubble.reset_size()
	var screen := level.get_viewport().get_visible_rect().size
	var size := bubble.size
	var area := level.hud.get_play_area()
	# La fiche d'une tour ouverte reste lisible : la bulle se place à côté d'elle aussi.
	var target := _target
	if target.has_area() and level.hud.tower_details.visible:
		target = target.merge(level.hud.tower_details.get_global_rect())
	var position: Vector2
	if not target.has_area():
		position = Vector2((screen.x - size.x) / 2.0, area.position.y + 24.0)
	else:
		var x := target.get_center().x - size.x / 2.0
		if target.get_center().y > screen.y / 2.0:
			position = Vector2(x, target.position.y - BUBBLE_GAP - size.y)
		else:
			position = Vector2(x, target.end.y + BUBBLE_GAP)
		# Une cible haute et large (la barre du haut) : la bulle reste sur la carte.
		position.y = maxf(position.y, area.position.y + 8.0)
	position.x = clampf(position.x, 16.0, screen.x - 16.0 - size.x)
	position.y = clampf(position.y, 8.0, screen.y - 8.0 - size.y)
	# La bulle ne doit pas cacher la cible : sinon, elle passe sur le côté.
	if target.has_area() and Rect2(position, size).intersects(target):
		position.x = target.end.x + BUBBLE_GAP if target.get_center().x < screen.x / 2.0 \
			else target.position.x - BUBBLE_GAP - size.x
		position.y = clampf(target.get_center().y - size.y / 2.0, 8.0, screen.y - 8.0 - size.y)
	bubble.position = position.round()


## Cadre clignotant autour de la cible, et un trait qui la relie à la bulle.
func _draw_highlight() -> void:
	if not _target.has_area() or not bubble.visible:
		return
	var pulse := 0.5 + 0.5 * sin(_time * 6.0)
	var rect := _target.grow(4.0 + 3.0 * pulse)
	var color := Color(UiStyle.FOCUS_COLOR, 0.55 + 0.45 * pulse)
	_overlay.draw_rect(rect, Color(UiStyle.FOCUS_COLOR, 0.08 * pulse))
	_overlay.draw_rect(rect, color, false, 3.0)
	var bubble_rect := bubble.get_global_rect()
	var from := Vector2(clampf(rect.get_center().x, bubble_rect.position.x + 12.0, bubble_rect.end.x - 12.0),
		clampf(rect.get_center().y, bubble_rect.position.y + 12.0, bubble_rect.end.y - 12.0))
	var to := Vector2(clampf(from.x, rect.position.x, rect.end.x), clampf(from.y, rect.position.y, rect.end.y))
	if from.distance_to(to) > 6.0:
		_overlay.draw_dashed_line(from, to, Color(UiStyle.FOCUS_COLOR, 0.7), 2.0, 6.0)
		_overlay.draw_circle(to, 4.0, UiStyle.FOCUS_COLOR)
