class_name EndStats
extends VBoxContainer
## Statistiques de fin de niveau, à droite de l'écran de fin : bilan de la partie (durée,
## monstres détruits, or dépensé et gagné…), meilleure tour, dégâts de chaque type de
## tour posé, et succès débloqués pendant la partie.

const TITLE_COLOR := Color(0.95, 0.85, 0.45)
const MUTED := Color(1, 1, 1, 0.6)
const GOLD_COLOR := Color(1.0, 0.82, 0.25)
const BAR_WIDTH := 150.0
const BAR_HEIGHT := 12.0
const ICON_SIZE := 26.0

## Bilan chiffré (libellé -> valeur), dans l'ordre d'affichage.
var summary := {}
## Lignes du tableau des dégâts, une par type de tour (du plus de dégâts au moins).
var type_rows: Array[LevelStats.TypeRecord] = []
var best_label: Label
var achievements_label: Label


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	custom_minimum_size.x = 420.0


## Remplit le panneau avec les statistiques d'une partie et les succès débloqués.
func setup(stats: LevelStats, achievement_ids: Array[String] = []) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_add_title("Statistiques")
	var total_damage := stats.get_total_damage()
	var kills := LevelStats.format_number(stats.kills)
	if stats.elite_kills > 0 or stats.boss_kills > 0:
		var details: Array[String] = []
		if stats.elite_kills > 0:
			details.append("%d élite%s" % [stats.elite_kills, "s" if stats.elite_kills > 1 else ""])
		if stats.boss_kills > 0:
			details.append("%d boss" % stats.boss_kills)
		kills += " (%s)" % ", ".join(details)
	summary = {
		"Durée": LevelStats.format_duration(stats.duration),
		"Monstres détruits": kills,
		"Dégâts infligés": LevelStats.format_number(total_damage),
		"Vies perdues": str(stats.lives_lost),
		"Or dépensé": LevelStats.format_number(stats.gold_spent),
		"Or gagné": LevelStats.format_number(stats.gold_earned),
		"Tours posées": str(stats.towers_built),
		"Améliorations": str(stats.upgrades_bought),
	}
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override(&"h_separation", 12)
	grid.add_theme_constant_override(&"v_separation", 2)
	add_child(grid)
	for key: String in summary:
		grid.add_child(_label(key, 15, MUTED))
		var value := _label(summary[key], 15, GOLD_COLOR if key.begins_with("Or") else Color.WHITE)
		value.custom_minimum_size.x = 92.0
		grid.add_child(value)

	var best := stats.get_best_tower()
	_add_title("Meilleure tour")
	var best_row := HBoxContainer.new()
	best_row.add_theme_constant_override(&"separation", 8)
	add_child(best_row)
	if best:
		best_row.add_child(_icon(best.data))
		best_label = _label("%s  niv. %d%s" % [best.data.display_name, best.level, "  (vendue)" if best.sold else ""],
			16, best.data.color.lightened(0.35))
		best_row.add_child(best_label)
		best_row.add_child(_label("%s dégâts · %d destruction%s" % [LevelStats.format_number(best.damage),
			best.kills, "s" if best.kills > 1 else ""], 15, MUTED))
	else:
		best_label = _label("Aucune tour n'a infligé de dégâts.", 15, MUTED)
		best_row.add_child(best_label)

	type_rows = stats.get_types()
	if not type_rows.is_empty():
		_add_title("Dégâts par tour")
		var table := GridContainer.new()
		table.columns = 4
		table.add_theme_constant_override(&"h_separation", 10)
		table.add_theme_constant_override(&"v_separation", 4)
		add_child(table)
		var top := maxf(type_rows[0].damage, 1.0)
		for row in type_rows:
			var name_box := HBoxContainer.new()
			name_box.add_theme_constant_override(&"separation", 6)
			name_box.add_child(_icon(row.data))
			var label := _label(row.data.display_name, 15, row.data.color.lightened(0.35))
			label.custom_minimum_size.x = 110.0
			name_box.add_child(label)
			name_box.add_child(_label("x%d" % row.count, 13, MUTED))
			table.add_child(name_box)
			table.add_child(_bar(row.damage / top, row.data.color))
			var damage := _label(LevelStats.format_number(row.damage), 15, Color.WHITE)
			damage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			damage.custom_minimum_size.x = 64.0
			table.add_child(damage)
			table.add_child(_label("%d %%" % roundi(100.0 * row.damage / total_damage) if total_damage > 0.0 else "-",
				13, MUTED))

	if not achievement_ids.is_empty():
		_add_title("Succès débloqué%s" % ("s" if achievement_ids.size() > 1 else ""), Achievements.COLOR)
		var names: Array[String] = []
		for id in achievement_ids:
			var definition := Achievements.get_definition(id)
			# Espaces insécables : un succès ne se coupe pas en fin de ligne.
			names.append(("%s %s" % [definition.icon, definition.name]).replace(" ", "\u00a0"))
		achievements_label = _label("   ".join(names), 15, Achievements.COLOR)
		achievements_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		achievements_label.custom_minimum_size.x = 420.0
		add_child(achievements_label)


func _add_title(text: String, color := TITLE_COLOR) -> void:
	var label := _label(text, 19, color)
	if get_child_count() > 0:
		# Un peu d'air au-dessus de chaque section, sauf la première.
		var spacer := Control.new()
		spacer.custom_minimum_size.y = 2.0
		add_child(spacer)
	add_child(label)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func _icon(data: TowerData) -> TowerIcon:
	var icon := TowerIcon.new()
	icon.data = data
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	return icon


## Barre de dégâts : sa longueur est la part de la tour qui en a fait le plus.
func _bar(ratio: float, color: Color) -> Control:
	var back := ColorRect.new()
	back.color = Color(1, 1, 1, 0.08)
	back.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := ColorRect.new()
	fill.color = color.lightened(0.15)
	fill.size = Vector2(maxf(BAR_WIDTH * clampf(ratio, 0.0, 1.0), 2.0), BAR_HEIGHT)
	back.add_child(fill)
	return back
