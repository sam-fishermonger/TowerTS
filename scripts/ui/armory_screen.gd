extends Control
## Armurerie (depuis l'écran titre) : l'équipement des tours (Equipment) et leur niveau
## (TowerLevels). À gauche les types de tour, au milieu le niveau et les emplacements de
## celui choisi puis les coffrets à ouvrir, à droite l'inventaire. Un clic sur un objet de
## l'inventaire le pose sur la tour choisie, un clic sur un emplacement (ou sur l'objet
## déjà posé) le retire. Les insignes à dépenser sont en haut à droite.

const TITLE_SCREEN := "res://scenes/ui/title_screen.tscn"
const TITLE_COLOR := Color(0.95, 0.85, 0.45)
const MUTED := Color(1, 1, 1, 0.6)
## Coffrets montrés au plus dans la rangée (les autres sont comptés).
const MAX_BOXES_SHOWN := 8
## Boutons de fusion, par rareté (Légendaire ne se fond pas).
const MERGE_TEXTS: Array[String] = ["Fondre 3 communs", "Fondre 3 rares", "Fondre 3 épiques"]
## Glissé (en pixels) avant qu'un doigt posé sur une liste la fasse défiler : en dessous,
## c'est un appui sur le bouton touché.
const SCROLL_DEADZONE := 16

## Type de tour choisi (chemin de sa TowerData).
var selected_tower := ""
## Boutons des types de tour, par chemin.
var tower_buttons := {}
## Boutons des emplacements de la tour choisie.
var slot_buttons: Array[Button] = []
## Boutons des objets de l'inventaire, par uid.
var item_buttons := {}
var open_button: Button
var merge_buttons: Array[Button] = []
var back_button: Button
## Insignes à dépenser, niveau de la tour choisie et bouton pour la monter d'un niveau.
var medal_label: Label
var level_label: Label
var level_bonus_label: Label
var level_button: Button
## Paliers de la tour choisie (un Label par palier).
var tier_labels: Array[Label] = []
var box_label: Label
var status_label: Label
var inventory_label: Label
## Dernier objet sorti d'un coffret, montré sous les coffrets (vide = aucun).
var last_opened: Dictionary = {}

var _tower_list: VBoxContainer
var _tower_header: HBoxContainer
var _slot_list: VBoxContainer
var _box_row: HBoxContainer
var _reveal: PanelContainer
var _inventory_grid: GridContainer


func _ready() -> void:
	_build()
	var towers := Equipment.get_towers()
	select_tower(towers[0] if not towers.is_empty() else "")
	Sound.play_music()
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()


## Vers l'écran titre, ou celui du mode joué quand l'Armurerie a été ouverte depuis
## l'écran de fin d'un niveau (Level.ARMORY_RETURN_META).
func go_back() -> void:
	var screen: String = Engine.get_meta(Level.ARMORY_RETURN_META, TITLE_SCREEN)
	if Engine.has_meta(Level.ARMORY_RETURN_META):
		Engine.remove_meta(Level.ARMORY_RETURN_META)
	get_tree().change_scene_to_file(screen)


## Choisit le type de tour dont on montre et change les emplacements.
func select_tower(tower_path: String) -> void:
	selected_tower = tower_path
	status_label.text = ""
	refresh()


## Clic sur un objet de l'inventaire : posé sur la tour choisie, ou retiré s'il y est déjà.
func toggle_item(uid: int) -> void:
	var item := Equipment.get_item(uid)
	if item.is_empty() or selected_tower.is_empty():
		return
	var tower_name := _tower_name(selected_tower)
	status_label.text = ""
	if Equipment.get_tower_of(uid) == selected_tower:
		Equipment.unequip(uid)
	elif not Equipment.get_reserved_tower(item).is_empty() and Equipment.get_reserved_tower(item) != selected_tower:
		status_label.text = tr("Cet objet est réservé à : %s.") % _tower_name(Equipment.get_reserved_tower(item))
	elif not Equipment.can_equip(item, selected_tower):
		status_label.text = tr("%s porte déjà un objet de cette sorte.") % tower_name
	elif Equipment.get_equipped_uids(selected_tower).size() >= Equipment.SLOTS:
		status_label.text = tr("Les emplacements de %s sont pleins : retirez d'abord un objet.") % tower_name
	else:
		Equipment.equip(uid, selected_tower)
		Sound.play(&"upgrade")
	refresh()


