class_name TowerInfoPanel
extends PanelContainer
## Fiche détaillée d'une tour. Deux usages :
## - aperçu d'un type de tour (survol de la barre d'achat) : statistiques et prix ;
## - tour posée sur la carte : niveau, gains de la prochaine amélioration,
##   choix de la cible, boutons Améliorer, Vendre et fermeture.

signal upgrade_requested(tower: Tower)
signal sell_requested(tower: Tower)
signal close_requested

## Écart entre la fiche et ce qu'elle décrit, et marge avec les bords de l'écran.
const GAP := 8.0
const BONUS_COLOR := Color(0.55, 0.95, 0.55)
const MUTED_COLOR := Color(1, 1, 1, 0.6)
const PRICE_COLOR := Color(1, 0.85, 0.3)
const TOO_EXPENSIVE_COLOR := Color(1, 0.45, 0.45)

## Zone de l'écran où la fiche doit rester (vide = tout l'écran) : le HUD y met la
## carte, entre ses barres du haut et du bas.
var bounds := Rect2()
## Type de tour affiché.
var data: TowerData
## Tour posée affichée, ou null en mode aperçu.
var tower: Tower

var _gold := 0
## Zone de l'écran que la fiche décrit (bouton ou tour).
var _anchor_rect := Rect2()
## true : à côté de la zone (tour posée) ; false : au-dessus ou en dessous (bouton).
var _beside := false

@onready var name_label: Label = %NameLabel
@onready var level_label: Label = %LevelLabel
@onready var close_button: Button = %CloseButton
@onready var description_label: Label = %DescriptionLabel
@onready var stats_grid: GridContainer = %StatsGrid
@onready var footer_label: Label = %FooterLabel
@onready var target_button: Button = %TargetButton
@onready var actions: HBoxContainer = %Actions
@onready var upgrade_button: Button = %UpgradeButton
@onready var sell_button: Button = %SellButton


func _ready() -> void:
	visible = false
	# Chaque fiche a son propre style, teinté selon la tour affichée.
	add_theme_stylebox_override("panel", get_theme_stylebox("panel").duplicate())
	close_button.pressed.connect(close_requested.emit)
	upgrade_button.pressed.connect(func() -> void: upgrade_requested.emit(tower))
	sell_button.pressed.connect(func() -> void: sell_requested.emit(tower))
	target_button.pressed.connect(_on_target_button_pressed)
	resized.connect(_reposition)


## Aperçu d'un type de tour, au-dessus de la zone donnée (le bouton de la barre
## d'achat), ou en dessous s'il n'y a pas la place.
func show_tower_type(tower_data: TowerData, gold: int, anchor_rect: Rect2) -> void:
	_set_tower(null)
	data = tower_data
	_gold = gold
	_anchor_rect = anchor_rect
	_beside = false
	_refresh()


## Fiche d'une tour posée, à côté d'elle.
func show_tower(placed: Tower, gold: int) -> void:
	_set_tower(placed)
	data = placed.data
	_gold = gold
	var tower_size := Vector2.ONE * Tower.SIZE
	_anchor_rect = Rect2(placed.get_global_transform_with_canvas().origin - tower_size / 2.0, tower_size)
	_beside = true
	_refresh()


func close() -> void:
	_set_tower(null)
	visible = false


## Met à jour l'or disponible (prix et bouton Améliorer). Seul ce qui dépend de l'or est
## refait : la fiche ouverte n'est pas reconstruite à chaque ennemi détruit.
func set_gold(gold: int) -> void:
	if gold == _gold:
		return
	_gold = gold
	if visible:
		_refresh_prices()


func _set_tower(new_tower: Tower) -> void:
	if is_instance_valid(tower) and tower.upgraded.is_connected(_on_tower_upgraded):
		tower.upgraded.disconnect(_on_tower_upgraded)
	tower = new_tower
	if tower:
		tower.upgraded.connect(_on_tower_upgraded)


func _on_tower_upgraded(_tower: Tower) -> void:
	_refresh()


func _on_target_button_pressed() -> void:
	tower.cycle_target_mode()
	_refresh()


# --- Contenu ------------------------------------------------------------------

