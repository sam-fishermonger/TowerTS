extends Control
## Lexique (depuis l'écran titre) : la fiche de chaque tour, de chaque monstre (élites et
## boss compris) et de chaque monde. Trois onglets, une liste à gauche, la fiche à droite.
## Tout est lu dans les ressources du jeu (tours de resources/towers/, mondes et monstres
## de la campagne, arbre des améliorations) : une tour ou un monstre ajouté y apparaît
## sans rien changer ici.

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"
const TOWERS_DIR := "res://resources/towers/"
const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")
const TITLE_COLOR := Color(0.95, 0.85, 0.45)
const MUTED := "#ffffff99"
const STAR_HEX := "#f2d973"

enum Tab { TOWERS, ENEMIES, WORLDS }
const TAB_NAMES: Array[String] = ["Tours", "Monstres", "Mondes"]

## Onglet affiché.
var current_tab := Tab.TOWERS

var _tab_group := ButtonGroup.new()
var _entry_group := ButtonGroup.new()
var _tab_buttons: Array[Button] = []
## Liste des entrées de l'onglet, à gauche.
var entries: VBoxContainer
## Fiche de l'entrée choisie, à droite.
var detail_title: RichTextLabel
var detail_text: RichTextLabel
var _detail_icon: TextureRect
var _detail_tower_icon: TowerIcon
var _detail_style: StyleBoxFlat
var back_button: Button


func _ready() -> void:
	_build()
	show_tab(Tab.TOWERS)
	Sound.play_music()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()


func go_back() -> void:
	get_tree().change_scene_to_file(TITLE_SCREEN)


## Tous les types de tour du jeu : ceux du début, du moins cher au plus cher, puis les
## tours des mondes, dans l'ordre de l'arbre des améliorations.
static func get_all_towers() -> Array[TowerData]:
	var unlockable: Array[String] = []
	for perk in Perks.TREE.perks:
		if not perk.unlocks_tower.is_empty():
			unlockable.append(perk.unlocks_tower)
	var base: Array[TowerData] = []
	for file in ResourceLoader.list_directory(TOWERS_DIR):
		var path := TOWERS_DIR + file
		if file.ends_with(".tres") and not unlockable.has(path):
			var data := load(path) as TowerData
			if data:
				base.append(data)
	base.sort_custom(func(a: TowerData, b: TowerData) -> bool:
		return a.cost < b.cost or (a.cost == b.cost and a.display_name < b.display_name))
	for path in unlockable:
		base.append(load(path))
	return base


## Affiche un onglet et sa première entrée.
func show_tab(tab: Tab) -> void:
	current_tab = tab
	_tab_buttons[tab].set_pressed_no_signal(true)
	for child in entries.get_children():
		entries.remove_child(child)
		child.queue_free()
	match tab:
		Tab.TOWERS:
			for data in get_all_towers():
				_add_entry(data.display_name, data.color.lightened(0.3), null, data, show_tower.bind(data))
		Tab.ENEMIES:
			_add_entry("Élites", EnemyData.ELITE_COLOR, null, null, show_elites)
			for world in CAMPAIGN.worlds:
				_add_header(world.display_name, world.color)
				for enemy in world.enemies:
					_add_entry(enemy.display_name, enemy.color.lightened(0.35), enemy.texture, null,
						show_enemy.bind(enemy, world))
				for boss in world.bosses:
					_add_entry("%s  ·  boss" % boss.display_name, EnemyData.BOSS_COLOR, boss.texture, null,
						show_enemy.bind(boss, world))
		Tab.WORLDS:
			for i in CAMPAIGN.worlds.size():
				var world := CAMPAIGN.worlds[i]
				_add_entry("%d. %s" % [i + 1, world.display_name], world.color,
					world.enemies[0].texture if not world.enemies.is_empty() else null, null, show_world.bind(i))
	var first := get_entry_buttons()
	if not first.is_empty():
		first[0].button_pressed = true
		first[0].pressed.emit()


## Boutons des entrées de l'onglet affiché.
func get_entry_buttons() -> Array[Button]:
	var result: Array[Button] = []
	for child in entries.get_children():
		if child is Button:
			result.append(child)
	return result