## Ouvre le premier coffret : l'objet obtenu est montré sous les coffrets.
func open_box() -> Dictionary:
	last_opened = Equipment.open_box()
	if not last_opened.is_empty():
		Sound.play(&"coins")
	status_label.text = ""
	refresh()
	if not last_opened.is_empty():
		# L'objet sorti du coffret apparaît dans un éclair de la couleur de sa rareté.
		_reveal.modulate = Equipment.rarity_color(last_opened.rarity) * 2.0
		_reveal.modulate.a = 0.0
		create_tween().tween_property(_reveal, ^"modulate", Color.WHITE, 0.4)
		UiMotion.pop(_reveal, 1.15, 0.45)
	return last_opened


## Monte la tour choisie d'un niveau en payant ses insignes.
func level_up() -> bool:
	if not TowerLevels.level_up(selected_tower):
		return false
	var level := TowerLevels.get_level(selected_tower)
	Sound.play(&"upgrade")
	status_label.text = tr("%s passe au niveau %d.") % [_tower_name(selected_tower), level]
	if level % TowerLevels.TIER_EVERY == 0:
		status_label.text = tr("%s passe au niveau %d : palier débloqué, %s !") % [_tower_name(selected_tower),
			level, TowerLevels.describe_tier(selected_tower, level / TowerLevels.TIER_EVERY - 1)]
	refresh()
	UiMotion.pop(level_label, 1.3, 0.4, Color(1.4, 1.6, 1.4))
	return true


## Fond trois objets libres de cette rareté en un coffret de la rareté au-dessus.
func merge(rarity: int) -> void:
	if Equipment.merge(rarity):
		status_label.text = tr("Trois objets fondus : un %s de plus à ouvrir.") \
			% Equipment.box_name(rarity + 1).to_lower()
	refresh()


func refresh() -> void:
	_refresh_medals()
	_refresh_towers()
	_refresh_slots()
	_refresh_boxes()
	_refresh_inventory()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh()


# --- Construction -------------------------------------------------------------