func _refresh() -> void:
	var placed := tower != null
	# En aperçu, la fiche ne doit pas intercepter la souris.
	mouse_filter = Control.MOUSE_FILTER_STOP if placed else Control.MOUSE_FILTER_IGNORE
	var style := get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.border_color = data.color
	name_label.text = data.display_name
	name_label.add_theme_color_override("font_color", data.color.lightened(0.3))
	close_button.visible = placed
	description_label.text = data.description
	# Spécialisations (étoiles infinies) et croisements achetés : déjà comptés dans les statistiques.
	for specialization in data.get_specializations():
		description_label.text += "\n%s : %s" % ["Croisement" if specialization.crossing else "Spécialisation",
			specialization.display_name]
	if placed and tower.is_boosted():
		description_label.text += "\nRenforcée par une Bobine : +%d %% de dégâts, +%d %% de cadence" % [
			roundi(tower.boost_damage * 100.0), roundi(tower.boost_fire_rate * 100.0)]
	description_label.text = description_label.text.strip_edges()
	description_label.visible = not description_label.text.is_empty()

	var level := tower.level if placed else 1
	var stats := tower.stats if placed else data.get_stats_at_level(1)
	var next: TowerData = null
	if placed and tower.can_upgrade():
		next = tower.get_stats_at_level(level + 1)
	_fill_stats(stats, next)

	if placed:
		level_label.text = "Niv. %d / %d" % [level, data.get_max_level()]
		level_label.visible = true
		footer_label.visible = false
		actions.visible = true
		sell_button.text = "Vendre  ·  %d or" % tower.get_sell_value()
		target_button.visible = tower.uses_target_mode()
		target_button.text = "Cible : %s" % Tower.TARGET_MODE_NAMES[tower.target_mode]
	else:
		level_label.visible = false
		var footer := "Prix : %d or" % data.get_cost()
		if data.upgrades.size() > 0:
			footer += "   ·   %d amélioration%s" % [data.upgrades.size(), "s" if data.upgrades.size() > 1 else ""]
		footer_label.text = footer
		footer_label.visible = true
		actions.visible = false
		target_button.visible = false

	_refresh_prices()
	visible = true
	# La taille dépend du contenu : on la recalcule (aussi à l'image suivante, une fois
	# la mise en page des nouvelles lignes faite), puis on replace la fiche.
	reset_size()
	reset_size.call_deferred()
	_reposition()


## Bouton Améliorer (tour posée) ou prix en rouge s'il dépasse l'or (aperçu).
func _refresh_prices() -> void:
	if not is_instance_valid(tower):
		footer_label.add_theme_color_override("font_color",
			PRICE_COLOR if _gold >= data.get_cost() else TOO_EXPENSIVE_COLOR)
		return
	if not tower.can_upgrade():
		upgrade_button.text = "Pas d'amélioration (défi)" if tower.upgrades_locked else "Niveau maximal"
		upgrade_button.disabled = true
		return
	var cost := tower.get_upgrade_cost()
	upgrade_button.text = "Améliorer  ·  %d or" % cost
	upgrade_button.disabled = _gold < cost