# --- Fiches ---------------------------------------------------------------------

func show_tower(data: TowerData) -> void:
	_set_detail_header(data.display_name, data.color, null, data)
	var lines: Array[String] = []
	if not data.description.is_empty():
		lines.append(data.description)
		lines.append("")
	lines.append(_line("Prix", "%d or" % data.cost))
	lines.append(_line("Dégâts", _num(data.damage)))
	lines.append(_line("Cadence", "%s tirs/s" % _num(data.fire_rate, 2)))
	lines.append(_line("Dégâts/s", _num(data.get_dps())))
	lines.append(_line("Portée", _num(data.attack_range)))
	if data.splash_radius > 0.0:
		lines.append(_line("Explosion", "rayon %s" % _num(data.splash_radius)))
	if data.slow_factor < 1.0:
		lines.append(_line("Ralentit", "-%d %% pendant %s s" % [roundi((1.0 - data.slow_factor) * 100.0),
			_num(data.slow_duration)]))
	if data.beam_ramp_max > 1.0:
		lines.append(_line("Montée", "jusqu'à x%s en %s s" % [_num(data.beam_ramp_max), _num(data.beam_ramp_time)]))
	if data.dot_damage > 0.0:
		lines.append(_line("Poison" if data.cloud_radius > 0.0 else "Brûlure",
			"%s/s pendant %s s, sous l'armure" % [_num(data.dot_damage), _num(data.dot_duration)]))
	if data.cloud_radius > 0.0:
		lines.append(_line("Nuage", "rayon %s, %s s" % [_num(data.cloud_radius), _num(data.cloud_duration)]))
	if data.armor_piercing:
		lines.append(_line("Armure", "ignorée"))
	if data.shield_damage_multiplier != 1.0:
		lines.append(_line("Boucliers", "x%s dégâts" % _num(data.shield_damage_multiplier)))
	if data.shield_jam_duration > 0.0:
		lines.append(_line("Brouillage", "%s s sans recharge du bouclier" % _num(data.shield_jam_duration)))
	if data.heal_block_duration > 0.0:
		lines.append(_line("Anti-soin", "%s s" % _num(data.heal_block_duration)))
	if data.prefers_healers:
		lines.append(_line("Cible", "les soigneurs en premier"))
	if not data.upgrades.is_empty():
		lines.append("")
		lines.append("[b]Améliorations[/b]")
		for i in data.upgrades.size():
			lines.append("Niveau %d  [color=%s](%d or)[/color] : %s" % [i + 2, EnemyInfo.GOLD_HEX, data.upgrades[i].cost,
				_describe_upgrade(data.upgrades[i])])
	for perk in Perks.TREE.perks:
		if perk.unlocks_tower == data.resource_path:
			lines.append("")
			var world_name := Perks.get_required_world_name(perk)
			lines.append("[color=%s]Tour des mondes : à débloquer dans l'arbre des améliorations (%s, ★ %d).[/color]"
				% [STAR_HEX, world_name if not world_name.is_empty() else "Tours des mondes", perk.cost])
		elif perk.specializes_tower == data.resource_path:
			lines.append("")
			lines.append("[color=#73d9ff]Spécialisation « %s » (∞ %d) : %s[/color]" % [perk.display_name, perk.cost,
				perk.description])
	detail_text.text = "\n".join(lines)


func show_enemy(data: EnemyData, world: World) -> void:
	_set_detail_header(data.display_name, EnemyData.BOSS_COLOR if data.is_boss else data.color.lightened(0.2),
		data.texture, null)
	if data.is_boss:
		detail_title.text += "  " + EnemyInfo.rank_tag(data)
	var lines: Array[String] = []
	lines.append("[color=#%s]%s[/color]" % [world.color.to_html(false), world.display_name])
	if not data.description.is_empty():
		lines.append(data.description)
	lines.append("")
	lines.append(EnemyInfo.stats(data))
	if data.is_boss:
		lines.append("")
		lines.append("[color=%s]La difficulté change sa vie, mais il n'arrive jamais qu'un boss à la fois.[/color]" % MUTED)
	elif not data.split_into or data.split_count == 0:
		var elite := data.make_elite()
		lines.append("")
		lines.append("[color=%s]En élite : vie %d, +%d or, -%d vies.[/color]" % [EnemyInfo.ELITE_HEX,
			roundi(elite.max_health), elite.reward, elite.damage])
	else:
		var elite := data.make_elite()
		lines.append("")
		lines.append("[color=%s]En élite : vie %d, +%d or, -%d vies (ceux qu'il libère restent normaux).[/color]"
			% [EnemyInfo.ELITE_HEX, roundi(elite.max_health), elite.reward, elite.damage])
	detail_text.text = "\n".join(lines)