func _build() -> void:
	var title := _label("Armurerie", 40, TITLE_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.style_title(title)
	add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 16.0
	var subtitle := _label("L'équipement et le niveau d'un type de tour renforcent toutes ses tours, dans toutes les parties.",
		16, MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	subtitle.offset_top = 70.0
	medal_label = _label("", 24, TowerLevels.COLOR)
	medal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	medal_label.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(medal_label)
	medal_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	medal_label.offset_left = -320.0
	medal_label.offset_right = -24.0
	medal_label.offset_top = 24.0
	medal_label.offset_bottom = 56.0

	# Types de tour.
	var towers_panel := _panel(Rect2(24, 104, 280, 600), UiStyle.ACCENT)
	var towers_column := VBoxContainer.new()
	towers_panel.add_child(towers_column)
	towers_column.add_child(_label("Tours", 20, UiStyle.ACCENT))
	var towers_scroll := _scroll()
	towers_column.add_child(towers_scroll)
	_tower_list = VBoxContainer.new()
	_tower_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tower_list.add_theme_constant_override(&"separation", 4)
	towers_scroll.add_child(_tower_list)
	for path in Equipment.get_towers():
		var button := _row_button(52.0)
		button.name = path.get_file().get_basename()
		var row := button.get_child(0) as HBoxContainer
		var icon := TowerIcon.new()
		icon.data = load(path)
		icon.custom_minimum_size = Vector2(40, 40)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var name_label := _label("", 18, Color.WHITE)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(_label("", 16, MUTED))
		var tower_level_label := _label("", 16, MUTED)
		tower_level_label.custom_minimum_size.x = 52.0
		tower_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(tower_level_label)
		button.pressed.connect(select_tower.bind(path))
		_tower_list.add_child(button)
		tower_buttons[path] = button

	# Emplacements de la tour choisie.
	var slots_panel := _panel(Rect2(320, 104, 440, 404), Equipment.COLOR)
	_slot_list = VBoxContainer.new()
	_slot_list.add_theme_constant_override(&"separation", 6)
	slots_panel.add_child(_slot_list)
	_tower_header = HBoxContainer.new()
	_tower_header.add_theme_constant_override(&"separation", 12)
	_slot_list.add_child(_tower_header)
	# Niveau de la tour : niveau, bonus, bouton pour monter, puis les paliers.
	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override(&"separation", 10)
	_slot_list.add_child(level_row)
	var level_column := VBoxContainer.new()
	level_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_column.add_theme_constant_override(&"separation", 0)
	level_row.add_child(level_column)
	level_label = _label("", 18, TowerLevels.COLOR)
	level_column.add_child(level_label)
	level_bonus_label = _label("", 13, MUTED)
	level_column.add_child(level_bonus_label)
	level_button = Button.new()
	level_button.name = "LevelUpButton"
	level_button.custom_minimum_size = Vector2(150, 40)
	UiStyle.style_button(level_button, TowerLevels.COLOR, 10.0, 10.0)
	level_button.pressed.connect(level_up)
	level_row.add_child(level_button)
	var tier_list := VBoxContainer.new()
	tier_list.add_theme_constant_override(&"separation", 0)
	_slot_list.add_child(tier_list)
	for i in TowerLevels.MAX_LEVEL / TowerLevels.TIER_EVERY:
		var tier := _label("", 13, MUTED)
		tier.custom_minimum_size.y = 19.0
		tier.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tier.mouse_filter = Control.MOUSE_FILTER_PASS
		tier_list.add_child(tier)
		tier_labels.append(tier)
	for i in Equipment.SLOTS:
		var slot := _row_button(56.0)
		slot.pressed.connect(_on_slot_pressed.bind(i))
		_slot_list.add_child(slot)
		slot_buttons.append(slot)

	# Coffrets.
	var boxes_panel := _panel(Rect2(320, 516, 440, 208), Equipment.COLOR)
	var boxes_column := VBoxContainer.new()
	boxes_column.add_theme_constant_override(&"separation", 8)
	boxes_panel.add_child(boxes_column)
	var boxes_header := HBoxContainer.new()
	boxes_column.add_child(boxes_header)
	box_label = _label("", 20, Equipment.COLOR)
	box_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boxes_header.add_child(box_label)
	open_button = Button.new()
	open_button.text = "Ouvrir"
	open_button.custom_minimum_size = Vector2(120, 36)
	UiStyle.style_button(open_button, Equipment.COLOR)
	open_button.pressed.connect(open_box)
	boxes_header.add_child(open_button)
	_box_row = HBoxContainer.new()
	_box_row.custom_minimum_size.y = 36.0
	_box_row.add_theme_constant_override(&"separation", 6)
	boxes_column.add_child(_box_row)
	_reveal = PanelContainer.new()
	_reveal.custom_minimum_size.y = 52.0
	boxes_column.add_child(_reveal)
	var merge_row := HBoxContainer.new()
	merge_row.add_theme_constant_override(&"separation", 6)
	boxes_column.add_child(merge_row)
	for rarity in Equipment.LEGENDAIRE:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 34.0
		button.add_theme_font_size_override(&"font_size", 14)
		UiStyle.style_button(button, Equipment.rarity_color(rarity), 6.0, 6.0, false)
		button.pressed.connect(merge.bind(rarity))
		merge_row.add_child(button)
		merge_buttons.append(button)

	# Inventaire.
	var inventory_panel := _panel(Rect2(776, 104, 480, 600), UiStyle.ACCENT)
	var inventory_column := VBoxContainer.new()
	inventory_panel.add_child(inventory_column)
	inventory_label = _label("", 20, UiStyle.ACCENT)
	inventory_column.add_child(inventory_label)
	var inventory_scroll := _scroll()
	inventory_column.add_child(inventory_scroll)
	_inventory_grid = GridContainer.new()
	_inventory_grid.columns = 2
	_inventory_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inventory_grid.add_theme_constant_override(&"h_separation", 6)
	_inventory_grid.add_theme_constant_override(&"v_separation", 6)
	inventory_scroll.add_child(_inventory_grid)

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

	status_label = _label("", 18, Color(1.0, 0.75, 0.5))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)
	status_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status_label.offset_left = 220.0
	status_label.offset_right = -220.0
	status_label.offset_top = -58.0
	status_label.offset_bottom = -26.0


# --- Mise à jour --------------------------------------------------------------

func _refresh_towers() -> void:
	for path: String in tower_buttons:
		var button: Button = tower_buttons[path]
		var row := button.get_child(0) as HBoxContainer
		(row.get_child(1) as Label).text = _tower_name(path)
		var count := Equipment.get_equipped_uids(path).size()
		var count_label := row.get_child(2) as Label
		count_label.text = "%d / %d" % [count, Equipment.SLOTS]
		count_label.add_theme_color_override(&"font_color", Equipment.COLOR if count > 0 else MUTED)
		var level := TowerLevels.get_level(path)
		var tower_level_label := row.get_child(3) as Label
		tower_level_label.text = tr("Niv. %d") % level
		tower_level_label.add_theme_color_override(&"font_color", TowerLevels.COLOR if level > 0 else MUTED)
		var accent: Color = (load(path) as TowerData).color.lightened(0.2)
		UiStyle.style_button(button, accent if path == selected_tower else Color(accent, 0.35), 8.0, 8.0, false)
		if path == selected_tower:
			var styles := UiStyle.button_styles(accent, 8.0, 8.0, false)
			(styles.normal as StyleBoxFlat).bg_color = Color(accent, 0.22)
			UiStyle.apply_styles(button, styles)


func _refresh_slots() -> void:
	for child in _tower_header.get_children():
		_tower_header.remove_child(child)
		child.queue_free()
	if selected_tower.is_empty():
		return
	var data: TowerData = load(selected_tower)
	var icon := TowerIcon.new()
	icon.data = data
	icon.custom_minimum_size = Vector2(56, 56)
	_tower_header.add_child(icon)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_tower_header.add_child(column)
	column.add_child(_label(_tower_name(selected_tower), 24, data.color.lightened(0.3)))
	_refresh_level()
	var base := data.get_stats_at_level(1)
	column.add_child(_label(tr("Tour posée : %s dégâts, %s tirs/s, portée %s") % [TowerInfoPanel._format(base.damage),
		TowerInfoPanel._format(base.fire_rate, 2), TowerInfoPanel._format(base.attack_range)], 14, MUTED))
	var items := Equipment.get_equipped(selected_tower)
	for i in slot_buttons.size():
		var slot := slot_buttons[i]
		var row := slot.get_child(0) as HBoxContainer
		for child in row.get_children():
			row.remove_child(child)
			child.queue_free()
		if i < items.size():
			_fill_item_row(row, items[i], "", true, false)
			slot.tooltip_text = tr("Cliquer pour retirer l'objet.")
			UiStyle.style_button(slot, Equipment.rarity_color(items[i].rarity), 8.0, 8.0, false)
		else:
			var empty := _label("Emplacement libre : choisissez un objet dans l'inventaire.", 16, MUTED)
			empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(empty)
			slot.tooltip_text = ""
			UiStyle.style_button(slot, Color(UiStyle.ACCENT, 0.3), 8.0, 8.0, false)


func _refresh_medals() -> void:
	medal_label.text = tr("Insignes : %s") % TowerLevels.medal_text(TowerLevels.get_medals())
	medal_label.tooltip_text = tr("Gagnés à chaque victoire (plus en difficulté haute et vers la fin d'un monde), et beaucoup à la première victoire du jour au défi du jour. Ils font monter le niveau des tours.") \
		+ "\n" + tr("Gagnés en tout : %d") % TowerLevels.get_earned()


## Niveau de la tour choisie, son bonus, le prix du suivant et ses paliers.
func _refresh_level() -> void:
	var level := TowerLevels.get_level(selected_tower)
	var cost := TowerLevels.get_cost(selected_tower)
	level_label.text = tr("Niveau %d / %d") % [level, TowerLevels.MAX_LEVEL]
	level_bonus_label.text = tr("Chaque niveau : +1 % dégâts, +0,5 % portée") if level == 0 \
		else tr("Bonus des niveaux : %s") % TowerLevels.describe_level_bonus(level)
	if cost < 0:
		level_button.text = tr("Niveau max")
		level_button.disabled = true
		level_button.tooltip_text = ""
	else:
		level_button.text = tr("Monter  ·  %s") % TowerLevels.medal_text(cost)
		level_button.disabled = not TowerLevels.can_level_up(selected_tower)
		level_button.tooltip_text = tr("Il manque %s.") % TowerLevels.medal_text(cost - TowerLevels.get_medals()) \
			if level_button.disabled else tr("Passer au niveau %d.") % (level + 1)
	var unlocked := TowerLevels.get_unlocked_tier_count(level)
	for i in tier_labels.size():
		var tier := tier_labels[i]
		var effect := TowerLevels.describe_tier(selected_tower, i)
		tier.text = ("● " if i < unlocked else "○ ") + tr("Niv. %d") % TowerLevels.tier_level(i) + "  ·  " + effect
		tier.tooltip_text = tr("Palier du niveau %d : %s") % [TowerLevels.tier_level(i), effect]
		tier.add_theme_color_override(&"font_color", TowerLevels.COLOR if i < unlocked else MUTED)
		tier.visible = not effect.is_empty()


func _refresh_boxes() -> void:
	var boxes := Equipment.get_boxes()
	box_label.text = tr("Coffrets à ouvrir : %d") % boxes.size()
	open_button.disabled = boxes.is_empty()
	for child in _box_row.get_children():
		_box_row.remove_child(child)
		child.queue_free()
	for i in mini(boxes.size(), MAX_BOXES_SHOWN):
		var box := EquipmentIcon.new()
		box.icon = "box"
		box.rarity = boxes[i]
		box.custom_minimum_size = Vector2(40, 40)
		box.tooltip_text = Equipment.box_name(boxes[i])
		box.mouse_filter = Control.MOUSE_FILTER_PASS
		_box_row.add_child(box)
	if boxes.size() > MAX_BOXES_SHOWN:
		_box_row.add_child(_label("+%d" % (boxes.size() - MAX_BOXES_SHOWN), 18, MUTED))
	if boxes.is_empty():
		_box_row.add_child(_label("Finissez des niveaux pour en gagner : plus la difficulté est haute, plus ils sont rares.",
			14, MUTED))
		(_box_row.get_child(0) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(_box_row.get_child(0) as Label).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for child in _reveal.get_children():
		_reveal.remove_child(child)
		child.queue_free()
	_reveal.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	if not last_opened.is_empty() and not Equipment.get_item(last_opened.uid).is_empty():
		_reveal.add_theme_stylebox_override(&"panel", UiStyle.panel(Equipment.rarity_color(last_opened.rarity), 8.0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 10)
		_reveal.add_child(row)
		_fill_item_row(row, last_opened, tr("Obtenu : "))
	for rarity in merge_buttons.size():
		var button := merge_buttons[rarity]
		button.text = tr(MERGE_TEXTS[rarity])
		button.disabled = not Equipment.can_merge(rarity)
		button.tooltip_text = tr("Fond les trois plus anciens objets libres de cette rareté en un %s (%d libres).") \
			% [Equipment.box_name(rarity + 1).to_lower(), Equipment.get_free_items(rarity).size()]


func _refresh_inventory() -> void:
	for child in _inventory_grid.get_children():
		_inventory_grid.remove_child(child)
		child.queue_free()
	item_buttons.clear()
	var items := Equipment.get_items()
	inventory_label.text = tr("Inventaire : %d") % items.size()
	# Les meilleurs d'abord, puis par sorte.
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.rarity != b.rarity:
			return a.rarity > b.rarity
		if a.kind != b.kind:
			return a.kind < b.kind
		return a.uid < b.uid)
	for item in items:
		var button := _row_button(92.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := button.get_child(0) as HBoxContainer
		_fill_item_row(row, item, "", true)
		var on_selected := Equipment.get_tower_of(item.uid) == selected_tower
		var usable := on_selected or Equipment.can_equip(item, selected_tower)
		var accent := Equipment.rarity_color(item.rarity)
		UiStyle.style_button(button, accent if usable else Color(accent, 0.3), 6.0, 6.0, false)
		if on_selected:
			var styles := UiStyle.button_styles(accent, 6.0, 6.0, false)
			(styles.normal as StyleBoxFlat).bg_color = Color(accent, 0.25)
			UiStyle.apply_styles(button, styles)
		button.modulate.a = 1.0 if usable else 0.5
		button.tooltip_text = tr("Cliquer pour le retirer.") if on_selected else tr("Cliquer pour le poser sur : %s.") \
			% _tower_name(selected_tower)
		button.pressed.connect(toggle_item.bind(item.uid))
		_inventory_grid.add_child(button)
		item_buttons[item.uid] = button
	if items.is_empty():
		var empty := _label("Aucun objet pour l'instant. Ouvrez des coffrets pour en trouver.", 16, MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size.x = 440.0
		_inventory_grid.add_child(empty)


## Ligne d'un objet : badge, nom (couleur de sa rareté), rareté et tour réservée ou
## portant l'objet, effets. `compact` : texte plus petit (inventaire, emplacements).
## `show_worn` : dit sur quelle tour l'objet est posé (inventaire).
func _fill_item_row(row: HBoxContainer, item: Dictionary, prefix := "", compact := false, show_worn := compact) -> void:
	var definition := Equipment.get_definition(item.kind)
	var badge := EquipmentIcon.new()
	badge.icon = definition.get("icon", "box")
	badge.rarity = item.rarity
	badge.custom_minimum_size = Vector2(40, 40) if compact else Vector2(48, 48)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(badge)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	var color := Equipment.rarity_color(item.rarity)
	var title := _label(prefix + Equipment.item_name(item), 15 if compact else 18, color.lightened(0.15))
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(title)
	var info := Equipment.rarity_name(item.rarity)
	var reserved := Equipment.get_reserved_tower(item)
	if not reserved.is_empty():
		info += "  ·  " + tr("Réservé : %s") % _tower_name(reserved)
	var worn := Equipment.get_tower_of(item.uid)
	if show_worn and not worn.is_empty():
		info += "  ·  " + tr("Sur : %s") % _tower_name(worn)
	var info_label := _label(info, 12 if compact else 13, Color(color, 0.85))
	info_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(info_label)
	for line in Equipment.describe_item(item):
		var effect := _label(line, 12 if compact else 14, Color(0.8, 0.95, 0.8))
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(effect)


func _on_slot_pressed(index: int) -> void:
	var uids := Equipment.get_equipped_uids(selected_tower)
	if index < uids.size():
		Equipment.unequip(uids[index])
		status_label.text = ""
		refresh()
	elif not item_buttons.is_empty():
		item_buttons.values()[0].grab_focus()


# --- Outils -------------------------------------------------------------------

func _tower_name(path: String) -> String:
	return tr((load(path) as TowerData).display_name) if ResourceLoader.exists(path) else path


func _panel(rect: Rect2, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", UiStyle.panel(Color(accent, 0.6), 12.0))
	panel.position = rect.position
	panel.size = rect.size
	panel.custom_minimum_size = rect.size
	add_child(panel)
	return panel


## Liste verticale qui défile à la molette et, sur écran tactile, au doigt.
func _scroll() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_deadzone = SCROLL_DEADZONE
	return scroll


## Bouton qui contient une rangée (badge, textes…) à remplir. Il laisse passer l'appui à
## la liste qui le contient (MOUSE_FILTER_PASS) : sans ça, un doigt posé sur un bouton ne
## fait pas défiler la liste. Le bouton reste pressé par un simple appui, et un glissé
## qui fait défiler la liste annule l'appui (NOTIFICATION_SCROLL_BEGIN).
func _row_button(height: float) -> Button:
	var button := Button.new()
	button.custom_minimum_size.y = height
	button.clip_contents = true
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10.0
	row.offset_right = -10.0
	row.offset_top = 4.0
	row.offset_bottom = -4.0
	return button


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