## Une ligne par statistique : nom, valeur actuelle et, si fourni, la valeur au niveau suivant.
func _fill_stats(stats: TowerData, next: TowerData) -> void:
	for child in stats_grid.get_children():
		stats_grid.remove_child(child)
		child.queue_free()
	if stats.is_support():
		# Bobine : pas de tir, seulement le bonus donné aux tours voisines.
		_add_stat("Dégâts", "+%d %%" % roundi(stats.boost_damage * 100.0),
			"+%d %%" % roundi(next.boost_damage * 100.0) if next else "")
		_add_stat("Cadence", "+%d %%" % roundi(stats.boost_fire_rate * 100.0),
			"+%d %%" % roundi(next.boost_fire_rate * 100.0) if next else "")
	else:
		_add_stat("Dégâts", _format(stats.damage), _format(next.damage) if next else "")
		_add_stat("Cadence", "%s tirs/s" % _format(stats.fire_rate, 2),
			"%s tirs/s" % _format(next.fire_rate, 2) if next else "")
		_add_stat("Dégâts/s", _format(stats.get_dps()), _format(next.get_dps()) if next else "")
	_add_stat("Portée", _format(stats.attack_range), _format(next.attack_range) if next else "")
	if stats.chain_count > 0:
		_add_stat("Rebonds", "%d, -%d %%" % [stats.chain_count, roundi((1.0 - stats.chain_falloff) * 100.0)],
			"%d, -%d %%" % [next.chain_count, roundi((1.0 - next.chain_falloff) * 100.0)] if next else "")
	if stats.knockback > 0.0:
		_add_stat("Recul", _format(stats.knockback), _format(next.knockback) if next else "")
	if stats.beam_ramp_max > 1.0:
		_add_stat("Montée", "x%s en %s s" % [_format(stats.beam_ramp_max), _format(stats.beam_ramp_time)],
			"x%s en %s s" % [_format(next.beam_ramp_max), _format(next.beam_ramp_time)] if next else "")
	if stats.splash_radius > 0.0:
		_add_stat("Explosion", _format(stats.splash_radius), _format(next.splash_radius) if next else "")
	if stats.cloud_radius > 0.0:
		_add_stat("Nuage", "%s, %s s" % [_format(stats.cloud_radius), _format(stats.cloud_duration)],
			"%s, %s s" % [_format(next.cloud_radius), _format(next.cloud_duration)] if next else "")
	if stats.dot_damage > 0.0:
		var dot_name := "Poison" if stats.cloud_radius > 0.0 or stats.dot_is_poison else "Brûlure"
		_add_stat(dot_name, "%s/s, %s s" % [_format(stats.dot_damage), _format(stats.dot_duration)],
			"%s/s, %s s" % [_format(next.dot_damage), _format(next.dot_duration)] if next else "")
	if not stats.hits_air:
		_add_stat("Volants", "hors d'atteinte", "")
	elif stats.air_damage_multiplier != 1.0:
		_add_stat("Volants", "x%s dégâts" % _format(stats.air_damage_multiplier), "")
	if stats.detects_stealth():
		_add_stat("Détection", _format(stats.detection_range), _format(next.detection_range) if next else "")
	if stats.armor_piercing:
		_add_stat("Armure", "ignorée", "")
	if stats.shield_damage_multiplier != 1.0:
		_add_stat("Boucliers", "x%s dégâts" % _format(stats.shield_damage_multiplier),
			"x%s dégâts" % _format(next.shield_damage_multiplier) if next else "")
	if stats.shield_jam_duration > 0.0:
		_add_stat("Brouillés", "%s s" % _format(stats.shield_jam_duration),
			"%s s" % _format(next.shield_jam_duration) if next else "")
	if stats.heal_block_duration > 0.0:
		_add_stat("Anti-soin", "%s s" % _format(stats.heal_block_duration),
			"%s s" % _format(next.heal_block_duration) if next else "")
	if stats.slow_factor < 1.0:
		_add_stat("Ralentit", "-%d %%" % roundi((1.0 - stats.slow_factor) * 100.0),
			"-%d %%" % roundi((1.0 - next.slow_factor) * 100.0) if next else "")
		_add_stat("Pendant", "%s s" % _format(stats.slow_duration),
			"%s s" % _format(next.slow_duration) if next else "")


func _add_stat(stat_name: String, value: String, next_value: String) -> void:
	var name_cell := Label.new()
	name_cell.text = stat_name
	name_cell.add_theme_color_override("font_color", MUTED_COLOR)
	stats_grid.add_child(name_cell)
	var value_cell := Label.new()
	value_cell.text = value
	value_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_grid.add_child(value_cell)
	# Seuls les gains apparaissent : une valeur inchangée laisse la case vide.
	var next_cell := Label.new()
	next_cell.text = "→ %s" % next_value if not next_value.is_empty() and next_value != value else ""
	next_cell.add_theme_color_override("font_color", BONUS_COLOR)
	stats_grid.add_child(next_cell)


## Nombre arrondi, sans décimales inutiles : 25, 1.5, 0.75.
static func _format(value: float, decimals := 1) -> String:
	var text := String.num(value, decimals)
	return text.rstrip("0").trim_suffix(".") if text.contains(".") else text


# --- Position -----------------------------------------------------------------

func _reposition() -> void:
	if not visible or not is_inside_tree():
		return
	var area := bounds if bounds.has_area() else get_viewport_rect()
	var target: Vector2
	if _beside:
		# À droite de la tour, ou à gauche s'il n'y a pas la place.
		target.x = _anchor_rect.end.x + GAP
		if target.x + size.x > area.end.x - GAP:
			target.x = _anchor_rect.position.x - GAP - size.x
		target.y = _anchor_rect.get_center().y - size.y / 2.0
	else:
		target.x = _anchor_rect.get_center().x - size.x / 2.0
		target.y = _anchor_rect.position.y - GAP - size.y
		if target.y < area.position.y + GAP:
			target.y = _anchor_rect.end.y + GAP
	target.x = clampf(target.x, area.position.x + GAP, maxf(area.position.x + GAP, area.end.x - size.x - GAP))
	target.y = clampf(target.y, area.position.y + GAP, maxf(area.position.y + GAP, area.end.y - size.y - GAP))
	position = target