func show_elites() -> void:
	_set_detail_header("Élites", EnemyData.ELITE_COLOR, null, null)
	detail_text.text = "\n".join([
		"N'importe quel monstre peut arriver en élite : il est entouré d'une aura dorée, et son nom porte « élite ».",
		"Chaque niveau en a quelques-uns, annoncés dans l'aperçu de la vague.",
		"",
		_line("Vie et bouclier", "x%s" % _num(EnemyData.ELITE_HEALTH)),
		_line("Taille", "+%d %%" % roundi((EnemyData.ELITE_SIZE - 1.0) * 100.0)),
		_line("Or", "x%d" % roundi(EnemyData.ELITE_REWARD)),
		_line("Vies", "%d de plus s'il atteint la base" % EnemyData.ELITE_DAMAGE),
		"",
		"[b]Boss[/b]",
		"Un boss par monde, à la dernière vague des niveaux 3 et 6 (plus coriace au 6). Une aura rouge l'entoure, "
			+ "sa vie s'affiche en haut de l'écran, et il appelle des renforts en marchant.",
	])


func show_world(index: int) -> void:
	var world := CAMPAIGN.worlds[index]
	_set_detail_header(world.display_name, world.color, null, null)
	var lines: Array[String] = []
	lines.append("[color=%s]Monde %d  ·  %d niveaux[/color]" % [MUTED, index + 1, world.levels.size()])
	lines.append(world.description)
	if not Progress.is_world_unlocked(CAMPAIGN, index):
		lines.append("[color=%s]Verrouillé : gagner le dernier niveau de %s pour l'ouvrir.[/color]"
			% [MUTED, CAMPAIGN.worlds[index - 1].display_name])
	lines.append("")
	lines.append("[b]Monstres[/b]")
	for enemy in world.enemies:
		lines.append("%s  %s" % [EnemyInfo.icon(enemy, 28), EnemyInfo.title(enemy)])
	for boss in world.bosses:
		lines.append("%s  %s" % [EnemyInfo.icon(boss, 36), EnemyInfo.title(boss)])
	var towers: Array[String] = []
	for perk in Perks.TREE.perks:
		if perk.required_world == index and not perk.unlocks_tower.is_empty():
			towers.append("%s (★ %d)" % [perk.get_unlocked_tower().display_name, perk.cost])
	if not towers.is_empty():
		lines.append("")
		lines.append("[b]Tours du monde[/b]")
		lines.append(", ".join(towers) + " : à débloquer dans l'arbre des améliorations.")
	lines.append("")
	lines.append(_line("Étoiles", "★ %d / %d (4 difficultés)" % [Progress.get_world_stars(world),
		world.levels.size() * Progress.MAX_LEVEL_STARS]))
	detail_text.text = "\n".join(lines)


func _describe_upgrade(upgrade: TowerUpgrade) -> String:
	var parts: Array[String] = []
	for item in [[upgrade.damage_multiplier, "dégâts"], [upgrade.range_multiplier, "portée"],
			[upgrade.fire_rate_multiplier, "cadence"], [upgrade.splash_radius_multiplier, "explosion"],
			[upgrade.cloud_radius_multiplier, "nuage"]]:
		var percent := roundi((item[0] - 1.0) * 100.0)
		if percent != 0:
			parts.append("%+d %% %s" % [percent, item[1]])
	if upgrade.slow_duration_bonus > 0.0:
		parts.append("+%s s de ralentissement" % _num(upgrade.slow_duration_bonus))
	return ", ".join(parts) if not parts.is_empty() else "-"


func _line(stat_name: String, value: String) -> String:
	return "[color=%s]%s :[/color]  %s" % [MUTED, stat_name, value]


static func _num(value: float, decimals := 1) -> String:
	var text := String.num(value, decimals)
	return text.rstrip("0").trim_suffix(".") if text.contains(".") else text


# --- Construction de l'écran ---------------------------------------------------

func _build() -> void:
	var title := Label.new()
	title.text = "Lexique"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 40)
	title.add_theme_color_override(&"font_color", TITLE_COLOR)
	title.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override(&"shadow_offset_x", 3)
	title.add_theme_constant_override(&"shadow_offset_y", 3)
	add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 20.0

	var tabs := HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override(&"separation", 12)
	add_child(tabs)
	tabs.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tabs.offset_top = 80.0
	tabs.offset_bottom = 120.0
	for i in TAB_NAMES.size():
		var button := Button.new()
		button.text = TAB_NAMES[i]
		button.toggle_mode = true
		button.button_group = _tab_group
		button.custom_minimum_size = Vector2(150, 40)
		button.add_theme_font_size_override(&"font_size", 20)
		button.pressed.connect(show_tab.bind(i))
		tabs.add_child(button)
		_tab_buttons.append(button)

	var body := HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 20)
	add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 24.0
	body.offset_right = -24.0
	body.offset_top = 136.0
	body.offset_bottom = -84.0

	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size.x = 330.0
	list_panel.add_theme_stylebox_override(&"panel", _panel_style(Color(1, 1, 1, 0.15)))
	body.add_child(list_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(scroll)
	entries = VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override(&"separation", 4)
	scroll.add_child(entries)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_style = _panel_style(Color(0.5, 0.5, 0.5))
	_detail_style.border_width_top = 6
	detail_panel.add_theme_stylebox_override(&"panel", _detail_style)
	body.add_child(detail_panel)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_panel.add_child(detail_scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 10)
	detail_scroll.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 16)
	column.add_child(header)
	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = Vector2(88, 88)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(_detail_icon)
	_detail_tower_icon = TowerIcon.new()
	_detail_tower_icon.custom_minimum_size = Vector2(88, 88)
	header.add_child(_detail_tower_icon)
	detail_title = RichTextLabel.new()
	detail_title.bbcode_enabled = true
	detail_title.fit_content = true
	detail_title.scroll_active = false
	detail_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	detail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	detail_title.add_theme_font_size_override(&"normal_font_size", 34)
	detail_title.add_theme_font_size_override(&"bold_font_size", 18)
	header.add_child(detail_title)
	detail_text = RichTextLabel.new()
	detail_text.bbcode_enabled = true
	detail_text.fit_content = true
	detail_text.scroll_active = false
	detail_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_text.add_theme_font_size_override(&"normal_font_size", 17)
	detail_text.add_theme_font_size_override(&"bold_font_size", 18)
	detail_text.add_theme_constant_override(&"line_separation", 4)
	column.add_child(detail_text)

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


func _panel_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.09, 0.08, 0.92)
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	return style


func _add_header(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", 16)
	label.add_theme_color_override(&"font_color", color)
	entries.add_child(label)


func _add_entry(text: String, color: Color, texture: Texture2D, tower: TowerData, on_pressed: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_group = _entry_group
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override(&"font_size", 17)
	for color_name in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color",
			&"font_focus_color"]:
		button.add_theme_color_override(color_name, color)
	if texture:
		button.icon = texture
		button.expand_icon = true
		button.add_theme_constant_override(&"icon_max_width", 32)
	elif tower:
		# Une tour n'a pas d'image toute faite : son icône est dessinée par-dessus le bouton.
		button.text = "        " + text
		var icon := TowerIcon.new()
		icon.data = tower
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.position = Vector2(8, 6)
		icon.size = Vector2(32, 32)
		button.add_child(icon)
	button.pressed.connect(on_pressed)
	entries.add_child(button)


func _set_detail_header(text: String, color: Color, texture: Texture2D, tower: TowerData) -> void:
	_detail_style.border_color = color
	_detail_icon.texture = texture
	_detail_icon.visible = texture != null
	_detail_tower_icon.data = tower
	_detail_tower_icon.visible = tower != null
	detail_title.text = "[color=#%s]%s[/color]" % [color.to_html(false), text]
